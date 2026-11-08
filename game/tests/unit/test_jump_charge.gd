extends GutTest
## Task T-590 (a playtest; Drifting, Decisions, "A charged jump, for a playtest"): with the Jump
## power-up owned and the car on the ground, holding Space charges the hop linearly up to x1.5
## takeoff over 3 s, and the car hops when Space is let go. A tap hops at x1. Space in the air is
## unchanged; without Jump, Space on the ground changes nothing. The cue shows while charging.

const CarScript := preload("res://scripts/driving/car.gd")
const JumpScript := preload("res://scripts/driving/jump_power_up.gd")
const CueScript := preload("res://scripts/driving/jump_charge_cue.gd")

var _world: Node2D
var _data := PowerUpData.new()


func before_each() -> void:
	_world = Node2D.new()
	add_child_autofree(_world)


func _car(tier: int) -> CharacterBody2D:
	var car: CharacterBody2D = CarScript.new()
	_world.add_child(car)
	car.set_physics_process(false)
	car.use_keyboard = false
	car.jump.set_tier(tier)
	car.scripted_input = [false, false, 0.0]
	return car


## Presses Space, holds it on the ground for `steps` physics steps (0: a tap), then lets go.
func _charge_and_release(car, steps: int) -> void:
	car.press_jump()
	car.scripted_jump_held = steps > 0
	car.physics_step()
	for i in steps - 1:
		car.physics_step()
		assert_false(car.airborne, "still charging on the ground at step %d" % i)
	car.scripted_jump_held = false
	if steps > 0:
		car.physics_step()


func _steps_for(seconds: float) -> int:
	return int(round(seconds * float(Engine.physics_ticks_per_second)))


func test_the_charge_numbers_come_from_power_ups_json() -> void:
	var c: Dictionary = _data.jump_charge()
	assert_almost_eq(float(c.charge_seconds), 3.0, 1e-9, "the board's 3 s")
	assert_almost_eq(float(c.max_multiplier), 1.5, 1e-9, "the board's +50%")
	var j = JumpScript.new()
	j.set_tier(1)
	assert_almost_eq(j.charge_seconds, 3.0, 1e-9)
	assert_almost_eq(j.max_multiplier, 1.5, 1e-9)


func test_the_multiplier_is_linear_and_held_after_the_full_charge() -> void:
	var j = JumpScript.new()
	j.set_tier(1)
	assert_almost_eq(j.multiplier_for(0.0), 1.0, 1e-9)
	assert_almost_eq(j.multiplier_for(1.5), 1.25, 1e-9)
	assert_almost_eq(j.multiplier_for(3.0), 1.5, 1e-9)
	assert_almost_eq(j.multiplier_for(10.0), 1.5, 1e-9, "held at the top")


## Acceptance 1: 0, 1.5 and 3+ s held give x1, x1.25 and x1.5, the hop on release, at both tiers.
func test_held_0_1_5_and_3_plus_seconds_give_x1_x1_25_and_x1_5() -> void:
	for tier in [1, 2]:
		var base := float(_data.at("jump", tier).takeoff_speed)
		for c in [[0.0, 1.0], [1.5, 1.25], [3.0, 1.5], [4.5, 1.5]]:
			var car := _car(tier)
			var got: Array = []
			car.jump.jumped.connect(func(vz: float) -> void: got.append(vz))
			_charge_and_release(car, _steps_for(c[0]))
			assert_true(car.airborne, "tier %d, %s s: hopped on release" % [tier, c[0]])
			assert_eq(got.size(), 1)
			if got.size() == 1:
				assert_almost_eq(float(got[0]), base * float(c[1]), 1e-6,
						"tier %d, %s s: takeoff x%s" % [tier, c[0], c[1]])
			assert_almost_eq(car.jump.last_multiplier, float(c[1]), 1e-6)
			assert_eq(car.jump.hops, 1)


## No hop while Space is held on the ground: the car stays down until it is let go.
func test_no_hop_until_space_is_let_go() -> void:
	var car := _car(1)
	car.press_jump()
	car.scripted_jump_held = true
	for i in 300:
		car.physics_step()
		assert_false(car.airborne, "step %d" % i)
	assert_true(car.jump.charging)
	assert_almost_eq(car.jump.charge_fraction(), 1.0, 1e-9)
	assert_eq(car.jump.hops, 0)
	car.scripted_jump_held = false
	car.physics_step()
	assert_true(car.airborne)
	assert_false(car.jump.charging, "the charge is spent")


## A higher charge flies longer and higher (the takeoff is the height model's vertical speed).
func test_a_full_charge_flies_longer_than_a_tap() -> void:
	var results: Array = []
	for secs in [0.0, 3.0]:
		var car := _car(1)
		_charge_and_release(car, _steps_for(secs))
		var steps := 0
		var peak := 0.0
		while car.airborne and steps < 1000:
			car.physics_step()
			steps += 1
			peak = maxf(peak, car.height)
		results.append([steps, peak])
	assert_gt(float(results[1][0]), float(results[0][0]) * 1.4, "about 1.5 times the airtime")
	assert_gt(float(results[1][1]), float(results[0][1]) * 2.0, "about 2.25 times the peak")


## Space in the air is unchanged: a press there starts no charge, and holding it tilts.
func test_space_in_the_air_does_not_charge_and_still_tilts() -> void:
	var car := _car(1)
	car.press_jump()
	car.physics_step()  # a tap: in the air
	assert_true(car.airborne)
	car.press_jump()
	car.scripted_jump_held = true
	for i in 10:
		car.physics_step()
	assert_false(car.jump.charging, "no charge in the air")
	assert_true(car.tilt.holding, "held in the air: the tilt")
	assert_gt(car.tilt.step, 0)
	assert_eq(car.jump.hops, 1)


## Space held through the landing is not a press: no charge starts on the ground.
func test_space_held_through_the_landing_starts_no_charge() -> void:
	var car := _car(1)
	car.press_jump()
	car.physics_step()
	car.scripted_jump_held = true
	while car.airborne:
		car.physics_step()
	for i in 20:
		car.physics_step()
	assert_false(car.jump.charging)
	car.scripted_jump_held = false
	car.physics_step()
	assert_false(car.airborne, "letting go after a held landing is no hop")
	assert_eq(car.jump.hops, 1)


## Without Jump, Space held and let go on the ground does nothing.
func test_without_jump_held_space_does_nothing() -> void:
	var car := _car(0)
	car.press_jump()
	car.scripted_jump_held = true
	for i in 100:
		car.physics_step()
	car.scripted_jump_held = false
	car.physics_step()
	assert_false(car.airborne)
	assert_false(car.jump.charging)
	assert_eq(car.jump.hops, 0)


## The dead keys (input off) drop the charge: letting go is no hop.
func test_the_dead_keys_drop_the_charge() -> void:
	var car := _car(1)
	car.press_jump()
	car.scripted_jump_held = true
	for i in 50:
		car.physics_step()
	car.input_enabled = false
	car.physics_step()
	assert_false(car.jump.charging)
	assert_false(car.airborne)
	car.input_enabled = true
	car.scripted_jump_held = false
	car.physics_step()
	assert_false(car.airborne)
	assert_eq(car.jump.hops, 0)


## Acceptance 3: the cue shows while charging, fills with the charge, and is gone after the jump.
func test_the_cue_shows_while_charging_and_is_gone_after_the_jump() -> void:
	var car := _car(1)
	var cue = CueScript.new()
	_world.add_child(cue)
	cue.bind(car)
	assert_false(cue.showing, "nothing before Space")
	car.press_jump()
	car.scripted_jump_held = true
	car.physics_step()
	assert_true(cue.showing, "shown from the press")
	for i in _steps_for(1.5):
		car.physics_step()
	assert_true(cue.showing)
	assert_almost_eq(cue.fraction, 0.5, 0.02, "half full at 1.5 s")
	var r: Array = cue.bar_rects(Vector2.ZERO, cue.fraction)
	assert_almost_eq(r[1].size.x, float(cue.config.cue_width_px) * 0.5, 1.0)
	car.scripted_jump_held = false
	car.physics_step()
	assert_true(car.airborne)
	assert_false(cue.showing, "gone after the jump")
	assert_eq(cue.fraction, 0.0)


func test_the_cue_shows_nothing_without_jump() -> void:
	var car := _car(0)
	var cue = CueScript.new()
	_world.add_child(cue)
	cue.bind(car)
	car.press_jump()
	car.scripted_jump_held = true
	for i in 20:
		car.physics_step()
	assert_false(cue.showing)


func test_the_run_has_the_cue_bound_to_its_car() -> void:
	var run: Node = preload("res://scenes/run/run.tscn").instantiate()
	add_child_autofree(run)
	assert_not_null(run.jump_charge_cue)
	assert_eq(run.jump_charge_cue.car, run.car)
