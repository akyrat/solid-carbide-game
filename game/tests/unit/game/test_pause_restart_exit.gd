extends GutTest
## Task T-327: Restart and Exit on the pause screen.

const GameScene := preload("res://scenes/game/game.tscn")
var TEST_PATH := RunPaths.file("test_settings_t327.cfg")
var PROGRESS_PATH := RunPaths.file("test_progress_t327.json")
var game: Node
var quit_calls := 0


func before_each() -> void:
	GameSettings.path = TEST_PATH
	PlayerProgress.path = PROGRESS_PATH
	DirAccess.remove_absolute(TEST_PATH)
	DirAccess.remove_absolute(PROGRESS_PATH)
	quit_calls = 0
	game = GameScene.instantiate()
	game.quit_game = func(): quit_calls += 1
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()


func after_each() -> void:
	get_tree().paused = false
	await wait_process_frames(1)
	DirAccess.remove_absolute(TEST_PATH)
	TestSave.restore_settings()
	DirAccess.remove_absolute(PROGRESS_PATH)
	TestSave.restore_progress()


func test_buttons_are_labelled_and_focusable() -> void:
	var ps = game.pause_screen
	assert_eq(ps.restart_button.text, "Restart")
	assert_eq(ps.exit_button.text, "Exit")
	assert_ne(ps.restart_button.focus_mode, Control.FOCUS_NONE)
	assert_ne(ps.exit_button.focus_mode, Control.FOCUS_NONE)
	ps.pause()
	assert_true(ps.resume_button.has_focus(), "keyboard focus starts on Resume (T-537)")


func test_restart_starts_a_fresh_run_and_cancels_the_old_one() -> void:
	var old = game.run
	old.state.add_coins(9)
	game.pause_screen.pause()
	game.pause_screen.restart_button.pressed.emit()
	assert_ne(game.run, old)
	assert_true(game.run.state.is_running())
	assert_eq(game.run.state.time_left_text(), "4:00")
	assert_eq(game.run.state.coins, 0)
	assert_eq(game.progress.coins, 0, "the cancelled run's coins are lost (board, 2026-10-30)")
	assert_eq(game.history.count(), 0, "no runs-list entry")
	assert_false(get_tree().paused)
	assert_null(game.menu)


func test_exit_shows_the_menu_unpaused_and_cancels_the_run() -> void:
	game.run.state.add_coins(4)
	game.pause_screen.pause()
	game.pause_screen.exit_button.pressed.emit()
	assert_null(game.run)
	assert_true(game.menu is MainMenu)
	assert_eq(game.progress.coins, 0, "the cancelled run's coins are lost (board, 2026-10-30)")
	assert_eq(game.history.count(), 0, "no runs-list entry")
	assert_false(get_tree().paused)
	assert_eq(quit_calls, 0, "the pause Exit does not close the game")


func test_main_menu_exit_still_closes_the_game() -> void:
	game.pause_screen.exit_button.pressed.emit()
	game.menu.exit_button.pressed.emit()
	assert_eq(quit_calls, 1)
