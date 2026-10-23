extends GutTest
## Task T-115: the likes drain. Once the combo is back at "no combo", the XP in
## the current level goes down at T-114's speed (RunData), never below 0, and
## the level never goes down. A trick stops it. No drain while paused, while a
## weapon choice waits, or after the run ends. xp_changed fires as it drains.

const RunStateScript := preload("res://scripts/run/run_state.gd")
const RunScene := preload("res://scenes/run/run.tscn")


## RunData with the drain's extra wait set by the test.
class RunDataWait extends RunData:
	var wait := 0.0

	func likes_drain_extra_wait_seconds() -> float:
		return wait


## RunData with the drain switched off.
class RunDataOff extends RunData:
	func likes_drain_enabled() -> bool:
		return false


var data := RunData.new()
var combo_data := ComboData.new()
var state: RunState
var xp_events: Array = []
var level_ups: Array = []


func before_each() -> void:
	state = _new_state(null)


func after_each() -> void:
	get_tree().paused = false


func _new_state(run_data: RunData) -> RunState:
	var s: RunState = RunStateScript.new(run_data)
	add_child_autofree(s)
	# Tests drive the clock by hand; the node's own _process would add time.
	s.set_process(false)
	s.start_run()
	xp_events = []
	level_ups = []
	s.xp_changed.connect(func(x: float, n: float, l: int) -> void: xp_events.append([x, n, l]))
	s.level_up.connect(func(l: int) -> void: level_ups.append(l))
	return s


func _simulate(seconds: float, step: float = 1.0 / 60.0) -> void:
	var t := 0.0
	while t < seconds - 0.0000001:
		var dt := minf(step, seconds - t)
		state.advance(dt)
		t += dt


## Seconds from a trick until the combo is back at "no combo": the wait,
## then the drain of what the trick added.
func _combo_gone_after(trick_id: String) -> float:
	return combo_data.drain_wait_seconds() \
			+ combo_data.trick_amount(trick_id, 1.0) / combo_data.drain_per_second()


func test_the_drain_numbers_load() -> void:
	assert_true(data.is_ok(), data.error)
	assert_true(data.likes_drain_enabled())
	assert_gt(data.likes_drain_xp_per_second(1), 0.0)


func test_no_drain_while_the_combo_is_above_no_combo() -> void:
	state.xp = 50.0
	state.add_trick("alternate_drift")
	assert_false(state.has_no_combo())
	# Through the combo's own wait and most of its drain: likes stay put.
	_simulate(_combo_gone_after("alternate_drift") - 0.1)
	assert_gt(state.combo, combo_data.start_multiplier(), "the combo is still draining")
	assert_eq(state.xp, 50.0, "no likes drain while there is a combo")
	assert_false(state.is_likes_draining())


func test_drain_starts_once_the_combo_is_gone() -> void:
	state.xp = 50.0
	state.add_trick("alternate_drift")
	_simulate(_combo_gone_after("alternate_drift") + 0.1)
	assert_true(state.has_no_combo(), "the combo has fully drained")
	assert_lt(state.xp, 50.0, "the likes drain has started")
	assert_true(state.is_likes_draining())


func test_drain_speed_is_t114s_speed_at_level_1() -> void:
	state.xp = 50.0
	_simulate(5.0)
	var expected := 50.0 - 5.0 * data.likes_drain_xp_per_second(1)
	assert_almost_eq(state.xp, expected, 0.001)
	assert_eq(state.level, 1)


func test_drain_speed_follows_the_level() -> void:
	state.level = 4
	state.xp = 150.0
	_simulate(3.0)
	var expected := 150.0 - 3.0 * data.likes_drain_xp_per_second(4)
	assert_almost_eq(state.xp, expected, 0.001)
	assert_ne(data.likes_drain_xp_per_second(4), data.likes_drain_xp_per_second(1),
			"T-114's speed is a share of each level's bar")


func test_drain_speed_does_not_depend_on_frame_size() -> void:
	state.xp = 50.0
	_simulate(4.0, 0.5)
	assert_almost_eq(state.xp, 50.0 - 4.0 * data.likes_drain_xp_per_second(1), 0.001)


func test_a_trick_stops_the_drain() -> void:
	state.xp = 50.0
	_simulate(2.0)
	var at_trick := state.xp
	assert_lt(at_trick, 50.0, "draining before the trick")
	state.add_trick("extended_drift", 1.0)
	assert_false(state.is_likes_draining(), "the trick stops it")
	_simulate(_combo_gone_after("extended_drift") - 0.1)
	assert_eq(state.xp, at_trick, "no drain until the combo has drained again")
	_simulate(1.0)
	assert_lt(state.xp, at_trick, "drains again once the combo is gone")


func test_xp_never_goes_below_zero_and_the_level_stays() -> void:
	state.add_xp(data.xp_needed(1) * 1.1)
	assert_eq(state.level, 2)
	level_ups.clear()
	_simulate(30.0)
	assert_eq(state.xp, 0.0, "stops at the start of the level")
	assert_eq(state.level, 2, "the level never goes down")
	assert_false(state.is_likes_draining(), "nothing left to drain")


func test_a_long_drain_never_goes_below_the_level() -> void:
	state.level = 6
	state.xp = 200.0
	xp_events.clear()
	_simulate(400.0, 0.1)
	assert_true(state.is_running(), "still before 0:00")
	assert_eq(state.xp, 0.0)
	assert_eq(state.level, 6, "level unchanged after a long drain")
	assert_eq(level_ups, [], "no level change signals")
	for e in xp_events:
		assert_gte(e[0], 0.0, "xp_changed never below 0")
		assert_eq(e[2], 6, "xp_changed always at the same level")


func test_the_drain_sends_xp_changed_as_it_drains() -> void:
	state.xp = 3.0
	xp_events.clear()
	_simulate(1.0)
	assert_gt(xp_events.size(), 10, "xp_changed fires as XP goes down")
	var last := 3.0
	for e in xp_events:
		assert_lt(e[0], last, "each one lower")
		assert_eq(e[1], data.xp_needed(1), "with the level's bar")
		assert_eq(e[2], 1)
		last = e[0]
	assert_eq(xp_events.back()[0], state.xp)
	_simulate(5.0)
	assert_eq(state.xp, 0.0)
	var count := xp_events.size()
	_simulate(2.0)
	assert_eq(xp_events.size(), count, "no more signals once the bar is empty")


func test_no_drain_after_the_run_ends() -> void:
	state.xp = 50.0
	state.kaiju_killed()
	_simulate(5.0)
	assert_eq(state.xp, 50.0)
	assert_false(state.is_likes_draining())


func test_no_drain_after_the_clock_runs_out() -> void:
	state.xp = 50.0
	state.advance(RunState.RUN_SECONDS)
	assert_false(state.is_running())
	var left := state.xp
	_simulate(5.0)
	assert_eq(state.xp, left)


func test_no_drain_while_the_tree_is_paused() -> void:
	state.set_process(true)
	state.xp = 50.0
	await wait_physics_frames(5)
	assert_lt(state.xp, 50.0, "drains on its own while not paused")
	get_tree().paused = true
	var frozen := state.xp
	await wait_physics_frames(60)
	assert_eq(state.xp, frozen, "paused: no drain")
	get_tree().paused = false
	await wait_physics_frames(60)
	assert_lt(state.xp, frozen, "unpaused: it drains again")


func test_no_drain_while_a_weapon_choice_waits() -> void:
	state.pause_on_level_up = true
	state.add_xp(data.xp_needed(1) * 1.2)
	assert_true(state.is_waiting_for_choice())
	var left := state.xp
	assert_gt(left, 0.0)
	_simulate(3.0)
	assert_eq(state.xp, left, "no drain while the choice is on show")
	state.choice_made()
	_simulate(1.0)
	assert_lt(state.xp, left, "drains after the choice")


func test_no_drain_at_the_top_level() -> void:
	state.level = data.max_level()
	state.xp = 0.0
	xp_events.clear()
	_simulate(5.0)
	assert_eq(state.level, data.max_level())
	assert_eq(xp_events, [], "nothing to drain at the top level")


func test_extra_wait_delays_the_drain() -> void:
	var rd := RunDataWait.new()
	rd.wait = 1.5
	state = _new_state(rd)
	state.xp = 50.0
	_simulate(1.4)
	assert_eq(state.xp, 50.0, "waiting")
	_simulate(1.6)
	assert_almost_eq(state.xp, 50.0 - 1.5 * data.likes_drain_xp_per_second(1), 0.001)
	state.add_trick("extended_drift", 1.0)
	_simulate(_combo_gone_after("extended_drift") + 1.4)
	var after := state.xp
	_simulate(0.05)
	assert_eq(state.xp, after, "the wait starts again after a trick")


func test_switched_off_means_no_drain() -> void:
	state = _new_state(RunDataOff.new())
	state.xp = 50.0
	_simulate(5.0)
	assert_eq(state.xp, 50.0)


func test_a_new_run_resets_the_drain_wait() -> void:
	_simulate(3.0)
	assert_gt(state.likes_drain_idle, 0.0)
	state.start_run()
	assert_eq(state.likes_drain_idle, 0.0)


func test_the_hud_likes_bar_empties_in_a_run() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	var s: RunState = run.state
	s.add_xp(s.xp_needed() * 0.5)
	var bar: ProgressBar = run.hud.likes_bar
	var start_value := bar.value
	# The bar rounds to whole likes (its step is 1), so allow 1 either way.
	assert_almost_eq(start_value, s.xp, 1.0)
	await wait_seconds(1.5)
	assert_lt(bar.value, start_value, "the likes bar goes down with no tricks")
	assert_almost_eq(bar.value, s.xp, 1.0, "the bar follows the run's XP")
	assert_eq(s.level, 1)
