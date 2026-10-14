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
		assert_true(s.height_units in [4.3, 30.0], "a short building or a skyscraper")
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


func test_boulder_behind_a_skyscraper_is_drawn_under_it_with_the_art_on() -> void:
	var map := make_map()
	assert_true(map.uses_building_art())
	map.add_meteor_boulder(BEHIND_BLOCK)
	var sprite: Sprite2D = null
	for s in map.boulder_sprites:
		if s.centre_units.is_equal_approx(BEHIND_BLOCK):
			sprite = s
	assert_not_null(sprite)
	var over := 0
	for s in slots_of(map, block_of(map)):
		if sprite.z_index < s.z_index:
			over += 1
	assert_gt(over, 0, "behind the block: under the slots that cover it")
	var front: Node2D = null
	for s in slots_of(map, block_of(map)):
		if front == null or s.depth_key() > front.depth_key():
			front = s
	assert_lt(sprite.z_index, front.z_index, "under the block's front slot")


func test_short_buildings_follow_the_slot_rule_and_the_plan_is_stable() -> void:
	# T-129: never the back slot; the front slot and/or one side slot; a fixed hash; two in a block are different designs.
	var total := 0
	var designs := {}
	for bx in 10:
		for by in 10:
			var shorts: Array = BuildingTowers.short_slots(bx * 30, by * 30)
			assert_false(Vector2i(0, 0) in shorts)
			assert_lte(shorts.size(), 2)
			total += shorts.size()
			assert_eq(shorts, BuildingTowers.short_slots(bx * 30, by * 30))
			var seen := []
			for e in BuildingTowers.make_plan(bx * 30, by * 30):
				if e.short:
					assert_false((e.short_body / 2) in seen, "two shorts in a block are different designs")
					seen.append(e.short_body / 2)
					designs[e.short_body / 2] = true
	assert_gt(total, 60, "about 0.9 per block")
	assert_lt(total, 120)
	assert_eq(designs.size(), 4, "all four designs are used")


func test_short_buildings_are_drawn_low_and_fade_on_their_own() -> void:
	var map := make_map()
	var found := 0
	for s in map.slots:
		if s.height_units < 10.0:
			found += 1
			assert_eq(s.custom_silhouette.size(), 6, "the outline follows the roof (QA round 1)")
			var tex: Texture2D = s.towers.get_child(0).texture
			assert_lt(tex.get_height(), 600, "short: the roof shows")
			assert_eq(tex.get_width(), 768)
	assert_gt(found, 0, "at least one short building on the map")


## The first short building slot on the map, or null.
func _a_short_slot(map: Node2D) -> Node2D:
	for s in map.slots:
		if s.height_units < 10.0:
			return s
	return null


## The skyscrapers' 5-point outline (a full-width top) for the slot's sprite, as before QA round 1's fix.
func _old_full_width_outline(s: Node2D) -> PackedVector2Array:
	var sp: Sprite2D = s.towers.get_child(0)
	var w := float(sp.texture.get_width())
	var h := float(sp.texture.get_height())
	var out := PackedVector2Array()
	for q in [Vector2(0, 0), Vector2(w, 0), Vector2(w, h - 192.0), Vector2(w * 0.5, h), Vector2(0, h - 192.0)]:
		out.append(sp.position + q * sp.scale)
	return out


func test_short_outline_follows_the_roof_and_skyscrapers_keep_theirs() -> void:
	# T-129 QA round 1: six points, roof apex at the top centre, side corners a quarter of the width lower.
	var o: Array = BuildingTowers.short_outline(768.0, 518.0)
	assert_eq(o.size(), 6)
	assert_eq(o[0], Vector2(384, -1))
	assert_eq(o[1], Vector2(768, 191))
	assert_eq(o[5], Vector2(0, 191))
	var map := make_map()
	var tall := 0
	for s in map.slots:
		if s.height_units >= 10.0:
			tall += 1
			assert_eq(s.custom_silhouette.size(), 5, "skyscrapers keep their 5-point outline")
			assert_eq(s.custom_silhouette[0].y, s.custom_silhouette[1].y, "with a level top")
	assert_gt(tall, 0)


func test_short_outline_contains_every_opaque_pixel_of_all_8_bodies() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://art/buildings/skyscrapers.json"))
	var bodies: Array = data.short.bodies
	assert_eq(bodies.size(), 8)
	for path in bodies:
		var img: Image = BuildingTowers.load_texture(str(path)).get_image()
		if img.is_compressed():
			img.decompress()
		var w := img.get_width()
		var h := img.get_height()
		var poly := PackedVector2Array(BuildingTowers.short_outline(float(w), float(h)))
		var outside := 0
		var opaque := 0
		# Every column's topmost and bottommost opaque pixel: all four corners (pulled in by 0.01) inside.
		for x in w:
			var top := -1
			var bottom := -1
			for y in h:
				if img.get_pixel(x, y).a > 0.0:
					if top < 0:
						top = y
					bottom = y
			if top < 0:
				continue
			opaque += 1
			for y in [top, bottom]:
				for c in [Vector2(0.01, 0.01), Vector2(0.99, 0.01), Vector2(0.01, 0.99), Vector2(0.99, 0.99)]:
					if not Geometry2D.is_point_in_polygon(Vector2(x, y) + c, poly):
						outside += 1
		assert_gt(opaque, w / 2, "%s has opaque columns" % path)
		assert_eq(outside, 0, "%s: every opaque pixel inside the short outline" % path)


func test_car_behind_a_short_roof_edge_does_not_fade_it_but_a_covered_car_does() -> void:
	# T-129 QA round 1: the old full-width outline faded a short building when the car was in the empty
	# triangle above the roof's back edge; T-034's rule is that only the building covering the car fades.
	var map := make_map()
	var s := _a_short_slot(map)
	assert_not_null(s, "a short building on the map")
	var old := _old_full_width_outline(s)
	var f: Rect2 = s.footprint
	var in_triangle: Array = []
	var covered: Array = []
	# Ground places behind the building and outside its footprint, every half unit, up to 8 units around it.
	for ix in range(-16, 25):
		for iy in range(-16, 25):
			var at := f.position + Vector2(ix, iy) * 0.5
			if f.has_point(at) or not s.is_behind(at):
				continue
			var shape: PackedVector2Array = map.car_screen_shape(at, NOSE_UP)
			var was := not Geometry2D.intersect_polygons(old, shape).is_empty()
			if s.covers(at, shape):
				covered.append(at)
				assert_true(was, "the new outline is inside the old one")
			elif was:
				in_triangle.append(at)
	assert_gt(in_triangle.size(), 0, "places in the old empty triangles exist")
	assert_gt(covered.size(), 0, "places hidden behind the short building exist")
	# The fade itself: a car just behind the roof's back edge (in an old triangle) does not fade it...
	for at in in_triangle:
		assert_false(s.update_fade(at, map.car_screen_shape(at, NOSE_UP), 1.0), "no fade at %s" % at)
		assert_eq(s.alpha(), 1.0)
	# ...and a car really covered by it still does.
	var hidden: Vector2 = covered[0]
	assert_true(s.update_fade(hidden, map.car_screen_shape(hidden, NOSE_UP), 1.0), "fades when it hides the car")
	assert_almost_eq(s.alpha(), s.see_through_alpha, 0.001)
