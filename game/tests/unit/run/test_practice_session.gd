extends GutTest
## Task T-561: the tutorial's practice session (practice_session.gd). It loads the practice
## playground (T-560's level) with the real car and none of the run's
## enemies, clock or damage; counts its one trick and no other, and signals on the third; shows
## the goal and its count in the real notebook; the grind's practice opens with the Jump gift
## and gives Jump when taken; it pauses only itself; the car resets on leaving and on R.

const SessionScene := preload("res://scenes/run/practice_session.tscn")
const CarScript := preload("res://scripts/driving/car.gd")
const Rails := preload("res://scripts/level/rails.gd")

var session: PracticeSession
var counted: Array = []
var completions := 0


func before_each() -> void:
	session = SessionScene.instantiate()
	add_child_autofree(session)
	counted = []
	completions = 0
	session.trick_counted.connect(func(id: String, done: int) -> void: counted.append([id, done]))
	session.completed.connect(func() -> void: completions += 1)


func after_each() -> void:
	get_tree().paused = false


## Sends one of the car's tricks as the car does, then ends the car's step.
func _do(trick_id: String) -> void:
	var car = session.car
	match trick_id:
		"airtime":
			car.airtime_trick.emit(1.0)
		"rail_grind":
			car.grind.grind_ended.emit("end", 1.0, 6.0)
		"extended_drift":
			car.tricks.last_trick_seconds = 1.2
			car.trick.emit(trick_id)
		_:
			car.trick.emit(trick_id)
	car.stepped.emit()


func _goal_line() -> String:
	session.notebook.finish_falls()  # T-563: the count arrives when the name box has landed
	return session.notebook.rows[0].label.text


# ---- The scene --------------------------------------------------------------------------------

func test_it_loads_the_playground_with_the_real_car_and_no_enemies_clock_or_damage() -> void:
	assert_eq(session.map.layout_path, PracticeSession.PLAYGROUND_PATH)
	assert_eq(session.car.get_script(), CarScript, "the game's own car")
	assert_eq(session.car.ground, session.elevation.ground_height, "the car's real height")
	var layout: Dictionary = session.map.layout
	assert_eq(session.elevation.areas.size(), layout.platforms.size() + layout.ramps.size(),
		"the playground's rooftop and ramps")
	assert_eq(session.car.grind.rails.size(), Rails.from_layout(layout).size(), "its rails go to the car")
	assert_gt(session.car.grind.rails.size(), 0)
	assert_false(session.map.grid_style.is_empty(), "the level's own grid ground")
	for n in ["Minions", "Kaiju", "Weapons", "GiftDrops", "LevelUpScreen", "Hud", "Sounds"]:
		assert_null(session.find_child(n, true, false), "no %s" % n)
	assert_eq(session.state.process_mode, Node.PROCESS_MODE_DISABLED, "the clock never runs")
	var before: float = session.state.time_left
	session.start()
	await wait_physics_frames(5)
	assert_eq(session.state.time_left, before)
	assert_eq(session.state.health, session.state.max_health)
	session.state.collision()  # a crash cuts the combo, as in the run, and costs no health
	assert_eq(session.state.health, session.state.max_health)


func test_every_slide_starts_on_the_levels_spawn() -> void:
	# T-574 (the board: "the spawnpoint is different for each slide please fix it"): one start for all.
	var layout: Dictionary = session.map.layout
	for t in PracticeSession.TRICKS:
		session.setup(t)
		assert_almost_eq(session.car.model.get_position(), LevelSpawn.position_of(layout), Vector2(0.001, 0.001), t)
		assert_almost_eq(session.car.model.rotation, LevelSpawn.rotation_of(layout), 0.001, t)
	assert_false(layout.has("start_points"), "the playground keeps no per-slide start points")


# ---- Counting ---------------------------------------------------------------------------------

func _check_counts(trick: String, counts: Array, others: Array) -> void:
	session.setup(trick)
	counted = []
	completions = 0
	for o in others:
		_do(o)
	assert_eq(session.successes, 0, "%s: the other tricks don't count" % trick)
	for i in 3:
		_do(counts[i % counts.size()])
		assert_eq(session.successes, i + 1, "%s: success %d" % [trick, i + 1])
		assert_eq(completions, 1 if i == 2 else 0, "%s: completed only on the third" % trick)
	_do(counts[0])
	_do(counts[0])
	assert_eq(session.successes, 5, "%s: the count overfills past 3 (T-574)" % trick)
	assert_eq(completions, 1, "completed once")
	assert_eq(counted.size(), 5)
	session.notebook.finish_falls()
	assert_true(session.notebook.rows[0].label.text.contains("5/3"), "%s: the notebook shows 5/3: %s" % [trick, session.notebook.rows[0].label.text])


## T-565: the drift slide counts seconds of drifting, not tricks: no trick counts, LONG DRIFT! either.
func test_the_drift_practice_counts_no_trick() -> void:
	session.setup("drift")
	for o in ["extended_drift", "alternate_drift", "three_sixty", "air_one_eighty", "air_three_sixty",
			"airtime", "rail_grind"]:
		_do(o)
	assert_eq(session.successes, 0)
	assert_eq(session.drift_seconds, 0.0, "a trick adds no drift seconds")
	assert_eq(counted.size(), 0)
	assert_eq(completions, 0)


func test_the_drift_practice_adds_drift_seconds_up_and_completes_at_3_s() -> void:
	session.setup("drift")
	var totals: Array = []
	session.seconds_progress.connect(func(done: float, goal: float) -> void: totals.append([done, goal]))
	session.add_drift_seconds(1.2)
	session.add_drift_seconds(0.4)  # a drift too short to pay counts too
	assert_almost_eq(session.drift_seconds, 1.6, 0.0001)
	assert_eq(completions, 0)
	assert_false(session.is_completed())
	session.add_drift_seconds(1.3)
	assert_eq(completions, 0, "2.9 s is not 3 s")
	session.add_drift_seconds(0.5)
	assert_almost_eq(session.drift_seconds, 3.4, 0.0001, "the total runs on past 3 s (T-574)")
	assert_eq(completions, 1, "completed when the total reaches 3 s")
	assert_true(session.is_completed())
	session.add_drift_seconds(1.0)
	assert_eq(completions, 1, "completed once")
	assert_eq(totals.size(), 5)
	assert_almost_eq(float(totals[4][0]), 4.4, 0.0001)
	session.notebook.finish_falls()
	assert_true(session.notebook.rows[0].label.text.contains("4.4/3"), "the notebook overfills: %s" % session.notebook.rows[0].label.text)


func test_the_other_slides_still_count_3_tricks() -> void:
	for t in ["alt_drift", "air_spin", "grind"]:
		session.setup(t)
		session.add_drift_seconds(5.0)
		assert_eq(session.drift_seconds, 0.0, "%s: drift seconds count only on the drift slide" % t)
		assert_false(session.is_completed(), t)
		assert_eq(session.missions.current_goals()[0]["kind"], RunMissions.KIND_COUNT, t)
		assert_eq(session.missions.current_goals()[0]["amount"], 3, t)


func test_the_alt_drift_practice_counts_alt_drifts_only() -> void:
	_check_counts("alt_drift", ["alternate_drift"],
		["extended_drift", "three_sixty", "air_one_eighty", "air_three_sixty", "airtime", "rail_grind"])


func test_the_air_spin_practice_counts_air_180s_and_air_360s_only() -> void:
	_check_counts("air_spin", ["air_one_eighty", "air_three_sixty"],
		["extended_drift", "alternate_drift", "three_sixty", "airtime", "rail_grind"])


func test_the_grind_practice_counts_grinds_only() -> void:
	_check_counts("grind", ["rail_grind"],
		["extended_drift", "alternate_drift", "three_sixty", "air_one_eighty", "air_three_sixty", "airtime"])


func test_one_landing_that_pays_an_air_360_and_an_air_180_counts_once() -> void:
	session.setup("air_spin")
	session.car.trick.emit("air_three_sixty")
	session.car.trick.emit("air_one_eighty")
	session.car.stepped.emit()
	assert_eq(session.successes, 1)
	_do("air_one_eighty")
	assert_eq(session.successes, 2, "the next landing counts again")


func test_a_grind_too_short_to_pay_does_not_count() -> void:
	session.setup("grind")
	session.car.grind.grind_ended.emit("end", 0.05, 0.5)
	assert_eq(session.successes, 0)


## T-565: the real car's drifting adds up over two drifts, live, and completes at 3 s in total.
func test_real_drifts_add_up_live_and_complete_at_3_s_in_total() -> void:
	session.setup("drift")
	session.start()  # a paused session's bodies are out of the physics space
	session.set_focused(true)
	var car = session.car
	car.use_keyboard = false
	var drifted := 0.0
	car.scripted_input = [true, false, 1.0]  # W + A: drifting
	for i in 50:
		car.physics_step()
		if car.model.is_drifting:
			drifted += car.model.dt
	assert_true(car.model.is_drifting)
	assert_gt(session.drift_seconds, 0.0, "the total grows while the drift goes on")
	assert_almost_eq(session.drift_seconds, drifted, 0.0001, "every drifting step adds its seconds")
	assert_almost_eq(float(session.missions.current_goals()[0]["done"]), drifted, 0.0001)
	var first := session.drift_seconds
	car.scripted_input = [false, false, 0.0]
	var steps := 0
	while car.model.is_drifting and steps < 200:
		car.physics_step()
		steps += 1
	assert_false(car.model.is_drifting)
	var after_first := session.drift_seconds
	assert_gt(after_first, first - 0.0001)
	for i in 20:
		car.physics_step()
	assert_almost_eq(session.drift_seconds, after_first, 0.0001, "the total stays between drifts")
	assert_eq(completions, 0)
	car.scripted_input = [true, false, 1.0]
	var guard := 0
	while completions == 0 and guard < 600:
		car.physics_step()
		guard += 1
	assert_eq(completions, 1, "the second drift tops the total up to 3 s")
	assert_gte(session.drift_seconds, 3.0 - RunMissions.EPSILON)
	assert_eq(counted.size(), 0, "no trick counted")
	session.notebook.finish_falls()
	assert_true(session.notebook.rows[0].ticked)


func test_restart_starts_the_count_over() -> void:
	session.setup("alt_drift")
	_do("alternate_drift")
	_do("alternate_drift")
	session.restart()
	assert_eq(session.successes, 0)
	assert_eq(_goal_line(), PracticeSession.goal_template("alt_drift").replace("{done}", "0").replace("{total}", "3"))


# ---- The notebook -----------------------------------------------------------------------------

func test_the_notebook_shows_the_goal_and_its_count() -> void:
	for t in PracticeSession.TRICKS:
		session.setup(t)
		assert_true(session.notebook.visible, t)
		assert_eq(session.notebook.rows.size(), 1, "%s: one goal" % t)
		var template := PracticeSession.goal_template(t)
		var zero := "0.0" if t == "drift" else "0"  # T-565: the drift's seconds, one decimal
		var goal := "3.0" if t == "drift" else "3"
		assert_eq(_goal_line(), template.replace("{done}", zero).replace("{total}", goal), t)
	session.setup("alt_drift")
	var alt := PracticeSession.goal_template("alt_drift")
	_do("alternate_drift")
	assert_eq(_goal_line(), alt.replace("{done}", "1").replace("{total}", "3"))
	_do("alternate_drift")
	_do("alternate_drift")
	assert_eq(_goal_line(), alt.replace("{done}", "3").replace("{total}", "3"))
	session.notebook.finish_falls()
	assert_true(session.notebook.rows[0].ticked, "the goal is ticked on the third")


## T-565: the drift's line shows the running total live (no name box to wait for).
func test_the_drift_notebook_line_shows_the_running_total_live() -> void:
	session.setup("drift")
	var drift := PracticeSession.goal_template("drift")
	session.add_drift_seconds(0.46)
	assert_false(session.notebook.is_falling(), "no name box for a fraction of a second")
	assert_eq(session.notebook.rows[0].label.text, drift.replace("{done}", "0.4").replace("{total}", "3.0"))
	session.add_drift_seconds(1.0)
	assert_eq(session.notebook.rows[0].label.text, drift.replace("{done}", "1.4").replace("{total}", "3.0"))
	session.add_drift_seconds(2.0)
	# T-574: the total overfills past 3 s (3.46 shows 3.4, cut to one decimal as before).
	assert_eq(session.notebook.rows[0].label.text, drift.replace("{done}", "3.4").replace("{total}", "3.0"))
	assert_true(session.notebook.rows[0].ticked, "ticked at 3 s")


func test_the_goal_lines_are_t559s_texts_word_for_word() -> void:
	var goals: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(PracticeSession.TEXTS_PATH))["tutorial"]["goal"]
	var keys := {"drift": "drift", "alt_drift": "altdrift", "air_spin": "airspin", "grind": "grind"}
	# T-565: the drift's line is T-564's seconds line, written in place of T-559's.
	keys["drift"] = PracticeSession.DRIFT_SECONDS_TEXT_KEYS[2]
	for t in PracticeSession.TRICKS:
		var line := PracticeSession.goal_template(t)
		assert_eq(line, String(goals[keys[t]]), t)
		assert_true(line.contains("{done}") and line.contains("{total}"), "%s has the counter" % t)


func test_the_run_notebook_keeps_its_own_lines() -> void:
	var page := MissionPage.new()
	autofree(page)
	assert_eq(page.line_text("alternate_drift", "count", 1.0, 4.0), "Alt drifts 1/4")
	page.goal_templates = {"alternate_drift": "X {done}/{total}"}
	assert_eq(page.line_text("alternate_drift", "count", 1.0, 4.0), "X 1/4")


func test_missions_start_with_holds_exactly_the_given_mission() -> void:
	var m := RunMissions.new()
	var started: Array = []
	m.mission_started.connect(func(i: int) -> void: started.append(i))
	m.start_with([[{"trick": "air_spin", "kind": "count", "amount": 3}]])
	assert_eq(m.count(), 1)
	assert_eq(started, [0])
	m.on_trick("air_spin")
	assert_eq(m.current_goals()[0].done, 1.0)


# ---- The grind's Jump gift --------------------------------------------------------------------

func test_the_grind_practice_opens_with_the_jump_gift_and_gives_jump_when_taken() -> void:
	session.setup("grind")
	assert_false(session.is_gift_open(), "not before the slide starts the practice")
	var opened := [0]
	session.gift_opened.connect(func() -> void: opened[0] += 1)
	session.start()
	assert_eq(opened[0], 1)
	assert_true(session.is_gift_open())
	assert_true(session.gift_screen.is_open(), "the real power-up overlay")
	assert_eq(session.gift_screen.cards.size(), 1, "one choice")
	assert_eq(session.gift_screen.cards[0].id, "jump")
	assert_false(session.is_running(), "the practice waits for the choice")
	assert_eq(session.world.process_mode, Node.PROCESS_MODE_DISABLED)
	assert_false(get_tree().paused, "only the practice pauses, never the tree")
	assert_eq(session.car.jump.tier, 0)
	session.gift_screen.skip_animation()
	session.take_gift()
	assert_false(session.is_gift_open())
	assert_eq(session.state.power_up_tier("jump"), 1)
	assert_eq(session.car.jump.tier, 1, "the car has Jump")
	assert_true(session.is_running())
	assert_eq(session.world.process_mode, Node.PROCESS_MODE_INHERIT)
	session.pause()
	session.start()
	assert_false(session.is_gift_open(), "the gift opens once per practice")


func test_the_other_practices_open_no_gift() -> void:
	for t in ["drift", "alt_drift", "air_spin"]:
		session.setup(t)
		session.start()
		assert_false(session.is_gift_open(), t)
		assert_eq(session.car.jump.tier, 0, t)
		session.pause()


func test_on_the_real_playground_a_grind_from_the_grind_start_counts() -> void:
	session.setup("grind")
	session.start()
	session.gift_screen.skip_animation()
	session.take_gift()
	assert_eq(session.car.jump.tier, 1)
	var r := _route(GRIND_ROUTE, 99, false, 2, 6.0)
	assert_ne(r.caught, "", "a rail is caught with a hop from the grind start")
	assert_eq(session.successes, 1, "the grind counts when it ends: %s" % [r])
	assert_eq(counted[0][0], "rail_grind")


# ---- Pause, focus and reset -------------------------------------------------------------------

func test_it_starts_paused_and_pauses_only_itself() -> void:
	assert_false(session.is_running())
	assert_eq(session.world.process_mode, Node.PROCESS_MODE_DISABLED)
	session.start()
	assert_true(session.is_running())
	assert_eq(session.world.process_mode, Node.PROCESS_MODE_INHERIT)
	session.pause()
	assert_false(session.is_running())
	assert_eq(session.world.process_mode, Node.PROCESS_MODE_DISABLED)
	assert_false(get_tree().paused)


func test_the_car_reads_the_keys_only_while_the_window_has_focus() -> void:
	assert_false(session.car.input_enabled, "no focus at first")
	session.set_focused(true)
	assert_true(session.car.input_enabled)
	session.reset_car()
	assert_true(session.car.input_enabled, "a reset car keeps the focus")
	session.set_focused(false)
	assert_false(session.car.input_enabled)


func test_r_puts_the_car_back_at_its_start_while_focused() -> void:
	session.setup("drift")
	var start: Vector2 = session.start_point().position
	session.car.model.set_position(Vector2(-30.0, -30.0))
	var key := InputEventKey.new()
	key.physical_keycode = KEY_R
	key.pressed = true
	session._unhandled_input(key)
	assert_eq(session.car.model.get_position(), Vector2(-30.0, -30.0), "not without focus")
	session.set_focused(true)
	var resets := [0]
	session.car_reset.connect(func() -> void: resets[0] += 1)
	session._unhandled_input(key)
	assert_eq(session.car.model.get_position(), start)
	assert_eq(resets[0], 1)


func test_leaving_the_playground_puts_the_car_back() -> void:
	session.setup("air_spin")
	var start: Vector2 = session.start_point().position
	assert_true(session.in_area(start))
	assert_false(session.in_area(Vector2(70.0, 0.0)))
	session.car.model.set_position(Vector2(70.0, 0.0))
	session.car.stepped.emit()
	await wait_process_frames(1)
	assert_eq(session.car.model.get_position(), start)


func test_the_count_survives_a_car_reset() -> void:
	session.setup("alt_drift")
	_do("alternate_drift")
	session.reset_car()
	_do("alternate_drift")
	assert_eq(session.successes, 2)


## T-574: drives from the spawn along `pts` (units) with W held, steering toward each point in turn
## (the car stepped by the test; A, steer +1, turns the nose to a smaller rotation). Below
## `slow_until` (a point index) W is let go above `slow_speed` units/s, so the turns stay tight. `spin`: A held
## in the air. `hop_at`: Space pressed on reaching that point (the grind's Jump) and held in the air
## and on the rail. Stops after the first landing, or once a grind ended.
func _route(pts: Array, slow_until: int, spin: bool, hop_at := -1, slow_speed := 8.0) -> Dictionary:
	session.set_focused(true)
	var car = session.car
	car.use_keyboard = false
	var out := {"caught": "", "flew": false, "reached": 0}
	var wi := 0
	var pressed := false
	for i in 1500:
		var pos: Vector2 = car.model.get_position()
		if wi < pts.size() and pos.distance_to(pts[wi]) < 3.5:
			if wi == hop_at and not pressed and not car.airborne:
				car.press_jump()
				pressed = true
			wi += 1
		var steer := 0.0
		if car.airborne:
			steer = 1.0 if spin else 0.0
		elif wi < pts.size():
			var diff := wrapf((pts[wi] - pos).angle() - car.model.rotation, -PI, PI)
			steer = -clampf(diff * 3.0, -1.0, 1.0)
		var slow: bool = wi < slow_until and car.model.get_velocity().length() > slow_speed
		car.scripted_input = [not slow, false, steer]
		car.scripted_jump_held = pressed and (car.airborne or car.grind.active)
		car.physics_step()
		if car.grind.active:
			out.caught = car.grind.rail.id
		if car.airborne:
			out.flew = true
		if out.flew and not car.airborne and not car.grind.active:
			break
	out.reached = wi
	out["end"] = car.model.get_position()
	return out


## From the spawn (-4.25, 1 since T-604) to the jump ramp ramp-7 (x -2 to 2, y 20 to 28): south-west
## round the ramp, wide to (-32, 22.5) so the car is turned east before it speeds up (T-604: from the
## new spawn the old, tighter turn made the car circle), then east along y 22.5 at full speed.
const AIR_ROUTE := [Vector2(-10, 8), Vector2(-20, 14), Vector2(-30, 18), Vector2(-32, 22.5),
	Vector2(-24, 22.5), Vector2(-12, 22.5), Vector2(4, 22.5)]
## From the spawn to the grind corridor: round to the west, a hop at (-14, 2) onto rail-40 (T-604:
## the first two points moved for the new spawn).
const GRIND_ROUTE := [Vector2(2, 6), Vector2(-6, 7), Vector2(-14, 2), Vector2(-30, 2)]


func test_on_the_real_playground_an_air_spin_from_the_air_spin_start_counts() -> void:
	session.setup("air_spin")
	session.start()
	var r := _route(AIR_ROUTE, 4, true)
	assert_true(r.flew, "flew off the jump ramp")
	assert_eq(session.successes, 1, "one landing, one success: %s %s" % [r, counted])
	assert_true(["air_one_eighty", "air_three_sixty"].has(counted[0][0]))


func test_on_the_real_playground_an_alt_drift_from_the_alt_drift_start_counts() -> void:
	session.setup("alt_drift")
	session.start()
	session.set_focused(true)
	var car = session.car
	car.use_keyboard = false
	for leg in [[1.0, true, false], [0.2, false, false], [1.0, false, true]]:  # forward, release, backward
		car.scripted_input = [leg[1], leg[2], 1.0]
		for i in roundi(float(leg[0]) * 50.0):
			car.physics_step()
	assert_eq(session.successes, 1, "%s" % [counted])
	assert_eq(counted[0][0], "alternate_drift")


func test_the_goal_done_stamps_a_green_check_on_the_notebook_and_restart_clears_it() -> void:
	# T-574 (the board): a green check stamp on the notebook page when the goal is done, no text.
	session.setup("alt_drift")
	assert_false(session.is_stamped(), "no stamp at first")
	assert_true(session.notebook.is_ancestor_of(session.stamp), "the stamp lives on the notebook page")
	_do("alternate_drift")
	_do("alternate_drift")
	assert_false(session.is_stamped(), "no stamp before the goal")
	_do("alternate_drift")
	assert_true(session.is_stamped(), "stamped on the third")
	assert_eq(session.stamp.get_child_count(), 0, "drawn in code: no label, no text")
	assert_lt(session.stamp.position.x + session.stamp.size.x, session.notebook.size.x + 20.0, "on the page")
	session.restart()
	assert_false(session.is_stamped(), "a restart clears it")
	session.setup("drift")
	session.add_drift_seconds(3.0)
	assert_true(session.is_stamped(), "the drift slide too, at 3 s")


func test_tricks_past_the_goal_drop_their_name_box_onto_the_notebook() -> void:
	# T-574: the falling name boxes go on landing for tricks past the goal.
	session.setup("grind")
	for i in 3:
		_do("rail_grind")
	session.notebook.finish_falls()
	assert_false(session.notebook.is_falling())
	_do("rail_grind")
	assert_true(session.notebook.is_falling(), "the fourth grind's box falls")
	assert_true(session.notebook.rows[0].label.text.contains("3/3"), "its count arrives when the box lands")
	session.notebook.finish_falls()
	assert_true(session.notebook.rows[0].label.text.contains("4/3"))
	assert_true(session.is_stamped(), "the stamp stays")


func test_the_board_s_pairs_are_live_and_threading_one_pays_the_trick_as_in_a_run() -> void:
	# T-574 tweak 6 (the board): the pairs made in the level creator work in the practice windows.
	var layout: Dictionary = session.map.layout
	assert_false(layout.get("pairs", []).is_empty(), "the board's playground has pairs")
	var ids: Array = session.needle.gates.map(func(g): return g.id)
	for p in layout.pairs:
		assert_true(ids.has(p.id), "%s is a live gate" % p.id)
	assert_not_null(session.map.view_root.find_child("NeedleMarkers", true, false), "the markers are drawn")
	assert_not_null(session.needle_flash, "the flash, as in the run")
	# pair-1: prop-2 (centre 15, -2.5) and prop-1 (centre 16, 11 since T-604); drive east across its gap at y 4.25.
	session.setup("alt_drift")
	session.start()
	session.set_focused(true)
	var car = session.car
	car.use_keyboard = false
	car.model.set_position(Vector2(9.0, 4.25))
	car.model.rotation = 0.0
	var paid: Array = []
	session.state.combo_trick.connect(func(id: String, _a: float, _m: float) -> void: paid.append(id))
	car.scripted_input = [true, false, 0.0]
	for i in 60:
		car.physics_step()
	assert_true(paid.has(RunState.TRICK_THREAD_THE_NEEDLE), "THREAD THE NEEDLE! paid: %s" % [paid])
	assert_eq(session.successes, 0, "it counts toward no slide's goal")


## Steps the car `seconds` standing still (no keys), as the window does each physics frame.
func _idle(seconds: float) -> void:
	var car = session.car
	car.use_keyboard = false
	car.scripted_input = [false, false, 0.0]
	for i in roundi(seconds * 50.0):
		car.physics_step()


func test_the_combo_breaks_again_and_drains_as_in_a_run_with_no_damage() -> void:
	# T-574 tweak 7 (the board: "in the practice, the combo can't be broken, and I want it to be able
	# to be broken"): the frozen run clock kept the collision window shut after the first cut, and the
	# drain never ran. Now each car step moves the combo's clock.
	session.setup("alt_drift")
	session.start()
	var broken: Array = []  # a lambda captures an int by value: count in an array
	session.state.combo_broken.connect(func() -> void: broken.append(1))
	var start_combo: float = session.state.combo
	for n in 3:
		session.state.add_trick("alternate_drift")
		assert_gt(session.state.combo, start_combo, "a combo going")
		session.state.collision()
		assert_eq(broken.size(), n + 1, "hit %d breaks it" % (n + 1))
		_idle(1.0)  # past combo.json's collision window
	assert_eq(session.state.health, session.state.max_health, "no damage, no hearts lost")
	assert_eq(session.state.time_left, session.state.RUN_SECONDS, "the run's clock still never runs")
	# The drain: a combo left alone drops after the wait.
	session.state.add_trick("alternate_drift")
	session.state.add_trick("alternate_drift")
	var high: float = session.state.combo
	_idle(ComboData.new().drain_wait_seconds() + 1.0)
	assert_lt(session.state.combo, high, "the combo drains when left idle")
	# The popup: COMBO BROKEN! as in the run (the trick popups hear combo_broken).
	assert_true(session.state.combo_broken.is_connected(session.trick_popups._on_combo_broken))
