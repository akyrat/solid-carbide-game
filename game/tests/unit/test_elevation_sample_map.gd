extends GutTest
## Task T-196: the elevation sample map, the drive-only scene. It loads
## data/level/elevation_sample_map.json into the MVP map's script (layout_path)
## and draws every rooftop and ramp of it with the placeholder drawing; the car
## has its real height there, its sprite lifted and its shadow on the ground.
## No run, HUD, enemies or weapons. The MVP map keeps its own layout.
##
## The layout (proposals, Level design, Content, "Elevation sample map"):
## roof-nw-3 x -96..-12, y -96..-66 (height 3); roof-nw-6 x -42..-12 on it
## (height 6); ramp-nw-0-3 x -86..-76, y -66..-54; ramp-nw-3-6 x -54..-42,
## y -86..-76; the south-east garage turned half a turn.

const SCENE := preload("res://scenes/elevation_sample/elevation_sample_map.tscn")
const MvpMapScript := preload("res://scripts/level/mvp_map.gd")
const CarSpriteScript := preload("res://scripts/driving/car_sprite.gd")
const CarShadowScript := preload("res://scripts/driving/car_shadow.gd")
const PlatformDrawingScript := preload("res://scripts/level/elevation_platform_drawing.gd")
const LAYOUT := "res://data/level/elevation_sample_map.json"

## Script folders whose nodes belong to a run, never to this scene.
const RUN_SCRIPT_DIRS := ["res://scripts/run/", "res://scripts/hud/", "res://scripts/enemies/", "res://scripts/weapons/"]

var scene: Node2D
var data: Dictionary
var _interp_before := false


func before_each() -> void:
	_interp_before = get_tree().physics_interpolation
	data = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
	scene = SCENE.instantiate()
	add_child_autofree(scene)
	scene.car.set_physics_process(false)
	scene.car.use_keyboard = false
	scene.car.detect_tricks = false


func after_each() -> void:
	get_tree().physics_interpolation = _interp_before


func _area(id: String):
	for a in scene.areas:
		if str(a.block.id) == id:
			return a
	return null


func _all_nodes(n: Node, out: Array) -> Array:
	out.append(n)
	for c in n.get_children():
		_all_nodes(c, out)
	return out


# --- What the scene has --------------------------------------------------------

func test_the_map_loads_the_sample_layout() -> void:
	assert_eq(scene.map.layout_path, LAYOUT)
	assert_eq(str(scene.map.layout.name), "Elevation sample map")
	assert_eq(scene.map.view, "iso")


func test_the_scene_has_the_ground_buildings_and_boulders() -> void:
	assert_not_null(scene.map.ground_draw, "ground")
	assert_true(scene.map.uses_ground_art(), "the ground art is drawn")
	assert_eq(scene.map.buildings.size(), data.buildings.size(), "one building per layout building")
	assert_gt(scene.map.buildings.size(), 0)
	var boulders := 0
	for copy in data.pattern_copies:
		boulders += copy.boulders.size()
	assert_gt(boulders, 0)
	assert_eq(scene.map.boulder_sprites.size(), boulders, "one boulder sprite per boulder")
	assert_eq(scene.map.walls.get_node("EdgeTop") != null, true, "the edge walls")


func test_one_drawing_per_raised_area_and_ramp() -> void:
	var ids := []
	for p in data.platforms:
		ids.append(str(p.id))
	for r in data.ramps:
		ids.append(str(r.id))
	assert_eq(scene.areas.size(), ids.size())
	for id in ids:
		var a = _area(id)
		assert_not_null(a, "a drawing for %s" % id)
		if a != null:
			assert_eq(a.get_script(), PlatformDrawingScript)
			assert_true(a.is_inside_tree())
	assert_eq(_area("ramp-nw-0-3").kind, "ramp")
	assert_eq(_area("roof-nw-6").kind, "platform")


func test_the_car_has_its_sprite_and_its_shadow() -> void:
	assert_eq(scene.car_sprite.get_script(), CarSpriteScript)
	assert_not_null(scene.car_sprite.texture, "the final sprite")
	assert_eq(scene.car_sprite.sheet, "iso")
	assert_eq(scene.shadow.get_script(), CarShadowScript)
	assert_eq(scene.car.ground, scene.ground_height, "the car's height reads the sample map's ground")
	assert_eq(scene.ground_height.platforms.size(), data.platforms.size())
	assert_eq(scene.ground_height.ramps.size(), data.ramps.size())


func test_the_car_starts_on_the_street_facing_a_0_to_3_ramp() -> void:
	var start: Vector2 = scene.START_UNITS
	assert_eq(scene.ground_height.height_at(start), 0.0)
	assert_almost_eq(scene.car.height, 0.0, 0.001)
	# Straight ahead (north) the ramp from the street.
	var ahead: Vector2 = start + Vector2.from_angle(scene.START_ROTATION) * 6.0
	var r: Dictionary = scene.ground_height.ramp_at(ahead)
	assert_false(r.is_empty(), "a ramp straight ahead")
	assert_eq(float(r.get("bottom_height", -1.0)), 0.0)
	assert_eq(float(r.get("top_height", -1.0)), 3.0)


func test_w_drives_up_the_ramp_onto_height_3() -> void:
	scene.car.scripted_input = [true, false, 0.0]
	var on_roof := false
	for i in 200:
		scene.car.physics_step()
		var units: Vector2 = scene.car.model.get_position()
		if not scene.car.airborne and scene.ground_height.height_at(units) == 3.0 \
				and not scene.ground_height.is_ramp(units):
			on_roof = true
			assert_almost_eq(scene.car.height, 3.0, 0.001)
			break
	assert_true(on_roof, "the car climbs the ramp and lands on the first floor")


# --- Nothing of a run -------------------------------------------------------------

func test_no_run_hud_enemy_or_weapon_nodes() -> void:
	for n in _all_nodes(scene, []):
		var s = n.get_script()
		if s != null:
			for dir in RUN_SCRIPT_DIRS:
				assert_false(str(s.resource_path).begins_with(dir),
					"%s uses %s" % [n.get_path(), s.resource_path])
		var lower := str(n.name).to_lower()
		for word in ["kaiju", "minion", "weapon", "hud", "timer", "likes"]:
			assert_false(lower.contains(word), "node %s" % n.get_path())
		assert_false(n is CanvasLayer, "no HUD layer: %s" % n.get_path())
		assert_false(n is Timer, "no timer: %s" % n.get_path())


# --- Height ----------------------------------------------------------------------

func _check_on_area(units: Vector2, expected: float) -> void:
	scene.place_car(units, 0.0)
	scene.sync_view()
	assert_almost_eq(scene.car.height, expected, 0.001, "the car's height at %s" % units)
	var at_ground: Vector2 = scene.drawn_ground(units)
	assert_almost_eq(scene.car_sprite.position.x, at_ground.x, 0.01)
	assert_almost_eq(scene.car_sprite.position.y, at_ground.y - expected * 16.0, 0.01,
		"the sprite is lifted by its height")
	assert_almost_eq(scene.shadow.surface_height, expected, 0.001, "the shadow lies on the area's top")
	assert_almost_eq(scene.shadow.position.x, at_ground.x, 0.01, "the shadow is under the car")
	assert_almost_eq(scene.shadow.position.y, at_ground.y - expected * 16.0, 0.01)
	assert_lt(scene.shadow.z_index, scene.car_sprite.z_index, "the shadow under the car")


func test_on_height_3_the_sprite_and_shadow_are_lifted_by_3() -> void:
	_check_on_area(Vector2(-70, -81), 3.0)


func test_on_height_6_the_sprite_and_shadow_are_lifted_by_6() -> void:
	_check_on_area(Vector2(-27, -81), 6.0)


func test_in_the_air_the_shadow_stays_on_the_ground() -> void:
	scene.place_car(Vector2(0, -81), 0.0)
	scene.car.height_model.height = 4.0
	scene.car.height_model.airborne = true
	scene.sync_view()
	assert_almost_eq(scene.car_sprite.position.y, scene.drawn_ground(Vector2(0, -81)).y - 64.0, 0.01)
	assert_almost_eq(scene.shadow.surface_height, 0.0, 0.001)


# --- Depth order ---------------------------------------------------------------

func test_stacked_and_attached_areas_are_drawn_over_the_rooftop_under_them() -> void:
	var roof = _area("roof-nw-3")
	for id in ["roof-nw-6", "ramp-nw-0-3", "ramp-nw-3-6"]:
		assert_gt(_area(id).z_index, roof.z_index, "%s over roof-nw-3" % id)
	var se = _area("roof-se-3")
	for id in ["roof-se-6", "ramp-se-3-6"]:
		assert_gt(_area(id).z_index, se.z_index, "%s over roof-se-3" % id)


func test_a_ramp_on_a_rooftops_far_side_is_drawn_under_it() -> void:
	# The south-east 0-to-3 ramp climbs its rooftop's north side: behind it.
	assert_lt(_area("ramp-se-0-3").z_index, _area("roof-se-3").z_index)
	# The north-west 3-to-6 ramp climbs its rooftop's west side: behind it.
	assert_lt(_area("ramp-nw-3-6").z_index, _area("roof-nw-6").z_index)


func test_every_depth_item_has_its_own_z() -> void:
	var seen := {}
	for item in scene.depth_items:
		assert_false(seen.has(item.z_index), "z %d used twice" % item.z_index)
		seen[item.z_index] = true
	assert_eq(scene.depth_items.size(), scene.map.fade_items().size() + scene.areas.size())


func test_the_car_behind_a_rooftop_is_drawn_under_it() -> void:
	# On the street north of the north-west garage, close behind its edge.
	scene.place_car(Vector2(-54, -98), 0.0)
	scene.sync_view()
	assert_lt(scene.car_sprite.z_index, _area("roof-nw-3").z_index)


func test_the_car_on_a_rooftop_is_drawn_over_it() -> void:
	scene.place_car(Vector2(-27, -81), 0.0)
	scene.sync_view()
	assert_gt(scene.car_sprite.z_index, _area("roof-nw-6").z_index)
	assert_gt(scene.car_sprite.z_index, _area("roof-nw-3").z_index)


# --- The MVP map is unchanged ------------------------------------------------------

func test_the_mvp_map_keeps_its_own_layout() -> void:
	var m = MvpMapScript.new()
	assert_eq(m.layout_path, MvpMapScript.LAYOUT_PATH)
	assert_eq(MvpMapScript.LAYOUT_PATH, "res://data/level/mvp_map.json")
	m.free()
