extends GutTest
## Task T-517: the Drift Guide (drift_guide.gd): the saved setting, showing only while drifting,
## the fades, the prediction against the real car, and steering changing it at once.

const CarScript := preload("res://scripts/driving/car.gd")
const GuideScript := preload("res://scripts/driving/drift_guide.gd")
var TEST_PATH := RunPaths.file("test_settings_t517.cfg")
var _world: Node2D


func before_each() -> void:
	GameSettings.path = TEST_PATH
	DirAccess.remove_absolute(TEST_PATH)
	_world = Node2D.new()
	add_child_autofree(_world)


func after_each() -> void:
	DirAccess.remove_absolute(TEST_PATH)
	TestSave.restore_settings()


func _car() -> CharacterBody2D:
	var car: CharacterBody2D = CarScript.new()
	_world.add_child(car)
	car.set_physics_process(false)
	car.use_keyboard = false
	return car


func _guide(car) -> Node2D:
	var g: Node2D = GuideScript.new()
	_world.add_child(g)
	g.bind(car)
	return g


func _drive(car, n: int, inp: Array) -> void:
	car.scripted_input = inp
	for i in n:
		car.physics_step()


func _fade(g, seconds: float) -> void:
	for i in int(seconds / 0.02):
		g.advance(0.02)


func test_off_by_default_and_saved() -> void:
	assert_false(GameSettings.load_drift_guide_enabled(), "no file: off")
	assert_true(GameSettings.save_drift_guide_enabled(true))
	assert_true(GameSettings.load_drift_guide_enabled())
	GameSettings.save_drift_guide_enabled(false)
	assert_false(GameSettings.load_drift_guide_enabled())


func test_off_never_draws_during_a_drift() -> void:
	var car = _car()
	var g = _guide(car)
	assert_false(g.enabled, "a new player has it off")
	_drive(car, 40, [true, false, 1.0])
	_fade(g, 1.0)
	assert_true(car.model.is_drifting)
	assert_false(g.is_showing())
	assert_eq(g.alpha, 0.0)
	assert_eq(g.path_units.size(), 0, "nothing is even computed")


func test_on_shows_only_while_drifting_and_fades() -> void:
	GameSettings.save_drift_guide_enabled(true)
	var car = _car()
	var g = _guide(car)
	assert_true(g.enabled)
	_drive(car, 20, [true, false, 0.0])
	_fade(g, 1.0)
	assert_false(g.is_showing(), "not drifting: nothing")
	_drive(car, 1, [true, false, 1.0])
	assert_true(car.model.is_drifting)
	assert_eq(g.alpha, 0.0, "starts at nothing")
	g.advance(0.05)
	assert_between(g.alpha, 0.01, 0.99, "fading in")
	_fade(g, 0.5)
	assert_eq(g.alpha, 1.0)
	assert_true(g.is_showing())
	_drive(car, 1, [true, false, 0.0])
	assert_false(car.model.is_drifting)
	g.advance(0.05)
	assert_between(g.alpha, 0.01, 0.99, "fading out")
	_fade(g, 1.0)
	assert_eq(g.alpha, 0.0)
	assert_false(g.is_showing())
	assert_lt(g.band_opacity(1.0), g.band_opacity(0.0) + 0.0001)


func test_the_arrow_fades_towards_its_tip_in_flat_bands() -> void:
	var g = GuideScript.new()
	add_child_autofree(g)
	g.alpha = 1.0
	assert_gt(g.band_opacity(0.0), g.band_opacity(0.99), "fainter at the tip")
	assert_eq(g.band_opacity(0.01), g.band_opacity(0.05), "flat steps: hard edges")


func test_setting_change_acts_at_once() -> void:
	var car = _car()
	var g = _guide(car)
	_drive(car, 20, [true, false, 1.0])
	_fade(g, 0.5)
	assert_false(g.is_showing())
	GameSettings.save_drift_guide_enabled(true)
	assert_true(g.enabled)
	_drive(car, 1, [true, false, 1.0])
	_fade(g, 0.5)
	assert_true(g.is_showing())
	GameSettings.save_drift_guide_enabled(false)
	assert_false(g.is_showing(), "off at once, no fade")


func test_prediction_matches_the_real_car() -> void:
	GameSettings.save_drift_guide_enabled(true)
	var car = _car()
	var g = _guide(car)
	for inp in [[true, false, 1.0], [true, false, -1.0]]:
		_drive(car, 30, inp)
		var secs: float = g.config.seconds
		var predicted: PackedVector2Array = g.path_units
		var steps := int(secs / car.model.dt)
		var every: int = g.config.sample_steps
		var worst := 0.0
		for i in range(1, steps + 1):
			car.physics_step()
			if i % every == 0:
				worst = maxf(worst, car.model.get_position().distance_to(predicted[i / every]))
		assert_lt(worst, 0.01, "within 0.01 units (0.16 px) over %.1f s, input %s" % [secs, inp])


func test_predicting_does_not_touch_the_car() -> void:
	var car = _car()
	_drive(car, 30, [true, false, 1.0])
	var before := [car.model.get_position(), car.model.get_velocity(), car.model.rotation, car.model.drift_amount]
	GuideScript.predict(car.model, true, false, 1.0, 1.0, 5)
	assert_eq([car.model.get_position(), car.model.get_velocity(), car.model.rotation, car.model.drift_amount], before)


func test_steering_change_bends_the_path_next_step() -> void:
	GameSettings.save_drift_guide_enabled(true)
	var car = _car()
	var g = _guide(car)
	_drive(car, 30, [true, false, 1.0])
	var tip_left: Vector2 = g.path_units[g.path_units.size() - 1]
	_drive(car, 1, [true, false, -1.0])
	var tip_right: Vector2 = g.path_units[g.path_units.size() - 1]
	assert_gt(tip_left.distance_to(tip_right), 1.0, "the path swings with the steering")


func test_a_wall_ends_the_path() -> void:
	var free := GuideScript.predict(CarModelScript.new(), true, false, 0.0, 1.0, 5)
	var wall := func(_from: Vector2, to: Vector2) -> bool: return to.y < -5.0
	var cut := GuideScript.predict(CarModelScript.new(), true, false, 0.0, 1.0, 5, wall)
	assert_lt(cut.size(), free.size())
	assert_gt(cut[cut.size() - 1].y, -5.0)


func test_numbers_live_in_data() -> void:
	var data = GameData.unwrap(GameData.load_file("res://data/drift_guide.json"))
	assert_true(data is Dictionary)
	assert_true(data.has("_comment"))
	for k in GuideScript.DEFAULTS:
		assert_true(data.has(k), k)


const CarModelScript := preload("res://scripts/driving/car_model.gd")
