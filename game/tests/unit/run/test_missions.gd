extends GutTest
## Task T-457 (Game loop architecture, Decisions, "Mission packs"): the run's mission tracker
## (missions.gd, RunState.missions) and the car's owned driving power-ups in RunState.

const RunStateScript := preload("res://scripts/run/run_state.gd")
const RunMissionsScript := preload("res://scripts/run/missions.gd")
const GameScene := preload("res://scenes/game/game.tscn")
const DT := 1.0 / 60.0

var state: RunState
var events: Array = []


func before_each() -> void:
	state = RunStateScript.new()
	add_child_autofree(state)
	state.mission_seed = 457
	events = []
	var m: RunMissions = state.missions
	m.goal_progress.connect(func(mi: int, gi: int, done: float, total: float) -> void:
		events.append(["progress", mi, gi, done, total]))
	m.goal_completed.connect(func(mi: int, gi: int) -> void: events.append(["goal", mi, gi]))
	m.mission_completed.connect(func(mi: int) -> void: events.append(["mission", mi]))
	state.start_run()


func after_each() -> void:
	get_tree().paused = false


func _of(kind: String) -> Array:
	return events.filter(func(e): return e[0] == kind)


## One unbroken drift of `seconds`, as the run scene feeds it: drift steps, then the step that
## ends it, with the trick detector's extended drift paid in between (car step, then drift_step).
func _drift(seconds: float) -> void:
	var t := 0.0
	while t < seconds - 0.000001:
		state.drift_step(true, DT)
		t += DT
	state.add_trick("extended_drift", seconds)
	state.drift_step(false, DT)


func _missions(seed_value: int) -> Array:
	var m: RunMissions = RunMissionsScript.new()
	m.start(seed_value)
	return m.missions


# --- 30 missions: 5 fixed, 25 generated per seed ------------------------------------

func test_a_new_run_has_30_missions_the_first_5_fixed_the_rest_by_seed() -> void:
	var fixed: Array = MissionData.new().fixed()
	var sets: Array = [_missions(1), _missions(2), _missions(3)]
	for s in sets:
		assert_eq(s.size(), 30, "30 missions a run")
		for i in 5:
			assert_eq(s[i].size(), fixed[i]["goals"].size(), "mission %d's goals" % (i + 1))
			for g in s[i].size():
				assert_eq(s[i][g]["trick"], fixed[i]["goals"][g]["trick"])
				assert_eq(s[i][g]["kind"], fixed[i]["goals"][g]["kind"])
				assert_eq(float(s[i][g]["amount"]), float(fixed[i]["goals"][g]["amount"]))
	for i in 5:
		assert_eq(sets[0][i], sets[1][i], "mission %d is the same for seeds 1 and 2" % (i + 1))
		assert_eq(sets[0][i], sets[2][i], "mission %d is the same for seeds 1 and 3" % (i + 1))
	assert_ne(sets[0].slice(5), sets[1].slice(5), "missions 6 to 30 differ between seeds 1 and 2")
	assert_eq(_missions(7).slice(5), _missions(7).slice(5), "one seed gives the same set")
	assert_eq(state.missions.count(), 30)
	assert_eq(state.missions.current_number(), 1)


func test_generated_missions_follow_the_rules() -> void:
	var data := MissionData.new()
	var s := _missions(99)
	for n in range(6, 31):
		var goals: Array = s[n - 1]
		assert_eq(goals.size(), data.goals_for(n), "mission %d's goal count" % n)
		var tricks := {}
		for g in goals:
			assert_true(data.known_tricks().has(g["trick"]))
			tricks[g["trick"]] = true
		assert_eq(tricks.size(), goals.size(), "no trick twice in mission %d" % n)


func test_each_run_without_a_seed_picks_a_new_one() -> void:
	var m: RunMissions = RunMissionsScript.new()
	var seeds := {}
	for i in 5:
		m.start()
		seeds[m.mission_seed] = true
	assert_gt(seeds.size(), 1, "a new seed each run")


# --- Missions 1 to 5 from trick events ----------------------------------------------

func test_missions_1_to_5_complete_in_order_from_trick_events() -> void:
	var m: RunMissions = state.missions
	# Mission 1: one unbroken drift of 2 seconds.
	_drift(2.1)
	assert_eq(_of("mission"), [["mission", 0]], "mission 1 done")
	assert_true(_of("goal").has(["goal", 0, 0]))
	assert_true(_of("progress").any(func(e): return e[1] == 0 and e[3] == 2.0 and e[4] == 2.0))
	assert_eq(m.current_number(), 2)
	# Mission 2: 10 alt drifts.
	for i in 9:
		state.add_trick("alternate_drift")
	assert_eq(m.current_number(), 2, "9 of 10 alt drifts")
	assert_eq(m.current_goals()[0]["done"], 9.0)
	assert_true(_of("progress").has(["progress", 1, 0, 9.0, 10.0]))
	state.add_trick("alternate_drift")
	assert_true(_of("goal").has(["goal", 1, 0]))
	assert_eq(_of("mission").back(), ["mission", 1])
	assert_eq(m.current_number(), 3)
	# Mission 3: 3 seconds of airtime in total (a short hop that pays nothing counts too).
	state.add_airtime_trick(0.1)
	state.add_airtime_trick(1.4)
	assert_eq(m.current_number(), 3)
	state.add_airtime_trick(1.5)
	assert_eq(_of("mission").back(), ["mission", 2])
	assert_eq(m.current_number(), 4)
	# Mission 4: 3 air 180s (an air 360 does not count for it).
	state.add_trick("air_three_sixty")
	state.add_trick("air_one_eighty")
	state.add_trick("air_one_eighty")
	assert_eq(m.current_number(), 4)
	state.add_trick("air_one_eighty")
	assert_eq(_of("mission").back(), ["mission", 3])
	# Mission 5: an air 360.
	assert_eq(m.current_number(), 5)
	state.add_trick("air_three_sixty")
	assert_eq(_of("mission"), [["mission", 0], ["mission", 1], ["mission", 2], ["mission", 3], ["mission", 4]])
	assert_eq(_of("goal").size(), 5)
	assert_eq(m.current_number(), 6)


func test_signals_come_progress_then_goal_then_mission() -> void:
	state.missions.current = 4  # straight to mission 5
	state.missions._load_current()
	events.clear()
	state.add_trick("air_three_sixty")
	assert_eq(events, [["progress", 4, 0, 1.0, 1.0], ["goal", 4, 0], ["mission", 4]])


func test_a_trick_that_completes_a_mission_does_not_count_for_the_next() -> void:
	var m: RunMissions = state.missions
	m.missions[1] = [{"trick": "alternate_drift", "kind": "count", "amount": 1.0}]
	m.missions[2] = [{"trick": "alternate_drift", "kind": "count", "amount": 2.0}]
	m.current = 1
	m._load_current()
	state.add_trick("alternate_drift")
	assert_eq(m.current_number(), 3)
	assert_eq(m.current_goals()[0]["done"], 0.0)


func test_a_mission_with_several_goals_needs_all_of_them() -> void:
	var m: RunMissions = state.missions
	m.missions[0] = [{"trick": "three_sixty", "kind": "count", "amount": 2.0},
		{"trick": "thread_the_needle", "kind": "count", "amount": 1.0}]
	m._load_current()
	state.add_needle_trick()
	assert_true(_of("goal").has(["goal", 0, 1]))
	assert_eq(_of("mission"), [], "one goal of two")
	state.add_trick("three_sixty")
	state.add_trick("three_sixty")
	assert_eq(_of("mission"), [["mission", 0]])


# --- The continuous drift goal ------------------------------------------------------

func test_two_1_second_drifts_do_not_complete_mission_1_one_2_second_drift_does() -> void:
	var m: RunMissions = state.missions
	_drift(1.0)
	_drift(1.0)
	assert_eq(m.current_number(), 1, "two 1 s drifts are not one 2 s drift")
	assert_eq(_of("mission"), [])
	assert_eq(m.current_goals()[0]["done"], 0.0, "the ended drift starts over")
	_drift(2.0)
	assert_eq(_of("mission"), [["mission", 0]], "one 2 s drift completes it")
	assert_eq(m.current_number(), 2)


func test_a_wall_hit_ends_the_drift_for_the_goal() -> void:
	var m: RunMissions = state.missions
	for i in 90:  # 1.5 s
		state.drift_step(true, DT)
	assert_almost_eq(float(m.current_goals()[0]["done"]), 1.5, 0.001)
	state.collision()
	assert_eq(m.current_goals()[0]["done"], 0.0, "the hit ends the drift")
	for i in 90:  # still drifting after the hit: a new drift of 1.5 s
		state.drift_step(true, DT)
	assert_eq(m.current_number(), 1, "1.5 s + 1.5 s across a wall hit is not 2 s")
	for i in 40:
		state.drift_step(true, DT)
	assert_eq(m.current_number(), 2, "an unbroken 2 s completes it while still drifting")


func test_nothing_counts_when_the_run_is_not_going() -> void:
	state.running = false
	state.add_trick("air_three_sixty")
	state.drift_step(true, 5.0)
	assert_eq(events.filter(func(e): return e[0] != "progress" or e[3] > 0.0), [])
	assert_eq(state.missions.current_number(), 1)


func test_after_mission_30_nothing_more_is_offered() -> void:
	var m: RunMissions = state.missions
	m.current = 29
	m._load_current()
	for g in m.current_goals():
		if g["kind"] == "seconds" and g["trick"] == "extended_drift":
			_drift(float(g["amount"]))
		elif g["trick"] == "airtime":
			state.add_airtime_trick(float(g["amount"]))
		elif g["trick"] == "thread_the_needle":
			for i in int(g["amount"]):
				state.add_needle_trick()
		else:
			for i in int(g["amount"]):
				state.add_trick(g["trick"])
	assert_eq(_of("mission"), [["mission", 29]])
	assert_true(m.is_all_done())
	assert_eq(m.current_index(), -1)
	assert_eq(m.current_goals(), [])
	events.clear()
	state.add_trick("air_three_sixty")
	_drift(10.0)
	assert_eq(events, [], "nothing after mission 30")


# --- A new run, and the power-ups ---------------------------------------------------

func test_a_new_run_resets_to_mission_1_and_clears_power_ups() -> void:
	_drift(2.0)
	state.add_trick("alternate_drift")
	state.grant_power_up("jump")
	assert_eq(state.missions.current_number(), 2)
	var changed := [0]
	state.power_ups_changed.connect(func() -> void: changed[0] += 1)
	state.mission_seed = 458
	state.start_run()
	assert_eq(state.missions.current_number(), 1)
	assert_eq(state.missions.current_goals()[0]["done"], 0.0)
	assert_eq(state.missions.mission_seed, 458, "a fresh set from the new seed")
	assert_eq(state.power_up_tier("jump"), 0)
	assert_eq(state.owned_power_ups(), {})
	assert_eq(changed[0], 1, "power_ups_changed on the new run")


func test_grant_power_up_gives_tier_1_then_tier_2() -> void:
	var changed := [0]
	state.power_ups_changed.connect(func() -> void: changed[0] += 1)
	for id in PowerUpData.IDS:
		assert_eq(state.power_up_tier(id), 0, "%s not owned at the start" % id)
	assert_eq(state.grant_power_up("rev_charge"), 1)
	assert_eq(state.power_up_tier("rev_charge"), 1)
	assert_eq(state.grant_power_up("rev_charge"), 2)
	assert_eq(state.power_up_tier("rev_charge"), 2)
	assert_eq(state.power_up_tier("jump"), 0)
	assert_eq(state.owned_power_ups(), {"rev_charge": 2})
	assert_eq(changed[0], 2)


func test_grant_power_up_stops_at_the_last_tier_and_ignores_unknown_ids() -> void:
	var last := PowerUpData.new().max_tier("jump")
	for i in last + 2:
		state.grant_power_up("jump")
	assert_eq(state.power_up_tier("jump"), last)
	assert_eq(state.grant_power_up("no_such_power_up"), 0)
	assert_eq(state.power_up_tier("no_such_power_up"), 0)


func test_restart_from_the_pause_screen_starts_mission_1_with_no_power_ups() -> void:
	TestSave.isolate()
	var game: GameFlow = GameScene.instantiate()
	game.quit_game = func(): pass
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()
	if game.run == null:  # the tutorial slides first
		game.tutorial.start_pressed.emit(false)
	var old: RunState = game.run.state
	old.drift_step(true, 2.1)
	old.grant_power_up("bouncy_bumpers")
	assert_eq(old.missions.current_number(), 2)
	game.pause_screen.restart_pressed.emit()
	var fresh: RunState = game.run.state
	assert_eq(fresh.missions.current_number(), 1)
	assert_eq(fresh.missions.count(), 30)
	assert_eq(fresh.power_up_tier("bouncy_bumpers"), 0)
	get_tree().paused = false
	await wait_process_frames(1)
	TestSave.restore()


func test_the_cars_trick_signal_reaches_the_missions_in_a_run() -> void:
	TestSave.isolate()
	var game: GameFlow = GameScene.instantiate()
	game.quit_game = func(): pass
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()
	if game.run == null:
		game.tutorial.start_pressed.emit(false)
	var run: Node2D = game.run
	run.car.set_physics_process(false)
	var m: RunMissions = run.state.missions
	m.current = 1  # mission 2: alt drifts
	m._load_current()
	run.car.trick.emit("alternate_drift")
	assert_eq(m.current_goals()[0]["done"], 1.0)
	get_tree().paused = false
	await wait_process_frames(1)
	TestSave.restore()
