extends Node
## Screenshot and GIF fixture for Jump (task T-461): a run started from the
## main menu with Jump granted at `tier`, the car stepped once per drawn frame
## so frame N is physics step N: W alone for `drive_steps`, then a Space press
## (press_jump()), W still held, steering A in the air (`spin`) until the car
## lands, then W alone. With `record_dir` set (relative to the repo root, or
## a res://, user:// or absolute path),
## every `record_every`th frame is saved there as a PNG (frames for
## frames_to_gif.py) until `record_frames`.

@export var tier := 4
@export var drive_steps := 40
@export var spin := true
@export var record_dir := ""
@export var record_every := 2
@export var record_frames := 0

var game: Node
var car: CharacterBody2D
var _step := 0


func _ready() -> void:
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.start_run()  # straight into a run, past the tutorial slides (T-387)
	for i in tier:
		game.run.state.grant_power_up("jump")
	car = game.run.car
	car.use_keyboard = false
	car.set_physics_process(false)
	if record_dir != "":
		if record_dir.begins_with("res://") or record_dir.begins_with("user://"):
			record_dir = ProjectSettings.globalize_path(record_dir)
		elif record_dir.is_relative_path():
			# Relative to the repo root (the folder above game/).
			record_dir = ProjectSettings.globalize_path("res://").path_join("..").path_join(record_dir).simplify_path()
		DirAccess.make_dir_recursive_absolute(record_dir)


func _process(_delta: float) -> void:
	if car == null or not is_instance_valid(car):
		return
	if _step == drive_steps:
		car.press_jump()
	var steer := 1.0 if spin and car.airborne else 0.0
	car.scripted_input = [true, false, steer]
	car.physics_step()
	_step += 1
	if record_dir != "" and _step <= record_frames and _step % record_every == 0:
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png(record_dir.path_join("frame_%04d.png" % _step))
