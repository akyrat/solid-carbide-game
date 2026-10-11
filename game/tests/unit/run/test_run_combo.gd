extends GutTest
## Task T-081: the combo. Tricks raise a multiplier on all likes (XP) gained,
## collisions and damage to the car cut it by 80%, it drains when no trick
## follows within 2 seconds, it resets with a new run and stops while paused.

const RunStateScript := preload("res://scripts/run/run_state.gd")
const RunScene := preload("res://scenes/run/run.tscn")
const GameScene := preload("res://scenes/game/game.tscn")
const TEST_PATH := "user://test_settings_t081.cfg"

var data := RunData.new()
var combo_data := ComboData.new()
var state: RunState
var tricks: Array = []
var changes: Array = []
var scores: Array = []


func before_each() -> void:
	state = RunStateScript.new()
	add_child_autofree(state)
	_listen(state)
	state.start_run()
	changes.clear()


func after_each() -> void:
	get_tree().paused = false


func _listen(s: RunState) -> void:
	tricks = []
	changes = []
	scores = []
	s.combo_trick.connect(func(id: String, a: float, m: float) -> void: tricks.append([id, a, m]))
	s.combo_changed.connect(func(m: float) -> void: changes.append(m))
	s.score.connect(func(a: float, id: String) -> void: scores.append([a, id]))


func _simulate(seconds: float, step: float = 1.0 / 60.0) -> void:
	var t := 0.0
	while t < seconds - 0.0000001:
		var dt := minf(step, seconds - t)
		state.advance(dt)
		t += dt


func test_the_data_loads() -> void:
	assert_true(combo_data.is_ok(), combo_data.error)


func test_fresh_run_has_no_combo() -> void:
	assert_eq(state.combo, combo_data.start_multiplier())
	assert_eq(state.combo, 1.0, "1.0 means no combo")
	assert_eq(state.combo_spawn_multiplier(), 1.0)


func test_tricks_raise_the_multiplier_by_the_data_amounts() -> void:
	var expected := combo_data.start_multiplier()
	for id in ["extended_drift", "three_sixty", "alternate_drift"]:
		var before := state.combo
		state.add_trick(id)
		expected += combo_data.trick_add(id)
		assert_almost_eq(state.combo, expected, 0.000001, id)
		assert_almost_eq(state.combo - before, combo_data.trick_add(id), 0.000001, id)
	assert_eq(tricks.size(), 3)
	assert_eq(tricks[0][0], "extended_drift")
	assert_almost_eq(tricks[0][1], combo_data.trick_add("extended_drift"), 0.000001)
	assert_almost_eq(tricks[0][2], 1.0 + combo_data.trick_add("extended_drift"), 0.000001)
	assert_eq(tricks[2][0], "alternate_drift")
	assert_almost_eq(tricks[2][1], combo_data.trick_add("alternate_drift"), 0.000001)
	assert_almost_eq(tricks[2][2], expected, 0.000001)
	assert_eq(changes.size(), 3, "combo_changed per trick")
	assert_almost_eq(changes[2], expected, 0.000001)


func test_an_unknown_trick_id_is_ignored() -> void:
	state.add_trick("nope")
	assert_eq(state.combo, 1.0)
	assert_eq(tricks.size(), 0)


func test_the_multiplier_stops_at_the_cap() -> void:
	for i in 100:
		state.add_trick("alternate_drift")
	assert_almost_eq(state.combo, combo_data.max_multiplier(), 0.000001)
	var last: Array = tricks[tricks.size() - 1]
	assert_almost_eq(last[1], 0.0, 0.000001, "nothing added at the cap")
	assert_almost_eq(last[2], combo_data.max_multiplier(), 0.000001)


func test_the_spawn_multiplier_follows_the_combo() -> void:
	state.add_trick("alternate_drift")
	assert_almost_eq(state.combo_spawn_multiplier(), combo_data.spawn_multiplier(state.combo), 0.000001)
	assert_gt(state.combo_spawn_multiplier(), 1.0)


func test_a_challenge_gives_likes_times_the_multiplier() -> void:
	state.add_trick("alternate_drift")
	state.add_trick("three_sixty")
	var m := state.combo
	var expected := data.challenge_xp(1) * m
	state.challenge_completed("c1")
	assert_almost_eq(scores[0][0], expected, 0.000001, "the score signal carries the multiplied likes")
	assert_eq(scores[0][1], "c1")
	if expected < data.xp_needed(1):
		assert_almost_eq(state.xp, expected, 0.000001)
	else:
		assert_gt(state.level, 1, "the multiplied likes levelled up")


func test_a_drift_second_gives_likes_times_the_multiplier() -> void:
	state.add_trick("three_sixty")
	var m := state.combo
	for i in 50:
		state.drift_step(true, 0.02)
	assert_almost_eq(state.xp, data.drift_xp_per_second() * m, 0.000001)


func test_add_xp_is_multiplied_too() -> void:
	state.add_trick("three_sixty")
	state.add_xp(2.0)
	assert_almost_eq(state.xp, 2.0 * state.combo, 0.000001)


func test_a_wall_hit_cuts_the_combo_by_80_percent() -> void:
	for i in 4:
		state.add_trick("alternate_drift")
	var before := state.combo  # 3.0
	state.collision()
	var expected := 1.0 + (before - 1.0) * (1.0 - combo_data.collision_cut())
	assert_almost_eq(state.combo, expected, 0.000001)
	assert_almost_eq(state.combo, combo_data.after_collision(before), 0.000001)
	assert_almost_eq(changes[changes.size() - 1], expected, 0.000001)


func test_damage_to_the_car_cuts_the_combo_by_80_percent() -> void:
	for i in 4:
		state.add_trick("alternate_drift")
	var before := state.combo
	state.damage_car(1.0)
	assert_almost_eq(state.combo, combo_data.after_collision(before), 0.000001)
	assert_lt(state.health, state.max_health)


func test_a_collision_with_no_combo_changes_nothing() -> void:
	state.collision()
	assert_eq(state.combo, 1.0)
	assert_eq(changes.size(), 0)


func test_the_run_scene_cuts_the_combo_on_the_cars_collision_signal() -> void:
	var run = RunScene.instantiate()
	add_child_autofree(run)
	var s: RunState = run.state
	run.car.trick.emit("alternate_drift")
	run.car.trick.emit("alternate_drift")
	var before := s.combo
	assert_almost_eq(before, 1.0 + 2.0 * combo_data.trick_add("alternate_drift"), 0.000001,
			"the car's trick signal reaches the combo")
	run.car.hit_obstacle.emit(autofree(StaticBody2D.new()), 0, Vector2.UP, 10.0)
	assert_almost_eq(s.combo, combo_data.after_collision(before), 0.000001)


func test_the_combo_waits_2_seconds_then_drains() -> void:
	state.add_trick("alternate_drift")
	state.add_trick("alternate_drift")
	var top := state.combo
	_simulate(combo_data.drain_wait_seconds() - 0.05)
	assert_almost_eq(state.combo, top, 0.000001, "no drain before 2 s")
	_simulate(0.55)
	assert_lt(state.combo, top, "draining after 2 s")
	assert_almost_eq(state.combo, top - 0.5 * combo_data.drain_per_second(), 0.0001)
	_simulate(30.0)
	assert_eq(state.combo, combo_data.start_multiplier(), "drains down to no combo, not below")


func test_a_trick_before_2_seconds_stops_the_drain() -> void:
	state.add_trick("alternate_drift")
	for i in 5:
		_simulate(combo_data.drain_wait_seconds() - 0.1)
		state.add_trick("extended_drift")
	var expected := 1.0 + combo_data.trick_add("alternate_drift") + 5.0 * combo_data.trick_add("extended_drift")
	assert_almost_eq(state.combo, expected, 0.000001, "never drained")


func test_a_new_run_resets_the_combo() -> void:
	state.add_trick("alternate_drift")
	state.start_run()
	assert_eq(state.combo, 1.0)
	assert_eq(state.combo_idle, 0.0)
	assert_eq(changes[changes.size() - 1], 1.0, "combo_changed on start")


func test_the_combo_does_not_change_while_paused() -> void:
	state.add_trick("alternate_drift")
	state.add_trick("alternate_drift")
	await wait_physics_frames(2)
	get_tree().paused = true
	var frozen := state.combo
	var idle := state.combo_idle
	await wait_physics_frames(150)
	assert_eq(state.combo, frozen, "paused: no drain")
	assert_eq(state.combo_idle, idle, "paused: the drain wait does not count")
	get_tree().paused = false
	await wait_physics_frames(150)
	assert_lt(state.combo, frozen, "unpaused: it drains again")


func test_nothing_changes_after_the_run_ends() -> void:
	state.add_trick("three_sixty")
	state.kaiju_killed()
	var c := state.combo
	state.add_trick("alternate_drift")
	state.collision()
	state.advance(10.0)
	assert_eq(state.combo, c)


func test_the_combo_works_in_a_run_started_from_the_main_menu() -> void:
	GameSettings.path = TEST_PATH
	DirAccess.remove_absolute(TEST_PATH)
	var game = GameScene.instantiate()
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()
	await wait_process_frames(1)
	var s: RunState = game.run.state
	assert_eq(s.combo, 1.0)
	game.run.car.trick.emit("three_sixty")
	assert_almost_eq(s.combo, 1.0 + combo_data.trick_add("three_sixty"), 0.000001)
	var before := s.combo
	game.run.car.hit_obstacle.emit(autofree(StaticBody2D.new()), 0, Vector2.UP, 10.0)
	assert_almost_eq(s.combo, combo_data.after_collision(before), 0.000001)
	DirAccess.remove_absolute(TEST_PATH)
	GameSettings.path = GameSettings.DEFAULT_PATH
