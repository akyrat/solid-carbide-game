extends GutTest
## The kaiju alert signs' geometry (scripts/level/kaiju_signs.gd). T-130 placed 4 banners and 2 standing
## signs from a fixed list; T-441 retired that list: the signs are level creator pieces now, placed in a
## level's "alert_signs" (tests in tests/unit/level_creator/test_creator_alert_signs.gd). These are the
## helpers both the run and the creator use.

const KaijuSigns := preload("res://scripts/level/kaiju_signs.gd")
const MapScene := preload("res://scenes/level/mvp_map.tscn")


func test_kinds_and_designs_come_from_the_asset() -> void:
	assert_eq(KaijuSigns.kind_of_asset("alert-sign-head"), "sign")
	assert_eq(KaijuSigns.kind_of_asset("alert-banner-body"), "banner")
	assert_eq(KaijuSigns.kind_of_asset("prop-barrier"), "")
	assert_eq(KaijuSigns.design_of_asset("alert-sign-head"), "head")
	assert_eq(KaijuSigns.design_of_asset("alert-banner-body"), "body")


func test_every_kind_and_design_has_its_t130_art() -> void:
	for design in KaijuSigns.DESIGNS:
		for kind in ["sign", "banner"]:
			var path := KaijuSigns.texture_path(design, kind)
			assert_true(path.begins_with("res://art/banners/kaiju_" + design), path)
			assert_not_null(KaijuSigns.texture_of({"asset": "alert-%s-%s" % [kind, design]}), path)


func test_banner_sits_on_the_wall_three_units_up() -> void:
	var foot := Rect2(0, 0, 12, 12)
	var tex := KaijuSigns.BuildingTowers.load_texture(KaijuSigns.texture_path("head", "banner"))
	var pos := KaijuSigns.banner_sprite_position(foot, "south", 2.0, 3.0, tex)
	var g := KaijuSigns.iso(Vector2(2.0, 12.0))
	# The sprite's bottom-left (unsheared) pixel row is front_h - 1.
	var front_h := float(tex.get_height()) - floorf((float(tex.get_width()) - 1.0) / 2.0)
	assert_almost_eq(pos.x, g.x, 0.001)
	assert_almost_eq(pos.y + (front_h - 1.0) * 0.5, g.y - 48.0, 0.001)
	# T-130's wall names are the same walls.
	assert_eq(KaijuSigns.banner_sprite_position(foot, "y", 2.0, 3.0, tex), pos)
	assert_eq(KaijuSigns.banner_ground_point(foot, "east", 2.0), Vector2(12, 10))
	assert_eq(KaijuSigns.banner_ground_point(foot, "x", 2.0), Vector2(12, 10))


func test_a_banner_is_three_units_long_and_stays_on_a_12_unit_wall() -> void:
	var tex := KaijuSigns.texture_of({"asset": "alert-banner-head"})
	assert_almost_eq(KaijuSigns.banner_length(tex), 3.0, 0.001)
	assert_almost_eq(KaijuSigns.max_along(Rect2(0, 0, 12, 12), "south", tex), 9.0, 0.001)
	var quad := KaijuSigns.banner_quad(Rect2(0, 0, 12, 12), "south", 0.0, 3.0, tex)
	assert_eq(quad[0], KaijuSigns.iso(Vector2(0, 12)) - Vector2(0, 48))
	assert_eq(quad[1], KaijuSigns.iso(Vector2(3, 12)) - Vector2(0, 48))


func test_the_banner_target_is_the_nearest_skyscraper_under_the_point_and_never_a_short_building() -> void:
	var layout := {"buildings": [
		{"x": 0.0, "y": 0.0, "w": 12.0, "h": 12.0, "asset": "skyscraper-1"},
		{"x": 14.0, "y": 14.0, "w": 12.0, "h": 12.0, "asset": "skyscraper-2"},
		{"x": -40.0, "y": 0.0, "w": 12.0, "h": 12.0, "asset": "short-0"},
	]}
	# A point drawn over both skyscrapers: the nearer (14, 14) one wins.
	var both := KaijuSigns.iso(Vector2(20, 26)) - Vector2(0, 300)
	assert_true(Geometry2D.is_point_in_polygon(both, KaijuSigns.skyscraper_outline(Rect2(0, 0, 12, 12))))
	var t := KaijuSigns.banner_target(layout, "alert-banner-head", both, "south", 6.0)
	assert_eq(t.building.asset, "skyscraper-2")
	assert_eq(t.wall, "south")
	assert_eq(t.along, 4.5)
	assert_eq(t.bottom_units, 6.0)
	assert_true(KaijuSigns.banner_target(layout, "alert-banner-head", KaijuSigns.iso(Vector2(-34, 6)), "south", 3.0).is_empty())
	assert_false(KaijuSigns.can_hang_on(layout.buildings[2]))
	assert_false(KaijuSigns.can_hang_on({"x": 0, "y": 0, "w": 30, "h": 30}), "nor a whole block of the old map")


func test_a_standing_sign_stands_on_its_cells_middle_at_the_height_under_it() -> void:
	var it := {"asset": "alert-sign-body", "x": 4.0, "y": 6.0, "w": 2.0, "h": 2.0}
	var g := KaijuSigns.sign_ground_point(it)
	assert_eq(g, Vector2(5, 7))
	var tex := KaijuSigns.texture_of(it)
	assert_eq(KaijuSigns.sign_sprite_position(g, 3.0, tex),
		KaijuSigns.iso(g) - Vector2(tex.get_width() * 0.5, tex.get_height()) * 0.5 - Vector2(0, 48))


func test_a_map_without_placed_signs_draws_none() -> void:
	var map: Node2D = MapScene.instantiate()
	add_child_autofree(map)
	map.set_view("iso")
	assert_eq(map.alert_signs.size(), 0)
	assert_null(map.alert_signs_root)
	assert_eq(map.depth_sprites().size(), map.boulder_sprites.size())
