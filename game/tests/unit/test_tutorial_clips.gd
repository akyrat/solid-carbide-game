extends GutTest
## Task T-483: the tutorial clips' fixtures (tests/fixtures/tutorial_clip_*.tscn, tutorial_clip_demo.gd).
## The four scenes load with their script and a non-empty drive; the ramp clip's own ground
## (tests/fixtures/data/tutorial_ramp.json) is a valid ramp up to a short rooftop; and the real car,
## driven the way the ramp clip drives it (W held along the ramp, W + A held in the air), takes off
## from the ramp's top with more airtime than the airtime trick's minimum and turns at least 180
## degrees in the air.

const CarScript := preload("res://scripts/driving/car.gd")
const GroundHeightScript := preload("res://scripts/level/ground_height.gd")
const RAMP_DATA := "res://tests/fixtures/data/tutorial_ramp.json"
const CLIPS := ["drift", "long_drift", "alt_drift", "ramp_jump"]


func test_the_four_clip_scenes_load_with_a_drive() -> void:
	for clip in CLIPS:
		var scene: PackedScene = load("res://tests/fixtures/tutorial_clip_%s.tscn" % clip)
		assert_not_null(scene, clip)
		var node: Node = scene.instantiate()
		assert_eq(node.clip, clip)
		assert_gt(node.parts.size(), 0, clip)
		assert_gt(node.zoom, 0.0, clip)
		node.free()


func test_the_drift_clip_is_zoomed_out_against_the_runs_camera() -> void:
	var node: Node = load("res://tests/fixtures/tutorial_clip_drift.tscn").instantiate()
	assert_gt(node.zoom, 14.4 * 1.5)
	assert_true(node.fixed_camera, "the camera holds still so the path reads")
	node.free()


func test_the_ramp_ground_is_a_ramp_up_to_a_short_rooftop() -> void:
	var g = GroundHeightScript.from_file(RAMP_DATA)
	assert_eq(g.error, "")
	assert_eq(g.platforms.size(), 1)
	assert_eq(g.ramps.size(), 1)
	assert_eq(g.platforms[0].rect.size.x, 8.0)
	assert_eq(g.ramps[0].top_height, 3.0)


func test_the_ramp_drive_flies_and_spins_at_least_a_half_turn() -> void:
	var car = CarScript.new()
	add_child_autofree(car)
	var g = GroundHeightScript.from_file(RAMP_DATA)
	car.model.set_position(Vector2(48.0, 0.0))
	car.model.rotation = PI
	car._sync_from_model()
	car.ground = g
	car.use_keyboard = false
	car.scripted_input = [true, false, 0.0]
	var air_steps := 0
	var turned := 0.0
	var took_off_from_ramp := []
	car.height_model.took_off.connect(func(from_ramp: bool, _vz: float) -> void: took_off_from_ramp.append(from_ramp))
	var before: float = car.model.rotation
	for i in 600:
		if car.airborne:
			car.scripted_input = [true, false, 1.0]
		car.physics_step()
		if car.airborne:
			air_steps += 1
			turned += wrapf(car.model.rotation - before, -PI, PI)
		before = car.model.rotation
		if air_steps > 0 and not car.airborne:
			break
	assert_eq(took_off_from_ramp, [true], "one takeoff, off the ramp's top")
	assert_gt(air_steps * car.model.dt, car.tricks.airtime_min_seconds, "more airtime than the airtime trick needs")
	assert_gt(rad_to_deg(absf(turned)), 180.0, "a half turn or more in the air")
