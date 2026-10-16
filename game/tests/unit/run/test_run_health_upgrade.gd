extends GutTest
## Task T-061: the car health upgrade sets the run's starting and maximum
## health (level 0 is run.json's starting health).

const GameScene := preload("res://scenes/game/game.tscn")
var PATH := RunPaths.file("test_progress_t061.json")
var game: Node


func before_each() -> void:
	PlayerProgress.path = PATH
	DirAccess.remove_absolute(PATH)


func after_each() -> void:
	get_tree().paused = false
	await wait_process_frames(1)
	DirAccess.remove_absolute(PATH)
	TestSave.restore_progress()


func _progress_at(level: int) -> PlayerProgress:
	var p := PlayerProgress.new(null, PATH)
	p.levels["car_health"] = level
	return p


func test_level_0_starts_with_the_base_health() -> void:
	var state := RunState.new()
	state.progress = _progress_at(0)
	state.start_run()
	assert_eq(state.health, RunData.new().starting_health())
	assert_eq(state.max_health, state.health)
	state.free()


func test_no_progress_keeps_the_base_health() -> void:
	var state := RunState.new()
	state.start_run()
	assert_eq(state.max_health, RunData.new().starting_health())
	state.free()


func test_every_level_uses_the_datas_health() -> void:
	var garage := GarageData.new()
	for lvl in range(garage.max_level() + 1):
		var state := RunState.new()
		state.progress = _progress_at(lvl)
		state.start_run()
		var want := garage.value("car_health", lvl)
		assert_eq(state.health, want, "level %d" % lvl)
		assert_eq(state.max_health, want, "level %d" % lvl)
		state.free()
	assert_gt(garage.value("car_health", 1), garage.value("car_health", 0))


func test_a_run_from_the_game_flow_uses_the_saved_level_and_the_hud_matches() -> void:
	game = GameScene.instantiate()
	game.quit_game = func(): pass
	add_child_autofree(game)
	game.progress.levels["car_health"] = 3
	game.start_run()
	await wait_process_frames(1)
	var want := GarageData.new().value("car_health", 3)
	assert_eq(game.run.state.max_health, want)
	assert_eq(game.run.state.health, want)
	assert_eq(game.run.hud.health_bar.max_value, want, "the HUD's maximum")
	assert_eq(game.run.hud.health_bar.value, want)


func test_a_new_run_picks_up_a_level_bought_since() -> void:
	var run: Node2D = preload("res://scenes/run/run.tscn").instantiate()
	run.progress = _progress_at(0)
	add_child_autofree(run)
	await wait_process_frames(1)
	var base: float = run.state.max_health
	run.progress.levels["car_health"] = 2
	run.start_run()
	assert_gt(run.state.max_health, base)
