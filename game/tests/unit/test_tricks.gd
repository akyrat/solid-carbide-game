extends GutTest
## Task T-079: trick detection. The three tricks (extended drift, 360,
## alternate drift) from the driving model, the car's trick signal, the tuning
## panel's trick sliders, and proof that detection never changes the movement.
##
## Most tests run the driving model and the detector directly, 50 steps per
## second, with the game's default tuning. One step of A or D turns the car
## 191.9 / 50 = 3.838 degrees, so a full circle takes 94 steps.

const CarModel := preload("res://scripts/driving/car_model.gd")
const TrickDetector := preload("res://scripts/driving/trick_detector.gd")
const CarScript := preload("res://scripts/driving/car.gd")
const CarTuning := preload("res://scripts/driving/car_tuning.gd")
const PrototypeScene := preload("res://scenes/drift_prototype/drift_prototype.tscn")
const TuningPanel := preload("res://scripts/driving/tuning_panel.gd")

const A := 1.0
const D := -1.0

var _model
var _det
var _tricks: Array = []


func before_each() -> void:
	_model = CarModel.new()
	_det = TrickDetector.new()
	_det.trick.connect(func(id: String) -> void: _tricks.append(id))
	_tricks = []


func _run(steps: int, w: bool, s: bool, steer: float) -> void:
	for i in steps:
		var before: float = _model.rotation
		_model.step(w, s, steer)
		_det.observe(_model, w, s, steer, before)


## Holds keys for a time in seconds (rounded to whole steps).
func _hold(seconds: float, w: bool, s: bool, steer: float) -> void:
	_run(roundi(seconds * 50.0), w, s, steer)


func _count(id: String) -> int:
	return _tricks.count(id)


# --- Extended drift --------------------------------------------------------------------

func test_ids() -> void:
	assert_eq(TrickDetector.TRICK_IDS, ["extended_drift", "three_sixty", "alternate_drift"])


func test_drift_held_3_5_seconds_gives_exactly_3_extended_drifts() -> void:
	_hold(3.5, true, false, A)
	assert_eq(_count("extended_drift"), 3)


func test_extended_drift_fires_on_each_full_second() -> void:
	_run(49, true, false, A)
	assert_eq(_count("extended_drift"), 0, "not before 1 s")
	_run(1, true, false, A)
	assert_eq(_count("extended_drift"), 1, "at 1 s")
	_run(50, true, false, D)
	assert_eq(_count("extended_drift"), 2, "changing steering side does not break the drift")


func test_a_break_restarts_the_extended_drift_second() -> void:
	_hold(0.9, true, false, A)
	_run(1, true, false, 0.0)  # W alone: not drifting
	_hold(0.9, true, false, A)
	assert_eq(_count("extended_drift"), 0)


func test_backward_drift_is_a_drift_too() -> void:
	_hold(2.0, false, true, D)
	assert_eq(_count("extended_drift"), 2)


func test_steering_without_w_or_s_is_not_a_drift() -> void:
	_hold(3.0, false, false, A)
	_hold(3.0, true, false, 0.0)
	assert_eq(_tricks, [])


# --- 360 -------------------------------------------------------------------------------

func test_full_circle_gives_one_360() -> void:
	_run(93, true, false, A)
	assert_eq(_count("three_sixty"), 0, "93 steps = 356.9 degrees")
	_run(1, true, false, A)
	assert_eq(_count("three_sixty"), 1, "94 steps = 360.8 degrees")


func test_two_circles_give_two_360s() -> void:
	_run(188, true, false, D)
	assert_eq(_count("three_sixty"), 2)


func test_300_degrees_then_a_break_gives_none() -> void:
	_run(78, true, false, A)  # 299.4 degrees
	_run(1, false, false, A)  # A without W or S: the drift breaks
	_run(30, true, false, A)  # another 115 degrees
	assert_eq(_count("three_sixty"), 0)


func test_turning_back_the_other_way_restarts_the_count() -> void:
	_run(78, true, false, A)
	_run(78, true, false, D)
	assert_eq(_count("three_sixty"), 0)
	_run(16, true, false, D)  # 94 steps of D in total
	assert_eq(_count("three_sixty"), 1)


func test_360_in_a_backward_drift() -> void:
	_run(94, false, true, A)
	assert_eq(_count("three_sixty"), 1)


# --- Alternate drift -------------------------------------------------------------------

func test_forward_release_backward_forward_gives_one_per_switch() -> void:
	_hold(1.0, true, false, A)    # forward drift
	_hold(0.2, false, false, A)   # W released, still steering
	_hold(1.0, false, true, A)    # backward drift
	assert_eq(_count("alternate_drift"), 1, "forward to backward")
	_hold(0.2, false, false, A)
	_hold(1.0, true, false, A)    # forward drift again
	assert_eq(_count("alternate_drift"), 2, "and back to forward")
	_hold(0.2, false, false, A)
	_hold(1.0, false, true, A)
	assert_eq(_count("alternate_drift"), 3)


func test_switching_straight_from_w_to_s_counts() -> void:
	_hold(1.0, true, false, D)
	_hold(1.0, false, true, D)
	assert_eq(_count("alternate_drift"), 1)


func test_switching_steering_direction_gives_none() -> void:
	_hold(1.0, true, false, A)
	_hold(0.2, false, false, D)
	_hold(1.0, false, true, D)
	_hold(1.0, true, false, A)
	_hold(1.0, false, true, D)
	assert_eq(_count("alternate_drift"), 0)


func test_alternate_fires_when_the_new_drift_reaches_its_shortest_time() -> void:
	_hold(1.0, true, false, A)
	_run(14, false, true, A)
	assert_eq(_count("alternate_drift"), 0, "0.28 s of backward drift: not yet")
	_run(1, false, true, A)
	assert_eq(_count("alternate_drift"), 1, "0.3 s")


func test_switch_slower_than_the_limit_gives_none() -> void:
	_hold(1.0, true, false, A)
	_hold(0.5, false, false, A)
	_hold(1.0, false, true, A)
	assert_eq(_count("alternate_drift"), 1, "0.5 s switch counts")
	_hold(0.52, false, false, A)
	_hold(1.0, true, false, A)
	assert_eq(_count("alternate_drift"), 1, "0.52 s switch does not")


func test_too_short_drifts_give_none() -> void:
	_hold(0.2, true, false, A)
	_hold(1.0, false, true, A)
	assert_eq(_count("alternate_drift"), 0, "first drift too short")
	_hold(0.2, true, false, A)
	_hold(1.0, false, true, A)
	assert_eq(_count("alternate_drift"), 0, "a short drift in between breaks the chain")


func test_letting_go_of_steering_during_the_switch() -> void:
	_hold(1.0, true, false, A)
	_hold(0.2, false, false, 0.0)
	_hold(1.0, false, true, A)
	assert_eq(_count("alternate_drift"), 0, "keep steering on: cancelled")
	_model.tuning.alternate_keep_steering = false
	_hold(0.2, false, false, 0.0)
	_hold(1.0, true, false, A)
	assert_eq(_count("alternate_drift"), 1, "keep steering off: counts")


func test_limits_are_read_live_from_the_tuning() -> void:
	_model.tuning.alternate_max_switch_seconds = 1.0
	_model.tuning.alternate_min_drift_seconds = 0.6
	_hold(1.0, true, false, A)
	_hold(0.9, false, false, A)
	_hold(0.5, false, true, A)
	assert_eq(_count("alternate_drift"), 0, "0.5 s is under the new shortest drift")
	_hold(0.1, false, true, A)
	assert_eq(_count("alternate_drift"), 1)


func test_reset_clears_everything() -> void:
	_hold(1.5, true, false, A)
	assert_eq(_det.last_trick, "extended_drift")
	assert_eq(_det.counts["extended_drift"], 1)
	_det.reset()
	assert_eq(_det.last_trick, "")
	assert_eq(_det.counts["extended_drift"], 0)
	_hold(0.6, true, false, A)
	assert_eq(_count("extended_drift"), 1, "the half second before the reset is forgotten")


# --- The car node ----------------------------------------------------------------------

func _world() -> Node2D:
	var w := Node2D.new()
	add_child_autofree(w)
	return w


func _car(world: Node2D) -> CharacterBody2D:
	var car: CharacterBody2D = CarScript.new()
	world.add_child(car)
	car.set_physics_process(false)
	car.use_keyboard = false
	return car


func _drive(car, steps: int, w: bool, s: bool, steer: float) -> void:
	car.scripted_input = [w, s, steer]
	for i in steps:
		car.physics_step()


func test_car_emits_one_signal_per_trick() -> void:
	var car := _car(_world())
	var got: Array = []
	car.trick.connect(func(id: String) -> void: got.append(id))
	_drive(car, 94, true, false, A)   # 1.88 s: one extended drift, one 360
	_drive(car, 5, false, false, A)
	_drive(car, 50, false, true, A)   # backward drift: an alternate drift
	assert_eq(got, ["extended_drift", "three_sixty", "alternate_drift", "extended_drift"])
	assert_eq(car.tricks.last_trick, "extended_drift")


## The sequence for the movement comparison: every key combination, drifts in
## both directions, coasting and switches.
const SEQUENCE := [
	[60, true, false, 0.0], [120, true, false, 1.0], [10, false, false, 1.0],
	[80, false, true, 1.0], [5, false, false, 1.0], [90, true, false, 1.0],
	[40, true, true, -1.0], [70, false, true, -1.0], [30, false, false, 0.0],
	[100, true, false, -1.0], [25, false, false, -1.0], [60, false, true, -1.0],
]


func test_movement_is_the_same_with_and_without_trick_detection() -> void:
	var world := _world()
	var on := _car(world)
	var off := _car(world)
	off.detect_tricks = false
	var model = CarModel.new()
	model.dt = on.model.dt
	var tricks_seen := [0]
	on.trick.connect(func(_id: String) -> void: tricks_seen[0] += 1)
	var steps := 0
	for part in SEQUENCE:
		on.scripted_input = [part[1], part[2], part[3]]
		off.scripted_input = [part[1], part[2], part[3]]
		for i in part[0]:
			on.physics_step()
			off.physics_step()
			model.step(part[1], part[2], part[3])
			steps += 1
			if on.model.x != off.model.x or on.model.y != off.model.y \
					or on.model.vx != off.model.vx or on.model.vy != off.model.vy \
					or on.model.rotation != off.model.rotation or on.model.drift_amount != off.model.drift_amount:
				fail_test("detection changed the movement at step %d" % steps)
				return
			if on.model.x != model.x or on.model.y != model.y or on.model.vx != model.vx \
					or on.model.vy != model.vy or on.model.rotation != model.rotation:
				fail_test("the car no longer matches the bare driving model at step %d" % steps)
				return
			if on.position != off.position or on.rotation != off.rotation:
				fail_test("the body moved differently at step %d" % steps)
				return
	assert_gt(tricks_seen[0], 5, "tricks were detected during the drive")
	assert_eq(off.tricks.last_trick, "", "no detection when turned off")


# --- The tuning panel ------------------------------------------------------------------

func _prototype() -> Node2D:
	GameSettings.path = RunPaths.file("test_no_such_settings.cfg")
	var p: Node2D = PrototypeScene.instantiate()
	add_child_autofree(p)
	p.car.set_physics_process(false)
	p.car.use_keyboard = false
	return p


func after_each() -> void:
	GameSettings.path = GameSettings.DEFAULT_PATH


func test_panel_has_trick_sliders_and_reset_restores_the_proposed_values() -> void:
	var p := _prototype()
	var sliders: Dictionary = p.panel.trick_sliders
	assert_eq(sliders.keys(), ["alternate_max_switch_seconds", "alternate_min_drift_seconds"])
	var switch: HSlider = sliders["alternate_max_switch_seconds"]
	var shortest: HSlider = sliders["alternate_min_drift_seconds"]
	var keep: CheckButton = p.panel.trick_toggles["alternate_keep_steering"]
	assert_almost_eq(switch.value, 0.5, 1e-9, "proposed switch time")
	assert_almost_eq(shortest.value, 0.3, 1e-9, "proposed shortest drift")
	assert_true(keep.button_pressed, "keep steering on")
	for sl in [switch, shortest]:
		assert_eq(sl.min_value, 0.0)
		assert_eq(sl.max_value, 2.0)
		assert_ne(sl.tooltip_text, "")
	assert_ne(keep.tooltip_text, "")

	switch.value = 1.2
	shortest.value = 0.8
	keep.button_pressed = false
	assert_almost_eq(p.car.tuning.alternate_max_switch_seconds, 1.2, 1e-9, "applies at once")
	assert_almost_eq(p.car.tuning.alternate_min_drift_seconds, 0.8, 1e-9)
	assert_false(p.car.tuning.alternate_keep_steering)

	p.panel.reset_button.pressed.emit()
	assert_almost_eq(p.car.tuning.alternate_max_switch_seconds, 0.5, 1e-12, "reset")
	assert_almost_eq(p.car.tuning.alternate_min_drift_seconds, 0.3, 1e-12, "reset")
	assert_true(p.car.tuning.alternate_keep_steering, "reset")
	assert_almost_eq(switch.value, 0.5, 1e-9, "slider follows")
	assert_almost_eq(shortest.value, 0.3, 1e-9, "slider follows")
	assert_true(keep.button_pressed, "toggle follows")


func test_readout_shows_the_last_trick() -> void:
	var p := _prototype()
	assert_string_contains(TuningPanel.trick_text(p.car.tricks), "Last trick: none yet")
	_drive(p.car, 94, true, false, A)
	var text: String = TuningPanel.trick_text(p.car.tricks)
	assert_string_contains(text, "Last trick: 360")
	assert_string_contains(text, "extended 1   360 1   alternate 0")
	p.panel.visible = true
	p.panel._process(0.0)
	assert_string_contains(p.panel.readout.text, "Last trick: 360")


func test_default_values_include_the_trick_limits() -> void:
	var values := CarTuning.default_values()
	assert_almost_eq(float(values["alternate_max_switch_seconds"]), 0.5, 1e-12)
	assert_almost_eq(float(values["alternate_min_drift_seconds"]), 0.3, 1e-12)
	assert_eq(values["alternate_keep_steering"], true)
