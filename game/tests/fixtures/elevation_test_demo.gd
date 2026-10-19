extends Node
## Test fixture for screenshots of the elevation test scene (task T-185): runs
## the scene with W held instead of the keyboard, from a chosen start, and
## stops the car after drive_steps physics steps so the screenshot shows that
## moment (on the street, on the ramp, on the platform, in the air past a
## drop-off edge).

## Where the car starts, flat units, and its heading (0 east, PI / 2 south).
@export var start_units := Vector2(26, 0)
@export var start_rotation := PI
## Physics steps with W held before the car stops.
@export var drive_steps := 5
## Camera zoom (orthographic size); 0 keeps the saved zoom.
@export var zoom := 0.0
## False keeps the raised areas solid (task T-191): the screenshot then shows
## the depth order alone (the car drawn under or over them).
@export var see_through := true

var scene: Node2D
var _steps := 0


func _ready() -> void:
	scene = preload("res://scenes/elevation_test/elevation_test.tscn").instantiate()
	add_child(scene)
	scene.car.use_keyboard = false
	scene.car.scripted_input = [true, false, 0.0]
	if not see_through:
		for a in scene.areas:
			a.see_through_alpha = 1.0
	scene.place_car(start_units, start_rotation)
	if zoom > 0.0:
		scene.camera_follow.set_base_size(zoom)
	scene.sync_view()
	scene.car.stepped.connect(_on_stepped)


func _on_stepped() -> void:
	_steps += 1
	if _steps >= drive_steps:
		scene.car.set_physics_process(false)
		print("elevation_test_demo: stopped at %s, height %.2f, airborne %s" % [
			scene.car.model.get_position(), scene.car.height, scene.car.airborne])
