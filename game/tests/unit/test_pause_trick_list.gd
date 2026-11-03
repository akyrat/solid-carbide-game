extends GutTest
## Task T-386: the trick list button and panel on the pause screen.

const GameScene := preload("res://scenes/game/game.tscn")
var TEST_PATH := RunPaths.file("test_settings_t386.cfg")
var PROGRESS_PATH := RunPaths.file("test_progress_t386.json")
var game: Node
var ps


func before_each() -> void:
	GameSettings.path = TEST_PATH
	PlayerProgress.path = PROGRESS_PATH
	DirAccess.remove_absolute(TEST_PATH)
	DirAccess.remove_absolute(PROGRESS_PATH)
	game = GameScene.instantiate()
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()
	ps = game.pause_screen
	ps.pause()


func after_each() -> void:
	get_tree().paused = false
	await wait_process_frames(1)
	DirAccess.remove_absolute(TEST_PATH)
	TestSave.restore_settings()
	DirAccess.remove_absolute(PROGRESS_PATH)
	TestSave.restore_progress()


func _escape() -> void:
	var ev := InputEventAction.new()
	ev.action = "pause"
	ev.pressed = true
	ps._input(ev)


func test_button_text_is_from_the_file_and_panel_starts_hidden() -> void:
	assert_eq(ps.trick_list_button.text, TrickList.text("button.trick_list"))
	assert_ne(ps.trick_list_button.text, "")
	assert_false(ps.is_trick_list_open())
	assert_true(ps.strip.visible)


func test_pressing_opens_panel_with_seven_tricks_only() -> void:
	ps.trick_list_button.pressed.emit()
	assert_true(ps.is_trick_list_open())
	assert_false(ps.strip.visible)
	assert_eq(ps.trick_list.scene_file_path, "res://scenes/menu/trick_list.tscn")
	assert_eq(ps.trick_list.labels.size(), 7)
	for id in TrickList.TRICK_IDS:
		assert_eq(ps.trick_list.labels[id].text, TrickList.text("trick." + id))
	for key in ["slide2.chain", "slide2.gift"]:
		for l in ps.trick_panel.find_children("*", "Label", true, false):
			assert_ne(l.text, TrickList.text(key))
	assert_eq(ps.trick_back_button.text, TrickList.text("button.back"))
	assert_true(get_tree().paused)


func test_back_returns_with_controls_unchanged_and_stays_paused() -> void:
	ps.zoom_slider.value = 9.0
	ps.sfx_slider.value = 33
	ps.music_slider.value = 77
	ps.smoothing_check.set_pressed_no_signal(true)
	ps.dynamic_check.set_pressed_no_signal(true)
	ps.trick_list_button.pressed.emit()
	ps.trick_back_button.pressed.emit()
	assert_false(ps.is_trick_list_open())
	assert_true(ps.strip.visible)
	assert_true(get_tree().paused)
	assert_eq(ps.zoom_slider.value, 9.0)
	assert_eq(ps.sfx_slider.value, 33.0)
	assert_eq(ps.music_slider.value, 77.0)
	assert_true(ps.smoothing_check.button_pressed)
	assert_true(ps.dynamic_check.button_pressed)
	assert_true(ps.trick_list_button.has_focus())


func test_escape_goes_back_instead_of_resuming() -> void:
	ps.trick_list_button.pressed.emit()
	_escape()
	assert_false(ps.is_trick_list_open())
	assert_true(ps.visible)
	assert_true(get_tree().paused, "Escape in the panel does not resume")
	_escape()
	assert_false(get_tree().paused, "a second Escape resumes")


func test_keyboard_focus_moves_to_back_and_returns() -> void:
	ps.trick_list_button.grab_focus()
	assert_true(ps.trick_list_button.has_focus())
	ps.trick_list_button.pressed.emit()
	assert_true(ps.trick_back_button.has_focus(), "Enter or Space on Back closes it")


func test_panel_fits_and_clears_the_hud_timer() -> void:
	# The headless window is tiny; measure at the game's own size.
	var old_size := get_tree().root.size
	get_tree().root.size = Vector2i(1152, 648)
	ps.trick_list_button.pressed.emit()
	await wait_process_frames(3)
	var screen := Rect2(Vector2.ZERO, Vector2(1152, 648))
	var r: Rect2 = ps.trick_panel.get_global_rect()
	assert_true(screen.encloses(r), "panel %s inside %s" % [r, screen])
	var hud = game.run.hud
	var clock: Rect2 = hud.timer_clock.get_global_rect()
	assert_false(r.intersects(clock), "panel %s clear of clock %s" % [r, clock])
	get_tree().root.size = old_size


func test_trick_list_clip_is_loaded_only_while_the_panel_shows() -> void:
	ps.trick_list_button.pressed.emit()
	await wait_process_frames(2)
	assert_not_null(ps.trick_list.clip_player.sheet, "loaded while the panel is open")
	ps.close_trick_list()
	await wait_process_frames(2)
	assert_null(ps.trick_list.clip_player.sheet, "freed when the panel is hidden")


func test_panel_fits_with_the_recipe_and_clip() -> void:
	var old_size := get_tree().root.size
	get_tree().root.size = Vector2i(1152, 648)
	ps.trick_list_button.pressed.emit()
	for id in TrickList.TRICK_IDS:
		ps.trick_list.select(id)
		await wait_process_frames(2)
		var r: Rect2 = ps.trick_panel.get_global_rect()
		assert_true(Rect2(Vector2.ZERO, Vector2(1152, 648)).encloses(r), "%s: %s" % [id, r])
	get_tree().root.size = old_size
