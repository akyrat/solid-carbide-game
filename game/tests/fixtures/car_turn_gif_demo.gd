extends "res://tests/fixtures/run_elevation_demo.gd"
## GIF fixture (task T-102): a run started from the main menu (as
## run_elevation_demo.gd), the car stopped after one physics step, then turned
## slowly clockwise through a full circle, one viewport image saved per step,
## so the 32 directions can be seen turning in the game. With lift_units > 0
## the car stays in the air (its shadowless frames).
## Images go to the folder in the environment variable TURN_GIF_DIR (absolute
## path), as turn_000.png, turn_001.png, ...; the scene quits when done.
## Run it with a window (not --headless):
##   TURN_GIF_DIR=C:/abs/dir "$GODOT_BIN" --path game res://tests/fixtures/car_turn_gif_run.tscn
## then assemble the GIF with game/tools/make_turn_gif.py.

## Images per full circle (3.75 degrees apart at 96, about 3 per sheet frame).
@export var steps_per_circle := 96
## Frames to wait before the first image (the run settles).
@export var warmup_frames := 30

var _frame := 0
var _shot := 0
var _out_dir := ""
var _busy := false


func _ready() -> void:
	drive_steps = 1
	hold_w = false
	_out_dir = OS.get_environment("TURN_GIF_DIR")
	await super._ready()


func _process(delta: float) -> void:
	super._process(delta)
	if run == null or _busy:
		return
	_frame += 1
	if _frame < warmup_frames:
		return
	if _shot >= steps_per_circle:
		get_tree().quit()
		return
	_busy = true
	var car: CharacterBody2D = run.car
	car.model.rotation = start_rotation + TAU * float(_shot) / float(steps_per_circle)
	car._sync_from_model()
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	if _out_dir != "":
		var img := get_viewport().get_texture().get_image()
		img.save_png(_out_dir.path_join("turn_%03d.png" % _shot))
	print("car_turn_gif_demo: shot %d, frame %d of %d, in air %s" % [
		_shot, run.car_sprite.frame, run.car_sprite.hframes, run.car_sprite.in_air])
	_shot += 1
	_busy = false
