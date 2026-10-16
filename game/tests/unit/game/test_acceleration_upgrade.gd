extends GutTest
## Task T-060: the acceleration garage upgrade reaches the car at the start of a
## run (time to top speed), and never reaches the drift prototype.

const GameScene := preload("res://scenes/game/game.tscn")
const PrototypeScene := preload("res://scenes/drift_prototype/drift_prototype.tscn")

var PROGRESS_PATH := RunPaths.file("test_progress_t060.json")
var SETTINGS_PATH := RunPaths.file("test_settings_t060.cfg")

var game: Node


func before_each() -> void:
	GameSettings.path = SETTINGS_PATH
	PlayerProgress.path = PROGRESS_PATH
	DirAccess.remove_absolute(SETTINGS_PATH)
	DirAccess.remove_absolute(PROGRESS_PATH)
	game = GameScene.instantiate()
	add_child_autofree(game)


func after_each() -> void:
	get_tree().paused = false
	await wait_process_frames(1)
	DirAccess.remove_absolute(SETTINGS_PATH)
	DirAccess.remove_absolute(PROGRESS_PATH)
	TestSave.restore_settings()
	TestSave.restore_progress()


## Seconds the car's model takes to go from standstill to top speed holding W.
func _seconds_to_top(car) -> float:
	var m = car.model
	m.set_velocity(Vector2.ZERO)
	var top: float = m.tuning.top_speed()
	var steps := 0
	while m.total_speed() < top - 0.0001 and steps < 1000:
		m.step(true, false, 0.0)
		steps += 1
	return steps * m.dt


func test_level_0_is_the_base_time_to_top_speed() -> void:
	var base := CarTuning_default()
	game.start_run()
	assert_almost_eq(game.run.car.tuning.time_to_top_speed, base, 0.0001)
	assert_almost_eq(game.run.car.tuning.time_to_top_speed, 2.3, 0.0001)


func CarTuning_default() -> float:
	return preload("res://scripts/driving/car_tuning.gd").new().time_to_top_speed


func test_higher_level_uses_the_datas_value_and_is_faster() -> void:
	game.start_run()
	var base_time := _seconds_to_top(game.run.car)
	for level in [1, 5, 10]:
		game.progress.levels["acceleration"] = level
		game.start_run()
		var want: float = game.progress.current_value("acceleration")
		assert_almost_eq(game.run.car.tuning.time_to_top_speed, want, 0.0001, "level %d" % level)
		assert_lt(want, 2.3)
		var t := _seconds_to_top(game.run.car)
		assert_lt(t, base_time, "level %d reaches top speed sooner" % level)
		# W snaps to cruise speed first, so the climb takes a fixed share of the
		# time: it scales with the data's value.
		assert_almost_eq(t, base_time * want / 2.3, 0.05, "scales with the data at level %d" % level)


func test_the_drift_prototype_is_not_affected() -> void:
	var p := PlayerProgress.new()
	p.levels["acceleration"] = 10
	game.progress = p
	var proto := PrototypeScene.instantiate()
	add_child_autofree(proto)
	await wait_process_frames(1)
	var found := false
	for n in proto.find_children("*", "", true, false):
		if "model" in n and n.get("model") != null and "tuning" in n.model:
			assert_almost_eq(n.model.tuning.time_to_top_speed, 2.3, 0.0001)
			found = true
	assert_true(found, "found the prototype's car")
