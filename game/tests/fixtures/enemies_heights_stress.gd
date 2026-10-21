extends Node
## Frame time with many enemies on the heights (task T-207): a run started
## from the main menu on the elevation map, the car parked on roof-nw-6
## (height 6), and `minions` minions put on the street inside the visible
## screen at once (more than the run spawns: the T-206 soak reached 21), so
## every one of them needs a path up the ramps. For `seconds` real seconds it reads Godot's physics
## time per frame (Performance.TIME_PHYSICS_PROCESS) and the minions' own step
## (run.minions.last_step_usec), then prints a summary and quits:
## python game/tools/run_scene_headless.py res://tests/fixtures/enemies_heights_stress.tscn 60
## `enemy_heights` false runs the same with the enemies ignoring the heights
## (as before T-207), to compare.

@export var minions := 30
@export var seconds := 20.0
@export var enemy_heights := true
@export var car_units := Vector2(-27, -81)
## The camera's orthographic size (units), fixed for the measure.
@export var zoom := 16.0
## Prints where the minions are every 2 s.
@export var debug := false
## Spawning, removing and "on screen" use the game window's screen (1152 x 648).
@export var real_screen := true

var game: Node
var run: Node2D
var elapsed := 0.0
var _frames: Array = []
var _max_on_screen := 0
var _reached := 0


func _ready() -> void:
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	run = game.run
	if not enemy_heights:
		run.minions.heights_enabled = false
		run.kaiju_boss.heights_enabled = false
		run.start_run()
	var car = run.car
	car.use_keyboard = false
	car.detect_tricks = false
	car.model.set_position(car_units)
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = run.elevation.ground_height
	car.scripted_input = [false, false, 0.0]
	run.sync_view()
	# Parked: the minions' knockback does not move it off the rooftop.
	car.set_physics_process(false)
	# The camera's size while driving (the dynamic camera zooms in on a parked car).
	run.camera_follow.dynamic = false
	run.set_zoom(zoom)
	await get_tree().process_frame
	await get_tree().process_frame
	if real_screen:
		_apply_real_screen()
	var placed := 0
	var tries := 0
	# On the street inside the visible screen, so all of them are on screen
	# and every one needs a path up the ramps.
	var rect: Rect2 = run.minions.visible_rect()
	var inv := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO).affine_inverse()
	var rng := RandomNumberGenerator.new()
	rng.seed = 207
	while placed < minions and tries < minions * 200:
		tries += 1
		var px := rect.position + Vector2(rng.randf(), rng.randf()) * rect.size
		var p: Vector2 = (inv * px) / 16.0
		if run.minions.is_free_spot(p):
			var m = run.minions.spawn_minion_at(p)
			# The car's weapons would kill them before the measure ends.
			m.max_health = 1000000.0
			m.health = m.max_health
			placed += 1
	print("enemies_heights_stress: %d minions on the street, car at %s height %.1f, enemy heights %s" % [
		placed, car_units, car.height, enemy_heights])


func _process(delta: float) -> void:
	if run == null:
		return
	elapsed += delta
	run.state.health = run.state.max_health
	if real_screen:
		_apply_real_screen()
	if debug and int(elapsed / 2.0) != int((elapsed - delta) / 2.0):
		var info := []
		for m in run.minions.minions:
			info.append("%s h%.1f p%s" % [m.position_units().round(), m.ground_height(), m.follower.has_path()])
		var iso := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
		print("enemies_heights_stress: t %.0f: screen %s car drawn %s: %d minions, nav paths %d: %s" % [elapsed, run.minions.visible_rect(), iso * run.car.position, run.minions.minions.size(), run.minions.navigation.paths_total if run.minions.navigation else 0, ", ".join(info.slice(0, 8))])
	if elapsed >= seconds:
		set_process(false)
		_report()
		_quit()


## The visible screen of the game's window (1152 x 648) at the run's zoom
## (run.gd, _apply_zoom: the orthographic size camera_follow.size), round the
## parked car: a headless run's viewport is far smaller, and its zoom
## follows it, which makes the minions spawn and disappear at the wrong
## distances from the car.
func _apply_real_screen() -> void:
	var size := Vector2(1152, 648) * (2.0 * float(run.camera_follow.size) * 16.0 / 648.0)
	# Round the parked car (the camera may still be on its way there).
	var centre: Vector2 = Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO) * run.car.position
	var rect := Rect2(centre - size / 2.0, size)
	run.minions.visible_rect_override = rect
	run.kaiju_boss.visible_rect_override = rect


## Once per physics step: Godot's physics time of the last step, the
## minions' own step, and how many are on screen.
func _physics_process(_delta: float) -> void:
	if run == null or not is_processing():
		return
	var n := _on_screen()
	_max_on_screen = maxi(_max_on_screen, n)
	_frames.append([n, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		run.minions.last_step_usec / 1000.0, run.minions.minions.size()])


func _on_screen() -> int:
	var rect: Rect2 = run.minions.visible_rect()
	var iso := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
	var c := 0
	for m in run.minions.minions:
		if is_instance_valid(m) and rect.has_point(iso * m.position):
			c += 1
	return c


func _report() -> void:
	var on_top := 0
	for m in run.minions.minions:
		if is_instance_valid(m) and absf(m.ground_height() - run.car.height) < 1.0:
			on_top += 1
	var phys := []
	var steps := []
	var busy_phys := []
	var busy_steps := []
	for f in _frames:
		phys.append(f[1])
		steps.append(f[2])
		if f[0] >= _max_on_screen - 1:
			busy_phys.append(f[1])
			busy_steps.append(f[2])
	print("enemies_heights_stress: enemy heights %s, most minions on screen %d (minions alive at the end %d, at the car's level %d)" % [
		enemy_heights, _max_on_screen, run.minions.minions.size(), on_top])
	print("enemies_heights_stress: all %d physics steps: physics ms %s; minions' step ms %s" % [phys.size(), _summary(phys), _summary(steps)])
	print("enemies_heights_stress: %d physics steps with %d+ on screen: physics ms %s; minions' step ms %s" % [
		busy_phys.size(), maxi(_max_on_screen - 1, 0), _summary(busy_phys), _summary(busy_steps)])


static func _summary(values: Array) -> String:
	if values.is_empty():
		return "none"
	var v := values.duplicate()
	v.sort()
	var sum := 0.0
	for x in v:
		sum += x
	return "mean %.2f, p99 %.2f, max %.2f" % [sum / v.size(), v[mini(v.size() - 1, int(v.size() * 0.99))], v[v.size() - 1]]


func _quit() -> void:
	run = null
	game.queue_free()
	game = null
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0)
