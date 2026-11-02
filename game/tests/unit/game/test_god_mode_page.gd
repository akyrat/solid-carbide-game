extends GutTest
## Task T-505: the God mode entry in the pause screen's settings and its page.

const GameScene := preload("res://scenes/game/game.tscn")
var TEST_PATH := RunPaths.file("test_settings_t505.cfg")
var PROGRESS_PATH := RunPaths.file("test_progress_t505.json")
var game: Node


func before_each() -> void:
	GodMode.unlocked = false
	GameSettings.path = TEST_PATH
	PlayerProgress.path = PROGRESS_PATH
	DirAccess.remove_absolute(TEST_PATH)
	DirAccess.remove_absolute(PROGRESS_PATH)
	game = GameScene.instantiate()
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()


func after_each() -> void:
	GodMode.unlocked = false
	get_tree().paused = false
	await wait_process_frames(1)
	DirAccess.remove_absolute(TEST_PATH)
	TestSave.restore_settings()
	DirAccess.remove_absolute(PROGRESS_PATH)
	TestSave.restore_progress()


func _unlock() -> void:
	var ev := InputEventAction.new()
	ev.action = "god_mode_unlock"
	ev.pressed = true
	game.run.god_mode._unhandled_input(ev)


func _key(code: int) -> InputEventKey:
	var k := InputEventKey.new()
	k.keycode = code
	k.physical_keycode = code
	k.pressed = true
	return k


func _open() -> GodModePage:
	_unlock()
	game.pause_screen.pause()
	game.pause_screen.god_mode_button.pressed.emit()
	return game.pause_screen.god_mode_page


func test_no_entry_before_n_and_the_entry_after() -> void:
	var ps = game.pause_screen
	ps.pause()
	assert_null(ps.god_mode_button, "no God mode entry before N")
	assert_null(ps.find_child("GodModeButton", true, false))
	_unlock()
	assert_not_null(ps.god_mode_button, "the entry is there once N was pressed")
	assert_eq(ps.god_mode_button.text, "God mode")
	assert_true(HudStyle.is_shared_button(ps.god_mode_button))
	assert_eq(ps.god_mode_button.get_parent().get_child(-1), ps.god_mode_button, "at the end")


func test_entry_opens_the_page_and_back_closes_it() -> void:
	var page := _open()
	assert_true(page.is_open())
	assert_false(game.pause_screen.strip.visible)
	assert_true(page.back_button.has_focus())
	assert_eq(page.find_child("Title", true, false).text, "God mode")
	assert_eq(page.find_child("Subtitle", true, false).text, "Set each weapon's and power-up's tier for this run.")
	assert_eq(page.back_button.text, "Back")
	page.back_button.pressed.emit()
	assert_false(page.is_open())
	assert_true(game.pause_screen.strip.visible)
	assert_true(game.pause_screen.god_mode_button.has_focus())


func test_rows_come_from_the_entries_all_six_weapons_and_the_power_ups() -> void:
	var page := _open()
	var entries: Array = game.run.god_mode.entries()
	assert_eq(page.rows.size(), entries.size())
	var weapons := 0
	var power_ups := 0
	for i in entries.size():
		assert_eq(page.rows[i].id, entries[i].id)
		if entries[i].kind == "weapon":
			weapons += 1
		else:
			power_ups += 1
		assert_ne(page.rows[i].name_label.text, "", "%s has a name" % entries[i].id)
	assert_eq(weapons, 6)
	assert_eq(power_ups, PowerUpData.new().ids().size())
	assert_gte(power_ups, 4)
	assert_eq(page.find_child("Heading_weapon", true, false).text, "Weapons")
	assert_eq(page.find_child("Heading_power_up", true, false).text, "Driving power-ups")


func test_tier_text_format() -> void:
	assert_eq(GodModePage.tier_text(0, 8), "Not owned")
	assert_eq(GodModePage.tier_text(3, 8), "Tier 3 / 8")


func test_minus_and_plus_set_the_tier_within_the_limits() -> void:
	var page := _open()
	var god: Node = game.run.god_mode
	var gun: Dictionary = page.rows[0]
	assert_eq(gun.id, "gun")
	assert_eq(god.current_tier("weapon", "gun"), 1)
	gun.minus.pressed.emit()
	assert_eq(god.current_tier("weapon", "gun"), 1, "the gun never goes below tier 1")
	gun.plus.pressed.emit()
	assert_eq(god.current_tier("weapon", "gun"), 2)
	assert_eq(gun.tier_label.text, "Tier 2 / %d" % god.last_tier("weapon", "gun"), "shown straight away")
	for r in page.rows:
		if r.kind == "weapon" and r.id != "gun":
			assert_eq(r.tier_label.text, "Not owned")
			r.minus.pressed.emit()
			assert_eq(god.current_tier(r.kind, r.id), 0, "never below 0")
			r.plus.pressed.emit()
			assert_eq(god.current_tier(r.kind, r.id), 1)
			assert_eq(r.tier_label.text, "Tier 1 / %d" % god.last_tier(r.kind, r.id))
			r.minus.pressed.emit()
			assert_eq(god.current_tier(r.kind, r.id), 0)
		elif r.kind == "power_up":
			var last: int = god.last_tier(r.kind, r.id)
			for i in last + 2:
				r.plus.pressed.emit()
			assert_eq(god.current_tier(r.kind, r.id), last, "%s stops at its last tier" % r.id)
			assert_eq(game.run.state.power_up_tier(r.id), last)
			r.minus.pressed.emit()
			assert_eq(god.current_tier(r.kind, r.id), last - 1)


func test_keyboard_navigation_and_press() -> void:
	var page := _open()
	var first: Dictionary = page.rows[0]
	var n: int = page.rows.size()
	assert_eq(page.back_button.get_node(page.back_button.focus_neighbor_bottom), first.plus)
	assert_eq(page.back_button.get_node(page.back_button.focus_neighbor_top), page.rows[n - 1].plus)
	assert_eq(first.plus.get_node(first.plus.focus_neighbor_left), first.minus)
	assert_eq(first.minus.get_node(first.minus.focus_neighbor_right), first.plus)
	assert_eq(first.plus.get_node(first.plus.focus_neighbor_bottom), page.rows[1].plus)
	assert_eq(page.rows[n - 1].plus.get_node(page.rows[n - 1].plus.focus_neighbor_bottom), page.back_button)
	# S moves to the first plus, then Enter (ui_accept) presses it.
	page.back_button.grab_focus()
	page._unhandled_key_input(_key(KEY_S))
	assert_true(first.plus.has_focus())
	var before: int = game.run.god_mode.current_tier("weapon", "gun")
	var accept := InputEventAction.new()
	accept.action = "ui_accept"
	accept.pressed = true
	assert_true(first.plus.has_focus())
	first.plus.pressed.emit()  # what Enter and Space do on a focused button
	assert_eq(game.run.god_mode.current_tier("weapon", "gun"), before + 1)
	page._unhandled_key_input(_key(KEY_A))
	assert_true(first.minus.has_focus())


func test_escape_closes_the_page_and_buttons_are_shared() -> void:
	var page := _open()
	for b in [page.back_button, page.rows[0].minus, page.rows[0].plus]:
		assert_true(HudStyle.is_shared_button(b))
	var esc := InputEventAction.new()
	esc.action = "pause"
	esc.pressed = true
	game.pause_screen._input(esc)
	assert_false(page.is_open())
	assert_true(get_tree().paused, "still paused behind the settings")


func test_no_placeholder_text_in_the_page() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/ui/god_mode_page.gd")
	for bad in ["TODO", "placeholder text", "Lorem", "TBD"]:
		assert_false(src.contains(bad), bad)
	var page := _open()
	for r in page.rows:
		assert_ne(r.name_label.text.strip_edges(), "")
		assert_ne(r.tier_label.text.strip_edges(), "")
