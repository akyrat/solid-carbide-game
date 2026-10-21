extends GutTest
## Task T-224: the pickup magnet upgrade sets the run's magnet radius
## (level 0 is run.json's 1 car length).

var PATH := RunPaths.file("test_progress_t224.json")


func before_each() -> void:
	PlayerProgress.path = PATH
	DirAccess.remove_absolute(PATH)


func after_each() -> void:
	DirAccess.remove_absolute(PATH)
	TestSave.restore_progress()


func _radius_at(level: int) -> float:
	var p := PlayerProgress.new(null, PATH)
	p.levels["pickup_magnet"] = level
	var state := RunState.new()
	state.progress = p
	state.start_run()
	var r := state.pickup_magnet_radius_units
	state.free()
	return r


func test_level_0_is_one_car_length() -> void:
	assert_eq(_radius_at(0), 3.0)
	assert_eq(_radius_at(0), RunData.new().pickup_magnet_radius_units())


func test_every_level_uses_the_datas_radius() -> void:
	var garage := GarageData.new()
	for lvl in range(garage.max_level() + 1):
		assert_almost_eq(_radius_at(lvl), garage.value("pickup_magnet", lvl), 0.0001, "level %d" % lvl)
	assert_gt(_radius_at(10), _radius_at(0))


func test_no_progress_keeps_the_base_radius() -> void:
	var state := RunState.new()
	state.start_run()
	assert_eq(state.pickup_magnet_radius_units, 3.0)
	state.free()
