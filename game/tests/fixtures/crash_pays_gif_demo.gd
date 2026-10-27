extends "res://tests/fixtures/run_elevation_demo.gd"
## GIF fixture (task T-315): a drift that ends in a crash, in a run started from
## the main menu on the elevation map, with trick detection on. The car drifts
## (W and A held from the first step) into the south face of the building at
## (12, -96, 30 x 30); the crash pays the drift so far, so LONG DRIFT! shows
## just before COMBO BROKEN!. A combo is built first (combo_tricks ALT DRIFT!s
## are added at the start), so the cut is visible on the HUD's counter.
## After the hit the keys are let go; after_hit frames later the scene quits.
## popup_frame frames after the hit the viewport is saved to the absolute path
## in the environment variable CRASH_PAYS_POPUP_PNG (if set).
##   "$GODOT_BIN" --path game --fixed-fps 50 --write-movie C:/abs/dir/f.png res://tests/fixtures/crash_pays_gif.tscn
## then: python game/tools/make_turn_gif.py C:/abs/dir out.gif --glob "f*.png" --every 2 --size 640 420 --scale 1 --ms 40
## CRASH_START="x,y,rotation" overrides the start (for finding a spot headless).

@export var after_hit := 60
@export var popup_frame := 8
@export var combo_tricks := 2
@export var max_steps := 400

var _frames := 0
var _hit_frame := -1


func _ready() -> void:
	steer_from = 0
	drive_steps = 1000000
	var env := OS.get_environment("CRASH_START")
	if env != "":
		var p := env.split(",")
		start_units = Vector2(float(p[0]), float(p[1]))
		start_rotation = float(p[2])
	await super._ready()
	var car: CharacterBody2D = run.car
	car.detect_tricks = true
	car.tricks.reset()
	car.scripted_input = [true, false, steer]
	for i in combo_tricks:
		run.state.add_trick("alternate_drift")
	run.state.combo_trick.connect(func(id: String, added: float, m: float) -> void:
		print("crash_pays_gif_demo: trick %s at step %d, %.2f s, +%.2f, combo %.2f" % [id, _steps, car.tricks.last_trick_seconds, added, m]))
	run.state.combo_broken.connect(func() -> void:
		print("crash_pays_gif_demo: COMBO BROKEN at step %d, combo %.2f" % [_steps, run.state.combo]))
	car.hit_obstacle.connect(func(_c, _i, _n, impact: float) -> void:
		if _hit_frame < 0:
			_hit_frame = _frames
			print("crash_pays_gif_demo: hit at step %d, impact %.2f, airborne %s, at %s" % [_steps, impact, car.airborne, car.model.get_position()])
			car.scripted_input = [false, false, 0.0])


func _on_stepped() -> void:
	_steps += 1
	if _steps >= max_steps and _hit_frame < 0:
		print("crash_pays_gif_demo: no hit in %d steps" % max_steps)
		get_tree().quit()


func _process(delta: float) -> void:
	super._process(delta)
	if run == null:
		return
	_frames += 1
	if _hit_frame < 0:
		return
	var since := _frames - _hit_frame
	if since == popup_frame:
		var path := OS.get_environment("CRASH_PAYS_POPUP_PNG")
		if path != "":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(path)
	if since >= after_hit:
		get_tree().quit()
