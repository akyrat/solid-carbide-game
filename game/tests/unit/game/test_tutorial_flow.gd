extends GutTest
## Task T-387: the main menu's Start shows the tutorial slides before the run, unless the player
## ticked "Don't show again". The run only exists once the slides' Start is pressed. The pause
## screen's Restart starts a fresh run directly. Saves go to test files (T-148).

const GameScene := preload("res://scenes/game/game.tscn")
var TEST_PATH := RunPaths.file("test_settings_t387.cfg")
var PROGRESS_PATH := RunPaths.file("test_progress_t387.json")

var game: Node


func before_each() -> void:
	GameFlow.tutorial_enabled = true
	GameSettings.path = TEST_PATH
	PlayerProgress.path = PROGRESS_PATH
	DirAccess.remove_absolute(TEST_PATH)
	DirAccess.remove_absolute(PROGRESS_PATH)
	game = _new_game()


func after_each() -> void:
	GameFlow.tutorial_enabled = false
	get_tree().paused = false
	await wait_process_frames(1)
	DirAccess.remove_absolute(TEST_PATH)
	TestSave.restore_settings()
	DirAccess.remove_absolute(PROGRESS_PATH)
	TestSave.restore_progress()


func _new_game() -> Node:
	var g = GameScene.instantiate()
	g.quit_game = func(): pass
	add_child_autofree(g)
	return g


func _screens(g: Node) -> Array:
	return g.get_children().filter(func(c): return c != g.music)


## Goes to slide 4 with the arrows, sets the checkbox and presses the slides' Start.
func _finish_slides(tick: bool) -> void:
	var t: TutorialSlides = game.tutorial
	t.right_arrow.pressed.emit()
	t.right_arrow.pressed.emit()
	t.right_arrow.pressed.emit()
	assert_eq(t.current, 3, "on the last slide")
	t.dont_show_checkbox.button_pressed = tick
	t.start_button.pressed.emit()


func test_start_shows_the_slides_and_no_run() -> void:
	watch_signals(game)
	game.menu.start_button.pressed.emit()
	await wait_process_frames(1)
	assert_signal_emitted(game, "tutorial_shown")
	assert_signal_not_emitted(game, "run_shown")
	assert_not_null(game.tutorial)
	assert_true(game.tutorial is TutorialSlides)
	assert_eq(_screens(game), [game.tutorial], "only the slides are on screen")
	assert_null(game.menu, "the menu is gone")
	assert_null(game.run, "no run while the slides are up")
	assert_eq(get_tree().get_nodes_in_group("run_state").size(), 0, "no run state in the tree")


func test_the_clock_does_not_start_while_the_slides_are_up() -> void:
	game.menu.start_button.pressed.emit()
	await wait_seconds(2.0)  # several seconds' worth of frames with the slides on screen
	await wait_physics_frames(30)
	assert_null(game.run, "still no run")
	_finish_slides(false)
	await wait_process_frames(1)
	assert_not_null(game.run, "the slides' Start begins the run")
	var s: RunState = game.run.state
	assert_eq(s.time_left_text(), "4:00", "the clock starts full: it did not tick during the slides")
	assert_almost_eq(s.time_left, RunState.RUN_SECONDS, 0.1)
	assert_true(s.is_running())


func test_the_slides_start_begins_the_run() -> void:
	game.menu.start_button.pressed.emit()
	var slides = game.tutorial
	watch_signals(game)
	_finish_slides(false)
	await wait_process_frames(1)
	assert_signal_emitted(game, "run_shown")
	assert_null(game.tutorial, "the slides are gone")
	assert_false(is_instance_valid(slides) and slides.is_inside_tree(), "the slides left the tree")
	assert_eq(_screens(game), [game.run], "only the run")
	assert_not_null(game.pause_screen, "the run has its pause screen")
	await wait_seconds(1.0)
	assert_lt(game.run.state.time_left, RunState.RUN_SECONDS, "the clock runs now")


func test_ticked_saves_hidden_and_the_next_start_skips_the_slides() -> void:
	assert_false(GameSettings.load_tutorial_hidden(), "shown by default")
	game.menu.start_button.pressed.emit()
	_finish_slides(true)
	assert_true(GameSettings.load_tutorial_hidden(), "the tick is saved")
	var cfg := ConfigFile.new()
	assert_eq(cfg.load(TEST_PATH), OK, "written to the test file, not the real save")
	assert_eq(cfg.get_value("tutorial", "hidden"), true)
	# As after restarting the game: a new game reads the settings from the file.
	game.queue_free()
	await wait_process_frames(1)
	game = _new_game()
	watch_signals(game)
	game.menu.start_button.pressed.emit()
	await wait_process_frames(1)
	assert_signal_not_emitted(game, "tutorial_shown")
	assert_null(game.tutorial, "no slides")
	assert_not_null(game.run, "straight into the run")
	assert_true(game.run.state.is_running())
	assert_eq(game.run.state.time_left_text(), "4:00")


func test_hidden_also_skips_after_returning_to_the_menu() -> void:
	game.menu.start_button.pressed.emit()
	_finish_slides(true)
	game.pause_screen.exit_button.pressed.emit()
	assert_not_null(game.menu)
	game.menu.start_button.pressed.emit()
	assert_null(game.tutorial)
	assert_not_null(game.run)


func test_unticked_leaves_it_false_and_the_slides_come_again() -> void:
	game.menu.start_button.pressed.emit()
	_finish_slides(false)
	assert_false(GameSettings.load_tutorial_hidden(), "not saved as hidden")
	game.queue_free()
	await wait_process_frames(1)
	game = _new_game()
	game.menu.start_button.pressed.emit()
	await wait_process_frames(1)
	assert_not_null(game.tutorial, "the slides show again")
	assert_null(game.run)


func test_pause_restart_starts_a_fresh_run_without_the_slides() -> void:
	game.menu.start_button.pressed.emit()
	_finish_slides(false)
	var old = game.run
	old.state.add_coins(3)
	watch_signals(game)
	game.pause_screen.pause()
	game.pause_screen.restart_button.pressed.emit()
	await wait_process_frames(1)
	assert_signal_not_emitted(game, "tutorial_shown")
	assert_null(game.tutorial, "no slides on Restart")
	assert_ne(game.run, old, "a fresh run")
	assert_true(game.run.state.is_running())
	assert_eq(game.run.state.time_left_text(), "4:00")
	assert_eq(game.run.state.coins, 0)
	assert_false(get_tree().paused)
	assert_false(GameSettings.load_tutorial_hidden(), "Restart does not hide the slides")


func test_the_tests_do_not_use_the_real_save() -> void:
	assert_false(TestSave.touches_real_save())
