extends GutTest
## Task T-336: the live viewers counter at the bottom right replaces the combo
## counter; it counts toward T-332's target and wobbles, heats up on T-332's steps
## and burns from 1,000,000; trick popups show "+{viewers}" with the eye in the
## viewers colour, the amount flies into the counter, which bumps; a crash flashes
## it red and drops "-{viewers lost}".

const RUN := preload("res://scenes/run/run.tscn")
const HUD_SCENE := preload("res://scenes/hud/hud.tscn")
const Art := preload("res://scripts/hud/trick_popup_art.gd")
const VIEWERS_COLOR := Color8(51, 225, 255)


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


# --- The counter and its place ---

func test_the_combo_counter_is_gone() -> void:
	var hud := _hud()
	assert_false("combo_label" in hud, "no combo counter")
	assert_null(hud.find_child("ComboLabel", true, false))
	assert_not_null(hud.viewers_counter)
	assert_eq(hud.find_children("*", "ViewersCounter", true, false).size(), 1, "one viewers counter")


func test_at_the_layout_pages_place_and_size_at_1152_x_648() -> void:
	var hud := _hud()
	await get_tree().process_frame
	var r := hud.viewers_counter.get_global_rect()
	assert_eq(r, Rect2(896, 560, 240, 72), "x896 y560 w240 h72")
	assert_eq(hud.viewers_counter.panel.get_global_rect(), r, "the panel art fills it")


func test_anchored_to_the_bottom_right_corner() -> void:
	for size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(1024, 576)]:
		var hud := _hud(size)
		await get_tree().process_frame
		var r := hud.viewers_counter.get_global_rect()
		assert_eq(r.size, Vector2(240, 72), "%s: same size" % size)
		assert_eq(Vector2(size) - r.end, Vector2(16, 16), "%s: 16 px from the right and bottom edges" % size)


func test_the_live_badge_eye_and_unit() -> void:
	var c := _hud().viewers_counter
	assert_eq(c.badge.texture.resource_path, "res://art/hud/live_badge.png", "T-339's badge art")
	assert_eq(c.badge.tooltip_text, Hud.TEXT_LIVE_BADGE, "T-331's badge text")
	assert_eq(c.eye.texture.resource_path, "res://art/hud/eye_icon.png")
	assert_eq(c.panel.texture.resource_path, "res://art/hud/viewers_panel.png")
	assert_eq(c.unit_label.text, Hud.TEXT_VIEWERS_UNIT, "T-331's unit")
	var panel := Rect2(Vector2.ZERO, c.size)
	for part: Control in [c.badge, c.eye, c.number_label, c.unit_label]:
		assert_true(panel.encloses(part.get_rect()), "%s inside the panel %s" % [part.name, part.get_rect()])
	assert_false(c.badge.get_rect().intersects(c.number_label.get_rect()), "badge clear of the number")
	assert_false(c.eye.get_rect().intersects(c.number_label.get_rect()), "eye clear of the number")
	assert_lt(c.number_label.get_rect().get_center().y, c.unit_label.position.y, "number above the unit")
	assert_lt(c.unit_label.get_rect().end.y, c.size.y - 6.0, "the unit clear of the panel's bottom bezel")


func test_the_viewers_colour_is_used_nowhere_else_in_the_hud() -> void:
	var hud := _hud()
	assert_eq(hud.viewers_counter.color, VIEWERS_COLOR, "hud.json's colour, the panel rim's")
	assert_eq(Art.PALETTE[Art.AMOUNT_VIEWERS], VIEWERS_COLOR, "the popups' amount")
	for l: Label in hud.find_children("*", "Label", true, false):
		if hud.viewers_counter.is_ancestor_of(l):
			continue
		assert_ne(l.get_theme_color("font_color"), VIEWERS_COLOR, "%s not in the viewers colour" % l.name)
	for i in Art.PALETTE.size():
		if i != Art.AMOUNT_VIEWERS:
			assert_ne(Art.PALETTE[i], VIEWERS_COLOR, "popup colour %d" % i)


# --- The number ---

func test_the_number_counts_toward_the_target_for_the_multiplier() -> void:
	var hud := _hud()
	var c := hud.viewers_counter
	var v := ViewersData.new()
	assert_eq(c.shown, v.viewers_for(1.0), "a new HUD starts at x1's viewers")
	hud._on_combo_changed(2.0)
	assert_eq(c.target(), v.viewers_for(2.0), "T-332's target")
	var gap := absf(c.target() - c.shown)
	c.advance(0.1)
	assert_lt(absf(c.target() - c.shown), gap, "closer after 0.1 s")
	assert_gt(c.shown, v.viewers_for(1.0), "counting up")
	for i in 300:
		c.advance(1.0 / 60.0)
	assert_eq(c.shown, c.target(), "there after 5 s")
	hud._on_combo_changed(1.5)
	c.advance(0.1)
	assert_gt(c.shown, v.viewers_for(1.5), "counting down, not jumping")
	assert_lt(c.shown, v.viewers_for(2.0))
	assert_eq(c.number_label.text, v.format(c.displayed), "shows the wobbling number, T-332's format")


func test_the_number_never_sits_still_while_the_run_goes() -> void:
	var hud := _hud()
	var c := hud.viewers_counter
	for m: float in [1.0, 2.0, 3.5, 6.0]:
		hud._on_combo_changed(m)
		for i in 300:
			c.advance(1.0 / 60.0)
		# Settled on the target: the wobble keeps the drawn number moving.
		var last := c.displayed
		var still := 0
		var longest := 0
		for i in 240:
			c.advance(1.0 / 60.0)
			if c.displayed == last:
				still += 1
				longest = maxi(longest, still)
			else:
				still = 0
			last = c.displayed
		assert_lt(longest, 12, "x%s: never still for 0.2 s" % m)


func test_it_stops_while_paused() -> void:
	var r := _run()
	var hud: Hud = r.hud
	r.state.add_trick("alternate_drift")
	await wait_process_frames(3)
	get_tree().paused = true
	var t := hud.viewers_counter.time
	var shown := hud.viewers_counter.shown
	var text := hud.viewers_counter.number_label.text
	await wait_process_frames(20)
	assert_eq(hud.viewers_counter.time, t, "the wobble stands still")
	assert_eq(hud.viewers_counter.shown, shown, "the count stands still")
	assert_eq(hud.viewers_counter.number_label.text, text)
	get_tree().paused = false
	await wait_process_frames(5)
	assert_gt(hud.viewers_counter.time, t, "moving again")


# --- Heat and fire ---

func test_the_look_changes_at_t332s_heat_steps() -> void:
	var hud := _hud()
	var c := hud.viewers_counter
	var v := ViewersData.new()
	var seen := {}
	var sizes := {}
	for m: float in [1.0, 1.9, 2.0, 2.9, 3.0, 3.9, 4.0, 5.9, 6.0]:
		hud._on_combo_changed(m)
		assert_eq(c.step, v.step_for_viewers(v.viewers_for(m)), "x%s: T-332's step" % m)
		seen[c.step] = c.number_label.get_theme_color("font_color")
		sizes[c.step] = c.number_label.get_theme_font_size("font_size")
	assert_eq(seen.keys().size(), 5, "base, three heat steps and fire")
	assert_eq(seen[0], VIEWERS_COLOR, "the base look is the viewers colour")
	for s in [1, 2, 3]:
		assert_eq(seen[s], ComboHeat.STEPS[s].color, "step %d: the old counter's heat colour" % s)
		assert_gt(sizes[s], sizes[s - 1], "step %d bigger" % s)


func test_on_fire_at_a_million_or_more() -> void:
	var hud := _hud()
	var c := hud.viewers_counter
	var v := ViewersData.new()
	for m: float in [1.0, 3.0, 4.5, 5.9, 5.99]:
		hud._on_combo_changed(m)
		assert_lt(c.target(), 1000000.0)
		assert_false(c.is_burning(), "no fire at x%s" % m)
		assert_false(c.fire.visible)
	hud._on_combo_changed(6.0)
	assert_eq(c.target(), 1000000.0)
	assert_true(c.is_burning(), "on fire at 1,000,000")
	assert_true(c.fire.visible)
	assert_eq(c.fire.texture.resource_path, "res://art/hud/viewers_fire_%02d.png" % c.fire_frame, "T-339's fire")
	var frames := {}
	for i in 24:
		c.advance(ComboHeat.FLICKER_FRAME)
		frames[c.fire.texture] = true
	assert_eq(frames.size(), ViewersCounter.FIRE_FRAMES, "the fire loops through its 12 frames")
	# The fire's panel sits on the counter's panel.
	assert_eq(c.fire.position + ViewersCounter.FIRE_PANEL_AT * 2.0, Vector2.ZERO)
	hud._on_combo_changed(4.0)
	assert_false(c.is_burning(), "the fire goes out when it drops")
	assert_true(v.is_fire(v.viewers_for(6.0)))


func test_no_heart_red_in_the_counter() -> void:
	var hud := _hud()
	var c := hud.viewers_counter
	var heart := Vector3(Hud.HEART_COLOR.r, Hud.HEART_COLOR.g, Hud.HEART_COLOR.b)
	for m: float in [1.0, 2.0, 3.0, 4.0, 6.0]:
		hud._on_combo_changed(m)
		var col := c.number_label.get_theme_color("font_color")
		assert_gt(Vector3(col.r, col.g, col.b).distance_to(heart), 0.5, "x%s" % m)


# --- Trick popups and the flight ---

func test_a_trick_popup_shows_plus_viewers_in_the_viewers_colour_with_the_eye() -> void:
	var r := _run()
	r.state.add_trick("alternate_drift")
	var p = r.trick_popups.popups().back()
	var gain := ViewersData.new().trick_gain(1.0, 1.5)
	assert_eq(p.text, "ALT DRIFT! +" + ViewersData.new().format(gain), "the name, then +{viewers}")
	assert_true(p.viewers)
	assert_eq(p.viewers_gain, roundf(gain))
	var img: Image = Art.bake(p.text, "normal", 0, 0, true)
	var box: Rect2i = Art.amount_box(p.text, "normal")
	var cyan := 0
	var eye := 0
	var eye_img := (load("res://art/hud/eye_icon.png") as Texture2D).get_image()
	eye_img.convert(Image.FORMAT_RGBA8)
	var eye_colors := {}
	for y in eye_img.get_height():
		for x in eye_img.get_width():
			var ec := eye_img.get_pixel(x, y)
			if ec.a > 0.5 and ec != Color(0, 0, 0, 1):
				eye_colors[Color(ec.r, ec.g, ec.b, 1.0).to_html()] = true
	for y in img.get_height():
		for x in img.get_width():
			var col := img.get_pixel(x, y)
			if col == VIEWERS_COLOR:
				cyan += 1
				assert_true(box.has_point(Vector2i(x, y)), "viewers colour only in the amount")
			if eye_colors.has(col.to_html()) and box.has_point(Vector2i(x, y)):
				eye += 1
	assert_gt(cyan, 50, "the amount in the viewers colour")
	assert_gt(eye, 20, "the eye beside it")
	# The name stays black.
	var plain: Image = Art.bake("ALT DRIFT!", "normal")
	assert_lt(plain.get_width(), img.get_width())


func test_the_amount_leaves_the_popup_and_flies_into_the_counter_which_bumps() -> void:
	var r := _run()
	var hud: Hud = r.hud
	var c := hud.viewers_counter
	await get_tree().process_frame
	var before := c.shown
	r.state.add_trick("alternate_drift")
	var p = r.trick_popups.popups().back()
	assert_eq(c.pending, p.viewers_gain, "the viewers are held until the amount lands")
	assert_eq(c.count_target(), c.target() - p.viewers_gain)
	var landed: Array = []
	c.landed.connect(func(g: float) -> void: landed.append(g))
	p.advance(TrickPopups.DETACH_AT)
	assert_true(p.amount_gone, "the amount left the popup")
	assert_eq(c.flights.size(), 1, "and flies")
	var f: ViewersFlight = c.flights[0]
	assert_eq(f.label.text, "+" + ViewersData.new().format(p.viewers_gain))
	assert_eq(f.label.get_theme_color("font_color"), VIEWERS_COLOR)
	assert_not_null(f.eye.texture)
	# The popup's bubble keeps its size, without the amount.
	var with_amount: ImageTexture = Art.texture(p.text, "normal", p.heat, 0, true)
	assert_eq(p.texture().get_size(), with_amount.get_size())
	assert_ne(p.texture(), with_amount)
	var start: Vector2 = f.point_at(0.0)
	var end: Vector2 = f.point_at(1.0)
	assert_eq(end, c.number_center(), "it ends on the counter's number")
	assert_true(start.distance_to(end) > 100.0, "it starts far from it, at the popup")
	f.advance(f.seconds * 0.5)
	assert_true(landed.is_empty(), "still flying")
	f.advance(f.seconds)
	assert_eq(landed, [p.viewers_gain], "landed")
	assert_eq(c.pending, 0.0, "the viewers count in")
	assert_gt(c.bump_left, 0.0, "the counter bumps")
	assert_gt(c.number_scale(), 1.0, "a pop")
	assert_gt(c.flash_rect.color.a, 0.0, "and a flash")
	assert_false(c.is_flashing_red())
	for i in 60:
		c.advance(1.0 / 60.0)
	assert_gt(c.shown, before, "the number went up")
	assert_eq(c.bump_left, 0.0, "the bump is over")


func test_a_popup_pushed_out_early_gives_its_viewers_back() -> void:
	var r := _run()
	var c: ViewersCounter = r.hud.viewers_counter
	for i in 4:  # the fourth pushes the first out (three at most)
		r.state.add_trick("alternate_drift")
	await get_tree().process_frame
	var held := 0.0
	for p in r.trick_popups.popups():
		held += p.viewers_gain
	assert_almost_eq(c.pending, held, 0.5, "only the popups still showing hold viewers")


func test_the_drift_prototype_shows_names_only_and_flies_nothing() -> void:
	var tp := TrickPopups.new()
	add_child_autofree(tp)
	var p = tp.show_popup("FULL 360!", Vector2.ZERO)
	assert_false(p.viewers)
	p.advance(0.5)
	assert_false(p.amount_gone)


# --- Crashes ---

func test_a_crash_flashes_red_and_drops_the_viewers_lost() -> void:
	var r := _run()
	var hud: Hud = r.hud
	var c := hud.viewers_counter
	for i in 4:
		r.state.add_trick("alternate_drift")
	for p in r.trick_popups.popups():
		p.advance(TrickPopups.DETACH_AT)
	for f in c.flights.duplicate():
		f.advance(5.0)
	for i in 120:
		c.advance(1.0 / 60.0)
	var before: float = r.state.combo
	var high := c.shown
	r.state.collision()
	var loss := ViewersData.new().crash_loss(before, r.state.combo)
	assert_gt(loss, 0.0)
	assert_true(c.is_flashing_red(), "the counter flashes red")
	assert_eq(c.number_label.get_theme_color("font_color"), c.crash_color, "the number goes red while it flashes")
	assert_eq(c.drops.size(), 1, "a drop")
	var d: ViewersDrop = c.drops[0]
	assert_eq(d.text, "-" + ViewersData.new().format(loss), "-{viewers lost}")
	assert_eq(d.get_theme_color("font_color"), c.crash_color)
	var y0 := d.position.y
	d.advance(0.4)
	assert_gt(d.position.y, y0, "it drops away")
	c.advance(0.2)
	assert_lt(c.shown, high, "the number falls")
	for i in 60:
		c.advance(1.0 / 60.0)
	assert_false(c.is_flashing_red(), "the flash is over")
	assert_ne(c.number_label.get_theme_color("font_color"), c.crash_color)


func test_no_crash_no_drop() -> void:
	var r := _run()
	var c: ViewersCounter = r.hud.viewers_counter
	r.state.collision()  # no combo to cut
	assert_false(c.is_flashing_red())
	assert_eq(c.drops.size(), 0)
	r.state.add_trick("alternate_drift")
	r.state.advance(30.0)  # the combo drains away: not a crash
	assert_false(c.is_flashing_red())
	assert_eq(c.drops.size(), 0)


func test_a_new_run_starts_clean() -> void:
	var r := _run()
	var c: ViewersCounter = r.hud.viewers_counter
	for i in 4:
		r.state.add_trick("alternate_drift")
	r.state.collision()
	r.start_run()
	assert_eq(c.multiplier, r.state.combo)
	assert_eq(c.pending, 0.0)
	assert_eq(c.shown, ViewersData.new().viewers_for(r.state.combo))
	assert_eq(c.flights.size(), 0)


# --- Texts ---

func test_no_text_written_in_the_counters_code() -> void:
	for path in ["res://scripts/hud/viewers_counter.gd", "res://scripts/hud/viewers_flight.gd",
			"res://scripts/hud/viewers_drop.gd"]:
		var src := FileAccess.get_file_as_string(path)
		var re := RegEx.create_from_string("text\\s*=\\s*\"")
		assert_null(re.search(src), "%s sets no literal text" % path)
		assert_false(src.contains("\"WATCHING\"") or src.contains("\"LIVE\""), path)
	assert_eq(TrickPopups.LOST_TEXT, "-{amount}")
	assert_eq(TrickPopups.ADDED_TEXT, "+{amount}")
