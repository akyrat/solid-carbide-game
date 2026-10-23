extends GutTest
## Task T-270: the air turn garage upgrade (Spin Doctor) is saved like the others and reaches the
## car at the start of every run through CarTuning.apply_air_turn_bonus(); the drift prototype
## never gets it.

const GameScene := preload("res://scenes/game/game.tscn")
const PrototypeScene := preload("res://scenes/drift_prototype/drift_prototype.tscn")

var PROGRESS_PATH := RunPaths.file("test_progress_t270.json")
var SETTINGS_PATH := RunPaths.file("test_settings_t270.cfg")

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


func _air_rate(tuning) -> float:
	return tuning.turn_rate_for(true) / tuning.turn_rate()


func test_the_data_is_base_to_old_value_in_steps() -> void:
	var g := GarageData.new()
	assert_almost_eq(g.value("air_turn", 0), 1.25, 0.0001)
	assert_almost_eq(g.value("air_turn", 10), 2.5, 0.0001)
	for l in range(1, 11):
		assert_almost_eq(g.value("air_turn", l) - g.value("air_turn", l - 1), 0.125, 0.0001)
	assert_eq(g.price("air_turn", 1), 40)
	assert_eq(g.price("air_turn", 10), 300)


func test_the_base_matches_the_cars_air_multiplier() -> void:
	var t = preload("res://scripts/driving/car_tuning.gd").new()
	assert_almost_eq(GarageData.new().value("air_turn", 0), t.air_turn_multiplier, 0.0001)


func test_level_0_keeps_the_base_air_rate() -> void:
	game.start_run()
	assert_almost_eq(_air_rate(game.run.car.tuning), 1.25, 0.0001)


func test_every_level_sets_the_next_runs_air_rate_to_the_datas_value() -> void:
	for level in range(0, 11):
		game.progress.levels["air_turn"] = level
		game.start_run()
		var want: float = GarageData.new().value("air_turn", level)
		assert_almost_eq(_air_rate(game.run.car.tuning), want, 0.0001, "level %d" % level)


func test_buying_a_level_is_saved_and_reaches_the_next_run() -> void:
	game.progress.coins = 1000
	assert_true(game.progress.buy("air_turn").ok)
	var reloaded := PlayerProgress.new(null, PROGRESS_PATH)
	assert_eq(reloaded.level("air_turn"), 1)
	game.start_run()
	assert_almost_eq(_air_rate(game.run.car.tuning), 1.375, 0.0001)


func test_the_ground_rate_is_not_changed() -> void:
	game.start_run()
	var before: float = game.run.car.tuning.turn_rate()
	game.progress.levels["air_turn"] = 10
	game.start_run()
	assert_almost_eq(game.run.car.tuning.turn_rate(), before, 0.0001)


func test_the_drift_prototype_is_not_affected() -> void:
	var p := PlayerProgress.new()
	p.levels["air_turn"] = 10
	game.progress = p
	var proto := PrototypeScene.instantiate()
	add_child_autofree(proto)
	await wait_process_frames(1)
	var found := false
	for n in proto.find_children("*", "", true, false):
		if "model" in n and n.get("model") != null and "tuning" in n.model:
			assert_almost_eq(_air_rate(n.model.tuning), 1.25, 0.0001)
			found = true
	assert_true(found, "found the prototype's car")
