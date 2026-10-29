extends GutTest
## Task T-363: every finished run's recap stats are saved (RunHistory).

const RunStateScript := preload("res://scripts/run/run_state.gd")

var PATH := RunPaths.file("test_run_history_t363.json")


func before_each() -> void:
	DirAccess.remove_absolute(PATH)


func after_each() -> void:
	DirAccess.remove_absolute(PATH)


func _recap(result := "win", coins := 10) -> Dictionary:
	return {"result": result, "loss_reason": "", "time_survived": 123.5, "coins": coins,
		"likes": 40, "level": 3, "enemies_slain": {"minion": 5}, "tricks": {}, "highest_combo": 2.0,
		"weapons": {"gun": {"tier": 2, "kills": 5}}}


func test_no_file_is_an_empty_history() -> void:
	var h := RunHistory.new(PATH)
	assert_eq(h.runs(), [])
	assert_eq(h.count(), 0)


func test_broken_files_are_empty() -> void:
	for text in ["not json {", "[1, 2]", "{\"runs\": 5}", ""]:
		var f := FileAccess.open(PATH, FileAccess.WRITE)
		f.store_string(text)
		f = null
		assert_eq(RunHistory.new(PATH).runs(), [], text)


func test_add_run_keeps_the_summary_and_end_time() -> void:
	var h := RunHistory.new(PATH)
	h.add_run(_recap("loss", 7), 1000)
	assert_eq(h.count(), 1)
	var e: Dictionary = h.runs()[0]
	assert_eq(e.result, "loss")
	assert_eq(e.coins, 7)
	assert_eq(e.likes, 40)
	assert_eq(e.time_survived, 123.5)
	assert_eq(e.weapons.gun.kills, 5)
	assert_eq(e.ended_unix, 1000)
	assert_true(str(e.ended_at).length() == 19, e.ended_at)


func test_a_run_still_going_is_ignored() -> void:
	var h := RunHistory.new(PATH)
	h.add_run(_recap(""))
	assert_eq(h.count(), 0)


func test_newest_first_after_a_restart() -> void:
	var h := RunHistory.new(PATH)
	h.add_run(_recap("win", 1), 100)
	h.add_run(_recap("loss", 2), 200)
	h.add_run(_recap("win", 3), 300)
	var again := RunHistory.new(PATH)  # a new instance reads the same file
	var coins: Array = again.runs().map(func(r): return int(r.coins))
	assert_eq(coins, [3, 2, 1])


func test_runs_returns_copies() -> void:
	var h := RunHistory.new(PATH)
	h.add_run(_recap(), 100)
	h.runs()[0]["coins"] = 999
	assert_eq(h.runs()[0].coins, 10)


func test_only_the_newest_max_runs_are_kept() -> void:
	var h := RunHistory.new(PATH)
	for i in RunHistory.MAX_RUNS + 3:
		h.add_run(_recap("win", i), i)
	assert_eq(h.count(), RunHistory.MAX_RUNS)
	assert_eq(h.runs()[0].coins, RunHistory.MAX_RUNS + 2)
	assert_eq(h.runs()[-1].coins, 3)


func test_a_scripted_run_ending_saves_one_entry() -> void:
	var state: RunState = RunStateScript.new()
	add_child_autofree(state)
	state.start_run()
	var h := RunHistory.new(PATH)
	h.connect_run(state)
	state.add_coins(5)
	state._end(RunStateScript.RESULT_LOSS, RunStateScript.LOSS_TIME)
	var again := RunHistory.new(PATH)
	assert_eq(again.count(), 1)
	var e: Dictionary = again.runs()[0]
	assert_eq(e.result, "loss")
	assert_eq(e.loss_reason, RunStateScript.LOSS_TIME)
	assert_eq(e.coins, 5)
	assert_true(e.has("time_survived") and e.has("likes") and e.has("ended_at"))
