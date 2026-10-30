extends GutTest
## Task T-272: pairs of obstacles in the level creator, for the thread the needle trick. Two placed
## obstacles (boulders, barriers, cones, crates) are paired with the pair tool (the top bar's Pair
## obstacles, key P) and T-271's labels; anything else is refused with T-271's message; a pair shows
## in the editor, is removed by Unpair or by deleting either obstacle, and pairs are saved in the
## level file, reopened and checked by check_level.py.
## T-394: an obstacle can be in several pairs; Shift+click picks a row in order and Pair or P pairs
## it as a chain; Unpair removes only the pairs aimed at.

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
	assert_eq(e.hint_label.text, CreatorTexts.get_text("controls_hint_spawn"), "the hint line with P: pair.")
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


func test_an_obstacle_can_be_in_several_pairs() -> void:
	# T-394: pairing B with C keeps A with B (T-272 moved B to the new pair).
	var e := _editor()
	var a := _place(e, "boulder-a", Vector2(-5, -39))
	var b := _place(e, "boulder-b", Vector2(3, -39))
	var c := _place(e, "prop-crates", Vector2(12, -39))
	e.set_pair_tool(true)
	e.pair_click(_mid(e, a))
	assert_eq(e.pair_click(_mid(e, b)), "made")
	e.pair_click(_mid(e, b))
	assert_eq(e.pair_click(_mid(e, c)), "made")
	var pairs := e.document.pairs()
	assert_eq(pairs.size(), 2, "A-B stays")
	assert_eq([pairs[0].a, pairs[0].b], [str(a.copy.id), str(b.copy.id)])
	assert_eq([pairs[1].a, pairs[1].b], [str(b.copy.id), str(c.item.id)])
	assert_eq(e.document.pairs_with(b).size(), 2, "b is in both")
	assert_eq(e.document.pairs_with(a).size(), 1)


func test_the_same_two_are_one_pair_at_most() -> void:
	var e := _editor()
	var a := _place(e, "boulder-a", Vector2(-5, -39))
	var b := _place(e, "boulder-b", Vector2(3, -39))
	e.set_pair_tool(true)
	e.pair_click(_mid(e, a))
	e.pair_click(_mid(e, b))
	e.pair_click(_mid(e, b))
	e.pair_click(_mid(e, a))
	assert_eq(e.document.pairs().size(), 1, "B with A again: still the one pair")
	assert_true(is_same(e.document.pair_between(a, b), e.document.pair_between(b, a)))


## Four obstacles in a row, west to east, with gaps between them.
func _row(e: LevelCreatorEditor) -> Array:
	return [_place(e, "boulder-a", Vector2(-12, -39)), _place(e, "prop-crates", Vector2(-4, -39)),
		_place(e, "boulder-b", Vector2(4, -39)), _place(e, "prop-barrier", Vector2(12, -39))]


func _refs(row: Array) -> Array:
	return row.map(func(p): return LevelDocument.obstacle_ref(p))


func _pair_refs(e: LevelCreatorEditor) -> Array:
	return e.document.pairs().map(func(p): return [p.a, p.b])


func test_shift_click_picks_a_row_and_p_pairs_it_as_a_chain() -> void:
	var e := _editor()
	var row := _row(e)
	var r := _refs(row)
	e.set_pair_tool(true)
	for i in row.size():
		assert_eq(e.pair_click(_mid(e, row[i]), true), "added", "Shift+click %d" % i)
	assert_eq(e.pair_picks.size(), 4, "picked in order")
	assert_eq(e.document.pairs().size(), 0, "nothing paired yet")
	_key(e, KEY_P)
	assert_true(e.pair_mode, "P with a row picked pairs it; the tool stays on")
	assert_eq(_pair_refs(e), [[r[0], r[1]], [r[1], r[2]], [r[2], r[3]]], "A-B, B-C, C-D")
	assert_true(e.pair_picks.is_empty(), "the pick is dropped")
	assert_eq(e.message_label.text, CreatorTexts.get_text("pair_made"))


func test_the_pair_button_pairs_a_picked_row() -> void:
	var e := _editor()
	var row := _row(e)
	var r := _refs(row)
	e.set_pair_tool(true)
	for i in 3:
		e.pair_click(_mid(e, row[i]), true)
	e.pair_button.button_pressed = false  # a click on the pressed toggle
	e.pair_button.pressed.emit()
	assert_true(e.pair_mode, "still on")
	assert_true(e.pair_button.button_pressed)
	assert_eq(_pair_refs(e), [[r[0], r[1]], [r[1], r[2]]])


func test_a_plain_click_ends_a_row_and_pairs_it() -> void:
	var e := _editor()
	var row := _row(e)
	var r := _refs(row)
	e.set_pair_tool(true)
	e.pair_click(_mid(e, row[0]), true)
	e.pair_click(_mid(e, row[1]), true)
	assert_eq(e.pair_click(_mid(e, row[2])), "made", "a plain click adds the last and pairs")
	assert_eq(_pair_refs(e), [[r[0], r[1]], [r[1], r[2]]])


func test_picking_two_one_by_one_chains_too() -> void:
	# The other way: two at a time, each pair keeps the ones before.
	var e := _editor()
	var row := _row(e)
	var r := _refs(row)
	e.set_pair_tool(true)
	for i in 3:
		e.pair_click(_mid(e, row[i]))
		e.pair_click(_mid(e, row[i + 1]))
	assert_eq(_pair_refs(e), [[r[0], r[1]], [r[1], r[2]], [r[2], r[3]]])


func test_shift_click_on_a_picked_one_takes_it_out() -> void:
	var e := _editor()
	var row := _row(e)
	var r := _refs(row)
	e.set_pair_tool(true)
	for i in 3:
		e.pair_click(_mid(e, row[i]), true)
	assert_eq(e.pair_click(_mid(e, row[1]), true), "removed")
	assert_eq(_refs(e.pair_picks), [r[0], r[2]])
	e.pair_picked_row()
	assert_eq(_pair_refs(e), [[r[0], r[2]]])


func test_shift_click_with_the_tool_off_starts_a_row() -> void:
	var e := _editor()
	var row := _row(e)
	assert_false(e.pair_mode)
	assert_true(e.shift_pick_obstacle(_mid(e, row[0])))
	assert_true(e.pair_mode, "the pair tool comes on")
	assert_eq(e.pair_picks.size(), 1)
	assert_false(e.shift_pick_obstacle(Vector2(-60, 60)), "not on bare ground")


func test_a_mouse_shift_click_reaches_the_row() -> void:
	var e := _editor()
	var row := _row(e)
	e.set_pair_tool(true)
	for i in 2:
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		mb.pressed = true
		mb.shift_pressed = true
		mb.position = e.units_to_screen(_mid(e, row[i]))
		e._on_map_input(mb)
	assert_eq(e.pair_picks.size(), 2, "both picked, nothing paired")
	assert_eq(e.document.pairs().size(), 0)


func test_the_picked_row_is_drawn_numbered() -> void:
	var e := _editor()
	var row := _row(e)
	e.set_pair_tool(true)
	for p in row:
		e.pair_click(_mid(e, p), true)
	e._overlay.queue_redraw()
	await get_tree().process_frame
	assert_eq(e.pair_picks.size(), 4, "drawn without error")


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


func test_unpair_of_one_selected_removes_all_its_pairs() -> void:
	var e := _editor()
	var row := _row(e)
	e.document.make_chain(row)
	e.select_at(_mid(e, row[1]))
	assert_true(e.unpair_button.visible)
	assert_true(e.unpair_selected())
	var r := _refs(row)
	assert_eq(_pair_refs(e), [[r[2], r[3]]], "both of B's pairs go, C-D stays")


func test_unpair_with_two_picked_removes_only_their_pair() -> void:
	var e := _editor()
	var row := _row(e)
	var r := _refs(row)
	e.document.make_chain(row)
	e.set_pair_tool(true)
	e.pair_click(_mid(e, row[1]), true)
	assert_true(e.unpair_button.visible, "one picked with pairs")
	e.pair_click(_mid(e, row[2]), true)
	assert_true(e.unpair_button.visible, "two picked that are a pair")
	e.unpair_button.pressed.emit()
	assert_eq(_pair_refs(e), [[r[0], r[1]], [r[2], r[3]]], "only B-C goes")
	assert_true(e.pair_picks.is_empty())


func test_unpair_with_one_picked_removes_all_its_pairs() -> void:
	var e := _editor()
	var row := _row(e)
	var r := _refs(row)
	e.document.make_chain(row)
	e.set_pair_tool(true)
	e.pair_click(_mid(e, row[2]), true)
	assert_true(e.unpair_selected())
	assert_eq(_pair_refs(e), [[r[0], r[1]]])


func test_unpair_with_a_picked_row_undoes_the_chain_only() -> void:
	var e := _editor()
	var row := _row(e)
	var r := _refs(row)
	e.document.make_chain(row)
	e.document.make_pair(row[0], row[3])
	e.set_pair_tool(true)
	for p in row:
		e.pair_click(_mid(e, p), true)
	assert_true(e.unpair_selected())
	assert_eq(_pair_refs(e), [[r[0], r[3]]], "A-D was not between consecutive picks: it stays")


func test_unpair_hides_for_two_picked_that_are_no_pair() -> void:
	var e := _editor()
	var row := _row(e)
	e.document.make_pair(row[0], row[1])
	e.set_pair_tool(true)
	e.pair_click(_mid(e, row[2]), true)
	e.pair_click(_mid(e, row[3]), true)
	assert_false(e.unpair_button.visible)
	assert_false(e.unpair_selected())
	assert_eq(e.document.pairs().size(), 1)


func test_deleting_the_middle_of_a_chain_keeps_the_rest() -> void:
	var e := _editor()
	var row := _row(e)
	var r := _refs(row)
	e.document.make_chain(row)
	e.select_at(_mid(e, row[1]))
	e.delete_selected()
	assert_eq(_pair_refs(e), [[r[2], r[3]]])


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


func test_a_chain_is_saved_reopened_and_passes_check_level() -> void:
	var e := _editor()
	var row := _row(e)
	var r := _refs(row)
	e.set_pair_tool(true)
	for p in row:
		e.pair_click(_mid(e, p), true)
	e.pair_picked_row()
	e.name_field.text = "T-394 chain"
	assert_eq(e.save(), OK)
	var saved := LevelStore.load_level(e.level_path)
	assert_eq(saved.pairs.map(func(p): return [p.a, p.b]), [[r[0], r[1]], [r[1], r[2]], [r[2], r[3]]], "a pair per entry")
	var res := _check_level(e.level_path)
	assert_eq(res[0], 0, res[1])
	var e2 := _editor()
	e2.open_level(e.level_path)
	assert_eq(_pair_refs(e2), _pair_refs(e))
	assert_eq(e2.document.pairs_with(e2.document.piece_at(_mid(e, row[1]))).size(), 2)


func test_a_level_saved_before_opens_with_its_pairs() -> void:
	# A T-272 file: {id, a, b} entries, each obstacle in one pair.
	var d := LevelDocument.new_level_data("T-272 old")
	d.pattern_copies = [{"id": "boulder-1", "boulders": [{"x": -3.0, "y": -40.0, "diameter": 3.0, "variant": "a"}]},
		{"id": "boulder-2", "boulders": [{"x": 3.0, "y": -40.0, "diameter": 3.0, "variant": "b"}]}]
	d["pairs"] = [{"id": "pair-1", "a": "boulder-1", "b": "boulder-2"}]
	var path := RunPaths.file("t394_old_level.json")
	assert_eq(LevelStore.save_level(path, d), OK)
	var e := _editor()
	e.open_level(path)
	assert_eq(_pair_refs(e), [["boulder-1", "boulder-2"]])
	var c := _place(e, "prop-crates", Vector2(10, -39))
	e.document.make_pair(e.document.piece_of_ref("boulder-2"), c)
	assert_eq(e.document.pairs().size(), 2, "and it chains on")
	assert_eq(e.document.pairs()[1].id, "pair-2")


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
