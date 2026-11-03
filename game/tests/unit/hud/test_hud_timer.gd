extends GutTest
## Task T-090: the HUD shows the run timer as M:SS and stops while paused.

const RUN := preload("res://scenes/run/run.tscn")


func after_each() -> void:
	get_tree().paused = false


func _run() -> Node2D:
	var r: Node2D = RUN.instantiate()
	add_child_autofree(r)
	return r


func test_hud_is_in_the_run_and_starts_at_8_00() -> void:
	var r := _run()
	assert_not_null(r.hud)
	assert_eq(r.hud.timer_label.text, "4:00")


func test_timer_follows_the_run_from_4_00_to_0_00() -> void:
	var r := _run()
	var cases := {RunState.RUN_SECONDS: "4:00", 239.5: "4:00", 180.0: "3:00", 179.0: "2:59", 61.0: "1:01",
		60.0: "1:00", 9.0: "0:09", 1.0: "0:01", 0.4: "0:01", 0.0: "0:00"}
	for left in cases:
		r.state.advance(r.state.time_left - left)
		assert_eq(r.hud.timer_label.text, cases[left], "time left %s" % left)
	assert_eq(r.hud.timer_label.text, r.state.time_left_text())


func test_timer_resets_with_a_fresh_run() -> void:
	var r := _run()
	r.state.advance(100.0)
	assert_ne(r.hud.timer_label.text, "4:00")
	r.start_run()
	assert_eq(r.hud.timer_label.text, "4:00")


func test_timer_stops_while_paused() -> void:
	var r := _run()
	await wait_process_frames(10)
	assert_lt(r.state.time_left, RunState.RUN_SECONDS, "the clock runs while not paused")
	assert_eq(r.hud.timer_label.text, r.state.time_left_text())
	get_tree().paused = true
	var frozen: float = r.state.time_left
	var shown: String = r.hud.timer_label.text
	await wait_process_frames(30)
	assert_eq(r.state.time_left, frozen, "paused: the clock does not move")
	assert_eq(r.hud.timer_label.text, shown, "paused: the timer does not move")
	get_tree().paused = false
	r.state.advance(2.0)
	assert_ne(r.hud.timer_label.text, shown, "unpaused: it runs again")


func test_timer_shows_in_a_run_started_from_the_main_menu() -> void:
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	game.quit_game = func(): pass
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()
	await wait_process_frames(2)
	var hud: Hud = game.run.hud
	assert_not_null(hud)
	assert_true(hud.is_inside_tree() and hud.timer_label.is_visible_in_tree())
	game.run.state.advance(65.0)
	assert_eq(hud.timer_label.text, "2:55")
