extends "res://tests/fixtures/run_elevation_demo.gd"
## GIF fixture (task T-246): a long drift in a run started from the main menu
## on the elevation map, with trick detection on, so the run's combo and popups
## react as in play. The car drives with W and A held for drift_steps physics
## steps (a drift), then lets go; the drift pays once, as it ends, with a
## LONG DRIFT! popup and its amount. popup_frame frames after the release the
## viewport is saved to the absolute path in the environment variable
## DRIFT_PAY_POPUP_PNG (if set); after_release frames after it the scene quits.
##   "$GODOT_BIN" --path game --fixed-fps 50 --write-movie C:/abs/dir/f.png res://tests/fixtures/drift_pay_gif.tscn
## then: python game/tools/make_turn_gif.py C:/abs/dir out.gif --glob "f*.png" --every 2 --size 640 420 --scale 1 --ms 40

@export var after_release := 60
@export var popup_frame := 12

var _frames := 0
var _released := -1


func _ready() -> void:
	steer_from = 0
	await super._ready()
	var car: CharacterBody2D = run.car
	car.detect_tricks = true
	car.tricks.reset()
	car.scripted_input = [true, false, steer]
	car.trick.connect(func(id: String) -> void:
		print("drift_pay_gif_demo: trick %s at frame %d, %.2f s, combo %.2f" % [id, _frames, car.tricks.last_trick_seconds, run.state.combo]))


func _on_stepped() -> void:
	_steps += 1
	if _steps == drive_steps:
		run.car.scripted_input = [true, false, 0.0]
		_released = _frames


func _process(delta: float) -> void:
	super._process(delta)
	if run == null:
		return
	_frames += 1
	if _released < 0:
		return
	var since := _frames - _released
	if since == popup_frame:
		var path := OS.get_environment("DRIFT_PAY_POPUP_PNG")
		if path != "":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(path)
	if since >= after_release:
		get_tree().quit()
