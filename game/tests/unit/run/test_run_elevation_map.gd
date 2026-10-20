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


func test_the_camera_follows_the_car_at_street_level_on_a_rooftop() -> void:
	_place(Vector2(-27, -81))
	var at_ground: Vector2 = run.ISO_TRANSFORM * (Vector2(-27, -81) * 16.0)
	assert_almost_eq(run.camera.position.x, at_ground.x, 0.01)
	assert_almost_eq(run.camera.position.y, at_ground.y, 0.01)


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
