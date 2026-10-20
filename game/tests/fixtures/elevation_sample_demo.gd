extends Node
## Test fixture for screenshots of the elevation sample map (task T-196): runs
## the scene with W held instead of the keyboard, from a chosen start, and
## stops the car after drive_steps physics steps so the screenshot shows that
## moment (on the street, on a ramp, on a rooftop, in the air).

## Where the car starts, flat units, and its heading (0 east, PI / 2 south).
@export var start_units := Vector2(-81, -50)
@export var start_rotation := -PI / 2.0
## Physics steps with W held before the car stops.
@export var drive_steps := 5
## Camera zoom (orthographic size); 0 keeps the saved zoom.
@export var zoom := 0.0
## Units above the ground at the start: the car is put in the air that high
## and stays there (use drive_steps 1).
@export var lift_units := 0.0
## Whether W is held (false: the car stands still for drive_steps steps, so
## the see-through areas have time to fade, task T-197).
@export var hold_w := true

var scene: Node2D
var _steps := 0


func _ready() -> void:
	scene = preload("res://scenes/elevation_sample/elevation_sample_map.tscn").instantiate()
	add_child(scene)
	scene.car.use_keyboard = false
	scene.car.detect_tricks = false
	scene.car.scripted_input = [hold_w, false, 0.0]
	scene.place_car(start_units, start_rotation)
	if lift_units > 0.0:
		scene.car.height_model.height = scene.car.height + lift_units
		scene.car.height_model.airborne = true
		scene.car.scripted_input = [false, false, 0.0]
	if zoom > 0.0:
		# A fixed zoom: the saved dynamic camera would override it (T-197).
		scene.camera_follow.dynamic = false
		scene.camera_follow.set_base_size(zoom)
	scene.sync_view()
	scene.car.stepped.connect(_on_stepped)


func _on_stepped() -> void:
	_steps += 1
	if _steps >= drive_steps:
		scene.car.set_physics_process(false)
		print("elevation_sample_demo: stopped at %s, height %.2f, airborne %s, ground %.2f" % [
			scene.car.model.get_position(), scene.car.height, scene.car.airborne,
			scene.ground_height.height_at(scene.car.model.get_position())])
