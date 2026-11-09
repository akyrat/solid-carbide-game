extends GutTest
## Task T-612, round 2 (HUD and menus, Decisions, "God mode can spawn the boss"; texts T-614):
## the God mode page's "Call the kaiju" button. It makes the kaiju arrive at once by the boss
## time's own arrival, with the run's time left unchanged; once per run (disabled and reading
## the "used" text after the press or once the kaiju arrived on its own, enabled again in a new
## run); the boss time coming later brings no second kaiju; keys and T-573 still work.

const GameScene := preload("res://scenes/game/game.tscn")
const KaijuBossScript := preload("res://scripts/enemies/kaiju_boss.gd")
var TEST_PATH := RunPaths.file("test_settings_t612.cfg")
var PROGRESS_PATH := RunPaths.file("test_progress_t612.json")
var game: Node


func before_each() -> void:
	GodMode.unlocked = false
	KaijuBossScript.playtest_override = -1.0  # the kaiju only at the boss time (or the button)
	GameSettings.path = TEST_PATH
	PlayerProgress.path = PROGRESS_PATH
	DirAccess.remove_absolute(TEST_PATH)
	DirAccess.remove_absolute(PROGRESS_PATH)
	game = GameScene.instantiate()
	add_child_autofree(game)
	game.start_run()
	game.run.minions.enabled = false


func after_each() -> void:
	GodMode.unlocked = false
	KaijuBossScript.playtest_override = -2.0
	get_tree().paused = false
	await wait_process_frames(1)
	DirAccess.remove_absolute(TEST_PATH)
	TestSave.restore_settings()
	DirAccess.remove_absolute(PROGRESS_PATH)
	TestSave.restore_progress()


func _open() -> GodModePage:
	var ev := InputEventAction.new()
	ev.action = "god_mode_unlock"
	ev.pressed = true
	game.run.god_mode._unhandled_input(ev)
	game.pause_screen.pause()
	game.pause_screen.god_mode_button.pressed.emit()
	return game.pause_screen.god_mode_page


func _kaijus() -> int:
	return get_tree().get_nodes_in_group("kaiju").size()


func _text(key: String) -> String:
	return GodModePage.pause_text(key)


func _key(code: int) -> InputEventKey:
	var k := InputEventKey.new()
	k.keycode = code
	k.physical_keycode = code
	k.pressed = true
	return k


func test_the_button_has_t614s_text_and_calls_the_kaiju_at_once_with_the_time_unchanged() -> void:
	var page := _open()
	var b: Button = page.spawn_boss_button
	assert_not_null(b)
	assert_eq(b.text, _text("god_mode_spawn_boss"))
	assert_eq(b.text, "Call the kaiju", "T-614's text, word for word")
	assert_true(HudStyle.is_shared_button(b), "the shared small button")
	assert_false(b.disabled)
	assert_eq(b.get_parent(), page.back_button.get_parent(), "on Back's row")
	assert_lt(b.get_index(), page.back_button.get_index(), "left of Back")
	var boss: Node = game.run.kaiju_boss
	var state: Node = game.run.state
	assert_false(state.boss_time_sent, "before the boss time")
	assert_eq(_kaijus(), 0)
	var left: float = state.time_left
	b.pressed.emit()
	assert_not_null(boss.kaiju, "the kaiju arrived at once")
	assert_true(boss.has_appeared())
	assert_eq(_kaijus(), 1)
	assert_eq(state.time_left, left, "the run's time left is unchanged")
	assert_false(state.boss_time_sent, "the clock was not moved to the boss time")
	# The boss time's own arrival: on the map, clear of obstacles, just beyond the visible screen.
	var at: Vector2 = boss.kaiju.position_units()
	assert_true(boss.is_free_spot(at), "a free spot, as at the boss time")
	var screen_pos: Vector2 = boss.ISO_TRANSFORM * (at * 16.0)
	assert_false(boss.visible_rect().has_point(screen_pos), "it walks in from off-screen")


func test_the_button_works_once_per_run() -> void:
	var page := _open()
	var b: Button = page.spawn_boss_button
	b.pressed.emit()
	assert_true(b.disabled, "disabled after the press")
	assert_eq(b.text, _text("god_mode_spawn_boss_used"))
	assert_eq(b.text, "Kaiju is here", "T-614's text, word for word")
	var k: Node = game.run.kaiju_boss.kaiju
	b.pressed.emit()  # a second press does nothing
	assert_eq(game.run.kaiju_boss.kaiju, k, "the same kaiju")
	assert_false(game.run.god_mode.spawn_boss(), "nothing more to call")
	assert_eq(_kaijus(), 1, "still one kaiju")
	# A new run: enabled again.
	page.back_button.pressed.emit()
	game.run.start_run()
	game.run.minions.enabled = false
	await wait_process_frames(2)
	game.pause_screen.open_god_mode()
	assert_false(b.disabled, "enabled again in a new run")
	assert_eq(b.text, _text("god_mode_spawn_boss"))


func test_the_button_is_disabled_once_the_kaiju_arrived_on_its_own() -> void:
	var state: Node = game.run.state
	state.advance(RunState.RUN_SECONDS - RunState.BOSS_TIME_LEFT + 0.01)
	assert_true(game.run.kaiju_boss.has_appeared(), "the boss time brought it")
	var page := _open()
	assert_true(page.spawn_boss_button.disabled)
	assert_eq(page.spawn_boss_button.text, _text("god_mode_spawn_boss_used"))
	page.spawn_boss_button.pressed.emit()
	assert_eq(_kaijus(), 1)


func test_the_boss_time_after_the_button_brings_no_second_kaiju() -> void:
	var page := _open()
	page.spawn_boss_button.pressed.emit()
	var k: Node = game.run.kaiju_boss.kaiju
	page.back_button.pressed.emit()
	get_tree().paused = false
	var state: Node = game.run.state
	state.advance(RunState.RUN_SECONDS - RunState.BOSS_TIME_LEFT - state.time_elapsed() + 0.01)
	assert_true(state.boss_time_sent, "the boss time came")
	for i in 5:
		game.run.kaiju_boss.step(0.02)
	assert_eq(game.run.kaiju_boss.kaiju, k, "the same kaiju")
	assert_eq(_kaijus(), 1, "no second kaiju")


func test_keys_reach_the_button_and_nothing_is_selected_at_open() -> void:
	var page := _open()
	assert_null(page.get_viewport().gui_get_focus_owner(), "T-573: nothing selected at open")
	var s: Button = page.spawn_boss_button
	var back: Button = page.back_button
	var n: int = page.rows.size()
	assert_eq(back.get_node(back.focus_neighbor_left), s)
	assert_eq(back.get_node(back.focus_neighbor_right), s)
	assert_eq(s.get_node(s.focus_neighbor_right), back)
	assert_eq(s.get_node(s.focus_neighbor_top), page.rows[n - 1].minus)
	assert_eq(s.get_node(s.focus_neighbor_bottom), page.rows[0].minus)
	assert_eq(page.rows[n - 1].minus.get_node(page.rows[n - 1].minus.focus_neighbor_bottom), s)
	back.grab_focus()
	page._unhandled_key_input(_key(KEY_A))
	assert_true(s.has_focus(), "A (left) from Back reaches the button")
	s.pressed.emit()  # what Enter, Space and the controller's accept do on a focused button
	assert_not_null(game.run.kaiju_boss.kaiju)
