extends "res://tests/fixtures/run_elevation_demo.gd"
## Screenshot and GIF fixture (task T-247): a run from the main menu on the
## elevation map's layout (as run_elevation_demo.gd). The car drives straight
## for `lead_steps` steps, drifts (W with A/D) for `drift_steps` steps, then
## straightens and the scene quits `after` steps later, so the HUD's drift counter
## counts up and disappears. Drifting stops in the air (T-219), so both counters
## cannot show at once in play; once the counter reads `shot_drift_time` seconds
## DRIFT_PNG gets the viewport (if set), and DRIFT_BOTH_PNG the same with the
## airtime counter shown too (staged: its number set by hand).
## Record the GIF with Godot's movie maker as the other GIF fixtures do.

@export var lead_steps := 40
@export var drift_steps := 90
@export var after := 40
@export var shot_drift_time := 1.0

var _n := 0
var _shots_done := false
var _stage_air := false


func _ready() -> void:
	drive_steps = -1
	steer_from = -1
	await super._ready()
	# After the HUD's own step (it connected first): stage the airtime counter.
	run.car.stepped.connect(func() -> void:
		if _stage_air:
			run.hud.airtime_counter.step(true, 0.6))


func _process(delta: float) -> void:
	super._process(delta)
	if run == null:
		return
	_n += 1
	var car: CharacterBody2D = run.car
	var drift_step := _n - lead_steps
	if drift_step == 0:
		car.scripted_input = [true, false, steer]
	elif drift_step == drift_steps:
		car.scripted_input = [true, false, 0.0]
	if run.hud.drift_counter.drift_time >= shot_drift_time and not _shots_done:
		_shots_done = true
		await _shoot("DRIFT_PNG")
		_stage_air = true
		await get_tree().physics_frame
		await get_tree().physics_frame
		await _shoot("DRIFT_BOTH_PNG")
		_stage_air = false
	if drift_step >= drift_steps + after:
		get_tree().quit()


func _shoot(var_name: String) -> void:
	var path := OS.get_environment(var_name)
	if path == "":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("drift_counter_demo: %s, drift %s" % [path, run.hud.drift_counter.number_label.text])
