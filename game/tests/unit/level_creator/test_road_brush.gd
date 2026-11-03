extends GutTest
## Task T-263: roads are painted with a brush (road_brush.gd, editor.gd paint_road). A drag lays a
## full-width road (2 x 2 tiles per block) along it, and where painted roads meet the brush picks
## the piece itself: straights along y and x, corners, T-junctions, crossroads, dead ends, for each
## road kind (Road, Centre line, Cracked road). Erasing re-joins the neighbours; a zebra crossing
## is clicked across a straight road; a road never paints over a building, platform or ramp. The
## saved data is the same ground data as before, so a painted level passes check_level.py and plays.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const Grid := preload("res://tests/fixtures/level_creator_road_brush_grid.gd")
const OLD_LEVEL := "res://tests/fixtures/t262_level_saved_before.json"
## Each paint kind and the asphalt of its first look.
const KINDS := {"road": "a0", "centre-line": "a0", "cracked-road": "g4"}

var dir: String


func before_each() -> void:
	dir = RunPaths.file("t263_levels_" + str(randi()))


func _editor(path: String = "") -> LevelCreatorEditor:
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.levels_dir = dir
	if path == "":
		e.open_new()
	else:
		e.open_level(path)
	add_child_autofree(e)
	return e


## The middle of block `b` (map blocks) in units.
func _at(e: LevelCreatorEditor, b: Vector2i) -> Vector2:
	return RoadBrush.block_rect(e.document, b).get_center()


func _tiles(e: LevelCreatorEditor, b: Vector2i) -> Array:
	var out: Array = []
	for r in 2:
		out.append([e.document.tile_at(b * 2 + Vector2i(0, r)), e.document.tile_at(b * 2 + Vector2i(1, r))])
	return out


func _piece(e: LevelCreatorEditor, b: Vector2i) -> String:
	return RoadBrush.piece_of(RoadBrush.arms_of(b, func(x): return RoadBrush.state_of(e.document, x)))


func _paint(e: LevelCreatorEditor, family: String, blocks: Array) -> void:
	e.panel.pick(family)
	e.paint_road(blocks.map(func(b): return _at(e, b)))


func _check_level(path: String) -> Array:
	var output: Array = []
	var code := OS.execute("python", [ProjectSettings.globalize_path("res://tools/check_level.py"),
		ProjectSettings.globalize_path(path)], output, true)
	return [code, "\n".join(output)]


# ---- A drag paints a full-width road ------------------------------------------------------------

func test_a_drag_paints_a_full_width_road_along_it() -> void:
	for kind in KINDS:
		var e := _editor()
		var a: String = KINDS[kind]
		_paint(e, kind, [Vector2i(30, 20), Vector2i(30, 26)])
		for j in range(20, 27):
			var b := Vector2i(30, j)
			assert_false(RoadBrush.state_of(e.document, b).is_empty(), "%s block %s is road" % [kind, b])
			assert_eq(str(RoadBrush.state_of(e.document, b).kind), kind)
		for j in range(21, 26):
			var t := _tiles(e, Vector2i(30, j))
			if kind == "centre-line":
				# The line in the middle: on the edge between the two tiles across the road.
				assert_eq(t, [["road-y_line_r_a0", "road-y_line_l_a0"], ["road-y_line_r_a0", "road-y_line_l_a0"]], kind)
			else:
				assert_eq(t, [["road-y_plain_" + a, "road-y_plain_" + a], ["road-y_plain_" + a, "road-y_plain_" + a]], kind)
		# Both ends are dead ends; the road is two tiles (4 units) wide, nothing beside it is road.
		assert_eq(_piece(e, Vector2i(30, 20)), "dead_s", kind)
		assert_eq(_piece(e, Vector2i(30, 26)), "dead_n", kind)
		assert_true(RoadBrush.state_of(e.document, Vector2i(29, 23)).is_empty())
		assert_true(RoadBrush.state_of(e.document, Vector2i(31, 23)).is_empty())
		var rows: Array = e.level_data.ground_rows
		var y := 23 * 4 + 1
		assert_eq(str(rows[y]).substr(30 * 4 - 1, 6), "GRRRRG", "a 4-unit road in ground_rows")
		# Along x too.
		_paint(e, kind, [Vector2i(10, 40), Vector2i(16, 40)])
		assert_eq(_piece(e, Vector2i(13, 40)), "straight_x")
		var tx := _tiles(e, Vector2i(13, 40))
		if kind == "centre-line":
			assert_eq(tx, [["road-x_line_r_a0", "road-x_line_r_a0"], ["road-x_line_l_a0", "road-x_line_l_a0"]])
		else:
			assert_eq(tx[0][0], "road-x_plain_" + a)


func test_a_diagonal_drag_leaves_no_gap() -> void:
	var e := _editor()
	_paint(e, "road", [Vector2i(10, 10), Vector2i(14, 13)])
	var path := RoadBrush.blocks_between(Vector2i(10, 10), Vector2i(14, 13))
	assert_eq(path.size(), 4 + 3 + 1)
	for i in range(1, path.size()):
		assert_eq((path[i] - path[i - 1]).abs().x + (path[i] - path[i - 1]).abs().y, 1, "each block next to the one before")
	for b in path:
		assert_false(RoadBrush.state_of(e.document, b).is_empty(), str(b))


func test_painting_by_mouse_left_drag_paints_right_drag_erases() -> void:
	var e := _editor()
	await wait_process_frames(2)
	e.panel.pick("centre-line")
	assert_eq(e.size_label.text, CreatorTexts.get_text("road_brush_hint"), "the top bar's brush hint")
	var from := e.units_to_screen(_at(e, Vector2i(30, 30)))
	var to := e.units_to_screen(_at(e, Vector2i(36, 30)))
	_mouse_button(e, from, MOUSE_BUTTON_LEFT, true)
	for k in range(1, 7):
		_mouse_move(e, from.lerp(to, k / 6.0))
	_mouse_button(e, to, MOUSE_BUTTON_LEFT, false)
	for i in range(30, 37):
		assert_false(RoadBrush.state_of(e.document, Vector2i(i, 30)).is_empty(), "painted %d" % i)
	assert_eq(e.map.ground_layout.cells[60][66], int(LevelDocument.entry(e.document.tile_at(Vector2i(66, 60))).atlas_index), "drawn")
	# Right-drag over the last two blocks erases them; the road's end becomes a dead end again.
	var back := e.units_to_screen(_at(e, Vector2i(35, 30)))
	_mouse_button(e, to, MOUSE_BUTTON_RIGHT, true)
	_mouse_move(e, back)
	_mouse_button(e, back, MOUSE_BUTTON_RIGHT, false)
	assert_true(RoadBrush.state_of(e.document, Vector2i(36, 30)).is_empty())
	assert_true(RoadBrush.state_of(e.document, Vector2i(35, 30)).is_empty())
	assert_eq(e.document.tile_at(Vector2i(72, 60)), LevelDocument.BASE_GROUND)
	assert_eq(_piece(e, Vector2i(34, 30)), "dead_w")
	assert_eq(e.document.tile_at(Vector2i(68, 60)), "road-piece_dead_w_00")
	# Del erases the block under the mouse.
	_mouse_move(e, e.units_to_screen(_at(e, Vector2i(34, 30))))
	var k := InputEventKey.new()
	k.keycode = KEY_DELETE
	k.pressed = true
	e._unhandled_key_input(k)
	assert_true(RoadBrush.state_of(e.document, Vector2i(34, 30)).is_empty())
	assert_eq(_piece(e, Vector2i(33, 30)), "dead_w")


func _mouse_button(e: LevelCreatorEditor, at: Vector2, button: MouseButton, pressed: bool) -> void:
	var mb := InputEventMouseButton.new()
	mb.button_index = button
	mb.pressed = pressed
	mb.position = at
	e._on_map_input(mb)


func _mouse_move(e: LevelCreatorEditor, at: Vector2) -> void:
	var mm := InputEventMouseMotion.new()
	mm.position = at
	e._on_map_input(mm)


# ---- Meeting roads join -------------------------------------------------------------------------

func test_meeting_roads_become_corners_t_junctions_crossroads_and_dead_ends_for_each_kind() -> void:
	for kind in KINDS:
		var e := _editor()
		var a: String = KINDS[kind]
		# A plus: a crossroads with four dead ends; an L: a corner; a T.
		_paint(e, kind, [Vector2i(10, 14), Vector2i(18, 14)])
		_paint(e, kind, [Vector2i(14, 10), Vector2i(14, 18)])
		_paint(e, kind, [Vector2i(30, 10), Vector2i(30, 16), Vector2i(36, 16)])
		_paint(e, kind, [Vector2i(40, 20), Vector2i(48, 20)])
		_paint(e, kind, [Vector2i(44, 21), Vector2i(44, 26)])
		var want := {
			Vector2i(14, 14): "cross", Vector2i(10, 14): "dead_e", Vector2i(18, 14): "dead_w",
			Vector2i(14, 10): "dead_s", Vector2i(14, 18): "dead_n", Vector2i(12, 14): "straight_x",
			Vector2i(14, 12): "straight_y", Vector2i(30, 16): "corner_ne", Vector2i(44, 20): "t_esw",
			Vector2i(44, 26): "dead_n",
		}
		for b in want:
			assert_eq(_piece(e, b), want[b], "%s %s" % [kind, b])
			var s := RoadBrush.state_of(e.document, b)
			assert_eq(_tiles(e, b), RoadBrush.tiles_for(kind, a, RoadBrush.arms_of(b, func(x): return RoadBrush.state_of(e.document, x)), {}),
				"%s %s tiles" % [kind, b])
			assert_eq(str(s.kind), kind, "%s keeps its kind at %s" % [kind, b])
		# The tiles each kind uses at a junction and a dead end.
		var cross := _tiles(e, Vector2i(14, 14))
		var dead := _tiles(e, Vector2i(14, 10))
		if kind == "centre-line":
			assert_eq(cross, [["road-piece_cross_00", "road-piece_cross_10"], ["road-piece_cross_01", "road-piece_cross_11"]])
			assert_eq(dead[0][0], "road-piece_dead_s_00")
			assert_eq(_tiles(e, Vector2i(30, 16))[1][1], "road-piece_corner_ne_11")
			assert_eq(_tiles(e, Vector2i(44, 20))[0][0], "road-piece_t_esw_00")
		else:
			assert_eq(cross, [["road-y_plain_" + a, "road-y_plain_" + a], ["road-y_plain_" + a, "road-y_plain_" + a]],
				"a junction of a road without a line is its plain asphalt")
			assert_eq(dead[0][0], "road-brush_plain_dead_s_%s_00" % a, "a dead end ends in a kerb")


func test_the_street_grid_has_every_junction_kind() -> void:
	var e := _editor()
	Grid.build(e)
	for b in Grid.EXPECTED:
		assert_eq(_piece(e, Grid.ORIGIN + b), Grid.EXPECTED[b], str(b))
	var kinds := {}
	for b in Grid.EXPECTED:
		kinds[str(Grid.EXPECTED[b]).split("_")[0]] = true
	assert_eq(kinds.keys().size(), 5, "corner, t, cross, dead, straight")
	assert_eq(str(RoadBrush.state_of(e.document, Grid.ORIGIN + Vector2i(3, 12)).kind), "road")
	assert_eq(str(RoadBrush.state_of(e.document, Grid.ORIGIN + Vector2i(3, 12)).asphalt), "g6")
	assert_eq(str(RoadBrush.state_of(e.document, Grid.ORIGIN + Vector2i(-3, 2)).kind), "cracked-road")
	assert_eq(str(RoadBrush.state_of(e.document, Grid.ORIGIN + Vector2i(-3, 2)).asphalt), "g5")


func test_the_centre_line_joins_across_every_piece() -> void:
	# On every side where a centre-line block meets a road, its two tiles on that side carry the
	# line to the edge: a straight's line tiles along that road, or a piece open on that side (its
	# tiles hold the straight tiles' own line pixels there: test_build_ground_tiles.py). The line runs
	# along the tile edge in the road's middle, so the pieces and straights continue it without gaps.
	var e := _editor()
	Grid.build(e)
	var read := func(x): return RoadBrush.state_of(e.document, x)
	var checked := 0
	for j in range(-2, 14):
		for i in range(-6, 18):
			var b := Grid.ORIGIN + Vector2i(i, j)
			var s := RoadBrush.state_of(e.document, b)
			if s.is_empty() or str(s.kind) != "centre-line":
				continue
			var arms := RoadBrush.arms_of(b, read)
			for d in arms:
				for t in _side_tiles(e, b, d):
					assert_true(_carries_line(t, d) or t.contains("zebra"), "%s side %s: %s" % [b, d, t])
				checked += 1
	assert_gt(checked, 60)


## The two tiles of block `b` on side `d`.
func _side_tiles(e: LevelCreatorEditor, b: Vector2i, d: String) -> Array:
	var t := _tiles(e, b)
	match d:
		"n":
			return [t[0][0], t[0][1]]
		"s":
			return [t[1][0], t[1][1]]
		"w":
			return [t[0][0], t[1][0]]
	return [t[0][1], t[1][1]]


## True when a tile carries the centre line out through side `d`.
func _carries_line(id: String, d: String) -> bool:
	var name := id.trim_prefix("road-")
	if name.begins_with("y_line_"):
		return d in ["n", "s"]
	if name.begins_with("x_line_"):
		return d in ["e", "w"]
	var piece := ""
	if name.begins_with("piece_"):
		piece = name.trim_prefix("piece_").left(-3)
	elif name.begins_with("brush_line_"):
		var parts := name.trim_prefix("brush_line_").split("_")
		piece = "_".join(parts.slice(0, parts.size() - 2))
	for arms in RoadBrush.PIECE_OF_ARMS:
		if RoadBrush.PIECE_OF_ARMS[arms] == piece:
			return d in arms
	return false


func test_centre_line_pieces_on_the_other_asphalts() -> void:
	var e := _editor()
	e.panel.pick("centre-line")
	e.look_pick()
	assert_eq(e.brush_asphalt(), "g6")
	e.paint_road([_at(e, Vector2i(10, 10)), _at(e, Vector2i(14, 10)), _at(e, Vector2i(14, 14))])
	assert_eq(_tiles(e, Vector2i(14, 10))[0][0], "road-brush_line_corner_sw_g6_00")
	assert_eq(_tiles(e, Vector2i(12, 10))[0][0], "road-x_line_r_g6")
	assert_eq(_tiles(e, Vector2i(10, 10))[0][0], "road-brush_line_dead_e_g6_00")
	e.mirror_pick()
	e.panel.pick("centre-line")
	e.mirror_pick()
	assert_eq(e.brush_asphalt(), "a0m")
	e.paint_road([_at(e, Vector2i(30, 10)), _at(e, Vector2i(30, 12))])
	assert_eq(_tiles(e, Vector2i(30, 12))[0][0], "road-brush_line_dead_n_a0m_00")
	for row in e.document.cells:
		for id in row:
			assert_false(LevelDocument.entry(str(id)).is_empty(), "%s is a catalogue tile" % id)


# ---- Erasing, repainting, crossings, what a road never covers -----------------------------------

func test_erasing_rejoins_the_neighbours() -> void:
	var e := _editor()
	_paint(e, "centre-line", [Vector2i(10, 14), Vector2i(18, 14)])
	_paint(e, "centre-line", [Vector2i(14, 10), Vector2i(14, 18)])
	assert_eq(_piece(e, Vector2i(14, 14)), "cross")
	# Take the north arm off next to the crossroads: a T-junction, and the arm's end a dead end.
	e.erase_road([_at(e, Vector2i(14, 13))])
	assert_eq(_piece(e, Vector2i(14, 14)), "t_esw")
	assert_eq(_piece(e, Vector2i(14, 12)), "dead_n")
	assert_eq(_tiles(e, Vector2i(14, 14))[0][0], "road-piece_t_esw_00")
	assert_eq(e.document.tile_at(Vector2i(28, 26)), LevelDocument.BASE_GROUND)
	# The whole middle: the straights either side end in dead ends.
	e.erase_road([_at(e, Vector2i(14, 14)), _at(e, Vector2i(14, 15))])
	assert_eq(_piece(e, Vector2i(13, 14)), "dead_w")
	assert_eq(_piece(e, Vector2i(15, 14)), "dead_e")
	assert_eq(_piece(e, Vector2i(14, 16)), "dead_s")
	assert_eq(str(e.level_data.ground_rows[14 * 4 + 1]).substr(14 * 4, 4), "GGGG")


func test_painting_over_a_road_changes_its_kind() -> void:
	var e := _editor()
	_paint(e, "road", [Vector2i(10, 10), Vector2i(20, 10)])
	_paint(e, "centre-line", [Vector2i(13, 10), Vector2i(16, 10)])
	for i in range(13, 17):
		assert_eq(str(RoadBrush.state_of(e.document, Vector2i(i, 10)).kind), "centre-line")
	assert_eq(str(RoadBrush.state_of(e.document, Vector2i(12, 10)).kind), "road")
	assert_eq(_tiles(e, Vector2i(14, 10))[0][0], "road-x_line_r_a0")
	assert_eq(_tiles(e, Vector2i(12, 10))[0][0], "road-x_plain_a0")
	e.panel.pick("cracked-road")
	e.look_pick()
	e.look_pick()
	e.paint_road([_at(e, Vector2i(14, 10))])
	assert_eq(RoadBrush.state_of(e.document, Vector2i(14, 10)), {"kind": "cracked-road", "asphalt": "g7", "zebra": {}})


func test_a_zebra_crossing_goes_across_a_straight_road_where_clicked() -> void:
	var e := _editor()
	_paint(e, "centre-line", [Vector2i(10, 10), Vector2i(10, 16)])
	_paint(e, "road", [Vector2i(20, 10), Vector2i(26, 10)])
	e.panel.pick("zebra-crossing")
	assert_eq(e.brush_mode(), "zebra")
	# Along y: the clicked row of tiles across the road (row 1 of the block).
	var b := Vector2i(10, 13)
	assert_true(e.place_zebra(RoadBrush.block_rect(e.document, b).position + Vector2(1, 3)))
	assert_eq(_tiles(e, b), [["road-y_line_r_a0", "road-y_line_l_a0"], ["road-y_zebra_a0", "road-y_zebra_a0"]])
	# Along x: the clicked column.
	var bx := Vector2i(23, 10)
	assert_true(e.place_zebra(RoadBrush.block_rect(e.document, bx).position + Vector2(1, 1)))
	assert_eq(_tiles(e, bx), [["road-x_zebra_a0", "road-x_plain_a0"], ["road-x_zebra_a0", "road-x_plain_a0"]])
	# Not on a dead end, a junction, or off the road.
	assert_false(e.place_zebra(_at(e, Vector2i(10, 10))))
	assert_false(e.place_zebra(_at(e, Vector2i(40, 40))))
	# The crossing stays when the road is painted over with another kind (the asphalt is the road's).
	_paint(e, "cracked-road", [Vector2i(10, 12), Vector2i(10, 14)])
	assert_eq(_tiles(e, b)[1], ["road-y_zebra_g4", "road-y_zebra_g4"])
	# A crossing saved with the game's edge tiles (e0, e1) is read back as a crossing too.
	assert_eq(RoadBrush.tile_info("road-y_zebra_e1_g4"), {"line": false, "zebra": "y", "asphalt": "g4"})
	assert_eq(RoadBrush.state_of(e.document, b).kind, "cracked-road")
	# It goes when the block becomes a junction.
	_paint(e, "cracked-road", [Vector2i(11, 13), Vector2i(13, 13)])
	assert_eq(_piece(e, b), "t_nes")
	assert_eq(RoadBrush.state_of(e.document, b).zebra, {})


func test_a_road_never_paints_over_a_building_platform_or_ramp() -> void:
	var e := _editor()
	var b := e.place_asset("building-small", _at(e, Vector2i(12, 10)) - Vector2(1, 1))
	assert_false(b.is_empty())
	assert_false(e.place_asset("rooftop-3", _at(e, Vector2i(20, 10)) - Vector2(1, 1), Vector2(8, 8)).is_empty())
	_paint(e, "road", [Vector2i(8, 10), Vector2i(26, 10)])
	for i in range(8, 27):
		var r := RoadBrush.block_rect(e.document, Vector2i(i, 10))
		var under := RoadBrush.blocked(e.document, Vector2i(i, 10))
		assert_eq(RoadBrush.state_of(e.document, Vector2i(i, 10)).is_empty(), under, "block %d (%s)" % [i, r])
	assert_true(RoadBrush.blocked(e.document, Vector2i(12, 10)))
	assert_true(RoadBrush.blocked(e.document, Vector2i(20, 10)))
	# The road ends against them in dead ends.
	assert_eq(_piece(e, Vector2i(11, 10)), "dead_w")
	assert_eq(e.level_data.buildings.size(), 1)


# ---- Saved levels -------------------------------------------------------------------------------

func test_a_painted_level_saves_passes_check_level_and_plays() -> void:
	var e := _editor()
	Grid.build(e)
	e.name_field.text = "Brush grid"
	assert_eq(e.save(), OK)
	var res := _check_level(e.level_path)
	assert_eq(res[0], 0, "check_level.py: " + res[1])
	# The same ground data as before: tiles of the catalogue per cell, and ground_rows R under them.
	var saved: Dictionary = LevelStore.load_level(e.level_path)
	var doc := LevelDocument.new(saved)
	assert_eq(doc.cells, e.document.cells, "it opens as painted")
	for t in saved.ground.tiles:
		assert_false(LevelDocument.entry(str(t)).is_empty(), str(t))
	TestSave.isolate()
	var run := GameFlow.add_run(self, PlayerProgress.new(), e.level_path)
	await wait_process_frames(2)
	assert_true(run.state.is_running())
	assert_eq(run.state.time_left_text(), "4:00")
	run.queue_free()
	await wait_process_frames(1)
	get_tree().paused = false
	TestSave.restore()


func test_an_earlier_level_opens_unchanged() -> void:
	var before: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OLD_LEVEL))
	var e := _editor(OLD_LEVEL)
	assert_eq(e.document.file_data(str(before.get("name", ""))).ground, before.ground, "its ground unchanged on opening")
	# Every tile it uses is still drawn (in the ground layout).
	var gl := e.document.ground_layout()
	for j in e.document.rows():
		for i in e.document.cols():
			assert_true(int(gl.cells[j][i]) >= 0, "cell %d %d drawn" % [i, j])
			if int(gl.cells[j][i]) < 0:
				return
	# Painting next to it changes only the blocks painted and their neighbours.
	var cells_before: Array = e.document.cells.duplicate(true)
	_paint(e, "road", [Vector2i(2, 2), Vector2i(4, 2)])
	var changed := 0
	for j in e.document.rows():
		for i in e.document.cols():
			if e.document.cells[j][i] != cells_before[j][i]:
				changed += 1
				assert_true(i < 12 and j < 8, "only near the stroke: %d %d" % [i, j])
	assert_gt(changed, 0)
