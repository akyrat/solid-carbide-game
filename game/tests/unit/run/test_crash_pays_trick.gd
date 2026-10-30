extends GutTest
## Task T-315: a crash that breaks the combo still pays the trick in progress
## (Game loop architecture, Decisions, "A crash pays the trick in progress").
## A drift cut by a crash pays its extended_drift for the time it lasted, with
## its LONG DRIFT! popup, before the combo is cut (combo.json's
## crash_pays_trick_first, the board's approved order; false swaps it). In the
## air, the aerial spins and the airtime so far pay the same way. A drift that
## ends normally, and a crash with no trick in progress, behave as before.

const CarModel := preload("res://scripts/driving/car_model.gd")
const TrickDetector := preload("res://scripts/driving/trick_detector.gd")
const CarScript := preload("res://scripts/driving/car.gd")
const RunScene := preload("res://scenes/run/run.tscn")
const U := 16.0
const A := 1.0

var combo_data := ComboData.new()

# Detector tests.
var _model
var _det
var _tricks: Array = []
var _airtimes: Array = []

# Run scene tests: the run's popups' order, "trick:<id>" or "broken".
var _events: Array = []
var _drift_seconds: Array = []


func before_each() -> void:
	_model = CarModel.new()
	_det = TrickDetector.new()
	_tricks = []
	_airtimes = []
	_det.trick.connect(func(id: String) -> void: _tricks.append([id, _det.last_trick_seconds]))
	_det.airtime_trick.connect(func(s: float) -> void: _airtimes.append(s))
	_events = []
	_drift_seconds = []


func _hold(seconds: float, w: bool, s: bool, steer: float) -> void:
	for i in roundi(seconds * 50.0):
		var before: float = _model.rotation
		_model.step(w, s, steer)
		_det.observe(_model, w, s, steer, before)


func _drifts() -> Array:
	return _tricks.filter(func(t: Array) -> bool: return t[0] == "extended_drift")


# --- The trick detector's settle() ------------------------------------------------------

func test_settle_pays_the_drift_so_far_and_the_rest_is_a_new_drift() -> void:
	_hold(1.5, true, false, A)
	assert_eq(_drifts().size(), 0, "nothing while the drift lasts")
	_det.settle()
	assert_eq(_drifts().size(), 1, "the crash pays the drift so far")
	assert_almost_eq(_drifts()[0][1], 1.5, 0.021, "for the time it lasted")
	_hold(1.2, true, false, A)  # still drifting after the crash
	_hold(0.02, false, false, 0.0)  # let go
	assert_eq(_drifts().size(), 2, "the rest of the drift pays at its end")
	assert_almost_eq(_drifts()[1][1], 1.2, 0.021, "only the time after the crash")


func test_settle_with_no_drift_does_nothing() -> void:
	_hold(1.0, true, false, 0.0)  # W alone: no drift
	_det.settle()
	assert_eq(_tricks.size(), 0)
	assert_eq(_airtimes.size(), 0)


func test_settle_leaves_a_drift_too_short_to_pay_alone() -> void:
	_hold(0.6, true, false, A)
	_det.settle()
	assert_eq(_tricks.size(), 0, "under min_seconds nothing pays")
	_hold(0.6, true, false, A)
	_hold(0.02, false, false, 0.0)
	assert_eq(_drifts().size(), 1, "the drift goes on as before")
	assert_almost_eq(_drifts()[0][1], 1.2, 0.021, "its whole length, as before T-315")


func test_settle_does_not_pay_a_partial_360_or_an_alternate_drift() -> void:
	_hold(1.5, true, false, A)  # about 290 degrees
	_det.settle()
	assert_eq(_tricks.map(func(t: Array) -> String: return t[0]), ["extended_drift"],
			"a 360 under way is not a trick yet")


func test_a_drift_that_ends_normally_pays_as_before() -> void:
	_hold(2.0, true, false, A)
	_hold(0.02, false, false, 0.0)
	assert_eq(_drifts().size(), 1)
	assert_almost_eq(_drifts()[0][1], 2.0, 0.021)


func test_settle_in_the_air_pays_the_spins_and_airtime_so_far() -> void:
	# 0.5 s in the air turning 200 degrees: an air 180 and 0.5 s of airtime.
	for i in 25:
		_det.observe_air(true, deg_to_rad(8.0), 0.02)
	_det.settle()
	assert_eq(_tricks.map(func(t: Array) -> String: return t[0]), ["air_one_eighty"])
	assert_eq(_airtimes.size(), 1)
	assert_almost_eq(_airtimes[0], 0.5, 0.0001)
	# Still in the air: the rest counts from the crash and pays on landing.
	for i in 10:
		_det.observe_air(true, 0.0, 0.02)
	_det.observe_air(false, 0.0, 0.02)
	assert_eq(_airtimes.size(), 2)
	assert_almost_eq(_airtimes[1], 0.2, 0.0001, "only the airtime after the crash")
	assert_eq(_tricks.size(), 1, "the spin was paid once")


func test_settle_in_a_short_airtime_without_a_spin_does_nothing() -> void:
	for i in 5:  # 0.1 s, under airtime.min_seconds
		_det.observe_air(true, 0.0, 0.02)
	_det.settle()
	assert_eq(_airtimes.size(), 0)
	for i in 20:
		_det.observe_air(true, 0.0, 0.02)
	_det.observe_air(false, 0.0, 0.02)
	assert_eq(_airtimes.size(), 1)
	assert_almost_eq(_airtimes[0], 0.5, 0.0001, "the whole airtime, as before")


func test_the_data_has_the_order_switch() -> void:
	assert_true(combo_data.crash_pays_trick_first(), "the board's order: the trick pays first")
	assert_almost_eq(combo_data.airtime_min_seconds(), 0.3, 0.0001)


# --- In a run --------------------------------------------------------------------------

func _run() -> Node2D:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	var car = run.car
	car.set_physics_process(false)
	car.use_keyboard = false
	var s: RunState = run.state
	s.combo_trick.connect(func(id: String, _a: float, _m: float) -> void:
		_events.append("trick:" + id)
		if id == "extended_drift":
			_drift_seconds.append(car.tricks.last_trick_seconds))
	s.combo_broken.connect(func() -> void: _events.append("broken"))
	return run


func _steps(run: Node2D, seconds: float, input: Array) -> void:
	run.car.scripted_input = input
	for i in roundi(seconds * 50.0):
		run.car.physics_step()


## Gives the run a combo of 3.0 first, so the cut is plain to see.
func _build_combo(run: Node2D) -> float:
	for i in 4:
		run.state.add_trick("alternate_drift")
	_events.clear()
	return run.state.combo


## A real obstacle across the car's path, two units ahead along its velocity.
func _obstacle_ahead(run: Node2D, boulder: bool) -> void:
	var car = run.car
	var dir: Vector2 = car.model.get_velocity().normalized()
	var body := StaticBody2D.new()
	body.collision_layer = CarScript.LAYER_OBSTACLES
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	if boulder:
		var circle := CircleShape2D.new()
		circle.radius = 1.5 * U
		cs.shape = circle
		body.position = (car.model.get_position() + dir * 2.5) * U
	else:
		var rect := RectangleShape2D.new()
		rect.size = Vector2(1.0, 12.0) * U
		cs.shape = rect
		body.position = (car.model.get_position() + dir * 2.0) * U
		body.rotation = dir.angle()
	body.add_child(cs)
	run.physics_world.add_child(body)


func _drive_into(run: Node2D, max_steps: int) -> bool:
	var hits := [0]
	run.car.hit_obstacle.connect(func(_c, _i, _n, _s) -> void: hits[0] += 1)
	run.car.scripted_input = [true, false, A]
	for i in max_steps:
		run.car.physics_step()
		if hits[0] > 0:
			return true
	return false


func _check_drift_then_crash(run: Node2D, c0: float) -> void:
	assert_eq(_events.slice(0, 2), ["trick:extended_drift", "broken"],
			"LONG DRIFT! pays first, then COMBO BROKEN!")
	assert_eq(_drift_seconds.size(), 1)
	var seconds: float = _drift_seconds[0]
	assert_between(seconds, 1.5, 2.3, "the drift's time up to the crash")
	var expected := combo_data.after_collision(c0 + combo_data.drift_amount(seconds))
	assert_almost_eq(run.state.combo, expected, 0.000001, "paid, then cut by 50%")


func test_a_wall_hit_during_a_drift_pays_it_before_the_cut() -> void:
	var run := _run()
	var c0 := _build_combo(run)
	_steps(run, 1.5, [true, false, A])
	_obstacle_ahead(run, false)
	await wait_physics_frames(2)  # the new body joins the physics space
	assert_true(_drive_into(run, 40), "the car hit the wall")
	_check_drift_then_crash(run, c0)


func test_a_boulder_hit_during_a_drift_pays_it_before_the_cut() -> void:
	var run := _run()
	var c0 := _build_combo(run)
	_steps(run, 1.5, [true, false, A])
	_obstacle_ahead(run, true)
	await wait_physics_frames(2)
	assert_true(_drive_into(run, 40), "the car hit the boulder")
	_check_drift_then_crash(run, c0)


func test_an_enemy_hit_during_a_drift_pays_it_before_the_cut() -> void:
	var run := _run()
	var c0 := _build_combo(run)
	_steps(run, 1.5, [true, false, A])
	run.state.damage_car(1.0)  # what minions, the kaiju and meteors call
	assert_eq(_events, ["trick:extended_drift", "broken"])
	assert_almost_eq(_drift_seconds[0], 1.5, 0.021)
	assert_almost_eq(run.state.combo,
			combo_data.after_collision(c0 + combo_data.drift_amount(_drift_seconds[0])), 0.000001)


func test_the_rest_of_the_drift_after_the_crash_pays_on_its_own() -> void:
	var run := _run()
	_steps(run, 1.5, [true, false, A])
	run.car.hit_obstacle.emit(autofree(StaticBody2D.new()), 0, Vector2.UP, 10.0)
	_steps(run, 1.1, [true, false, A])
	_steps(run, 0.04, [false, false, 0.0])
	assert_eq(_drift_seconds.size(), 2)
	assert_almost_eq(_drift_seconds[0], 1.5, 0.021)
	assert_almost_eq(_drift_seconds[1], 1.1, 0.021, "not the whole drift again")


func test_a_drift_with_no_combo_still_pays_then_breaks() -> void:
	var run := _run()
	_steps(run, 1.8, [true, false, A])  # under a full 360
	run.car.hit_obstacle.emit(autofree(StaticBody2D.new()), 0, Vector2.UP, 10.0)
	assert_eq(_events, ["trick:extended_drift", "broken"],
			"the drift raised the combo, so the crash breaks it")
	assert_almost_eq(run.state.combo,
			combo_data.after_collision(1.0 + combo_data.drift_amount(_drift_seconds[0])), 0.000001)


func test_the_other_order_cuts_first_then_pays() -> void:
	var run := _run()
	run.state._combo_data._data["crash_pays_trick_first"] = false
	var c0 := _build_combo(run)
	_steps(run, 1.5, [true, false, A])
	run.car.hit_obstacle.emit(autofree(StaticBody2D.new()), 0, Vector2.UP, 10.0)
	assert_eq(_events, ["broken", "trick:extended_drift"])
	assert_almost_eq(run.state.combo,
			combo_data.after_collision(c0) + combo_data.drift_amount(_drift_seconds[0]), 0.000001)


func test_a_crash_with_no_trick_in_progress_is_as_before() -> void:
	var run := _run()
	var c0 := _build_combo(run)
	_steps(run, 0.5, [true, false, 0.0])  # W alone: no drift
	run.car.hit_obstacle.emit(autofree(StaticBody2D.new()), 0, Vector2.UP, 10.0)
	assert_eq(_events, ["broken"])
	assert_almost_eq(run.state.combo, combo_data.after_collision(c0), 0.000001)
	run.state.advance(0.6)  # T-415: past the combo's collision window
	run.state.damage_car(1.0)
	assert_eq(_events, ["broken", "broken"])


func test_a_drift_that_ends_normally_in_a_run_pays_as_before() -> void:
	var run := _run()
	_steps(run, 1.6, [true, false, A])
	_steps(run, 0.04, [false, false, 0.0])
	assert_eq(_events, ["trick:extended_drift"])
	assert_almost_eq(_drift_seconds[0], 1.6, 0.021)
	assert_almost_eq(run.state.combo, 1.0 + combo_data.drift_amount(_drift_seconds[0]), 0.000001)


func test_the_drift_xp_is_unchanged_by_the_crash() -> void:
	var run := _run()
	_steps(run, 1.5, [true, false, A])
	var xp: float = run.state.xp
	run.state.collision()
	assert_eq(run.state.xp, xp, "the crash itself gives no XP: drift seconds pay XP as they pass")
