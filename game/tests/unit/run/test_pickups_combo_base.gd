extends GutTest
## Task T-415: a health pickup at full hearts stays (not collected, not pulled), a collision
## within combo.json's window of the one that cut the combo does not cut it again, and the
## garage adds to run.json's base hearts and magnet radius.

const RunScene := preload("res://scenes/run/run.tscn")
const FlameScript := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const STEP := 1.0 / 60.0
const P := 16.0
var PATH := RunPaths.file("test_progress_t415.json")
var RUN_FIXTURE := RunPaths.file("test_run_t415.json")


func before_each() -> void:
	PlayerProgress.path = PATH
	DirAccess.remove_absolute(PATH)
	FlameScript.playtest_override = 0


func after_each() -> void:
	FlameScript.playtest_override = -1
	get_tree().paused = false
	DirAccess.remove_absolute(PATH)
	DirAccess.remove_absolute(RUN_FIXTURE)
	TestSave.restore_progress()


func _run() -> Node2D:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	run.car.model.x = 0.0
	run.car.model.y = 0.0
	run.car.model.set_velocity(Vector2.ZERO)
	run.car._sync_from_model()
	return run


func _steps(run: Node2D, n: int) -> void:
	for i in n:
		run.pickup_magnet.step(STEP)


func test_full_hearts_pickup_is_not_collected_or_pulled() -> void:
	var run := _run()
	var s: RunState = run.state
	assert_eq(s.health, s.max_health)
	var p: Node = run.minions.spawn_health_pickup_at(run.car.position / P + Vector2(-2.0, 0))
	var at: Vector2 = p.position
	assert_false(p.wants_health())
	assert_false(p.can_be_picked_up_by(run.car))
	_steps(run, 60)
	assert_eq(p.position, at, "the magnet leaves it")
	assert_false(p.is_taken())


func test_below_full_hearts_it_is_pulled_and_collected() -> void:
	var run := _run()
	run.state.health = run.state.max_health - 1.0
	var p: Node = run.minions.spawn_health_pickup_at(run.car.position / P + Vector2(-2.0, 0))
	assert_true(p.wants_health())
	assert_true(p.can_be_picked_up_by(run.car))
	_steps(run, 60)
	assert_true(p.is_taken())
	assert_eq(run.state.health, run.state.max_health)


func test_a_pickup_waits_and_is_taken_once_hurt() -> void:
	var run := _run()
	var p: Node = run.minions.spawn_health_pickup_at(run.car.position / P + Vector2(-2.0, 0))
	_steps(run, 10)
	assert_false(p.is_taken())
	run.state.damage_car(1.0)
	_steps(run, 60)
	assert_true(p.is_taken())


func _combo_state() -> RunState:
	var s := RunState.new()
	add_child_autofree(s)
	s.start_run()
	s.combo = 4.0
	return s


func test_two_collisions_03_apart_cut_once() -> void:
	var s := _combo_state()
	s.collision()
	var after_first := s.combo
	assert_lt(after_first, 4.0)
	s.advance(0.3)
	s.collision()
	assert_eq(s.combo, after_first, "the second did not cut")


func test_two_collisions_07_apart_cut_twice() -> void:
	var s := _combo_state()
	s.collision()
	var after_first := s.combo
	s.advance(0.7)
	s.combo = after_first
	s.collision()
	assert_lt(s.combo, after_first, "the second cut")


func test_the_window_is_read_from_the_data() -> void:
	assert_eq(ComboData.new().collision_window_seconds(), 0.5)


func test_a_crash_inside_the_window_still_pays_its_trick() -> void:
	var s := _combo_state()
	var crashes := [0]
	s.crashed.connect(func(): crashes[0] += 1)
	s.collision()
	s.advance(0.2)
	s.collision()
	assert_eq(crashes[0], 2)


func test_a_new_run_clears_the_window() -> void:
	var s := _combo_state()
	s.collision()
	s.start_run()
	s.combo = 4.0
	s.collision()
	assert_lt(s.combo, 4.0)


func _write_run_fixture(hearts: float, radius: float) -> RunData:
	var d: Dictionary = GameData.load_file("run").data
	d["car"]["starting_hearts"] = hearts
	d["pickup_magnet"]["radius_units"] = radius
	var f := FileAccess.open(RUN_FIXTURE, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	return RunData.new(RUN_FIXTURE)


func _progress(health_level: int, magnet_level: int) -> PlayerProgress:
	var p := PlayerProgress.new(null, PATH)
	p.levels["car_health"] = health_level
	p.levels["pickup_magnet"] = magnet_level
	return p


func test_run_json_hearts_change_max_health_with_a_saved_garage() -> void:
	var rd := _write_run_fixture(8.0, 3.0)
	var garage := GarageData.new()
	for lvl in [0, 3]:
		var s := RunState.new(rd)
		s.progress = _progress(lvl, 0)
		s.start_run()
		assert_eq(s.max_health, 8.0 + garage.bonus("car_health", lvl), "level %d" % lvl)
		assert_eq(s.health, s.max_health)
		s.free()
	assert_eq(garage.bonus("car_health", 3), 3.0, "+1 heart per level")


func test_run_json_radius_changes_the_magnet_with_a_saved_garage() -> void:
	var rd := _write_run_fixture(5.0, 4.0)
	var garage := GarageData.new()
	var s := RunState.new(rd)
	s.progress = _progress(0, 5)
	s.start_run()
	assert_almost_eq(s.pickup_magnet_radius_units, 4.0 + garage.bonus("pickup_magnet", 5), 0.0001)
	assert_almost_eq(garage.bonus("pickup_magnet", 5), 3.0, 0.0001)
	s.free()


func test_the_garages_value_follows_run_json_and_stores_no_base() -> void:
	var rd := _write_run_fixture(9.0, 5.0)
	var g := GarageData.new("garage", rd)
	assert_eq(g.value("car_health", 0), 9.0)
	assert_eq(g.value("car_health", 2), 11.0)
	assert_almost_eq(g.value("pickup_magnet", 1), 5.6, 0.0001)
	var raw: Dictionary = GameData.load_file("garage").data
	for id in GarageData.RUN_BASES:
		assert_false(raw["upgrades"][id].has("base_value"), "%s: base only in run.json" % id)
		for row in raw["upgrades"][id]["levels"]:
			assert_false(row.has("value"), "%s: levels store only a bonus" % id)
