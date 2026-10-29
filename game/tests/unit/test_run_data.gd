extends GutTest

func test_loads_through_loader() -> void:
	var r := GameData.load_file("run")
	assert_true(r.ok, r.error)
	assert_true(r.data is Dictionary)
	assert_eq(float(GameData.unwrap(GameData.get_value(r.data, "car.starting_hearts"))), 5.0)


func test_level_1_threshold_is_one_challenge() -> void:
	var rd := RunData.new()
	assert_true(rd.is_ok())
	assert_eq(rd.xp_needed(1), rd.challenge_xp(1))


func test_drift_second_is_10_percent_of_level_1_and_constant() -> void:
	var rd := RunData.new()
	# T-328: level 1 needs 30 now, so a drift second is a third of it (was 10% of 100); still 10 a second.
	assert_almost_eq(rd.drift_xp_per_second(), 10.0, 0.0001)
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


func test_likes_drain_loads_with_sensible_values() -> void:
	var rd := RunData.new()
	assert_true(rd.is_ok())
	assert_true(rd.likes_drain_enabled(), "the drain is on by default")
	assert_gt(rd.likes_drain_bar_share_per_second(), 0.0)
	assert_lt(rd.likes_drain_bar_share_per_second(), 1.0, "less than a whole bar per second")
	assert_eq(rd.likes_drain_extra_wait_seconds(), 0.0, "the board's rule: starts when the combo has drained")


func test_likes_drain_is_the_boards_playtest_speed() -> void:
	# T-120: the board's playtest value, four times T-114's first proposal.
	var rd := RunData.new()
	assert_almost_eq(rd.likes_drain_bar_share_per_second(), 0.08, 0.0001)
	# A full bar empties in 12.5 seconds, at every level.
	assert_almost_eq(1.0 / rd.likes_drain_bar_share_per_second(), 12.5, 0.0001)
	# T-328: 2.4 likes a second at level 1 (8% of its 30 bar; was 8 of 100).
	assert_almost_eq(rd.likes_drain_xp_per_second(1), 2.4, 0.0001)


func test_likes_drain_scales_with_the_level_bar() -> void:
	var rd := RunData.new()
	var share := rd.likes_drain_bar_share_per_second()
	for l in range(1, rd.max_level()):
		assert_almost_eq(rd.likes_drain_xp_per_second(l), share * rd.xp_needed(l), 0.0001)
	assert_eq(rd.likes_drain_xp_per_second(rd.max_level()), 0.0, "no bar at max level")
	assert_almost_eq(rd.likes_drain_xp_per_second(1), share * rd.xp_needed(1), 0.0001)


func test_hearts_numbers() -> void:
	var rd := RunData.new()
	assert_eq(rd.starting_hearts(), 5.0, "5 starting hearts")
	assert_eq(rd.starting_health(), 5.0, "the old name reads the same")
	assert_eq(rd.invulnerability_seconds(), 1.0, "1 s of invulnerability after a hit")
	assert_gt(rd.blink_interval_seconds(), 0.0)
	assert_lt(rd.blink_interval_seconds(), rd.invulnerability_seconds())
	assert_false(GameData.load_file("run").data["car"].has("starting_health"), "the 100 health is gone")


func test_damage_in_hearts() -> void:
	var e := EnemyData.new()
	assert_eq(float(e.minion()["contact_damage"]), 1.0, "minion hit: 1 heart")
	assert_eq(float(e.meteor_attack()["impact_damage"]), 1.0, "meteor: 1 heart")
	assert_eq(float(e.kaiju()["contact_damage"]), 2.0, "kaiju: 2 hearts")
	assert_false(e.minion().has("contact_damage_interval"), "the 0.5 s contact repeat is gone")
	assert_false(e.kaiju().has("contact_damage_interval"), "the 1 s contact repeat is gone")


func test_health_drops_and_garage_hearts() -> void:
	var d := EnemyData.new().health_drops()
	assert_eq(float(d["drop_chance"]), 0.15)
	assert_eq(float(d["restore_hearts"]), 1.0)
	var g := GarageData.new()
	assert_eq(g.value("car_health", 0), 5.0, "level 0: 5 hearts")
	for l in range(1, g.max_level() + 1):
		assert_eq(g.value("car_health", l), 5.0 + l, "+1 heart per level (level %d)" % l)
