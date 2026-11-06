extends GutTest
## Task T-536: the reverse drift and the aura tricks (Drifting, Decisions, "A
## reverse drift trick" and "An aura trick"; proposals in combo.json). The
## detector runs on the driving model directly, 50 steps per second, like
## test_tricks.gd; the car node, the run state, the popups and the recap
## texts are checked at the end.

const CarModel := preload("res://scripts/driving/car_model.gd")
const TrickDetector := preload("res://scripts/driving/trick_detector.gd")
const CarScript := preload("res://scripts/driving/car.gd")
const RunStateScript := preload("res://scripts/run/run_state.gd")
const TrickPopupsScript := preload("res://scripts/hud/trick_popups.gd")

const A := 1.0
const D := -1.0
const STEPS_PER_SECOND := 50

var _model
var _det
var _tricks: Array = []


func before_each() -> void:
	_model = CarModel.new()
	_det = TrickDetector.new()
	_tricks = []
	_det.trick.connect(func(id: String) -> void: _tricks.append(id))


func _run(steps: int, w: bool, s: bool, steer: float, airborne := false) -> void:
	for i in steps:
		var before: float = _model.rotation
		_model.step(w, s, steer)
		_det.observe(_model, w, s, steer, before, airborne)


func _hold(seconds: float, w: bool, s: bool, steer: float) -> void:
	_run(roundi(seconds * STEPS_PER_SECOND), w, s, steer)


func _count(id: String) -> int:
	return _tricks.count(id)


# --- Data ------------------------------------------------------------------------------

func test_ids_and_numbers_come_from_combo_json() -> void:
	assert_true(TrickDetector.TRICK_IDS.has("reverse_drift"))
	assert_true(TrickDetector.TRICK_IDS.has("aura"))
	var c := ComboData.new()
	assert_eq(c.reverse_drift_min_seconds(), float(c._data["reverse_drift"]["min_seconds"]))
	assert_eq(c.aura_still_speed(), float(c._data["aura"]["still_speed"]))
	assert_eq(c.aura_wait_seconds(), 5.0, "the board's 5 s")
	assert_eq(c.aura_every_seconds(), 1.0, "the board's every second")
	assert_eq(_det.reverse_drift_min_seconds, c.reverse_drift_min_seconds())
	assert_eq(_det.aura_still_speed, c.aura_still_speed())
	assert_gt(c.trick_add("reverse_drift"), 0.0)
	assert_gt(c.trick_add("aura"), 0.0)
	assert_gt(c.trick_subs("reverse_drift"), 0.0)
	assert_gt(c.trick_subs("aura"), 0.0)


# --- Reverse drift ---------------------------------------------------------------------

func test_a_reverse_drift_pays_once_when_it_reaches_the_minimum() -> void:
	var need := roundi(_det.reverse_drift_min_seconds * STEPS_PER_SECOND)
	for steer in [A, D]:
		before_each()
		_run(need - 1, false, true, steer)
		assert_lt(_model.forward_speed(), 0.0, "moving backwards")
		assert_eq(_count("reverse_drift"), 0, "not before the minimum")
		_run(1, false, true, steer)
		assert_eq(_count("reverse_drift"), 1, "at the minimum")
		_hold(4.0, false, true, steer)
		assert_eq(_count("reverse_drift"), 1, "once per unbroken reverse drift")


func test_a_forward_drift_never_pays_it() -> void:
	_hold(4.0, true, false, A)
	_hold(4.0, true, false, D)
	_hold(2.0, true, true, A)  # W and S: W wins, a forward drift
	assert_eq(_count("reverse_drift"), 0)


func test_reversing_straight_does_not_pay() -> void:
	_hold(3.0, false, true, 0.0)
	assert_eq(_count("reverse_drift"), 0)


func test_too_short_does_not_pay_and_a_break_starts_again() -> void:
	_hold(0.8, false, true, A)
	_hold(0.1, false, true, 0.0)  # straightened: the reverse drift breaks
	_hold(0.8, false, true, A)
	assert_eq(_count("reverse_drift"), 0, "two short ones do not add up")
	_hold(0.3, false, true, A)
	assert_eq(_count("reverse_drift"), 1, "the second reaches 1.1 s")
	_hold(0.1, false, false, 0.0)
	_hold(1.2, false, true, D)
	assert_eq(_count("reverse_drift"), 2, "a new reverse drift pays again")


func test_braking_with_s_while_still_rolling_forward_does_not_count() -> void:
	_hold(2.0, true, false, 0.0)  # build up forward speed
	var need := roundi(_det.reverse_drift_min_seconds * STEPS_PER_SECOND)
	var forward_steps := 0
	var paid_at := -1
	for i in 400:
		_run(1, false, true, A)
		if _model.forward_speed() > 0.0:
			forward_steps += 1  # this step ended still rolling forward
		if paid_at < 0 and _count("reverse_drift") > 0:
			paid_at = i
	assert_gt(forward_steps, 0, "the S drift started while rolling forward")
	assert_eq(paid_at, forward_steps + need - 1, "the time counts only once it moves backwards")


func test_the_velocity_must_point_backwards() -> void:
	# A reverse drift step with the car still moving forward along the nose
	# (as right after a knockback) does not count.
	_hold(0.9, false, true, A)
	_model.set_velocity(Vector2(cos(_model.rotation), sin(_model.rotation)) * 20.0)
	_run(1, false, true, A)
	_hold(0.5, false, true, A)
	assert_eq(_count("reverse_drift"), 0, "the forward step broke it")


# --- Aura ------------------------------------------------------------------------------

func test_still_pays_nothing_for_5_s_then_one_aura_each_second() -> void:
	_hold(5.0, false, false, 0.0)
	assert_eq(_count("aura"), 0, "nothing in the first 5 s")
	_hold(0.98, false, false, 0.0)
	assert_eq(_count("aura"), 0, "not before the first full second after")
	_hold(0.02, false, false, 0.0)
	assert_eq(_count("aura"), 1, "the first at 6 s")
	_hold(1.0, false, false, 0.0)
	assert_eq(_count("aura"), 2, "7 s")
	_hold(3.0, false, false, 0.0)
	assert_eq(_count("aura"), 5, "one per second for as long as it stays still")
	assert_eq(_tricks.count("aura"), _tricks.size(), "and nothing else")


func test_moving_resets_the_count() -> void:
	_hold(7.0, false, false, 0.0)
	assert_eq(_count("aura"), 2)
	_hold(0.1, true, false, 0.0)  # W: cruise speed
	assert_gt(_model.total_speed(), _det.aura_still_speed)
	var before := _count("aura")
	# Coast back to a stop, then 5 s still again pays nothing yet.
	while _model.total_speed() > _det.aura_still_speed:
		_run(1, false, false, 0.0)
	_hold(5.5, false, false, 0.0)
	assert_eq(_count("aura"), before, "the wait starts again from zero")
	_hold(0.6, false, false, 0.0)
	assert_eq(_count("aura"), before + 1)


func test_a_slow_roll_under_the_threshold_counts_as_still() -> void:
	var slow: float = _det.aura_still_speed * 0.5
	for i in 6 * STEPS_PER_SECOND:
		_model.set_velocity(Vector2(slow, 0.0))
		_det.observe(_model, false, false, 0.0, _model.rotation)
	assert_eq(_count("aura"), 1)
	_model.set_velocity(Vector2(_det.aura_still_speed * 1.5, 0.0))
	_det.observe(_model, false, false, 0.0, _model.rotation)
	_model.set_velocity(Vector2.ZERO)
	_hold(5.9, false, false, 0.0)
	assert_eq(_count("aura"), 1, "faster than the threshold reset it")


func test_in_the_air_is_not_still() -> void:
	_hold(5.5, false, false, 0.0)
	_run(1, false, false, 0.0, true)
	_hold(5.5, false, false, 0.0)
	assert_eq(_count("aura"), 0)


func test_reset_forgets_the_stillness() -> void:
	_hold(5.9, false, false, 0.0)
	_det.reset()
	_hold(5.9, false, false, 0.0)
	assert_eq(_count("aura"), 0)


# --- The car node: paused and wrecked --------------------------------------------------

func _car() -> CharacterBody2D:
	var world := Node2D.new()
	add_child_autofree(world)
	var car: CharacterBody2D = CarScript.new()
	world.add_child(car)
	car.use_keyboard = false
	car.scripted_input = [false, false, 0.0]
	return car


func test_the_car_pays_the_aura_and_nothing_while_the_tree_is_paused() -> void:
	var car := _car()
	var got: Array = []
	car.trick.connect(func(id: String) -> void: got.append(id))
	await wait_physics_frames(4 * STEPS_PER_SECOND)
	get_tree().paused = true
	await wait_physics_frames(4 * STEPS_PER_SECOND)
	assert_eq(got.count("aura"), 0, "paused: the 4 s still are not counted")
	get_tree().paused = false
	await wait_physics_frames(int(2.5 * STEPS_PER_SECOND))
	assert_eq(got.count("aura"), 1, "the count goes on after the pause: 6.5 s still")


func test_no_aura_while_tricks_are_off_as_in_the_wreck() -> void:
	var car := _car()
	car.set_physics_process(false)
	var got: Array = []
	car.trick.connect(func(id: String) -> void: got.append(id))
	# The run's wreck (run.gd, _on_wreck_started): dead keys, tricks reset and off.
	car.input_enabled = false
	car.tricks.reset()
	car.detect_tricks = false
	for i in 10 * STEPS_PER_SECOND:
		car.physics_step()
	assert_eq(got.count("aura"), 0)


func test_the_car_pays_a_reverse_drift() -> void:
	var car := _car()
	car.set_physics_process(false)
	var got: Array = []
	car.trick.connect(func(id: String) -> void: got.append(id))
	car.scripted_input = [false, true, A]
	for i in 2 * STEPS_PER_SECOND:
		car.physics_step()
	assert_eq(got.count("reverse_drift"), 1)


# --- The run: combo, subs, recap, popups -----------------------------------------------

func test_both_raise_the_combo_pay_subs_and_count_for_the_recap() -> void:
	var c := ComboData.new()
	var state: RunState = RunStateScript.new()
	add_child_autofree(state)
	state.start_run()
	for id in ["reverse_drift", "aura"]:
		state.start_run()
		state.xp = 0.0
		var popups: Array = []
		state.combo_trick.connect(func(t: String, added: float, _m: float) -> void: popups.append([t, added]))
		state.add_trick(id)
		assert_almost_eq(state.combo, 1.0 + c.trick_add(id), 0.001, "%s raises the combo" % id)
		assert_almost_eq(state.xp, c.trick_subs(id), 0.001, "%s pays its subs" % id)
		assert_eq(popups.size(), 1)
		assert_eq(popups[0][0], id)
		assert_eq(int(state.recap()["tricks"].get(id, 0)), 1, "%s counts for the recap" % id)


func test_no_aura_pays_into_a_run_that_is_not_going() -> void:
	var state: RunState = RunStateScript.new()
	add_child_autofree(state)
	state.start_run()
	state.running = false  # as during the time's up hold and the wreck
	state.add_trick("aura")
	assert_almost_eq(state.combo, 1.0, 0.001)


func test_popup_and_recap_texts_are_t533s() -> void:
	assert_eq(TrickPopupsScript.TEXTS["reverse_drift"], "REVERSE DRIFT!")
	assert_eq(TrickPopupsScript.TEXTS["aura"], "AURA FARMING!")
	assert_true(TrickPopupsScript.SIZES.has("reverse_drift"))
	assert_true(TrickPopupsScript.SIZES.has("aura"))
	var r := GameData.load_file("recap_text")
	assert_true(r.ok)
	assert_eq(r.data["trick"]["reverse_drift"], "REVERSE DRIFT!")
	assert_eq(r.data["trick"]["aura"], "AURA FARMING!")
	assert_true(TrickPopupsScript.trick_text("aura", 0.1).begins_with("AURA FARMING! "))
