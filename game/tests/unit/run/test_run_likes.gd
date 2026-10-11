extends GutTest
## Task T-037: likes (XP) and levels, from challenges and drifting, the
## level-up signals and the level-up pause switch.

const RunStateScript := preload("res://scripts/run/run_state.gd")
const RunScene := preload("res://scenes/run/run.tscn")

var data := RunData.new()
var state: RunState
var levels: Array = []
var scores: Array = []
var bars: Array = []
var choices_started: Array = []
var choices_made: Array = []


func before_each() -> void:
	state = RunStateScript.new()
	add_child_autofree(state)
	_listen(state)
	state.start_run()
	bars.clear()


func after_each() -> void:
	get_tree().paused = false


func _listen(s: RunState) -> void:
	levels = []
	scores = []
	bars = []
	choices_started = []
	choices_made = []
	s.level_up.connect(func(l: int) -> void: levels.append(l))
	s.score.connect(func(a: float, id: String) -> void: scores.append([a, id]))
	s.xp_changed.connect(func(x: float, n: float, l: int) -> void: bars.append([x, n, l]))
	s.level_up_choice_started.connect(func(l: int) -> void: choices_started.append(l))
	s.level_up_choice_made.connect(func(l: int) -> void: choices_made.append(l))


## Drives `seconds` of unbroken drift in car-sized steps, then one step off.
func _drift(seconds: float, step: float = 0.02) -> void:
	var t := 0.0
	while t < seconds - 0.0000001:
		var dt := minf(step, seconds - t)
		state.drift_step(true, dt)
		t += dt
	state.drift_step(false, step)


func test_fresh_run_values() -> void:
	assert_eq(state.xp, 0.0)
	assert_eq(state.level, 1)
	assert_eq(state.xp_needed(), data.xp_needed(1))
	assert_false(state.pause_on_level_up, "the switch is off for now")


func test_challenge_at_level_1_fills_bar_and_levels_up() -> void:
	var gained := data.challenge_xp(1)
	state.challenge_completed("c-1")
	assert_eq(state.level, 2, "one challenge at level 1 fills the bar")
	assert_eq(levels, [2], "level up fires once, with the new level")
	assert_eq(scores, [[gained, "c-1"]], "score carries the XP gained")
	assert_eq(bars.size(), 1)
	assert_eq(bars[0], [maxf(gained - data.xp_needed(1), 0.0), data.xp_needed(2), 2],
		"the bar filled: leftover XP out of level 2's threshold")


func test_challenge_xp_follows_the_level() -> void:
	state.challenge_completed("a")
	state.challenge_completed("b")
	assert_eq(scores[1][0], data.challenge_xp(2), "level 2's challenge XP")


func test_drift_under_a_second_gives_nothing_three_seconds_gives_three() -> void:
	_drift(0.9)
	assert_eq(state.xp, 0.0, "0.9 s of drift: no XP")
	assert_eq(bars.size(), 0)
	_drift(3.0)
	assert_almost_eq(state.xp, 3.0 * data.drift_xp_per_second(), 0.0001,
		"3 s of drift: exactly 3 seconds' worth")


func test_drift_xp_counts_each_second_as_it_passes() -> void:
	state.drift_step(true, 0.5)
	state.drift_step(true, 0.49)
	assert_eq(state.xp, 0.0, "not before the first second")
	state.drift_step(true, 0.02)
	assert_eq(state.xp, data.drift_xp_per_second(), "the first second, once reached")
	state.drift_step(true, 0.99)
	assert_eq(state.xp, 2.0 * data.drift_xp_per_second())
	state.drift_step(false, 0.02)
	state.drift_step(true, 0.9)
	assert_eq(state.xp, 2.0 * data.drift_xp_per_second(), "a break starts the count again")


func test_drift_seconds_level_up_with_leftover() -> void:
	var per := data.drift_xp_per_second()
	var seconds := int(ceil(data.xp_needed(1) / per)) + 2
	_drift(float(seconds))
	assert_eq(state.level, 2)
	assert_eq(levels, [2])
	assert_almost_eq(state.xp, seconds * per - data.xp_needed(1), 0.0001, "leftover carries over")


func test_switch_off_level_up_keeps_clock_running() -> void:
	state.challenge_completed("c")
	assert_eq(state.level, 2)
	assert_false(get_tree().paused, "the run is not paused")
	assert_false(state.is_waiting_for_choice())
	assert_eq(choices_started, [])
	var before := state.time_left
	await wait_physics_frames(5)
	assert_lt(state.time_left, before, "the clock keeps running")


func test_switch_on_pauses_until_choice_made() -> void:
	state.pause_on_level_up = true
	state.challenge_completed("c")
	assert_eq(state.level, 2)
	assert_true(get_tree().paused, "the level-up pauses the run")
	assert_true(state.is_waiting_for_choice())
	assert_eq(choices_started, [2])
	var frozen := state.time_left
	await wait_physics_frames(10)
	assert_eq(state.time_left, frozen, "the clock is stopped")
	state.choice_made()
	assert_eq(choices_made, [2])
	assert_false(get_tree().paused, "resumed after the choice")
	assert_false(state.is_waiting_for_choice())
	await wait_physics_frames(5)
	assert_lt(state.time_left, frozen, "the clock runs again")


func test_switch_on_freezes_the_car() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.state.pause_on_level_up = true
	run.car.use_keyboard = false
	run.car.scripted_input = [true, false, 0.0]
	await wait_physics_frames(5)
	run.state.challenge_completed("c")
	assert_true(get_tree().paused)
	var at: Vector2 = run.car.position
	await wait_physics_frames(10)
	assert_eq(run.car.position, at, "the car does not move while the choice waits")
	run.state.choice_made()
	await wait_physics_frames(5)
	assert_ne(run.car.position, at, "the car moves again")


func test_two_level_ups_at_once_wait_one_after_the_other() -> void:
	state.pause_on_level_up = true
	state.add_xp(data.xp_needed(1) + data.xp_needed(2))
	assert_eq(state.level, 3)
	assert_eq(levels, [2, 3], "one level up signal per level")
	assert_eq(choices_started, [2], "only the first choice is on show")
	assert_eq(state.choice_level(), 2)
	assert_true(get_tree().paused)
	state.choice_made()
	assert_eq(choices_made, [2])
	assert_eq(choices_started, [2, 3], "the second choice follows the first")
	assert_eq(state.choice_level(), 3)
	assert_true(get_tree().paused, "still paused for the second choice")
	state.choice_made()
	assert_eq(choices_made, [2, 3])
	assert_false(get_tree().paused, "resumed after both choices")
	state.choice_made()
	assert_eq(choices_made, [2, 3], "choice_made with nothing waiting does nothing")


func test_meteor_challenge_gives_same_xp_as_preset() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	_listen(run.state)
	run.map.challenge_completed.emit(run.map.challenge_ids()[0])
	var preset_xp: float = scores[0][0]
	run.start_run()
	run.map.meteor_challenge_completed.emit("meteor-1")
	assert_eq(scores.size(), 2, "the meteor challenge sends score")
	assert_eq(scores[1], [preset_xp, "meteor-1"], "the same XP as a preset challenge")
	assert_eq(run.state.level, 2)
	assert_eq(levels, [2, 2])


func test_run_scene_drift_gives_xp() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.car.use_keyboard = false
	run.car.scripted_input = [true, false, 1.0]  # W with D: drifting
	var steps := int(ceil(1.0 / run.car.model.dt)) + 3
	await wait_physics_frames(steps)
	assert_true(run.car.model.is_drifting)
	# T-081: the extended-drift trick at the 1 s mark raises the combo before
	# that second's drift XP is paid, so the second is multiplied by it.
	assert_gt(run.state.combo, 1.0, "the extended-drift trick raised the combo")
	assert_almost_eq(run.state.xp, data.drift_xp_per_second() * run.state.combo, 0.000001,
			"one second of drift in the run, times the combo")


func test_new_run_resets_xp_and_level() -> void:
	state.pause_on_level_up = true
	state.add_xp(data.xp_needed(1) + data.xp_needed(2) + 5.0)
	assert_eq(state.level, 3)
	state.drift_step(true, 0.8)
	assert_true(get_tree().paused)
	bars.clear()
	state.start_run()
	assert_eq(state.xp, 0.0)
	assert_eq(state.level, 1)
	assert_eq(state.xp_needed(), data.xp_needed(1))
	assert_false(state.is_waiting_for_choice())
	assert_false(get_tree().paused, "a new run is not left waiting for an old choice")
	assert_eq(bars, [[0.0, data.xp_needed(1), 1]], "the HUD hears the reset")
	state.drift_step(true, 0.5)
	assert_eq(state.xp, 0.0, "the old drift does not carry into the new run")


func test_no_xp_after_the_run_ends() -> void:
	state.kaiju_killed()
	state.challenge_completed("c")
	state.drift_step(true, 5.0)
	assert_eq(state.xp, 0.0)
	assert_eq(state.level, 1)
	assert_eq(scores, [])


func test_top_level_bar_stops() -> void:
	var total := 0.0
	for l in range(1, data.max_level()):
		total += data.xp_needed(l)
	state.add_xp(total + 50.0)
	assert_eq(state.level, data.max_level())
	assert_eq(levels.size(), data.max_level() - 1)
	assert_eq(state.xp, 0.0)
	assert_eq(state.xp_needed(), 0.0)
	state.challenge_completed("c")
	assert_eq(state.level, data.max_level(), "no level past the top")
	assert_eq(scores.size(), 1, "the challenge still sends its score")
