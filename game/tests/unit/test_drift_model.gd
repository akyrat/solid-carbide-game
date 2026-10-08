extends GutTest
## Checks the car's movement against the Unity prototype report
## (docs/drifting/unity-prototype-report.md, sections 4 to 6) and the numbers
## printed by `python tools/unity_drift_charts.py --summary`.

const CarModel := preload("res://scripts/driving/car_model.gd")

const DT := 0.02
const CRUISE := 11.0
const TOP := 27.5


func _new_car() -> Object:
	var m = CarModel.new()
	m.dt = DT
	return m


## A car driving straight along its nose (nose up, as at the start) at `speed`.
func _car_at(speed: float) -> Object:
	var m = _new_car()
	m.set_velocity(Vector2(cos(m.rotation), sin(m.rotation)) * speed)
	return m


## Steps until forward speed satisfies `done`; returns the step count (or -1).
func _steps_until(m: Object, w: bool, s: bool, steer: float, done: Callable, limit := 1000) -> int:
	for i in range(1, limit + 1):
		m.step(w, s, steer)
		if done.call(m.forward_speed()):
			return i
	return -1


func test_physics_step_is_50_per_second() -> void:
	assert_eq(Engine.physics_ticks_per_second, 50)


func test_w_from_standstill_gives_cruise_on_first_step() -> void:
	var m = _new_car()
	m.step(true, false, 0.0)
	assert_almost_eq(m.forward_speed(), CRUISE, 1e-9)
	assert_almost_eq(m.sideways_speed(), 0.0, 1e-9)


func test_top_speed_reached_69_steps_after_cruise() -> void:
	var m = _new_car()
	m.step(true, false, 0.0)
	var steps := _steps_until(m, true, false, 0.0, func(f: float) -> bool: return f >= TOP - 1e-9)
	assert_eq(steps, 69, "cruise to top speed takes 69 steps (1.38 s)")
	assert_almost_eq(m.forward_speed(), TOP, 1e-9)
	# W from rest: top speed at t = 1.40 s (summary: "W from rest reaches top at t=1.40 s").
	assert_almost_eq((steps + 1) * DT, 1.40, 1e-9)
	for i in 20:
		m.step(true, false, 0.0)
	assert_almost_eq(m.forward_speed(), TOP, 1e-9, "stays at top speed")


func test_coasting_from_top_speed_reaches_zero_in_3_3_s() -> void:
	var m = _car_at(TOP)
	var steps := _steps_until(m, false, false, 0.0, func(f: float) -> bool: return f == 0.0)
	# 27.5 / 8.25 = 3.333 s; the report rounds it to 3.3 s. Stepped: 167 steps = 3.34 s.
	assert_almost_eq(steps * DT, TOP / (TOP * 0.3), DT, "coast time %.2f s" % (steps * DT))
	assert_eq(steps, 167)
	# Straight-line coast: 0.165 per step.
	var m2 = _car_at(TOP)
	m2.step(false, false, 0.0)
	assert_almost_eq(m2.forward_speed(), TOP - 0.165, 1e-9)


func test_braking_from_top_speed_reaches_zero_in_2_3_s_then_snaps_to_reverse() -> void:
	var m = _car_at(TOP)
	var steps := _steps_until(m, false, true, 0.0, func(f: float) -> bool: return f <= 0.0)
	assert_almost_eq(steps * DT, 2.3, DT, "brake time %.2f s" % (steps * DT))
	assert_almost_eq(m.forward_speed(), 0.0, 1e-9)
	m.step(false, true, 0.0)
	assert_almost_eq(m.forward_speed(), -CRUISE, 1e-9, "snaps to -11 at zero")
	# Then climbs to -27.5, mirroring W.
	var back := _steps_until(m, false, true, 0.0, func(f: float) -> bool: return f <= -TOP + 1e-9)
	assert_eq(back, 69)


func test_w_while_reversing_snaps_to_cruise() -> void:
	var m = _new_car()
	for i in 120:
		m.step(false, true, 0.0)
	assert_almost_eq(m.forward_speed(), -TOP, 1e-9)
	m.step(true, false, 0.0)
	assert_almost_eq(m.forward_speed(), CRUISE, 1e-9)


func test_w_wins_over_s() -> void:
	var m = _new_car()
	m.step(true, true, 0.0)
	assert_almost_eq(m.forward_speed(), CRUISE, 1e-9)


func test_rotation_rate_at_standstill() -> void:
	var m = _new_car()
	var start: float = m.rotation
	for i in 50:
		m.step(false, false, 1.0)
	assert_almost_eq(rad_to_deg(start - m.rotation), 191.9, 1e-6, "A turns counter-clockwise on screen")
	assert_almost_eq(m.total_speed(), 0.0, 1e-12, "spins on the spot")


func test_rotation_rate_at_top_speed() -> void:
	var m = _car_at(TOP)
	var start: float = m.rotation
	for i in 50:
		m.step(true, false, -1.0)
	assert_almost_eq(rad_to_deg(m.rotation - start), 191.9, 1e-6, "D turns clockwise on screen")
	# Per step: 3.838 degrees.
	var before: float = m.rotation
	m.step(true, false, -1.0)
	assert_almost_eq(rad_to_deg(m.rotation - before), 3.838, 1e-9)


func test_velocity_lags_rotation_by_one_step() -> void:
	var m = _car_at(TOP)
	var heading_before := Vector2(cos(m.rotation), sin(m.rotation))
	m.step(true, false, 1.0)
	# The velocity is still built on the heading from the start of the step.
	assert_almost_eq(m.get_velocity().normalized().dot(heading_before), 1.0, 1e-9)
	assert_almost_eq(m.get_velocity().length(), TOP, 1e-9)


## W + A held from straight-line top speed (the report's drift run).
func _drift_run(steps: int) -> Array:
	var m = _car_at(TOP)
	var out := []
	for i in steps:
		m.step(true, false, 1.0)
		out.append({"t": (i + 1) * DT, "slip": absf(m.drift_angle_deg()), "total": m.total_speed(),
			"forward": m.forward_speed(), "sideways": absf(m.sideways_speed())})
	return out


func test_drift_angle_passes_45_degrees_at_0_28_s() -> void:
	var run := _drift_run(150)
	var t45 := -1.0
	var t60 := -1.0
	var t70 := -1.0
	for r in run:
		if t45 < 0.0 and r.slip >= 45.0:
			t45 = r.t
		if t60 < 0.0 and r.slip >= 60.0:
			t60 = r.t
		if t70 < 0.0 and r.slip >= 70.0:
			t70 = r.t
	assert_almost_eq(t45, 0.28, 0.04, "45 degrees at %.2f s" % t45)
	assert_almost_eq(t60, 0.38, 0.04, "60 degrees at %.2f s" % t60)
	assert_almost_eq(t70, 0.52, 0.04, "70 degrees at %.2f s" % t70)


func test_held_drift_settles_at_33_9_and_75_degrees() -> void:
	var run := _drift_run(150)
	var at3: Dictionary = run[149]
	assert_almost_eq(at3.t, 3.0, 1e-9)
	assert_almost_eq(at3.total, 33.9, 0.5, "total speed %.2f" % at3.total)
	assert_almost_eq(at3.slip, 75.0, 2.0, "drift angle %.1f" % at3.slip)
	# Tighter, against the chart script's own numbers (W+A from top, at 3 s).
	assert_almost_eq(at3.forward, 8.83, 0.01)
	assert_almost_eq(at3.sideways, 32.70, 0.01)
	assert_almost_eq(at3.total, 33.87, 0.01)
	assert_almost_eq(at3.slip, 74.9, 0.05)


func test_releasing_a_straightens_out_back_to_top_speed() -> void:
	var m = _car_at(TOP)
	for i in 150:
		m.step(true, false, 1.0)
	for i in 100:
		m.step(true, false, 0.0)
	# Summary: "2 s after releasing A (W held): slip 9.0 deg, forward 27.50".
	assert_almost_eq(absf(m.drift_angle_deg()), 9.0, 0.05)
	assert_almost_eq(m.forward_speed(), TOP, 1e-6)


func test_drift_amount_ramps_in_and_out() -> void:
	var m = _car_at(TOP)
	m.step(true, false, 1.0)
	assert_almost_eq(m.drift_amount, 0.24, 1e-9)
	for i in 4:
		m.step(true, false, 1.0)
	assert_almost_eq(m.drift_amount, 1.0, 1e-9, "full after 5 steps (0.08 s)")
	assert_true(m.is_drifting)
	var steps := 0
	while m.drift_amount > 0.0 and steps < 100:
		m.step(true, false, 0.0)
		steps += 1
	assert_almost_eq(steps, 17, 1, "gone after about 17 steps (0.33 s)")
	assert_false(m.is_drifting)


func test_steering_without_drive_is_not_drifting() -> void:
	var m = _new_car()
	m.step(false, false, 1.0)
	assert_false(m.is_drifting)
	assert_eq(m.drift_amount, 0.0)


func test_cruise_jump_signal() -> void:
	var m = _new_car()
	var got := []
	m.cruise_jump.connect(func(from_speed: float, just: bool) -> void: got.append([from_speed, just]))
	m.step(true, false, 0.0)
	assert_eq(got.size(), 1, "W from standstill jumps to cruise")
	assert_almost_eq(got[0][0], 0.0, 1e-9)
	assert_true(got[0][1], "W was just pressed")
	for i in 80:
		m.step(true, false, 0.0)
	assert_eq(got.size(), 1, "no jump while climbing or at top speed")
	for i in 120:
		m.step(false, true, 0.0)
	m.step(true, false, 0.0)
	assert_eq(got.size(), 2, "W while reversing jumps to cruise")
	assert_true(got[1][0] < 0.0)


func test_w_reaches_top_speed_at_every_heading() -> void:
	# Rounding guard (CarModel.CRUISE_EPSILON): at some headings the forward
	# speed reads back a hair under cruise and W would snap to cruise forever.
	for k in 400:
		var m = _new_car()
		m.rotation = k * 0.9137
		for i in 100:
			m.step(true, false, 0.0)
		assert_almost_eq(m.forward_speed(), TOP, 1e-6, "heading %d" % k)
		var r = _new_car()
		r.rotation = k * 0.9137
		for i in 100:
			r.step(false, true, 0.0)
		assert_almost_eq(r.forward_speed(), -TOP, 1e-6, "reverse, heading %d" % k)
