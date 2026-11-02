extends GutTest
## Task T-508: the pause screen's rain checkbox (saved setting rain_enabled).

const SCENE := preload("res://scenes/drift_prototype/drift_prototype.tscn")
var TEST_PATH := RunPaths.file("test_settings_t508.cfg")


func before_each() -> void:
	GameSettings.path = TEST_PATH
	DirAccess.remove_absolute(TEST_PATH)


func after_each() -> void:
	get_tree().paused = false
	DirAccess.remove_absolute(TEST_PATH)
	TestSave.restore_settings()


func _ps():
	var p: Node2D = SCENE.instantiate()
	add_child_autofree(p)
	p.car.use_keyboard = false
	return p.pause_screen


func test_label_from_data_and_checked_by_default() -> void:
	var ps = _ps()
	assert_eq(ps.rain_check.text, ps.pause_text("rain_label"))
	assert_ne(ps.rain_check.text, "")
	assert_true(ps.rain_check.button_pressed)
	assert_eq(ps.rain_check.get_parent(), ps.dynamic_check.get_parent(), "next to the camera checkboxes")


func test_toggle_saves_and_survives_a_restart() -> void:
	var ps = _ps()
	ps.rain_check.button_pressed = false
	assert_false(GameSettings.load_rain_enabled())
	var ps2 = _ps()
	assert_false(ps2.rain_check.button_pressed, "a new screen reads the saved choice")
	ps2.rain_check.button_pressed = true
	assert_true(GameSettings.load_rain_enabled())


func _open() -> Object:
	var ps = _ps()
	ps.pause()
	await wait_process_frames(3)
	return ps


func _click(c: Control) -> void:
	for down in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = down
		ev.position = c.get_global_rect().get_center()
		ev.global_position = ev.position
		get_viewport().push_input(ev)
		await wait_process_frames(1)


func test_mouse_click_toggles() -> void:
	var win := get_window()
	var old_size := win.size
	win.size = Vector2i(1152, 648)
	var ps = await _open()
	await _click(ps.rain_check)
	var off_ok: bool = not GameSettings.load_rain_enabled()
	await _click(ps.rain_check)
	var on_ok: bool = GameSettings.load_rain_enabled()
	win.size = old_size
	assert_true(off_ok, "a click switches the rain off and saves it")
	assert_true(on_ok, "a second click switches it on")


func test_keyboard_accept_toggles() -> void:
	var ps = await _open()
	assert_ne(ps.rain_check.focus_mode, Control.FOCUS_NONE, "reachable by keyboard")
	ps.rain_check.grab_focus()
	for down in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = KEY_SPACE
		ev.physical_keycode = KEY_SPACE
		ev.pressed = down
		ps.rain_check.get_viewport().push_input(ev)
		await wait_process_frames(1)
	assert_false(GameSettings.load_rain_enabled())


func test_rain_in_a_run_hides_at_once() -> void:
	var game = preload("res://scenes/game/game.tscn").instantiate()
	add_child_autofree(game)
	game.start_run()
	var run = game.run if "run" in game else null
	if run == null:
		pending("no run node")
		return
	var ps = game.pause_screen
	ps.rain_check.button_pressed = false
	assert_false(run.rain.visible)
	ps.rain_check.button_pressed = true
	assert_true(run.rain.visible)
