extends GutTest
## Task T-460: Rev Charge. With the power-up owned, W+S charges a boost that
## fires when S is released (power_ups.json's tier numbers); without it, W+S
## drives exactly as before. The placeholder effect shows while charging and
## boosting, and stops after.

const CarScript := preload("res://scripts/driving/car.gd")
const RevChargeScript := preload("res://scripts/driving/rev_charge.gd")
const EffectScript := preload("res://scripts/driving/rev_charge_effect.gd")

var _world: Node2D
var _data := PowerUpData.new()


func before_each() -> void:
	_world = Node2D.new()
	add_child_autofree(_world)


func _car(tier := 0) -> CharacterBody2D:
	var car: CharacterBody2D = CarScript.new()
	_world.add_child(car)
	car.set_physics_process(false)
	car.use_keyboard = false
	car.detect_tricks = false
	car.rev_charge.set_tier(tier)
	return car


func _steps(car, n: int, w: bool, s: bool, steer := 0.0) -> void:
	car.scripted_input = [w, s, steer]
	for i in n:
		car.physics_step()


func _secs(car, seconds: float) -> int:
	return int(round(seconds / car.model.dt))


## Drives up to top speed, then charges a full charge and releases S.
func _full_charge_and_release(car) -> void:
	_steps(car, 150, true, false)
	_steps(car, _secs(car, car.rev_charge.charge_seconds) + 2, true, true)
	_steps(car, 1, true, false)


func test_tier_numbers_come_from_power_ups_json() -> void:
	for tier in range(1, _data.max_tier("rev_charge") + 1):
		var rc = RevChargeScript.new()
		rc.set_tier(tier)
		var t: Dictionary = _data.at("rev_charge", tier)
		assert_almost_eq(rc.charge_seconds, float(t.charge_seconds), 1e-9, "tier %d" % tier)
		assert_almost_eq(rc.boost_speed_multiplier, float(t.boost_speed_multiplier), 1e-9)
		assert_almost_eq(rc.boost_seconds, float(t.boost_seconds), 1e-9)


func test_charging_fills_in_the_tiers_charge_time() -> void:
	for tier in range(1, _data.max_tier("rev_charge") + 1):
		var car := _car(tier)
		var need := _secs(car, car.rev_charge.charge_seconds)
		_steps(car, need - 2, true, true)
		assert_true(car.rev_charge.charging)
		assert_lt(car.rev_charge.charge_fraction(), 1.0, "tier %d not full yet" % tier)
		_steps(car, 3, true, true)
		assert_almost_eq(car.rev_charge.charge_fraction(), 1.0, 1e-9, "tier %d full" % tier)


func test_releasing_s_fires_a_boost_at_the_tiers_strength_and_length() -> void:
	for tier in range(1, _data.max_tier("rev_charge") + 1):
		var car := _car(tier)
		var fired := []
		car.rev_charge.fired.connect(func(f, sp, sec): fired.append([f, sp, sec]))
		_full_charge_and_release(car)
		assert_eq(fired.size(), 1, "tier %d fires once" % tier)
		var top: float = car.tuning.top_speed()
		var want: float = top * car.rev_charge.boost_speed_multiplier
		assert_almost_eq(fired[0][1], want, 1e-6, "tier %d boost speed" % tier)
		assert_almost_eq(fired[0][2], car.rev_charge.boost_seconds, 1e-9)
		assert_true(car.rev_charge.is_boosting())
		assert_almost_eq(car.model.forward_speed(), want, 0.3, "tier %d the car is at the boost speed" % tier)
		assert_gt(car.model.forward_speed(), top + 1.0, "faster than top speed")
		# The boost lasts boost_seconds, then the speed falls back towards top speed.
		_steps(car, _secs(car, car.rev_charge.boost_seconds) - 2, true, false)
		assert_true(car.rev_charge.is_boosting(), "tier %d still boosting" % tier)
		assert_almost_eq(car.model.forward_speed(), want, 0.3)
		_steps(car, 3, true, false)
		assert_false(car.rev_charge.is_boosting(), "tier %d boost over" % tier)
		_steps(car, 400, true, false)
		assert_almost_eq(car.model.forward_speed(), top, 0.05, "back to top speed")


func test_a_higher_tier_charges_faster_and_boosts_harder() -> void:
	var last_charge := INF
	var last_speed := 0.0
	var last_len := 0.0
	for tier in range(1, _data.max_tier("rev_charge") + 1):
		var rc = RevChargeScript.new()
		rc.set_tier(tier)
		assert_lt(rc.charge_seconds, last_charge, "tier %d charges faster" % tier)
		assert_gt(rc.boost_speed_multiplier, last_speed, "tier %d boosts harder" % tier)
		assert_gt(rc.boost_seconds, last_len, "tier %d boosts longer" % tier)
		last_charge = rc.charge_seconds
		last_speed = rc.boost_speed_multiplier
		last_len = rc.boost_seconds


func test_while_charging_the_car_slows_to_cruise_and_holds_there() -> void:
	var car := _car(1)
	_steps(car, 150, true, false)
	assert_almost_eq(car.model.forward_speed(), car.tuning.top_speed(), 0.05)
	_steps(car, 75, true, true)
	assert_almost_eq(car.model.forward_speed(), car.tuning.forward_speed, 0.05, "held at cruise")


func test_charging_still_drifts() -> void:
	var car := _car(1)
	_steps(car, 50, true, true, 1.0)
	assert_true(car.model.is_drifting)


func test_a_partial_charge_fires_a_partial_boost() -> void:
	var car := _car(1)
	var fired := []
	car.rev_charge.fired.connect(func(f, sp, sec): fired.append([f, sp, sec]))
	_steps(car, 150, true, false)
	var half := _secs(car, car.rev_charge.charge_seconds * 0.5)
	_steps(car, half, true, true)
	_steps(car, 1, true, false)
	assert_eq(fired.size(), 1)
	var f: float = fired[0][0]
	assert_almost_eq(f, 0.5, 0.02)
	var mult: float = 1.0 + (car.rev_charge.boost_speed_multiplier - 1.0) * f
	assert_almost_eq(fired[0][1], car.tuning.top_speed() * mult, 1e-6)
	assert_almost_eq(fired[0][2], car.rev_charge.boost_seconds * f, 1e-9)


func test_a_short_overlap_fires_nothing() -> void:
	var car := _car(4)
	var fired := []
	car.rev_charge.fired.connect(func(f, sp, sec): fired.append(f))
	_steps(car, 3, true, true)
	_steps(car, 1, true, false)
	assert_eq(fired.size(), 0)
	assert_false(car.rev_charge.is_boosting())


func test_letting_go_of_w_first_drops_the_charge() -> void:
	var car := _car(1)
	var fired := []
	car.rev_charge.fired.connect(func(f, sp, sec): fired.append(f))
	_steps(car, 100, true, true)
	_steps(car, 1, false, true)
	_steps(car, 1, false, false)
	assert_eq(fired.size(), 0)
	assert_false(car.rev_charge.charging)


func test_the_wreck_drops_the_charge_and_the_boost() -> void:
	var car := _car(2)
	_steps(car, 100, true, true)
	car.input_enabled = false
	_steps(car, 1, true, false)
	assert_false(car.rev_charge.charging)
	assert_false(car.rev_charge.is_boosting())
	car.input_enabled = true
	_full_charge_and_release(car)
	assert_true(car.rev_charge.is_boosting())
	car.input_enabled = false
	_steps(car, 1, true, false)
	assert_false(car.rev_charge.is_boosting(), "the wreck ends the boost")


func test_end_boost_on_a_hit_keeps_nothing_running() -> void:
	var car := _car(1)
	_full_charge_and_release(car)
	assert_true(car.rev_charge.is_boosting())
	car._end_drift_on_hit(5.0)
	assert_false(car.rev_charge.is_boosting())


func test_without_the_power_up_w_and_s_drive_exactly_as_before() -> void:
	# "Before" is the driving model alone (CarModel.step, which the car ran
	# before T-460 in an open world): the car without the power-up must match it
	# step for step, speed, heading, position and drift state, over a script of
	# W, W+S, W+S drifting, S and releases.
	var plain = preload("res://scripts/driving/car_model.gd").new()
	var unowned := _car(0)
	var owned := _car(1)
	plain.dt = unowned.model.dt
	plain.rotation = unowned.model.rotation
	var script := [[60, true, false, 0.0], [80, true, true, 0.0], [40, true, true, 1.0],
		[1, true, false, 0.0], [50, true, false, -1.0], [30, false, true, 0.0], [20, true, true, 0.0],
		[1, true, false, 0.0], [30, true, false, 0.0]]
	var differs := false
	var steps := 0
	for leg in script:
		for i in leg[0]:
			plain.step(leg[1], leg[2], leg[3])
			unowned.scripted_input = [leg[1], leg[2], leg[3]]
			unowned.physics_step()
			owned.scripted_input = [leg[1], leg[2], leg[3]]
			owned.physics_step()
			steps += 1
			assert_almost_eq(unowned.model.vx, plain.vx, 1e-9, "vx, step %d" % steps)
			assert_almost_eq(unowned.model.vy, plain.vy, 1e-9, "vy, step %d" % steps)
			assert_almost_eq(unowned.model.x, plain.x, 1e-9)
			assert_almost_eq(unowned.model.y, plain.y, 1e-9)
			assert_eq(unowned.model.rotation, plain.rotation)
			assert_eq(unowned.model.is_drifting, plain.is_drifting)
			if absf(owned.model.forward_speed() - plain.forward_speed()) > 0.5:
				differs = true
	assert_false(unowned.rev_charge.charging, "no charge without the power-up")
	assert_eq(unowned.rev_charge.boosts_fired, 0)
	assert_true(differs, "the owned car does drive differently over the same steps")


func test_w_and_s_without_the_power_up_match_the_model_with_w_alone() -> void:
	# Before T-460, W wins over S: the model alone with W+S, step for step.
	var car := _car(0)
	var model = preload("res://scripts/driving/car_model.gd").new()
	model.dt = car.model.dt
	model.rotation = car.model.rotation
	for i in 120:
		car.scripted_input = [true, true, 0.0]
		car.physics_step()
		model.step(true, true, 0.0)
	assert_almost_eq(car.model.forward_speed(), model.forward_speed(), 1e-9)
	assert_almost_eq(car.model.forward_speed(), car.tuning.top_speed(), 0.05, "W+S still climbs to top speed")


func test_the_effect_shows_while_charging_and_boosting_and_stops_after() -> void:
	var car := _car(1)
	var fx = EffectScript.new()
	_world.add_child(fx)
	fx.bind(car)
	assert_false(fx.is_showing(), "nothing before")
	_steps(car, 150, true, false)
	assert_false(fx.is_showing(), "W alone shows nothing")
	_steps(car, 10, true, true)
	assert_true(fx.charge_visible())
	assert_false(fx.boost_visible())
	var small: float = fx.glow_radius()
	_steps(car, 40, true, true)
	assert_gt(fx.glow_radius(), small, "the glow grows with the charge")
	_steps(car, _secs(car, car.rev_charge.charge_seconds), true, true)
	_steps(car, 1, true, false)
	assert_false(fx.charge_visible())
	assert_true(fx.boost_visible())
	assert_eq(fx.speed_lines().size(), fx.line_count)
	_steps(car, _secs(car, car.rev_charge.boost_seconds) + 2, true, false)
	assert_false(fx.is_showing(), "stops after the boost")
	assert_eq(fx.speed_lines().size(), 0)


func test_the_effect_picks_art_frames_by_charge_and_boost() -> void:
	var car := _car(1)
	var fx = EffectScript.new()
	_world.add_child(fx)
	fx.bind(car)
	assert_eq(fx.frame_now(), -1, "nothing shows before")
	_steps(car, 150, true, false)
	_steps(car, 10, true, true)
	assert_between(fx.frame_now(), 0, EffectScript.CHARGE_FRAMES - 1, "a charge step while charging")
	_steps(car, _secs(car, car.rev_charge.charge_seconds), true, true)
	assert_between(fx.frame_now(), EffectScript.CHARGE_FRAMES,
		EffectScript.CHARGE_FRAMES + EffectScript.PULSE_FRAMES - 1, "a pulse frame when full")
	_steps(car, 1, true, false)
	assert_gte(fx.frame_now(), EffectScript.CHARGE_FRAMES + EffectScript.PULSE_FRAMES, "a boost frame")
	_steps(car, _secs(car, car.rev_charge.boost_seconds) + 2, true, false)
	assert_eq(fx.frame_now(), -1, "nothing after the boost")
	assert_eq(EffectScript.SHEET.get_width(), EffectScript.CELL * (EffectScript.CHARGE_FRAMES
		+ EffectScript.PULSE_FRAMES + EffectScript.BOOST_FRAMES), "the sheet has every column")
	assert_eq(EffectScript.SHEET.get_height(), EffectScript.CELL * EffectScript.DIRECTIONS)


func test_the_effect_shows_nothing_without_the_power_up() -> void:
	var car := _car(0)
	var fx = EffectScript.new()
	_world.add_child(fx)
	fx.bind(car)
	_steps(car, 100, true, true)
	assert_false(fx.is_showing())


func test_the_run_gives_the_car_the_owned_tier_and_its_effect() -> void:
	var run: Node = preload("res://scenes/run/run.tscn").instantiate()
	add_child_autofree(run)
	assert_not_null(run.rev_charge_effect)
	assert_eq(run.car.rev_charge.tier, 0, "a new run owns none")
	run.state.grant_power_up("rev_charge")
	assert_eq(run.car.rev_charge.tier, 1)
	run.state.grant_power_up("rev_charge")
	assert_eq(run.car.rev_charge.tier, 2)
