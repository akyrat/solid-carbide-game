extends GutTest
## Task T-206: a run plays on the elevation sample map's layout
## (data/level/elevation_sample_map.json) with its rooftops and ramps
## (elevation_layer.gd), and run.gd's USE_ELEVATION_MAP switches it back to
## the MVP map. Heights: roof-nw-3 (height 3) under (-70, -81), roof-nw-6
## (height 6) under (-27, -81), the street at (-81, -40) and the start (0, 0).

const RunScene := preload("res://scenes/run/run.tscn")
const RunScript := preload("res://scripts/run/run.gd")
const ElevationLayerScript := preload("res://scripts/level/elevation_layer.gd")
const ELEVATION_LAYOUT := "res://data/level/elevation_sample_map.json"
const MVP_LAYOUT := "res://data/level/mvp_map.json"

var run: Node2D


func before_each() -> void:
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.car.use_keyboard = false
	run.car.detect_tricks = false


func _area(id: String):
	for a in run.elevation.areas:
		if str(a.block.id) == id:
			return a
	return null


## Puts the run's car at rest at `units` with heading `rot`, on the ground there.
func _place(units: Vector2, rot: float = 0.0) -> void:
	var car = run.car
	car.model.set_position(units)
	car.model.rotation = rot
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = run.elevation.ground_height
	run.sync_view()


# --- The switch -----------------------------------------------------------------

func test_the_elevation_map_is_the_default() -> void:
	assert_true(RunScript.USE_ELEVATION_MAP, "the run's map is the elevation sample map")
	assert_eq(run.map.layout_path, ELEVATION_LAYOUT)
	assert_eq(str(run.map.layout.name), "Elevation sample map")
	assert_not_null(run.elevation, "the run has the rooftops and ramps")
	assert_eq(run.elevation.get_script(), ElevationLayerScript)
	assert_eq(run.map.elevation, run.elevation, "the map knows its elevation")
	assert_eq(run.elevation.get_parent(), run.map, "drawn in the map's place")


func test_switched_off_the_run_builds_the_mvp_map() -> void:
	run.use_elevation_map = false
	run.start_run()
	assert_eq(run.map.layout_path, MVP_LAYOUT)
	assert_null(run.elevation, "no rooftops on the MVP map")
	assert_null(run.map.elevation)
	assert_false(run.shadow.visible, "no round shadow on the MVP map")
	assert_null(run.car.ground, "the car stays at street level")


func test_one_drawing_per_rooftop_and_ramp() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ELEVATION_LAYOUT))
	assert_eq(run.elevation.areas.size(), data.platforms.size() + data.ramps.size())
	assert_eq(run.elevation.depth_items.size(),
		run.map.fade_items().size() + run.elevation.areas.size())


func test_a_new_run_brings_a_new_elevation() -> void:
	var old = run.elevation
	run.start_run()
	assert_ne(run.elevation, old)
	assert_eq(run.map.elevation, run.elevation)
	assert_eq(run.car.ground, run.elevation.ground_height)


# --- The car's height, shadow and depth order -------------------------------------

func test_the_car_starts_on_the_street_with_its_shadow() -> void:
	assert_eq(run.car.ground, run.elevation.ground_height, "the car has the map's heights")
	assert_almost_eq(run.elevation.ground_height.height_at(run.START_POSITION_UNITS), 0.0, 0.001,
		"the start is at street level (a proposal)")
	assert_true(run.shadow.visible, "the round shadow is shown")
	assert_lt(run.shadow.z_index, run.view_root.z_index, "the shadow under the car")


func test_on_a_rooftop_the_car_and_shadow_are_lifted() -> void:
	for spot in [[Vector2(-70, -81), 3.0], [Vector2(-27, -81), 6.0]]:
		_place(spot[0])
		var at_ground: Vector2 = run.ISO_TRANSFORM * (spot[0] * 16.0)
		assert_almost_eq(run.car.height, spot[1], 0.001, "height at %s" % spot[0])
		assert_almost_eq(run.car_sprite.position.y, at_ground.y - spot[1] * 16.0, 0.01, "sprite lifted")
		assert_almost_eq(run.shadow.surface_height, spot[1], 0.001, "shadow on the rooftop")
		assert_false(run.car_sprite.in_air, "on the rooftop, not in the air")


func test_in_the_air_the_car_uses_its_air_frames_and_the_shadow_stays_down() -> void:
	_place(Vector2(0, -81))
	run.car.height_model.height = 4.0
	run.car.height_model.airborne = true
	run.sync_view()
	assert_true(run.car_sprite.in_air, "the shadowless frames")
	assert_almost_eq(run.shadow.surface_height, 0.0, 0.001)


func test_the_car_on_a_rooftop_is_drawn_over_it_and_behind_one_under_it() -> void:
	_place(Vector2(-27, -81))
	assert_gt(run.view_root.z_index, _area("roof-nw-6").z_index)
	_place(Vector2(-54, -98))
	assert_lt(run.view_root.z_index, _area("roof-nw-3").z_index)


func test_a_rooftop_covering_the_car_fades() -> void:
	_place(Vector2(-54, -98))
	assert_true(run.elevation.covering_areas().has(_area("roof-nw-3")), "the rooftop covers the car")


func test_the_camera_follows_the_car_as_drawn_on_a_rooftop() -> void:
	_place(Vector2(-27, -81))
	var at_ground: Vector2 = run.ISO_TRANSFORM * (Vector2(-27, -81) * 16.0)
	assert_almost_eq(run.camera.position.x, at_ground.x, 0.01)
	assert_almost_eq(run.camera.position.y, at_ground.y - 6.0 * 16.0, 0.01, "lifted by the height")
	assert_almost_eq(run.camera.position.y, run.car_sprite.position.y, 0.01, "on the drawn car")


func test_the_run_camera_eases_to_the_car_when_its_height_changes() -> void:
	_place(Vector2(-27, -81))
	run.car.height_model.height = 0.0  # as if it had just come up from the street
	run.sync_view(true)
	run.car.height_model.height = 6.0
	run.sync_view(false)
	assert_gt(run.camera.position.y, run.car_sprite.position.y + 50.0, "one step later the camera is still well below the car")
	for i in 60:
		run.sync_view(false)
	assert_almost_eq(run.camera.position.y, run.car_sprite.position.y, 3.0, "settled on the car")


# --- The run's other things at street level ----------------------------------------

func test_open_spots_are_street_level_only() -> void:
	assert_false(run.map.is_open_spot(Vector2(-70, -81), 1.0), "a rooftop is no open spot")
	assert_true(run.map.is_open_spot(run.START_POSITION_UNITS, 1.0), "the gravel square is")


func test_an_enemy_behind_a_rooftop_is_drawn_under_it() -> void:
	var depth = preload("res://scripts/enemies/enemy_depth.gd").new(run.map)
	var z: int = depth.z_index_for(Vector2(-54, -98), 0.5, 0.0)
	assert_lt(z, _area("roof-nw-3").z_index, "at street level, under the rooftop covering it")


func test_the_run_goes_on_with_enemies_and_weapons() -> void:
	run.car.scripted_input = [true, false, 0.4]
	run.state.time_left = 200.0
	await wait_seconds(4.0)
	assert_true(run.state.is_running())
	assert_gt(run.minions.minions.size(), 0, "enemies spawned")


# --- The board's tweaks after playing it (2026-10-21) ---------------------------

## Drifting, Decisions, "No drift smoke in the air": no smoke while airborne,
## even with the drift state on; it comes back on landing.
func test_no_drift_smoke_in_the_air_and_back_on_landing() -> void:
	_place(Vector2(0, -81))
	run.drift_smoke.clear()
	run.car.model.is_drifting = true
	run.car.height_model.height = 4.0
	run.car.height_model.airborne = true
	for i in 10:
		run.car.stepped.emit()
	assert_eq(run.drift_smoke.puff_count(), 0, "no smoke in the air while drifting")
	run.car.height_model.height = 0.0
	run.car.height_model.airborne = false
	run.car.model.is_drifting = true
	run.car.stepped.emit()
	assert_gt(run.drift_smoke.puff_count(), 0, "smoke again once landed")


func test_drift_smoke_on_a_rooftop_while_drifting() -> void:
	_place(Vector2(-27, -81))
	run.drift_smoke.clear()
	run.car.model.is_drifting = true
	run.car.stepped.emit()
	assert_gt(run.drift_smoke.puff_count(), 0, "on a rooftop the car is not airborne: smoke")


## Weapons, Decisions, "The flamethrower at height": the flames come out of the
## exhaust where the car is drawn, at its height, and burn what they touch there.
func _flame_on_at(units: Vector2, height: float, airborne: bool):
	_place(units)
	if airborne:
		run.car.height_model.height = height
		run.car.height_model.airborne = true
		run.sync_view()
	assert_almost_eq(run.car.height, height, 0.001)
	run.minions.enabled = false
	run.weapons.gun.set_tier(0)
	assert_true(run.weapons.upgrade("flamethrower"))
	var flame = run.weapons.flamethrower
	run.car.model.is_drifting = true
	run.car.model.vx = 5.0
	run.car.model.vy = 0.0
	flame.step(0.02)
	assert_true(flame.active)
	return flame


func _check_flame_at_height(flame, height: float) -> void:
	var rot: float = run.car.model.rotation
	var back := -Vector2(cos(rot), sin(rot))
	var ground: Vector2 = run.ISO_TRANSFORM * ((run.car.model.get_position() + back * flame.EXHAUST_OFFSET_UNITS) * 16.0)
	var d: Node2D = flame.flame_drawing
	assert_almost_eq(d.position.x, ground.x, 0.01)
	assert_almost_eq(d.position.y, ground.y - height * 16.0, 0.01, "lifted by the car's height")
	# The exhaust is where the car is drawn: the same lift as the car sprite.
	var car_ground: Vector2 = run.ISO_TRANSFORM * (run.car.model.get_position() * 16.0)
	assert_almost_eq(run.car_sprite.position.y - d.position.y, car_ground.y - ground.y, 0.01,
		"the flame keeps its place next to the drawn car")


func test_the_flame_on_a_rooftop_is_at_the_cars_exhaust() -> void:
	var flame = _flame_on_at(Vector2(-27, -81), 6.0, false)
	_check_flame_at_height(flame, 6.0)


func test_the_flame_in_the_air_is_at_the_cars_exhaust() -> void:
	var flame = _flame_on_at(Vector2(0, -81), 4.0, true)
	_check_flame_at_height(flame, 4.0)


func test_the_flame_on_a_rooftop_burns_what_is_at_the_car() -> void:
	var flame = _flame_on_at(Vector2(-27, -81), 6.0, false)
	var e: Node2D = preload("res://tests/fixtures/weapons/fake_enemy.gd").new()
	var rot: float = run.car.model.rotation
	e.position = (run.car.model.get_position() - Vector2(cos(rot), sin(rot)) * 1.5) * 16.0
	run.add_child(e)
	var far: Node2D = preload("res://tests/fixtures/weapons/fake_enemy.gd").new()
	far.position = (run.car.model.get_position() + Vector2(0, 20)) * 16.0
	run.add_child(far)
	flame.step(0.02)
	assert_true(flame.is_inside(e), "the enemy behind the car's exhaust is in the flames")
	assert_false(flame.is_inside(far), "one far away is not")
	assert_gt(flame.hits, 0)


## Drifting, Decisions, "No drift smoke or tyre marks in the air": no tyre
## marks while airborne, even with the drift state on; new ones on landing.
func test_no_tyre_marks_in_the_air_and_back_on_landing() -> void:
	_place(Vector2(0, -81))
	run.car.model.is_drifting = true
	run.car.stepped.emit()
	var before: int = run.drift_marks.marks_started
	assert_gt(before, 0, "drifting on the street lays marks")
	run.car.height_model.height = 4.0
	run.car.height_model.airborne = true
	var segments_before: int = run.drift_marks.segment_count()
	for i in 10:
		run.car.model.is_drifting = true
		run.car.stepped.emit()
	assert_eq(run.drift_marks.marks_started, before, "no new marks in the air")
	assert_true(run.drift_marks.segment_count() <= segments_before, "nothing laid in the air")
	run.car.height_model.height = 0.0
	run.car.height_model.airborne = false
	run.car.model.is_drifting = true
	run.car.stepped.emit()
	assert_gt(run.drift_marks.marks_started, before, "new marks once landed")


# --- T-225: the underglow and the wiper rise with the car ------------------------

func _glow_at(units: Vector2, height: float, airborne: bool):
	_place(units)
	if airborne:
		run.car.height_model.height = height
		run.car.height_model.airborne = true
		run.sync_view()
	assert_almost_eq(run.car.height, height, 0.001)
	run.minions.enabled = false
	assert_true(run.weapons.upgrade("underglow"))
	var glow = run.weapons.underglow
	glow.step(0.02)
	return glow


func _check_glow_at_height(glow, height: float) -> void:
	var d: Node2D = glow.drawing
	assert_true(d.visible)
	var ground: Vector2 = run.ISO_TRANSFORM * (run.car.model.get_position() * 16.0)
	assert_almost_eq(d.position.x, ground.x, 0.01)
	assert_almost_eq(d.position.y, ground.y - height * 16.0, 0.01, "lifted by the car's height")
	assert_almost_eq(run.car_sprite.position.y - d.position.y, 0.0, 0.01, "centred under the drawn car")
	assert_eq(d.get_parent(), run.car_sprite.get_parent(), "in the car's view, so the same depth order")
	assert_lt(d.get_index(), run.car_sprite.get_index(), "under the car sprite")


func test_the_underglow_on_the_street_is_on_the_ground() -> void:
	var glow = _glow_at(Vector2(-81, -40), 0.0, false)
	_check_glow_at_height(glow, 0.0)


func test_the_underglow_on_a_rooftop_rises_with_the_car() -> void:
	var glow = _glow_at(Vector2(-27, -81), 6.0, false)
	_check_glow_at_height(glow, 6.0)
	assert_almost_eq(glow.car_height(), 6.0, 0.001)


func test_the_underglow_on_a_lower_roof_rises_with_the_car() -> void:
	var glow = _glow_at(Vector2(-70, -81), 3.0, false)
	_check_glow_at_height(glow, 3.0)


func test_the_underglow_in_the_air_rises_with_the_car() -> void:
	var glow = _glow_at(Vector2(0, -81), 4.0, true)
	_check_glow_at_height(glow, 4.0)


func test_the_underglow_damage_area_is_unchanged_at_height() -> void:
	var glow = _glow_at(Vector2(-27, -81), 6.0, false)
	var near: Node2D = preload("res://tests/fixtures/weapons/fake_enemy.gd").new()
	near.position = (run.car.model.get_position() + Vector2(1.0, 0.0)) * 16.0
	run.add_child(near)
	var far: Node2D = preload("res://tests/fixtures/weapons/fake_enemy.gd").new()
	far.position = (run.car.model.get_position() + Vector2(0, 20)) * 16.0
	run.add_child(far)
	assert_true(glow.is_inside(near))
	assert_false(glow.is_inside(far))


func test_the_wiper_on_a_rooftop_rises_with_the_car() -> void:
	_place(Vector2(-27, -81))
	run.minions.enabled = false
	assert_true(run.weapons.upgrade("wiper"))
	var w = run.weapons.wiper
	w.step(0.02)
	var d: Node2D = w.drawing
	var ground: Vector2 = run.ISO_TRANSFORM * (w.pivot_units() * 16.0)
	assert_almost_eq(d.position.y, ground.y - 6.0 * 16.0, 0.01, "lifted by the car's height")
