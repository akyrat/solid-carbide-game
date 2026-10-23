extends GutTest
## Task T-251: in the level creator, rooftops of any even size from 4 x 4 (heights 3 and 6, a 6 on a
## 3 or on the street) and ramps climbing in all four directions (0 to 3, 3 to 6 and 0 to 6), sized
## by dragging, drawn in the engine from the piece style's textures; the saved level passes
## check_level.py, the game's own map still draws its art, and enemies find their way up a new ramp.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const Level := preload("res://tests/fixtures/level_creator_pieces_level.gd")
const ElevationLayerScript := preload("res://scripts/level/elevation_layer.gd")
const EnemyNavigationScript := preload("res://scripts/enemies/enemy_navigation.gd")
const MapScene := preload("res://scenes/level/mvp_map.tscn")
const STYLE_PATH := "res://art/creator_pieces/piece_style.tres"


func _editor() -> LevelCreatorEditor:
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.open_new()
	add_child_autofree(e)
	return e


func _pick(e: LevelCreatorEditor, id: String, view: String = "") -> void:
	e.panel.pick(id)
	for i in 4:
		if view == "" or e.pick_view == view:
			return
		e.rotate_pick()


func _run_check_level(data: Dictionary, file_name: String) -> Array:
	var path := RunPaths.file(file_name)
	assert_eq(LevelStore.save_level(path, data), OK)
	var output: Array = []
	var code := OS.execute("python", [ProjectSettings.globalize_path("res://tools/check_level.py"),
		ProjectSettings.globalize_path(path)], output, true)
	return [code, "\n".join(output)]


func _r(item: Dictionary) -> Rect2:
	return Rect2(float(item.x), float(item.y), float(item.w), float(item.h))


# ---- Sizes --------------------------------------------------------------------------------------

func test_a_rooftop_takes_any_even_size_from_4_by_4_up_to_the_map() -> void:
	for id in ["rooftop-3", "rooftop-6"]:
		assert_true(LevelDocument.is_resizable(id))
		assert_eq(LevelDocument.piece_size(id, "", Vector2(4, 4)), Vector2(4, 4))
		assert_eq(LevelDocument.piece_size(id, "", Vector2(6, 22)), Vector2(6, 22))
		assert_eq(LevelDocument.piece_size(id, "", Vector2(5, 9)), Vector2(6, 10), "odd sizes: whole cells")
		assert_eq(LevelDocument.piece_size(id, "", Vector2(2, 2)), Vector2(4, 4), "at least 4 x 4")
		assert_eq(LevelDocument.piece_size(id, "", Vector2(500, 300)), Vector2(240, 240), "at most the map")
		assert_eq(LevelDocument.piece_size(id), Vector2(LevelDocument.entry(id).footprint_units[0],
			LevelDocument.entry(id).footprint_units[1]), "no size: the default")


func test_a_ramp_takes_a_width_along_its_side_and_a_fixed_length_per_direction() -> void:
	var lengths := {"ramp-0-3": 12.0, "ramp-3-6": 12.0, "ramp-0-6": 24.0}
	for id in lengths:
		var l: float = lengths[id]
		assert_eq(LevelDocument.piece_size(id, "north", Vector2(6, 99)), Vector2(6, l), id + " north")
		assert_eq(LevelDocument.piece_size(id, "south", Vector2(14, 0)), Vector2(14, l), id + " south")
		assert_eq(LevelDocument.piece_size(id, "east", Vector2(99, 8)), Vector2(l, 8), id + " east")
		assert_eq(LevelDocument.piece_size(id, "west", Vector2(0, 2)), Vector2(l, 4), id + " west: at least 4")
		assert_eq(LevelDocument.piece_size(id, "west"), Vector2(l, 10), id + ": default width 10")


func test_rooftops_of_many_sizes_at_3_and_6_place_and_pass_check_level() -> void:
	var e := _editor()
	var sizes := [Vector2(4, 4), Vector2(6, 4), Vector2(4, 12), Vector2(20, 8), Vector2(36, 36), Vector2(10, 30)]
	var x := -116.0
	for s in sizes:
		for id in ["rooftop-3", "rooftop-6"]:
			e.panel.pick(id)
			var p := e.place_asset(id, Vector2(x + 1, (-110.0 if id == "rooftop-3" else 0.0) + 1), s)
			assert_false(p.is_empty(), "%s %s placed" % [id, s])
			assert_eq(_r(p.item).size, s, "%s %s keeps its size" % [id, s])
			assert_false(p.item.has("on"), "on the street")
		x += 40.0
	# A 6 of each size on a big 3.
	e.panel.pick("rooftop-3")
	var big := e.place_asset("rooftop-3", Vector2(-115, 61), Vector2(230, 56))
	assert_false(big.is_empty())
	x = -110.0
	for s in [Vector2(4, 4), Vector2(12, 6), Vector2(20, 20)]:
		e.panel.pick("rooftop-6")
		var p6 := e.place_asset("rooftop-6", Vector2(x + 1, 81), s)
		assert_eq(_r(p6.item).size, s)
		assert_eq(p6.item.on, big.item.id, "a 6 on the 3")
		x += 40.0
	var res := _run_check_level(e.level_data, "t251_rooftops.json")
	assert_eq(res[0], 0, "check_level.py: " + res[1])


func test_the_multi_layer_level_has_ramps_in_all_four_directions_and_passes_check_level() -> void:
	var e := _editor()
	var placed := Level.build(e)
	for i in placed.size():
		assert_false(placed[i].is_empty(), "step %d placed: %s" % [i, Level.STEPS[i]])
	var d := e.level_data
	assert_eq(d.platforms.size(), 4)
	assert_eq(d.ramps.size(), 6)
	var sides := {}
	for r in d.ramps:
		assert_ne(str(r.platform), "", "%s climbs a rooftop" % r.id)
		assert_false(r.has("art"))
		sides["%s %d-%d" % [r.side, int(r.bottom_height), int(r.top_height)]] = true
	for k in ["south 0-3", "west 0-3", "east 0-3", "north 3-6", "west 3-6", "south 0-6"]:
		assert_true(sides.has(k), "a ramp up a %s side" % k)
	assert_eq(d.platforms[1].on, d.platforms[0].id, "the 6 stands on the big 3")
	assert_false(d.platforms[3].has("on"), "the other 6 on the street")
	# The heights the car drives: up each ramp to its rooftop.
	var g = e.elevation.ground_height
	assert_almost_eq(g.height_at(Vector2(-21, 16.5)), 3.0, 0.2, "top of the 0 to 3 north")
	assert_almost_eq(g.height_at(Vector2(-21, 27.5)), 0.0, 0.2, "its foot")
	assert_almost_eq(g.height_at(Vector2(5, -15.5)), 3.0, 0.2, "foot of the 3 to 6 south, on the 3")
	assert_almost_eq(g.height_at(Vector2(5, -4.5)), 6.0, 0.3, "its top")
	assert_almost_eq(g.height_at(Vector2(-22, 79.5)), 0.0, 0.2, "foot of the 0 to 6")
	assert_almost_eq(g.height_at(Vector2(-22, 56.5)), 6.0, 0.2, "its top")
	var res := _run_check_level(e.level_data, "t251_level.json")
	assert_eq(res[0], 0, "check_level.py: " + res[1])


# ---- Dragging to size ---------------------------------------------------------------------------

func _press(e: LevelCreatorEditor, units: Vector2, pressed: bool) -> void:
	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.pressed = pressed
	mb.position = e.units_to_screen(units)
	e._on_map_input(mb)


func _move(e: LevelCreatorEditor, units: Vector2) -> void:
	var mm := InputEventMouseMotion.new()
	mm.position = e.units_to_screen(units)
	e._on_map_input(mm)


func test_dragging_sizes_a_rooftop_and_the_top_bar_shows_the_size() -> void:
	var e := _editor()
	e.panel.pick("rooftop-3")
	assert_eq(e.size_label.text, CreatorTexts.get_text("size_hint"))
	_press(e, Vector2(10.5, 20.5), true)
	assert_eq(e.level_data.platforms.size(), 0, "nothing placed on the press")
	_move(e, Vector2(25.5, 27.5))
	assert_eq(e.size_label.text, CreatorTexts.get_text("size_readout").format({"w": 16, "d": 8}))
	assert_eq(e.preview_block().rect, Rect2(10, 20, 16, 8))
	_press(e, Vector2(25.5, 27.5), false)
	assert_eq(e.level_data.platforms.size(), 1)
	assert_eq(_r(e.level_data.platforms[0]), Rect2(10, 20, 16, 8))
	# Dragged up and to the left: the same cells.
	_press(e, Vector2(-30.5, -40.5), true)
	_move(e, Vector2(-41.5, -51.5))
	_press(e, Vector2(-41.5, -51.5), false)
	assert_eq(_r(e.level_data.platforms[1]), Rect2(-42, -52, 12, 12))
	# A click: the default size.
	_press(e, Vector2(-9.5, 70.5), true)
	_press(e, Vector2(-9.5, 70.5), false)
	assert_eq(_r(e.level_data.platforms[2]).size, Vector2(16, 16), "T-264: a click is M, 16 x 16")


func test_dragging_a_ramp_sets_only_its_width_along_the_side() -> void:
	var e := _editor()
	_pick(e, "ramp-0-3", "east")
	assert_eq(e.direction_label.text, CreatorTexts.get_text("ramp_dir_east"))
	_press(e, Vector2(30.5, 30.5), true)
	_move(e, Vector2(41.5, 35.5))  # 6 cells east, 3 south: only south counts for an east ramp
	_press(e, Vector2(41.5, 35.5), false)
	assert_eq(_r(e.level_data.ramps[0]), Rect2(30, 30, 12, 6), "3 cells wide, its length fixed")
	assert_eq(e.level_data.ramps[0].side, "west")


func test_the_hint_and_labels_come_from_the_texts() -> void:
	var e := _editor()
	assert_eq(e.hint_label.text, CreatorTexts.get_text("controls_hint_spawn"))  # T-280: the line with moving the start.
	_pick(e, "ramp-0-6", "south")
	assert_eq(e.height_label.text, CreatorTexts.get_text("ramp_height_0_6"))
	assert_eq(e.direction_label.text, CreatorTexts.get_text("ramp_dir_south"))
	e.panel.pick("boulder-a")
	assert_eq(e.direction_label.text, "")
	assert_eq(e.size_label.text, "")


# ---- Drawn in the engine ------------------------------------------------------------------------

func test_new_pieces_are_drawn_from_the_one_piece_style() -> void:
	var e := _editor()
	Level.build(e)
	var style = load(STYLE_PATH)
	assert_eq(ElevationLayerScript.piece_style(), style, "the layer's style is the one resource")
	var allowed := [style.roof_top, style.wall, style.ramp_top, style.ramp_side, style.parapet]
	assert_eq(e.elevation.areas.size(), 10)
	for a in e.elevation.areas:
		assert_true(a.is_textured(), "%s drawn in the engine" % a.block.id)
		# Ramps tile plainly since T-255 (ramp_plain_repeat: their arrows keep pointing one way).
		assert_eq(a.texture_repeat, CanvasItem.TEXTURE_REPEAT_ENABLED if a.kind == "ramp" else CanvasItem.TEXTURE_REPEAT_MIRROR)
		assert_eq(a.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
		var faces: Array = a.textured_faces()
		assert_true(faces.any(func(f): return f.name == "top"), "%s has its top" % a.block.id)
		for f in faces:
			assert_true(f.texture in allowed, "%s %s: a style texture" % [a.block.id, f.name])
		assert_gt(a.outline_segments().size(), 0, "with an outline")


func test_walls_start_on_what_a_piece_stands_on_and_a_ramp_has_a_wall_at_its_top() -> void:
	var e := _editor()
	Level.build(e)
	var by_id := {}
	for a in e.elevation.areas:
		by_id[str(a.block.id)] = a
	var six = by_id[str(e.level_data.platforms[1].id)]
	assert_eq(six.base, 3.0, "the 6 on the 3: walls from 3")
	assert_eq(by_id[str(e.level_data.platforms[3].id)].base, 0.0, "the 6 on the street: from 0")
	for a in e.elevation.areas:
		if a.kind != "ramp":
			continue
		var names: Array = a.textured_faces().map(func(f): return f.name)
		# T-264: a ramp is closed, its tall end has its wall (test_creator_ramps.gd).
		assert_true(a.join_edge() in names, "%s: a wall at its top end" % a.block.id)
	# The big 3's parapet breaks where the 3 to 6 on it climbs south (its north edge is the 6's).
	var big = by_id[str(e.level_data.platforms[0].id)]
	assert_false(big.edge_gaps.south.is_empty(), "a ramp meets the 3's south edge")
	assert_false(big.edge_gaps.west.is_empty(), "and its west edge")


func test_the_game_map_still_draws_its_own_art() -> void:
	var map: Node2D = MapScene.instantiate()
	map.layout_path = "res://data/level/elevation_sample_map.json"
	add_child_autofree(map)
	var layer = ElevationLayerScript.new()
	map.add_child(layer)
	layer.setup(map, "res://data/level/elevation_sample_map.json")
	assert_eq(layer.areas.size(), 8)
	for a in layer.areas:
		assert_not_null(a.art_sprite, "%s keeps its art" % a.block.id)
		assert_false(a.is_textured())
		assert_eq(a.art_sprite.texture.resource_path, "res://art/elevation_sample/%s.png" % a.block.id)


func test_no_redgull_red_in_the_piece_textures() -> void:
	var style = load(STYLE_PATH)
	for tex in [style.roof_top, style.wall, style.ramp_top, style.ramp_side, style.parapet]:
		var img: Image = tex.get_image()
		var red := 0
		for y in range(0, img.get_height()):
			for x in range(0, img.get_width()):
				var c := img.get_pixel(x, y)
				if c.a > 0.5 and c.r8 > 110 and c.g8 < 60 and c.b8 < 70:
					red += 1
		assert_eq(red, 0, "%s has no Redgull red" % tex.resource_path)


# ---- Enemies ------------------------------------------------------------------------------------

func test_enemies_path_up_the_new_ramps() -> void:
	var e := _editor()
	Level.build(e)
	var g = e.elevation.ground_height
	var nav = EnemyNavigationScript.new()
	nav.build(e.document.map_rect(), [], g)
	# From the street to the 6 on the street: only the 0 to 6 leads up.
	var path: PackedVector2Array = nav.find_path(Vector2(-60, 90), Vector2(-22, 48))
	assert_gt(path.size(), 1, "a path up the 0 to 6")
	var ramp_index := -1
	for i in g.ramps.size():
		if int(g.ramps[i].bottom_height) == 0 and int(g.ramps[i].top_height) == 6:
			ramp_index = i
	assert_true(path.has(nav.ramp_end(ramp_index, false)), "through the ramp's foot")
	assert_true(path.has(nav.ramp_end(ramp_index, true)), "and its top")
	assert_almost_eq(g.height_at(path[path.size() - 1]), 6.0, 0.01, "ends on the 6")
	# From the street onto the 6 on the 3: up a 0 to 3, then a 3 to 6.
	var up: PackedVector2Array = nav.find_path(Vector2(-60, 20), Vector2(3, 2))
	assert_gt(up.size(), 1, "a path onto the 6 on the 3")
	assert_almost_eq(g.height_at(up[up.size() - 1]), 6.0, 0.01)
	var tops_36 := []
	for i in g.ramps.size():
		if int(g.ramps[i].bottom_height) == 3:
			tops_36.append(nav.ramp_end(i, true))
	assert_true(Array(up).any(func(p): return p in tops_36), "up one of the new 3 to 6 ramps")
