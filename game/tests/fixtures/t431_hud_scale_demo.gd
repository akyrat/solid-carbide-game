extends Node
## Screenshot fixture for T-431: a run at a given window size and HUD size, drawn in a
## SubViewport of that size (so 2560 x 1440 and the 3440 x 1440 ultrawide work on any monitor)
## and saved straight to art-archive/T-431/screenshots/<out_name>.png. With `paused` the pause
## screen is open with the HUD size slider at `hud_size`. The saves point at fixture files, never
## the player's own.

@export var shot_size := Vector2i(1152, 648)
@export var hud_size := 100.0
@export var paused := false
@export var out_name := "hud"
@export var frames := 40


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameSettings.path = "user://t431_fixture_settings.cfg"
	PlayerProgress.path = "user://t431_fixture_progress.json"
	RunHistory.path = "user://t431_fixture_history.json"
	DirAccess.remove_absolute(GameSettings.path)
	var sv := SubViewport.new()
	sv.size = shot_size
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sv)
	var run: Node2D = GameFlow.add_run(sv, PlayerProgress.new())
	await get_tree().process_frame
	var state: RunState = run.state
	state.damage_car(state.max_health * 0.4)
	state.add_xp(state.xp_needed() * 0.6)
	state.add_coins(37)
	for i in 12:
		state.add_trick("alternate_drift")
	run.hud.set_hud_size(hud_size)
	if paused:
		var ps: CanvasLayer = run.get_node("PauseScreenLayer")
		ps.pause()
		ps.hud_size_slider.value = hud_size
	for i in frames:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := sv.get_texture().get_image()
	var dir := ProjectSettings.globalize_path("res://").path_join("../art-archive/T-431/screenshots").simplify_path()
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join(out_name + ".png")
	img.save_png(path)
	print("t431 fixture: saved %dx%d to %s (HUD scale %.3f)" % [img.get_width(), img.get_height(), path, run.hud.hud_scale()])
	get_tree().paused = false
