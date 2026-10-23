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
	for weapon in ["gun", "flamethrower", "underglow", "molotov", "wiper"]:
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
	# T-267: a quarter of the Unity prototype's 2.5; the hit area is the drawn flame, so no area numbers.
	assert_almost_eq(f.size_multiplier, 0.625, 0.0001)
	assert_false(f.has("area_width") or f.has("area_depth") or f.has("inner_edge"), "no separate area")
	assert_eq(f.ramp_start_fraction, 0.5)
	assert_eq(f.ramp_seconds, 1.0)
	assert_eq(f.burn_flash_seconds, 0.38)
	assert_false(f.always_on)


func test_flame_tiers_match_report_table() -> void:
	var w := WeaponData.new()
	# tier: [size multiplier, burn flash, turn multiplier, always on]. The size steps are the
	# report's (x1.2 at tiers 2 and 4, x1.3 at tier 6) on T-267's smaller start (0.625).
	var expected := {
		1: [0.625, 0.38, 1.0, false], 2: [0.75, 0.38, 1.0, false],
		3: [0.75, 0.38, 1.0, false], 4: [0.9, 0.38, 1.0, false],
		5: [0.9, 0.88, 1.0, false], 6: [1.17, 0.88, 1.0, false],
		7: [1.17, 0.88, 1.2, false], 8: [1.17, 0.88, 1.2, true],
	}
	for tier in expected:
		var f := w.flame_at(tier)
		var e: Array = expected[tier]
		assert_almost_eq(f.size_multiplier, e[0], 0.0001, "size tier %d" % tier)
		assert_almost_eq(f.burn_flash_seconds, e[1], 0.0001, "flash tier %d" % tier)
		assert_almost_eq(f.turn_speed_multiplier, e[2], 0.0001, "turn tier %d" % tier)
		assert_eq(f.always_on, e[3], "always on tier %d" % tier)


func test_flame_damage_not_rounded_so_hotter_flame_adds_damage() -> void:
	var w := WeaponData.new()
	# Board's fix: the report's tier 3 gave 2.4 rounded to 2 (no change); now it stays 2.4.
	assert_eq(w.flame_at(2).damage, 2.0)
	assert_almost_eq(w.flame_at(3).damage, 2.4, 0.0001)
	assert_almost_eq(w.flame_at(8).damage, 2.4, 0.0001)


func test_five_weapons_each_with_eight_tiers() -> void:
	var raw: Dictionary = GameData.load_file("weapons").data
	var count := 0
	for k in raw:
		if raw[k] is Dictionary and raw[k].has("tiers"):
			count += 1
			assert_eq(raw[k].tiers.size() + 1, 8, "%s has base plus 7 tiers" % k)
	assert_eq(count, 5)


func test_underglow_tiers() -> void:
	var w := WeaponData.new()
	var u1 := w.underglow_at(1)
	assert_eq(u1.damage, 1.0)
	assert_eq(u1.radius, 2.5)
	assert_eq(u1.tick_interval, 1.0)
	assert_true(u1.damage_on_enter)
	var u8 := w.underglow_at(8)
	assert_almost_eq(u8.damage, 2.25, 0.0001)
	assert_almost_eq(u8.radius, 2.5 * 1.2 * 1.25 * 1.3, 0.0001)
	assert_almost_eq(u8.tick_interval, 0.75 * 0.67, 0.0001)


func test_molotov_tiers() -> void:
	var w := WeaponData.new()
	var m1 := w.molotov_at(1)
	assert_eq(m1.molotovs_per_throw, 1)
	assert_eq(m1.fire_radius, 1.5)
	assert_eq(m1.fire_duration, 3.0)
	assert_eq(m1.throw_interval, 3.0)
	var m8 := w.molotov_at(8)
	assert_eq(m8.molotovs_per_throw, 3)
	assert_almost_eq(m8.fire_radius, 1.5 * 1.2 * 1.3, 0.0001)
	assert_almost_eq(m8.fire_duration, 4.5, 0.0001)
	assert_almost_eq(m8.throw_interval, 2.4, 0.0001)
	assert_almost_eq(m8.damage, 3.0, 0.0001)


func test_wiper_tiers_and_knockback() -> void:
	var w := WeaponData.new()
	var w1 := w.wiper_at(1)
	assert_eq(w1.damage, 3.0)
	assert_eq(w1.length, 2.5)
	assert_eq(w1.knockback_distance, 6.0)
	assert_false(w1.knockback_kaiju)
	var w8 := w.wiper_at(8)
	assert_almost_eq(w8.damage, 3.0 * 1.4 * 1.4, 0.0001)
	assert_almost_eq(w8.length, 2.5 * 1.2 * 1.3, 0.0001)
	assert_almost_eq(w8.knockback_distance, 9.0, 0.0001)
	assert_almost_eq(w8.sweep_degrees_per_second, 240.0 * 1.25 * 1.3, 0.0001)


func test_flame_data_has_no_separate_area() -> void:
	# T-267: the hit area is the drawn flame, so the old rectangle's numbers are gone from the data.
	var raw: Dictionary = GameData.load_file("weapons").data
	for k in ["car_half_size", "inner_edge_multiplier", "depth_multiplier", "half_width_multiplier"]:
		assert_false(raw.flamethrower.has(k), "%s is gone" % k)
