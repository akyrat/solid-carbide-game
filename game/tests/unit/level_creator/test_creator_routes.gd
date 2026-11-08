extends GutTest
## Task T-592: needle routes in the level creator (Level design, Decisions, "Needle routes"; T-591's
## texts). With the route tool (the top bar's Route, key N), clicking pairs' dashed lines makes a route
## in click order; the order switch (In order, Random) and Remove from route work; routes are saved in
## the level file, reopened and accepted by check_level.py; a pair that goes leaves its route.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")


func _editor() -> LevelCreatorEditor:
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.open_new()
	e.levels_dir = RunPaths.file("t592_levels")
	add_child_autofree(e)
	return e


func _place(e: LevelCreatorEditor, asset: String, at: Vector2) -> Dictionary:
	e.panel.pick(asset)
	var p := e.place_asset(asset, at)
	assert_false(p.is_empty(), "%s placed at %s" % [asset, at])
	e.panel.pick("")
	return p


func _mid(e: LevelCreatorEditor, piece: Dictionary) -> Vector2:
	return e.document.piece_rect(piece).get_center()


## Three boulder pairs across x, at y -20, -30 and -40: [pair ids], [[a, b] pieces].
func _three_pairs(e: LevelCreatorEditor) -> Array:
	var ids: Array = []
	var pieces: Array = []
	for i in 3:
		var y := -20.0 - 10.0 * i
		var a := _place(e, "boulder-a", Vector2(-6, y))
		var b := _place(e, "boulder-b", Vector2(4, y))
		var p := e.document.make_pair(a, b)
		ids.append(str(p.id))
		pieces.append([a, b])
	return [ids, pieces]


## The middle of pair `pair_id`'s dashed line in the map view's pixels (where a click picks it).
func _line_local(e: LevelCreatorEditor, pair_id: String) -> Vector2:
	var line := ObstaclePairs.line_of(e.document.data, e.document.pair_by_id(pair_id))
	var a := e.map_px_at(line.gap_a, e.document.height_at(line.a))
	var b := e.map_px_at(line.gap_b, e.document.height_at(line.b))
	return e.viewport.get_canvas_transform() * ((a + b) / 2.0)


func _key(e: LevelCreatorEditor, keycode: Key) -> void:
	var k := InputEventKey.new()
	k.keycode = keycode
	k.pressed = true
	e._unhandled_key_input(k)


func _click(e: LevelCreatorEditor, local: Vector2, button := MOUSE_BUTTON_LEFT) -> void:
	var mb := InputEventMouseButton.new()
	mb.button_index = button
	mb.pressed = true
	mb.position = local
	e._on_map_input(mb)


func _check_level(path: String) -> Array:
	var output: Array = []
	var code := OS.execute("python", [ProjectSettings.globalize_path("res://tools/check_level.py"),
		ProjectSettings.globalize_path(path)], output, true)
	return [code, "\n".join(output)]


# ---- The tool and its texts ---------------------------------------------------------------------

func test_the_texts_are_t591s_and_n_is_the_key() -> void:
	var e := _editor()
	assert_eq(e.route_button.text, CreatorTexts.get_text("route_tool"))
	assert_eq(e.route_order_buttons["in_order"].text, CreatorTexts.get_text("route_order_in_order"))
	assert_eq(e.route_order_buttons["random"].text, CreatorTexts.get_text("route_order_random"))
	assert_eq(e.route_remove_button.text, CreatorTexts.get_text("route_remove_pair"))
	assert_eq(e.hint_label.text, CreatorTexts.get_text("controls_hint_routes"))
	assert_string_contains(e.hint_label.text, "N: route.")
	assert_eq(LevelCreatorEditor.KEY_ACTIONS.get(KEY_N), "route")
	assert_false(e.route_order_buttons["in_order"].visible, "the switch shows only with the tool on")


func test_n_turns_the_tool_on_and_off_and_drops_the_pair_tool() -> void:
	var e := _editor()
	e.set_pair_tool(true)
	_key(e, KEY_N)
	assert_true(e.route_mode)
	assert_false(e.pair_mode, "one tool at a time")
	assert_true(e.route_button.button_pressed)
	assert_eq(e.size_label.text, CreatorTexts.get_text("route_hint"))
	assert_true(e.route_order_buttons["random"].visible)
	e.set_pair_tool(true)
	assert_false(e.route_mode, "the pair tool turns the route tool off")
	e.set_route_tool(true)
	_key(e, KEY_N)
	assert_false(e.route_mode)


# ---- Making a route -----------------------------------------------------------------------------

func test_clicking_pair_lines_makes_a_route_in_click_order() -> void:
	var e := _editor()
	var ids: Array = _three_pairs(e)[0]
	e.set_route_tool(true)
	_click(e, _line_local(e, ids[2]))
	assert_eq(e.message_label.text, CreatorTexts.get_text("route_pair_added") % 1)
	_click(e, _line_local(e, ids[0]))
	_click(e, _line_local(e, ids[1]))
	assert_eq(e.message_label.text, CreatorTexts.get_text("route_pair_added") % 3)
	var routes := e.document.routes()
	assert_eq(routes.size(), 1)
	assert_eq(routes[0].pairs, [ids[2], ids[0], ids[1]], "in click order")
	assert_eq(routes[0].order, "in_order", "in order by default")
	_key(e, KEY_N)
	assert_eq(e.message_label.text, CreatorTexts.get_text("route_finished"))


func test_a_click_away_from_any_line_adds_nothing() -> void:
	var e := _editor()
	var ids: Array = _three_pairs(e)[0]
	e.set_route_tool(true)
	assert_eq(e.route_click(_line_local(e, ids[0]) + Vector2(0, 200)), "none")
	assert_true(e.document.routes().is_empty())


func test_a_right_click_finishes_the_route_and_the_next_click_starts_another() -> void:
	var e := _editor()
	var ids: Array = _three_pairs(e)[0]
	e.set_route_tool(true)
	_click(e, _line_local(e, ids[0]))
	_click(e, _line_local(e, ids[1]))
	_click(e, Vector2(5, 5), MOUSE_BUTTON_RIGHT)
	assert_eq(e.message_label.text, CreatorTexts.get_text("route_finished"))
	assert_true(e.route_mode, "the tool stays on for the next route")
	_click(e, _line_local(e, ids[2]))
	var routes := e.document.routes()
	assert_eq(routes.size(), 2)
	assert_eq(routes[1].pairs, [ids[2]])
	_key(e, KEY_ESCAPE)
	assert_false(e.route_mode, "Esc finishes it and turns the tool off")


func test_clicking_a_pair_of_a_route_selects_it_and_later_clicks_add_to_that_route() -> void:
	var e := _editor()
	var ids: Array = _three_pairs(e)[0]
	e.set_route_tool(true)
	e.route_click_pair(ids[0])
	e.finish_route()
	assert_eq(e.route_click_pair(ids[0]), "selected")
	assert_eq(e.route_pair_selected, ids[0])
	assert_true(e.route_remove_button.visible)
	assert_eq(e.route_click_pair(ids[1]), "added")
	assert_eq(e.document.routes().size(), 1)
	assert_eq(e.document.routes()[0].pairs, [ids[0], ids[1]])


func test_a_pair_is_in_one_route_at_most() -> void:
	var e := _editor()
	var ids: Array = _three_pairs(e)[0]
	e.set_route_tool(true)
	e.route_click_pair(ids[0])
	e.route_click_pair(ids[1])
	e.finish_route()
	e.route_click_pair(ids[2])  # a new route
	e.route_click_pair(ids[1])  # moves here from the first
	var routes := e.document.routes()
	assert_eq(routes.size(), 2)
	assert_eq(routes[0].pairs, [ids[0]])
	assert_eq(routes[1].pairs, [ids[2], ids[1]])


func test_the_order_switch_sets_the_routes_order() -> void:
	var e := _editor()
	var ids: Array = _three_pairs(e)[0]
	e.set_route_tool(true)
	e.route_click_pair(ids[0])
	e.route_click_pair(ids[1])
	e.route_order_buttons["random"].emit_signal("pressed")
	assert_eq(e.document.routes()[0].order, "random")
	assert_true(e.route_order_buttons["random"].button_pressed)
	assert_false(e.route_order_buttons["in_order"].button_pressed)
	e.set_route_order("in_order")
	assert_eq(e.document.routes()[0].order, "in_order")
	# Chosen before the first click: the new route gets it.
	e.finish_route()
	e.set_route_order("random")
	e.route_click_pair(ids[2])
	assert_eq(e.document.routes()[1].order, "random")


func test_remove_from_route_takes_the_pair_out_and_an_empty_route_goes() -> void:
	var e := _editor()
	var ids: Array = _three_pairs(e)[0]
	e.set_route_tool(true)
	e.route_click_pair(ids[0])
	e.route_click_pair(ids[1])
	e.route_click_pair(ids[0])  # selects it
	e.route_remove_button.emit_signal("pressed")
	assert_eq(e.document.routes()[0].pairs, [ids[1]])
	assert_eq(e.document.pairs().size(), 3, "the pair stays, in no route")
	assert_false(e.route_remove_button.visible)
	e.route_click_pair(ids[1])
	assert_true(e.remove_pair_from_route())
	assert_true(e.document.routes().is_empty())
	assert_false(e.document.data.has("routes"), "no routes left: the file has none, as before")


func test_a_pair_that_goes_leaves_its_route() -> void:
	var e := _editor()
	var made: Array = _three_pairs(e)
	var ids: Array = made[0]
	e.set_route_tool(true)
	for id in ids:
		e.route_click_pair(id)
	e.set_route_tool(false)
	e.selected = made[1][0][0]
	e.unpair_selected()
	assert_eq(e.document.routes()[0].pairs, [ids[1], ids[2]])
	e.delete_piece(made[1][2][1])  # an obstacle of the third pair
	assert_eq(e.document.routes()[0].pairs, [ids[1]])


func test_routes_draw_without_error() -> void:
	var e := _editor()
	var ids: Array = _three_pairs(e)[0]
	e.set_route_tool(true)
	e.route_click_pair(ids[0])
	e.route_click_pair(ids[1])
	e._overlay.queue_redraw()
	await wait_frames(2)
	assert_true(true)


# ---- Saving -------------------------------------------------------------------------------------

func test_routes_save_reopen_and_pass_the_level_check() -> void:
	var e := _editor()
	var ids: Array = _three_pairs(e)[0]
	e.set_route_tool(true)
	e.route_click_pair(ids[1])
	e.route_click_pair(ids[0])
	e.set_route_order("random")
	e.finish_route()
	e.route_click_pair(ids[2])
	e.set_route_tool(false)
	e.name_field.text = "T-592 routes"
	assert_eq(e.save(), OK)
	var path := e.level_path
	var back := LevelStore.load_level(path)
	assert_eq(back.routes.size(), 2)
	assert_eq(back.routes[0], {"id": "route-1", "order": "random", "pairs": [ids[1], ids[0]]})
	assert_eq(back.routes[1].pairs, [ids[2]])
	var e2 := _editor()
	e2.open_level(path)
	assert_eq(e2.document.routes().size(), 2)
	assert_eq(e2.document.route_of_pair(ids[0]).id, "route-1")
	var res := _check_level(path)
	assert_eq(res[0], 0, res[1])


func test_a_level_without_routes_saves_none() -> void:
	var e := _editor()
	_three_pairs(e)
	e.name_field.text = "T-592 no routes"
	assert_eq(e.save(), OK)
	assert_false(LevelStore.load_level(e.level_path).has("routes"))
