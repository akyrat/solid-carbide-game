extends GutTest
## Task T-272: pairs of obstacles in the level creator, for the thread the needle trick. Two placed
## obstacles (boulders, barriers, cones, crates) are paired with the pair tool (the top bar's Pair
## obstacles, key P) and T-271's labels; anything else is refused with T-271's message; a pair shows
## in the editor, is removed by Unpair or by deleting either obstacle, an obstacle is in at most one
## pair, and pairs are saved in the level file, reopened and checked by check_level.py.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")


func _editor() -> LevelCreatorEditor:
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.open_new()
	e.levels_dir = RunPaths.file("t272_levels")
	add_child_autofree(e)
	return e


## Places `asset` with the cursor at `at`, then drops the pick. Returns the piece.
func _place(e: LevelCreatorEditor, asset: String, at: Vector2) -> Dictionary:
	e.panel.pick(asset)
	var p := e.place_asset(asset, at)
	assert_false(p.is_empty(), "%s placed at %s" % [asset, at])
	e.panel.pick("")
	return p


## The middle of a placed piece's footprint (units): where a click picks it.
func _mid(e: LevelCreatorEditor, piece: Dictionary) -> Vector2:
	return e.document.piece_rect(piece).get_center()


func _check_level(path: String) -> Array:
	var output: Array = []
	var code := OS.execute("python", [ProjectSettings.globalize_path("res://tools/check_level.py"),
		ProjectSettings.globalize_path(path)], output, true)
	return [code, "\n".join(output)]


func _key(e: LevelCreatorEditor, keycode: Key) -> void:
	var k := InputEventKey.new()
	k.keycode = keycode
	k.pressed = true
	e._unhandled_key_input(k)


# ---- The tool and its labels --------------------------------------------------------------------

func test_the_labels_are_t271s() -> void:
	var e := _editor()
	assert_eq(e.pair_button.text, CreatorTexts.get_text("pair_tool"))
	assert_eq(e.pair_button.text, "Pair obstacles")
	assert_eq(e.unpair_button.text, CreatorTexts.get_text("unpair_label"))
	assert_eq(e.hint_label.text, CreatorTexts.get_text("controls_hint_pairs"), "the hint line with P: pair.")
	assert_string_contains(e.hint_label.text, "P: pair.")


func test_p_is_the_pair_key_in_key_actions() -> void:
	assert_eq(LevelCreatorEditor.KEY_ACTIONS.get(KEY_P), "pair")
	var e := _editor()
	_key(e, KEY_P)
	assert_true(e.pair_mode, "P turns the pair tool on")
	assert_true(e.pair_button.button_pressed)
	assert_eq(e.size_label.text, CreatorTexts.get_text("pair_hint"), "the hint while it is on")
	_key(e, KEY_P)
	assert_false(e.pair_mode, "and off")
	assert_false(e.pair_button.button_pressed)


func test_the_button_turns_it_on_and_drops_the_pick() -> void:
	var e := _editor()
	e.panel.pick("boulder-a")
	e.pair_button.button_pressed = true
	e.pair_button.pressed.emit()
	assert_true(e.pair_mode)
	assert_eq(e.panel.picked, "", "the pick is dropped")
	e.panel.pick("boulder-a")
	assert_false(e.pair_mode, "picking a piece ends the tool")
	e.panel.pick("")
	e.set_pair_tool(true)
	_key(e, KEY_ESCAPE)
	assert_false(e.pair_mode, "Esc ends it")


# ---- Pairing ------------------------------------------------------------------------------------

func test_two_boulders_are_paired() -> void:
	var e := _editor()
	var a := _place(e, "boulder-a", Vector2(-5, -39))
	var b := _place(e, "boulder-b", Vector2(3, -39))
	e.set_pair_tool(true)
	assert_eq(e.pair_click(_mid(e, a)), "first")
	assert_eq(e.document.pairs().size(), 0, "not yet")
	assert_eq(e.pair_click(_mid(e, b)), "made")
	assert_eq(e.message_label.text, CreatorTexts.get_text("pair_made"))
	assert_eq(e.message_label.text, "Pair made. Drive between them.")
	var pairs := e.document.pairs()
	assert_eq(pairs.size(), 1)
	assert_eq(pairs[0].id, "pair-1")
	assert_eq(pairs[0].a, str(a.copy.id))
	assert_eq(pairs[0].b, str(b.copy.id))
	assert_false(e.document.pair_of(a).is_empty())
	assert_true(is_same(e.document.pair_of(a), e.document.pair_of(b)))
	assert_true(e.pair_mode, "the tool stays on for the next pair")


func test_barrier_cones_and_crates_are_obstacles() -> void:
	var e := _editor()
	var barrier := _place(e, "prop-barrier", Vector2(-20, -39))
	var cones := _place(e, "prop-cones", Vector2(-10, -39))
	var crates := _place(e, "prop-crates", Vector2(0, -39))
	var boulder := _place(e, "boulder-a", Vector2(10, -39))
	for p in [barrier, cones, crates, boulder]:
		assert_true(LevelDocument.is_obstacle(p), str(p.item))
	e.set_pair_tool(true)
	e.pair_click(_mid(e, barrier))
	assert_eq(e.pair_click(_mid(e, cones)), "made")
	e.pair_click(_mid(e, crates))
	assert_eq(e.pair_click(_mid(e, boulder)), "made")
	assert_eq(e.document.pairs().size(), 2)
	assert_eq(e.document.pair_of(barrier).b, str(cones.item.id))
	assert_eq(e.document.pair_of(crates).b, str(boulder.copy.id))


func test_a_non_obstacle_is_refused_with_t271s_message() -> void:
	var e := _editor()
	var a := _place(e, "boulder-a", Vector2(-5, -39))
	var lamp := _place(e, "prop-street-lamp", Vector2(10, -39))
	var house := _place(e, "building-small", Vector2(30, -39))
	e.set_pair_tool(true)
	assert_eq(e.pair_click(Vector2(-60, 60)), "not_obstacle", "the bare ground")
	assert_eq(e.message_label.text, CreatorTexts.get_text("pair_not_obstacle"))
	assert_eq(e.message_label.text, "Not an obstacle. Pick a boulder, barrier, cones or crates.")
	assert_eq(e.pair_click(_mid(e, a)), "first")
	assert_eq(e.pair_click(_mid(e, lamp)), "not_obstacle", "a street lamp is decoration")
	assert_eq(e.pair_click(_mid(e, house)), "not_obstacle", "a building")
	assert_false(e.pair_first.is_empty(), "the first obstacle stays held")
	assert_eq(e.document.pairs().size(), 0)
	assert_false(LevelDocument.is_obstacle(lamp))


func test_clicking_the_same_obstacle_twice_lets_it_go() -> void:
	var e := _editor()
	var a := _place(e, "boulder-a", Vector2(-5, -39))
	e.set_pair_tool(true)
	e.pair_click(_mid(e, a))
	assert_eq(e.pair_click(_mid(e, a)), "cancelled")
	assert_true(e.pair_first.is_empty())
	assert_eq(e.document.pairs().size(), 0)


func test_an_obstacle_is_in_at_most_one_pair() -> void:
	var e := _editor()
	var a := _place(e, "boulder-a", Vector2(-5, -39))
	var b := _place(e, "boulder-b", Vector2(3, -39))
	var c := _place(e, "prop-crates", Vector2(12, -39))
	e.set_pair_tool(true)
	e.pair_click(_mid(e, a))
	e.pair_click(_mid(e, b))
	e.pair_click(_mid(e, a))
	assert_eq(e.pair_click(_mid(e, c)), "made")
	var pairs := e.document.pairs()
	assert_eq(pairs.size(), 1, "the new pair replaces a's old one")
	assert_eq([pairs[0].a, pairs[0].b], [str(a.copy.id), str(c.item.id)])
	assert_true(e.document.pair_of(b).is_empty(), "b is free again")


# ---- Unpairing ----------------------------------------------------------------------------------

func _paired(e: LevelCreatorEditor) -> Array:
	var a := _place(e, "boulder-a", Vector2(-5, -39))
	var b := _place(e, "prop-barrier", Vector2(3, -39))
	e.set_pair_tool(true)
	e.pair_click(_mid(e, a))
	e.pair_click(_mid(e, b))
	e.set_pair_tool(false)
	return [a, b]


func test_unpair_removes_the_selected_obstacles_pair() -> void:
	var e := _editor()
	var ab := _paired(e)
	assert_false(e.unpair_button.visible, "hidden with nothing selected")
	e.select_at(_mid(e, ab[1]))
	assert_true(e.unpair_button.visible, "shows with a paired obstacle selected")
	e.unpair_button.pressed.emit()
	assert_eq(e.document.pairs().size(), 0)
	assert_false(e.unpair_button.visible)
	assert_false(e.unpair_selected(), "nothing left to unpair")


func test_deleting_either_obstacle_removes_the_pair() -> void:
	for which in [0, 1]:
		var e := _editor()
		var ab := _paired(e)
		e.select_at(_mid(e, ab[which]))
		e.delete_selected()
		assert_eq(e.document.pairs().size(), 0, "deleting obstacle %d" % which)
		e.queue_free()


func test_deleting_another_piece_keeps_the_pair() -> void:
	var e := _editor()
	_paired(e)
	var other := _place(e, "boulder-a", Vector2(20, -39))
	e.select_at(_mid(e, other))
	e.delete_selected()
	assert_eq(e.document.pairs().size(), 1)


func test_a_copy_of_several_boulders_keeps_its_pairs_right() -> void:
	# The game's own map holds copies of two boulders: each is named "<copy>/<index>".
	var d := LevelDocument.new_level_data("t")
	d.pattern_copies = [{"id": "copy-02", "boulders": [{"x": -10.0, "y": 0.0, "diameter": 3.0},
		{"x": 10.0, "y": 0.0, "diameter": 3.0}]}]
	d["props"] = [{"id": "prop-1", "asset": "prop-crates", "rotation": "north", "x": 0.0, "y": 10.0, "w": 2.0, "h": 2.0}]
	var doc := LevelDocument.new(d)
	var b0 := doc.piece_at(Vector2(-10, 0))
	var b1 := doc.piece_at(Vector2(10, 0))
	var crate := doc.piece_at(Vector2(1, 11))
	assert_eq(LevelDocument.obstacle_ref(b0), "copy-02/0")
	assert_eq(LevelDocument.obstacle_ref(b1), "copy-02/1")
	doc.make_pair(b1, crate)
	doc.delete(b0)
	assert_eq(doc.pairs().size(), 1, "the other boulder's pair stays")
	assert_eq(doc.pairs()[0].a, "copy-02", "named by its copy now that it is alone")
	assert_true(is_same(doc.piece_of_ref("copy-02").item, b1.item))


# ---- Drawing, saving, reopening, checking --------------------------------------------------------

func test_the_pair_is_drawn_in_the_editor() -> void:
	var e := _editor()
	_paired(e)
	var line := ObstaclePairs.line_of(e.document.data, e.document.pairs()[0])
	assert_false(line.is_empty(), "the overlay has a line to draw")
	assert_gt(line.gap_a.distance_to(line.gap_b), 0.5, "across the gap between the two")
	assert_lt(line.gap_a.distance_to(line.gap_b), line.a.distance_to(line.b), "edge to edge, not centre to centre")
	e._overlay.queue_redraw()
	await get_tree().process_frame
	var col: Color = LevelCreatorEditor.PAIR_COLOR
	assert_false(col.r8 >= 150 and col.g8 <= 100 and col.b8 <= 100, "not Redgull red")


func test_pairs_are_saved_reopened_and_pass_check_level() -> void:
	var e := _editor()
	var ab := _paired(e)
	e.name_field.text = "T-272 pairs"
	assert_eq(e.save(), OK)
	var path := e.level_path
	var saved := LevelStore.load_level(path)
	assert_eq(saved.get("pairs", []).size(), 1, "written in the level file")
	assert_eq(saved.pairs[0].a, str(ab[0].copy.id))
	assert_eq(saved.pairs[0].b, str(ab[1].item.id))
	var r := _check_level(path)
	assert_eq(r[0], 0, r[1])
	var e2 := _editor()
	e2.open_level(path)
	assert_eq(e2.document.pairs().size(), 1, "reopened")
	var p := e2.document.piece_at(_mid(e, ab[0]))
	assert_false(e2.document.pair_of(p).is_empty(), "the reopened boulder is still paired")
	var q := e2.document.piece_at(_mid(e, ab[1]))
	assert_true(is_same(e2.document.pair_of(p), e2.document.pair_of(q)))


func test_check_level_refuses_a_pair_naming_a_missing_obstacle() -> void:
	var e := _editor()
	_paired(e)
	var data := e.document.file_data("T-272 broken")
	data.pairs[0].b = "prop-99"
	var path := RunPaths.file("t272_broken.json")
	assert_eq(LevelStore.save_level(path, data), OK)
	var r := _check_level(path)
	assert_eq(r[0], 1, r[1])
	assert_string_contains(r[1], "no such obstacle")


func test_the_games_own_map_has_no_pairs() -> void:
	var d := LevelStore.load_level("res://data/level/elevation_sample_map.json")
	assert_false(d.has("pairs"))
	assert_eq(ObstaclePairs.pairs_of(d), [])
