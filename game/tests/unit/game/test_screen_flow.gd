extends GutTest
## Task T-055: the screen flow. The game opens on the main menu, Start begins
## a fresh run, a won or lost run goes back to the main menu, Garage does
## nothing yet, Exit closes the game, and Escape pauses a run started from
## the menu.

const GameScene := preload("res://scenes/game/game.tscn")
const TEST_PATH := "user://test_settings_t055.cfg"

var game: Node
var quit_calls := 0


func before_each() -> void:
	GameSettings.path = TEST_PATH
	DirAccess.remove_absolute(TEST_PATH)
	quit_calls = 0
	game = GameScene.instantiate()
	game.quit_game = func(): quit_calls += 1
	add_child_autofree(game)


func after_each() -> void:
	get_tree().paused = false
	await wait_process_frames(1)  # let screens freed with queue_free() go
	DirAccess.remove_absolute(TEST_PATH)
	GameSettings.path = GameSettings.DEFAULT_PATH


func _press(button: Button) -> void:
	button.pressed.emit()


func _only_screen() -> Node:
	assert_eq(game.get_child_count(), 1, "exactly one screen on show")
	return game.get_child(0)


func test_the_main_scene_is_the_game_flow() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/game/game.tscn")


func test_the_game_opens_on_the_main_menu() -> void:
	assert_not_null(game.menu)
	assert_true(game.menu is MainMenu, "the first screen is the main menu")
	assert_eq(_only_screen(), game.menu)
	assert_null(game.run, "no run before Start")
	assert_false(get_tree().paused)


func test_start_begins_a_fresh_run() -> void:
	var menu = game.menu
	_press(menu.start_button)
	await wait_process_frames(1)
	assert_not_null(game.run, "a run is on screen")
	assert_eq(_only_screen(), game.run, "the menu is gone")
	assert_false(is_instance_valid(menu) and menu.is_inside_tree(), "the menu left the tree")
	var s: RunState = game.run.state
	assert_true(s.is_running())
	assert_eq(s.time_left_text(), "8:00")
	assert_eq(s.health, s.max_health)
	assert_eq(s.coins, 0)
	assert_eq(s.result, "")
	assert_eq(game.run.car.position, game.run.START_POSITION_UNITS * 16.0, "the car at the start")


func _end_run_and_check_menu(end: Callable, expected_result: String) -> void:
	_press(game.menu.start_button)
	var run = game.run
	var s: RunState = run.state
	watch_signals(s)
	end.call(s)
	assert_eq(s.result, expected_result)
	assert_signal_emitted(s, "run_ended")
	await wait_process_frames(2)
	assert_not_null(game.menu, "back on the main menu")
	assert_eq(_only_screen(), game.menu, "only the menu, no message")
	assert_null(game.run)
	assert_false(is_instance_valid(run), "the old run is freed")
	assert_false(get_tree().paused)


func test_a_won_run_returns_to_the_main_menu() -> void:
	await _end_run_and_check_menu(func(s): s.kaiju_killed(), "win")


func test_a_run_lost_on_health_returns_to_the_main_menu() -> void:
	await _end_run_and_check_menu(func(s): s.damage_car(s.max_health), "loss")


func test_a_run_lost_on_the_clock_returns_to_the_main_menu() -> void:
	await _end_run_and_check_menu(func(s): s.advance(RunState.RUN_SECONDS + 1.0), "loss")


func test_a_second_run_from_the_menu_is_fresh() -> void:
	_press(game.menu.start_button)
	game.run.state.add_coins(5)
	game.run.state.damage_car(1.0)
	game.run.state.kaiju_killed()
	await wait_process_frames(2)
	_press(game.menu.start_button)
	var s: RunState = game.run.state
	assert_true(s.is_running())
	assert_eq(s.coins, 0)
	assert_eq(s.health, s.max_health)
	assert_eq(s.time_left_text(), "8:00")
	assert_eq(get_tree().get_nodes_in_group("run_state").size(), 1, "only one run state in the tree")


func test_garage_does_nothing_yet() -> void:
	var menu = game.menu
	_press(menu.garage_button)
	await wait_process_frames(2)
	assert_eq(game.menu, menu, "the same main menu")
	assert_eq(_only_screen(), menu)
	assert_true(menu.is_inside_tree())
	assert_true(menu.visible)
	assert_null(game.run)
	assert_eq(quit_calls, 0)


func test_exit_closes_the_game() -> void:
	_press(game.menu.exit_button)
	assert_eq(quit_calls, 1)


func test_the_default_exit_quits_the_tree() -> void:
	# The real Exit is get_tree().quit(); check it is wired without calling it.
	var fresh: GameFlow = GameFlow.new()
	assert_true(fresh.quit_game.is_valid())
	fresh.free()


func _escape() -> InputEventAction:
	var e := InputEventAction.new()
	e.action = "pause"
	e.pressed = true
	return e


func test_escape_pauses_a_run_started_from_the_menu() -> void:
	_press(game.menu.start_button)
	assert_not_null(game.pause_screen)
	assert_eq(game.pause_screen.get_parent(), game.run)
	assert_false(game.pause_screen.visible)
	game.pause_screen._input(_escape())
	assert_true(get_tree().paused, "Escape pauses")
	assert_true(game.pause_screen.visible)
	var left: float = game.run.state.time_left
	await wait_process_frames(5)
	assert_eq(game.run.state.time_left, left, "the clock stops while paused")
	game.pause_screen._input(_escape())
	assert_false(get_tree().paused, "Escape resumes")
	assert_false(game.pause_screen.visible)


func test_escape_through_the_input_system_pauses_the_run() -> void:
	_press(game.menu.start_button)
	Input.parse_input_event(_escape())
	await wait_process_frames(2)
	assert_true(get_tree().paused, "a real Escape press reaches the pause screen")
	get_tree().paused = false


func test_the_pause_zoom_slider_zooms_the_run() -> void:
	_press(game.menu.start_button)
	var before: Vector2 = game.run.camera.zoom
	game.pause_screen.zoom_slider.value = 8.0
	assert_almost_eq(game.run.zoom, 8.0, 0.0001)
	assert_gt(game.run.camera.zoom.x, before.x, "a smaller size zooms in")


func test_a_run_uses_the_saved_zoom() -> void:
	GameSettings.save_zoom(10.0)
	_press(game.menu.start_button)
	assert_almost_eq(game.run.zoom, 10.0, 0.0001)


func test_escape_on_the_menu_does_not_pause() -> void:
	Input.parse_input_event(_escape())
	await wait_process_frames(2)
	assert_false(get_tree().paused)
	assert_not_null(game.menu)


func test_a_run_ending_while_paused_still_returns_unpaused() -> void:
	_press(game.menu.start_button)
	game.pause_screen.pause()
	game.run.state.kaiju_killed()
	await wait_process_frames(2)
	assert_not_null(game.menu)
	assert_false(get_tree().paused)
