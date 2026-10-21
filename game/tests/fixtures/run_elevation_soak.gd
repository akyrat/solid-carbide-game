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
	run.car.use_keyboard = false
	run.weapons.gun.fired.connect(func(_b, _t) -> void: shots += 1)
	run.state.level_up_choice_started.connect(func(_l) -> void: level_up_screens += 1)
	print("run_elevation_soak: started, layout %s, %d rooftops and ramps" % [
		run.map.layout_path, run.elevation.areas.size() if run.elevation != null else 0])


func _process(delta: float) -> void:
	if run == null or not is_instance_valid(run):
		return
	elapsed += delta
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
		set_process(false)
		_quit()


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
