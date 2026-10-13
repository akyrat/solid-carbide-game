extends GutTest
## Task T-116: the combo counter is hidden at "no combo" (combo.json's
## start_multiplier), shows as soon as a trick raises the multiplier, hides
## again once the combo has drained back, and hiding it moves nothing else.

const RUN := preload("res://scenes/run/run.tscn")
const GAME := preload("res://scenes/game/game.tscn")


func _no_combo() -> float:
	return ComboData.new().start_multiplier()


## A run in a window-sized viewport (headless, the root viewport is 64x64).
func _run() -> Node2D:
	var sv := SubViewport.new()
	sv.size = Vector2i(1152, 648)
	add_child_autofree(sv)
	var r: Node2D = RUN.instantiate()
	sv.add_child(r)
	return r


## Every other HUD element's place on screen, by name.
func _others(hud: Hud) -> Dictionary:
	return {
		"health bar": hud.health_bar.get_global_rect(),
		"Car Health": hud.health_label.get_global_rect(),
		"likes bar": hud.likes_bar.get_global_rect(),
		"likes row": hud.likes_row.get_global_rect(),
		"heart": hud.heart.get_global_rect(),
		"Likes": hud.likes_label.get_global_rect(),
		"Hype Lv": hud.level_label.get_global_rect(),
		"timer": hud.timer_label.get_global_rect(),
		"coins": hud.coins_label.get_parent().get_global_rect(),
	}


func test_no_combo_value_comes_from_the_combo_data() -> void:
	var r := _run()
	var hud: Hud = r.hud
	var s := _no_combo()
	assert_false(hud.show_combo(s), "hidden at combo.json's start value")
	assert_true(hud.show_combo(s + 0.05), "shown just above it")
	assert_true(hud.show_combo(s + 5.0), "shown at the cap")


func test_hidden_at_the_start_of_a_run() -> void:
	var r := _run()
	await get_tree().process_frame
	assert_eq(r.state.combo, _no_combo())
	assert_false(r.hud.combo_label.visible, "hidden with no combo")


func test_shown_after_a_trick_with_the_right_text() -> void:
	var r := _run()
	var hud: Hud = r.hud
	r.state.add_trick("alternate_drift")
	assert_true(hud.combo_label.visible, "shown after a trick")
	assert_true(hud.combo_label.is_visible_in_tree())
	assert_eq(hud.combo_label.text, "Combo x1.5")
	r.state.add_trick("extended_drift")
	assert_true(hud.combo_label.visible)
	assert_eq(hud.combo_label.text, "Combo x1.55")


func test_even_the_smallest_trick_shows_it() -> void:
	var r := _run()
	r.state.add_trick("extended_drift")
	assert_true(r.hud.combo_label.visible)
	assert_eq(r.hud.combo_label.text, "Combo x1.05")


func test_hidden_again_once_drained_back() -> void:
	var r := _run()
	var hud: Hud = r.hud
	r.state.add_trick("alternate_drift")
	assert_true(hud.combo_label.visible)
	r.state.advance(2.5)  # the 2 second wait, then 0.25 drained
	assert_true(hud.combo_label.visible, "still shown while draining")
	assert_eq(hud.combo_label.text, "Combo x1.25")
	r.state.advance(1.0)  # drains to the start value
	assert_eq(r.state.combo, _no_combo())
	assert_false(hud.combo_label.visible, "hidden once drained back")
	r.state.add_trick("three_sixty")
	assert_true(hud.combo_label.visible, "shown again by the next trick")
	assert_eq(hud.combo_label.text, "Combo x1.25")


func test_a_collision_keeps_it_shown_while_above_no_combo() -> void:
	var r := _run()
	r.state.add_trick("alternate_drift")
	r.state.add_trick("alternate_drift")
	r.state.collision()  # 2.0 -> 1.2
	assert_gt(r.state.combo, _no_combo())
	assert_true(r.hud.combo_label.visible)
	assert_eq(r.hud.combo_label.text, Hud.combo_text(r.state.combo))


func test_hidden_again_in_a_new_run() -> void:
	var r := _run()
	r.state.add_trick("alternate_drift")
	assert_true(r.hud.combo_label.visible)
	r.state.start_run()
	assert_false(r.hud.combo_label.visible, "a new run starts with no combo")


func test_hiding_moves_nothing_else() -> void:
	var r := _run()
	var hud: Hud = r.hud
	await get_tree().process_frame
	assert_false(hud.combo_label.visible)
	var hidden := _others(hud)
	var combo_hidden := hud.combo_label.get_global_rect()
	r.state.add_trick("alternate_drift")
	await get_tree().process_frame
	assert_true(hud.combo_label.visible)
	var shown := _others(hud)
	for n: String in hidden:
		assert_eq(shown[n], hidden[n], "%s stays put when the counter shows" % n)
	assert_almost_eq(hud.combo_label.get_global_rect().get_center().x,
		combo_hidden.get_center().x, 1.0, "the counter shows where it was")
	r.state.advance(10.0)
	await get_tree().process_frame
	assert_false(hud.combo_label.visible)
	var again := _others(hud)
	for n: String in hidden:
		assert_eq(again[n], hidden[n], "%s stays put when the counter hides" % n)


func test_in_a_run_started_from_the_main_menu() -> void:
	var sv := SubViewport.new()
	sv.size = Vector2i(1152, 648)
	add_child_autofree(sv)
	var game: Node = GAME.instantiate()
	game.quit_game = func(): pass
	sv.add_child(game)
	game.menu.start_button.pressed.emit()
	await wait_process_frames(2)
	var hud: Hud = game.run.hud
	assert_false(hud.combo_label.is_visible_in_tree(), "hidden with no combo")
	assert_true(hud.likes_bar.is_visible_in_tree(), "the likes bar still shows")
	game.run.state.add_trick("three_sixty")
	assert_true(hud.combo_label.is_visible_in_tree(), "shown with a combo")
