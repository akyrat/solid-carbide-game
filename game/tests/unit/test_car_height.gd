extends GutTest
## Task T-183: the car's real height (car_height.gd) stepped by car.gd over the
## elevation test scene's ground (data/level/elevation_test.json): following the
## ground up the ramp, taking off at the ramp's top and off a drop-off edge,
## gravity in the air and landing. The flat driving must not change.
##
## The test data's proposals: platform 16 x 16 at (-8, -8), height 3; ramp on
## its east side, 12 x 8 at (8, -4), 0 at x = 20 up to 3 at x = 8.

const CarScript := preload("res://scripts/driving/car.gd")
const CarHeight := preload("res://scripts/driving/car_height.gd")
const GroundHeightScript := preload("res://scripts/level/ground_height.gd")
const EPS := 1e-6

var _world: Node2D
var _ground


func before_each() -> void:
	_world = Node2D.new()
	add_child_autofree(_world)
	_ground = GroundHeightScript.from_file()


## A car at start (units) facing rotation, driven by scripted input, W held.
func _car(start: Vector2, rotation: float, with_ground: bool = true) -> CharacterBody2D:
	var car: CharacterBody2D = CarScript.new()
	car.model.set_position(start)
	car.model.rotation = rotation
	_world.add_child(car)
	car.set_physics_process(false)
	car.use_keyboard = false
	car.detect_tricks = false
	car.scripted_input = [true, false, 0.0]
	if with_ground:
		car.ground = _ground
	return car


func test_data_is_the_expected_scene() -> void:
	assert_eq(_ground.platforms.size(), 1)
	assert_eq(_ground.ramps.size(), 1)
	assert_almost_eq(_ground.height_at(Vector2(0, 0)), 3.0, EPS)
	assert_eq(str(_ground.ramps[0].side), "east")


func test_no_ground_source_height_stays_zero() -> void:
	var car := _car(Vector2(19, 0), PI, false)
	assert_null(car.ground)
	for i in 120:
		car.physics_step()
		assert_eq(car.height, 0.0)
		assert_eq(car.vertical_speed, 0.0)
		assert_false(car.airborne)


func test_height_and_vertical_speed_are_separate_from_flat_position() -> void:
	var car := _car(Vector2(0, 0), -PI / 2.0)
	assert_almost_eq(car.height, 3.0, EPS, "placed on the platform: its height")
	assert_eq(car.model.get_position(), Vector2(0, 0), "flat position untouched")
	assert_eq(car.vertical_speed, 0.0)


func test_up_the_ramp_height_follows_the_ground_each_step() -> void:
	var car := _car(Vector2(19.5, 0), PI)
	var steps_on_ramp := 0
	for i in 200:
		var before: Vector2 = car.model.get_position()
		car.physics_step()
		var pos: Vector2 = car.model.get_position()
		if not _ground.is_ramp(pos):
			break
		assert_false(car.airborne, "on the ramp at step %d" % i)
		assert_almost_eq(car.height, _ground.height_at(pos), EPS, "step %d" % i)
		assert_true(pos.x < before.x, "driving west, up the ramp")
		steps_on_ramp += 1
	assert_gt(steps_on_ramp, 10, "the car drove a while up the ramp")


func test_takeoff_at_ramp_top_matches_formula() -> void:
	var car := _car(Vector2(19.5, 0), PI)
	var took := []
	car.height_model.took_off.connect(func(from_ramp, vz): took.append([from_ramp, vz]))
	var r: Dictionary = _ground.ramps[0]
	for i in 200:
		var before: Vector2 = car.model.get_position()
		var h_before: float = car.height
		car.physics_step()
		if car.airborne:
			assert_true(_ground.is_ramp(before), "it left from the ramp")
			assert_false(_ground.is_ramp(car.model.get_position()), "past the ramp's top")
			var v: Vector2 = car.model.get_velocity()
			assert_gte(v.length(), CarHeight.RAMP_TAKEOFF_MIN_SPEED)
			# README formula: speed towards the top x rise / ramp length x factor.
			var expected := -v.x * (3.0 - 0.0) / 12.0 * CarHeight.RAMP_TAKEOFF_FACTOR
			assert_almost_eq(car.vertical_speed, expected, EPS)
			assert_almost_eq(CarHeight.ramp_vertical_speed(r, v), -v.x * 0.25, EPS)
			assert_almost_eq(car.height, h_before + expected * car.model.dt, EPS)
			assert_gt(car.height, 3.0, "above the platform")
			assert_eq(took.size(), 1)
			assert_true(took[0][0], "from the ramp")
			return
	fail_test("never left the ground at the ramp's top")


func test_slow_car_at_ramp_top_follows_the_ground() -> void:
	var h = CarHeight.new()
	h.ground = _ground
	h.reset(Vector2(8.1, 0))
	var v := Vector2(-(CarHeight.RAMP_TAKEOFF_MIN_SPEED - 1.0), 0)
	h.step(Vector2(8.1, 0), Vector2(8.1, 0) + v * 0.02 * 10.0, v, 0.02)
	assert_false(h.airborne)
	assert_almost_eq(h.height, 3.0, EPS)


func test_drop_off_edge_takes_off_and_falls() -> void:
	# On the platform, nose north (-y), towards the north drop-off at y = -8.
	var car := _car(Vector2(0, -4), -PI / 2.0)
	var took := []
	car.height_model.took_off.connect(func(from_ramp, vz): took.append([from_ramp, vz]))
	for i in 100:
		car.physics_step()
		if car.airborne:
			assert_lt(car.model.get_position().y, -8.0, "past the edge")
			assert_eq(car.vertical_speed, 0.0, "flat platform: no upward speed")
			assert_almost_eq(car.height, 3.0, EPS)
			assert_eq(took, [[false, 0.0]])
			return
		assert_almost_eq(car.height, 3.0, EPS)
	fail_test("never left the drop-off edge")


func test_in_the_air_height_follows_gravity() -> void:
	var car := _car(Vector2(19.5, 0), PI)
	var guard := 0
	while not car.airborne and guard < 200:
		car.physics_step()
		guard += 1
	assert_true(car.airborne)
	var dt: float = car.model.dt
	var air_steps := 0
	while car.airborne and guard < 600:
		var vz0: float = car.vertical_speed
		var h0: float = car.height
		car.physics_step()
		guard += 1
		if not car.airborne:
			break
		assert_almost_eq(car.vertical_speed, vz0 - CarHeight.GRAVITY * dt, EPS)
		assert_almost_eq(car.height, h0 + car.vertical_speed * dt, EPS)
		air_steps += 1
	assert_gt(air_steps, 3, "a few steps in the air")


func test_lands_when_height_reaches_ground() -> void:
	var car := _car(Vector2(0, -4), -PI / 2.0)
	var landings := []
	car.height_model.landed.connect(func(vz): landings.append(vz))
	var was_air := false
	for i in 300:
		var h0: float = car.height
		var vz0: float = car.vertical_speed
		car.physics_step()
		if car.airborne:
			was_air = true
		elif was_air:
			var pos: Vector2 = car.model.get_position()
			var at: float = _ground.height_at(pos)
			assert_almost_eq(at, 0.0, EPS, "fell to the street")
			assert_true(h0 + (vz0 - CarHeight.GRAVITY * car.model.dt) * car.model.dt <= at,
				"it reached the ground this step")
			assert_eq(car.vertical_speed, 0.0)
			assert_almost_eq(car.height, at, EPS)
			assert_eq(landings.size(), 1)
			assert_lt(landings[0], 0.0, "it was falling")
			return
	fail_test("never landed")


func test_ramp_jump_lands_on_platform() -> void:
	var car := _car(Vector2(19.5, 0), PI)
	var was_air := false
	for i in 300:
		car.physics_step()
		if car.airborne:
			was_air = true
		elif was_air:
			assert_almost_eq(car.height, 3.0, EPS, "landed on the platform")
			assert_eq(car.vertical_speed, 0.0)
			return
	fail_test("never landed")


func test_flat_driving_unchanged_by_height() -> void:
	var with_h := _car(Vector2(19.5, 0.3), PI, true)
	var without := _car(Vector2(19.5, 0.3), PI, false)
	# Task T-219 (board, 2026-10-21, "no drifting in the air"): in the air the
	# car keeps its takeoff velocity and only spins, on purpose, so the flat
	# driving is compared while the car with height is on the ground: up to
	# its first takeoff. The air is tested in test_air_tricks.gd.
	var inputs := [[true, false, 0.0], [true, false, 0.4], [true, false, -1.0], [false, true, 0.0]]
	var compared := 0
	for i in 240:
		var inp: Array = inputs[(i / 30) % inputs.size()]
		with_h.scripted_input = inp
		without.scripted_input = inp
		with_h.physics_step()
		without.physics_step()
		if with_h.airborne:
			break
		compared += 1
		assert_eq(with_h.model.get_position(), without.model.get_position(), "step %d" % i)
		assert_eq(with_h.model.get_velocity(), without.model.get_velocity(), "step %d" % i)
		assert_eq(with_h.model.rotation, without.model.rotation, "step %d" % i)
	assert_gt(compared, 20, "compared on the ground, up the ramp")
