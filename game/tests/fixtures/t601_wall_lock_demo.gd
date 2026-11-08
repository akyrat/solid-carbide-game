extends Node
## Screenshot fixture (task T-601, the car never locks against a wall): the elevation test scene,
## the car driven nose first into the platform's south side with W held (pin_steps physics steps,
## pressed on it), then W with A or D (steer) held: the car turns off the side and drives away.
## Run it with game/tools/screenshot.sh for each frame of a GIF: the output file's name ends in the
## physics step to show (".../step_045.png" stops the car after step 45, so the shot shows that
## step however fast the window renders); give enough frames (400) for the car to get there.

@export var start_units := Vector2(0, 13)
@export var start_rotation := -1.5708
@export var pin_steps := 70
## +1 = A, -1 = D.
@export var steer := 1.0
@export var zoom := 10.0

var scene: Node2D
var _steps := 0
var _stop_step := 0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			var m := RegEx.create_from_string("step_([0-9]+)[.]png$").search(arg)
			if m != null:
				_stop_step = int(m.get_string(1))
	scene = preload("res://scenes/elevation_test/elevation_test.tscn").instantiate()
	add_child(scene)
	scene.car.use_keyboard = false
	scene.car.scripted_input = [true, false, 0.0]
	for a in scene.areas:
		a.see_through_alpha = 1.0
	scene.place_car(start_units, start_rotation)
	if zoom > 0.0:
		scene.camera_follow.set_base_size(zoom)
	scene.sync_view()
	scene.car.stepped.connect(_on_stepped)


func _on_stepped() -> void:
	_steps += 1
	if _steps == pin_steps:
		scene.car.scripted_input = [true, false, steer]
	if _stop_step > 0 and _steps >= _stop_step:
		scene.car.set_physics_process(false)
	print("t601_wall_lock_demo: step %d at %s heading %.1f" % [
		_steps, scene.car.model.get_position(), rad_to_deg(scene.car.model.rotation)])
