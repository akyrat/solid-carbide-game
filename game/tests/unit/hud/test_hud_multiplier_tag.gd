extends GutTest
## Task T-514: the combo multiplier beside the car replaces the live viewers counter. It shows
## T-512's "x{multiplier}", follows the car, heats up on ComboHeat's steps, takes a trick
## popup's "+x{amount}" flying in (bumping on arrival), and flashes red with a "-x{lost}" on a
## crash. All its text comes from data/multiplier_text.json.

const RUN := preload("res://scenes/run/run.tscn")
const HUD_SCENE := preload("res://scenes/hud/hud.tscn")
const Art := preload("res://scripts/hud/trick_popup_art.gd")
const COLOR := Color8(51, 225, 255)


func after_each() -> void:
	get_tree().paused = false


func _screen(size := Vector2i(1152, 648)) -> SubViewport:
	var sv := SubViewport.new()
	sv.size = size
	add_child_autofree(sv)
	return sv


func _run(size := Vector2i(1152, 648)) -> Node2D:
	var r: Node2D = RUN.instantiate()
	_screen(size).add_child(r)
	return r


func _hud(size := Vector2i(1152, 648)) -> Hud:
	var hud: Hud = HUD_SCENE.instantiate()
	_screen(size).add_child(hud)
	return hud


func test_no_viewers_counter_and_the_multiplier_is_there() -> void:
	var hud := _hud()
	assert_false("viewers_counter" in hud, "no viewers counter")
	assert_null(hud.find_child("ViewersCounter", true, false))
	assert_eq(hud.find_children("*", "MultiplierTag", true, false).size(), 1)
	assert_eq(hud.multiplier_tag.number_label.text, "x1.00")
	assert_false("viewers" in HudLayout.PIECES, "not a movable piece any more")


func test_it_sits_left_of_the_car_and_follows_the_window() -> void:
	for size in [Vector2i(1152, 648), Vector2i(1920, 1080), Vector2i(960, 540)]:
		var hud := _hud(size)
		await get_tree().process_frame
		var view := Vector2(size)
		var rect := hud.multiplier_tag.get_global_rect()
		assert_true(Rect2(Vector2.ZERO, view).encloses(rect), "%s: on screen" % size)
		var centre := rect.get_center()
		assert_lt(centre.x, view.x / 2.0, "%s: left of the car (the screen's middle)" % size)
		assert_almost_eq(centre.y, view.y / 2.0 + hud.multiplier_tag.offset.y * hud.hud_scale(), 3.0)


func test_the_number_is_t512s_text_and_eases_to_the_multiplier() -> void:
	var r := _run()
	var tag: MultiplierTag = r.hud.multiplier_tag
	r.state.add_trick("alternate_drift")
	assert_eq(tag.multiplier, r.state.combo)
	assert_eq(tag.pending, 0.5, "the add is held until its amount lands")
	tag.release(tag.pending)
	for i in 120:
		tag.advance(1.0 / 60.0)
	var expected: String = MultiplierTag.text_for("multiplier").format({"multiplier": "%.2f" % r.state.combo})
	assert_eq(tag.number_label.text, expected)
	assert_eq(MultiplierTag.multiplier_text(2.5), "x2.50")
	assert_eq(MultiplierTag.gain_text(0.5), "+x0.5")
	assert_eq(MultiplierTag.gain_text(0.25), "+x0.25")
	assert_eq(MultiplierTag.loss_text(1.5), "-x1.5")


func test_the_look_follows_the_heat_steps() -> void:
	var hud := _hud()
	var tag := hud.multiplier_tag
	var sizes: Array[int] = []
	for m: float in [1.5, 2.0, 3.0, 4.0]:
		tag.reset(m)
		assert_eq(tag.step, ComboHeat.step_for(m))
		sizes.append(tag.number_label.get_theme_font_size("font_size"))
	for i in range(1, 4):
		assert_gt(sizes[i], sizes[i - 1])
	tag.reset(6.0)
	assert_eq(tag.step, 4, "the cap is the fire step for the reactions")
	tag.reset(1.0)
	assert_eq(tag.number_label.get_theme_color("font_color"), COLOR, "the multiplier colour at the base")


func test_a_trick_popup_shows_its_add_and_the_amount_flies_in_and_bumps() -> void:
	var r := _run()
	var tag: MultiplierTag = r.hud.multiplier_tag
	await get_tree().process_frame
	r.state.add_trick("alternate_drift")
	var p = r.trick_popups.popups().back()
	assert_eq(p.text, "ALT DRIFT! " + MultiplierTag.gain_text(0.5), "the name, then T-512's +x{amount}")
	assert_true(p.multiplier_amount)
	assert_eq(p.gain, 0.5)
	assert_eq(tag.pending, 0.5, "held until the amount lands")
	var img: Image = Art.bake(p.text, "normal", 0, 0, true)
	var box: Rect2i = Art.amount_box(p.text, "normal")
	var cyan := 0
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y) == COLOR:
				cyan += 1
				assert_true(box.has_point(Vector2i(x, y)), "the multiplier colour only in the amount")
	assert_gt(cyan, 30)
	var landed: Array = []
	tag.landed.connect(func(g: float) -> void: landed.append(g))
	p.advance(TrickPopups.DETACH_AT)
	assert_true(p.amount_gone)
	assert_eq(tag.flights.size(), 1)
	var f: MultiplierFlight = tag.flights[0]
	assert_eq(f.label.text, "+x0.5")
	assert_eq(f.point_at(1.0), tag.number_center(), "it ends on the number")
	f.advance(f.seconds * 0.5)
	assert_true(landed.is_empty())
	f.advance(f.seconds)
	assert_eq(landed, [0.5])
	assert_eq(tag.pending, 0.0)
	assert_gt(tag.bump_left, 0.0, "the number bumps")
	assert_gt(tag.number_scale(), 1.0)


func test_a_popup_pushed_out_early_gives_its_add_back() -> void:
	var r := _run()
	var tag: MultiplierTag = r.hud.multiplier_tag
	for i in 4:
		r.state.add_trick("alternate_drift")
	await get_tree().process_frame
	var held := 0.0
	for p in r.trick_popups.popups():
		held += p.gain
	assert_almost_eq(tag.pending, held, 0.001)


func test_a_crash_flashes_red_and_drops_what_was_lost() -> void:
	var r := _run()
	var tag: MultiplierTag = r.hud.multiplier_tag
	for i in 3:
		r.state.add_trick("alternate_drift")
	await get_tree().process_frame
	var before: float = r.state.combo
	r.state.collision()
	assert_lt(r.state.combo, before)
	assert_true(tag.is_flashing_red())
	assert_eq(tag.drops.size(), 1)
	assert_eq(tag.drops[0].text, MultiplierTag.loss_text(before - r.state.combo))
	for i in 120:
		tag.advance(1.0 / 60.0)
	assert_false(tag.is_flashing_red())


func test_a_new_run_starts_clean() -> void:
	var hud := _hud()
	var tag := hud.multiplier_tag
	tag.hold(1.0)
	tag.fly_in("+x0.5", 0.5, Vector2(500, 300))
	tag.reset(1.0)
	assert_eq(tag.pending, 0.0)
	assert_true(tag.flights.is_empty())


func test_it_stands_still_while_paused() -> void:
	var hud := _hud()
	var t: float = hud.multiplier_tag.time
	get_tree().paused = true
	await wait_process_frames(10)
	assert_eq(hud.multiplier_tag.time, t)


func test_the_drift_prototype_flies_nothing() -> void:
	var holder := Node2D.new()
	var popups := TrickPopups.new()
	holder.add_child(popups)
	add_child_autofree(holder)
	var p := popups.show_popup("FULL 360! +x0.25", Vector2.ZERO, TrickPopups.SIZE_NORMAL)
	assert_false(p.multiplier_amount, "only the run's combo popups carry an amount")


func test_no_text_written_in_the_code() -> void:
	for path in ["res://scripts/hud/multiplier_tag.gd", "res://scripts/hud/multiplier_flight.gd", "res://scripts/hud/multiplier_drop.gd"]:
		var src := FileAccess.get_file_as_string(path)
		for bad in ["\"WATCHING\"", "\"LIVE\"", "\"+%s\"", "\"x%s\""]:
			assert_false(src.contains(bad), "%s: %s" % [path, bad])
	for path in ["res://scripts/hud/hud.gd", "res://scripts/hud/trick_popups.gd"]:
		var src := FileAccess.get_file_as_string(path)
		for bad in ["TEXT_LIVE_BADGE", "TEXT_VIEWERS_UNIT", "ADDED_TEXT", "LOST_TEXT"]:
			assert_false(src.contains(bad), "%s still has %s" % [path, bad])


# --- Hidden at x1 (the board, quick tuning 2026-11-02: "hide it if its at 1x") ---

func test_hidden_at_x1_and_shown_above_it() -> void:
	var hud := _hud()
	var tag := hud.multiplier_tag
	assert_false(tag.is_visible_now(), "hidden at the start")
	assert_eq(tag.number_label.modulate.a, 0.0)
	tag.set_multiplier(1.5)
	for i in 30:
		tag.advance(1.0 / 60.0)
	assert_true(tag.is_visible_now())
	assert_eq(tag.number_label.modulate.a, 1.0, "faded in")
	tag.set_multiplier(1.0)
	for i in 240:
		tag.advance(1.0 / 60.0)
	assert_eq(tag.number_label.modulate.a, 0.0, "hidden again once it has drained back to x1")


func test_a_trick_amount_lands_on_it_as_it_appears() -> void:
	var r := _run()
	var tag: MultiplierTag = r.hud.multiplier_tag
	await get_tree().process_frame
	assert_false(tag.is_visible_now())
	r.state.add_trick("alternate_drift")
	assert_true(tag.wants_show(), "the trick's add shows it at once")
	var p = r.trick_popups.popups().back()
	p.advance(TrickPopups.DETACH_AT)
	var f: MultiplierFlight = tag.flights[0]
	for i in 12:
		tag.advance(1.0 / 60.0)
	assert_gt(tag.number_label.modulate.a, 0.5, "mostly in while the amount is still flying")
	f.advance(f.seconds * 2.0)
	assert_gt(tag.bump_left, 0.0)
	for i in 30:
		tag.advance(1.0 / 60.0)
	assert_eq(tag.number_label.modulate.a, 1.0)


func test_a_crash_to_x1_still_shows_its_flash_and_drop_then_hides() -> void:
	var r := _run()
	var tag: MultiplierTag = r.hud.multiplier_tag
	r.state.add_trick("alternate_drift")
	tag.release(tag.pending)
	for i in 30:
		tag.advance(1.0 / 60.0)
	r.state.collision()
	assert_true(tag.wants_show())
	for i in 20:
		tag.advance(1.0 / 60.0)
	assert_gt(tag.number_label.modulate.a, 0.0, "the loss is seen")
	tag.set_multiplier(1.0)  # the combo then drains back to x1
	for d in tag.drops.duplicate():
		d.advance(2.0)  # the drop has fallen away
	await get_tree().process_frame
	for i in 240:
		tag.advance(1.0 / 60.0)
	assert_eq(tag.number_label.modulate.a, 0.0)
