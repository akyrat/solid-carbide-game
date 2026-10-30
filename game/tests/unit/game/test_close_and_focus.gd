extends GutTest
## Task T-416: closing the window mid-run ends the run as a loss (coins banked, runs-list
## entry) before the game quits; losing focus pauses the run, except during the level-up
## choice and the time's up screen. Game loop architecture, Decisions, "Closing the game mid-run".

const GameScene := preload("res://scenes/game/game.tscn")
var TEST_PATH := RunPaths.file("test_settings_t416.cfg")
var PROGRESS_PATH := RunPaths.file("test_progress_t416.json")
var HISTORY_PATH := RunPaths.file("test_history_t416.json")

var game: Node
var quit_calls := 0


func before_each() -> void:
	GameSettings.path = TEST_PATH
	PlayerProgress.path = PROGRESS_PATH
	RunHistory.path = HISTORY_PATH
	for p in [TEST_PATH, PROGRESS_PATH, HISTORY_PATH]:
		DirAccess.remove_absolute(p)
	quit_calls = 0
	game = GameScene.instantiate()
	game.quit_game = func(): quit_calls += 1
	add_child_autofree(game)


func after_each() -> void:
	get_tree().paused = false
	await wait_process_frames(1)
	for p in [TEST_PATH, PROGRESS_PATH, HISTORY_PATH]:
		DirAccess.remove_absolute(p)
	TestSave.restore_settings()
	TestSave.restore_progress()
	RunHistory.path = TestSave.history_path()


func _start() -> RunState:
	game.menu.start_button.pressed.emit()
	await wait_process_frames(1)
	return game.run.state


func test_close_during_a_run_banks_coins_logs_a_loss_and_quits() -> void:
	var s := await _start()
	s.add_coins(7)
	game.notification(NOTIFICATION_WM_CLOSE_REQUEST)
	assert_eq(s.result, "loss")
	assert_eq(game.progress.get_coins(), 7, "the coins were banked")
	assert_eq(game.history.count(), 1, "one run in the runs list")
	assert_eq(game.history.runs()[0]["result"], "loss")
	assert_eq(game.history.runs()[0]["coins"], 7)
	assert_eq(quit_calls, 1)


func test_close_during_the_wreck_loses_the_run_and_keeps_coins() -> void:
	var s := await _start()
	s.add_coins(3)
	s.damage_car(s.max_health)
	assert_true(s.is_wrecked())
	game.notification(NOTIFICATION_WM_CLOSE_REQUEST)
	assert_eq(s.result, "loss")
	assert_eq(game.progress.get_coins(), 3)
	assert_eq(game.history.count(), 1)
	assert_eq(quit_calls, 1)


func test_close_during_the_time_up_screen_logs_the_run_once() -> void:
	var s := await _start()
	s.add_coins(2)
	s.advance(s.time_left + 1.0)
	assert_true(s.is_timed_out())
	game.notification(NOTIFICATION_WM_CLOSE_REQUEST)
	assert_eq(game.history.count(), 1)
	assert_eq(game.progress.get_coins(), 2)
	assert_eq(quit_calls, 1)


func test_close_after_the_run_ended_does_not_log_it_twice() -> void:
	var s := await _start()
	s.kaiju_killed()
	game.notification(NOTIFICATION_WM_CLOSE_REQUEST)
	assert_eq(s.result, "win", "a won run stays won")
	assert_eq(game.history.count(), 1)
	assert_eq(quit_calls, 1)


func test_close_outside_a_run_just_quits() -> void:
	game.notification(NOTIFICATION_WM_CLOSE_REQUEST)
	assert_eq(quit_calls, 1)
	assert_eq(game.history.count(), 0)
	assert_eq(game.progress.get_coins(), 0)


func test_focus_out_during_a_run_opens_the_pause_screen() -> void:
	await _start()
	game.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_true(game.pause_screen.is_paused())
	assert_true(game.pause_screen.visible)
	game.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_true(game.pause_screen.is_paused(), "a second focus out keeps it paused")


func test_focus_out_does_nothing_during_the_level_up_choice() -> void:
	var s := await _start()
	s.pause_on_level_up = true
	s.add_xp(s.xp_needed())
	assert_true(s.is_waiting_for_choice())
	var was_visible: bool = game.pause_screen.visible
	game.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_eq(game.pause_screen.visible, was_visible, "the pause screen did not open")
	assert_true(s.is_waiting_for_choice())


func test_focus_out_does_nothing_during_the_time_up_screen() -> void:
	var s := await _start()
	s.advance(s.time_left + 1.0)
	assert_true(s.is_timed_out())
	game.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_false(game.pause_screen.visible)


func test_focus_out_outside_a_run_does_nothing() -> void:
	game.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_false(get_tree().paused)
