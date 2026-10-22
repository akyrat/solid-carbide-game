extends GutTest
## Task T-185: the elevation test scene's drawing. The car's drawing lifts up
## the screen with its height (16 px per unit), its shadow stays at its map
## position on the ground under it, the platform and ramp placeholders are
## drawn with no Redgull red, and the depth order puts the car under an area
## it is behind and over one it is on or above.
##
## The test data (data/level/elevation_test.json, proposals): platform 16 x 16
## at (-8, -8), height 3; ramp on its east side, 12 x 8 at (8, -4), height
## (20 - x) / 4.

const SCENE := preload("res://scenes/elevation_test/elevation_test.tscn")
const CarSpriteScript := preload("res://scripts/driving/car_sprite.gd")
const CarShadowScript := preload("res://scripts/driving/car_shadow.gd")
const PlatformDrawingScript := preload("res://scripts/level/elevation_platform_drawing.gd")
const HudScript := preload("res://scripts/hud/hud.gd")
const ISO := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)

var scene: Node2D
var _interp_before := false


func before_each() -> void:
	_interp_before = get_tree().physics_interpolation
	scene = SCENE.instantiate()
	add_child_autofree(scene)
	scene.car.set_physics_process(false)
	scene.car.use_keyboard = false
	scene.car.detect_tricks = false


func after_each() -> void:
	get_tree().physics_interpolation = _interp_before


func _drawn(units: Vector2) -> Vector2:
	return ISO * (units * 16.0)


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


func _put(units: Vector2, rot: float = 0.0) -> void:
	scene.place_car(units, rot)
	scene.sync_view()


# --- The lift ---------------------------------------------------------------

func test_lift_is_16_px_up_the_screen_per_unit_of_height() -> void:
	assert_eq(CarSpriteScript.lift_for_height(1.0), Vector2(0, -16))
	assert_eq(CarSpriteScript.lift_for_height(0.0), Vector2.ZERO)
	assert_eq(CarSpriteScript.lift_for_height(2.5), Vector2(0, -40))


func test_the_drawing_is_offset_by_height_times_16_for_a_known_height() -> void:
	_put(Vector2(0, 12))  # on the street, in front of the platform
	scene.car.height_model.height = 1.0  # one unit up
	scene.sync_view()
	assert_eq(scene.car_sprite.position, _drawn(Vector2(0, 12)) + Vector2(0, -16))


func test_the_car_on_the_platform_is_drawn_48_px_up() -> void:
	_put(Vector2(0, 0))
	assert_almost_eq(scene.car.height, 3.0, 1e-9)
	assert_eq(scene.car_sprite.position, _drawn(Vector2.ZERO) + Vector2(0, -48))


func test_the_car_on_the_street_is_not_lifted() -> void:
	_put(Vector2(26, 0), PI)
	assert_eq(scene.car_sprite.position, _drawn(Vector2(26, 0)))


# --- The shadow --------------------------------------------------------------

func test_the_shadow_is_on_the_street_under_a_car_in_the_air() -> void:
	_put(Vector2(0, 12))
	scene.car.height_model.height = 2.0
	scene.car.height_model.airborne = true
	scene.sync_view()
	assert_eq(scene.shadow.position, _drawn(Vector2(0, 12)))
	assert_eq(scene.shadow.surface_height, 0.0)
	assert_eq(scene.car_sprite.position, _drawn(Vector2(0, 12)) + Vector2(0, -32))


func test_the_shadow_is_on_the_platform_top_when_over_it() -> void:
	_put(Vector2(2, -3))
	scene.car.height_model.height = 4.5  # in the air above the platform
	scene.car.height_model.airborne = true
	scene.sync_view()
	assert_eq(scene.shadow.position, _drawn(Vector2(2, -3)) + Vector2(0, -48))
	assert_eq(scene.shadow.surface_height, 3.0)
	assert_eq(scene.car_sprite.position, _drawn(Vector2(2, -3)) + Vector2(0, -72))


func test_the_shadow_is_on_the_ramp_when_over_it() -> void:
	_put(Vector2(14, 0), PI)  # ramp height (20 - 14) / 4 = 1.5
	assert_almost_eq(scene.shadow.surface_height, 1.5, 1e-9)
	assert_almost_eq(scene.shadow.position.y, _drawn(Vector2(14, 0)).y - 24.0, 1e-6)


func _bounds(pts: PackedVector2Array) -> Rect2:
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	return r


func test_the_shadow_is_an_ellipse_centred_under_the_cars_map_position() -> void:
	_put(Vector2(0, 12), 0.7)
	var pts: PackedVector2Array = scene.shadow.outline()
	var sum := Vector2.ZERO
	for p in pts:
		sum += p
	assert_almost_eq((sum / pts.size()).length(), 0.0, 1e-4, "centred on the shadow's position")
	assert_eq(scene.shadow.position, _drawn(Vector2(0, 12)), "at the car's map position")


func test_the_shadow_is_about_one_unit_across_and_twice_as_wide_as_tall() -> void:
	_put(Vector2(0, 12))
	var b := _bounds(scene.shadow.outline())
	# 1 unit across on the ground: sqrt(2) x 16 px wide on screen in this view.
	assert_almost_eq(b.size.x, 16.0 * sqrt(2.0), 0.1)
	assert_almost_eq(b.size.x / b.size.y, 2.0, 0.01, "2:1 on screen")
	# every point of the outline is half a unit from the centre on the ground
	var inv := ISO.affine_inverse()
	for p in scene.shadow.outline():
		assert_almost_eq(inv.basis_xform(p).length(), 8.0, 1e-3)


func test_the_shadow_does_not_turn_with_the_car() -> void:
	_put(Vector2(0, 12), 0.0)
	var a: PackedVector2Array = scene.shadow.outline()
	for rot in [0.5, PI / 2.0, PI, 4.0]:
		_put(Vector2(0, 12), rot)
		assert_eq(scene.shadow.outline(), a, "same outline at heading %s" % rot)


func test_the_shadow_keeps_its_colour_and_is_opaque() -> void:
	assert_eq(CarShadowScript.COLOR, Color(0.02, 0.02, 0.05, 1.0))
	assert_eq(scene.shadow.modulate, Color.WHITE)


# --- Colours -----------------------------------------------------------------

func _far_from_redgull(c: Color, what: String) -> void:
	var red: Color = HudScript.HEART_COLOR
	assert_eq(c.a, 1.0, what + ": opaque (no semi-transparent pixels)")
	assert_gt(Vector3(c.r - red.r, c.g - red.g, c.b - red.b).length(), 0.5, what + ": far from Redgull red")


func test_the_placeholders_and_the_shadow_use_no_redgull_red() -> void:
	var colours: Array = PlatformDrawingScript.colors_used()
	assert_gt(colours.size(), 3)
	for c in colours:
		_far_from_redgull(c, "platform / ramp colour %s" % c)
	_far_from_redgull(CarShadowScript.COLOR, "shadow")
	assert_lt(CarShadowScript.COLOR.get_luminance(), 0.1, "the shadow is dark")


# --- The placeholder shapes ---------------------------------------------------

func test_the_platform_top_is_lifted_by_its_height_and_shows_two_sides() -> void:
	var p = _platform()
	assert_not_null(p)
	var top: PackedVector2Array = p.top_face()
	assert_eq(top[0], _drawn(Vector2(-8, -8)) + Vector2(0, -48))
	assert_eq(top[2], _drawn(Vector2(8, 8)) + Vector2(0, -48))
	assert_eq(p.east_face().size(), 4)
	assert_eq(p.south_face().size(), 4)


func test_the_ramp_rises_from_its_foot_to_the_platform() -> void:
	var r = _ramp()
	assert_not_null(r)
	assert_eq(r.corner_heights(), [3.0, 0.0, 0.0, 3.0])
	assert_almost_eq(r.top_height_at(Vector2(14, 0)), 1.5, 1e-9)
	assert_eq(r.east_face().size(), 0, "the foot has no side")
	assert_eq(r.south_face().size(), 3, "the south side is a triangle")


func test_the_areas_are_drawn_back_to_front() -> void:
	assert_eq(scene.areas.size(), 2)
	assert_eq(scene.areas[0].kind, "platform")
	assert_eq(scene.areas[1].kind, "ramp")
	assert_lt(scene.areas[0].z_index, scene.areas[1].z_index)


# --- Depth order -------------------------------------------------------------

func test_the_car_on_the_street_behind_the_platform_is_drawn_under_it() -> void:
	_put(Vector2(-10, 0), 0.0)  # west of the platform: behind it
	assert_lt(scene.car_sprite.z_index, _platform().z_index)
	assert_lt(scene.shadow.z_index, _platform().z_index)
	assert_lt(scene.shadow.z_index, scene.car_sprite.z_index)
	_put(Vector2(0, -10), 0.0)  # north of it: behind it too
	assert_lt(scene.car_sprite.z_index, _platform().z_index)


func test_the_car_on_the_platform_is_drawn_over_it() -> void:
	_put(Vector2(0, 0))
	assert_gt(scene.car_sprite.z_index, _platform().z_index)
	assert_gt(scene.shadow.z_index, _platform().z_index)
	assert_gt(scene.car_sprite.z_index, scene.shadow.z_index)


func test_the_car_on_the_street_in_front_of_the_platform_is_drawn_over_it() -> void:
	_put(Vector2(0, 10))
	assert_gt(scene.car_sprite.z_index, _platform().z_index)
	assert_gt(scene.car_sprite.z_index, _ramp().z_index)


func test_the_car_above_the_platform_behind_it_is_over_it_and_so_is_its_shadow() -> void:
	_put(Vector2(0, -10))
	scene.car.height_model.height = 3.5
	scene.car.height_model.airborne = true
	scene.sync_view()
	assert_gt(scene.car_sprite.z_index, _platform().z_index)
	# T-258: the shadow is not lost under the area the car is over.
	assert_gt(scene.shadow.z_index, _platform().z_index)
	assert_lt(scene.shadow.z_index, scene.car_sprite.z_index)


func test_the_car_on_the_ramp_is_over_it_and_behind_it_under_it() -> void:
	_put(Vector2(14, 0), PI)
	assert_gt(scene.car_sprite.z_index, _ramp().z_index)
	_put(Vector2(14, -6), PI)  # on the street north of the ramp: behind it
	assert_lt(scene.car_sprite.z_index, _ramp().z_index)
	assert_gt(scene.car_sprite.z_index, _platform().z_index, "but in front of the platform")


# --- Driving it --------------------------------------------------------------

func test_driving_up_the_ramp_the_drawing_follows_the_height_every_step() -> void:
	scene.car.scripted_input = [true, false, 0.0]
	var was_airborne := false
	for i in 120:
		scene.car.physics_step()
		var units: Vector2 = scene.car.model.get_position()
		assert_almost_eq(scene.car_sprite.position.y, _drawn(units).y - scene.car.height * 16.0, 1e-4)
		var under: float = scene.ground_height.height_at(units)
		assert_almost_eq(scene.shadow.position.y, _drawn(units).y - under * 16.0, 1e-4)
		if scene.car.airborne:
			was_airborne = true
	assert_true(was_airborne, "the car left the ramp's top in the air")


func test_the_scene_runs_for_a_second_on_its_own() -> void:
	scene.car.set_physics_process(true)
	await wait_physics_frames(50)
	assert_true(is_instance_valid(scene.car))
	assert_eq(scene.car_sprite.sheet, "iso")


## Task T-192: the car is drawn at its normal size at every height.
func test_the_cars_drawing_scale_is_the_same_at_every_height() -> void:
	var base: Vector2 = scene.car_sprite.scale
	for h in [0.0, 1.5, 3.0, 4.5]:
		scene.car_sprite.place(Vector2.ZERO, h)
		assert_eq(scene.car_sprite.scale, base, "scale unchanged at height %s" % h)
	assert_false("draw_bigger_when_high" in scene)
	assert_false("height_scale_per_unit" in scene.car_sprite)
