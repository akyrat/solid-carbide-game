extends SceneTree
## How fast the game runs with a crowd of minions (task T-444): starts the game's own run on
## its map (Kaiju City, game_flow.gd GAME_MAP_PATH), parks the car where the run puts it, and
## for each count in --counts holds that many minions alive round the car (placed on free
## spots MIN_RING to MAX_RING units from it, topped up every frame when one is removed, and
## too tough for the weapons to kill) for --seconds after --warmup seconds. It then prints,
## per count, the average, 99th percentile and worst time of:
##   - frame: one whole frame (one physics step and one idle frame: the tool runs with
##     --fixed-fps 50, so every frame is exactly one physics step of the game's 50 a second),
##   - physics: the scripts' physics step (every node's _physics_process, minions, car,
##     weapons, camera, between two bracket nodes that run first and last),
##   - minions: the minion spawner's own step (minion_spawner.gd, last_step_usec).
## A frame of 20 ms is the whole budget of a 50 Hz physics step.
##
## Usage (normally through tools/minion_crowd_bench.sh, from the repo root):
##   godot --headless --fixed-fps 50 --path game -s res://tools/minion_crowd_bench.gd -- \
##       [--counts=50,100,200,300] [--seconds=6] [--warmup=1] [--seed=444] [--breakdown]
## --breakdown also times the parts of the minions' step (separation, paths, walking,
## contact, removing, drawing), by running the same parts the spawner runs, one at a time.
## Exit codes: 0 = measured; 1 = the run did not start; 2 = bad arguments.
## Only the timer's ceiling is changed (to the count), for this tool's run; nothing is saved.

const GameScene := preload("res://scenes/game/game.tscn")
const ISO := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
## The ring round the car where minions are placed, units.
const MIN_RING := 4.0
const MAX_RING := 30.0
## Health that the weapons cannot take away during the measure.
const TOUGH := 1000000000.0

var counts: Array = [50, 100, 200, 300]
var seconds := 6.0
var warmup := 1.0
var seed_value := 444
var breakdown := false

var game: Node
var run: Node2D
var spawner: Node
var rng := RandomNumberGenerator.new()
var _phase := "start"
var _count_index := -1
var _time := 0.0
var _frames := 0
var _last_usec := 0
var _frame_ms: Array = []
var _physics_ms: Array = []
var _minion_ms: Array = []
var _parts: Dictionary = {}
var _phys_t0 := 0
var _results: Array = []


class Bracket extends Node:
	var on_step: Callable

	func _physics_process(_delta: float) -> void:
		on_step.call()


func _initialize() -> void:
	if not _parse(OS.get_cmdline_user_args()):
		quit(2)
		return
	rng.seed = seed_value


## The tree is only ready from the first frame: the game is started there.
func _start() -> bool:
	game = GameScene.instantiate()
	game.set("tutorial_enabled", false)
	root.add_child(game)
	game.start_run()
	run = game.run
	if run == null or run.minions == null or run.car == null:
		printerr("minion_crowd_bench: the run did not start")
		quit(1)
		return false
	spawner = run.minions
	spawner.rng.seed = seed_value
	spawner.minion_spawned.connect(_toughen)
	var first := Bracket.new()
	first.process_physics_priority = -1000000
	first.on_step = func() -> void: _phys_t0 = Time.get_ticks_usec()
	root.add_child(first)
	var last := Bracket.new()
	last.process_physics_priority = 1000000
	last.on_step = _after_physics
	root.add_child(last)
	var car = run.car
	car.use_keyboard = false
	car.set("detect_tricks", false)
	car.scripted_input = [false, false, 0.0]
	# Parked: the minions' knockback does not move it.
	car.set_physics_process(false)
	print("minion_crowd_bench: map %s, car at %s (units), %d physics steps a second, counts %s, %.1f s each after %.1f s warm-up" % [
		run.current_layout_path(), (car.position / 16.0).round(), Engine.physics_ticks_per_second, counts, seconds, warmup])
	_next_count()
	return true


func _parse(args: PackedStringArray) -> bool:
	for a in args:
		if a.begins_with("--counts="):
			counts = []
			for s in a.trim_prefix("--counts=").split(",", false):
				if not s.is_valid_int() or int(s) <= 0:
					printerr("minion_crowd_bench: bad count: %s" % s)
					return false
				counts.append(int(s))
		elif a.begins_with("--seconds="):
			seconds = a.trim_prefix("--seconds=").to_float()
		elif a.begins_with("--warmup="):
			warmup = a.trim_prefix("--warmup=").to_float()
		elif a.begins_with("--seed="):
			seed_value = a.trim_prefix("--seed=").to_int()
		elif a == "--breakdown":
			breakdown = true
		else:
			printerr("minion_crowd_bench: unknown argument %s" % a)
			return false
	if counts.is_empty() or seconds <= 0.0 or warmup < 0.0:
		printerr("minion_crowd_bench: need counts and seconds above 0")
		return false
	return true


func _toughen(m: Node) -> void:
	m.max_health = TOUGH
	m.health = TOUGH


## Starts the next count: removes every minion and puts `n` round the car.
func _next_count() -> void:
	_count_index += 1
	if _count_index >= counts.size():
		_phase = "done"
		return
	spawner.clear()
	var n: int = counts[_count_index]
	spawner._spawning["max_minions_alive"] = float(n)
	_top_up(n)
	_time = 0.0
	_frame_ms = []
	_physics_ms = []
	_minion_ms = []
	_parts = {}
	_last_usec = 0
	_phase = "warmup"


## Puts minions on free spots round the car until `n` are alive.
func _top_up(n: int) -> void:
	var car_units: Vector2 = run.car.position / 16.0
	var tries := 0
	while spawner.minions.size() < n and tries < n * 200:
		tries += 1
		var p: Vector2 = car_units + Vector2.RIGHT.rotated(rng.randf() * TAU) * rng.randf_range(MIN_RING, MAX_RING)
		if spawner.is_free_spot(p):
			spawner.spawn_minion_at(p)


## The physics bracket's end: the scripts' physics step, and the parts with --breakdown.
func _after_physics() -> void:
	if _phase != "measure":
		return
	_physics_ms.append((Time.get_ticks_usec() - _phys_t0) / 1000.0)
	_minion_ms.append(spawner.last_step_usec / 1000.0)
	if breakdown:
		_time_parts()


func _process(delta: float) -> bool:
	if _phase == "done":
		_report()
		return true
	if _phase == "start":
		return not _start()
	var now := Time.get_ticks_usec()
	if _phase == "measure" and _last_usec > 0:
		_frame_ms.append((now - _last_usec) / 1000.0)
	_last_usec = now
	run.state.health = run.state.max_health
	_apply_real_screen()
	_top_up(counts[_count_index])
	_time += delta
	if _phase == "warmup" and _time >= warmup:
		_phase = "measure"
		_time = 0.0
		_last_usec = Time.get_ticks_usec()
	elif _phase == "measure" and _time >= seconds:
		_results.append(_result_line())
		print(_results[-1])
		if breakdown:
			print(_parts_line())
		_next_count()
	return false


## The game window's visible screen (1152 x 648) at the run's zoom round the car: a headless
## viewport is smaller, which would make minions spawn and disappear too near the car.
func _apply_real_screen() -> void:
	var size := Vector2(1152, 648) * (2.0 * float(run.camera_follow.size) * 16.0 / 648.0)
	var centre: Vector2 = ISO * run.car.position
	var rect := Rect2(centre - size / 2.0, size)
	spawner.visible_rect_override = rect
	run.kaiju_boss.visible_rect_override = rect


## The minions' step again, part by part (not moving anything twice: it times a copy of the
## work that does not change the minions: separation, the follower's sight check and path,
## the depth order). Only with --breakdown, after the real step.
func _time_parts() -> void:
	var car_units: Vector2 = run.car.position / 16.0
	var t := Time.get_ticks_usec()
	spawner._separation()
	_add_part("separation", t)
	t = Time.get_ticks_usec()
	var nav = spawner.navigation
	if nav != null:
		for m in spawner.minions:
			if is_instance_valid(m):
				nav.line_clear(m.position_units(), car_units, 0.5)
	_add_part("sight (line_clear, every minion)", t)
	t = Time.get_ticks_usec()
	for m in spawner.minions:
		if is_instance_valid(m):
			m.body_height()
	_add_part("body_height", t)
	t = Time.get_ticks_usec()
	for m in spawner.minions:
		if is_instance_valid(m):
			spawner.depth.z_index_for(m.position_units(), m.radius_units(), m.height_units(), m.body_height())
	_add_part("depth order", t)
	t = Time.get_ticks_usec()
	for m in spawner.minions:
		if is_instance_valid(m) and spawner.ground != null:
			spawner.EnemyHeightScript.limit_motion(spawner.ground, m.position_units(), m.heading * 0.084, 0.5, m.body_height(), false)
	_add_part("edge check (limit_motion)", t)


func _add_part(name: String, t0: int) -> void:
	if not _parts.has(name):
		_parts[name] = []
	_parts[name].append((Time.get_ticks_usec() - t0) / 1000.0)


func _result_line() -> String:
	return "minion_crowd_bench: %d alive (%d at the end), %d frames: frame ms %s | physics ms %s | minions' step ms %s" % [
		counts[_count_index], spawner.minions.size(), _frame_ms.size(), summary(_frame_ms), summary(_physics_ms), summary(_minion_ms)]


func _parts_line() -> String:
	var bits := []
	for k in _parts:
		bits.append("%s %s" % [k, summary(_parts[k])])
	return "minion_crowd_bench:   parts (ms, timed apart): " + "; ".join(bits)


## "avg A, p99 B, worst C" of `values` (ms).
static func summary(values: Array) -> String:
	if values.is_empty():
		return "none"
	var v := values.duplicate()
	v.sort()
	var sum := 0.0
	for x in v:
		sum += float(x)
	return "avg %.2f, p99 %.2f, worst %.2f" % [sum / v.size(), v[mini(v.size() - 1, int(v.size() * 0.99))], v[v.size() - 1]]


func _report() -> void:
	print("minion_crowd_bench: done")
	for line in _results:
		print(line)
	spawner = null
	run = null
	game.queue_free()
	game = null
	quit(0)
