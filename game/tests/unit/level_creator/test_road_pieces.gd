extends GutTest
## Task T-252: the road pieces (corners, T-junctions, crossroads, dead ends) are 2 x 2 tiles
## (4 x 4 units, the two-tile-wide roads' size). Each rotation is one catalogue entry under Roads with
## its label from creator_texts.json; picking one and clicking places all four tiles at once. The
## game's own map's ground is unchanged.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const GAME_GROUND := "res://data/level/mvp_ground.json"
const OLD_TILES := 87

const EXPECTED := {"corner": 4, "t": 4, "dead": 4, "cross": 1}
const LABELS := {
	"corner": "road_corner", "t": "road_t_junction", "cross": "road_crossroads", "dead": "road_dead_end",
}


func _editor() -> LevelCreatorEditor:
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.open_new()
	add_child_autofree(e)
	return e


func _pieces() -> Array:
	return LevelDocument.entries().filter(func(e): return e.has("parts"))


func _kind_of(id: String) -> String:
	return id.trim_prefix("road-piece_").split("_")[0]


func test_the_catalogue_has_every_piece_in_every_rotation() -> void:
	var counts := {}
	for e in _pieces():
		assert_eq(str(e.kind), "road")
		assert_eq(e.footprint_units, [4.0, 4.0])
		assert_eq(e.parts.size(), 4)
		var k := _kind_of(str(e.id))
		counts[k] = int(counts.get(k, 0)) + 1
	assert_eq(counts, EXPECTED)


func test_each_part_is_a_tile_entry_of_the_atlas() -> void:
	for e in _pieces():
		var seen := {}
		for part in e.parts:
			var tile := LevelDocument.entry(str(part.tile))
			assert_false(tile.is_empty(), str(part.tile))
			assert_true(tile.get("part", false))
			assert_eq(str(tile.kind), "road")
			assert_gte(int(tile.atlas_index), OLD_TILES)
			assert_eq(tile.footprint_units, [2.0, 2.0])
			seen[Vector2(float(part.dx), float(part.dy))] = true
		assert_eq(seen.size(), 4, "four different tiles of %s" % e.id)


func test_pieces_come_first_among_the_roads_and_old_tiles_keep_their_index() -> void:
	var seen_other := false
	for e in LevelDocument.entries():
		if str(e.kind) != "road":
			continue
		if e.has("parts"):
			assert_false(seen_other, "%s is before the other roads" % e.id)
		else:
			seen_other = true
			if e.has("atlas_index") and not e.get("part", false):
				assert_lt(int(e.atlas_index), OLD_TILES, "%s keeps its index" % e.id)


func test_the_panel_shows_the_pieces_with_their_labels_and_not_their_tiles() -> void:
	var e := _editor()
	for entry in _pieces():
		var id := str(entry.id)
		var k := _kind_of(id)
		assert_eq(LevelCreatorAssetPanel.LABEL_KEYS[id], LABELS[k])
		var label: Label = e.panel.buttons[id].get_meta("label")
		assert_eq(label.text, CreatorTexts.get_text(LABELS[k]))
		assert_ne(label.text, "")
		for part in entry.parts:
			assert_false(e.panel.buttons.has(str(part.tile)), "a part is not a button")


func test_a_piece_places_all_four_tiles_at_once() -> void:
	var e := _editor()
	for entry in _pieces():
		var placed := e.place_asset(str(entry.id), Vector2(-40.0, -40.0))
		assert_false(placed.is_empty(), str(entry.id))
		var c: Vector2i = placed.cell
		for part in entry.parts:
			var pc := c + Vector2i(int(part.dx) / 2, int(part.dy) / 2)
			assert_eq(e.document.tile_at(pc), str(part.tile))
			var tile := LevelDocument.entry(str(part.tile))
			assert_eq(e.map.ground_layout.cells[pc.y][pc.x], int(tile.atlas_index), str(part.tile))
			assert_eq(e.level_data.ground_rows[pc.y * 2].substr(pc.x * 2, 2), "RR")
			assert_eq(e.level_data.ground_rows[pc.y * 2 + 1].substr(pc.x * 2, 2), "RR")


func test_a_piece_near_the_edge_is_moved_inside_the_map() -> void:
	var e := _editor()
	var m := e.document.map_rect()
	var placed := e.place_asset("road-piece_cross", m.end - Vector2(1, 1))
	assert_false(placed.is_empty())
	assert_eq(placed.cell, Vector2i(e.document.cols() - 2, e.document.rows() - 2))
	assert_eq(e.document.tile_at(Vector2i(e.document.cols() - 1, e.document.rows() - 1)), "road-piece_cross_11")
	var at := LevelSnapping.placement(e.document, "road-piece_cross", m.end - Vector2(1, 1))
	assert_eq(at.rect.size, Vector2(4, 4))


func test_the_games_own_ground_does_not_use_the_pieces() -> void:
	var g = JSON.parse_string(FileAccess.get_file_as_string(GAME_GROUND))
	assert_gte(g.names.size(), OLD_TILES + 52, "the layout names every atlas tile")
	for row in g.cells:
		for k in row:
			assert_lt(int(k), OLD_TILES, "no piece in the game's ground")
	for k in range(OLD_TILES, g.names.size()):
		assert_true(str(g.names[k]).begins_with("piece_"))
