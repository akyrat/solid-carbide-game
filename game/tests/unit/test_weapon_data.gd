extends GutTest
## Weapon data against the Unity weapons report (docs/weapons/unity-weapons-report.md), sections 2 to 5.


func test_loads_through_loader() -> void:
	var r := GameData.load_file("weapons")
	assert_true(r.ok, r.error)
	assert_true(WeaponData.new().is_ok())
	assert_eq(int(GameData.unwrap(GameData.get_value(r.data, "gun.tiers.0.tier"))), 2)
	assert_false(GameData.get_value(r.data, "gun.armor").ok)


func test_gun_base_values_match_report() -> void:
	var g := WeaponData.new().gun_at(1)
	assert_eq(g.damage, 2.0)
	assert_eq(g.range, 12.0)
	assert_almost_eq(g.fire_interval, 1.26, 0.0001)
	assert_eq(g.bullets, 1)
	assert_eq(g.bullet_speed, 15.0)
	assert_eq(g.bullet_hit_radius, 1.0)
	assert_eq(g.delay_between_bullets, 0.05)
	assert_eq(g.pierce_hits, 0)


func test_gun_tiers_match_report_table() -> void:
	var w := WeaponData.new()
	# tier: [bullets, fire interval, range, pierce]
	var expected := {
		1: [1, 1.26, 12.0, 0], 2: [3, 1.26, 12.0, 0], 3: [3, 1.06, 12.0, 0],
		4: [3, 0.893, 12.0, 0], 5: [3, 0.893, 18.0, 0], 6: [5, 0.893, 18.0, 0],
		7: [5, 0.754, 18.0, 0], 8: [5, 0.754, 18.0, 1],
	}
	for tier in expected:
		var g := w.gun_at(tier)
		var e: Array = expected[tier]
		assert_eq(g.bullets, e[0], "bullets tier %d" % tier)
		assert_almost_eq(g.fire_interval, e[1], 0.001, "interval tier %d" % tier)
		assert_eq(g.range, e[2], "range tier %d" % tier)
		assert_eq(g.pierce_hits, e[3], "pierce tier %d" % tier)
		assert_eq(g.damage, 2.0)


func test_gun_missed_bullets_removed_past_range() -> void:
	var w := WeaponData.new()
	assert_eq(w.gun_at(1).missed_bullet_max_travel, 12.0)
	assert_eq(w.gun_at(5).missed_bullet_max_travel, 18.0)


func test_tier_count_is_seven_upgrades_each() -> void:
	var w := WeaponData.new()
	assert_eq(w.max_tier(), 8)
	for weapon in ["gun", "flamethrower"]:
		var tiers := w.tiers(weapon)
		assert_eq(tiers.size(), 7)
		for i in 7:
			assert_eq(int(tiers[i].tier), i + 2)


func test_flame_base_values_match_report() -> void:
	var f := WeaponData.new().flame_at(1)
	assert_eq(f.damage, 2.0)
	assert_eq(f.tick_interval, 0.2)
	assert_eq(f.min_speed, 0.85)
	assert_eq(f.linger, 0.2)
	assert_almost_eq(f.size_multiplier, 2.5, 0.0001)
	assert_almost_eq(f.area_width, 2.625, 0.0001)
	assert_almost_eq(f.area_depth, 3.25, 0.0001)
	assert_almost_eq(f.inner_edge, 0.175, 0.0001)
	assert_eq(f.ramp_start_fraction, 0.5)
	assert_eq(f.ramp_seconds, 1.0)
	assert_eq(f.burn_flash_seconds, 0.38)
	assert_false(f.always_on)


func test_flame_tiers_match_report_table() -> void:
	var w := WeaponData.new()
	# tier: [size multiplier, width, depth, burn flash, turn multiplier, always on]
	var expected := {
		1: [2.5, 2.625, 3.25, 0.38, 1.0, false], 2: [3.0, 3.15, 3.9, 0.38, 1.0, false],
		3: [3.0, 3.15, 3.9, 0.38, 1.0, false], 4: [3.6, 3.78, 4.68, 0.38, 1.0, false],
		5: [3.6, 3.78, 4.68, 0.88, 1.0, false], 6: [4.68, 4.914, 6.084, 0.88, 1.0, false],
		7: [4.68, 4.914, 6.084, 0.88, 1.2, false], 8: [4.68, 4.914, 6.084, 0.88, 1.2, true],
	}
	for tier in expected:
		var f := w.flame_at(tier)
		var e: Array = expected[tier]
		assert_almost_eq(f.size_multiplier, e[0], 0.0001, "size tier %d" % tier)
		assert_almost_eq(f.area_width, e[1], 0.001, "width tier %d" % tier)
		assert_almost_eq(f.area_depth, e[2], 0.001, "depth tier %d" % tier)
		assert_almost_eq(f.burn_flash_seconds, e[3], 0.0001, "flash tier %d" % tier)
		assert_almost_eq(f.turn_speed_multiplier, e[4], 0.0001, "turn tier %d" % tier)
		assert_eq(f.always_on, e[5], "always on tier %d" % tier)


func test_flame_damage_not_rounded_so_hotter_flame_adds_damage() -> void:
	var w := WeaponData.new()
	# Board's fix: the report's tier 3 gave 2.4 rounded to 2 (no change); now it stays 2.4.
	assert_eq(w.flame_at(2).damage, 2.0)
	assert_almost_eq(w.flame_at(3).damage, 2.4, 0.0001)
	assert_almost_eq(w.flame_at(8).damage, 2.4, 0.0001)


func test_flame_area_does_not_depend_on_heading() -> void:
	# Board's fix: the half-size is the fixed axis value 0.5, not the world bounding box (0.5 to 0.707).
	var raw: Dictionary = GameData.load_file("weapons").data
	assert_eq(float(raw.flamethrower.car_half_size), 0.5)
