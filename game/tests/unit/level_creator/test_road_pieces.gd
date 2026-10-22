extends GutTest
## Task T-252: the road pieces (corners, T-junctions, crossroads, dead ends) are in the catalogue
## under Roads with their labels from creator_texts.json, can be placed in the creator, and the
## game's own map's ground is unchanged by them.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const GAME_GROUND := "res://data/level/mvp_ground.json"
const OLD_TILES := 87

const EXPECTED := {
	"corner": 4, "t": 4, "dead": 4, "cross": 1, "mid": 2,
}
const LABELS := {
	"corner": "road_corner", "t": "road_t_junction", "cross": "road_crossroads", "dead": "road_dead_end",
}


func _editor() -> LevelCreatorEditor:
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.open_new()
	add_child_autofree(e)
	return e


func _pieces() -> Array:
	var out: Array = []
	for e in LevelDocument.entries():
		if str(e.id).begins_with("road-piece_"):
			out.append(e)
	return out


func _kind_of(id: String) -> String:
	return id.trim_prefix("road-piece_").split("_")[0]


func test_the_catalogue_has_every_piece_in_every_rotation() -> void:
	var counts := {}
	for e in _pieces():
		assert_eq(str(e.kind), "road")
		assert_eq(e.footprint_units, [2.0, 2.0])
		var k := _kind_of(str(e.id))
		counts[k] = int(counts.get(k, 0)) + 1
	assert_eq(counts, EXPECTED)


func test_pieces_come_first_among_the_roads_and_old_tiles_keep_their_index() -> void:
	var seen_other := false
	for e in LevelDocument.entries():
		if str(e.kind) != "road":
			continue
		var is_piece := str(e.id).begins_with("road-piece_")
		if is_piece:
			assert_false(seen_other, "%s is before the other roads" % e.id)
			assert_gte(int(e.atlas_index), OLD_TILES)
		else:
			seen_other = true
			if e.has("atlas_index"):
				assert_lt(int(e.atlas_index), OLD_TILES, "%s keeps its index" % e.id)


func test_the_panel_labels_the_pieces_from_the_texts() -> void:
	var e := _editor()
	for entry in _pieces():
		var id := str(entry.id)
		var k := _kind_of(id)
		if k == "mid":
			continue
		assert_true(LevelCreatorAssetPanel.LABEL_KEYS.has(id), id)
		assert_eq(LevelCreatorAssetPanel.LABEL_KEYS[id], LABELS[k])
		var label: Label = e.panel.buttons[id].get_meta("label")
		assert_eq(label.text, CreatorTexts.get_text(LABELS[k]))
		assert_ne(label.text, "")


func test_every_piece_can_be_placed_and_is_drawn_from_its_atlas_tile() -> void:
	var e := _editor()
	var i := 0
	for entry in _pieces():
		var id := str(entry.id)
		var at := Vector2(-20.0 + 2.0 * (i % 8) + 1.0, -20.0 + 2.0 * (i / 8) + 1.0)
		var placed := e.place_asset(id, at)
		assert_false(placed.is_empty(), id)
		var c: Vector2i = placed.cell
		assert_eq(e.document.tile_at(c), id)
		assert_eq(e.map.ground_layout.cells[c.y][c.x], int(entry.atlas_index), id)
		i += 1


func test_pieces_make_road_in_the_ground_rows() -> void:
	var e := _editor()
	var placed := e.place_asset("road-piece_cross", Vector2(1, 1))
	var c: Vector2i = placed.cell
	assert_eq(e.level_data.ground_rows[c.y * 2].substr(c.x * 2, 2), "RR")
	assert_eq(e.level_data.ground_rows[c.y * 2 + 1].substr(c.x * 2, 2), "RR")


func test_the_games_own_ground_does_not_use_the_pieces() -> void:
	var g = JSON.parse_string(FileAccess.get_file_as_string(GAME_GROUND))
	assert_gte(g.names.size(), OLD_TILES + 15, "the layout names every atlas tile")
	for row in g.cells:
		for k in row:
			assert_lt(int(k), OLD_TILES, "no piece in the game's ground")
	for k in range(OLD_TILES, g.names.size()):
		assert_true(str(g.names[k]).begins_with("piece_"))
