extends GutTest
## Task T-278: the side slip out of a drift (Drifting, Decisions, "A little
## side slip out of a drift"; car_model.gd, _exit_slip_turn). When a drift ends
## on the ground, the body keeps turning the drift's way for a moment (the
## tail keeps swinging out), so the car's sideways slide grows a little more
## than it did before; it fades to nothing on its own, counter-steer catches it
## faster, it never spins the car out, and it never applies in the air.
##
## These tests use the game's default tuning (the slip's proposed defaults:
## strength 0.35, 0.4 s, catch x4, full at 60 degrees) unless they say so.

const CarModel := preload("res://scripts/driving/car_model.gd")
const CarTuning := preload("res://scripts/driving/car_tuning.gd")
const PROTOTYPE := preload("res://scenes/drift_prototype/drift_prototype.tscn")

const DT := 0.02
const A := 1.0
const D := -1.0


func _car(slip_on := true) -> Object:
	var m = CarModel.new()
	m.dt = DT
	if not slip_on:
		m.tuning.exit_slip_turn = 0.0
	return m


## W held straight for 1 s (up to speed), then W + A for `drift_steps`.
func _drifted(drift_steps := 75, slip_on := true) -> Object:
	var m = _car(slip_on)
	for i in 50:
		m.step(true, false, 0.0)
	for i in drift_steps:
		m.step(true, false, A)
	return m


## The full slip at the defaults, degrees per second.
func _full_slip(m) -> float:
	return m.tuning.exit_slip_turn * m.tuning.turn_rate()


# --- The values -----------------------------------------------------------------------

func test_the_values_are_tuning_values_with_proposed_defaults() -> void:
	var t = CarTuning.new()
	assert_almost_eq(float(t.exit_slip_turn), 0.35, 1e-9)
	assert_almost_eq(float(t.exit_slip_seconds), 0.4, 1e-9)
	assert_almost_eq(float(t.exit_slip_catch), 4.0, 1e-9)
	assert_almost_eq(float(t.exit_slip_full_angle), 60.0, 1e-9)
	var keys := []
	for s in CarTuning.SLIP_SETTINGS:
		keys.append(s.key)
		assert_true(CarTuning.default_values().has(s.key), s.key)
		assert_true(float(t.get(s.key)) >= float(s.min) and float(t.get(s.key)) <= float(s.max), "%s default in its slider's range" % s.key)
	assert_eq(keys, ["exit_slip_turn", "exit_slip_seconds", "exit_slip_catch", "exit_slip_full_angle"])


func test_the_unity_car_has_no_slip_and_reset_puts_it_back() -> void:
	var t = CarTuning.new()
	t.reset_to_unity()
	assert_eq(float(t.exit_slip_turn), 0.0, "Unity: no slip")
	t.reset_to_defaults()
	assert_almost_eq(float(t.exit_slip_turn), 0.35, 1e-9)


# --- How a drift ends -----------------------------------------------------------------

func test_with_the_slip_off_the_body_stops_turning_the_moment_a_is_let_go() -> void:
	# How a drift ends without the slip (the Unity car, and the game before T-278).
	var m = _drifted(75, false)
	var before: float = m.rotation
	m.step(true, false, 0.0)
	assert_eq(m.rotation, before, "no turn after letting go")
	assert_eq(m.exit_slip, 0.0)


func test_after_a_full_drift_the_body_keeps_turning_and_the_slip_fades_to_none_in_0_4_s() -> void:
	var m = _drifted()
	assert_gt(absf(m.drift_angle_deg()), 60.0, "a full drift (%.1f deg)" % m.drift_angle_deg())
	var full := _full_slip(m)
	var before: float = m.rotation
	m.step(true, false, 0.0)
	assert_almost_eq(m.rotation - before, -deg_to_rad(full * DT), 1e-9, "first step: the full slip, the way A turns")
	var steps := 1
	while m.exit_slip != 0.0 and steps < 200:
		m.step(true, false, 0.0)
		steps += 1
	var expected := int(round(m.tuning.exit_slip_seconds / DT))
	assert_between(steps, expected - 1, expected + 1, "gone after %d steps (%.2f s)" % [steps, steps * DT])


func test_the_slip_keeps_a_little_more_sideways_speed_than_before() -> void:
	var on = _drifted()
	var off = _drifted(75, false)
	var extra_max := 0.0
	for i in 20:
		on.step(true, false, 0.0)
		off.step(true, false, 0.0)
		assert_true(absf(on.sideways_speed()) >= absf(off.sideways_speed()) - 1e-9, "step %d: at least as sideways" % i)
		extra_max = maxf(extra_max, absf(on.sideways_speed()) - absf(off.sideways_speed()))
	assert_gt(extra_max, 0.5, "a visible extra slide (%.2f units/s)" % extra_max)
	assert_lt(extra_max, 5.0, "but a small one (%.2f units/s)" % extra_max)


func test_the_extra_turn_is_small_and_matches_its_formula() -> void:
	var on = _drifted()
	var off = _drifted(75, false)
	for i in 60:
		on.step(true, false, 0.0)
		off.step(true, false, 0.0)
	var extra := rad_to_deg(absf(on.rotation - off.rotation))
	# Straight-line fade over 20 steps: full x (seconds + one step) / 2
	# = 67.2 x 0.42 / 2 = 14.1 degrees.
	var expected: float = _full_slip(on) * (on.tuning.exit_slip_seconds + DT) / 2.0
	assert_almost_eq(extra, expected, 0.01, "extra heading %.2f deg" % extra)
	assert_lt(extra, 22.5, "under one of the sprite's 16 directions")


func test_counter_steer_catches_it_faster() -> void:
	var m = _drifted()
	m.step(true, false, 0.0)  # the drift ends; the slip starts
	assert_gt(absf(m.exit_slip), 0.0)
	var steps := 0
	while m.exit_slip != 0.0 and steps < 200:
		m.step(true, false, D)  # a touch of counter-steer
		steps += 1
	var no_input := int(round(m.tuning.exit_slip_seconds / DT))
	assert_lt(steps, no_input / 2, "caught in %d steps, %d with no input" % [steps, no_input])
	assert_lte(steps, 6, "within about 0.1 s")


func test_letting_go_and_steering_back_the_same_way_ends_the_slip() -> void:
	var m = _drifted()
	m.step(true, false, 0.0)
	assert_gt(absf(m.exit_slip), 0.0)
	m.step(true, false, A)
	assert_eq(m.exit_slip, 0.0, "the player is turning that way anyway")


func test_no_spin_out_with_no_input() -> void:
	# W held, and coasting with no key at all; at the defaults and at the
	# sliders' strongest ends. The extra turn (against the same drift with the
	# slip off) stays within its bound: full slip x (seconds + one step) / 2.
	for strong in [false, true]:
		for hold_w in [true, false]:
			var on = _drifted()
			var off = _drifted(75, false)
			if strong:
				for s in CarTuning.SLIP_SETTINGS:
					if s.key in ["exit_slip_turn", "exit_slip_seconds"]:
						on.tuning.set(s.key, s.max)
			var release_angle := absf(on.drift_angle_deg())
			var peak := 0.0
			for i in 250:
				on.step(hold_w, false, 0.0)
				off.step(hold_w, false, 0.0)
				peak = maxf(peak, absf(on.drift_angle_deg()))
			var label := "strong %s, W %s" % [strong, hold_w]
			assert_eq(on.exit_slip, 0.0, "%s: the slip has ended" % label)
			var extra := rad_to_deg(absf(on.rotation - off.rotation))
			var bound: float = _full_slip(on) * (on.tuning.exit_slip_seconds + DT) / 2.0
			assert_lt(extra, bound + 0.01, "%s: extra turn %.1f within its bound %.1f" % [label, extra, bound])
			assert_lt(extra, 15.0 if not strong else 60.0, "%s: no spin (%.1f deg more)" % [label, extra])
			if hold_w:
				# Coasting, the car slows to a stop and its drift angle means
				# little; with W held it must stay a slide and straighten.
				assert_lt(peak, 90.0, "%s: never sideways past 90 deg (peak %.1f)" % [label, peak])
				assert_lt(peak, release_angle + (15.0 if strong else 5.0), "%s: barely more than at the release (%.1f, %.1f)" % [label, peak, release_angle])
				assert_lt(absf(on.drift_angle_deg()), 5.0, "%s: settled straight after 5 s" % label)


func test_small_steering_touches_barely_slip() -> void:
	var m = _drifted(3)  # a 0.06 s touch of A
	m.step(true, false, 0.0)
	assert_lt(absf(m.exit_slip), _full_slip(m) * 0.1, "touch slip %.1f deg/s" % absf(m.exit_slip))
	var half = _drifted(10)  # 0.2 s: about 34 degrees of drift angle
	half.step(true, false, 0.0)
	assert_between(absf(half.exit_slip), _full_slip(half) * 0.2, _full_slip(half) * 0.5)


func test_it_works_the_same_out_of_a_right_drift() -> void:
	var m = _car()
	for i in 50:
		m.step(true, false, 0.0)
	for i in 75:
		m.step(true, false, D)
	var before: float = m.rotation
	m.step(true, false, 0.0)
	assert_almost_eq(m.rotation - before, deg_to_rad(_full_slip(m) * DT), 1e-9, "the way D turns")
	assert_lt(m.exit_slip, 0.0)


func test_releasing_w_while_still_steering_has_no_slip() -> void:
	# The drift ends (no W) but A is still held, so the car is still turning:
	# no extra turn on top (this is also the alternate drift's switch).
	var m = _drifted()
	m.step(false, false, A)
	assert_false(m.is_drifting)
	assert_eq(m.exit_slip, 0.0)


func test_a_turn_that_was_straightening_the_car_never_slips() -> void:
	# Sliding to the car's right (as after a left drift), steering D with W
	# turns the nose back toward the travel: no tail swinging out to carry on.
	var m = _drifted()
	for i in 5:
		m.step(true, false, D)
	assert_gt(m.sideways_speed() * m.forward_speed(), 0.0, "still sliding the left drift's way")
	m.step(true, false, 0.0)
	assert_eq(m.exit_slip, 0.0)


# --- Not in the air -------------------------------------------------------------------

func test_a_drift_ending_in_the_air_has_no_slip() -> void:
	var m = _drifted()
	m.airborne = true
	var before: float = m.rotation
	m.step(true, false, 0.0)
	assert_eq(m.rotation, before, "in the air the body turns only with the keys")
	assert_eq(m.exit_slip, 0.0)
	m.airborne = false
	m.step(true, false, 0.0)
	assert_eq(m.exit_slip, 0.0, "no slip on landing either")


func test_a_slip_running_at_takeoff_stops_in_the_air() -> void:
	var m = _drifted()
	m.step(true, false, 0.0)
	assert_gt(absf(m.exit_slip), 0.0)
	m.airborne = true
	var before: float = m.rotation
	m.step(true, false, A)
	assert_eq(m.exit_slip, 0.0)
	assert_almost_eq(m.rotation - before, -deg_to_rad(m.tuning.turn_rate_for(true) * DT), 1e-9, "only the air turn")


# --- The tuning panel -----------------------------------------------------------------

func test_the_tuning_panel_has_a_slider_for_each_value() -> void:
	var p = PROTOTYPE.instantiate()
	add_child_autofree(p)
	var sl: Dictionary = p.panel.slip_sliders
	assert_eq(sl.size(), CarTuning.SLIP_SETTINGS.size())
	for s in CarTuning.SLIP_SETTINGS:
		assert_true(sl.has(s.key), s.key)
		var slider: HSlider = sl[s.key]
		assert_almost_eq(slider.value, float(p.car.tuning.get(s.key)), 1e-6, "%s starts at the game value" % s.key)
		assert_ne(slider.tooltip_text, "", "%s has a tooltip" % s.key)
	sl["exit_slip_turn"].value = 0.6
	assert_almost_eq(float(p.car.tuning.exit_slip_turn), 0.6, 1e-6, "applies live")
	p.panel.reset_to_defaults()
	assert_almost_eq(sl["exit_slip_turn"].value, 0.35, 1e-6, "reset puts it back")
	assert_almost_eq(float(p.car.tuning.exit_slip_turn), 0.35, 1e-6)


func test_the_prototype_car_slips_out_of_a_drift() -> void:
	var p = PROTOTYPE.instantiate()
	add_child_autofree(p)
	var car = p.car
	car.use_keyboard = false
	car.scripted_input = [true, false, 0.0]
	for i in 50:
		car.physics_step()
	car.scripted_input = [true, false, A]
	for i in 75:
		car.physics_step()
	car.scripted_input = [true, false, 0.0]
	var before: float = car.model.rotation
	car.physics_step()
	assert_lt(car.model.rotation - before, 0.0, "still turning A's way after letting go")
	assert_gt(absf(car.model.exit_slip), 0.0)
