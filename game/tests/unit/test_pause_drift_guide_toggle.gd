extends GutTest
## Task T-518: the pause screen's Drift Guide checkbox (saved setting drift_guide_enabled).

const SCENE := preload("res://scenes/drift_prototype/drift_prototype.tscn")
var TEST_PATH := RunPaths.file("test_settings_t518.cfg")


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


func test_label_from_data_and_unticked_by_default() -> void:
	var ps = _ps()
	assert_eq(ps.drift_guide_check.text, ps.pause_text("drift_guide_label"))
	assert_ne(ps.drift_guide_check.text, "")
	assert_false(ps.drift_guide_check.button_pressed, "a new player starts with no guide")
	assert_eq(ps.drift_guide_check.get_parent(), ps.rain_check.get_parent(), "next to the Rain checkbox")
	assert_eq(ps.drift_guide_check.text, "Drift Guide")


func test_toggle_saves_and_survives_a_restart() -> void:
	var ps = _ps()
	ps.drift_guide_check.button_pressed = true
	assert_true(GameSettings.load_drift_guide_enabled())
	var ps2 = _ps()
	assert_true(ps2.drift_guide_check.button_pressed, "a new screen reads the saved choice")
	ps2.drift_guide_check.button_pressed = false
	assert_false(GameSettings.load_drift_guide_enabled())


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
	await _click(ps.drift_guide_check)
	var on_ok: bool = GameSettings.load_drift_guide_enabled()
	await _click(ps.drift_guide_check)
	var off_ok: bool = not GameSettings.load_drift_guide_enabled()
	win.size = old_size
	assert_true(off_ok, "a click switches the guide on and saves it")
	assert_true(on_ok, "a second click switches it off")


func test_keyboard_accept_toggles() -> void:
	var ps = await _open()
	assert_ne(ps.drift_guide_check.focus_mode, Control.FOCUS_NONE, "reachable by keyboard")
	ps.drift_guide_check.grab_focus()
	for down in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = KEY_SPACE
		ev.physical_keycode = KEY_SPACE
		ev.pressed = down
		ps.drift_guide_check.get_viewport().push_input(ev)
		await wait_process_frames(1)
	assert_true(GameSettings.load_drift_guide_enabled())




func test_toggle_applies_at_once_through_the_notifier() -> void:
	var ps = _ps()
	watch_signals(GameSettings.notifier)
	ps.drift_guide_check.button_pressed = true
	assert_signal_emitted_with_parameters(GameSettings.notifier, "drift_guide_enabled_changed", [true])
	ps.drift_guide_check.button_pressed = false
	assert_signal_emitted_with_parameters(GameSettings.notifier, "drift_guide_enabled_changed", [false])


func test_saved_true_shows_ticked() -> void:
	GameSettings.save_drift_guide_enabled(true)
	assert_true(_ps().drift_guide_check.button_pressed)
