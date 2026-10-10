extends GutTest

func test_loads_through_loader() -> void:
	var r := GameData.load_file("garage")
	assert_true(r.ok, r.error)
	var g := GarageData.new()
	assert_true(g.is_ok())
	assert_eq(g.max_level(), 10)
	for id in GarageData.UPGRADES:
		assert_has(g.upgrade_ids(), id)


func test_every_level_has_price_and_value() -> void:
	var g := GarageData.new()
	for id in GarageData.UPGRADES:
		var rows: Array = GameData.unwrap(GameData.get_value(GameData.load_file("garage").data, "upgrades.%s.levels" % id))
		assert_eq(rows.size(), g.max_level(), id)
		for l in range(1, g.max_level() + 1):
			assert_eq(int(rows[l - 1]["level"]), l)
			assert_gt(g.price(id, l), 0, "%s price level %d" % [id, l])


func test_prices_never_go_down() -> void:
	var g := GarageData.new()
	for id in GarageData.UPGRADES:
		for l in range(2, g.max_level() + 1):
			assert_gte(g.price(id, l), g.price(id, l - 1), "%s level %d" % [id, l])


func test_effects_only_improve() -> void:
	var g := GarageData.new()
	for l in range(1, g.max_level() + 1):
		# acceleration: time to top speed goes down (and stays positive)
		assert_lt(g.value("acceleration", l), g.value("acceleration", l - 1))
		assert_gt(g.value("acceleration", l), 0.0)
		assert_gt(g.value("car_health", l), g.value("car_health", l - 1))
		assert_gt(g.value("damage_bonus", l), g.value("damage_bonus", l - 1))


func test_bases_match_the_game() -> void:
	var g := GarageData.new()
	assert_eq(g.value("car_health", 0), RunData.new().starting_health())
	assert_almost_eq(g.value("acceleration", 0), preload("res://scripts/driving/car_tuning.gd").new().time_to_top_speed, 0.0001)
	assert_eq(g.value("damage_bonus", 0), 0.0)
