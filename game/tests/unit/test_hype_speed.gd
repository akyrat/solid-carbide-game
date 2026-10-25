extends GutTest
## Task T-275: the higher the hype level, the faster the car. Top speed is the
## base plus combo.json's amount at each combo heat step (ComboHeat's own
## thresholds), eased in and out; the drift prototype is unchanged.

const CarModel := preload("res://scripts/driving/car_model.gd")
const CarTuningScript := preload("res://scripts/driving/car_tuning.gd")
const CarHeightScript := preload("res://scripts/driving/car_height.gd")
const RunScene := preload("res://scenes/run/run.tscn")
const PrototypeScene := preload("res://scenes/drift_prototype/drift_prototype.tscn")

var data := ComboData.new()


func test_the_data_has_a_rising_bonus_for_each_heat_step() -> void:
	assert_true(data.is_ok(), data.error)
	assert_eq(data.hype_speed_bonus(0), 0.0)
	var last := 0.0
	for step in range(1, ComboHeat.THRESHOLDS.size() + 1):
		assert_gt(data.hype_speed_bonus(step), last, "step %d" % step)
		last = data.hype_speed_bonus(step)
	assert_eq(data.hype_speed_bonus(9), last, "a step past the list takes the last")
	assert_gt(data.hype_speed_ease_per_second(), 0.0)


func test_top_speed_is_the_data_amount_above_the_base_at_each_step() -> void:
	var t = CarModel.new().tuning
	var base: float = t.top_speed()
	assert_almost_eq(base, 16.5, 1e-9, "no bonus: 11 x 1.5")
	for step in range(0, ComboHeat.THRESHOLDS.size() + 1):
		t.hype_speed_bonus = data.hype_speed_bonus(step)
		assert_almost_eq(t.top_speed(), base * (1.0 + data.hype_speed_bonus(step)), 1e-9, "step %d" % step)


func test_the_run_target_follows_the_combo_heat_thresholds() -> void:
	var s := RunState.new()
	add_child_autofree(s)
	s.start_run()
	var cases := {1.0: 0, 1.99: 0, 2.0: 1, 2.99: 1, 3.0: 2, 3.99: 2, 4.0: 3, 6.0: 3}
	for m in cases:
		s.combo = m
		assert_eq(s.hype_speed_target(), data.hype_speed_bonus(cases[m]), "x%s" % m)
		assert_eq(cases[m], ComboHeat.step_for(m))


func test_the_bonus_eases_up_and_back_down_without_a_jump() -> void:
	var s := RunState.new()
	add_child_autofree(s)
	s.start_run()
	var dt := 0.02
	var bonus := 0.0
	s.combo = 4.0
	var target := s.hype_speed_target()
	var first := s.eased_hype_speed(bonus, dt)
	assert_gt(first, 0.0)
	assert_almost_eq(first, data.hype_speed_ease_per_second() * dt, 1e-9, "one small step")
	var steps := 0
	while bonus < target and steps < 1000:
		bonus = s.eased_hype_speed(bonus, dt)
		steps += 1
	assert_eq(bonus, target, "arrives")
	assert_almost_eq(steps * dt, target / data.hype_speed_ease_per_second(), 0.05, "in target / ease seconds")
	s.combo = 1.0  # the combo drops
	steps = 0
	while bonus > 0.0 and steps < 1000:
		var next := s.eased_hype_speed(bonus, dt)
		assert_lt(bonus - next, 0.01, "no jolt")
		bonus = next
		steps += 1
	assert_eq(bonus, 0.0, "back to the base")


func test_the_run_raises_the_cars_top_speed_as_the_combo_heats_and_drops_it_back() -> void:
	var run = RunScene.instantiate()
	add_child_autofree(run)
	var base: float = run.car.tuning.top_speed()
	run.state.combo = 4.0
	for i in 200:
		run.car.physics_step()
	assert_almost_eq(run.car.tuning.top_speed(), base * (1.0 + data.hype_speed_bonus(3)), 1e-6)
	run.state.combo = 1.0
	for i in 200:
		run.car.physics_step()
	assert_almost_eq(run.car.tuning.top_speed(), base, 1e-6)


func test_acceleration_rises_with_top_speed_and_time_to_top_stays() -> void:
	var t = CarModel.new().tuning
	var base_ramp: float = t.ramp_delta(0.02)
	t.hype_speed_bonus = 0.25
	assert_almost_eq(t.ramp_delta(0.02), base_ramp * 1.25, 1e-9)
	assert_eq(t.time_to_top_speed, 2.3, "time to top speed is unchanged")


func test_the_drift_prototype_keeps_its_top_speed() -> void:
	var p = PrototypeScene.instantiate()
	add_child_autofree(p)
	for i in 100:
		p.car.physics_step()
	assert_eq(p.car.tuning.hype_speed_bonus, 0.0, "nothing sets it there")
	assert_almost_eq(p.car.tuning.top_speed(), 16.5, 1e-9)
	assert_false(CarTuningScript.default_values().has("hype_speed_bonus"), "not a slider")


## The farthest a jump off the tallest rooftop (height 6) goes at each step: top
## speed times the fall time (gravity 12: sqrt(2 x 6 / 12) = 1 s).
func test_the_jump_off_the_tallest_rooftop_at_each_step() -> void:
	var fall := sqrt(2.0 * 6.0 / CarHeightScript.GRAVITY)
	assert_almost_eq(fall, 1.0, 1e-9)
	var t = CarModel.new().tuning
	var base: float = t.top_speed() * fall
	var top_step := data.hype_speed_bonus(ComboHeat.THRESHOLDS.size())
	t.hype_speed_bonus = top_step
	var far: float = t.top_speed() * fall
	gut.p("jump off a height-6 rooftop: %.1f units base, %.1f units at the top step" % [base, far])
	assert_almost_eq(far, base * (1.0 + top_step), 1e-9)
