extends "res://tests/fixtures/run_elevation_demo.gd"
## GIF fixture (task T-219): an aerial trick in a run started from the main
## menu on the elevation map (as run_elevation_demo.gd), with trick detection
## on, so the run's combo and popups react as in play.
##
## - drive_off_edge true: the car drives with W held from start_units at
##   start_rotation, off a rooftop's side; from the step it is in the air it
##   also holds `steer` (W with A or D) until it lands, then lets go of the
##   steering and keeps W.
## - drive_off_edge false: the car is let go lift_units above the ground at
##   start_units, standing, and holds `steer` until it lands (a staged drop:
##   nothing on today's map is that high).
##
## after_landing frames after the landing the scene quits. At popup_frame
## frames after the landing it saves the viewport to the absolute path in the
## environment variable AIR_TRICK_POPUP_PNG (if set). Record the frames with
## Godot's movie maker, one physics step per frame:
##   "$GODOT_BIN" --path game --fixed-fps 50 --write-movie C:/abs/dir/f.png res://tests/fixtures/air_trick_gif_180.tscn
## then assemble the GIF with game/tools/make_turn_gif.py --glob "f*.png".

@export var drive_off_edge := true
@export var after_landing := 45
@export var popup_frame := 14

var _was_airborne := false
var _landed_frame := -1
var _frames := 0
var _air_steps := 0
var _turned := 0.0
var _rotation_before := 0.0


func _ready() -> void:
	drive_steps = -1
	steer_from = -1
	await super._ready()
	var car: CharacterBody2D = run.car
	car.detect_tricks = true
	car.tricks.reset()
	if drive_off_edge:
		car.scripted_input = [true, false, 0.0]
	else:
		car.scripted_input = [false, false, steer]
	_was_airborne = car.airborne
	_rotation_before = car.model.rotation
	car.trick.connect(func(id: String) -> void:
		print("air_trick_gif_demo: trick %s at frame %d, combo %.2f" % [id, _frames, run.state.combo]))


func _on_stepped() -> void:
	var car: CharacterBody2D = run.car
	if car.airborne:
		_air_steps += 1
		_turned += car.model.rotation - _rotation_before
	_rotation_before = car.model.rotation
	if car.airborne and not _was_airborne and drive_off_edge:
		car.scripted_input = [true, false, steer]
	if not car.airborne and _was_airborne:
		_landed_frame = _frames
		car.scripted_input = [drive_off_edge, false, 0.0]
		print("air_trick_gif_demo: landed at frame %d after %d steps in the air, turned %.1f degrees" % [
			_frames, _air_steps, rad_to_deg(absf(_turned))])
	_was_airborne = car.airborne


func _process(delta: float) -> void:
	super._process(delta)
	if run == null:
		return
	_frames += 1
	if _landed_frame < 0:
		return
	var since := _frames - _landed_frame
	if since == popup_frame:
		var path := OS.get_environment("AIR_TRICK_POPUP_PNG")
		if path != "":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(path)
			print("air_trick_gif_demo: popup screenshot %s" % path)
	if since >= after_landing:
		get_tree().quit()
