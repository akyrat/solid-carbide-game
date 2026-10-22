extends "res://tests/fixtures/air_trick_gif_demo.gd"
## Screenshot and GIF fixture (task T-243): a jump off a rooftop in a run from
## the main menu (as air_trick_gif_demo.gd), with the HUD's airtime counter
## counting. At `shot_air_step` steps in the air it saves the viewport to the
## absolute path in the environment variable AIRTIME_PNG (if set). Record the
## GIF with Godot's movie maker as the air trick GIFs do.

@export var shot_air_step := 30

var _shot_done := false


func _process(delta: float) -> void:
	super._process(delta)
	if run == null or _shot_done or _air_steps < shot_air_step:
		return
	_shot_done = true
	var path := OS.get_environment("AIRTIME_PNG")
	if path != "":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(path)
		print("airtime_counter_demo: screenshot %s, counter %s" % [path, run.hud.airtime_counter.number_label.text])
