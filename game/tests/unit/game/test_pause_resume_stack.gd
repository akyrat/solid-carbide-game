extends GutTest
## Task T-537: the pause screen's Resume button and the vertical button column.

const GameScene := preload("res://scenes/game/game.tscn")
var TEST_PATH := RunPaths.file("test_settings_t537.cfg")
var PROGRESS_PATH := RunPaths.file("test_progress_t537.json")
var game: Node


func before_each() -> void:
	GameSettings.path = TEST_PATH
	PlayerProgress.path = PROGRESS_PATH
	DirAccess.remove_absolute(TEST_PATH)
	DirAccess.remove_absolute(PROGRESS_PATH)
	game = GameScene.instantiate()
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()


func after_each() -> void:
	get_tree().paused = false
	await wait_process_frames(1)
	DirAccess.remove_absolute(TEST_PATH)
	TestSave.restore_settings()
	DirAccess.remove_absolute(PROGRESS_PATH)
	TestSave.restore_progress()


func _buttons(ps) -> Array:
	var out: Array = []
	for c in ps._run_row.get_children():
		if c is Button:
			out.append(c)
	return out


func test_resume_text_is_t533s() -> void:
	assert_eq(game.pause_screen.resume_button.text, "Resume")


func test_resume_closes_the_pause_and_the_run_carries_on() -> void:
	var ps = game.pause_screen
	ps.pause()
	assert_true(get_tree().paused)
	ps.resume_button.pressed.emit()
	assert_false(get_tree().paused)
	assert_false(ps.visible)


func test_buttons_are_one_column_resume_first() -> void:
	var ps = game.pause_screen
	ps.pause()
	await wait_process_frames(2)
	var names: Array = []
	for b in _buttons(ps):
		names.append(b.name)
	assert_eq(names[0], &"ResumeButton")
	assert_eq(names.slice(0, 2), [&"ResumeButton", &"TrickListButton"])
	assert_eq(names[names.size() - 2], &"RestartButton")
	assert_eq(names[names.size() - 1], &"ExitButton")
	assert_true(ps._run_row is VBoxContainer, "the buttons sit in a vertical box, one under the other")
	var bs := _buttons(ps)
	for b in bs:
		assert_eq(b.get_parent(), ps._run_row)
		assert_almost_eq(b.global_position.x, bs[0].global_position.x, 1.0, "one column")


func test_keyboard_order_follows_the_column() -> void:
	var ps = game.pause_screen
	ps.pause()
	var bs := _buttons(ps)
	assert_true(bs[0].has_focus())
	for i in bs.size():
		var down: Button = bs[i].get_node(bs[i].focus_neighbor_bottom)
		assert_eq(down, bs[(i + 1) % bs.size()], "Down from %s" % bs[i].name)
		var up: Button = bs[i].get_node(bs[i].focus_neighbor_top)
		assert_eq(up, bs[(i - 1 + bs.size()) % bs.size()])


func test_god_mode_entry_joins_the_column_last() -> void:
	var ps = game.pause_screen
	GodMode.unlocked = true
	ps.pause()
	var bs := _buttons(ps)
	assert_eq(bs[bs.size() - 1].name, &"GodModeButton")
	assert_eq(bs[bs.size() - 1].get_node(bs[bs.size() - 1].focus_neighbor_bottom), bs[0])
	GodMode.unlocked = false


func test_strip_fits_the_window_at_1280x720() -> void:
	var ps = game.pause_screen
	ps.pause()
	await wait_process_frames(2)
	var bottom: float = ps.strip.global_position.y + ps.strip.size.y
	assert_lt(bottom, 720.0 * 1.0, "strip bottom %s" % bottom)
