extends GutTest
## Task T-565 (Game loop architecture, Decisions, "Total-time mission goals show their running
## total"): a mission goal that adds time up (the airtime) shows its total so far against its goal
## in the notebook, updating as it grows; the unbroken drift goal is unchanged.
##
## The texts are T-564's (missions.<MissionPage.TOTAL_GOALS_KEY>.<trick> in screen_texts.json).
## Tests that need a line with {done} in it use a stand-in template set on the page's text cache
## here, so they test the code whether or not T-564's texts are merged; the last test checks the
## real file's line once it is.

const STAND_IN := "Air {done}/{total}"  # a test template, never shown to the player

var _saved_texts: Dictionary


func before_each() -> void:
	_saved_texts = MissionPage.texts().duplicate(true)


func after_each() -> void:
	MissionPage._texts = _saved_texts


func _with_stand_in() -> void:
	var t := _saved_texts.duplicate(true)
	t[MissionPage.TOTAL_GOALS_KEY] = {"airtime": STAND_IN}
	MissionPage._texts = t


func _page(goals: Array) -> MissionPage:
	var m := RunMissions.new()
	m.start_with([goals])
	var p := MissionPage.new()
	add_child_autofree(p)
	p.bind(m)
	return p


# ---- The tracker ------------------------------------------------------------------------------

func test_airtime_seconds_is_a_running_total_and_the_unbroken_drift_is_not() -> void:
	assert_true(RunMissions.is_running_total("airtime", "seconds"))
	assert_false(RunMissions.is_running_total("extended_drift", "seconds"))
	assert_false(RunMissions.is_running_total("airtime", "count"))
	assert_false(RunMissions.is_running_total("alternate_drift", "count"))


func test_landings_add_their_airtime_up_and_send_each_total() -> void:
	var m := RunMissions.new()
	m.start_with([[{"trick": "airtime", "kind": "seconds", "amount": 3.0}]])
	var totals: Array = []
	m.goal_progress.connect(func(_mi: int, _gi: int, done: float, total: float) -> void:
		totals.append([done, total]))
	m.on_airtime(0.8)
	m.on_airtime(1.1)
	assert_eq(totals.size(), 2)
	assert_almost_eq(float(totals[1][0]), 1.9, 0.0001)
	assert_eq(float(totals[1][1]), 3.0)
	m.on_airtime(1.5)
	assert_true(m.is_all_done(), "done at 3 s in total")


func test_add_seconds_adds_up_without_a_name_box_and_never_to_the_unbroken_drift() -> void:
	var m := RunMissions.new()
	m.start_with([[{"trick": "airtime", "kind": "seconds", "amount": 2.0},
		{"trick": "extended_drift", "kind": "seconds", "amount": 2.0}]])
	var boxes := [0]
	m.trick_counted.connect(func(_mi: int, _gi: int, _id: String) -> void: boxes[0] += 1)
	m.add_seconds("airtime", 0.5)
	m.add_seconds("airtime", 0.25)
	m.add_seconds("extended_drift", 5.0)
	assert_almost_eq(float(m.progress[0]), 0.75, 0.0001)
	assert_eq(float(m.progress[1]), 0.0, "the unbroken drift is not added up")
	assert_eq(boxes[0], 0, "no name box for a fraction of a second")
	m.add_seconds("airtime", 2.0)
	assert_true(m.completed[0])
	assert_eq(float(m.progress[0]), 2.0)


# ---- The notebook -----------------------------------------------------------------------------

func test_the_airtime_line_shows_its_running_total_and_follows_it() -> void:
	_with_stand_in()
	var p := _page([{"trick": "airtime", "kind": "seconds", "amount": 3.0}])
	var m: RunMissions = p._missions
	assert_eq(p.rows[0].label.text, "Air 0.0/3")
	m.on_airtime(0.84)
	assert_true(p.is_falling(), "a landing drops its name box (HANG TIME!)")
	p.finish_falls()
	assert_eq(p.rows[0].label.text, "Air 0.8/3", "seconds with one decimal, cut down")
	m.on_airtime(1.2)
	p.finish_falls()
	assert_eq(p.rows[0].label.text, "Air 2.0/3")
	assert_false(p.rows[0].ticked)
	m.on_airtime(0.97)
	p.finish_falls()
	assert_eq(p.rows[0].label.text, "Air 3.0/3")
	assert_true(p.rows[0].ticked, "ticked and crossed off at its goal")


func test_never_reads_its_goal_before_it_is_done() -> void:
	assert_eq(MissionPage.format_seconds(2.99), "2.9")
	assert_eq(MissionPage.format_seconds(3.0), "3.0")
	assert_eq(MissionPage.format_seconds(0.0), "0.0")
	assert_eq(MissionPage.format_seconds(1.25), "1.2")


func test_the_unbroken_drift_line_is_unchanged() -> void:
	_with_stand_in()
	var p := _page([{"trick": "extended_drift", "kind": "seconds", "amount": 2.0}])
	var m: RunMissions = p._missions
	var line := String(MissionPage.texts()["goals"]["extended_drift"]).replace("{seconds}", "2")
	assert_eq(p.rows[0].label.text, line)
	m.on_drift_step(true, 1.5)
	assert_eq(p.rows[0].label.text, line, "no running total for the unbroken drift")
	assert_eq(MissionPage.goal_template("extended_drift", "seconds"),
		String(MissionPage.texts()["goals"]["extended_drift"]))


func test_count_goals_keep_their_lines() -> void:
	_with_stand_in()
	assert_eq(MissionPage.goal_text("alternate_drift", "count", 2.0, 4.0), "Alt drifts 2/4")
	assert_eq(MissionPage.goal_text("airtime", "count", 1.0, 3.0),
		String(MissionPage.texts()["goals"]["airtime"]).replace("{seconds}", "3"),
		"an airtime count goal is no running total")


func test_the_real_file_airtime_line() -> void:
	# T-564's line when it is in (with {done}), else the goal's usual line (the seam's fallback).
	var totals: Variant = MissionPage.texts().get(MissionPage.TOTAL_GOALS_KEY, {})
	var line := MissionPage.goal_text("airtime", "seconds", 1.26, 4.0)
	assert_false("{" in line, "no unfilled slot in '%s'" % line)
	if totals is Dictionary and (totals as Dictionary).has("airtime"):
		assert_true(String(totals["airtime"]).contains("{done}"), "T-564's line shows the total")
		assert_true(line.contains("1.2"), "the running total is in '%s'" % line)
	else:
		assert_eq(line, String(MissionPage.texts()["goals"]["airtime"]).replace("{seconds}", "4"))
