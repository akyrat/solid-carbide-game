extends GutTest
## Task T-606: the notebook page pulses discreetly on any mission progress: a count going up, a
## running total growing (rate limited), a goal ticked. Only its scale changes, never its place.


func _page(goals: Array) -> MissionPage:
	var m := RunMissions.new()
	m.start_with([goals])
	var p := MissionPage.new()
	add_child_autofree(p)
	p.bind(m)
	return p


func _count_page() -> MissionPage:
	return _page([{"trick": "alternate_drift", "kind": "count", "amount": 3}])


func _total_page() -> MissionPage:
	return _page([{"trick": "airtime", "kind": "seconds", "amount": 30.0}])


func _rest(p: MissionPage) -> void:
	p.finish_falls()
	p.advance(1.0)


func test_a_count_going_up_pulses_once_its_box_has_landed() -> void:
	var p := _count_page()
	_rest(p)
	assert_false(p.is_pulsing())
	p._missions.on_trick("alternate_drift")
	assert_false(p.is_pulsing(), "the count waits for the box")
	p.finish_falls()
	assert_true(p.is_pulsing(), "the box landed and the count changed")
	p.advance(2.0)  # finish_falls ran the splash out; let the pulse end too
	assert_false(p.is_pulsing())
	p.pulse()
	p.advance(p._pulse_seconds * 0.5)
	assert_almost_eq(p.scale.x, 1.0 + p._pulse_scale, 0.001)
	p.advance(p._pulse_seconds)
	assert_false(p.is_pulsing())
	assert_eq(p.scale, Vector2.ONE)


func test_a_goal_without_a_box_pulses_at_once() -> void:
	var p := _total_page()
	_rest(p)
	p._missions.add_seconds("airtime", 0.5)
	assert_true(p.is_pulsing())


func test_a_goal_ticked_pulses() -> void:
	var p := _page([{"trick": "alternate_drift", "kind": "count", "amount": 1}])
	_rest(p)
	p._missions.on_trick("alternate_drift")
	p.finish_falls()
	assert_true(p.rows[0].ticked)
	assert_true(p.is_pulsing())


func test_a_running_total_pulses_when_it_starts_growing_then_at_most_every_gap() -> void:
	var p := _total_page()
	_rest(p)
	var pulses := 0
	var gap: float = p._pulse_total_gap
	var t := 0.0
	var was := false
	while t < 3.0:
		p._missions.add_seconds("airtime", 0.1 / 60.0 * 6.0)  # about every frame: grows 0.01 s
		p.advance(1.0 / 60.0)
		t += 1.0 / 60.0
		if p.is_pulsing() and not was:
			pulses += 1
		was = p.is_pulsing()
	assert_gt(pulses, 0, "it pulsed when it started growing")
	assert_lte(pulses, int(ceil(3.0 / gap)) + 1, "not every frame: %d pulses in 3 s" % pulses)
	assert_lt(pulses, 6)


func test_a_total_that_stops_and_starts_again_pulses_again() -> void:
	var p := _total_page()
	_rest(p)
	p._missions.add_seconds("airtime", 1.0)
	assert_true(p.is_pulsing())
	p.advance(p._pulse_total_gap + 0.5)
	assert_false(p.is_pulsing())
	p._missions.add_seconds("airtime", 1.0)
	assert_true(p.is_pulsing())


func test_a_total_that_shows_the_same_text_does_not_pulse() -> void:
	var p := _total_page()
	_rest(p)
	p._missions.add_seconds("airtime", 0.01)  # reads 0.0 still
	assert_false(p.is_pulsing())


func test_a_pulse_still_growing_is_left_to_finish_and_one_past_its_peak_restarts() -> void:
	var p := _count_page()
	_rest(p)
	p.pulse()
	p.advance(p._pulse_seconds * 0.25)
	var age: float = p._pulse_age
	p.pulse()
	assert_eq(p._pulse_age, age, "left to finish")
	p.advance(p._pulse_seconds * 0.5)
	p.pulse()
	assert_eq(p._pulse_age, 0.0, "restarted past the peak")


func test_the_pulse_never_moves_or_resizes_the_page() -> void:
	var p := _count_page()
	_rest(p)
	var pos := p.position
	var sz := p.size
	p._missions.on_trick("alternate_drift")
	p.finish_falls()
	var steps := 0
	while p.is_pulsing() and steps < 100:
		assert_eq(p.position, pos)
		assert_eq(p.size, sz)
		assert_eq(p.pivot_offset, sz * 0.5, "scales around its own centre")
		assert_between(p.scale.x, 1.0, 1.0 + p._pulse_scale + 0.0001)
		p.advance(0.02)
		steps += 1
	assert_eq(p.position, pos)
	assert_eq(p.size, sz)


func test_the_numbers_come_from_hud_json_and_are_discreet() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/hud.json"))["notebook_pulse"]
	var p := MissionPage.new()
	add_child_autofree(p)
	assert_eq(p._pulse_scale, float(d["scale"]))
	assert_eq(p._pulse_seconds, float(d["seconds"]))
	assert_eq(p._pulse_total_gap, float(d["total_gap"]))
	assert_between(float(d["scale"]), 0.01, 0.1, "a few percent")
	assert_true(String(d["_comment"]).length() > 50, "with its reasons")


func test_the_tutorials_practice_window_pulses_too() -> void:
	var session: PracticeSession = preload("res://scenes/run/practice_session.tscn").instantiate()
	add_child_autofree(session)
	session.setup("alt_drift")
	session.notebook.finish_falls()
	session.notebook.advance(1.0)
	session.notebook.show_progress(0, 1.0)
	assert_true(session.notebook.is_pulsing())
	session.notebook.advance(1.0)
	session.add_drift_seconds(0.0)
	session.setup("drift")
	session.notebook.advance(1.0)
	session.add_drift_seconds(1.0)
	assert_true(session.notebook.is_pulsing(), "the drift slide's seconds pulse when they start growing")
