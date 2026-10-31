extends GutTest
## Task T-458: the current mission as a notebook page on the HUD's left (placeholder art):
## the header and goal lines are screen_texts.json's words, a quantity goal shows its live
## count, a done goal is ticked and crossed off, the next mission replaces the one done.

const RUN := preload("res://scenes/run/run.tscn")


func _page() -> MissionPage:
	var m := RunMissions.new()
	m.start(7)
	var p := MissionPage.new()
	add_child_autofree(p)
	p.bind(m)
	return p


func _tracker(p: MissionPage) -> RunMissions:
	return p._missions


func _label_texts(p: MissionPage) -> Array:
	var out: Array = []
	for r in p.rows:
		out.append(r.label.text)
	return out


func test_header_is_the_texts_header() -> void:
	var p := _page()
	assert_eq(p.header_label.text, "Content quota")
	assert_true(p.visible)


func test_first_mission_is_the_duration_goal_without_count() -> void:
	var p := _page()
	assert_eq(_label_texts(p), ["Hold one drift for 4 seconds"])
	assert_false(p.rows[0].ticked)
	assert_false(p.rows[0].crossed)


func test_quantity_goal_shows_live_count() -> void:
	var p := _page()
	var m := _tracker(p)
	m.on_drift_step(true, 5.0)  # mission 1 done by one 5 s drift
	assert_eq(_label_texts(p), ["Alt drifts 0/10"])
	for i in 4:
		m.on_trick("alternate_drift")
	assert_eq(_label_texts(p), ["Alt drifts 4/10"])
	assert_false(p.rows[0].ticked)


func test_duration_goal_text_does_not_change_with_progress() -> void:
	var p := _page()
	var m := _tracker(p)
	m.on_drift_step(true, 1.5)
	assert_eq(_label_texts(p), ["Hold one drift for 4 seconds"])
	assert_false(p.rows[0].ticked)


func test_done_goal_is_ticked_and_crossed_then_next_mission_shows() -> void:
	var p := _page()
	var m := _tracker(p)
	# Go to a mission with two goals so the ticked goal stays on show.
	while m.current_goals().size() < 2:
		for g in m.current_goals():
			if String(g["kind"]) == "seconds":
				m.on_trick(String(g["trick"]), float(g["amount"]))
			else:
				for i in int(g["amount"]):
					m.on_trick(String(g["trick"]))
	assert_eq(p.rows.size(), 2)
	var first: Dictionary = m.current_goals()[0]
	if String(first["kind"]) == "seconds":
		m.on_trick(String(first["trick"]), float(first["amount"]))
	else:
		for i in int(first["amount"]):
			m.on_trick(String(first["trick"]))
	assert_true(p.rows[0].ticked)
	assert_true(p.rows[0].crossed)
	assert_false(p.rows[1].ticked)
	assert_false(p.rows[1].crossed)
	# The rest of the mission: the next one appears, nothing ticked.
	var number := m.current_number()
	var second: Dictionary = m.current_goals()[1]
	if String(second["kind"]) == "seconds":
		m.on_trick(String(second["trick"]), float(second["amount"]))
	else:
		for i in int(second["amount"]):
			m.on_trick(String(second["trick"]))
	assert_eq(m.current_number(), number + 1)
	for r in p.rows:
		assert_false(r.ticked)
		assert_false(r.crossed)
	assert_eq(p.rows.size(), m.current_goals().size())


func test_every_goal_line_is_a_known_text() -> void:
	var m := RunMissions.new()
	m.start(3)
	for mi in m.count():
		for g in m.mission(mi):
			var t := MissionPage.goal_text(String(g["trick"]), String(g["kind"]), 0.0, float(g["amount"]))
			assert_ne(t, "", "no text for %s" % g["trick"])
			assert_false("{" in t, "unfilled slot in '%s'" % t)


func test_whole_and_half_seconds_format() -> void:
	assert_eq(MissionPage.goal_text("airtime", "seconds", 0.0, 4.5), "Rack up 4.5 seconds of airtime")
	assert_eq(MissionPage.goal_text("airtime", "seconds", 0.0, 3.0), "Rack up 3 seconds of airtime")


func test_page_hides_after_the_last_mission() -> void:
	var p := _page()
	var m := _tracker(p)
	m.current = m.count()
	p.show_current()
	assert_false(p.visible)


func test_hud_has_the_page_and_follows_the_run() -> void:
	var r: Node2D = RUN.instantiate()
	add_child_autofree(r)
	var hud: Hud = r.hud
	assert_true(hud.mission_page.visible)
	assert_eq(hud.mission_page.header_label.text, "Content quota")
	r.state.missions.on_trick("alternate_drift")
	assert_eq(hud.mission_page.rows.size(), 1)


func test_page_does_not_overlap_hearts_coins_clock_at_two_sizes() -> void:
	var r: Node2D = RUN.instantiate()
	add_child_autofree(r)
	var hud: Hud = r.hud
	var page := Rect2(hud.mission_page.position, hud.mission_page.size)
	# Layout-page pixels, so the check holds at every window size (the HUD scales as one).
	for size: Vector2 in [Vector2(1152, 648), Vector2(1920, 1080)]:
		var s: float = Hud.scale_for(size, 100.0)
		var area: Vector2 = size / s
		var coins := Rect2(Hud.COINS_POS, Hud.COINS_SIZE)
		var clock := Rect2(hud.timer_clock.offset_left, area.y + hud.timer_clock.offset_top,
			hud.timer_clock.offset_right - hud.timer_clock.offset_left,
			hud.timer_clock.offset_bottom - hud.timer_clock.offset_top)
		var hearts := Rect2(Hud.HEART_ROW_POS, HeartRow.size_for(30))
		assert_false(page.intersects(coins), "coins at %s" % size)
		assert_false(page.intersects(clock), "clock at %s" % size)
		assert_false(page.intersects(hearts), "hearts at %s" % size)


func test_the_final_art_is_loaded_and_is_the_size_the_page_expects() -> void:
	# T-464: the page is 88 x 90 art px at 2x = PAGE_SIZE; the marks are 7 x 7 (the
	# checkbox and tick) and 24 x 4 (the pen stroke) and are not blank.
	var page := MissionPage.art(MissionPage.PAGE_ART)
	assert_not_null(page)
	assert_eq(page.get_size() * float(HudStyle.HUD_ART_SCALE), MissionPage.PAGE_SIZE)
	assert_eq(MissionPage.art(MissionPage.CHECKBOX_ART).get_size() * float(HudStyle.HUD_ART_SCALE),
		Vector2(MissionPage.BOX_SIZE, MissionPage.BOX_SIZE))
	assert_eq(MissionPage.art(MissionPage.TICK_ART).get_size(), Vector2(7, 7))
	assert_eq(MissionPage.art(MissionPage.CROSS_ART).get_size(), Vector2(24, 4))
	var im := page.get_image()
	var colours := {}
	for y in im.get_height():
		for x in im.get_width():
			colours[im.get_pixel(x, y).to_html()] = true
	gut.p("page colours: %d, pixel (30,24): %s, (3,3): %s" % [colours.size(), im.get_pixel(30, 24), im.get_pixel(3, 3)])
	assert_gt(colours.size(), 4, "the page has its paper, rules, margin and outline")
