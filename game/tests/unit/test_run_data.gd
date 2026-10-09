extends GutTest

func test_loads_through_loader() -> void:
	var r := GameData.load_file("run")
	assert_true(r.ok, r.error)
	assert_true(r.data is Dictionary)
	assert_eq(float(GameData.unwrap(GameData.get_value(r.data, "car.starting_health"))), 100.0)


func test_level_1_threshold_is_one_challenge() -> void:
	var rd := RunData.new()
	assert_true(rd.is_ok())
	assert_eq(rd.xp_needed(1), rd.challenge_xp(1))


func test_drift_second_is_10_percent_of_level_1_and_constant() -> void:
	var rd := RunData.new()
	assert_almost_eq(rd.drift_xp_per_second(), rd.xp_needed(1) * 0.1, 0.0001)
	# One fixed value for every level: the data has a single drift number, none per level.
	for row in GameData.unwrap(GameData.get_value(GameData.load_file("run").data, "levels")):
		assert_false(row.has("drift_xp"))


func test_levels_are_complete_and_growing() -> void:
	var rd := RunData.new()
	for l in range(1, rd.max_level() - 1):
		assert_gt(rd.xp_needed(l + 1), rd.xp_needed(l))
	assert_eq(rd.xp_needed(rd.max_level()), 0.0)
	assert_gt(rd.starting_health(), 0.0)


func test_missing_file_gives_clear_error() -> void:
	var r := GameData.load_file("does_not_exist")
	assert_false(r.ok)
	assert_string_contains(r.error, "not found")
	assert_string_contains(r.error, "does_not_exist.json")
	assert_false(RunData.new("nope").is_ok())


func test_missing_value_gives_clear_error() -> void:
	var data: Dictionary = GameData.load_file("run").data
	var r := GameData.get_value(data, "car.armor")
	assert_false(r.ok)
	assert_string_contains(r.error, "car.armor")
	assert_false(GameData.get_value(data, "levels.99.xp_needed").ok)
