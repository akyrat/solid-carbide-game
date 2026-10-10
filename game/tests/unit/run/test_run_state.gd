extends GutTest
## Task T-036: the run's state (clock, health, coins, win and loss).

const RunStateScript := preload("res://scripts/run/run_state.gd")

var state: RunState
var ended: Array = []
var boss_count := 0


func before_each() -> void:
	state = RunStateScript.new()
	add_child_autofree(state)
	ended = []
	boss_count = 0
	state.run_ended.connect(func(r: String, c: int) -> void: ended.append([r, c]))
	state.boss_time.connect(func() -> void: boss_count += 1)
	state.start_run()


func after_each() -> void:
	get_tree().paused = false


func _simulate(seconds: float, step: float = 1.0 / 60.0) -> void:
	var t := 0.0
	while t < seconds - 0.0000001:
		var dt := minf(step, seconds - t)
		state.advance(dt)
		t += dt


func test_fresh_run_values() -> void:
	assert_eq(state.time_left, 480.0)
	assert_eq(state.time_left_text(), "8:00")
	assert_eq(state.health, RunData.new().starting_health())
	assert_eq(state.max_health, state.health)
	assert_eq(state.coins, 0)
	assert_true(state.is_running())
	assert_eq(state.result, "")


func test_boss_time_fires_once_at_seven_minutes() -> void:
	_simulate(419.0)
	assert_eq(boss_count, 0, "not before 7:00 have passed")
	assert_eq(state.time_left_text(), "1:01")
	_simulate(1.0)
	assert_eq(boss_count, 1, "at 7:00 passed (1:00 left)")
	assert_eq(state.time_left_text(), "1:00")
	_simulate(30.0)
	assert_eq(boss_count, 1, "only once")
	assert_eq(ended.size(), 0)


func test_clock_runs_out_is_a_loss() -> void:
	state.add_coins(7)
	_simulate(479.5)
	assert_eq(ended.size(), 0)
	assert_eq(state.time_left_text(), "0:01")
	_simulate(0.5)
	assert_eq(state.time_left, 0.0)
	assert_eq(ended, [["loss", 7]], "one run ended signal, loss, with the coins")
	assert_eq(boss_count, 1)
	_simulate(5.0)
	assert_eq(ended.size(), 1, "the clock stays at 0 and the run ends once")
	assert_eq(state.time_left, 0.0)


func test_big_step_still_sends_boss_time_and_ends() -> void:
	state.advance(1000.0)
	assert_eq(boss_count, 1)
	assert_eq(ended, [["loss", 0]])


func test_damage_to_zero_is_a_loss_once() -> void:
	var healths := []
	state.health_changed.connect(func(h: float, m: float) -> void: healths.append([h, m]))
	state.add_coins(3)
	state.add_coins(2)
	state.damage_car(30.0)
	assert_eq(state.health, state.max_health - 30.0)
	assert_eq(ended.size(), 0)
	state.damage_car(state.max_health)
	assert_eq(state.health, 0.0, "health stops at 0")
	assert_eq(ended, [["loss", 5]], "loss with the coins so far")
	state.damage_car(10.0)
	state.kaiju_killed()
	state.advance(500.0)
	assert_eq(ended.size(), 1, "nothing ends the run twice")
	assert_eq(healths.size(), 2)
	assert_eq(healths[1], [0.0, state.max_health])


func test_kaiju_killed_is_a_win_at_once() -> void:
	_simulate(430.0)
	state.add_coins(12)
	state.kaiju_killed()
	assert_eq(ended, [["win", 12]])
	assert_eq(state.result, "win")
	assert_false(state.is_running())
	var left := state.time_left
	state.advance(100.0)
	assert_eq(state.time_left, left, "the clock stops when the run ends")
	assert_eq(ended.size(), 1)


func test_coins_add_up_and_signal() -> void:
	var seen := []
	state.coins_changed.connect(func(c: int) -> void: seen.append(c))
	state.add_coins(4)
	state.add_coins(0)
	state.add_coins(-3)
	state.add_coins(6)
	assert_eq(state.coins, 10)
	assert_eq(seen, [4, 10])


func test_time_signal_once_per_shown_second() -> void:
	var seen := []
	state.time_left_changed.connect(func(s: float) -> void: seen.append(state.time_left_text()))
	_simulate(3.0)
	assert_eq(seen, ["7:59", "7:58", "7:57"])


func test_clock_does_not_advance_while_paused() -> void:
	await wait_physics_frames(5)
	var before := state.time_left
	assert_lt(before, 480.0, "the clock runs on its own while not paused")
	get_tree().paused = true
	var frozen := state.time_left
	await wait_physics_frames(20)
	assert_eq(state.time_left, frozen, "paused: the clock does not move")
	get_tree().paused = false
	await wait_physics_frames(5)
	assert_lt(state.time_left, frozen, "unpaused: it runs again")


func test_second_run_resets_everything() -> void:
	_simulate(425.0)
	state.add_coins(9)
	state.damage_car(state.max_health)
	assert_eq(ended.size(), 1)
	state.start_run()
	assert_eq(state.time_left, 480.0)
	assert_eq(state.health, state.max_health)
	assert_eq(state.coins, 0)
	assert_true(state.is_running())
	assert_eq(state.result, "")
	_simulate(420.0)
	assert_eq(boss_count, 2, "boss time fires again in the new run")
	state.kaiju_killed()
	assert_eq(ended[1], ["win", 0])
