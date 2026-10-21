extends Node
## Scripted run (task T-206): a run started from the main menu (game.tscn,
## Start) on the elevation sample map, played for RUN_SECONDS of real time
## with the car driven by script, so Godot's output can be checked for errors
## over a long run (python game/tools/run_scene_headless.py
## res://tests/fixtures/run_elevation_soak.tscn 135 --show).
##
## What it does, by the clock (real seconds since Start):
## - the car drives with W held, steering in turns (so it drifts and earns
##   likes); every SPOT_SECONDS it is put on the next spot of SPOTS: on the
##   street, on the rooftops at heights 3 and 6, at the foot of a ramp, so the
##   run goes on with the car at every height;
## - the car's health is kept full, so the run does not end before the kaiju;
## - at LEVEL_UP_AT seconds the run gains enough likes for two level-ups: the
##   gift pack's helicopters come, their packages are picked up and each
##   level-up screen's highlighted weapon is taken;
## - at BOSS_AT seconds the clock jumps to just over 1:00 left, so the kaiju
##   arrives.
## Every 10 s it prints one line; at the end a summary
## ("run_elevation_soak: done ...") and the game quits.
##
## Frame time (task T-207): every frame it reads Godot's physics time for the
## frame (Performance.TIME_PHYSICS_PROCESS) and the minions' own step
## (run.minions.last_step_usec), with the number of minions on screen; the
## summary ("run_elevation_soak: frame time ...") gives them at the most
## minions on screen. `enemy_heights` false runs the enemies as before T-207
## (they ignore the heights), to compare.

const RUN_SECONDS := 120.0
const SPOT_SECONDS := 12.0
const LEVEL_UP_AT := 25.0
const BOSS_AT := 70.0
## Spots (flat units) and headings: street, rooftop 3, rooftop 6, the gravel
## centre, the south-east rooftops, the street by the south-east ramp.
const SPOTS := [
	[Vector2(-81, -40), -PI / 2.0],
	[Vector2(-70, -80), 0.0],
	[Vector2(-27, -81), PI / 2.0],
	[Vector2(0, 0), 0.0],
	[Vector2(60, 80), PI],
	[Vector2(27, 81), 0.0],
	[Vector2(81, 40), -PI / 2.0],
]

## The MVP map instead (run.use_elevation_map false), to compare the two maps.
@export var mvp_map := false
## How long the run is played, real seconds.
@export var run_seconds := RUN_SECONDS
## T-207: false makes the enemies ignore the heights (as before T-207), to compare.
@export var enemy_heights := true
## T-207: spawning, removing and "on screen" use the game window's screen
## (1152 x 648) instead of the headless run's tiny viewport.
@export var real_screen := false

var game: Node
var run: Node2D
var elapsed := 0.0
var _next_line := 10.0
var _next_spot := 0.0
var _spot := 0
var _levelled := false
var _boss := false
var shots := 0
var max_minions := 0
var max_height := 0.0
var level_up_screens := 0
var kaiju_seen := false
## Per frame: [minions on screen, physics frame ms, minions' step ms].
var _frames: Array = []


func _ready() -> void:
	# Keeps running while the level-up screen pauses the run, to take its weapon.
	process_mode = Node.PROCESS_MODE_ALWAYS
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	run = game.run
	if mvp_map:
		run.use_elevation_map = false
		run.start_run()
	if not enemy_heights:
		run.minions.heights_enabled = false
		run.kaiju_boss.heights_enabled = false
		run.start_run()
	run.car.use_keyboard = false
	run.weapons.gun.fired.connect(func(_b, _t) -> void: shots += 1)
	run.state.level_up_choice_started.connect(func(_l) -> void: level_up_screens += 1)
	print("run_elevation_soak: started, layout %s, %d rooftops and ramps" % [
		run.map.layout_path, run.elevation.areas.size() if run.elevation != null else 0])


func _process(delta: float) -> void:
	if run == null or not is_instance_valid(run):
		return
	elapsed += delta
	if real_screen:
		_apply_real_screen()
	var state = run.state
	state.health = state.max_health
	# The level-up screen: take the highlighted weapon once it is built up.
	if run.level_up_screen.is_open():
		run.level_up_screen.skip_animation()
		run.level_up_screen.take_highlighted()
	if elapsed >= _next_spot:
		_next_spot += SPOT_SECONDS
		_put_car(SPOTS[_spot % SPOTS.size()])
		_spot += 1
	# Steer in turns: right, straight, left, straight, two seconds each.
	var phase := int(elapsed / 2.0) % 4
	var steer: float = [-1.0, 0.0, 1.0, 0.0][phase]
	run.car.scripted_input = [true, false, steer]
	if not _levelled and elapsed >= LEVEL_UP_AT:
		_levelled = true
		state.add_xp(state.xp_needed() + 1.0)
		state.add_xp(state.xp_needed() + 1.0)
	if _levelled and not run.gift_drops.packages.is_empty() and not run.level_up_screen.is_open():
		run.gift_drops.pick_up_all()
	if not _boss and elapsed >= BOSS_AT:
		_boss = true
		state.time_left = 61.0
	max_minions = maxi(max_minions, run.minions.minions.size())
	max_height = maxf(max_height, run.car.height)
	if run.kaiju_boss.kaiju != null:
		kaiju_seen = true
	if elapsed >= _next_line:
		_next_line += 10.0
		_print_line("at")
	if elapsed >= run_seconds:
		_print_line("done")
		_print_frame_time()
		set_process(false)
		_quit()


## The visible screen of the game's window (1152 x 648) at the run's zoom
## (run.gd, _apply_zoom: the orthographic size camera_follow.size), round the
## camera's centre: a headless run's viewport is far smaller, and its zoom
## follows it, which makes the minions spawn and disappear at the wrong
## distances from the car.
func _apply_real_screen() -> void:
	var cam: Camera2D = run.camera
	var size := Vector2(1152, 648) * (2.0 * float(run.camera_follow.size) * 16.0 / 648.0)
	var rect := Rect2(cam.get_screen_center_position() - size / 2.0, size)
	run.minions.visible_rect_override = rect
	run.kaiju_boss.visible_rect_override = rect


## Once per physics step (T-207): Godot's physics time of the last step, the
## minions' own step, and how many are on screen.
func _physics_process(_delta: float) -> void:
	if run == null or not is_instance_valid(run) or not is_processing():
		return
	_frames.append([_on_screen(), Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		run.minions.last_step_usec / 1000.0])


## Minions inside the visible screen now.
func _on_screen() -> int:
	var rect: Rect2 = run.minions.visible_rect()
	var iso := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
	var n := 0
	for m in run.minions.minions:
		if is_instance_valid(m) and rect.has_point(iso * m.position):
			n += 1
	return n


## The frame time summary: over every frame, and over the frames with the
## most minions on screen (the top count and one under it).
func _print_frame_time() -> void:
	var top := 0
	for f in _frames:
		top = maxi(top, f[0])
	var all := _stats(_frames)
	var busy := _stats(_frames.filter(func(f) -> bool: return f[0] >= top - 1))
	print("run_elevation_soak: frame time, enemy heights %s, real screen %s: most minions on screen %d; physics step ms mean %.2f, p99 %.2f, max %.2f over %d steps; at %d+ on screen: physics ms mean %.2f, p99 %.2f, max %.2f, minions' step ms mean %.3f, max %.3f over %d steps" % [
		enemy_heights, real_screen, top, all.mean, all.p99, all.max, all.n, maxi(top - 1, 0),
		busy.mean, busy.p99, busy.max, busy.step_mean, busy.step_max, busy.n])
	var nav = run.minions.navigation
	if nav != null:
		print("run_elevation_soak: navigation built in %.1f ms, %d points" % [nav.build_usec / 1000.0, nav.astar.get_point_count()])


static func _stats(frames: Array) -> Dictionary:
	var phys := []
	var step_sum := 0.0
	var step_max := 0.0
	for f in frames:
		phys.append(f[1])
		step_sum += f[2]
		step_max = maxf(step_max, f[2])
	phys.sort()
	var n := phys.size()
	if n == 0:
		return {"mean": 0.0, "p99": 0.0, "max": 0.0, "n": 0, "step_mean": 0.0, "step_max": 0.0}
	var sum := 0.0
	for p in phys:
		sum += p
	return {"mean": sum / n, "p99": phys[mini(n - 1, int(n * 0.99))], "max": phys[n - 1], "n": n,
		"step_mean": step_sum / n, "step_max": step_max}


func _put_car(spot: Array) -> void:
	var car: CharacterBody2D = run.car
	car.model.set_position(spot[0])
	car.model.rotation = spot[1]
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	if run.elevation != null:
		car.ground = run.elevation.ground_height


func _print_line(what: String) -> void:
	var state = run.state
	print("run_elevation_soak: %s %.0f s: time left %s, level %d, likes %.1f, minions %d (max %d), shots %d, level-up screens %d, kaiju %s (seen %s), car %s height %.2f (max %.2f), running %s" % [
		what, elapsed, state.time_left_text(), state.level, state.xp, run.minions.minions.size(),
		max_minions, shots, level_up_screens, run.kaiju_boss.kaiju != null, kaiju_seen,
		run.car.model.get_position().round(), run.car.height, max_height, state.is_running()])


## Frees the game before quitting, so nothing of it is still in use at exit.
func _quit() -> void:
	run = null
	game.queue_free()
	game = null
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0)
