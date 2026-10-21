extends Node
## GIF fixture (task T-228): a run started from the main menu on the elevation
## map, the car driven up the 0-to-3 ramp, the 3-to-6 ramp and off the
## height-6 rooftop's edge by the same scripted route as
## tools/drive_elevation_sample.gd, so the recording shows the camera following
## the car's height. The scene quits `after_landing` physics steps after the
## car lands. Record it with Godot's movie maker, one physics step per frame:
##   "$GODOT_BIN" --path game --fixed-fps 50 --write-movie C:/abs/dir/f.png res://tests/fixtures/run_camera_height_gif.tscn

const Drive := preload("res://tools/drive_elevation_sample.gd")

@export var zoom := 14.0
@export var after_landing := 60

var game: Node
var run: Node2D
var route: Dictionary
var wp := 0
var prev_point := Vector2.ZERO
var jumped := false
var landed_at := -1
var _steps := 0


func _ready() -> void:
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	run = game.run
	var car: CharacterBody2D = run.car
	car.use_keyboard = false
	car.detect_tricks = false
	route = Drive.plan(run.elevation.ground_height)
	var start: Vector2 = route.start
	car.model.set_position(start)
	car.model.rotation = route.rotation
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = run.elevation.ground_height
	prev_point = start
	run.camera_follow.dynamic = false
	run.camera_follow.smoothing = false
	run.set_zoom(zoom)
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()
	car.stepped.connect(_on_stepped)
	_on_stepped()


func _process(_delta: float) -> void:
	if run != null and run.state != null:
		run.state.health = run.state.max_health


func _on_stepped() -> void:
	var car: CharacterBody2D = run.car
	_steps += 1
	var pos: Vector2 = car.model.get_position()
	var wps: Array = route.waypoints
	while wp < wps.size():
		var target: Vector2 = wps[wp].point
		var leg: Vector2 = (target - prev_point).normalized()
		if pos.distance_to(target) < Drive.WAYPOINT_RADIUS or (pos - target).dot(leg) >= 0.0:
			prev_point = target
			wp += 1
		else:
			break
	var steer := 0.0
	if wp < wps.size():
		var err := wrapf((wps[wp].point - pos).angle() - car.model.rotation, -PI, PI)
		steer = clampf(-err * Drive.STEER_GAIN, -1.0, 1.0)
		if absf(steer) < 0.02:
			steer = 0.0
	if car.airborne and absf(car.height - 6.0) < 6.5 and wp >= wps.size() - 1:
		jumped = true
	car.scripted_input = [not jumped, false, steer]
	if jumped and not car.airborne and landed_at < 0:
		landed_at = _steps
	if landed_at >= 0 and _steps - landed_at >= after_landing:
		print("run_camera_height_gif: done after %d steps" % _steps)
		get_tree().quit()
	if _steps % 25 == 0:
		print("run_camera_height_gif: step %d height %.2f camera-to-car %s" % [
			_steps, car.height, run.camera.position - run.car_sprite.position])
