extends GutTest
## Task T-083: the HUD's combo counter and the combo amount on trick popups,
## with the approved texts from T-082.

const RUN := preload("res://scenes/run/run.tscn")


func _run() -> Node2D:
	var r: Node2D = RUN.instantiate()
	add_child_autofree(r)
	return r


func test_counter_shows_the_multiplier_with_the_label() -> void:
	var r := _run()
	var hud: Hud = r.hud
	assert_eq(hud.combo_label.text, "Combo x1.0")
	r.state.add_trick("alternate_drift")
	assert_eq(hud.combo_label.text, "Combo x1.5")
	r.state.add_trick("three_sixty")
	assert_eq(hud.combo_label.text, "Combo x1.75")
	r.state.add_trick("extended_drift")
	assert_eq(hud.combo_label.text, "Combo x1.8")
	r.state.collision()
	assert_eq(hud.combo_label.text, Hud.combo_text(r.state.combo))
	assert_lt(r.state.combo, 1.8)


func test_counter_holds_at_the_cap() -> void:
	var r := _run()
	for i in 40:
		r.state.add_trick("alternate_drift")
	assert_eq(r.hud.combo_label.text, "Combo x6.0")


func test_counter_is_right_of_the_likes_row_and_clear_of_the_rest() -> void:
	var r := _run()
	await get_tree().process_frame
	var hud: Hud = r.hud
	var c := hud.combo_label.get_global_rect()
	assert_gt(c.position.x, hud.likes_row.get_global_rect().end.x, "right of the likes row")
	assert_false(c.intersects(hud.timer_label.get_global_rect()), "clear of the timer")
	assert_false(c.intersects(hud.coins_label.get_global_rect()), "clear of the coins")
	assert_false(c.intersects(hud.health_bar.get_global_rect()), "clear of the health bar")


func test_counter_is_not_red() -> void:
	var r := _run()
	var col: Color = r.hud.combo_label.get_theme_color("font_color")
	assert_ne(col, Hud.HEART_COLOR)
	assert_true(col.g > 0.2 or col.b > 0.5, "not a red")


func test_each_trick_popup_shows_the_amount_added() -> void:
	var r := _run()
	var expect := {
		"extended_drift": "LONG DRIFT! +0.05",
		"three_sixty": "FULL 360! +0.25",
		"alternate_drift": "ALT DRIFT! +0.5",
	}
	for id in expect:
		r.state.combo = 1.0
		var before: int = r.trick_popups.popups().size()
		r.car.trick.emit(id)
		var shown: Array = r.trick_popups.popups()
		assert_eq(shown.size(), before + 1, "%s: one popup, not two" % id)
		assert_eq(shown.back().text, expect[id])


func test_popup_at_the_cap_shows_only_the_name() -> void:
	var r := _run()
	r.state.combo = 6.0
	r.car.trick.emit("three_sixty")
	assert_eq(r.trick_popups.popups().back().text, "FULL 360!")


func test_popup_text_helper() -> void:
	assert_eq(TrickPopups.trick_text("three_sixty", 0.25), "FULL 360! +0.25")
	assert_eq(TrickPopups.trick_text("three_sixty", 0.0), "FULL 360!")
	assert_eq(TrickPopups.trick_text("nope", 1.0), "")
