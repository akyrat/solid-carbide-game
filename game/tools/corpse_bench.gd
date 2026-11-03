extends SceneTree
## How much the minions' corpses and green spills cost (task T-531): starts the game's own run on
## its map, parks the car, and for --seconds kills --kills minions every --every seconds (a mass
## death, like a bricks wave on a crowd), twice: with the corpses off (the old "freed at death")
## and with them on. Prints the average, 99th percentile and worst frame and physics time (ms) of each,
## and the most corpses, droplets and pools alive. Headless: the scripts' work is measured, not the
## graphics card's (the perf recorder in a window does that: perf_sample_run.sh).
##
## Usage (normally through tools/corpse_bench.sh): godot --headless --fixed-fps 50 --path game
##   -s res://tools/corpse_bench.gd -- [--seconds=8] [--kills=40] [--every=0.5] [--crowd=60]
## Exit codes: 0 = measured; 1 = the run did not start.

const GameScene := preload("res://scenes/game/game.tscn")
const TOUGH := 1000000000.0

var seconds := 8.0
var kills := 40
var every := 0.5
var crowd := 60
## --on-first: measure with the corpses on first (checks that the order does not matter).
var on_first := false

var game: Node
var run: Node2D
var spawner: Node
var rng := RandomNumberGenerator.new()
var _phase := -1  # 0 = corpses off, 1 = corpses on, 2 = done
var _time := 0.0
var _since_kill := 0.0
var _frame_ms: Array = []
var _physics_ms: Array = []
var _last_usec := 0
var _phys_t0 := 0
var _max := [0, 0, 0]
var _lines: Array = []
var _started := false
var _step_us: Array = []
var _adopt_us: Array = []


class Bracket extends Node:
	var on_step: Callable

	func _physics_process(_delta: float) -> void:
		on_step.call()


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seconds="):
			seconds = a.get_slice("=", 1).to_float()
		elif a.begins_with("--kills="):
			kills = a.get_slice("=", 1).to_int()
		elif a.begins_with("--every="):
			every = a.get_slice("=", 1).to_float()
		elif a == "--on-first":
			on_first = true
		elif a.begins_with("--crowd="):
			crowd = a.get_slice("=", 1).to_int()
	rng.seed = 531


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		return _start()
	var now := Time.get_ticks_usec()
	if _last_usec > 0:
		_frame_ms.append((now - _last_usec) / 1000.0)
	_last_usec = now
	if _phase >= 2:
		return false
	var dt := 1.0 / Engine.physics_ticks_per_second
	_time += dt
	_since_kill += dt
	_top_up()
	if _since_kill >= every:
		_since_kill = 0.0
		_mass_death()
	var c = spawner.corpses
	_step_us.append(c.last_step_usec / 1000.0)
	_adopt_us.append(c.adopt_usec / 1000.0)
	c.adopt_usec = 0
	_max = [maxi(_max[0], c.corpse_count()), maxi(_max[1], c.droplet_count()), maxi(_max[2], c.pool_count())]
	if _time >= seconds:
		_finish_phase()
	return false


func _start() -> bool:
	game = GameScene.instantiate()
	game.set("tutorial_enabled", false)
	root.add_child(game)
	game.start_run()
	run = game.run
	if run == null or run.minions == null or run.car == null:
		printerr("corpse_bench: the run did not start")
		quit(1)
		return true
	spawner = run.minions
	spawner.rng.seed = 531
	spawner.enabled = true
	spawner._spawning["max_minions_alive"] = float(crowd + kills)
	var first := Bracket.new()
	first.process_physics_priority = -1000000
	first.on_step = func() -> void: _phys_t0 = Time.get_ticks_usec()
	root.add_child(first)
	var last := Bracket.new()
	last.process_physics_priority = 1000000
	last.on_step = func() -> void: _physics_ms.append((Time.get_ticks_usec() - _phys_t0) / 1000.0)
	root.add_child(last)
	var car = run.car
	car.use_keyboard = false
	car.set("detect_tricks", false)
	car.set_physics_process(false)
	run.state.max_health = TOUGH
	run.state.health = TOUGH
	run.kaiju_boss.enabled = false
	_begin_phase(1 if on_first else 0)
	return false


func _begin_phase(p: int) -> void:
	_phase = p
	spawner.clear()
	spawner.corpses.enabled = (p == 1)
	_time = 0.0
	_since_kill = 0.0
	_frame_ms = []
	_physics_ms = []
	_last_usec = 0
	_max = [0, 0, 0]
	_step_us = []
	_adopt_us = []


## Keeps `crowd` minions alive round the car, placed on the street 4 to 14 units away.
func _top_up() -> void:
	var car_units: Vector2 = run.car.position / 16.0
	var tries := 0
	while spawner.minions.size() < crowd + kills and tries < 400:
		tries += 1
		var a := rng.randf() * TAU
		var p := car_units + Vector2.from_angle(a) * rng.randf_range(4.0, 14.0)
		if spawner.is_free_spot(p):
			var m = spawner.spawn_minion_at(p)
			m.max_health = TOUGH
			m.health = TOUGH


func _mass_death() -> void:
	var n := 0
	for m in spawner.minions.duplicate():
		if n >= kills:
			break
		if is_instance_valid(m) and not m.is_dead():
			m.take_damage(TOUGH * 2.0, "bench")
			n += 1


func _finish_phase() -> void:
	var c = spawner.corpses
	_lines.append("corpse_bench: corpses %s, %d kills every %.2f s, %d frames: frame ms %s | physics ms %s | most alive: %d corpses, %d droplets, %d pools | corpse keeper step ms %s, adopt ms a step %s" % [
		"ON " if _phase == 1 else "OFF", kills, every, _frame_ms.size(), summary(_frame_ms), summary(_physics_ms), _max[0], _max[1], _max[2],
		summary(_step_us), summary(_adopt_us)])
	if _lines.size() == 1:
		_begin_phase(0 if on_first else 1)
		return
	_phase = 2
	for l in _lines:
		print(l)
	spawner.clear()
	quit(0)


static func summary(values: Array) -> String:
	if values.is_empty():
		return "none"
	var v := values.duplicate()
	v.sort()
	var sum := 0.0
	for x in v:
		sum += float(x)
	return "avg %.2f, p99 %.2f, worst %.2f" % [sum / v.size(), v[mini(v.size() - 1, int(v.size() * 0.99))], v[v.size() - 1]]
