extends GutTest
## Task T-563: a trick that counts toward a mission goal falls into the notebook as a small
## box with the trick's name, splashes on the goal line, and only then the count updates.

const FIRST_GOAL_TRICK := "extended_drift"


func _page() -> MissionPage:
	var m := RunMissions.new()
	m.start(7)
	var p := MissionPage.new()
	add_child_autofree(p)
	p.bind(m)
	return p


## Moves on to the mission whose goal is a count of `trick` (alt drifts, mission 2).
func _page_on_alt_drifts() -> MissionPage:
	var p := _page()
	p._missions.on_drift_step(true, 5.0)  # mission 1: one 5 s drift
	p.finish_falls()
	return p


func test_a_counting_trick_plays_a_box_with_its_name_and_the_count_waits() -> void:
	var p := _page_on_alt_drifts()
	assert_eq(p.rows[0].label.text, "Alt drifts 0/10")
	p._missions.on_trick("alternate_drift")
	assert_true(p.is_falling())
	assert_eq(p._falls[0]["text"], "ALT DRIFT!")
	assert_eq(p.rows[0].label.text, "Alt drifts 0/10", "the count waits for the landing")
	p.advance(MissionPage.FALL_TIME * 0.5)
	assert_eq(p.rows[0].label.text, "Alt drifts 0/10")
	var mid := p.box_state(p._falls[0])
	assert_lt(float(mid["y"]), float(p._falls[0]["land_y"]))
	assert_gt(float(mid["y"]), MissionPage.BOX_START_Y)
	p.advance(MissionPage.FALL_TIME * 0.6)
	assert_eq(p.rows[0].label.text, "Alt drifts 1/10", "landed: the count updates")
	assert_true(p.is_falling(), "the splash is still playing")
	p.advance(MissionPage.SPLASH_TIME + 0.1)
	assert_false(p.is_falling())


func test_a_trick_that_does_not_count_plays_nothing() -> void:
	var p := _page_on_alt_drifts()
	p._missions.on_trick("rail_grind")  # not a goal of this mission
	p._missions.on_trick("air_one_eighty")
	assert_false(p.is_falling())
	assert_eq(p.rows[0].label.text, "Alt drifts 0/10")


func test_the_box_lands_on_its_goal_line() -> void:
	var p := _page_on_alt_drifts()
	p._missions.on_trick("alternate_drift")
	var f: Dictionary = p._falls[0]
	var row: MissionPage.Row = p.rows[0]
	assert_almost_eq(float(f["land_y"]) + MissionPage.BOX_H * 0.5, row.position.y + 2.0, 0.01)
	assert_lt(MissionPage.BOX_START_Y + MissionPage.BOX_H, 0.0, "it starts above the page's top")


func test_quick_tricks_queue_in_order_and_every_count_arrives() -> void:
	var p := _page_on_alt_drifts()
	for i in 3:
		p._missions.on_trick("alternate_drift")
	assert_eq(p._falls.size(), 3)
	var s0: float = p._falls[0]["start"]
	var s1: float = p._falls[1]["start"]
	assert_gte(s1 - s0, MissionPage.FALL_GAP - 0.001, "boxes do not stack on each other")
	assert_eq(p.rows[0].label.text, "Alt drifts 0/10")
	assert_eq(p.rows.size(), 1, "the page is intact")
	var seen := []
	for i in 40:
		p.advance(0.05)
		seen.append(p.rows[0].label.text)
	assert_eq(p.rows[0].label.text, "Alt drifts 3/10")
	assert_true(seen.has("Alt drifts 1/10") and seen.has("Alt drifts 2/10"), "one step at a time")
	assert_true(p.header_label.is_inside_tree() and p.visible)


func test_a_burst_never_hides_the_count_or_grows_the_queue_without_end() -> void:
	var p := _page_on_alt_drifts()
	for i in 9:
		p._missions.on_trick("alternate_drift")
	assert_lte(p._falls.size(), MissionPage.MAX_QUEUED)
	p.finish_falls()
	assert_eq(p.rows[0].label.text, "Alt drifts 9/10")
	assert_false(p.is_falling())


func test_the_mission_that_ends_shows_its_last_box_before_the_next_page() -> void:
	var p := _page_on_alt_drifts()
	for i in 9:
		p._missions.on_trick("alternate_drift")
		p.finish_falls()
	p._missions.on_trick("alternate_drift")  # the tenth completes the mission
	assert_eq(p._missions.current_number(), 3)
	assert_eq(p.rows[0].label.text, "Alt drifts 9/10", "still the old page while the box falls")
	p.advance(MissionPage.FALL_TIME + 0.01)
	assert_eq(p.rows.size(), p._missions.current_goals().size())
	assert_false(p.rows[0].ticked, "the next mission's page is on show")


func test_binding_again_drops_pending_boxes() -> void:
	var p := _page_on_alt_drifts()
	p._missions.on_trick("alternate_drift")
	assert_true(p.is_falling())
	var m2 := RunMissions.new()
	m2.start(7)
	p.bind(m2)
	assert_false(p.is_falling())
