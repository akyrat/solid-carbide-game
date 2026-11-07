extends GutTest
## Task T-571: the Settings screen opened from the main menu (HUD and menus, Decisions, "A Settings
## screen from the main menu"). Its button, its exact settings, Back and Escape, the saves shared with
## the pause screen, and the music heard at once. Uses a test settings file, never the real one.

var SETTINGS_PATH := RunPaths.file("test_settings_t571.cfg")


func before_each() -> void:
	GameSettings.path = SETTINGS_PATH
	DirAccess.remove_absolute(SETTINGS_PATH)


func after_each() -> void:
	GameSettings.sfx_enabled_override = -1
	get_tree().paused = false
	DirAccess.remove_absolute(SETTINGS_PATH)
	TestSave.restore_settings()
	GameSettings.apply_sfx_volume(GameSettings.load_sfx_volume())
	GameSettings.apply_music_volume(GameSettings.load_music_volume())


func _flow() -> GameFlow:
	var f := GameFlow.new()
	add_child_autofree(f)
	return f


func _screen() -> SettingsScreen:
	var s: SettingsScreen = load("res://scenes/menu/settings_screen.tscn").instantiate()
	add_child_autofree(s)
	return s


func _heard(bus_name: String) -> float:
	var i := AudioServer.get_bus_index(bus_name)
	return 0.0 if AudioServer.is_bus_mute(i) else db_to_linear(AudioServer.get_bus_volume_db(i))


## The names of every control the player can see and use on `root`.
func _visible_controls(root: Node) -> Array:
	var out: Array = []
	for n in root.find_children("*", "Control", true, false):
		if (n is Range or n is BaseButton) and n.is_visible_in_tree():
			out.append(str(n.name))
	out.sort()
	return out


func _escape() -> void:
	var e := InputEventAction.new()
	e.action = "pause"
	e.pressed = true
	get_viewport().push_input(e)
	var up := InputEventAction.new()
	up.action = "pause"
	up.pressed = false
	get_viewport().push_input(up)


func test_main_menu_has_the_settings_button_from_t570() -> void:
	var f := _flow()
	assert_not_null(f.menu.settings_button)
	assert_eq(f.menu.settings_button.text, "Settings", "settings_button in data/pause_text.json")
	assert_true(HudStyle.is_shared_button(f.menu.settings_button), "the shared button")
	var column: Node = f.menu.settings_button.get_parent()
	assert_eq(f.menu.settings_button.get_index(), f.menu.cosmetics_button.get_index() + 1, "after Cosmetics")
	assert_eq(f.menu.exit_button.get_index(), f.menu.settings_button.get_index() + 1, "before Exit")
	assert_not_null(column)


func test_button_opens_the_screen_and_back_returns() -> void:
	var f := _flow()
	f.menu.settings_button.pressed.emit()
	assert_null(f.menu)
	assert_true(f.settings is SettingsScreen)
	assert_eq(f.settings.title_label.text, "Settings", "settings_title")
	assert_eq(f.settings.back_button.text, "Back", "settings_back")
	f.settings.back_button.pressed.emit()
	assert_null(f.settings)
	assert_not_null(f.menu, "Back returns to the main menu")


func test_escape_returns_to_the_main_menu() -> void:
	var f := _flow()
	f.menu.settings_button.pressed.emit()
	await wait_process_frames(1)
	_escape()
	await wait_process_frames(1)
	assert_null(f.settings, "Escape closes the screen")
	assert_not_null(f.menu, "and shows the main menu")
	assert_false(get_tree().paused, "never pauses the tree")


func test_exactly_the_listed_settings_with_the_switch_off() -> void:
	GameSettings.sfx_enabled_override = 0
	var s := _screen()
	assert_eq(_visible_controls(s), ["BackButton", "DriftGuideCheck", "DynamicCheck", "JumpArrowCheck",
		"MusicSlider", "RainCheck", "SmoothingCheck", "ZoomSlider"])
	assert_false(s.sfx_row.visible, "no SFX volume while the sound effects are off (T-389)")


func test_sfx_volume_shows_when_the_switch_is_on() -> void:
	GameSettings.sfx_enabled_override = 1
	var s := _screen()
	assert_eq(_visible_controls(s), ["BackButton", "DriftGuideCheck", "DynamicCheck", "JumpArrowCheck",
		"MusicSlider", "RainCheck", "SfxSlider", "SmoothingCheck", "ZoomSlider"])


func test_labels_are_the_pause_screens() -> void:
	var s := _screen()
	assert_eq(s.zoom_label.text, "Camera zoom level")
	assert_eq(s.music_slider.get_parent().get_child(0).text, "Music volume")
	assert_eq(s.smoothing_check.text, "Camera smoothing")
	assert_eq(s.dynamic_check.text, "Dynamic camera")
	assert_eq(s.rain_check.text, SettingsScreen.text("rain_label"))
	assert_eq(s.drift_guide_check.text, SettingsScreen.text("drift_guide_label"))
	assert_eq(s.jump_arrow_check.text, SettingsScreen.text("jump_arrow_label"))
	for c in s.checkboxes():
		assert_eq(c.get_meta("hud_button", ""), "checkbox", "the shared checkbox")
	assert_true(HudStyle.is_shared_button(s.back_button))
	assert_eq(s.music_slider.min_value, 0.0)
	assert_eq(s.music_slider.max_value, 100.0)
	assert_eq(s.zoom_slider.min_value, GameSettings.MIN_ZOOM)
	assert_eq(s.zoom_slider.max_value, GameSettings.MAX_ZOOM)


func test_values_are_read_from_the_saved_settings_at_open() -> void:
	GameSettings.save_zoom(9.5)
	GameSettings.save_music_volume(65.0)
	GameSettings.save_camera_smoothing(true)
	GameSettings.save_rain_enabled(true)
	GameSettings.save_jump_arrow_enabled(false)
	var s := _screen()
	assert_eq(s.zoom_slider.value, 9.5)
	assert_eq(s.zoom_value_label.text, "9.5")
	assert_eq(s.music_slider.value, 65.0)
	assert_eq(s.music_value_label.text, "65")
	assert_true(s.smoothing_check.button_pressed)
	assert_false(s.dynamic_check.button_pressed)
	assert_true(s.rain_check.button_pressed)
	assert_false(s.drift_guide_check.button_pressed)
	assert_false(s.jump_arrow_check.button_pressed)


func test_music_is_heard_at_once_and_saved_on_release() -> void:
	var s := _screen()
	var writes := GameSettings.slider_writes
	s.music_slider.value = 80.0
	assert_almost_eq(_heard(GameSettings.MUSIC_BUS), 0.8, 0.001, "the menu's music follows at once")
	assert_eq(GameSettings.slider_writes, writes, "not saved while dragging (T-427)")
	s.music_slider.value = 25.0
	s.music_slider.drag_ended.emit(true)
	assert_eq(GameSettings.slider_writes, writes + 1, "one write on release")
	assert_eq(GameSettings.load_music_volume(), 25.0)
	assert_almost_eq(_heard(GameSettings.MUSIC_BUS), 0.25, 0.001)


func test_a_slider_change_is_saved_on_back() -> void:
	var s := _screen()
	s.zoom_slider.value = 7.0
	s.music_slider.value = 12.0
	assert_eq(GameSettings.load_zoom(), GameSettings.DEFAULT_ZOOM, "not yet saved")
	s.back_button.pressed.emit()
	assert_eq(GameSettings.load_zoom(), 7.0, "saved on Back")
	assert_eq(GameSettings.load_music_volume(), 12.0)


func test_checkboxes_save_at_once() -> void:
	var s := _screen()
	s.smoothing_check.button_pressed = true
	s.dynamic_check.button_pressed = true
	s.rain_check.button_pressed = true
	s.drift_guide_check.button_pressed = true
	s.jump_arrow_check.button_pressed = false
	assert_true(GameSettings.load_camera_smoothing())
	assert_true(GameSettings.load_dynamic_camera())
	assert_true(GameSettings.load_rain_enabled())
	assert_true(GameSettings.load_drift_guide_enabled())
	assert_false(GameSettings.load_jump_arrow_enabled())


func test_changes_show_on_the_pause_screen_in_the_next_run_and_after_a_restart() -> void:
	var f := _flow()
	f.menu.settings_button.pressed.emit()
	var s: SettingsScreen = f.settings
	s.zoom_slider.value = 8.0
	s.music_slider.value = 55.0
	s.smoothing_check.button_pressed = true
	s.dynamic_check.button_pressed = true
	s.rain_check.button_pressed = true
	s.drift_guide_check.button_pressed = true
	s.jump_arrow_check.button_pressed = false
	s.back_button.pressed.emit()
	f.start_run()
	var ps = f.pause_screen
	assert_almost_eq(float(ps.zoom_slider.value), 8.0, 0.001, "the run's zoom")
	assert_eq(ps.music_slider.value, 55.0)
	assert_true(ps.smoothing_check.button_pressed)
	assert_true(ps.dynamic_check.button_pressed)
	assert_true(ps.rain_check.button_pressed)
	assert_true(ps.drift_guide_check.button_pressed)
	assert_false(ps.jump_arrow_check.button_pressed)
	f.queue_free()
	await wait_process_frames(1)
	# The game closed and opened again: a fresh flow reads the same file.
	var g := _flow()
	g.menu.settings_button.pressed.emit()
	var again: SettingsScreen = g.settings
	assert_almost_eq(again.zoom_slider.value, 8.0, 0.001)
	assert_eq(again.music_slider.value, 55.0)
	assert_true(again.smoothing_check.button_pressed)
	assert_true(again.dynamic_check.button_pressed)
	assert_true(again.rain_check.button_pressed)
	assert_true(again.drift_guide_check.button_pressed)
	assert_false(again.jump_arrow_check.button_pressed)


func test_a_pause_screen_change_shows_on_the_settings_screen() -> void:
	var f := _flow()
	f.start_run()
	var ps = f.pause_screen
	ps.music_slider.value = 33.0
	ps.rain_check.button_pressed = true
	ps.save_pending()
	f.show_menu()
	f.menu.settings_button.pressed.emit()
	assert_eq(f.settings.music_slider.value, 33.0)
	assert_true(f.settings.rain_check.button_pressed)


func test_keyboard_reaches_every_checkbox_and_back() -> void:
	var s := _screen()
	await wait_process_frames(1)
	assert_eq(get_viewport().gui_get_focus_owner(), s.back_button, "Back has the focus at open")
	var first: CheckBox = s.checkboxes()[0]
	assert_eq(s.back_button.get_node(s.back_button.focus_neighbor_top), first)
	var c: Control = first
	for i in s.checkboxes().size() - 1:
		c = c.get_node(c.focus_neighbor_right)
	assert_eq(c, s.jump_arrow_check, "Right walks the five checkboxes")
	assert_eq(c.get_node(c.focus_neighbor_bottom), s.back_button)
