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
	r.state.add_trick("extended_drift", 1.0)
	assert_eq(hud.combo_label.text, "Combo x1.8")
	r.state.collision()
	assert_eq(hud.combo_label.text, Hud.combo_text(r.state.combo))
	assert_lt(r.state.combo, 1.8)


func test_counter_holds_at_the_cap() -> void:
	var r := _run()
	for i in 40:
		r.state.add_trick("alternate_drift")
	assert_eq(r.hud.combo_label.text, "Combo x6.0")


func test_counter_is_centred_above_the_likes_row_and_clear_of_the_rest() -> void:
	# Headless, the root viewport is only 64x64: lay the run out in a window-sized one.
	var sv := SubViewport.new()
	sv.size = Vector2i(1152, 648)
	add_child_autofree(sv)
	var r: Node2D = RUN.instantiate()
	sv.add_child(r)
	await get_tree().process_frame
	var hud: Hud = r.hud
	var c := hud.combo_label.get_global_rect()
	var bar := hud.likes_bar.get_global_rect()
	assert_almost_eq(c.get_center().x, bar.get_center().x, 1.0, "centred over the likes bar (T-113)")
	assert_lte(c.end.y, hud.likes_row.get_global_rect().position.y, "above the likes row")
	assert_false(c.intersects(hud.timer_label.get_global_rect()), "clear of the timer")
	assert_false(c.intersects(hud.coins_label.get_global_rect()), "clear of the coins")
	assert_false(c.intersects(hud.health_bar.get_global_rect()), "clear of the health bar")
	assert_false(c.intersects(bar), "clear of the likes bar")
	for l: Control in [hud.health_heart, hud.weapon_icons, hud.likes_row, hud.level_label]:
		assert_false(c.intersects(l.get_global_rect()), "clear of %s" % l.name)


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
		r.car.tricks.last_trick_seconds = 1.0 if id == "extended_drift" else 0.0  # a 1 s drift (T-246)
		r.car.trick.emit(id)
		var shown: Array = r.trick_popups.popups()
		# Since T-125 round 2 an older popup may make room under the screen-height
		# limit, so count the popups with this trick's text, not all of them.
		var same: Array = shown.filter(func(p) -> bool: return p.text == expect[id])
		assert_eq(same.size(), 1, "%s: one popup, not two" % id)
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
