extends GutTest
## Task T-254: the level creator's small (6 x 6) and long (12 x 6, rotated 6 x 12) buildings can be
## placed, saved, reopened and pass check_level.py; since T-405 they are platforms at height 3 (no
## wall: the car from the street meets their sides, and it can drive on them), they fade like the
## rooftops, and the enemies on the street path round them. Their art per rotation and mirror is in
## data/level/creator_buildings.json (the catalogue shows its platform cut, T-405); labels come
## from creator_texts.json.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const NavScript := preload("res://scripts/enemies/enemy_navigation.gd")
const PIECES := "res://data/level/creator_buildings.json"
const BuildingTowers := preload("res://scripts/level/building_towers.gd")
const ShortPlatforms := preload("res://scripts/level/short_platforms.gd")

var dir: String


func before_each() -> void:
	dir = RunPaths.file("t254_levels_" + str(randi()))


func _editor() -> LevelCreatorEditor:
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.levels_dir = dir
	e.open_new()
	e.level_data["spawn"] = {"x": 111.0, "y": 111.0, "heading": 270}  # T-280: out of the way of the tests' pieces
	add_child_autofree(e)
	return e


## Picks `id`, rotates `turns` times and places it at `units`; returns the piece.
func _place(e: LevelCreatorEditor, id: String, units: Vector2, turns: int = 0) -> Dictionary:
	e.panel.pick(id)
	for i in turns:
		e.rotate_pick()
	var piece := e.place_asset(id, units)
	e.panel.pick("")
	return piece


func _check_level(path: String) -> Array:
	var output: Array = []
	var code := OS.execute("python", [ProjectSettings.globalize_path("res://tools/check_level.py"),
		ProjectSettings.globalize_path(path)], output, true)
	return [code, "\n".join(output)]


func test_the_catalogue_lists_both_with_their_views_and_footprints() -> void:
	var small := LevelDocument.entry("building-small")
	var long_b := LevelDocument.entry("building-long")
	assert_eq(LevelDocument.footprint_of("building-small", "iso", false), Vector2(6, 6))
	assert_eq(LevelDocument.views_of("building-long").size(), 2, "the long one has two rotations")
	assert_eq(LevelDocument.footprint_of("building-long", "ew", false), Vector2(12, 6))
	assert_eq(LevelDocument.footprint_of("building-long", "ns", true), Vector2(6, 12))
	assert_eq(str(small.kind), "building")
	assert_eq(float(long_b.height_units), 3.0, "T-405: a platform 3 high")


func test_the_data_file_names_every_view_and_mirror_texture() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(PIECES))
	for p in data.pieces:
		assert_eq(p.textures.size(), p.views.size() * p.mirrors.size(), "%s: one texture per view and mirror" % p.id)
		for t in p.textures:
			assert_true(ResourceLoader.exists(str(t.texture)), str(t.texture) + " exists")
			assert_true(str(p.views).contains(str(t.view)))
			# The catalogue carries their platform art (T-405), cut from these textures.
			assert_eq(LevelDocument.texture_of(str(p.id), str(t.view), bool(t.mirror)).texture,
				ShortPlatforms.art_of(str(t.texture)).full)


func test_the_panel_buttons_carry_the_labels_from_the_texts() -> void:
	var e := _editor()
	assert_eq(e.panel.buttons["building-small"].text, CreatorTexts.get_text("building_small"))
	assert_eq(e.panel.buttons["building-long"].text, CreatorTexts.get_text("building_long"))
	assert_true(e.panel.entries_by_category()[CreatorTexts.get_text("category_buildings")].has("building-long"))


func test_place_save_reopen_and_check_level() -> void:
	var e := _editor()
	var small := _place(e, "building-small", Vector2(-40.0, -40.0))
	var long_ew := _place(e, "building-long", Vector2(-20.0, -40.0))
	var long_ns := _place(e, "building-long", Vector2(10.0, -40.0), 1)
	assert_false(small.is_empty() or long_ew.is_empty() or long_ns.is_empty(), "all three placed")
	assert_eq([small.item.w, small.item.h], [6.0, 6.0])
	assert_eq([long_ew.item.w, long_ew.item.h], [12.0, 6.0])
	assert_eq([long_ns.item.w, long_ns.item.h], [6.0, 12.0], "rotated, it covers 6 x 12")
	e.name_field.text = "Small And Long"
	assert_eq(e.save(), OK)
	var res := _check_level(e.level_path)
	assert_eq(res[0], 0, "check_level.py: " + res[1])
	var again := _editor()
	again.open_level(e.level_path)
	assert_eq(again.level_data.buildings.size(), 3)
	var assets: Array = again.level_data.buildings.map(func(b): return str(b.asset))
	assert_eq(assets.count("building-long"), 2)
	assert_eq(again.map.buildings.size(), 3, "the reopened map builds them")


func test_a_mirrored_long_building_keeps_its_footprint_and_writes_its_look() -> void:
	var e := _editor()
	e.panel.pick("building-long")
	e.mirror_pick()
	var piece := e.place_asset("building-long", Vector2(0.0, 0.0))
	assert_eq(int(piece.item.look), 1)
	assert_eq([piece.item.w, piece.item.h], [12.0, 6.0])
	assert_ne(BuildingTowers.piece_of(piece.item).texture, "")
	var other := {"asset": "building-long", "look": 0, "w": 12.0, "h": 6.0}
	assert_ne(BuildingTowers.piece_of(piece.item).texture, BuildingTowers.piece_of(other).texture)


func test_each_footprint_is_a_platform_at_3_with_no_wall() -> void:
	# T-405: no wall; the footprint is a platform at 3 (the car on the street meets its sides as a
	# rooftop's, tests/unit/level_creator/test_short_platforms.gd drives on them).
	var e := _editor()
	var pieces: Array = [_place(e, "building-small", Vector2(-40.0, -40.0)),
		_place(e, "building-long", Vector2(-20.0, -40.0)), _place(e, "building-long", Vector2(10.0, -40.0), 1)]
	for child in e.map.walls.get_children():
		assert_false(str(child.name).begins_with("Building"), "no building wall: %s" % child.name)
	for p in pieces:
		var r := Rect2(float(p.item.x), float(p.item.y), float(p.item.w), float(p.item.h))
		assert_eq(e.elevation.ground_height.height_at(r.get_center()), 3.0, "a platform at 3 on %s" % [r])
		assert_eq(e.elevation.ground_height.height_at(r.position - Vector2(1, 1)), 0.0, "the street round it")


func test_they_fade_as_rooftops_do() -> void:
	# T-405: a raised area (a platform at 3) that fades while it covers the car behind it.
	var e := _editor()
	_place(e, "building-long", Vector2(0.0, 0.0))
	assert_eq(e.map.slots.size(), 0, "no building slot")
	var node: Node2D = null
	for a in e.elevation.areas:
		if bool(a.block.get("short", false)):
			node = a
	assert_eq(float(node.block.height), 3.0)
	assert_false(node.silhouette().is_empty())
	var r: Rect2 = node.rect()
	assert_true(node.is_behind(r.position - Vector2(1, 1), 0.5, 0.0), "a car on the street behind it")
	assert_false(node.is_behind(r.end + Vector2(1, 1), 0.5, 0.0), "one in front")
	assert_false(node.is_behind(r.get_center(), 0.5, 3.0), "one on it")


func test_enemies_path_round_them() -> void:
	var e := _editor()
	var piece := _place(e, "building-long", Vector2(-6.0, -2.0))
	var r := Rect2(float(piece.item.x), float(piece.item.y), float(piece.item.w), float(piece.item.h))
	var nav = NavScript.build_for_map(e.map)
	var from := Vector2(r.position.x - 10.0, r.get_center().y)
	var to := Vector2(r.end.x + 10.0, r.get_center().y)
	var path: PackedVector2Array = nav.find_path(from, to)
	assert_gt(path.size(), 2, "a path exists")
	for p in path:
		assert_false(r.grow(-0.5).has_point(p), "the path never goes through the building")
	var length := 0.0
	for i in range(1, path.size()):
		length += path[i - 1].distance_to(path[i])
	assert_gt(length, from.distance_to(to) + 2.0, "it goes round, not straight")
