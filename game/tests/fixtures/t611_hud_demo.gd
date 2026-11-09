extends Node
## Screenshot fixture for T-611: a run's HUD with the timer at the top centre. `mode` is
## "start" (the HUD at the start of a run), "editing" (the layout editor open with the notebook
## being dragged) or "moved" (the notebook moved with the editor, saved, and a new run built from
## the saved settings). Saved to art-archive/T-611/screenshots/<out_name>.png. The saves point at
## fixture files, never the player's own.

@export var mode := "start"
@export var out_name := "start"
@export var frames := 40


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameSettings.path = "user://t611_fixture_settings.cfg"
	PlayerProgress.path = "user://t611_fixture_progress.json"
	RunHistory.path = "user://t611_fixture_history.json"
	DirAccess.remove_absolute(GameSettings.path)
	var sv := SubViewport.new()
	sv.size = Vector2i(1152, 648)
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sv)
	var run: Node2D = GameFlow.add_run(sv, PlayerProgress.new())
	await get_tree().process_frame
	_fill(run)
	if mode != "start":
		var ps: CanvasLayer = run.get_node("PauseScreenLayer")
		ps.pause()
		ps.open_hud_layout()
		var ed: HudLayoutEditor = ps.hud_layout_editor
		var grab := ed.screen_rect("notebook").get_center()
		ed.press(grab)
		ed.drag_to(grab + Vector2(790, -180) * run.hud.hud_scale())
		if mode == "moved":
			ed.release()
			ed.finish()
			ps.resume()
			run.queue_free()
			await get_tree().process_frame
			run = GameFlow.add_run(sv, PlayerProgress.new())
			await get_tree().process_frame
			_fill(run)
	for i in frames:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := sv.get_texture().get_image()
	var dir := ProjectSettings.globalize_path("res://").path_join("../art-archive/T-611/screenshots").simplify_path()
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join(out_name + ".png")
	img.save_png(path)
	print("t611 fixture: saved %dx%d to %s (layout %s)" % [img.get_width(), img.get_height(), path, GameSettings.load_hud_layout()])
	get_tree().paused = false
	get_tree().quit()


func _fill(run: Node2D) -> void:
	var state: RunState = run.state
	state.damage_car(state.max_health * 0.4)
	state.add_xp(state.xp_needed() * 0.6)
	state.add_coins(37)
	for i in 3:
		state.add_trick("alternate_drift")
