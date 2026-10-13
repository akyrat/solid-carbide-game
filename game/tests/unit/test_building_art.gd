extends GutTest
## Task T-064: each city block is drawn with a dense 7 x 7 grid of narrow
## towers from the building atlas in the isometric view, the placeholder box
## stays in the flat view, the plan is a fixed hash (neighbouring towers differ,
## blocks differ), and the whole block still fades as one.

const MapScene := preload("res://scenes/level/mvp_map.tscn")
const BuildingTowers := preload("res://scripts/level/building_towers.gd")
const BLOCK := Rect2(12, 66, 30, 30)
const BEHIND_BLOCK := Vector2(27, 61)
const NOSE_UP := -PI / 2.0


func make_map(view := "iso") -> Node2D:
	var map: Node2D = MapScene.instantiate()
	add_child_autofree(map)
	map.set_view(view)
	return map


func block_of(map: Node2D) -> Node2D:
	for b in map.buildings:
		if b.footprint == BLOCK:
			return b
	return null


func test_every_block_has_49_towers_and_no_placeholder_in_iso() -> void:
	var map := make_map()
	assert_true(map.uses_building_art())
	for b in map.buildings:
		assert_not_null(b.towers)
		assert_eq(b.towers.get_child_count(), 49)
		assert_false(b.draw_placeholder)
		assert_true(b.towers.visible)


func test_flat_view_keeps_the_placeholder() -> void:
	var map := make_map("flat")
	for b in map.buildings:
		assert_true(b.draw_placeholder)
		assert_false(b.towers.visible)


func test_sprites_use_nearest_filter_and_the_art_scale() -> void:
	var map := make_map()
	var t: Node2D = block_of(map).towers
	assert_eq(t.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	for s in t.get_children():
		assert_eq(s.scale, Vector2(0.5, 0.5))
		assert_true(s.region_enabled)


func test_neighbouring_towers_are_different_base_towers() -> void:
	var map := make_map()
	for b in map.buildings:
		var grid := {}
		for e in b.towers.plan:
			grid[Vector2i(e.gx, e.gy)] = e.tower
		for k in grid:
			for d in [Vector2i(1, 0), Vector2i(0, 1)]:
				if grid.has(k + d):
					assert_ne(grid[k], grid[k + d], "neighbours at %s" % k)


func test_all_eight_base_towers_are_used_and_blocks_differ() -> void:
	var map := make_map()
	var seen := {}
	var signatures := {}
	for b in map.buildings:
		var sig := ""
		for e in b.towers.plan:
			seen[e.tower] = true
			sig += e.variant + ","
		signatures[sig] = true
	assert_eq(seen.size(), 8)
	assert_eq(signatures.size(), map.buildings.size(), "no two blocks are the same")


func test_the_plan_is_stable() -> void:
	var map := make_map()
	var a := BuildingTowers.make_plan(map.building_art, 12, 66)
	var b := BuildingTowers.make_plan(map.building_art, 12, 66)
	assert_eq(a, b)


func test_footprint_height_and_silhouette_come_from_the_towers() -> void:
	var map := make_map()
	var b := block_of(map)
	assert_eq(b.footprint, BLOCK)
	assert_true(b.height_units > 9.0 and b.height_units <= 15.5)
	assert_false(b.custom_silhouette.is_empty())


func test_the_whole_block_fades_with_the_car_behind_it() -> void:
	var map := make_map()
	var b := block_of(map)
	map.update_see_through(BEHIND_BLOCK, NOSE_UP, 1.0)
	assert_true(b in map.covering_buildings())
	assert_almost_eq(b.alpha(), 0.15, 0.001)
	for s in b.towers.get_children():
		assert_eq(s.modulate.a, 1.0, "the towers themselves are untouched; the block's modulate fades them")


func test_atlas_has_no_semi_transparent_pixels() -> void:
	var map := make_map()
	var img: Image = map.building_atlas.get_image()
	var bad := 0
	for y in img.get_height():
		for x in img.get_width():
			var a := img.get_pixel(x, y).a
			if a > 0.0 and a < 1.0:
				bad += 1
	assert_eq(bad, 0)
