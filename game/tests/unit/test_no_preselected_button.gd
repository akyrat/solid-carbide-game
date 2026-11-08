extends GutTest
## T-573: no button looks selected when a menu opens. The first arrow, Tab, W, A, S or D selects the
## screen's first button; Enter or Space either does the same or keeps what it did before (the main
## menu starts the run, the tutorial presses its default button). Mouse hover is not touched.

const GameScene := preload("res://scenes/game/game.tscn")
const RunScene := preload("res://scenes/run/run.tscn")
const PauseScript := preload("res://scripts/ui/pause_screen.gd")
var PATH := RunPaths.file("test_no_preselected_t573.json")
var SETTINGS_PATH := RunPaths.file("test_no_preselected_t573.cfg")
var _old_size := Vector2i.ZERO


func before_each() -> void:
	GodMode.unlocked = false
	GameSettings.path = SETTINGS_PATH
	PlayerProgress.path = PATH
	DirAccess.remove_absolute(SETTINGS_PATH)
	DirAccess.remove_absolute(PATH)
	_old_size = get_tree().root.size
	get_tree().root.size = Vector2i(1152, 648)


func after_each() -> void:
	GodMode.unlocked = false
	get_tree().paused = false
	await wait_process_frames(1)
	get_tree().root.size = _old_size
	DirAccess.remove_absolute(SETTINGS_PATH)
	DirAccess.remove_absolute(PATH)
	TestSave.restore_settings()
	TestSave.restore_progress()


func _key(code: Key, pressed := true) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = pressed
	return e


func _press(code: Key) -> void:
	get_viewport().push_input(_key(code, true))
	get_viewport().push_input(_key(code, false))


func _focus() -> Control:
	return get_viewport().gui_get_focus_owner()


func _progress(coins: int) -> PlayerProgress:
	var p := PlayerProgress.new(null, PATH)
	p.coins = coins
	return p


func _garage() -> GarageScreen:
	var g: GarageScreen = load("res://scenes/menu/garage_screen.tscn").instantiate()
	g.progress = _progress(100000)
	add_child_autofree(g)
	return g


func _cosmetics() -> CosmeticsScreen:
	var s: CosmeticsScreen = load("res://scenes/menu/cosmetics_screen.tscn").instantiate()
	s.progress = _progress(100000)
	add_child_autofree(s)
	return s


func _settings() -> SettingsScreen:
	var s: SettingsScreen = load("res://scenes/menu/settings_screen.tscn").instantiate()
	add_child_autofree(s)
	return s


func _menu() -> MainMenu:
	var m: MainMenu = load("res://scenes/menu/main_menu.tscn").instantiate()
	add_child_autofree(m)
	return m


func _slides():
	var slides = load("res://scenes/menu/tutorial_slides.tscn").instantiate()
	add_child_autofree(slides)
	slides.practice_scene_path = "res://nonexistent.tscn"
	return slides


func _game_paused() -> Node:
	var game := GameScene.instantiate()
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()
	game.pause_screen.pause()
	return game


# --- The helper ---------------------------------------------------------------------------------

func test_every_move_key_selects_the_start_button() -> void:
	for code in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_TAB, KEY_W, KEY_A, KEY_S, KEY_D]:
		var g := _garage()
		assert_null(_focus())
		_press(code)
		assert_eq(_focus(), g.start_button(), "key %d" % code)
		g.free()
		await wait_process_frames(1)


func test_a_held_key_does_not_select() -> void:
	_garage()
	var e := _key(KEY_DOWN)
	e.echo = true
	get_viewport().push_input(e)
	assert_null(_focus())


# --- Screens ------------------------------------------------------------------------------------

func test_garage_opens_with_nothing_selected_and_the_first_press_shows_the_start() -> void:
	var g := _garage()
	assert_null(_focus())
	_press(KEY_DOWN)
	assert_eq(_focus(), g.rows[GarageData.UPGRADES[0]].buy, "the first press stays on the first Buy")
	_press(KEY_DOWN)
	assert_eq(_focus(), g.rows[GarageData.UPGRADES[1]].buy, "then it moves")


func test_garage_enter_with_nothing_selected_only_shows_the_selection() -> void:
	var g := _garage()
	var coins := g.progress.get_coins()
	_press(KEY_ENTER)
	assert_eq(_focus(), g.start_button())
	assert_eq(g.progress.get_coins(), coins, "nothing was bought")


func test_cosmetics_opens_with_nothing_selected_and_the_first_press_shows_the_start() -> void:
	var s := _cosmetics()
	assert_null(_focus())
	_press(KEY_TAB)
	assert_eq(_focus(), s.focus_order()[0])
	_press(KEY_DOWN)
	assert_eq(_focus(), s.focus_order()[1])


func test_main_menu_opens_with_nothing_selected_and_the_first_press_selects_start() -> void:
	var m := _menu()
	watch_signals(m)
	assert_null(_focus())
	_press(KEY_DOWN)
	assert_eq(_focus(), m.start_button)
	assert_signal_not_emitted(m, "start_pressed")
	_press(KEY_DOWN)
	assert_eq(_focus(), m.garage_button)


func test_main_menu_enter_with_nothing_selected_starts_the_run() -> void:
	var m := _menu()
	watch_signals(m)
	_press(KEY_ENTER)
	assert_signal_emitted(m, "start_pressed")
	assert_null(_focus())


func test_main_menu_space_with_nothing_selected_starts_the_run() -> void:
	var m := _menu()
	watch_signals(m)
	_press(KEY_SPACE)
	assert_signal_emitted(m, "start_pressed")


func test_a_hidden_main_menu_ignores_the_keys() -> void:
	var m := _menu()
	m.visible = false
	_press(KEY_DOWN)
	assert_null(_focus())


func test_settings_opens_with_nothing_selected_and_the_first_press_selects_back() -> void:
	var s := _settings()
	await wait_process_frames(1)
	assert_null(_focus())
	_press(KEY_DOWN)
	assert_eq(_focus(), s.back_button)
	_press(KEY_DOWN)
	assert_eq(_focus(), s.checkboxes()[0])


func test_settings_enter_with_nothing_selected_does_not_leave() -> void:
	var s := _settings()
	watch_signals(s)
	_press(KEY_ENTER)
	assert_signal_not_emitted(s, "back_pressed")
	assert_eq(_focus(), s.back_button)


func test_tutorial_opens_with_nothing_selected() -> void:
	var slides = _slides()
	assert_null(_focus())
	_press(KEY_DOWN)
	assert_eq(_focus(), slides.right_arrow, "the first press selects the right arrow")


func test_tutorial_enter_with_nothing_selected_goes_to_the_next_slide() -> void:
	var slides = _slides()
	_press(KEY_ENTER)
	assert_eq(slides.current, 1, "what Enter did before: press the right arrow")
	assert_null(_focus())


func test_tutorial_selection_follows_the_slides_once_a_key_made_it() -> void:
	var slides = _slides()
	_press(KEY_TAB)
	slides.show_slide(5)
	assert_true(slides.start_button.has_focus())


func test_pause_opens_with_nothing_selected_and_the_first_press_selects_resume() -> void:
	var game := _game_paused()
	var ps = game.pause_screen
	assert_null(_focus())
	_press(KEY_DOWN)
	assert_eq(_focus(), ps.resume_button)
	_press(KEY_DOWN)
	assert_ne(_focus(), ps.resume_button)


func test_pause_enter_with_nothing_selected_does_not_resume() -> void:
	var game := _game_paused()
	_press(KEY_ENTER)
	assert_true(get_tree().paused)
	assert_eq(_focus(), game.pause_screen.resume_button)


func test_pause_opened_a_second_time_clears_the_old_selection() -> void:
	var game := _game_paused()
	var ps = game.pause_screen
	_press(KEY_DOWN)
	assert_not_null(_focus())
	ps.resume()
	ps.pause()
	assert_null(_focus())


func test_trick_list_opens_with_nothing_selected_and_back_returns_with_none() -> void:
	var game := _game_paused()
	var ps = game.pause_screen
	ps.open_trick_list()
	assert_null(_focus())
	_press(KEY_DOWN)
	assert_eq(_focus(), ps.trick_back_button)
	ps.close_trick_list()
	assert_null(_focus())


func test_god_mode_page_opens_with_nothing_selected() -> void:
	var game := _game_paused()
	var ev := InputEventAction.new()
	ev.action = "god_mode_unlock"
	ev.pressed = true
	game.run.god_mode._unhandled_input(ev)
	game.pause_screen.pause()
	game.pause_screen.god_mode_button.pressed.emit()
	var page: GodModePage = game.pause_screen.god_mode_page
	assert_null(_focus())
	_press(KEY_DOWN)
	assert_eq(_focus(), page.back_button)
	page.close()
	assert_null(_focus())


func test_hud_layout_editor_opens_with_nothing_selected() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	var ps: CanvasLayer = PauseScript.new()
	run.add_child(ps)
	ps.setup(run)
	ps.pause()
	ps.open_hud_layout()
	assert_null(_focus())
	_press(KEY_TAB)
	assert_eq(_focus(), ps.hud_layout_editor.done_button)
	ps.hud_layout_editor.finish()
	assert_null(_focus())


func test_level_up_power_up_and_recap_screens_never_grab_focus() -> void:
	# They take their keys themselves (cards, Enter) and their buttons take no focus.
	for path in ["res://scripts/ui/level_up_screen.gd", "res://scripts/ui/power_up_screen.gd", "res://scripts/ui/recap_screen.gd"]:
		assert_eq(FileAccess.get_file_as_string(path).count("grab_focus"), 0, path)
