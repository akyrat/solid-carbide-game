extends GutTest
## Task T-197: see-through on the elevation sample map. Every raised area and
## ramp covering the car fades to mvp_map.gd's SEE_THROUGH_ALPHA over
## SEE_THROUGH_FADE_TIME with map_building.gd's faded_alpha (shared, not
## copied); the areas not covering it stay solid; the buildings keep fading as
## on the MVP map. T-191's fix holds on every rooftop: a car driving into the
## back sides (west and north: top-left and top-right on screen) of a height-3
## and a height-6 area stays drawn under it on every step of the hit.
##
## The layout (data/level/elevation_sample_map.json, proposals): roof-nw-3 x
## -96..-12, y -96..-66 (height 3); roof-nw-6 x -42..-12 on it (height 6, its
## north side on the street); roof-se-3 x 12..96, y 66..96; roof-se-6 x 12..42
## on it (its west and north sides on the street).

const SCENE := preload("res://scenes/elevation_sample/elevation_sample_map.tscn")
const MvpMapScript := preload("res://scripts/level/mvp_map.gd")
const MapBuildingScript := preload("res://scripts/level/map_building.gd")
const SCENE_SCRIPT := "res://scripts/level/elevation_sample_map.gd"
const DRAWING_SCRIPT := "res://scripts/level/elevation_platform_drawing.gd"

var scene: Node2D
var _interp_before := false
var _hits := 0


func before_each() -> void:
	_interp_before = get_tree().physics_interpolation
	scene = SCENE.instantiate()
	add_child_autofree(scene)
	scene.car.set_physics_process(false)
	scene.car.use_keyboard = false
	scene.car.detect_tricks = false
	_hits = 0
	scene.car.hit_obstacle.connect(func(_c, _s, _n, _i) -> void: _hits += 1)


func after_each() -> void:
	get_tree().physics_interpolation = _interp_before


func _area(id: String):
	for a in scene.areas:
		if str(a.block.id) == id:
			return a
	return null


## Puts the car somewhere at rest and every area and building straight to solid.
func _put(units: Vector2, rot: float = 0.0) -> void:
	scene.place_car(units, rot)
	for a in scene.areas:
		a.modulate.a = 1.0
	for b in scene.map.fade_items():
		b.reset_fade()
	scene.update_depth()
	scene.update_see_through(0.0)


# --- The fade's numbers and code ---------------------------------------------

func test_every_area_uses_the_buildings_numbers() -> void:
	for a in scene.areas:
		assert_eq(a.see_through_alpha, MvpMapScript.SEE_THROUGH_ALPHA, a.name)
		assert_eq(a.fade_time, MvpMapScript.SEE_THROUGH_FADE_TIME, a.name)


func test_the_fade_step_is_map_buildings_faded_alpha() -> void:
	var b = MapBuildingScript.new()
	autofree(b)
	var a = _area("roof-nw-6")
	_put(Vector2(-44, -74), 0.0)  # on roof-nw-3, behind roof-nw-6
	assert_true(a.covering)
	a.modulate.a = 1.0
	b.modulate.a = 1.0
	b.see_through_alpha = MvpMapScript.SEE_THROUGH_ALPHA
	b.fade_time = MvpMapScript.SEE_THROUGH_FADE_TIME
	for i in 5:
		scene.update_see_through(0.025)
		b.step_fade(true, 0.025)
		assert_almost_eq(a.alpha(), b.alpha(), 1e-6, "step %d" % i)


func test_no_second_fade_formula() -> void:
	# The only fade step is map_building.gd's faded_alpha: the sample map and
	# the area drawing call it and never move an alpha themselves.
	for path in [SCENE_SCRIPT, DRAWING_SCRIPT]:
		var src := FileAccess.get_file_as_string(path)
		assert_false(src.contains("move_toward"), "%s moves no alpha itself" % path)
		assert_false(src.contains("lerp(modulate") or src.contains("modulate.a +=") or src.contains("modulate.a -="),
			"%s has no fade formula" % path)
	assert_true(FileAccess.get_file_as_string(DRAWING_SCRIPT).contains("MapBuildingScript.faded_alpha("))


# --- Fading areas that cover the car, keeping the others solid ----------------

func _check_fade(units: Vector2, rot: float, covering_ids: Array) -> void:
	_put(units, rot)
	for a in scene.areas:
		var id := str(a.block.id)
		assert_eq(a.covering, id in covering_ids, "%s covers the car at %s" % [id, units])
	scene.update_see_through(MvpMapScript.SEE_THROUGH_FADE_TIME / 2.0)
	for a in scene.areas:
		if str(a.block.id) in covering_ids:
			assert_almost_eq(a.alpha(), 1.0 - 0.5 * (1.0 - MvpMapScript.SEE_THROUGH_ALPHA), 1e-4,
				"%s half way after half the fade time" % a.name)
	scene.update_see_through(MvpMapScript.SEE_THROUGH_FADE_TIME / 2.0)
	scene.update_see_through(0.5)
	for a in scene.areas:
		if str(a.block.id) in covering_ids:
			assert_almost_eq(a.alpha(), MvpMapScript.SEE_THROUGH_ALPHA, 1e-4, "%s faded at %s" % [a.name, units])
		else:
			assert_almost_eq(a.alpha(), 1.0, 1e-6, "%s solid at %s" % [a.name, units])


func test_a_height_3_area_covering_the_car_fades() -> void:
	# On the street north of the north-west garage, behind roof-nw-3 (and
	# lower than roof-nw-6 too, but not under it on screen there).
	_check_fade(Vector2(-70, -98), 0.0, ["roof-nw-3"])


func test_a_height_6_area_covering_the_car_on_height_3_fades_but_not_the_one_it_is_on() -> void:
	_check_fade(Vector2(-44, -74), 0.0, ["roof-nw-6"])


func test_both_stacked_areas_fade_when_the_car_is_behind_both() -> void:
	# On the street north of roof-nw-6, whose north side is roof-nw-3's too.
	_check_fade(Vector2(-27, -98), PI / 2.0, ["roof-nw-3", "roof-nw-6"])


func test_a_ramp_covering_the_car_fades() -> void:
	# On roof-nw-3 just north of the 3-to-6 ramp: behind it, lower than its top.
	_check_fade(Vector2(-48, -88), 0.0, ["ramp-nw-3-6"])


func test_nothing_fades_when_the_car_is_on_above_or_in_front_of_the_areas() -> void:
	for at in [Vector2(-70, -81), Vector2(-27, -81), Vector2(-60, -60), Vector2(0, -81), Vector2(27, 81),
			Vector2(60, 100), Vector2(100, 81)]:
		_check_fade(at, 0.0, [])


func test_the_car_in_the_air_over_the_areas_makes_none_fade() -> void:
	_put(Vector2(-44, -74), 0.0)
	scene.car.height_model.height = 6.5
	scene.car.height_model.airborne = true
	scene.update_see_through(0.5)
	for a in scene.areas:
		assert_false(a.covering, a.name)
		assert_almost_eq(a.alpha(), 1.0, 1e-6, a.name)


func test_the_scene_fades_by_itself_while_driving() -> void:
	scene.place_car(Vector2(-70, -100), PI / 2.0)
	scene.sync_view()
	for i in 10:
		scene.car.physics_step()
	assert_true(_area("roof-nw-3").covering)
	assert_almost_eq(_area("roof-nw-3").alpha(), MvpMapScript.SEE_THROUGH_ALPHA, 1e-4)


# --- Buildings keep fading -----------------------------------------------------

func test_a_building_covering_the_car_fades_as_on_the_mvp_map() -> void:
	_put(Vector2(8, -92), PI / 2.0)  # behind the block east of the north-west garage
	var covering: Array = scene.covering_buildings()
	assert_gt(covering.size(), 0, "a building covers the car")
	scene.update_see_through(MvpMapScript.SEE_THROUGH_FADE_TIME)
	for b in scene.map.fade_items():
		if b in covering:
			assert_almost_eq(b.alpha(), MvpMapScript.SEE_THROUGH_ALPHA, 1e-4, b.name)
		else:
			assert_almost_eq(b.alpha(), 1.0, 1e-6, b.name)
	# The garage beside it stays solid: the car is in front of it.
	for a in scene.areas:
		assert_almost_eq(a.alpha(), 1.0, 1e-6, a.name)
	# Out in front of the block it fades back.
	scene.place_car(Vector2(27, -60), 0.0)
	scene.update_see_through(MvpMapScript.SEE_THROUGH_FADE_TIME)
	for b in covering:
		assert_almost_eq(b.alpha(), 1.0, 1e-4, "%s solid again" % b.name)


func test_the_map_does_not_fade_the_buildings_a_second_time() -> void:
	assert_null(scene.map.car, "the scene fades the buildings itself")


# --- No popping over an area at a back-side wall hit ---------------------------

## Drives the car from start with heading rot and W held (steer as given) for
## up to 150 physics steps, or until the car has hit the side and steered more
## than 1 unit away from it again; fails on the first step where the car or
## its shadow is drawn over the area `id`. Returns the hits and the closest the
## car's centre came to the side (side_line along axis 0 = x, 1 = y).
func _drive_into(id: String, start: Vector2, rot: float, steer: float, side_line: float, axis: int) -> Dictionary:
	scene.place_car(start, rot)
	scene.sync_view()
	scene.car.scripted_input = [true, false, steer]
	var a = _area(id)
	var closest := INF
	var under := true
	for i in 150:
		scene.car.physics_step()
		var units: Vector2 = scene.car.model.get_position()
		var gap: float = side_line - (units.x if axis == 0 else units.y)
		closest = minf(closest, gap)
		if _hits > 0 and gap > 1.0:
			break  # the hit is over: the car has steered away from the side
		if scene.car_sprite.z_index >= a.z_index or scene.shadow.z_index >= a.z_index:
			under = false
			fail_test("%s step %d at %s height %.2f: car z %d, shadow z %d, area z %d" % [
				id, i, units, scene.car.height, scene.car_sprite.z_index, scene.shadow.z_index, a.z_index])
			break
	return {"hits": _hits, "closest": closest, "under": under}


func _assert_hit(r: Dictionary, what: String) -> void:
	assert_true(r.under, "%s: under the area on every step" % what)
	assert_gt(r.hits, 0, "%s: the car hit the side" % what)
	assert_lt(r.closest, scene.DEPTH_RADIUS, "%s: the footprint reached the side" % what)
	assert_gte(r.closest, 0.0, "%s: the centre stayed outside" % what)


func test_height_3_west_side_straight_and_angled() -> void:
	_assert_hit(_drive_into("roof-nw-3", Vector2(-100, -81), 0.0, 0.0, -96.0, 0), "nw-3 west, straight")
	_hits = 0
	_assert_hit(_drive_into("roof-nw-3", Vector2(-100, -86), 0.6, 0.0, -96.0, 0), "nw-3 west, angled")
	_hits = 0
	_assert_hit(_drive_into("roof-nw-3", Vector2(-100, -78), 0.0, 0.5, -96.0, 0), "nw-3 west, steering")


func test_height_3_north_side_straight_and_angled() -> void:
	_assert_hit(_drive_into("roof-nw-3", Vector2(-70, -100), PI / 2.0, 0.0, -96.0, 1), "nw-3 north, straight")
	_hits = 0
	_assert_hit(_drive_into("roof-nw-3", Vector2(-74, -100), PI / 2.0 - 0.6, 0.0, -96.0, 1), "nw-3 north, angled")
	_hits = 0
	_assert_hit(_drive_into("roof-nw-3", Vector2(-66, -100), PI / 2.0, -0.5, -96.0, 1), "nw-3 north, steering")


func test_height_6_north_side_from_the_street() -> void:
	_assert_hit(_drive_into("roof-nw-6", Vector2(-27, -100), PI / 2.0, 0.0, -96.0, 1), "nw-6 north, straight")
	_hits = 0
	_assert_hit(_drive_into("roof-nw-6", Vector2(-30, -100), PI / 2.0 - 0.6, 0.0, -96.0, 1), "nw-6 north, angled")


func test_height_6_west_side_from_the_height_3_rooftop() -> void:
	# On roof-nw-3, south of the 3-to-6 ramp: a 3-unit wall up to roof-nw-6.
	_assert_hit(_drive_into("roof-nw-6", Vector2(-46, -70), 0.0, 0.0, -42.0, 0), "nw-6 west from height 3")
	_hits = 0
	_assert_hit(_drive_into("roof-nw-6", Vector2(-46, -92), 0.0, 0.0, -42.0, 0), "nw-6 west from height 3, north of the ramp")


func test_height_6_west_and_north_sides_of_the_south_east_garage() -> void:
	_assert_hit(_drive_into("roof-se-6", Vector2(8, 81), 0.0, 0.0, 12.0, 0), "se-6 west, straight")
	_hits = 0
	_assert_hit(_drive_into("roof-se-6", Vector2(27, 62), PI / 2.0, 0.0, 66.0, 1), "se-6 north, straight")
	_hits = 0
	_assert_hit(_drive_into("roof-se-3", Vector2(60, 62), PI / 2.0, 0.0, 66.0, 1), "se-3 north, straight")


func test_at_a_back_side_hit_the_area_is_see_through() -> void:
	_drive_into("roof-nw-6", Vector2(-27, -100), PI / 2.0, 0.0, -96.0, 1)
	assert_true(_area("roof-nw-6").covering)
	assert_almost_eq(_area("roof-nw-6").alpha(), MvpMapScript.SEE_THROUGH_ALPHA, 1e-4)
	assert_true(_area("roof-nw-3").covering)
	assert_almost_eq(_area("roof-nw-3").alpha(), MvpMapScript.SEE_THROUGH_ALPHA, 1e-4)
