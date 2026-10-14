extends GutTest
## Task T-064: each city block is drawn with a 2 x 2 grid of skyscrapers
## (6 towers, palette B), each its own fade node (per-slot fade) in the isometric view, the placeholder box
## stays in the flat view, the plan is a fixed hash (the four slots differ), and the whole block still fades as one.

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


func slots_of(map: Node2D, block: Node2D) -> Array:
	var out := []
	for s in map.slots:
		if block.footprint.encloses(s.footprint):
			out.append(s)
	return out


func test_every_block_has_4_skyscraper_slots_and_4_pavements() -> void:
	var map := make_map()
	assert_true(map.uses_building_art())
	assert_eq(map.slots.size(), map.buildings.size() * 4)
	for b in map.buildings:
		assert_not_null(b.towers)
		assert_eq(slots_of(map, b).size(), 4)
		assert_eq(b.towers.pavement_root.get_child_count(), 4)
		assert_false(b.draw_placeholder)
		assert_eq(b.towers.pavement_root.get_parent(), map.buildings_draw, "pavement is not under a faded node")
		for s in slots_of(map, b):
			assert_eq(s.get_parent(), map.buildings_draw)
			assert_true(s.towers.visible)
			assert_false(s.draw_placeholder)


func test_flat_view_keeps_the_placeholder() -> void:
	var map := make_map("flat")
	for b in map.buildings:
		assert_true(b.draw_placeholder)
		assert_false(b.towers.pavement_root.visible)
	for s in map.slots:
		assert_false(s.towers.visible)


func test_sprites_use_nearest_filter_and_the_art_scale() -> void:
	var map := make_map()
	var t: Node2D = block_of(map).towers
	assert_eq(t.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	for s in t.pavement_root.get_children():
		assert_eq(s.scale, Vector2(0.5, 0.5))
	for s in map.slots:
		var sp: Sprite2D = s.towers.get_child(0)
		assert_eq(sp.scale, Vector2(0.5, 0.5))
		assert_eq(s.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)


func test_the_four_slots_of_a_block_differ_and_all_six_towers_are_used() -> void:
	var map := make_map()
	var used := {}
	for b in map.buildings:
		var seen := {}
		for e in b.towers.plan:
			seen[e.tower] = true
			used[e.tower] = true
		assert_eq(seen.size(), 4)
	assert_eq(used.size(), 6)
	assert_eq(BuildingTowers.make_plan(12, 66), BuildingTowers.make_plan(12, 66))


func test_footprint_height_and_silhouette_come_from_the_art() -> void:
	var map := make_map()
	var b := block_of(map)
	assert_eq(b.footprint, BLOCK)
	for s in slots_of(map, b):
		assert_eq(s.footprint.size, Vector2(12, 12))
		assert_eq(s.height_units, 30.0)
		assert_false(s.custom_silhouette.is_empty())


func test_only_the_slot_covering_the_car_fades() -> void:
	var map := make_map()
	var b := block_of(map)
	map.update_see_through(BEHIND_BLOCK, NOSE_UP, 1.0)
	var covering: Array = map.covering_buildings()
	assert_gt(covering.size(), 0)
	for c in covering:
		assert_almost_eq(c.alpha(), 0.15, 0.001)
	var solid := 0
	for s in slots_of(map, b):
		if not (s in covering):
			assert_eq(s.alpha(), 1.0, "a slot that does not cover the car stays solid")
			solid += 1
	assert_gt(solid, 0, "not every slot of the block fades")
	for p in b.towers.pavement_root.get_children():
		assert_eq(p.modulate.a, 1.0)
	assert_eq(b.alpha(), 1.0, "the block node itself does not fade")


func test_car_draws_under_the_covering_slot_only() -> void:
	var map := make_map()
	var z: int = map.car_z_index(BEHIND_BLOCK, NOSE_UP)
	var covering := []
	var shape: PackedVector2Array = map.car_screen_shape(BEHIND_BLOCK, NOSE_UP)
	for s in map.slots:
		if s.covers(BEHIND_BLOCK, shape):
			covering.append(s)
	assert_gt(covering.size(), 0)
	for s in covering:
		assert_lt(z, s.z_index)
	assert_lt(z, map.top_z_index())


func test_bodies_have_no_semi_transparent_pixels() -> void:
	var map := make_map()
	assert_eq(map.building_art.bodies.size(), 12)
	for p in map.building_art.bodies:
		var img: Image = BuildingTowers.load_texture(str(p)).get_image()
		var bad := 0
		for y in img.get_height():
			for x in img.get_width():
				var a := img.get_pixel(x, y).a
				if a > 0.0 and a < 1.0:
					bad += 1
		assert_eq(bad, 0)
