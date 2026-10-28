extends "res://tests/fixtures/run_elevation_demo.gd"
## Screenshot fixture (task T-335): a run from the main menu, then the viewport is
## saved with the HUD hidden (NOHUD_PNG) and with the timer clock at 5:00 (green),
## 2:00 (yellow), 1:00 (orange) and 0:20 (red) (CLOCK_PNG_PREFIX + "_<colour>.png").
## Run it windowed at 1152 x 648. Quits when done.

var _done := false


func _ready() -> void:
	drive_steps = -1
	await super._ready()
	_shoot_all()


func _shoot_all() -> void:
	for i in 20:
		await get_tree().process_frame
	run.hud.visible = false
	await _save("NOHUD_PNG", "")
	run.hud.visible = true
	var prefix := OS.get_environment("CLOCK_PNG_PREFIX")
	for pair in [[300.0, "green"], [120.0, "yellow"], [60.0, "orange"], [20.0, "red"]]:
		run.state.time_left = pair[0]
		run.state.advance(0.0)
		run.hud.timer_label.text = run.state.time_left_text()
		run.hud.timer_clock.set_time_left(pair[0])
		await _save("", prefix + "_" + pair[1] + ".png")
	get_tree().quit()


func _save(var_name: String, path: String) -> void:
	if var_name != "":
		path = OS.get_environment(var_name)
	if path == "":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
