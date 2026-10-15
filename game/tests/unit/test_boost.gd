extends GutTest
## Task T-008: the boost signal (Car.boost) and its placeholder effect. The
## signal fires once per W press that snaps the car up to cruise speed, never
## while W stays held and never at or above cruise speed; it changes no speed.

const CarScript := preload("res://scripts/driving/car.gd")
const RunScene := preload("res://scenes/run/run.tscn")
const BoostScript := preload("res://scripts/driving/boost_effect.gd")

const W_ONLY := [true, false, 0.0]
const W_AND_D := [true, false, -1.0]
const NOTHING := [false, false, 0.0]

var _boosts: Array


func _car() -> CharacterBody2D:
	var car: CharacterBody2D = CarScript.new()
	add_child_autofree(car)
	car.use_keyboard = false
	_boosts = []
	car.boost.connect(func(from_speed: float) -> void: _boosts.append(from_speed))
	return car


func _drive(car: CharacterBody2D, input: Array, steps: int) -> void:
	car.scripted_input = input
	for i in steps:
		car.physics_step()


func test_fires_once_from_standstill() -> void:
	var car := _car()
	_drive(car, W_ONLY, 1)
	assert_eq(_boosts.size(), 1)
	assert_almost_eq(float(_boosts[0]), 0.0, 0.001)
	_drive(car, W_ONLY, 30)
	assert_eq(_boosts.size(), 1, "W held: no more")


func test_fires_once_when_pressed_while_slower_than_cruise() -> void:
	var car := _car()
	_drive(car, W_ONLY, 5)
	_drive(car, NOTHING, 20)  # coasting down a little
	var speed: float = car.model.get_velocity().length()
	assert_lt(speed, car.tuning.forward_speed - 0.5, "slower than cruise")
	assert_gt(speed, 0.5, "still moving")
	_boosts = []
	_drive(car, W_ONLY, 20)
	assert_eq(_boosts.size(), 1)
	assert_gt(float(_boosts[0]), 0.0)


func test_not_while_w_held_during_a_drift() -> void:
	var car := _car()
	_drive(car, W_ONLY, 20)
	_boosts = []
	var jumps := []
	car.cruise_jump.connect(func(_f: float, _j: bool) -> void: jumps.append(1))
	_drive(car, W_AND_D, 150)
	assert_gt(jumps.size(), 3, "the car does jump back to cruise during the drift")
	assert_eq(_boosts.size(), 0, "but no boost while W stays held")


func test_not_when_pressed_at_or_above_cruise() -> void:
	var car := _car()
	_drive(car, W_ONLY, 200)  # climbs above cruise
	assert_gt(car.model.get_velocity().length(), car.tuning.forward_speed + 0.5)
	_drive(car, NOTHING, 1)  # a single coasting step keeps it above cruise
	_boosts = []
	_drive(car, W_ONLY, 1)
	assert_eq(_boosts.size(), 0)


func test_fires_again_on_a_new_press() -> void:
	var car := _car()
	_drive(car, W_ONLY, 5)
	_drive(car, NOTHING, 100)
	_drive(car, W_ONLY, 5)
	assert_eq(_boosts.size(), 2)


func test_speeds_identical_with_and_without_the_effect() -> void:
	var plain := _car()
	var with_effect := _car()
	var effect: Node2D = BoostScript.new()
	add_child_autofree(effect)
	effect.set_process(false)
	effect.bind(with_effect)
	var script := [[W_ONLY, 10], [NOTHING, 8], [W_AND_D, 60], [NOTHING, 30], [W_ONLY, 40]]
	for part in script:
		plain.scripted_input = part[0]
		with_effect.scripted_input = part[0]
		for i in part[1]:
			plain.physics_step()
			with_effect.physics_step()
			effect.advance(plain.model.dt)
			assert_eq(plain.model.get_velocity(), with_effect.model.get_velocity())
			assert_eq(plain.model.rotation, with_effect.model.rotation)
	assert_gt(effect.bursts_made, 1, "the effect did play")


func test_effect_plays_and_ends() -> void:
	var car := _car()
	var effect: Node2D = BoostScript.new()
	add_child_autofree(effect)
	effect.set_process(false)
	effect.bind(car)
	assert_eq(effect.burst_count(), 0)
	_drive(car, W_ONLY, 1)
	assert_eq(effect.burst_count(), 1)
	_drive(car, W_ONLY, 30)
	assert_eq(effect.burst_count(), 1, "no new burst while held")
	effect.advance(effect.lifetime + 0.01)
	assert_eq(effect.burst_count(), 0, "it ends")


func test_run_has_the_effect_bound_to_the_car() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.boost_effect.set_process(false)
	assert_not_null(run.boost_effect)
	run.car.use_keyboard = false
	run.car.scripted_input = W_ONLY
	run.car.physics_step()
	assert_eq(run.boost_effect.burst_count(), 1)
