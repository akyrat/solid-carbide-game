extends Node
## Screenshot fixture for T-453: a run with the player's HUD layout. It drags four pieces the
## way the editor does (the clock to the top centre, the viewers counter to the right edge's
## middle, the sub goal to the left edge under the weapons, the coins to the bottom centre),
## saves the layout through the editor's Done, then either keeps the editor open mid-drag
## (`editing`) or rebuilds the run from the saved settings and shows it running. Drawn in a
## SubViewport of `shot_size` and saved to art-archive/T-453/screenshots/<out_name>.png. The saves
## point at fixture files, never the player's own.

@export var shot_size := Vector2i(1152, 648)
@export var hud_size := 100.0
@export var editing := false
@export var out_name := "layout"
@export var frames := 40


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameSettings.path = "user://t453_fixture_settings.cfg"
	PlayerProgress.path = "user://t453_fixture_progress.json"
	RunHistory.path = "user://t453_fixture_history.json"
	DirAccess.remove_absolute(GameSettings.path)
	GameSettings.save_hud_size(hud_size)
	var sv := SubViewport.new()
	sv.size = shot_size
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sv)
	var run: Node2D = GameFlow.add_run(sv, PlayerProgress.new())
	await get_tree().process_frame
	_fill(run)
	var ps: CanvasLayer = run.get_node("PauseScreenLayer")
	ps.pause()
	ps.open_hud_layout()
	var ed: HudLayoutEditor = ps.hud_layout_editor
	_drag(ed, "clock", func(a: Vector2, s: Vector2): return Vector2(a.x / 2.0 - s.x / 2.0, 16.0))
	_drag(ed, "viewers", func(a: Vector2, s: Vector2): return Vector2(a.x - s.x - 16.0, a.y / 2.0 - s.y / 2.0))
	_drag(ed, "sub_goal", func(a: Vector2, s: Vector2): return Vector2(170.0, a.y - s.y - 16.0))
	_drag(ed, "coins", func(a: Vector2, s: Vector2): return Vector2(a.x / 2.0 - s.x / 2.0, a.y - s.y - 16.0))
	if editing:
		# Mid-drag: the hearts held a little right of their place, so the drag frame shows.
		var r := ed.screen_rect("hearts")
		ed.press(r.get_center())
		ed.drag_to(r.get_center() + Vector2(120, 8) * run.hud.hud_scale())
	else:
		ed.finish()
		ps.resume()
		run.queue_free()
		await get_tree().process_frame
		run = GameFlow.add_run(sv, PlayerProgress.new())  # the next run, from the saved settings
		await get_tree().process_frame
		_fill(run)
	for i in frames:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := sv.get_texture().get_image()
	var dir := ProjectSettings.globalize_path("res://").path_join("../art-archive/T-453/screenshots").simplify_path()
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join(out_name + ".png")
	img.save_png(path)
	print("t453 fixture: saved %dx%d to %s (layout %s)" % [img.get_width(), img.get_height(), path, GameSettings.load_hud_layout()])
	get_tree().paused = false


func _fill(run: Node2D) -> void:
	var state: RunState = run.state
	state.damage_car(state.max_health * 0.4)
	state.add_xp(state.xp_needed() * 0.6)
	state.add_coins(37)
	for i in 12:
		state.add_trick("alternate_drift")


## Drags a piece in the editor, as the mouse would, to where `to(area, size)` says (layout pixels).
func _drag(ed: HudLayoutEditor, id: String, to: Callable) -> void:
	var hud: Hud = ed.hud
	var r := hud.piece_rect(id)
	var target: Vector2 = to.call(hud.root.size, r.size)
	var grab := ed.screen_rect(id).get_center()
	ed.press(grab)
	ed.drag_to(grab + (target - r.position) * hud.hud_scale())
	ed.release()
