extends GutTest
## Task T-064: each city block is drawn with a 2 x 2 grid of skyscrapers
## (round-2 sample, quick tuning) in the isometric view, the placeholder box
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


func test_every_block_has_4_skyscrapers_and_4_pavements() -> void:
	var map := make_map()
	assert_true(map.uses_building_art())
	for b in map.buildings:
		assert_not_null(b.towers)
		assert_eq(b.towers.get_child_count(), 4)
		assert_eq(b.towers.pavement_root.get_child_count(), 4)
		assert_false(b.draw_placeholder)
		assert_true(b.towers.visible)
		assert_eq(b.towers.pavement_root.get_parent(), map.buildings_draw, "pavement is not under the faded block")


func test_flat_view_keeps_the_placeholder() -> void:
	var map := make_map("flat")
	for b in map.buildings:
		assert_true(b.draw_placeholder)
		assert_false(b.towers.visible)
		assert_false(b.towers.pavement_root.visible)


func test_sprites_use_nearest_filter_and_the_art_scale() -> void:
	var map := make_map()
	var t: Node2D = block_of(map).towers
	assert_eq(t.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	for s in t.get_children():
		assert_eq(s.scale, Vector2(0.5, 0.5))
	for s in t.pavement_root.get_children():
		assert_eq(s.scale, Vector2(0.5, 0.5))


func test_the_four_slots_of_a_block_differ_and_the_plan_is_stable() -> void:
	var map := make_map()
	for b in map.buildings:
		var seen := {}
		for e in b.towers.plan:
			seen[e.body] = true
		assert_eq(seen.size(), 4)
	assert_eq(BuildingTowers.make_plan(12, 66), BuildingTowers.make_plan(12, 66))


func test_footprint_height_and_silhouette_come_from_the_art() -> void:
	var map := make_map()
	var b := block_of(map)
	assert_eq(b.footprint, BLOCK)
	assert_eq(b.height_units, 30.0)
	assert_false(b.custom_silhouette.is_empty())


func test_the_whole_block_fades_with_the_car_behind_it() -> void:
	var map := make_map()
	var b := block_of(map)
	map.update_see_through(BEHIND_BLOCK, NOSE_UP, 1.0)
	assert_true(b in map.covering_buildings())
	assert_almost_eq(b.alpha(), 0.15, 0.001)
	for s in b.towers.get_children():
		assert_eq(s.modulate.a, 1.0, "the sprites themselves are untouched; the block's modulate fades them")
	for s in b.towers.pavement_root.get_children():
		assert_eq(s.modulate.a, 1.0)


func test_bodies_have_no_semi_transparent_pixels() -> void:
	var map := make_map()
	for p in map.building_art.bodies:
		var img: Image = BuildingTowers.load_texture(str(p)).get_image()
		var bad := 0
		for y in img.get_height():
			for x in img.get_width():
				var a := img.get_pixel(x, y).a
				if a > 0.0 and a < 1.0:
					bad += 1
		assert_eq(bad, 0)


func test_f7_cycles_three_city_palettes_and_swaps_textures() -> void:
	BuildingTowers.current_palette = "A"
	var map := make_map()
	var t: Node2D = block_of(map).towers
	assert_eq(t.palette_letters(), ["A", "B", "C"])
	var first: Texture2D = t.get_child(0).texture
	assert_eq(map.cycle_city_palette(), "B")
	assert_ne(t.get_child(0).texture, first)
	assert_eq(map.cycle_city_palette(), "C")
	assert_eq(map.cycle_city_palette(), "A")
	assert_eq(t.get_child(0).texture, first)
	assert_not_null(map.get_node("PaletteLabel"))
