extends GutTest
## Task T-561: the tutorial's practice session (practice_session.gd). It loads the practice
## playground (until T-560's level is in, the stand-in) with the real car and none of the run's
## enemies, clock or damage; counts its one trick and no other, and signals on the third; shows
## the goal and its count in the real notebook; the grind's practice opens with the Jump gift
## and gives Jump when taken; it pauses only itself; the car resets on leaving and on R.

const SessionScene := preload("res://scenes/run/practice_session.tscn")
const CarScript := preload("res://scripts/driving/car.gd")

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
	return session.notebook.rows[0].label.text


# ---- The scene --------------------------------------------------------------------------------

func test_it_loads_the_playground_with_the_real_car_and_no_enemies_clock_or_damage() -> void:
	assert_eq(session.map.layout_path, PracticeSession.PLAYGROUND_PATH)
	assert_eq(session.car.get_script(), CarScript, "the game's own car")
	assert_eq(session.car.ground, session.elevation.ground_height, "the car's real height")
	assert_eq(session.elevation.areas.size(), 2, "the stand-in's rooftop and ramp")
	assert_eq(session.car.grind.rails.size(), 1, "the stand-in's rail goes to the car")
	assert_not_null(session.ground, "no painted ground: the drift prototype's grid")
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


func test_the_car_starts_on_the_tricks_start_point() -> void:
	for t in PracticeSession.TRICKS:
		session.setup(t)
		var s: Dictionary = session.map.layout.practice_starts[t]
		assert_almost_eq(session.car.model.get_position(), Vector2(s.x, s.y), Vector2(0.001, 0.001), t)
		assert_almost_eq(session.car.model.rotation, deg_to_rad(float(s.heading)), 0.001, t)


func test_a_level_without_practice_starts_starts_every_trick_on_its_spawn() -> void:
	session.map.layout.erase("practice_starts")
	var p: Dictionary = session.start_point("grind")
	assert_eq(p.position, LevelSpawn.position_of(session.map.layout))


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
	assert_eq(session.successes, 3, "%s: the count stays at 3" % trick)
	assert_eq(completions, 1)
	assert_eq(counted.size(), 3)


func test_the_drift_practice_counts_long_drifts_only() -> void:
	_check_counts("drift", ["extended_drift"],
		["alternate_drift", "three_sixty", "air_one_eighty", "air_three_sixty", "airtime", "rail_grind"])


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


func test_a_real_drift_of_over_a_second_counts_when_it_ends() -> void:
	session.setup("drift")
	session.start()  # a paused session's bodies are out of the physics space
	session.set_focused(true)
	var car = session.car
	car.use_keyboard = false
	car.scripted_input = [true, false, 1.0]  # W + A: drifting
	for i in 75:  # 1.5 s at 50 steps a second
		car.physics_step()
	assert_true(car.model.is_drifting)
	assert_eq(session.successes, 0, "a drift pays when it ends")
	car.scripted_input = [false, false, 0.0]
	for i in 25:
		car.physics_step()
	assert_eq(session.successes, 1)
	assert_eq(counted[0][0], "extended_drift")


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
		assert_eq(_goal_line(), template.replace("{done}", "0").replace("{total}", "3"), t)
	session.setup("drift")
	var drift := PracticeSession.goal_template("drift")
	assert_eq(_goal_line(), drift.replace("{done}", "0").replace("{total}", "3"))
	_do("extended_drift")
	assert_eq(_goal_line(), drift.replace("{done}", "1").replace("{total}", "3"))
	_do("extended_drift")
	_do("extended_drift")
	assert_eq(_goal_line(), drift.replace("{done}", "3").replace("{total}", "3"))
	assert_true(session.notebook.rows[0].ticked, "the goal is ticked on the third")


func test_the_goal_lines_are_t559s_texts_word_for_word() -> void:
	var goals: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(PracticeSession.TEXTS_PATH))["tutorial"]["goal"]
	var keys := {"drift": "drift", "alt_drift": "altdrift", "air_spin": "airspin", "grind": "grind"}
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


func test_a_real_hop_onto_the_rail_counts_a_grind() -> void:
	session.setup("grind")
	session.start()
	session.gift_screen.skip_animation()
	session.take_gift()
	session.set_focused(true)
	var car = session.car
	car.use_keyboard = false
	car.model.set_position(Vector2(-20.0, 16.0))
	car.model.rotation = -PI / 2.0
	car.model.set_velocity(Vector2(0, -11.0))
	car.position = Vector2(-20.0, 16.0) * 16.0
	car.press_jump()
	car.scripted_jump_held = true
	for i in 80:
		car.physics_step()
		if car.grind.active:
			break
	assert_true(car.grind.active, "caught the rail from a hop")
	for i in 600:
		car.physics_step()
		if not car.grind.active:
			break
	assert_false(car.grind.active)
	assert_eq(session.successes, 1)
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
	assert_false(session.in_area(Vector2(60.0, 0.0)))
	session.car.model.set_position(Vector2(60.0, 0.0))
	session.car.stepped.emit()
	await wait_process_frames(1)
	assert_eq(session.car.model.get_position(), start)


func test_the_count_survives_a_car_reset() -> void:
	session.setup("alt_drift")
	_do("alternate_drift")
	session.reset_car()
	_do("alternate_drift")
	assert_eq(session.successes, 2)


func test_driving_up_the_stand_ins_ramp_takes_off() -> void:
	session.setup("air_spin")
	session.start()
	session.set_focused(true)
	var car = session.car
	car.use_keyboard = false
	car.scripted_input = [true, false, 0.0]
	var flew := false
	var top := 0.0
	for i in 200:
		car.physics_step()
		top = maxf(top, car.height)
		if car.airborne and car.model.get_position().x < 14.0:
			flew = true
	gut.p("top height %.2f, at %s, speed %.2f" % [top, car.model.get_position(), car.model.get_velocity().length()])
	assert_true(flew, "flies off the ramp's top")
