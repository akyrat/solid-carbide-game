extends GutTest
## Task T-453: the player moves the HUD's pieces from the pause screen. The pause screen's
## "Edit HUD layout" button opens an editor over the paused run; dragging a piece moves it
## (snapped, kept fully on screen), Reset puts the default layout back, Done saves the layout
## once to the settings file, and the next HUD built with the saved layout shows the pieces at
## their new places, at any window size and HUD size.

const RunScene := preload("res://scenes/run/run.tscn")
const HUD_SCENE := preload("res://scenes/hud/hud.tscn")
const PauseScript := preload("res://scripts/ui/pause_screen.gd")
const WeaponsScript := preload("res://scripts/weapons/weapons.gd")
var TEST_PATH := RunPaths.file("test_settings_t453_layout.cfg")
## Screen pixels of slack (pieces round to whole pixels).
const EPS := 1.5
var _old_size := Vector2i.ZERO


func before_each() -> void:
	GameSettings.path = TEST_PATH
	DirAccess.remove_absolute(TEST_PATH)
	GameSettings.hud_layout_writes = 0
	_old_size = get_tree().root.size
	get_tree().root.size = Vector2i(1152, 648)  # the headless window is tiny


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


## A HUD in a window of `size` at `hud_size`, with all five weapons (the tallest column).
func _hud_at(size: Vector2i, hud_size := 100.0, layout := {}) -> Hud:
	var sv := SubViewport.new()
	sv.size = size
	add_child_autofree(sv)
	var hud: Hud = HUD_SCENE.instantiate()
	sv.add_child(hud)
	hud.set_hud_size(hud_size)
	hud.set_layout(layout)
	var rack: Node = WeaponsScript.new()
	add_child_autofree(rack)
	for i in 5:
		rack.get_weapon(rack.weapons.keys()[i]).set_tier(1 + i)
	hud.bind_weapons(rack)
	return hud


func _defaults(hud: Hud) -> Dictionary:
	var out := {}
	for id in HudLayout.PIECES:
		out[id] = hud.piece_rect(id)
	return out


func _file_text(key: String) -> String:
	var f := FileAccess.open("res://data/pause_text.json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	return data[key]


# --- HudLayout, the stored entries --------------------------------------------------------

func test_entry_keeps_the_nearest_corner_and_round_trips() -> void:
	var area := Vector2(1152, 648)
	var size := Vector2(200, 72)
	var e := HudLayout.entry_for(Vector2(936, 560), size, area)
	assert_eq([e.ax, e.ay], [1.0, 1.0], "bottom right third: the bottom-right corner")
	assert_almost_eq(HudLayout.position_for(e, size, area), Vector2(936, 560), Vector2(0.01, 0.01))
	var wide := Vector2(2000, 648)
	assert_almost_eq(HudLayout.position_for(e, size, wide), Vector2(1784, 560), Vector2(0.01, 0.01),
		"keeps its margins to the corner on a wider area")
	var c := HudLayout.entry_for(Vector2(476, 20), size, area)
	assert_eq([c.ax, c.ay], [0.5, 0.0], "top centre")
	assert_almost_eq(HudLayout.position_for(c, size, wide).x, (2000.0 - 200.0) / 2.0, 0.01, "stays centred")


func test_snap_grid_edges_and_on_screen() -> void:
	var area := Vector2(1152, 648)
	var size := Vector2(100, 50)
	assert_eq(HudLayout.snap(Vector2(301, 203), size, area), Vector2(300, 204), "on the 4 px grid")
	assert_eq(HudLayout.snap(Vector2(25, 9), size, area), Vector2(16, 16), "at the edge margin when near")
	assert_eq(HudLayout.snap(Vector2(1040, 590), size, area), Vector2(1036, 582), "the far margins too")
	assert_eq(HudLayout.snap(Vector2(-500, 900), size, area), Vector2(0, 598), "never off screen")


func test_clean_drops_bad_entries() -> void:
	var l := HudLayout.clean({"clock": {"ax": 0, "ay": 1, "dx": 5, "dy": -3},
		"coins": {"ax": 2.0, "ay": 0, "dx": 0, "dy": 0}, "nope": {"ax": 0, "ay": 0, "dx": 0, "dy": 0},
		"hearts": "x"})
	assert_eq(l.keys(), ["clock"])
	assert_eq(l.clock, {"ax": 0.0, "ay": 1.0, "dx": 5.0, "dy": -3.0})


# --- The editor ---------------------------------------------------------------------------

func test_button_and_editor_texts_are_the_files() -> void:
	var ps := _pause_screen()
	assert_not_null(ps.hud_layout_button, "the pause screen has the button")
	assert_eq(ps.hud_layout_button.text, _file_text("hud_layout_button"))
	assert_true(HudStyle.is_shared_button(ps.hud_layout_button), "the shared button (T-446)")
	var ed: HudLayoutEditor = ps.hud_layout_editor
	assert_eq(ed.hint_label.text, _file_text("hud_layout_hint"))
	assert_eq(ed.reset_button.text, _file_text("hud_layout_reset"))
	assert_eq(ed.done_button.text, _file_text("hud_layout_done"))
	assert_true(HudStyle.is_shared_button(ed.reset_button) and HudStyle.is_shared_button(ed.done_button))


func test_open_hides_the_strip_and_done_brings_it_back() -> void:
	var ps := _pause_screen()
	ps.pause()
	ps.hud_layout_button.pressed.emit()
	assert_true(ps.is_hud_layout_open())
	assert_false(ps.strip.visible, "the strip makes way for the HUD")
	assert_true(get_tree().paused, "the run stays paused")
	ps.hud_layout_editor.done_button.pressed.emit()
	assert_false(ps.is_hud_layout_open())
	assert_true(ps.strip.visible and ps.visible, "back on the pause screen")
	assert_eq(GameSettings.hud_layout_writes, 1, "Done saves once")


func test_escape_while_editing_is_done() -> void:
	var ps := _pause_screen()
	ps.pause()
	ps.open_hud_layout()
	var ev := InputEventAction.new()
	ev.action = "pause"
	ev.pressed = true
	ps._input(ev)
	assert_false(ps.is_hud_layout_open(), "Escape finishes editing")
	assert_true(get_tree().paused and ps.visible, "still paused, on the pause screen")
	assert_eq(GameSettings.hud_layout_writes, 1)


func test_moved_in_the_editor_saved_and_found_in_a_new_hud() -> void:
	var ps := _pause_screen()
	await get_tree().process_frame
	ps.pause()
	ps.open_hud_layout()
	var ed: HudLayoutEditor = ps.hud_layout_editor
	var hud: Hud = ps.target.hud
	var clock := ed.screen_rect("clock")
	var grab := clock.get_center()
	# Drag the clock from the bottom left to the top centre (layout pixels = screen at 1152 x 648).
	assert_true(ed.press(grab), "the clock is under the pointer")
	ed.drag_to(grab + Vector2(300, -200))
	ed.drag_to(grab + Vector2(401, -499))
	ed.release()
	var moved := hud.piece_rect("clock")
	assert_almost_eq(moved.position, HudLayout.snap(clock.position / hud.hud_scale() + Vector2(401, -499) / hud.hud_scale(),
		moved.size, hud.root.size), Vector2(EPS, EPS), "the clock followed the drag, snapped")
	assert_false(GameSettings.load_hud_layout().has("clock"), "not saved before Done")
	ed.finish()
	var saved := GameSettings.load_hud_layout()
	assert_true(saved.has("clock"), "Done saved the clock's place")
	# A new HUD (the next run) built with the saved layout shows the clock at the new place.
	var fresh := _hud_at(Vector2i(1152, 648), 100.0, saved)
	await get_tree().process_frame
	assert_almost_eq(fresh.piece_rect("clock").position, moved.position, Vector2(EPS, EPS),
		"the next HUD has the clock where it was left")
	var defaults := _defaults(_hud_at(Vector2i(1152, 648)))
	await get_tree().process_frame
	for id in HudLayout.PIECES:
		if id != "clock":
			assert_almost_eq(fresh.piece_rect(id).position, defaults[id].position, Vector2(EPS, EPS),
				"%s untouched" % id)


func test_dragging_empty_space_moves_nothing() -> void:
	var ps := _pause_screen()
	await get_tree().process_frame
	ps.open_hud_layout()
	assert_false(ps.hud_layout_editor.press(Vector2(576, 200)), "nothing at the top centre")
	assert_eq(ps.target.hud.layout, {})


func test_layout_holds_at_two_window_sizes_and_two_hud_sizes() -> void:
	# Move three pieces at 1152 x 648: the clock to the top right, the coins to the
	# left middle, the sub goal to the top left area under the weapons.
	var base := _hud_at(Vector2i(1152, 648))
	await get_tree().process_frame
	base.move_piece("clock", Vector2(936, 16))
	base.move_piece("coins", Vector2(16, 300))
	base.move_piece("sub_goal", Vector2(500, 450))
	var layout := base.layout.duplicate(true)
	assert_eq(layout.keys().size(), 3)
	var ref := {}
	for id in HudLayout.PIECES:
		ref[id] = base.piece_rect(id)
	for size in [Vector2i(1920, 1080), Vector2i(960, 540)]:
		for pct in [GameSettings.MIN_HUD_SIZE, GameSettings.MAX_HUD_SIZE]:
			var hud := _hud_at(size, pct, layout)
			await get_tree().process_frame
			var where := "%dx%d at %d" % [size.x, size.y, int(pct)]
			var area: Vector2 = hud.root.size
			var screen := Rect2(Vector2.ZERO, Vector2(size)).grow(0.01)
			for id in HudLayout.PIECES:
				var r := hud.piece_rect(id)
				var t := hud.root.get_global_transform()
				var on_screen := Rect2(t * r.position, r.size * hud.hud_scale())
				assert_true(screen.encloses(on_screen), "%s: %s fully on screen (%s)" % [where, id, on_screen])
			# The moved pieces keep their corner or centre, in layout pixels.
			var clock := hud.piece_rect("clock")
			assert_almost_eq(area.x - clock.end.x, 1152.0 - ref.clock.end.x, EPS, "%s: clock's right margin" % where)
			assert_almost_eq(clock.position.y, ref.clock.position.y, EPS, "%s: clock's top margin" % where)
			var v := hud.piece_rect("coins")
			assert_almost_eq(v.position.x, ref.coins.position.x, EPS, "%s: coins' left margin" % where)
			assert_almost_eq(v.get_center().y - area.y / 2.0, ref.coins.get_center().y - 324.0, EPS,
				"%s: coins centred on the height" % where)
			var sg := hud.piece_rect("sub_goal")
			assert_almost_eq(sg.get_center().x - area.x / 2.0, ref.sub_goal.get_center().x - 576.0, EPS,
				"%s: sub goal centred on the width" % where)


func test_a_moved_piece_that_grows_stays_on_screen() -> void:
	var hud := _hud_at(Vector2i(1152, 648))
	await get_tree().process_frame
	hud.move_piece("hearts", Vector2(2000, 2000))
	var before := hud.piece_rect("hearts")
	assert_almost_eq(before.end, hud.root.size, Vector2(EPS, EPS), "clamped into the bottom-right corner")
	hud.heart_row.set_hearts(12, 12, false)  # a second row: the row grows
	await get_tree().process_frame
	var after := hud.piece_rect("hearts")
	assert_gt(after.size.y, before.size.y, "it grew")
	assert_true(Rect2(Vector2.ZERO, hud.root.size).grow(0.01).encloses(after), "still fully on screen")


func test_reset_returns_every_piece_to_the_default() -> void:
	var ps := _pause_screen()
	await get_tree().process_frame
	var hud: Hud = ps.target.hud
	var defaults := _defaults(hud)
	var sub_offset_top := hud.sub_goal.offset_top
	var i := 0
	for id in HudLayout.PIECES:
		hud.move_piece(id, Vector2(300 + i * 40, 200 + i * 30))
		i += 1
	for id in HudLayout.PIECES:
		assert_false(hud.piece_rect(id).position.is_equal_approx(defaults[id].position), "%s moved" % id)
	ps.open_hud_layout()
	ps.hud_layout_editor.reset_button.pressed.emit()
	for id in HudLayout.PIECES:
		assert_almost_eq(hud.piece_rect(id).position, defaults[id].position, Vector2(EPS, EPS), "%s back" % id)
	assert_eq(hud.sub_goal.offset_top, sub_offset_top, "the sub goal's own anchoring back")
	ps.hud_layout_editor.done_button.pressed.emit()
	assert_eq(GameSettings.load_hud_layout(), {}, "the default layout saved")
	var cfg := ConfigFile.new()
	cfg.load(TEST_PATH)
	assert_false(cfg.has_section("hud_layout"), "no layout left in the file")


func test_reset_at_a_big_hud_keeps_the_sub_goal_in_place() -> void:
	var hud := _hud_at(Vector2i(1152, 648), GameSettings.MAX_HUD_SIZE)
	await get_tree().process_frame
	var before := hud.piece_rect("sub_goal")
	hud.move_piece("sub_goal", Vector2(400, 100))
	hud.reset_layout()
	assert_almost_eq(hud.piece_rect("sub_goal").position, before.position, Vector2(EPS, EPS))


func test_saved_layout_is_used_by_a_run_started_by_the_game_flow() -> void:
	GameSettings.save_hud_layout({"coins": {"ax": 0.0, "ay": 0.0, "dx": 16.0, "dy": 200.0}})
	var holder := Node.new()
	add_child_autofree(holder)
	var run: Node2D = GameFlow.add_run(holder, PlayerProgress.new())
	await get_tree().process_frame
	assert_eq(run.hud.layout.keys(), ["coins"], "the run's HUD has the saved layout")
	assert_almost_eq(run.hud.piece_rect("coins").position, Vector2(16, 200), Vector2(EPS, EPS))
