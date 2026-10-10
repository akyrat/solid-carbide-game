extends GutTest
## Task T-020: a building fades when the car is behind it and returns to normal
## when the car leaves. Drives the see-through demo with no keyboard.

const DemoScript := preload("res://scripts/level/see_through_demo.gd")
const SCENE := preload("res://scenes/see_through_demo/see_through_demo.tscn")

## The building at world Rect2(120, -120, 96, 96) (index 1 in the demo).
const BEHIND := Vector2(96, -150)
const IN_FRONT := Vector2(232, -4)
const FAR_AWAY := Vector2(-250, 250)


func _make(car_world: Vector2) -> SeeThroughDemo:
	var demo: SeeThroughDemo = SCENE.instantiate()
	demo.keyboard = false
	demo.car_world = car_world
	add_child_autofree(demo)
	return demo


func _step(demo: SeeThroughDemo, seconds: float) -> void:
	for i in int(seconds * 60.0):
		demo._update_buildings(1.0 / 60.0)


func test_scene_builds_buildings_and_car() -> void:
	var demo := _make(FAR_AWAY)
	assert_eq(demo.buildings.size(), 4)
	assert_not_null(demo.car_sprite)


func test_building_fades_when_car_is_behind_it() -> void:
	var demo := _make(BEHIND)
	var b: SeeThroughBuilding = demo.buildings[1]
	assert_true(b.see_through, "car is behind building 1")
	_step(demo, 1.0)
	assert_almost_eq(b.current_alpha, demo.see_through_alpha, 0.001)
	assert_almost_eq(b.modulate.a, demo.see_through_alpha, 0.001)


func test_building_returns_to_normal_when_car_leaves() -> void:
	var demo := _make(BEHIND)
	var b: SeeThroughBuilding = demo.buildings[1]
	_step(demo, 1.0)
	assert_lt(b.modulate.a, 1.0)
	demo.car_world = FAR_AWAY
	_step(demo, 1.0)
	assert_false(b.see_through)
	assert_almost_eq(b.modulate.a, 1.0, 0.001)


func test_building_stays_solid_when_car_is_in_front() -> void:
	var demo := _make(IN_FRONT)
	_step(demo, 1.0)
	for b in demo.buildings:
		assert_almost_eq(b.modulate.a, 1.0, 0.001, "nothing is between the car and the viewer")


func test_beside_a_building_is_not_behind_it() -> void:
	# Same distance from the viewer as BEHIND, but off to the side on screen.
	var demo := _make(Vector2(-60, -100))
	var b: SeeThroughBuilding = demo.buildings[1]
	assert_false(b.see_through)


func test_fade_is_gradual() -> void:
	var demo := _make(BEHIND)
	demo.fade_time = 0.5
	demo._update_buildings(0.1)
	var b: SeeThroughBuilding = demo.buildings[1]
	assert_gt(b.current_alpha, demo.see_through_alpha, "still on its way")
	assert_lt(b.current_alpha, 1.0, "already started")


func test_cutout_mode_uses_shader_and_keeps_building_solid() -> void:
	var demo := _make(BEHIND)
	demo.mode = SeeThroughBuilding.Mode.CUTOUT
	demo.see_through_alpha = 0.0
	_step(demo, 1.0)
	var b: SeeThroughBuilding = demo.buildings[1]
	assert_true(b.material is ShaderMaterial)
	assert_almost_eq(b.modulate.a, 1.0, 0.001)
	assert_almost_eq(float(b.material.get_shader_parameter("hole_alpha")), 0.0, 0.001)
	assert_eq(b.material.get_shader_parameter("hole_center"), SeeThroughBuilding.iso(BEHIND))


func test_draw_order_matches_depth() -> void:
	var demo := _make(BEHIND)
	assert_lt(demo.car_sprite.z_index, demo.buildings[1].z_index, "car draws behind the building")
	demo.car_world = IN_FRONT
	demo._refresh()
	assert_gt(demo.car_sprite.z_index, demo.buildings[1].z_index, "car draws in front of it")


func test_many_buildings_only_the_covering_ones_fade() -> void:
	var demo := _make(BEHIND)
	_step(demo, 1.0)
	var faded := 0
	for b in demo.buildings:
		if b.modulate.a < 1.0:
			faded += 1
	assert_between(faded, 1, 2)
