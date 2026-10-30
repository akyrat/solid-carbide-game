extends GutTest
## Task T-319: the run keeps its stats for the recap (RunState.recap()).

const RunStateScript := preload("res://scripts/run/run_state.gd")
const MinionScript := preload("res://scripts/enemies/minion.gd")

var state: RunState
var tiers := {"gun": 1}


func before_each() -> void:
	tiers = {"gun": 1}
	state = RunStateScript.new()
	add_child_autofree(state)
	state.weapons_source = func() -> Dictionary: return tiers
	state.start_run()


func test_a_new_run_has_an_empty_summary() -> void:
	var r := state.recap()
	assert_eq(r.enemies_slain, {})
	assert_eq(r.tricks, {})
	assert_eq(r.highest_combo, 1.0)
	assert_eq(r.result, "")
	assert_eq(r.coins, 0)


func test_counts_per_enemy_type_trick_and_weapon() -> void:
	state.enemy_slain("minion", "gun")
	state.enemy_slain("minion", "gun")
	state.enemy_slain("minion", "flamethrower")
	state.enemy_slain("kaiju", "gun")
	state.add_trick("three_sixty")
	state.add_trick("three_sixty")
	state.add_trick("alternate_drift")
	state.add_airtime_trick(5.0)
	state.add_needle_trick()
	tiers = {"gun": 3, "flamethrower": 1}
	var r := state.recap()
	assert_eq(r.enemies_slain, {"minion": 3, "kaiju": 1})
	assert_eq(r.tricks.three_sixty, 2)
	assert_eq(r.tricks.alternate_drift, 1)
	assert_eq(r.tricks.thread_the_needle, 1)
	assert_eq(r.tricks.get("airtime", 0), 1)
	assert_eq(r.weapons.gun, {"tier": 3, "kills": 3})
	assert_eq(r.weapons.flamethrower, {"tier": 1, "kills": 1})
	assert_false(r.weapons.has("bricks"), "only owned weapons")


func test_a_trick_that_is_not_the_cars_is_not_counted() -> void:
	state.add_trick("backflip_of_doom")
	assert_eq(state.recap().tricks, {})


func test_highest_combo_stays_after_a_crash_cut() -> void:
	for i in 5:
		state.add_trick("three_sixty")
	var peak := state.combo
	assert_gt(peak, 1.0)
	state.collision()
	assert_lt(state.combo, peak)
	assert_eq(state.recap().highest_combo, peak)


func test_kills_after_the_run_ended_are_ignored() -> void:
	state.enemy_slain("minion", "gun")
	state.kaiju_killed()
	state.enemy_slain("minion", "gun")
	assert_eq(state.recap().enemies_slain, {"minion": 1})


func test_summary_is_readable_after_run_ended_and_is_final() -> void:
	watch_signals(state)
	state.add_coins(7)
	state.add_trick("three_sixty")
	state.advance(30.0)
	state.kaiju_killed()
	assert_signal_emitted(state, "run_ended")
	tiers = {"gun": 9}  # later changes do not reach a finished run's summary
	state.add_trick("three_sixty")
	var r := state.recap()
	assert_eq(r.result, "win")
	assert_eq(r.loss_reason, "")
	assert_eq(r.coins, 7)
	assert_almost_eq(float(r.time_survived), 30.0, 0.001)
	assert_eq(r.tricks.three_sixty, 1)
	assert_eq(r.weapons.gun.tier, 1)


func test_loss_reason_time_and_health() -> void:
	state.advance(RunState.RUN_SECONDS + 1.0)
	assert_eq(state.recap().result, "loss")
	assert_eq(state.recap().loss_reason, "time")
	state.start_run()
	state.damage_car(state.max_health + 1.0)
	state.advance(state.wreck_left)  # T-413: the loss is decided when the wreck ends
	assert_eq(state.recap().loss_reason, "health")


func test_next_run_clears_the_summary() -> void:
	state.enemy_slain("minion", "gun")
	state.add_trick("three_sixty")
	state.kaiju_killed()
	state.start_run()
	var r := state.recap()
	assert_eq(r.enemies_slain, {})
	assert_eq(r.tricks, {})
	assert_eq(r.result, "")
	assert_eq(r.highest_combo, 1.0)
	assert_eq(r.weapons.gun.kills, 0)


func test_summary_serialises_to_json() -> void:
	state.enemy_slain("minion", "gun")
	state.add_trick("three_sixty")
	state.kaiju_killed()
	var back = JSON.parse_string(JSON.stringify(state.recap()))
	assert_not_null(back)
	assert_eq(back.enemies_slain.minion, 1)


func test_the_summary_is_a_copy() -> void:
	var r := state.recap()
	r.enemies_slain["minion"] = 99
	assert_eq(state.recap().enemies_slain, {})


func test_minion_remembers_the_weapon_that_hit_it_last() -> void:
	var m: Node = MinionScript.new()
	add_child_autofree(m)
	m.setup({"health": 5.0})
	m.take_damage(1.0, "gun")
	m.take_damage(1.0, "flamethrower")
	m.take_damage(1.0)
	assert_eq(m.last_hit_by, "flamethrower")
	assert_eq(MinionScript.ENEMY_TYPE, "minion")


## T-320 quick tuning (board, 2026-10-29): the summary keeps the peak live viewers, the
## counter's number for the highest combo on T-332's curve.
func test_the_summary_keeps_the_peak_viewers() -> void:
	var curve := ViewersData.new()
	assert_eq(state.recap().peak_viewers, curve.base_viewers(), "no combo: the base viewers")
	for i in 5:
		state.add_trick("three_sixty")
	var peak := state.combo
	state.collision()
	var r := state.recap()
	assert_eq(r.peak_viewers, curve.viewers_for(peak), "the peak, not the viewers after the crash")
	assert_gt(r.peak_viewers, curve.base_viewers())
	var back: Dictionary = JSON.parse_string(JSON.stringify(r))
	assert_eq(float(back.peak_viewers), r.peak_viewers, "saved with the run history as JSON")
