extends GutTest
## Task T-245: the combo broken popup, a red cracked card with T-244's text,
## shown when a crash cuts a combo that was going (not with no combo, not when
## the combo drains away).

const RunScene := preload("res://scenes/run/run.tscn")
const Popups := preload("res://scripts/hud/trick_popups.gd")
const Art := preload("res://scripts/hud/combo_broken_art.gd")
const Hud := preload("res://scripts/hud/hud.gd")


func _run() -> Node2D:
	var r: Node2D = RunScene.instantiate()
	add_child_autofree(r)
	return r


func _broken(r: Node2D) -> Array:
	return r.trick_popups.popups().filter(func(p): return p.broken)


func test_text_is_the_approved_one() -> void:
	assert_eq(Popups.BROKEN_TEXT, "COMBO BROKEN!")


func test_popup_appears_when_a_crash_cuts_a_combo() -> void:
	var r := _run()
	r.state.add_trick("alternate_drift")
	assert_eq(_broken(r).size(), 0, "a trick shows no broken popup")
	r.state.collision()
	var shown := _broken(r)
	assert_eq(shown.size(), 1)
	assert_eq(shown[0].text, "COMBO BROKEN!")


func test_any_damage_cuts_the_combo_and_shows_it() -> void:
	var r := _run()
	r.state.add_trick("alternate_drift")
	r.state.damage_car(1.0)
	assert_eq(_broken(r).size(), 1)


func test_a_hit_on_an_obstacle_shows_it() -> void:
	var r := _run()
	r.state.add_trick("three_sixty")
	r._on_car_hit_obstacle(null, 0, Vector2.UP, 100.0)
	assert_eq(_broken(r).size(), 1)


func test_no_popup_when_there_is_no_combo() -> void:
	var r := _run()
	assert_true(r.state.has_no_combo())
	r.state.collision()
	r.state.damage_car(1.0)
	assert_eq(_broken(r).size(), 0)


func test_no_popup_when_the_combo_drains_away() -> void:
	var r := _run()
	r.state.add_trick("alternate_drift")
	for _i in 60:
		r.state.advance(0.5)
	assert_true(r.state.has_no_combo(), "the combo drained to nothing")
	assert_eq(_broken(r).size(), 0)


func test_the_signal_comes_only_on_a_cut() -> void:
	var r := _run()
	watch_signals(r.state)
	r.state.collision()
	assert_signal_not_emitted(r.state, "combo_broken")
	r.state.add_trick("alternate_drift")
	r.state.collision()
	assert_signal_emit_count(r.state, "combo_broken", 1)


func test_it_follows_the_car_and_stacks_with_trick_popups() -> void:
	var r := _run()
	r.state.add_trick("alternate_drift")
	r.state.add_trick("three_sixty")
	r.state.collision()
	var tp = r.trick_popups
	assert_eq(tp.popups().size(), 3)
	var p = _broken(r)[0]
	assert_true(p.follow.is_valid(), "follows the car")
	for o in tp.popups():
		for q in tp.popups():
			if o != q:
				var a := Rect2(o.position - o.size() / 2.0, o.size())
				var b := Rect2(q.position - q.size() / 2.0, q.size())
				assert_false(a.intersects(b), "popups do not overlap")
	r.car_sprite.position += Vector2(50, 20)
	p.place()
	assert_almost_eq(p.position.x, r.car_sprite.position.x + p.offset().x, 0.01)


func test_it_goes_away_after_its_life() -> void:
	var r := _run()
	r.state.add_trick("alternate_drift")
	r.state.collision()
	var p = _broken(r)[0]
	p.advance(Popups.LIFETIME + 0.1)
	await get_tree().process_frame
	# Ask is_instance_valid() first: after the frame the popup is usually freed,
	# and calling a method on a freed object crashes Godot 4.6 (T-281).
	assert_true(not is_instance_valid(p) or p.is_queued_for_deletion())


func test_right_half_falls_and_card_shakes_at_first() -> void:
	var r := _run()
	r.state.add_trick("alternate_drift")
	r.state.collision()
	var p = _broken(r)[0]
	assert_eq(p.broken_fall(), Vector2.ZERO)
	p.age = 0.05
	assert_gt(p.broken_shake().length(), 0.0)
	p.age = 0.8
	assert_gt(p.broken_fall().y, 20.0)
	assert_eq(p.broken_shake(), Vector2.ZERO)


func test_art_is_red_cracked_and_hard_edged() -> void:
	var heart: Color = Hud.HEART_COLOR
	var heart_v := Vector3(heart.r, heart.g, heart.b)
	for i in range(1, Art.PALETTE.size()):
		var c: Color = Art.PALETTE[i]
		assert_gt(Vector3(c.r, c.g, c.b).distance_to(heart_v), Art.RED_CLEARANCE, "palette %d clear of Redgull red" % i)
	var halves := Art.bake("COMBO BROKEN!", "normal")
	var l: Image = halves[0]
	var rt: Image = halves[1]
	assert_eq(l.get_size(), rt.get_size())
	var red: Color = Art.PALETTE[Art.CARD]
	var red_px := 0
	for img in halves:
		for y in img.get_height():
			for x in img.get_width():
				var p: Color = img.get_pixel(x, y)
				assert_true(p.a == 0.0 or p.a == 1.0, "no semi-transparent pixels")
				if p == red:
					red_px += 1
				if x == 0 or y == 0 or x == img.get_width() - 1 or y == img.get_height() - 1:
					assert_eq(p.a, 0.0, "transparent rim")
	assert_gt(red_px, 200, "mostly red")
	# The halves do not overlap: no pixel is opaque in both.
	for y in l.get_height():
		for x in l.get_width():
			assert_false(l.get_pixel(x, y).a > 0.0 and rt.get_pixel(x, y).a > 0.0, "halves apart at %d,%d" % [x, y])
	# The crack is jagged: its x differs between rows.
	var xs := {}
	for y in l.get_height():
		xs[Art.crack_x(l.get_width(), y)] = true
	assert_gt(xs.size(), 3)
	# It has white letters.
	var white := 0
	for img in halves:
		for y in img.get_height():
			for x in img.get_width():
				if img.get_pixel(x, y) == Color(1, 1, 1, 1):
					white += 1
	assert_gt(white, 50)
