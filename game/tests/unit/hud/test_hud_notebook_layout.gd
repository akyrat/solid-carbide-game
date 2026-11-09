extends GutTest
## Task T-611 (HUD and menus, Decisions, "The notebook can be moved in the HUD layout editor"):
## the mission notebook page is one of the editor's movable pieces: framed (even with no mission
## on the page), dragged with the same snapping and on-screen rule, saved in the settings file's
## hud_layout section, read back by a new run and put back by Reset layout. The pulse (T-606)
## and the falling trick box (T-563) play at its moved place; the tutorial's practice windows keep
## their own notebook place.

const RunScene := preload("res://scenes/run/run.tscn")
const HUD_SCENE := preload("res://scenes/hud/hud.tscn")
const PauseScript := preload("res://scripts/ui/pause_screen.gd")
const SessionScene := preload("res://scenes/run/practice_session.tscn")
var TEST_PATH := RunPaths.file("test_settings_t611_notebook.cfg")
const EPS := 1.5
## The notebook's default place at the 1152 x 648 layout.
const DEFAULT_POS := Vector2(12, 304)
var _old_size := Vector2i.ZERO


func before_each() -> void:
	GameSettings.path = TEST_PATH
	DirAccess.remove_absolute(TEST_PATH)
	GameSettings.hud_layout_writes = 0
	_old_size = get_tree().root.size
	get_tree().root.size = Vector2i(1152, 648)


func after_each() -> void:
	get_tree().paused = false
	get_tree().root.size = _old_size
	DirAccess.remove_absolute(TEST_PATH)
	TestSave.restore_settings()


func _pause_screen() -> CanvasLayer:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	var screen: CanvasLayer = PauseScript.new()
	run.add_child(screen)
	screen.setup(run)
	return screen


func _hud(size := Vector2i(1152, 648), layout := {}) -> Hud:
	var sv := SubViewport.new()
	sv.size = size
	add_child_autofree(sv)
	var hud: Hud = HUD_SCENE.instantiate()
	sv.add_child(hud)
	hud.set_layout(layout)
	return hud


func _screen_rect(hud: Hud, id: String) -> Rect2:
	var r := hud.piece_rect(id)
	return Rect2(hud.root.get_global_transform() * r.position, r.size * hud.hud_scale())


func test_the_notebook_is_a_movable_piece_at_its_default_place() -> void:
	assert_true(HudLayout.PIECES.has("notebook"))
	var hud := _hud()
	await get_tree().process_frame
	assert_eq(hud.piece("notebook"), hud.mission_page)
	var r := hud.piece_rect("notebook")
	assert_almost_eq(r.position, DEFAULT_POS, Vector2(EPS, EPS), "x 12, y 304")
	assert_almost_eq(r.size, MissionPage.PAGE_SIZE, Vector2(EPS, EPS), "its size is unchanged")


func test_the_editor_frames_the_notebook_even_with_no_mission_on_the_page() -> void:
	var ps := _pause_screen()
	await get_tree().process_frame
	var hud: Hud = ps.target.hud
	var ed: HudLayoutEditor = ps.hud_layout_editor
	ps.open_hud_layout()
	hud.mission_page.visible = false  # all missions done: the page is hidden in the run
	var frame := ed.screen_rect("notebook")
	assert_almost_eq(frame.size, MissionPage.PAGE_SIZE * hud.hud_scale(), Vector2(EPS, EPS), "framed")
	assert_true(ed.is_ghost("notebook"), "a hidden page gets its frame filled so it can be seen")
	assert_eq(ed.piece_at(frame.get_center()), "notebook", "and it can be picked up")
	hud.mission_page.visible = true
	assert_false(ed.is_ghost("notebook"), "a shown page is just framed")


func test_a_drag_moves_it_with_the_same_snap_and_on_screen_rule_and_done_saves_it() -> void:
	var ps := _pause_screen()
	await get_tree().process_frame
	var hud: Hud = ps.target.hud
	var ed: HudLayoutEditor = ps.hud_layout_editor
	ps.open_hud_layout()
	var from := ed.screen_rect("notebook").get_center()
	assert_true(ed.press(from), "pressed on the notebook")
	ed.drag_to(from + Vector2(301, 3) * hud.hud_scale())
	var at := hud.piece_rect("notebook").position
	assert_eq(at, HudLayout.snap(DEFAULT_POS + Vector2(301, 3), MissionPage.PAGE_SIZE, hud.root.size),
		"snapped like the others")
	assert_almost_eq(fmod(at.x, HudLayout.GRID), 0.0, 0.01, "on the grid")
	ed.drag_to(from + Vector2(5000, 5000))
	var r := hud.piece_rect("notebook")
	assert_true(Rect2(Vector2.ZERO, hud.root.size).grow(0.01).encloses(r), "never off screen (%s)" % r)
	ed.drag_to(from + Vector2(301, 3) * hud.hud_scale())
	ed.release()
	var moved := hud.piece_rect("notebook")
	assert_false(GameSettings.load_hud_layout().has("notebook"), "not saved before Done")
	ed.done_button.pressed.emit()
	var saved := GameSettings.load_hud_layout()
	assert_true(saved.has("notebook"), "Done wrote the notebook's entry")
	var cfg := ConfigFile.new()
	cfg.load(TEST_PATH)
	assert_true(cfg.has_section_key("hud_layout", "notebook"), "in the hud_layout section")
	var fresh := _hud(Vector2i(1152, 648), saved)
	await get_tree().process_frame
	assert_almost_eq(fresh.piece_rect("notebook").position, moved.position, Vector2(EPS, EPS),
		"a new HUD reads it back")


func test_a_new_run_from_the_game_flow_reads_the_saved_notebook_place() -> void:
	GameSettings.save_hud_layout({"notebook": {"ax": 0.0, "ay": 0.0, "dx": 300.0, "dy": 100.0}})
	var holder := Node.new()
	add_child_autofree(holder)
	var run: Node2D = GameFlow.add_run(holder, PlayerProgress.new())
	await get_tree().process_frame
	assert_eq(run.hud.layout.keys(), ["notebook"])
	assert_almost_eq(run.hud.piece_rect("notebook").position, Vector2(300, 100), Vector2(EPS, EPS))
	assert_almost_eq(run.hud.mission_page.position, Vector2(300, 100), Vector2(EPS, EPS), "the page itself is there")


func test_reset_layout_returns_the_notebook_to_its_default_place() -> void:
	var ps := _pause_screen()
	await get_tree().process_frame
	var hud: Hud = ps.target.hud
	hud.move_piece("notebook", Vector2(600, 200))
	assert_false(hud.piece_rect("notebook").position.is_equal_approx(DEFAULT_POS))
	ps.open_hud_layout()
	ps.hud_layout_editor.reset_button.pressed.emit()
	assert_almost_eq(hud.piece_rect("notebook").position, DEFAULT_POS, Vector2(EPS, EPS), "x 12, y 304 again")
	ps.hud_layout_editor.done_button.pressed.emit()
	assert_false(GameSettings.load_hud_layout().has("notebook"))


func test_the_pulse_scales_the_page_about_its_centre_at_the_moved_place() -> void:
	var hud := _hud()
	await get_tree().process_frame
	var m := RunMissions.new()
	m.start_with([[{"trick": "alternate_drift", "kind": "count", "amount": 3}]])
	hud.mission_page.bind(m)
	hud.move_piece("notebook", Vector2(600, 200))
	var page := hud.mission_page
	var moved_centre := _screen_rect(hud, "notebook").get_center()
	var centre_before := page.get_global_transform() * (page.size * 0.5)
	assert_almost_eq(centre_before, moved_centre, Vector2(EPS, EPS), "the page's centre is the moved piece's centre")
	var pos_before := page.position
	page.pulse()
	page.advance(page._pulse_seconds * 0.5)  # the peak
	assert_gt(page.scale.x, 1.0, "grown")
	assert_eq(page.position, pos_before, "its position does not move")
	var centre_peak := page.get_global_transform() * (page.size * 0.5)
	assert_almost_eq(centre_peak, centre_before, Vector2(0.01, 0.01), "scaled about its own centre")


func test_the_falling_box_lands_in_the_page_at_the_moved_place() -> void:
	var hud := _hud()
	await get_tree().process_frame
	var m := RunMissions.new()
	m.start_with([[{"trick": "alternate_drift", "kind": "count", "amount": 3}]])
	var page := hud.mission_page
	page.bind(m)
	hud.move_piece("notebook", Vector2(600, 200))
	m.on_trick("alternate_drift")
	assert_true(page.is_falling())
	var f: Dictionary = page._falls[0]
	var land := Vector2(float(f["x"]) + float(f["w"]) * 0.5, float(f["land_y"]) + MissionPage.BOX_H * 0.5)
	var on_screen := page.get_global_transform() * land
	var rect := _screen_rect(hud, "notebook")
	assert_true(rect.grow(0.5).has_point(on_screen), "the landing spot %s is in the moved page %s" % [on_screen, rect])
	var start := page.get_global_transform() * Vector2(0, MissionPage.BOX_START_Y)
	assert_lt(start.y, rect.position.y, "it starts above the moved page's top")
	page.finish_falls()
	assert_eq(page.rows[0].label.text, "Alt drifts 1/3", "and the count updates there")


func test_the_tutorials_notebook_ignores_a_saved_layout() -> void:
	var before: Vector2 = await _practice_notebook_place()
	GameSettings.save_hud_layout({"notebook": {"ax": 0.0, "ay": 0.0, "dx": 500.0, "dy": 50.0}})
	var after: Vector2 = await _practice_notebook_place()
	assert_eq(after, before, "the same place with and without a layout that moves the notebook")


func _practice_notebook_place() -> Vector2:
	var session = SessionScene.instantiate()
	add_child_autofree(session)
	await get_tree().process_frame
	var place: Vector2 = session.notebook.get_global_position()
	session.queue_free()
	await get_tree().process_frame
	return place
