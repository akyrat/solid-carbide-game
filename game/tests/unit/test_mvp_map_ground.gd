extends GutTest
## Checks the MVP map's ground art (task T-103): the ground tile layout lines up
## with the map's layout and collisions, and the isometric view draws it.

const MapScene := preload("res://scenes/level/mvp_map.tscn")
const MvpMap := preload("res://scripts/level/mvp_map.gd")

var layout: Dictionary
var ground: Dictionary


func before_all() -> void:
	layout = MvpMap.load_layout()
	ground = MvpMap.load_layout(MvpMap.GROUND_PATH)


func make_map() -> Node2D:
	var map: Node2D = MapScene.instantiate()
	add_child_autofree(map)
	return map


func test_ground_layout_covers_the_map() -> void:
	var m := MvpMap.rect_of(layout.map.rect)
	var cell := float(ground.cell_units)
	assert_eq(Vector2(float(ground.origin[0]), float(ground.origin[1])), m.position)
	assert_eq(int(ground.cols) * cell, m.size.x)
	assert_eq(int(ground.rows) * cell, m.size.y)
	assert_eq(ground.cells.size(), int(ground.rows))


func test_atlas_loads_with_every_tile() -> void:
	var tex: Texture2D = load(str(ground.atlas))
	assert_not_null(tex)
	var cols := int(ground.atlas_columns)
	var n: int = ground.names.size()
	assert_eq(tex.get_width(), cols * int(ground.tile_px[0]))
	assert_eq(tex.get_height(), ceili(float(n) / cols) * int(ground.tile_px[1]))


## Every cell with a tile is road or gravel, and every building cell has none:
## the ground art lines up with the buildings' collision shapes.
func test_tiles_line_up_with_buildings_and_collisions() -> void:
	var cell := float(ground.cell_units)
	var origin := Vector2(float(ground.origin[0]), float(ground.origin[1]))
	var rects: Array[Rect2] = []
	for b in layout.buildings:
		rects.append(MvpMap.rect_of(b))
	for j in int(ground.rows):
		for i in int(ground.cols):
			var centre := origin + Vector2(i + 0.5, j + 0.5) * cell
			var in_building := false
			for r in rects:
				if r.has_point(centre):
					in_building = true
			var has_tile := int(ground.cells[j][i]) >= 0
			if has_tile == in_building:
				fail_test("cell %d,%d: tile %s, building %s" % [i, j, has_tile, in_building])
				return
	pass_test("every cell matches")


func test_gravel_cells_are_the_gravel_square() -> void:
	var cell := float(ground.cell_units)
	var origin := Vector2(float(ground.origin[0]), float(ground.origin[1]))
	var g := MvpMap.rect_of(layout.gravel)
	var count := 0
	for j in int(ground.rows):
		for i in int(ground.cols):
			var k := int(ground.cells[j][i])
			var is_gravel: bool = k >= 0 and str(ground.names[k]).begins_with("gravel")
			var centre := origin + Vector2(i + 0.5, j + 0.5) * cell
			assert_eq(is_gravel, g.has_point(centre), "cell %d,%d" % [i, j])
			if is_gravel:
				count += 1
	assert_eq(count, int(g.size.x / cell) * int(g.size.y / cell))


func test_iso_view_draws_the_ground_art_and_flat_keeps_placeholders() -> void:
	var map := make_map()
	map.set_view("iso")
	assert_true(map.uses_ground_art())
	assert_true(map.ground_tiles.visible)
	map.set_view("flat")
	assert_false(map.uses_ground_art())
	assert_false(map.ground_tiles.visible)


## The tiles are drawn in screen pixels: with the view's projection undone,
## cell (i, j)'s top vertex is the projection of its world corner, and
## neighbouring cells are 32 x 16 screen pixels apart (64 x 32 per tile).
func test_tile_positions_match_the_projection() -> void:
	var map := make_map()
	map.set_view("iso")
	var total: Transform2D = map.view_root.transform * map.ground_tiles.transform
	assert_almost_eq(total.x, Vector2(1, 0), Vector2(1e-5, 1e-5))
	assert_almost_eq(total.y, Vector2(0, 1), Vector2(1e-5, 1e-5))
	var u := MvpMap.PX_PER_UNIT
	var origin := Vector2(float(ground.origin[0]), float(ground.origin[1])) * u
	assert_eq(map.ground_cell_top(0, 0), MvpMap.ISO_TRANSFORM * origin)
	assert_eq(map.ground_cell_top(1, 0) - map.ground_cell_top(0, 0), Vector2(32, 16))
	assert_eq(map.ground_cell_top(0, 1) - map.ground_cell_top(0, 0), Vector2(-32, 16))


func test_map_draw_order_ground_then_tiles_then_buildings() -> void:
	var map := make_map()
	var names := []
	for c in map.view_root.get_children():
		names.append(c.name)
	assert_true(names.find("Ground") < names.find("GroundTiles"))
	assert_true(names.find("GroundTiles") < names.find("Buildings"))
	assert_true(names.find("Buildings") < names.find("Boulders"))
