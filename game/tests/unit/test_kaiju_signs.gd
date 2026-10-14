extends GutTest
## Task T-130: the kaiju alert signs: 4 banners hanging on skyscraper walls and 2 signs on the pavement,
## from data/level/kaiju_signs.json. Pictures only (no collisions), banners fade with their slot, signs do not.

const MapScene := preload("res://scenes/level/mvp_map.tscn")
const KaijuSigns := preload("res://scripts/level/kaiju_signs.gd")
const NOSE_UP := -PI / 2.0
## Behind the skyscraper at block (2, 0) slot (1, 0), on the road north of it.
const BEHIND_BANNER_SLOT := Vector2(30, -100)


func make_map(view := "iso", art := true) -> Node2D:
	var map: Node2D = MapScene.instantiate()
	map.building_art_enabled = art
	add_child_autofree(map)
	map.set_view(view)
	return map


func _count_collision(n: Node) -> int:
	var c := 1 if (n is CollisionObject2D or n is CollisionShape2D or n is CollisionPolygon2D) else 0
	for k in n.get_children():
		c += _count_collision(k)
	return c


func _block_rect_at(map: Node2D, p: Vector2) -> Rect2:
	for b in map.buildings:
		if b.footprint.has_point(p):
			return b.footprint
	return Rect2()


func test_six_signs_four_banners_two_pavement_signs() -> void:
	var map := make_map()
	assert_eq(map.alert_signs.size(), 6)
	var banners := 0
	var pavement := 0
	var designs := {}
	for s in map.alert_signs:
		if s.get_meta("alert_kind") == "banner":
			banners += 1
		else:
			pavement += 1
		designs[s.texture.resource_path] = true
	assert_eq(banners, 4)
	assert_eq(pavement, 2)
	assert_eq(designs.size(), 4, "all 4 designs: head and body, as banner and as sign")


func test_the_data_list_is_small_and_valid() -> void:
	var data := KaijuSigns.load_data()
	assert_eq(data.size(), 6)
	for e in data:
		assert_true(e.design in ["head", "body"])
		assert_true(e.kind in ["banner", "sign"])


func test_no_sign_on_a_road_and_all_on_blocks() -> void:
	var map := make_map()
	for s in map.alert_signs:
		var g: Vector2 = s.get_meta("ground")
		var rect := _block_rect_at(map, g if s.get_meta("alert_kind") == "sign" else g - Vector2(0.01, 0.01))
		assert_ne(rect, Rect2(), "%s: its ground point is on a block (not a road)" % s.name)
		if s.get_meta("alert_kind") == "sign":
			assert_gt(g.x, rect.end.x - 1.5, "%s: on the pavement strip, not in a building" % s.name)
			assert_gt(g.y, rect.end.y - 1.5)
			assert_lt(g.x, rect.end.x, "%s: not on the road" % s.name)
			assert_lt(g.y, rect.end.y)


func test_banners_hang_on_skyscrapers_not_short_buildings() -> void:
	var map := make_map()
	for s in map.alert_signs:
		if s.get_meta("alert_kind") == "banner":
			var slot: Node2D = s.get_parent().get_parent()
			assert_gte(slot.height_units, 20.0, "%s hangs on a skyscraper" % s.name)
			assert_true(slot in map.slots)


func test_banners_are_children_of_their_slot_art_and_pavement_signs_are_not_under_a_slot() -> void:
	var map := make_map()
	for s in map.alert_signs:
		if s.get_meta("alert_kind") == "banner":
			assert_true(s.get_parent() in map.slots.map(func(n): return n.towers))
		else:
			assert_eq(s.get_parent(), map.alert_signs_root)
			assert_eq(map.alert_signs_root.get_parent(), map.buildings_draw)


func test_nearest_filter_and_art_scale() -> void:
	var map := make_map()
	for s in map.alert_signs:
		assert_eq(s.scale, Vector2(0.5, 0.5))
	assert_eq(map.alert_signs_root.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)


func test_banner_fades_with_its_slot_and_pavement_signs_do_not() -> void:
	var map := make_map()
	map.update_see_through(BEHIND_BANNER_SLOT, NOSE_UP, 1.0)
	var slot: Node2D = null
	for s in map.alert_signs:
		if s.name == "banner_top_east":
			slot = s.get_parent().get_parent()
			assert_almost_eq(s.get_parent().get_parent().alpha(), 0.15, 0.001, "the slot fades")
			assert_almost_eq(s.get_global_transform().get_scale().x, 0.5, 0.001)
	assert_not_null(slot)
	assert_true(slot in map.covering_buildings())
	# The banner's own alpha stays 1: it shows at the slot's alpha through the parent's modulate.
	for s in map.alert_signs:
		assert_eq(s.modulate.a, 1.0)
		if s.get_meta("alert_kind") == "sign":
			assert_eq(map.alert_signs_root.modulate.a, 1.0, "pavement signs never fade")
			assert_false(s.get_parent() in map.slots)
	# Out of the way, the slot is solid again.
	map.update_see_through(Vector2(0, 0), NOSE_UP, 2.0)
	assert_eq(slot.alpha(), 1.0)


func test_depth_order_pavement_sign_is_just_above_its_blocks_front_slot() -> void:
	var map := make_map()
	for s in map.alert_signs:
		if s.get_meta("alert_kind") != "sign":
			continue
		var block := _block_rect_at(map, s.get_meta("ground"))
		var front: Node2D = null
		for sl in map.slots:
			if sl.footprint.position.distance_to(block.position + Vector2(16.5, 16.5)) < 0.01:
				front = sl
		assert_not_null(front)
		assert_eq(s.z_index, front.z_index + 1)
		for sl in map.slots:
			if sl.depth_key() > front.depth_key():
				assert_gt(sl.z_index, s.z_index, "every nearer slot draws over the sign")
		assert_lt(s.z_index, map.top_z_index(), "the car at the top is drawn over every sign")


func test_banners_inherit_their_slots_depth() -> void:
	var map := make_map()
	for s in map.alert_signs:
		if s.get_meta("alert_kind") == "banner":
			assert_eq(s.z_index, 0, "relative to the slot, which has the z")
			assert_gt(s.get_parent().get_parent().z_index, 1)


func test_no_collisions_added() -> void:
	var with_signs := _count_collision(make_map())
	var placeholder := _count_collision(make_map("iso", false))
	assert_eq(with_signs, placeholder, "the collision objects are the same as without the art")
	var map := make_map()
	for s in map.alert_signs:
		assert_eq(s.get_child_count(), 0)
		assert_eq(_count_collision(s), 0)


func test_flat_view_hides_the_signs() -> void:
	var map := make_map("flat")
	assert_false(map.alert_signs_root.visible)
	for s in map.alert_signs:
		if s.get_meta("alert_kind") == "banner":
			assert_false(s.is_visible_in_tree())


func test_banner_sits_on_the_wall_three_units_up() -> void:
	var foot := Rect2(0, 0, 12, 12)
	var tex := KaijuSigns.BuildingTowers.load_texture(KaijuSigns.texture_path("head", "banner"))
	var pos := KaijuSigns.banner_sprite_position(foot, "y", 2.0, 3.0, tex)
	var g := KaijuSigns.iso(Vector2(2.0, 12.0))
	# The sprite's bottom-left (unsheared) pixel row is front_h - 1.
	var front_h := float(tex.get_height()) - floorf((float(tex.get_width()) - 1.0) / 2.0)
	assert_almost_eq(pos.x, g.x, 0.001)
	assert_almost_eq(pos.y + (front_h - 1.0) * 0.5, g.y - 48.0, 0.001)
