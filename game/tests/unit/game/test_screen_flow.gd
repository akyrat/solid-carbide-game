extends GutTest
## Task T-055: the screen flow. The game opens on the main menu, Start begins
## a fresh run, a won or lost run goes back to the main menu, Garage opens
## the garage screen and its back button returns to the menu, Exit closes the game, and Escape pauses a run started from
## the menu.

const GameScene := preload("res://scenes/game/game.tscn")
var TEST_PATH := RunPaths.file("test_settings_t055.cfg")

var PROGRESS_PATH := RunPaths.file("test_progress_t055.json")

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


func after_each() -> void:
	get_tree().paused = false
	await wait_process_frames(1)  # let screens freed with queue_free() go
	DirAccess.remove_absolute(TEST_PATH)
	TestSave.restore_settings()
	DirAccess.remove_absolute(PROGRESS_PATH)
	TestSave.restore_progress()


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


func test_garage_opens_the_garage_screen() -> void:
	var menu = game.menu
	_press(menu.garage_button)
	await wait_process_frames(2)
	assert_null(game.menu, "the main menu is gone")
	assert_not_null(game.garage)
	assert_true(game.garage is GarageScreen, "the garage screen is on show")
	assert_eq(_only_screen(), game.garage)
	assert_eq(game.garage.progress, game.progress, "it shows the game's saved progress")
	assert_null(game.run)
	assert_eq(quit_calls, 0)


func test_garage_back_returns_to_the_main_menu() -> void:
	_press(game.menu.garage_button)
	await wait_process_frames(2)
	_press(game.garage.back_button)
	await wait_process_frames(2)
	assert_null(game.garage, "the garage is gone")
	assert_true(game.menu is MainMenu, "the main menu is back")
	assert_eq(_only_screen(), game.menu)
	_press(game.menu.start_button)
	await wait_process_frames(1)
	assert_not_null(game.run, "Start still works after the garage")


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


func test_the_zoom_slider_zooms_the_view_at_once_while_a_run_is_paused() -> void:
	_press(game.menu.start_button)
	await wait_physics_frames(3)
	game.pause_screen.pause()
	assert_eq(game.pause_screen.zoom_label.text, "Camera zoom level")
	var remaining: float = game.run.state.time_left
	var pos: Vector2 = game.run.car.position
	var view: Viewport = game.run.get_viewport()
	var before: float = view.get_canvas_transform().get_scale().y
	game.pause_screen.zoom_slider.value = 7.0
	await wait_process_frames(2)
	var zoomed_in: float = view.get_canvas_transform().get_scale().y
	assert_gt(zoomed_in, before, "the view zooms in")
	game.pause_screen.zoom_slider.value = 19.0
	await wait_process_frames(2)
	assert_lt(view.get_canvas_transform().get_scale().y, before, "and out")
	await wait_physics_frames(5)
	assert_true(get_tree().paused)
	assert_eq(game.run.car.position, pos, "the car stays paused")
	assert_almost_eq(game.run.state.time_left, remaining, 1e-9, "the clock stays paused")


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


func test_the_pause_title_does_not_overlap_the_run_timer() -> void:
	_press(game.menu.start_button)
	game.pause_screen.pause()
	await wait_process_frames(2)
	var timer: Label = game.run.hud.timer_label
	var title: Label = game.pause_screen.title_label
	assert_false(timer.get_global_rect().intersects(title.get_global_rect()), "timer and title are apart")


func test_the_pause_strip_is_compact_and_below_the_timer() -> void:
	_press(game.menu.start_button)
	game.pause_screen.pause()
	await wait_process_frames(2)
	var strip: Control = game.pause_screen.strip
	var timer: Label = game.run.hud.timer_label
	var screen_h := float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	assert_false(strip.get_global_rect().intersects(timer.get_global_rect()), "strip and timer are apart")
	assert_lt(strip.size.y, screen_h * 0.30, "the strip is a thin band (room for the SFX volume row, T-077)")
	assert_almost_eq(strip.size.y, strip.get_combined_minimum_size().y, 1.0, "only as tall as its content")
	assert_lt(strip.get_global_rect().end.y, screen_h * 0.45, "most of the map stays visible")


func test_the_camera_settings_come_back_on_resume() -> void:
	_press(game.menu.start_button)
	var cam: Camera2D = game.run.camera
	var mode := cam.process_mode
	var callback := cam.process_callback
	var interp := cam.physics_interpolation_mode
	game.pause_screen.pause()
	assert_eq(cam.process_callback, Camera2D.CAMERA2D_PROCESS_IDLE, "follows every frame while paused")
	assert_eq(cam.physics_interpolation_mode, Node.PHYSICS_INTERPOLATION_MODE_OFF)
	game.pause_screen.resume()
	assert_eq(cam.process_mode, mode)
	assert_eq(cam.process_callback, callback)
	assert_eq(cam.physics_interpolation_mode, interp)


## T-077 (board's tweak, 2026-10-16): the "SFX volume" row is laid out like the zoom row.
func test_the_sfx_slider_is_as_wide_as_the_zoom_slider_on_its_own_row() -> void:
	_press(game.menu.start_button)
	game.pause_screen.pause()
	await wait_process_frames(3)
	var ps = game.pause_screen
	assert_almost_eq(ps.sfx_slider.size.x, ps.zoom_slider.size.x, 1.0, "same width")
	assert_gt(ps.sfx_slider.size.x, 100.0, "room to drag")
	assert_ne(ps.sfx_slider.get_parent(), ps.zoom_slider.get_parent(), "its own row")
	assert_gt(ps.sfx_slider.get_global_rect().position.y, ps.zoom_slider.get_global_rect().end.y - 1.0, "directly under the zoom row")
	assert_lt(ps.sfx_slider.get_global_rect().end.y, ps.smoothing_check.get_global_rect().position.y + 1.0, "above the checkboxes")
	assert_eq(ps.sfx_slider.get_parent().get_child(0), ps.sfx_label, "label first")
	assert_eq(ps.sfx_slider.get_parent().get_child(2), ps._sfx_value_label, "value number at the right end")


func test_a_real_mouse_drag_changes_the_sfx_volume() -> void:
	var win := get_window()
	var old_size := win.size
	win.size = Vector2i(1152, 648)
	_press(game.menu.start_button)
	game.pause_screen.pause()
	await wait_process_frames(3)
	var s: HSlider = game.pause_screen.sfx_slider
	assert_eq(s.value, 0.0)
	var r := s.get_global_rect()
	var y := r.get_center().y
	var steps := [[r.position.x + 2.0, true], [r.position.x + r.size.x * 0.5, null], [r.end.x - 2.0, null], [r.end.x - 2.0, false]]
	for st in steps:
		var pos := Vector2(st[0], y)
		if st[1] == null:
			var m := InputEventMouseMotion.new()
			m.position = pos
			m.global_position = pos
			m.button_mask = MOUSE_BUTTON_MASK_LEFT
			get_viewport().push_input(m)
		else:
			var e := InputEventMouseButton.new()
			e.button_index = MOUSE_BUTTON_LEFT
			e.position = pos
			e.global_position = pos
			e.pressed = st[1]
			get_viewport().push_input(e)
		await wait_process_frames(1)
	win.size = old_size
	assert_gt(s.value, 90.0, "dragged to the right end")
	assert_eq(GameSettings.load_sfx_volume(), s.value, "and saved")
