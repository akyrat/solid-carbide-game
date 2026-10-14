extends GutTest
## Task T-065: the map's boulders (and the kaiju's landed meteors) are drawn
## with the boulder art in the isometric view: a variant chosen from each
## boulder's position, the sprite's width fitted to the 3-unit collision
## circle, nearest filtering, and a place in the depth order with the
## buildings and the car. The flat view keeps the placeholder circles.

const MapScene := preload("res://scenes/level/mvp_map.tscn")
const MvpMap := preload("res://scripts/level/mvp_map.gd")

## The block south of the gravel centre (as in test_see_through_map.gd), a
## spot on the road just behind it (north) and one just in front of it.
const BLOCK := Rect2(12, 66, 30, 30)
const BEHIND_BLOCK := Vector2(27, 61)
const IN_FRONT_OF_BLOCK := Vector2(27, 100)
const NOSE_UP := -PI / 2.0


func make_map(view := "iso") -> Node2D:
	var map: Node2D = MapScene.instantiate()
	# These tests pin the block-level mechanism (fade, depth order) on the placeholder blocks; the skyscraper
	# art with its per-slot fade has its own tests (test_building_art.gd, T-064).
	map.building_art_enabled = false
	add_child_autofree(map)
	map.set_view(view)
	return map


func building_at(map: Node2D, footprint: Rect2) -> Node2D:
	for b in map.buildings:
		if b.footprint == footprint:
			return b
	return null


func sprite_at(map: Node2D, centre: Vector2) -> Sprite2D:
	for s in map.boulder_sprites:
		if s.centre_units.is_equal_approx(centre):
			return s
	return null


func test_one_sprite_per_boulder_from_the_art_list() -> void:
	var map := make_map()
	var all: Array = map.all_boulders()
	assert_eq(all.size(), 96, "the map's boulders")
	assert_eq(map.boulder_sprites.size(), all.size(), "one sprite each")
	assert_eq(map.boulder_textures.size(), map.boulder_art.variants.size())
	assert_gt(map.boulder_textures.size(), 1, "more than one variant")
	for s in map.boulder_sprites:
		assert_not_null(s.texture)
		assert_eq(s.get_parent(), map.boulder_sprites_root)


func test_art_files_exist_and_are_160_square() -> void:
	var data: Dictionary = MvpMap.load_layout(MvpMap.BOULDER_ART_PATH)
	for v in data.variants:
		var tex: Texture2D = load(str(v.texture))
		assert_not_null(tex, str(v.texture))
		assert_eq(tex.get_size(), Vector2(160, 160))


func test_variants_are_stable_and_all_used() -> void:
	var a := make_map()
	var b := make_map()
	var used := {}
	for i in a.boulder_sprites.size():
		assert_eq(a.boulder_sprites[i].variant, b.boulder_sprites[i].variant, "same boulder, same variant")
		used[a.boulder_sprites[i].variant] = true
	for v in a.boulder_art.variants:
		assert_true(used.has(str(v.id)), "variant %s is used" % v.id)
	# The variant depends on the position only.
	var one := {"x": 10.0, "y": -20.5, "diameter": 3.0}
	assert_eq(a.boulder_variant(one), a.boulder_variant(one.duplicate()))


func test_drawn_width_matches_the_3_unit_circle() -> void:
	var map := make_map()
	var u: float = MvpMap.PX_PER_UNIT
	for s in map.boulder_sprites:
		var d := 3.0
		var width := d * u * sqrt(2.0)
		assert_almost_eq(s.box.size.x, width, 0.01, "opaque width = the circle's on-screen width")
		var c: Vector2 = MvpMap.ISO_TRANSFORM * (s.centre_units * u)
		assert_almost_eq(s.box.get_center().x, c.x, 0.01, "centred on the circle")
		assert_almost_eq(s.box.end.y, c.y + width / 4.0, 0.01, "standing on the circle's front edge")
		# The box really is where the sprite's opaque pixels are drawn.
		var v: Dictionary = {}
		for x in map.boulder_art.variants:
			if str(x.id) == s.variant:
				v = x
		var bb: Array = v.bbox
		assert_almost_eq(s.position.x + float(bb[0]) * s.scale.x, s.box.position.x, 0.01)
		assert_almost_eq(s.position.y + float(bb[3]) * s.scale.y, s.box.end.y, 0.01)


func test_nearest_filtering_and_only_in_the_iso_view() -> void:
	var map := make_map("iso")
	assert_eq(map.boulder_sprites_root.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	for s in map.boulder_sprites:
		assert_eq(s.texture_filter, CanvasItem.TEXTURE_FILTER_PARENT_NODE, "inherits nearest")
	assert_true(map.boulder_sprites_root.visible)
	assert_true(map.uses_boulder_art(), "no placeholder circles in the iso view")
	map.set_view("flat")
	assert_false(map.boulder_sprites_root.visible, "the flat view keeps the circles")
	assert_false(map.uses_boulder_art())


func test_collision_circles_unchanged() -> void:
	var map := make_map()
	var shapes := 0
	for body in map.boulder_bodies:
		for cs in body.get_children():
			assert_almost_eq(cs.shape.radius, 1.5 * MvpMap.PX_PER_UNIT, 0.001)
			shapes += 1
	assert_eq(shapes, map.boulder_sprites.size())


func test_meteor_boulders_get_sprites() -> void:
	var map := make_map()
	var n: int = map.boulder_sprites.size()
	map.add_meteor_boulder(IN_FRONT_OF_BLOCK)
	assert_eq(map.boulder_sprites.size(), n + 1)
	assert_not_null(sprite_at(map, IN_FRONT_OF_BLOCK))
	map.add_meteor_challenge("single-boulder/arrow-1", Vector2(-27, 100), 0.0)
	assert_eq(map.boulder_sprites.size(), map.all_boulders().size(), "challenge boulders too")


func test_boulder_behind_a_building_is_drawn_under_it() -> void:
	var map := make_map()
	var block := building_at(map, BLOCK)
	assert_not_null(block)
	map.add_meteor_boulder(BEHIND_BLOCK)
	map.add_meteor_boulder(IN_FRONT_OF_BLOCK)
	assert_lt(sprite_at(map, BEHIND_BLOCK).z_index, block.z_index, "behind: under the block")
	assert_eq(sprite_at(map, IN_FRONT_OF_BLOCK).z_index, map.top_z_index(), "in front: over every building")
	for b in map.buildings:
		assert_gt(b.z_index, 0, "buildings over the ground, drift marks and flat placeholders")


func test_car_behind_a_boulder_is_drawn_under_it() -> void:
	var map := make_map()
	map.add_meteor_boulder(IN_FRONT_OF_BLOCK)
	var s := sprite_at(map, IN_FRONT_OF_BLOCK)
	var behind := IN_FRONT_OF_BLOCK - Vector2(1.5, 1.5)
	var in_front := IN_FRONT_OF_BLOCK + Vector2(2.5, 2.5)
	var z_behind: int = map.car_z_index(behind, 0.0)
	assert_lt(z_behind, s.z_index, "the boulder covers the car")
	assert_gt(z_behind, map.top_z_index() - MvpMap.BUILDING_Z_STEP, "still over every building")
	assert_eq(map.car_z_index(in_front, 0.0), map.top_z_index(), "in front: over the boulder (tree order)")
	assert_eq(map.car_z_index(Vector2.ZERO, NOSE_UP), map.top_z_index(), "the open start")


func test_car_behind_a_boulder_and_a_building_stays_over_lower_buildings() -> void:
	var map := make_map()
	var block := building_at(map, BLOCK)
	map.add_meteor_boulder(BEHIND_BLOCK)
	var s := sprite_at(map, BEHIND_BLOCK)
	var car := BEHIND_BLOCK - Vector2(1.5, 1.5)
	var z: int = map.car_z_index(car, 0.0)
	assert_lt(z, s.z_index)
	assert_lt(z, block.z_index)
	assert_gt(z, s.z_index - MvpMap.BUILDING_Z_STEP, "over the building below the boulder's level")
