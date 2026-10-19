extends GutTest
## Task T-191: the elevation test scene's raised areas turn see-through like
## the map's buildings (15% visible, 0.15 s fade, both ways) while they cover
## the car, and a car hitting the platform's back sides (west and north, the
## top-left and top-right sides on screen) from behind stays drawn under the
## platform on every step of the hit.
##
## The test data (data/level/elevation_test.json, proposals): platform 16 x 16
## at (-8, -8), height 3; ramp on its east side, 12 x 8 at (8, -4).

const SCENE := preload("res://scenes/elevation_test/elevation_test.tscn")
const MvpMapScript := preload("res://scripts/level/mvp_map.gd")
const MapBuildingScript := preload("res://scripts/level/map_building.gd")

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


func _platform():
	for a in scene.areas:
		if a.kind == "platform":
			return a
	return null


func _ramp():
	for a in scene.areas:
		if a.kind == "ramp":
			return a
	return null


## Puts the car somewhere at rest and sets every area's fade straight to solid.
func _put(units: Vector2, rot: float = 0.0) -> void:
	scene.place_car(units, rot)
	for a in scene.areas:
		a.modulate.a = 1.0
	scene.update_depth()
	scene.update_see_through(0.0)


# --- The fade's numbers -------------------------------------------------------

func test_the_fade_uses_the_buildings_numbers() -> void:
	assert_eq(MvpMapScript.SEE_THROUGH_ALPHA, 0.15, "the buildings: 15% visible")
	assert_eq(MvpMapScript.SEE_THROUGH_FADE_TIME, 0.15, "the buildings: 0.15 s")
	for a in scene.areas:
		assert_eq(a.see_through_alpha, MvpMapScript.SEE_THROUGH_ALPHA, a.name)
		assert_eq(a.fade_time, MvpMapScript.SEE_THROUGH_FADE_TIME, a.name)


func test_the_fade_step_is_the_buildings_one() -> void:
	# The same step as a map building given the same inputs.
	var b = MapBuildingScript.new()
	autofree(b)
	var a = _platform()
	_put(Vector2(-10, 0), 0.0)  # behind the platform, covered by it
	a.modulate.a = 1.0
	b.modulate.a = 1.0
	for i in 4:
		a.update_fade(scene.car.model.get_position(), scene.DEPTH_RADIUS, scene.car.height, scene.car_shape(), 0.03)
		b.step_fade(true, 0.03)
		assert_almost_eq(a.alpha(), b.alpha(), 1e-6, "step %d" % i)


# --- Fading in and out --------------------------------------------------------

func test_the_platform_fades_while_it_covers_the_car_and_comes_back() -> void:
	var p = _platform()
	_put(Vector2(-10, 0), 0.0)  # on the street west of it: behind it, covered
	assert_true(p.covering, "the platform covers the car")
	assert_almost_eq(p.alpha(), 1.0, 1e-6, "no time passed yet")
	scene.update_see_through(0.075)
	assert_almost_eq(p.alpha(), 1.0 - 0.5 * (1.0 - 0.15), 1e-4, "half way after half the fade time")
	scene.update_see_through(0.075)
	assert_almost_eq(p.alpha(), 0.15, 1e-4, "15% visible after 0.15 s")
	scene.update_see_through(0.5)
	assert_almost_eq(p.alpha(), 0.15, 1e-4, "and stays there")
	# Out in front of it: it no longer covers the car and fades back.
	scene.place_car(Vector2(0, 12), 0.0)
	scene.update_see_through(0.075)
	assert_false(p.covering)
	assert_almost_eq(p.alpha(), 0.15 + 0.5 * (1.0 - 0.15), 1e-4, "half way back")
	scene.update_see_through(0.075)
	assert_almost_eq(p.alpha(), 1.0, 1e-4, "solid again after 0.15 s")


func test_the_platform_fades_with_the_car_north_of_it_too() -> void:
	_put(Vector2(0, -10), PI / 2.0)
	assert_true(_platform().covering)
	scene.update_see_through(0.15)
	assert_almost_eq(_platform().alpha(), 0.15, 1e-4)


func test_nothing_fades_when_the_car_is_on_or_in_front_of_the_areas() -> void:
	for at in [Vector2(0, 0), Vector2(0, 12), Vector2(14, 0), Vector2(26, 0), Vector2(12, 8)]:
		_put(at, 0.0)
		scene.update_see_through(0.5)
		for a in scene.areas:
			assert_false(a.covering, "%s at %s" % [a.name, at])
			assert_almost_eq(a.alpha(), 1.0, 1e-6, "%s at %s" % [a.name, at])


func test_the_platform_does_not_fade_when_the_car_is_behind_but_far_from_it_on_screen() -> void:
	# Far west and far north of it: behind it, but nowhere near it on screen.
	_put(Vector2(-40, 30), 0.0)
	assert_false(_platform().covering)
	_put(Vector2(30, -40), 0.0)
	assert_false(_platform().covering)


func test_the_ramp_fades_when_it_covers_the_car() -> void:
	var r = _ramp()
	_put(Vector2(14, -4.6), 0.0)  # on the street just north of the ramp: behind it
	assert_true(r.covering, "the ramp covers the car")
	assert_false(_platform().covering, "the car is in front of the platform")
	scene.update_see_through(0.15)
	assert_almost_eq(r.alpha(), 0.15, 1e-4)
	assert_almost_eq(_platform().alpha(), 1.0, 1e-6)


func test_the_car_above_the_platform_does_not_make_it_fade() -> void:
	_put(Vector2(0, -10))
	scene.car.height_model.height = 3.5
	scene.car.height_model.airborne = true
	scene.update_see_through(0.15)
	assert_false(_platform().covering)
	assert_almost_eq(_platform().alpha(), 1.0, 1e-6)


func test_only_modulate_alpha_changes_so_the_art_fades_with_the_area() -> void:
	var p = _platform()
	_put(Vector2(-10, 0), 0.0)
	scene.update_see_through(0.15)
	assert_almost_eq(p.modulate.a, 0.15, 1e-4)
	assert_eq(p.modulate.r, 1.0)
	if p.art_sprite != null:
		assert_eq(p.art_sprite.modulate.a, 1.0, "the sprite's own pixels stay as they are")
		assert_eq(p.art_sprite.get_parent(), p, "the art is a child, so it fades with the area")


func test_the_scene_fades_by_itself_while_driving() -> void:
	# sync_view (every physics step) runs the fade: no extra call needed.
	scene.place_car(Vector2(-12, 0), 0.0)
	scene.sync_view()
	for i in 10:
		scene.car.physics_step()
	assert_true(_platform().covering)
	assert_almost_eq(_platform().alpha(), 0.15, 1e-4, "10 steps of 0.02 s > 0.15 s")


# --- No popping over the platform at a back-side wall hit ----------------------

## Drives the car from start with heading rot and W held (steer as given) for
## steps physics steps; checks the car's drawing is under the platform on every
## step and returns the number of wall hits and the closest the car's centre
## came to the side (units, along normal n pointing away from the platform).
func _drive_into_back_side(start: Vector2, rot: float, steer: float, side_line: float, axis: int) -> Dictionary:
	scene.place_car(start, rot)
	scene.sync_view()
	scene.car.scripted_input = [true, false, steer]
	var p = _platform()
	var closest := INF
	var under_every_step := true
	for i in 150:
		scene.car.physics_step()
		var units: Vector2 = scene.car.model.get_position()
		var gap: float = side_line - (units.x if axis == 0 else units.y)
		closest = minf(closest, gap)
		if scene.car_sprite.z_index >= p.z_index:
			under_every_step = false
			fail_test("step %d at %s: the car (z %d) is drawn over the platform (z %d)" % [
				i, units, scene.car_sprite.z_index, p.z_index])
			break
		if scene.shadow.z_index >= p.z_index:
			under_every_step = false
			fail_test("step %d at %s: the shadow is drawn over the platform" % [i, units])
			break
	return {"hits": _hits, "closest": closest, "under": under_every_step}


func _assert_hit(result: Dictionary, what: String) -> void:
	assert_true(result.under, "%s: under the platform on every step" % what)
	assert_gt(result.hits, 0, "%s: the car hit the side" % what)
	# The hit brought the car's 1 x 1 footprint into the platform's rectangle:
	# the moment the old footprint rule drew it over the platform.
	assert_lt(result.closest, scene.DEPTH_RADIUS, "%s: the footprint reached the side" % what)
	assert_gte(result.closest, 0.0, "%s: the centre stayed outside" % what)


func test_driving_into_the_west_side_straight_stays_under_the_platform() -> void:
	_assert_hit(_drive_into_back_side(Vector2(-12, 0), 0.0, 0.0, -8.0, 0), "west, straight")


func test_driving_into_the_west_side_at_an_angle_stays_under_the_platform() -> void:
	_assert_hit(_drive_into_back_side(Vector2(-12, -4), 0.6, 0.0, -8.0, 0), "west, angled south")
	_hits = 0
	_assert_hit(_drive_into_back_side(Vector2(-12, 4), -0.6, 0.0, -8.0, 0), "west, angled north")


func test_driving_into_the_west_side_while_steering_stays_under_the_platform() -> void:
	_assert_hit(_drive_into_back_side(Vector2(-12, 2), 0.0, 0.5, -8.0, 0), "west, steering")


func test_driving_into_the_north_side_straight_stays_under_the_platform() -> void:
	_assert_hit(_drive_into_back_side(Vector2(0, -12), PI / 2.0, 0.0, -8.0, 1), "north, straight")


func test_driving_into_the_north_side_at_an_angle_stays_under_the_platform() -> void:
	_assert_hit(_drive_into_back_side(Vector2(-4, -12), PI / 2.0 - 0.6, 0.0, -8.0, 1), "north, angled east")
	_hits = 0
	_assert_hit(_drive_into_back_side(Vector2(4, -12), PI / 2.0 + 0.6, 0.0, -8.0, 1), "north, angled west")


func test_driving_into_the_north_side_while_steering_stays_under_the_platform() -> void:
	_assert_hit(_drive_into_back_side(Vector2(2, -12), PI / 2.0, -0.5, -8.0, 1), "north, steering")


func test_at_the_back_side_hit_the_platform_is_see_through() -> void:
	_drive_into_back_side(Vector2(-12, 0), 0.0, 0.0, -8.0, 0)
	assert_true(_platform().covering, "the car against the west side is covered")
	assert_almost_eq(_platform().alpha(), 0.15, 1e-4)


func test_a_car_straddling_a_back_side_is_behind_by_its_centre() -> void:
	var p = _platform()
	# Centre just outside the west and north sides, footprint reaching in.
	assert_true(p.is_behind(Vector2(-8.05, 0), 0.5, 0.0), "west side")
	assert_true(p.is_behind(Vector2(0, -8.05), 0.5, 0.0), "north side")
	# Just outside the front sides it stays in front.
	assert_false(p.is_behind(Vector2(8.05, 6), 0.5, 0.0), "east side")
	assert_false(p.is_behind(Vector2(0, 8.05), 0.5, 0.0), "south side")
	# On the top, or above it, never behind.
	assert_false(p.is_behind(Vector2(-7.9, 0), 0.5, 3.0), "on the top at the edge")
	assert_false(p.is_behind(Vector2(-8.05, 0), 0.5, 3.2), "above it")
