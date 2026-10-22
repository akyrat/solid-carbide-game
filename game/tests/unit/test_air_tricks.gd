extends GutTest
## Task T-219: the aerial tricks (Drifting, Decisions, "Aerial tricks"): a 180
## and a full 360 of the heading turned during one airtime, left and right the
## same, from trick_detector.gd's observe_air(). Then the real car falling and
## driving off a rooftop on the elevation map's ground, and the run's combo
## and popups with T-218's texts.
##
## The detector tests feed it ground-rate steps: one step of A or D turns the
## car 191.9 / 50 = 3.838 degrees on the ground (47 steps for a 180, 94 for a
## 360). The real car turns air_turn_multiplier (2.5) times faster in the air
## (the board's tweak): 9.6 degrees a step, 19 steps for a 180, 38 for a 360;
## a fall off a height-6 rooftop counts 49 steps in the air.

const TrickDetector := preload("res://scripts/driving/trick_detector.gd")
const CarModel := preload("res://scripts/driving/car_model.gd")
const CarScript := preload("res://scripts/driving/car.gd")
const CarTuningScript := preload("res://scripts/driving/car_tuning.gd")
const GroundHeightScript := preload("res://scripts/level/ground_height.gd")
const ComboDataScript := preload("res://scripts/data/combo_data.gd")
const RUN := preload("res://scenes/run/run.tscn")
const LAYOUT := "res://data/level/elevation_sample_map.json"

const A := 1.0
const D := -1.0
## The heading's change for one step of steering, radians (positive = A).
var STEP_TURN := 0.0

var _det
var _tricks: Array = []


func before_each() -> void:
	_det = TrickDetector.new()
	_tricks = []
	_det.trick.connect(func(id: String) -> void: _tricks.append(id))
	var m = CarModel.new()
	STEP_TURN = deg_to_rad(m.tuning.turn_rate() * m.dt)


func _count(id: String) -> int:
	return _tricks.count(id)


## `steps` steps in the air (or on the ground), steering `steer` (+1 A, -1 D, 0 none).
## The model turns clockwise on screen for A: rotation goes down by STEP_TURN.
func _air(steps: int, steer: float, airborne := true) -> void:
	for i in steps:
		_det.observe_air(airborne, -steer * STEP_TURN)


func _land() -> void:
	_det.observe_air(false, 0.0)


func _air_tricks() -> Array:
	return _tricks.filter(func(id: String) -> bool: return TrickDetector.AIR_TRICK_IDS.has(id))


# --- The detector ---------------------------------------------------------------------

func test_ids_are_tricks_with_combo_values() -> void:
	assert_eq(TrickDetector.AIR_TRICK_IDS, ["air_one_eighty", "air_three_sixty"])
	for id in TrickDetector.AIR_TRICK_IDS:
		assert_true(TrickDetector.TRICK_IDS.has(id), id)
	var c = ComboDataScript.new()
	assert_true(c.is_ok())
	for id in TrickDetector.TRICK_IDS:
		if id == TrickDetector.TRICK_EXTENDED_DRIFT:
			assert_gt(c.drift_amount(1.0), 0.0, "combo.json has drift_pay")  # scaled by length (T-246)
		else:
			assert_gt(c.trick_add(id), 0.0, "combo.json has trick_add.%s" % id)


func test_a_180_in_one_airtime_gives_the_180_left_and_right() -> void:
	for steer in [A, D]:
		_tricks = []
		_det.reset()
		_air(47, steer)  # 180.4 degrees
		assert_eq(_air_tricks(), [], "nothing before landing")
		_land()
		assert_eq(_air_tricks(), ["air_one_eighty"], "steer %s" % steer)


func test_a_full_turn_gives_the_360_only_left_and_right() -> void:
	for steer in [A, D]:
		_tricks = []
		_det.reset()
		_air(94, steer)  # 360.8 degrees
		_land()
		assert_eq(_air_tricks(), ["air_three_sixty"], "the 360, not its 180 too (steer %s)" % steer)


func test_a_smaller_turn_gives_neither() -> void:
	_air(46, A)  # 176.5 degrees
	_land()
	_air(93, D, true)  # 356.9 degrees: a 180, not a 360
	_land()
	assert_eq(_air_tricks(), ["air_one_eighty"])
	_tricks = []
	_air(10, A)
	_land()
	assert_eq(_air_tricks(), [])


func test_the_same_turn_on_the_ground_gives_neither() -> void:
	_air(200, A, false)
	_land()
	_air(200, D, false)
	assert_eq(_air_tricks(), [])


func test_540_and_720() -> void:
	_air(141, A)  # 541.2 degrees
	_land()
	assert_eq(_air_tricks(), ["air_three_sixty", "air_one_eighty"], "540: a 360 and a 180")
	_tricks = []
	_air(188, D)  # 721.5 degrees
	_land()
	assert_eq(_air_tricks(), ["air_three_sixty", "air_three_sixty"], "720: two 360s")


func test_turns_in_two_airtimes_do_not_add_up() -> void:
	_air(30, A)
	_land()
	_air(30, A)
	_land()
	assert_eq(_air_tricks(), [])


func test_turning_back_keeps_the_biggest_turn_of_the_airtime() -> void:
	_air(50, A)  # 191.9 one way
	_air(20, D)  # then back 76.8
	_land()
	assert_eq(_air_tricks(), ["air_one_eighty"], "the 180 still counts after a wiggle back")
	_tricks = []
	_air(30, A)  # 115 one way, then 115 the other: neither is a 180
	_air(30, D)
	_land()
	assert_eq(_air_tricks(), [])


func test_letting_go_of_the_steering_in_the_air_keeps_the_count() -> void:
	_air(25, A)
	_air(10, 0.0)
	_air(22, A)
	_land()
	assert_eq(_air_tricks(), ["air_one_eighty"])


func test_reset_forgets_the_airtime() -> void:
	_air(60, A)
	_det.reset()
	_land()
	assert_eq(_air_tricks(), [])


func test_half_turns() -> void:
	assert_eq(TrickDetector.half_turns(PI - 0.01), 0)
	assert_eq(TrickDetector.half_turns(PI), 1)
	assert_eq(TrickDetector.half_turns(-TAU), 2)
	assert_eq(TrickDetector.half_turns(3.0 * PI + 0.1), 3)


func test_counts_and_last_trick() -> void:
	_air(94, A)
	_land()
	assert_eq(_det.counts["air_three_sixty"], 1)
	assert_eq(_det.counts["air_one_eighty"], 0)
	assert_eq(_det.last_trick, "air_three_sixty")


# --- The real car on the elevation map's ground -------------------------------------

var _world: Node2D
var _ground


func _car(start: Vector2, rotation: float) -> CharacterBody2D:
	_world = Node2D.new()
	add_child_autofree(_world)
	_ground = GroundHeightScript.from_file(LAYOUT)
	var car: CharacterBody2D = CarScript.new()
	car.model.set_position(start)
	car.model.rotation = rotation
	_world.add_child(car)
	car.set_physics_process(false)
	car.use_keyboard = false
	car.ground = _ground
	car.trick.connect(func(id: String) -> void: _tricks.append(id))
	return car


## A street point (height 0, no ramp) with street all round it for `r` units.
func _street_point(r: float) -> Vector2:
	var g = GroundHeightScript.from_file(LAYOUT)
	for y in range(-120, 121, 4):
		for x in range(-120, 121, 4):
			var p := Vector2(x, y)
			var ok := true
			for off in [Vector2.ZERO, Vector2(r, 0), Vector2(-r, 0), Vector2(0, r), Vector2(0, -r)]:
				if g.is_ramp(p + off) or g.height_at(p + off) != 0.0:
					ok = false
			if ok:
				return p
	return Vector2.INF


## The car let go `lift` units above the street, standing; it steers `steer`
## from `from_step` physics steps after the start for `for_steps` steps (-1:
## until it lands). Returns the physics steps it was in the air.
func _drop(lift: float, steer: float, from_step := 0, for_steps := -1) -> int:
	var p := _street_point(3.0)
	assert_ne(p, Vector2.INF, "a street point")
	var car := _car(p, 0.0)
	car.height_model.height = lift
	car.height_model.airborne = true
	var steps := 0
	while car.airborne and steps < 1000:
		var on := steps >= from_step and (for_steps < 0 or steps < from_step + for_steps)
		car.scripted_input = [false, false, steer if on else 0.0]
		car.physics_step()
		steps += 1
	car.scripted_input = [false, false, 0.0]
	car.physics_step()
	return steps


## Task T-219, the board's tweak: the car turns air_turn_multiplier times faster
## in the air, so a fall off a height-6 rooftop (50 steps) fits a 360.
func test_air_turn_rate_is_a_tuning_value_and_the_ground_rate_is_unchanged() -> void:
	var t = CarModel.new().tuning
	assert_almost_eq(t.turn_rate_for(false), 191.9, 1e-9, "ground: 202 x 0.95, as before")
	assert_almost_eq(t.turn_rate_for(true), 191.9 * t.air_turn_multiplier, 1e-9)
	assert_almost_eq(float(t.air_turn_multiplier), 2.5, 1e-9, "proposed")
	assert_true(CarTuningScript.default_values().has("air_turn_multiplier"))


func test_the_real_car_turns_faster_only_in_the_air() -> void:
	var car := _car(_street_point(3.0), 0.0)
	car.scripted_input = [false, false, A]
	car.physics_step()
	assert_almost_eq(car.model.rotation, -STEP_TURN, 1e-9, "on the ground: one ground step")
	car.height_model.height = 6.0
	car.height_model.airborne = true
	var before: float = car.model.rotation
	car.physics_step()
	assert_almost_eq(car.model.rotation - before, -STEP_TURN * car.tuning.air_turn_multiplier, 1e-9, "in the air")


func test_the_real_car_falling_6_units_steering_throughout_gives_the_360_both_ways() -> void:
	for steer in [A, D]:
		_tricks = []
		var steps := _drop(6.0, steer)
		assert_between(steps, 48, 52, "a 6 unit fall (%d steps)" % steps)
		assert_eq(_air_tricks(), ["air_three_sixty"], "steer %s" % steer)


func test_the_360_off_a_6_rooftop_has_a_fifth_of_a_second_to_spare() -> void:
	_drop(6.0, A, 10)  # starting 0.2 s late still makes it
	assert_eq(_air_tricks(), ["air_three_sixty"], "10 steps late")
	_tricks = []
	_drop(6.0, A, 12)
	assert_eq(_air_tricks(), ["air_one_eighty"], "12 steps late: only the 180")


func test_the_180_is_much_easier_it_takes_19_steps() -> void:
	_drop(6.0, D, 0, 19)
	assert_eq(_air_tricks(), ["air_one_eighty"], "0.38 s of steering")
	_tricks = []
	_drop(6.0, D, 0, 18)
	assert_eq(_air_tricks(), [])


func test_the_real_car_turning_on_the_ground_gives_neither() -> void:
	var car := _car(_street_point(3.0), 0.0)
	car.scripted_input = [false, false, A]
	for i in 200:
		car.physics_step()
	assert_false(car.airborne)
	assert_eq(_air_tricks(), [])


func test_the_real_car_falling_without_turning_gives_neither() -> void:
	_drop(6.0, 0.0)
	assert_eq(_air_tricks(), [])


## Drives off the side of a height-6 rooftop onto the street with W held,
## turning with W and A as soon as it is in the air: a drift in the air.
func test_driving_off_a_6_rooftop_and_turning_gives_the_360() -> void:
	var g = GroundHeightScript.from_file(LAYOUT)
	var edge := {}
	for p in g.platforms:
		if not is_equal_approx(float(p.height), 6.0):
			continue
		var rect: Rect2 = p.rect
		for n in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			var mid: Vector2 = rect.get_center() + n * (rect.size / 2.0)
			if g.height_at(mid + n * 3.0) == 0.0 and not g.is_ramp(mid + n * 3.0) and g.height_at(mid - n * 3.0) == 6.0:
				edge = {"point": mid, "normal": n}
				break
		if not edge.is_empty():
			break
	assert_false(edge.is_empty(), "a height-6 side over the street")
	var n: Vector2 = edge.normal
	var car := _car(edge.point - n * 2.0, n.angle())
	car.scripted_input = [true, false, 0.0]
	var steps := 0
	while not car.airborne and steps < 200:
		car.physics_step()
		steps += 1
	assert_true(car.airborne, "off the edge")
	car.scripted_input = [true, false, A]
	var air := 0
	while car.airborne and air < 500:
		car.physics_step()
		air += 1
	assert_eq(_air_tricks(), ["air_three_sixty"], "%d steps in the air" % air)
	assert_eq(_count("three_sixty"), 0, "each spin pays once: no FULL 360 for the air spin (W held)")


func test_detection_off_gives_no_air_tricks() -> void:
	var p := _street_point(3.0)
	var car := _car(p, 0.0)
	car.detect_tricks = false
	car.height_model.height = 6.0
	car.height_model.airborne = true
	car.scripted_input = [false, false, A]
	for i in 80:
		car.physics_step()
	assert_eq(_tricks, [])


# --- Each spin pays once (task T-219, board): air turning is not the drift 360's ---

## Drift steps (W + A) with the model in the air or not: in the air the model
## is not drifting (board: no drifting in the air).
func _drift_steps(model, steps: int, airborne: bool) -> void:
	for i in steps:
		var before: float = model.rotation
		model.airborne = airborne
		model.step(true, false, A)
		_det.observe(model, true, false, A, before, airborne)


func test_drift_360_and_long_drift_ignore_the_air() -> void:
	var m = CarModel.new()
	_drift_steps(m, 200, true)
	assert_eq(_count("three_sixty"), 0, "a spin in the air is no FULL 360")
	assert_eq(_count("extended_drift"), 0, "airtime is no drift time")


## Since "no drifting in the air", a takeoff is a break in the drift: a drift
## 360 (and the extended drift's second) in progress starts again from zero.
func test_a_drift_360_in_progress_at_takeoff_starts_again_after_landing() -> void:
	var m = CarModel.new()
	_drift_steps(m, 50, false)  # 191.9 degrees on the ground
	_drift_steps(m, 30, true)   # in the air: not drifting, a break
	_drift_steps(m, 93, false)  # 93 ground steps since landing: 356.9 degrees
	assert_eq(_count("three_sixty"), 0, "the 50 steps before the jump don't count")
	_drift_steps(m, 1, false)   # the 94th since landing
	assert_eq(_count("three_sixty"), 1)


# --- No drifting in the air (task T-219, board): the path is kept, the car only spins ---

func test_airborne_velocity_stays_the_takeoff_velocity_with_any_keys() -> void:
	var car := _car(_street_point(30.0), 0.0)
	car.height_model.height = 22.0
	car.height_model.airborne = true
	var v0 := Vector2(9.0, -4.0)
	car.model.set_velocity(v0)
	var r0: float = car.model.rotation
	var keys := [[true, false, A], [true, false, D], [false, true, A], [false, true, 0.0],
		[true, true, D], [false, false, A], [true, false, 0.0], [false, false, 0.0]]
	for k in keys:
		for i in 10:
			car.scripted_input = k
			car.physics_step()
			assert_true(car.airborne)
			assert_eq(car.model.get_velocity(), v0, "keys %s" % [k])
			assert_false(car.model.is_drifting, "no drifting in the air")
	assert_ne(car.model.rotation, r0, "the heading still spins")


func test_in_the_air_the_heading_spins_at_the_air_rate_and_nothing_else() -> void:
	var car := _car(_street_point(30.0), 0.0)
	car.height_model.height = 22.0
	car.height_model.airborne = true
	car.model.set_velocity(Vector2(11.0, 0.0))
	car.scripted_input = [true, false, A]
	var start: Vector2 = car.model.get_position()
	for i in 20:
		var before: float = car.model.rotation
		car.physics_step()
		assert_almost_eq(car.model.rotation - before, -STEP_TURN * car.tuning.air_turn_multiplier, 1e-9)
	var moved: Vector2 = car.model.get_position() - start
	assert_almost_eq(moved.y, 0.0, 1e-9, "flies straight on")
	assert_almost_eq(moved.x, 11.0 * 20 * car.model.dt, 1e-4)


func test_driving_resumes_on_landing_from_the_kept_velocity() -> void:
	var p := _street_point(30.0)
	var car := _car(p, 0.0)
	car.height_model.height = 1.0
	car.height_model.airborne = true
	car.model.set_velocity(Vector2(11.0, 0.0))
	car.model.rotation = PI / 2.0  # landing at 90 degrees to the path
	car.scripted_input = [false, false, 0.0]
	while car.airborne:
		car.physics_step()
	var v_land: Vector2 = car.model.get_velocity()
	assert_eq(v_land, Vector2(11.0, 0.0), "landed with the takeoff velocity")
	car.physics_step()
	var v_next: Vector2 = car.model.get_velocity()
	assert_lt(v_next.length(), v_land.length(), "grip works again: the sideways slide fades")
	assert_lt(absf(v_next.x), 11.0, "sliding sideways, slowing")


func test_no_long_drift_while_spinning_in_the_air_with_w_held() -> void:
	var car := _car(_street_point(30.0), 0.0)
	car.height_model.height = 22.0
	car.height_model.airborne = true
	car.scripted_input = [true, false, A]
	var steps := 0
	while car.airborne and steps < 200:
		car.physics_step()
		steps += 1
	assert_gt(steps, 90, "almost 2 s in the air")
	assert_eq(_count("extended_drift"), 0, "airtime is no drift time")
	assert_eq(_count("three_sixty"), 0)


func test_the_real_car_drift_360_on_the_ground_still_works() -> void:
	var car := _car(_street_point(8.0), 0.0)
	car.scripted_input = [true, false, A]
	for i in 94:
		car.physics_step()
		if car.airborne:
			fail_test("left the ground")
			return
	assert_eq(_count("three_sixty"), 1, "94 ground steps: a FULL 360")
	assert_eq(_air_tricks(), [])


func test_the_real_car_air_spin_with_w_held_pays_only_the_air_360() -> void:
	var p := _street_point(3.0)
	var car := _car(p, 0.0)
	car.height_model.height = 6.0
	car.height_model.airborne = true
	car.model.set_velocity(Vector2(11.0, 0.0))
	car.scripted_input = [true, false, A]
	var steps := 0
	while car.airborne and steps < 200:
		car.physics_step()
		steps += 1
	car.scripted_input = [false, false, 0.0]
	car.physics_step()
	assert_eq(_air_tricks(), ["air_three_sixty"])
	assert_eq(_count("three_sixty"), 0, "no FULL 360 for the same spin")


# --- The run: combo and popups ------------------------------------------------------

func test_each_air_trick_raises_the_combo_and_shows_its_popup() -> void:
	var c = ComboDataScript.new()
	var texts := {"air_one_eighty": "AIR 180!", "air_three_sixty": "AIR 360!"}
	for id in texts:
		var r: Node2D = RUN.instantiate()
		add_child_autofree(r)
		var before: float = r.state.combo
		r.car.trick.emit(id)
		assert_almost_eq(r.state.combo, before + c.trick_add(id), 0.000001, id)
		var pop = r.trick_popups.popups().back()
		assert_eq(pop.text, "%s +%s" % [texts[id], String.num(c.trick_add(id), 2)], id)


func test_popup_texts_word_for_word() -> void:
	assert_eq(TrickPopups.TEXTS["air_one_eighty"], "AIR 180!")
	assert_eq(TrickPopups.TEXTS["air_three_sixty"], "AIR 360!")
	assert_eq(TrickPopups.trick_text("air_one_eighty", 0.25), "AIR 180! +0.25")
	assert_eq(TrickPopups.trick_text("air_three_sixty", 0.0), "AIR 360!")


func test_a_real_fall_in_the_run_raises_the_combo() -> void:
	var r: Node2D = RUN.instantiate()
	add_child_autofree(r)
	await get_tree().process_frame
	var car: CharacterBody2D = r.car
	car.set_physics_process(false)
	car.use_keyboard = false
	var p := _street_point(3.0)
	car.model.set_position(p)
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = r.elevation.ground_height
	car.height_model.height = 6.0
	car.height_model.airborne = true
	car.scripted_input = [false, false, D]
	var before: float = r.state.combo
	var steps := 0
	while car.airborne and steps < 200:
		car.physics_step()
		steps += 1
	var c = ComboDataScript.new()
	# The same fall also pays the airtime trick (T-242): 49 steps = 0.98 s.
	assert_almost_eq(r.state.combo, before + c.trick_add("air_three_sixty") + c.airtime_add(0.98), 0.000001)
	assert_true(r.trick_popups.popups().any(func(q) -> bool: return q.text.begins_with("AIR 360!")))
