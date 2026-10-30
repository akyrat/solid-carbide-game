extends GutTest
## Task T-280: every level has a spawn point (Level design, Decisions, "The car's spawn point"). It
## is there from the moment a level opens (a new level, or one saved before T-280), drawn above the
## pieces with T-279's label, movable (dragged, onto a street, a rooftop or a ramp, never inside a
## building, an obstacle or off the map), turned by R, never deleted, saved in the level file and
## used by a run started from the creator (place, height and heading); check_level.py refuses a
## level without a valid one. The game's own map is unchanged.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const RunScript := preload("res://scripts/run/run.gd")
const SAMPLE :="res://data/level/elevation_sample_map.json"

var dir: String


func before_each() -> void:
	TestSave.isolate()
	dir = RunPaths.file("t280_levels_" + str(randi()))


func after_each() -> void:
	get_tree().paused = false
	await wait_process_frames(1)
	TestSave.restore()


func _editor() -> LevelCreatorEditor:
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.open_new()
	e.levels_dir = dir
	add_child_autofree(e)
	return e


func _spawn(e: LevelCreatorEditor) -> Dictionary:
	return e.level_data.spawn


func _at(e: LevelCreatorEditor) -> Vector2:
	return Vector2(_spawn(e).x, _spawn(e).y)


func _key(e: LevelCreatorEditor, keycode: Key) -> void:
	var k := InputEventKey.new()
	k.keycode = keycode
	k.pressed = true
	e._unhandled_key_input(k)


func _place(e: LevelCreatorEditor, asset: String, at: Vector2, size: Vector2 = Vector2.ZERO) -> Dictionary:
	e.panel.pick(asset)
	var p := e.place_asset(asset, at, size)
	assert_false(p.is_empty(), "%s placed at %s" % [asset, at])
	e.panel.pick("")
	return p


func _check_level(path: String) -> Array:
	var output: Array = []
	var code := OS.execute("python", [ProjectSettings.globalize_path("res://tools/check_level.py"),
		ProjectSettings.globalize_path(path)], output, true)
	return [code, "\n".join(output)]


# ---- Always there ----------------------------------------------------------------------------

func test_a_new_level_opens_with_its_spawn_point_at_the_centre() -> void:
	var e := _editor()
	assert_true(LevelSpawn.has_spawn(e.level_data))
	assert_eq(_at(e), Vector2(1, 1), "the middle of the cell at the map's centre")
	assert_eq(int(_spawn(e).heading), LevelSpawn.DEFAULT_HEADING)
	assert_eq(e.document.height_at(_at(e)), 0.0, "on the street")
	assert_eq(e._overlay.z_index, LevelCreatorEditor.OVERLAY_Z, "drawn above every piece")
	assert_eq(LevelSpawn.problem(e.level_data, _at(e)), "")


func test_a_level_saved_before_t280_opens_with_it_at_the_centre() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAMPLE))
	assert_false(data.has("spawn"), "the game's own map has none")
	var path := dir.path_join("old.json")
	assert_eq(LevelStore.save_level(path, data), OK)
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.levels_dir = dir
	e.open_level(path)
	add_child_autofree(e)
	assert_true(LevelSpawn.has_spawn(e.level_data), "an old level opens with one")
	assert_eq(_at(e), Vector2(1, 1))
	assert_eq(LevelSpawn.problem(e.level_data, _at(e)), "", "a place the car can stand")


func test_the_label_is_t279s_and_the_hint_line_has_the_start() -> void:
	var e := _editor()
	assert_eq(CreatorTexts.get_text("spawn_label"), "Start")
	assert_eq(e.hint_label.text, CreatorTexts.get_text("controls_hint_spawn"))
	assert_string_contains(e.hint_label.text, "move the start")


func test_the_marker_draws_without_error_dragged_and_not() -> void:
	var e := _editor()
	await wait_process_frames(2)  # the overlay's own draw runs, the marker included
	e.begin_spawn_drag()
	e.update_spawn_drag(Vector2(31, 31))
	await wait_process_frames(2)
	assert_eq(e.spawn_drop, Vector2(31, 31))
	assert_eq(e.spawn_drop_problem, "")
	e.end_spawn_drag(Vector2(31, 31))
	assert_false(e.spawn_dragging)


# ---- Moving and turning -----------------------------------------------------------------------

func test_a_click_on_it_selects_it_with_the_hint() -> void:
	var e := _editor()
	e.select_at(Vector2(1.2, 0.8))
	assert_eq(e.selected.kind, "spawn")
	assert_eq(e.message_label.text, CreatorTexts.get_text("spawn_hint"))
	e.select_at(Vector2(41, 41))
	assert_ne(str(e.selected.get("kind", "")), "spawn")
	assert_eq(e.message_label.text, "", "the hint goes when something else is selected")


func test_dragging_it_moves_it_to_the_cell_under_the_mouse() -> void:
	var e := _editor()
	e.begin_spawn_drag()
	assert_true(e.spawn_dragging)
	e.update_spawn_drag(Vector2(30.3, -20.9))
	assert_true(e.end_spawn_drag(Vector2(30.3, -20.9)))
	assert_eq(_at(e), Vector2(31, -21), "snapped to a cell's middle")


func test_mouse_events_drag_the_start() -> void:
	var e := _editor()
	await wait_process_frames(2)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = e.units_to_screen(_at(e))
	e._on_map_input(press)
	assert_true(e.spawn_dragging)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = e.units_to_screen(Vector2(21, 11))
	e._on_map_input(release)
	assert_false(e.spawn_dragging)
	assert_eq(_at(e), Vector2(21, 11))


func test_it_can_be_moved_onto_a_rooftop_at_its_height() -> void:
	var e := _editor()
	var roof := _place(e, "rooftop-3", Vector2(41, 41))
	var mid := e.document.piece_rect(roof).get_center()
	assert_true(e.move_spawn(mid))
	assert_eq(e.document.height_at(_at(e)), 3.0, "the rooftop's height")
	assert_eq(e.message_label.text, "")


func test_it_can_be_moved_onto_a_ramp() -> void:
	var e := _editor()
	_place(e, "rooftop-3", Vector2(61, 61))
	var ramp := _place(e, "ramp-0-3", Vector2(53, 71))
	var mid := e.document.piece_rect(ramp).get_center()
	assert_true(e.move_spawn(mid))
	var h := e.document.height_at(_at(e))
	assert_true(h > 0.0 and h <= 3.0, "a height on the slope: %s" % h)


func test_it_is_refused_inside_a_building_with_the_message() -> void:
	var e := _editor()
	# T-405: a skyscraper (a small building is a platform the car may start on).
	var b := _place(e, "skyscraper-1", Vector2(51, 51))
	var before := _at(e)
	assert_false(e.move_spawn(e.document.piece_rect(b).get_center()))
	assert_eq(_at(e), before, "it stays where it was")
	assert_eq(e.message_label.text, CreatorTexts.get_text("spawn_blocked"))


func test_it_is_refused_on_an_obstacle() -> void:
	var e := _editor()
	var before := _at(e)
	for asset in ["boulder-a", "prop-barrier", "prop-crates"]:
		e.message_label.text = ""
		var p := _place(e, asset, Vector2(71, 71) if asset == "boulder-a" else Vector2(81, 81 + (4 if asset == "prop-crates" else 0)))
		assert_false(e.move_spawn(e.document.piece_rect(p).get_center()), asset)
		assert_eq(e.message_label.text, CreatorTexts.get_text("spawn_blocked"), asset)
		assert_eq(_at(e), before)


func test_it_is_refused_off_the_map() -> void:
	var e := _editor()
	var before := _at(e)
	for off in [Vector2(-200, 0), Vector2(0, 300), Vector2(121, 0)]:
		e.message_label.text = ""
		assert_false(e.move_spawn(off), str(off))
		assert_eq(e.message_label.text, CreatorTexts.get_text("spawn_blocked"))
		assert_eq(_at(e), before)


func test_the_cell_next_to_a_building_is_allowed() -> void:
	var e := _editor()
	var b := _place(e, "building-small", Vector2(51, 51))
	var r := e.document.piece_rect(b)
	assert_true(e.move_spawn(Vector2(r.end.x + 1.0, r.get_center().y)))


func test_r_turns_the_selected_start_through_eight_headings() -> void:
	var e := _editor()
	e.select_spawn()
	var seen := {}
	for i in 8:
		_key(e, KEY_R)
		seen[int(_spawn(e).heading)] = true
	assert_eq(seen.size(), 8, "eight headings")
	assert_eq(int(_spawn(e).heading), LevelSpawn.DEFAULT_HEADING, "back to the start after eight")
	_key(e, KEY_R)
	assert_eq(int(_spawn(e).heading), 315)
	for h in seen:
		assert_eq(h % 45, 0)


func test_r_with_nothing_selected_leaves_the_start_alone() -> void:
	var e := _editor()
	_key(e, KEY_R)
	assert_eq(int(_spawn(e).heading), LevelSpawn.DEFAULT_HEADING)


# ---- Never deleted ----------------------------------------------------------------------------

func test_delete_shows_the_message_and_keeps_it() -> void:
	var e := _editor()
	e.select_spawn()
	_key(e, KEY_DELETE)
	assert_eq(e.message_label.text, CreatorTexts.get_text("spawn_no_delete"))
	assert_true(LevelSpawn.has_spawn(e.level_data))
	assert_eq(e.selected.kind, "spawn", "still selected")
	e.delete_selected()
	assert_false(e.document.delete(e.document.spawn_piece()))
	assert_true(LevelSpawn.has_spawn(e.level_data))
	assert_eq(e.level_data.keys().filter(func(k): return k == "spawn").size(), 1, "exactly one")


func test_a_piece_is_not_placed_over_the_start() -> void:
	var e := _editor()
	# T-405: a skyscraper (a small building is a platform the car may start on).
	e.panel.pick("skyscraper-1")
	var p := e.place_asset("skyscraper-1", _at(e))
	assert_true(p.is_empty(), "a building over the start is refused")
	assert_eq(e.message_label.text, CreatorTexts.get_text("spawn_blocked"))
	assert_eq(e.level_data.buildings.size(), 0)
	assert_eq(LevelSpawn.problem(e.level_data, _at(e)), "")


# ---- Saved, reopened, and used by a run ---------------------------------------------------------

func test_it_is_saved_and_reopened_and_passes_check_level() -> void:
	var e := _editor()
	var roof := _place(e, "rooftop-3", Vector2(41, 41))
	e.move_spawn(e.document.piece_rect(roof).get_center())
	e.select_spawn()
	_key(e, KEY_R)
	_key(e, KEY_R)
	var want := _at(e)
	var heading := int(_spawn(e).heading)
	assert_eq(e.save(), OK)
	var saved := LevelStore.load_level(e.level_path)
	assert_eq(Vector2(saved.spawn.x, saved.spawn.y), want)
	assert_eq(int(saved.spawn.heading), heading)
	var again: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	again.levels_dir = dir
	again.open_level(e.level_path)
	add_child_autofree(again)
	assert_eq(_at(again), want, "reopens where it was")
	assert_eq(int(_spawn(again).heading), heading)
	var res := _check_level(e.level_path)
	assert_eq(res[0], 0, "check_level.py: " + res[1])


func test_check_level_refuses_a_level_without_a_valid_spawn() -> void:
	var e := _editor()
	assert_eq(e.save(), OK)
	var data := LevelStore.load_level(e.level_path)
	var bad_path := dir.path_join("bad.json")
	data.erase("spawn")
	LevelStore.save_level(bad_path, data)
	var res := _check_level(bad_path)
	assert_eq(res[0], 1)
	assert_string_contains(res[1], "spawn")
	data.spawn = {"x": 500.0, "y": 0.0, "heading": 0}
	LevelStore.save_level(bad_path, data)
	res = _check_level(bad_path)
	assert_eq(res[0], 1)
	assert_string_contains(res[1], "spawn")


func _run_on(path: String) -> Node2D:
	var c: LevelCreator = load("res://scenes/level_creator/level_creator.tscn").instantiate()
	c.levels_dir = dir
	add_child_autofree(c)
	c.play_level(path)
	return c.run


func test_a_run_starts_the_car_at_the_spawn_place_height_and_heading() -> void:
	var e := _editor()
	var roof := _place(e, "rooftop-3", Vector2(41, 41))
	e.move_spawn(e.document.piece_rect(roof).get_center())
	e.select_spawn()
	_key(e, KEY_R)  # 315
	assert_eq(e.save(), OK)
	var want := _at(e)
	var run := _run_on(e.level_path)
	assert_not_null(run)
	assert_eq(Vector2(run.car.model.x, run.car.model.y), want, "the car's place")
	assert_almost_eq(run.car.model.rotation, deg_to_rad(315.0), 0.0001, "the car's heading")
	assert_eq(run.car.height, 3.0, "the car's height: the rooftop's")


func test_a_run_on_an_old_level_starts_at_the_centre() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAMPLE))
	var path := dir.path_join("old.json")
	LevelStore.save_level(path, data)
	var run := _run_on(path)
	assert_eq(Vector2(run.car.model.x, run.car.model.y), Vector2.ZERO, "the run's own start, as before")
	assert_almost_eq(run.car.model.rotation, -PI / 2.0, 0.0001)


# ---- The game's own map is unchanged ----------------------------------------------------------

func test_the_games_own_map_file_has_no_spawn() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAMPLE))
	assert_false(data.has("spawn"))
	assert_eq(_check_level(SAMPLE)[0], 0)
	var run := GameFlow.add_run(self, PlayerProgress.new())
	autofree(run)
	assert_eq(Vector2(run.car.model.x, run.car.model.y), RunScript.START_POSITION_UNITS)
	assert_almost_eq(run.car.model.rotation, RunScript.START_ROTATION, 0.0001)


func test_no_redgull_red_in_the_marker() -> void:
	for c in [LevelCreatorEditor.SPAWN_COLOR, LevelCreatorEditor.SPAWN_REFUSED_COLOR]:
		assert_true(c.r < 0.9 or c.g > 0.5, "not red: %s" % c)
