extends GutTest
## Task T-205: the car is drawn from the shadowless sheet (car_iso_noshadow.png,
## T-204) while its height is above the ground under it, and from the normal
## sheet (car_iso.png) on the ground; the same frame for the same heading. The
## switch happens on the step it takes off and the step it lands. The run's car
## and the drift prototype's car never leave the ground: always the normal sheet.

const TEST_SCENE := preload("res://scenes/elevation_test/elevation_test.tscn")
const SAMPLE_SCENE := preload("res://scenes/elevation_sample/elevation_sample_map.tscn")
const RUN_SCENE := preload("res://scenes/run/run.tscn")
const DRIFT_SCENE := preload("res://scenes/drift_prototype/drift_prototype.tscn")
const CarSpriteScript := preload("res://scripts/driving/car_sprite.gd")
const NORMAL := "res://art/car/car_iso.png"
const SHADOWLESS := "res://art/car/car_iso_noshadow.png"

var _interp_before := false


func before_each() -> void:
	_interp_before = get_tree().physics_interpolation


func after_each() -> void:
	get_tree().physics_interpolation = _interp_before


func _scene(packed: PackedScene) -> Node2D:
	var s: Node2D = packed.instantiate()
	add_child_autofree(s)
	s.car.set_physics_process(false)
	s.car.use_keyboard = false
	s.car.detect_tricks = false
	return s


func _is_normal(sprite) -> bool:
	return sprite.texture.resource_path == NORMAL


func _is_shadowless(sprite) -> bool:
	return sprite.texture.resource_path == SHADOWLESS


func test_both_sheets_have_one_layout() -> void:
	var a = JSON.parse_string(FileAccess.get_file_as_string("res://art/car/car_iso.json"))
	var b = JSON.parse_string(FileAccess.get_file_as_string("res://art/car/car_iso_noshadow.json"))
	for k in ["columns", "rows", "frame_count", "frame_width", "frame_height", "center_px", "px_per_unit", "step_deg", "frame0_heading_deg"]:
		assert_eq(a[k], b[k], k)


func test_on_the_ground_the_normal_sheet() -> void:
	var s := _scene(SAMPLE_SCENE)
	s.place_car(Vector2(-81, -50), 0.0)
	s.sync_view()
	assert_false(s.car_sprite.in_air)
	assert_true(_is_normal(s.car_sprite))


func test_on_a_rooftop_the_normal_sheet() -> void:
	var s := _scene(SAMPLE_SCENE)
	s.place_car(Vector2(-70, -81), 0.0)
	s.sync_view()
	assert_almost_eq(s.car.height, 3.0, 0.001)
	assert_true(_is_normal(s.car_sprite), "on a rooftop is on the ground under it")


func test_above_the_ground_the_shadowless_sheet() -> void:
	var s := _scene(SAMPLE_SCENE)
	s.place_car(Vector2(-70, -81), 0.0)
	s.car.height_model.height = s.car.height + 2.0
	s.car.height_model.airborne = true
	s.sync_view()
	assert_true(s.car_sprite.in_air)
	assert_true(_is_shadowless(s.car_sprite))


func test_the_frame_is_the_same_on_both_sheets() -> void:
	var s := _scene(SAMPLE_SCENE)
	for i in 32:
		var rot := float(i) * deg_to_rad(11.25) + 0.03
		s.place_car(Vector2(0, -81), rot)
		s.sync_view()
		var ground_frame: int = s.car_sprite.frame
		s.car.height_model.height = 3.0
		s.car.height_model.airborne = true
		s.sync_view()
		assert_true(_is_shadowless(s.car_sprite))
		assert_eq(s.car_sprite.frame, ground_frame, "heading %d" % i)
		assert_eq(s.car_sprite.frame, s.car_sprite.frame_for_rotation(rot))
		assert_eq(s.car_sprite.hframes, 32)


func test_the_switch_is_on_the_takeoff_step_and_the_landing_step() -> void:
	var s := _scene(TEST_SCENE)
	s.place_car(Vector2(19.5, 0), PI)
	s.car.scripted_input = [true, false, 0.0]
	var took_off := false
	var landed := false
	for i in 600:
		s.car.physics_step()
		s.sync_view()
		var above: bool = s.car.height > s.ground_height.height_at(s.car.model.get_position()) + 0.0001
		assert_eq(s.car_sprite.in_air, above, "step %d" % i)
		assert_eq(_is_shadowless(s.car_sprite), above, "step %d" % i)
		assert_eq(_is_normal(s.car_sprite), not above, "step %d" % i)
		if above:
			took_off = true
		elif took_off:
			landed = true
			break
	assert_true(took_off, "the car took off")
	assert_true(landed, "the car landed, back on the normal sheet")


func test_the_run_car_always_uses_the_normal_sheet() -> void:
	var run: Node = RUN_SCENE.instantiate()
	add_child_autofree(run)
	var sprite = run.car_sprite
	assert_true(_is_normal(sprite))
	assert_false(sprite.in_air)
	for i in 5:
		await get_tree().physics_frame
	assert_true(_is_normal(sprite))
	assert_false(sprite.in_air)
	assert_eq(sprite.AIR_SHEETS.keys(), ["iso"], "only the isometric view has an air sheet")


func test_the_drift_prototype_car_always_uses_the_normal_sheet() -> void:
	var proto: Node = DRIFT_SCENE.instantiate()
	add_child_autofree(proto)
	var sprite = proto.car_sprite
	for view in ["iso", "flat"]:
		sprite.use_sheet(view)
		for i in 3:
			await get_tree().physics_frame
		assert_false(sprite.in_air)
		assert_true(sprite.texture.resource_path.ends_with("car_%s.png" % view), view)


func test_is_in_air_compares_the_height_to_the_ground_under_it() -> void:
	assert_false(CarSpriteScript.is_in_air(0.0, 0.0))
	assert_false(CarSpriteScript.is_in_air(3.0, 3.0))
	assert_true(CarSpriteScript.is_in_air(3.5, 3.0))
	assert_true(CarSpriteScript.is_in_air(0.5, 0.0))
