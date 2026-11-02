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
	assert_eq(g.damage, 4.0, "T-408: a minion's health, one bullet kills one")
	assert_eq(g.targets, 1)
	assert_eq(g.range, 12.0)
	assert_almost_eq(g.fire_interval, 1.26, 0.0001)
	assert_eq(g.bullets, 1)
	assert_eq(g.bullet_speed, 15.0)
	assert_eq(g.bullet_hit_radius, 1.0)
	assert_eq(g.delay_between_bullets, 0.05)
	assert_eq(g.pierce_hits, 0)


## T-496 (Weapons, Decisions, 2026-11-02, the board's own tree): tiers 2-3 +1 bullet, 4-5 20%
## faster, 6 +1 bullet, 7 20% faster, 8 fire rate x4; one target at every tier; range and pierce never change.
func test_gun_tiers_match_the_board_order() -> void:
	var w := WeaponData.new()
	# tier: [bullets, fire interval, targets]
	var expected := {
		1: [1, 1.26, 1], 2: [2, 1.26, 1], 3: [3, 1.26, 1], 4: [3, 1.06, 1], 5: [3, 0.893, 1],
		6: [4, 0.893, 1], 7: [4, 0.754, 1], 8: [4, 1.2 / 6.912 + 0.06, 1],
	}
	for tier in expected:
		var g := w.gun_at(tier)
		var e: Array = expected[tier]
		assert_eq(g.bullets, e[0], "bullets tier %d" % tier)
		assert_almost_eq(g.fire_interval, e[1], 0.001, "interval tier %d" % tier)
		assert_eq(g.targets, e[2], "targets tier %d" % tier)
		assert_eq(g.range, 12.0, "range tier %d" % tier)
		assert_eq(g.missed_bullet_max_travel, 12.0)
		assert_eq(g.pierce_hits, 0, "pierce tier %d" % tier)
		assert_eq(g.damage, 4.0)


func test_gun_damage_one_shots_a_minion() -> void:
	var minion_health := float(GameData.unwrap(GameData.get_value(GameData.unwrap(GameData.load_file("enemies")), "minion.health")))
	assert_gte(WeaponData.new().gun_at(1).damage, minion_health, "tier 1 bullet >= a minion's health")


func test_tier_count_per_weapon() -> void:
	var w := WeaponData.new()
	assert_eq(w.max_tier(), 8, "the shared last tier")
	assert_eq(w.max_tier("gun"), 8, "the gun's own (T-496)")
	var gun_tiers := w.tiers("gun")
	assert_eq(gun_tiers.size(), 7)
	for i in 7:
		assert_eq(int(gun_tiers[i].tier), i + 2)
	for weapon in ["flamethrower", "underglow", "molotov", "wiper", "bricks"]:
		# The wiper ends at tier 7 until T-499 adds its tier 8 (Bricks' came with T-498).
		var last := 7 if weapon in ["wiper"] else 8
		assert_eq(w.max_tier(weapon), last, weapon)
		var tiers := w.tiers(weapon)
		assert_eq(tiers.size(), last - 1)
		for i in last - 1:
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
	# tier: [size multiplier, burn time, turn multiplier, always on]. T-496, the board's tree: size
	# x1.2, x1.3, x1.3 at tiers 2, 4, 6 (from T-267's 0.625), +1 s burn at tiers 5 and 7, always on at 8.
	var expected := {
		1: [0.625, 0.38, 1.0, false], 2: [0.75, 0.38, 1.0, false],
		3: [0.75, 0.38, 1.0, false], 4: [0.975, 0.38, 1.0, false],
		5: [0.975, 1.38, 1.0, false], 6: [1.2675, 1.38, 1.0, false],
		7: [1.2675, 2.38, 1.0, false], 8: [1.2675, 2.38, 1.0, true],
	}
	for tier in expected:
		var f := w.flame_at(tier)
		var e: Array = expected[tier]
		assert_almost_eq(f.size_multiplier, e[0], 0.0001, "size tier %d" % tier)
		assert_almost_eq(f.burn_flash_seconds, e[1], 0.0001, "burn time tier %d" % tier)
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
			var last := int(raw[k].get("max_tier", raw["max_tier"]))
			assert_eq(raw[k].tiers.size() + 1, last, "%s has base plus its upgrade tiers" % k)
			assert_eq(last, 7 if k in ["wiper"] else 8, "%s's last tier (T-496: the wiper 7 until T-499; Bricks 8 since T-498)" % k)
	assert_eq(count, 6, "the five MVP weapons and Bricks")


func test_underglow_tiers() -> void:
	var w := WeaponData.new()
	var u1 := w.underglow_at(1)
	assert_eq(u1.damage, 2.0)
	assert_eq(u1.radius, 2.5)
	assert_eq(u1.tick_interval, 1.0)
	assert_true(u1.damage_on_enter)
	var u8 := w.underglow_at(8)
	assert_almost_eq(u8.damage, 4.5, 0.0001)
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
	assert_eq(m8.molotovs_per_throw, 4, "MOREEEE: 4 per throw")
	assert_almost_eq(m8.fire_radius, 1.5 * 1.2 * 1.3, 0.0001)
	assert_almost_eq(m8.fire_duration, 3.0, 0.0001, "no duration tier any more")
	assert_almost_eq(m8.throw_interval, 3.0 * 0.8 * 0.7, 0.0001)
	assert_almost_eq(m8.damage, 2.0, 0.0001, "no damage tier any more")


func test_wiper_tiers_and_knockback() -> void:
	var w := WeaponData.new()
	var w1 := w.wiper_at(1)
	assert_eq(w1.damage, 3.0)
	assert_eq(w1.length, 2.5)
	assert_eq(w1.knockback_distance, 6.0)
	assert_false(w1.knockback_kaiju)
	var w7 := w.wiper_at(7)
	assert_almost_eq(w7.damage, 3.0, 0.0001, "no damage upgrades")
	assert_almost_eq(w7.length, 2.5 * 1.2 * 1.3 * 1.3, 0.0001)
	assert_almost_eq(w7.knockback_distance, 9.0, 0.0001)
	assert_almost_eq(w7.sweep_degrees_per_second, 240.0 * 1.25 * 1.3, 0.0001)


func test_bricks_numbers_and_tiers() -> void:
	var w := WeaponData.new()
	var b1 := w.bricks_at(1)
	assert_eq(b1.damage, 6.0)
	assert_eq(b1.radius, 4.0)
	assert_eq(b1.knockback_distance, 4.0)
	assert_false(b1.knockback_kaiju)
	assert_eq(b1.min_air_seconds, 0.3)
	assert_eq(b1.cooldown, 0.5)
	var b7 := w.bricks_at(7)
	assert_almost_eq(b7.damage, 6.0 * 1.5 * 1.5, 0.0001)
	assert_almost_eq(b7.radius, 4.0 * 1.4 * 1.5, 0.0001)
	assert_almost_eq(b7.knockback_distance, 4.0 * 1.5 * 1.5, 0.0001)
	# The wave kills a minion (health 4) outright from the first tier.
	var minion_health := float(GameData.load_file("enemies").data.minion.health)
	assert_true(b1.damage >= minion_health)
	# Tier 8, Widest Wave (T-498): the radius x3, three rings; the shortest air time is the airtime trick's.
	assert_eq(w.tiers("bricks").size(), 7)
	assert_eq(b7.rings, 1)
	var b8 := w.bricks_at(8)
	assert_almost_eq(b8.radius, b7.radius * 3.0, 0.0001)
	assert_eq(b8.rings, 3)
	assert_almost_eq(b8.damage, b7.damage, 0.0001)
	assert_almost_eq(b8.knockback_distance, b7.knockback_distance, 0.0001)
	assert_eq(b1.min_air_seconds, float(GameData.load_file("combo").data.airtime.min_seconds))


func test_bricks_offered_now_that_it_is_built() -> void:
	# T-323 kept it out of the level-ups; T-324 turned it on with the weapon.
	assert_true(WeaponData.new().bricks_offered())
	var offers := preload("res://scripts/weapons/level_up_offers.gd")
	assert_true(offers.WEAPON_ORDER.has("bricks"))
	assert_true(offers.ALL_IDS.has("get_bricks"))
	assert_true(offers.ALL_IDS.has("upgrade_bricks"))


func test_flame_data_has_no_separate_area() -> void:
	# T-267: the hit area is the drawn flame, so the old rectangle's numbers are gone from the data.
	var raw: Dictionary = GameData.load_file("weapons").data
	for k in ["car_half_size", "inner_edge_multiplier", "depth_multiplier", "half_width_multiplier"]:
		assert_false(raw.flamethrower.has(k), "%s is gone" % k)


func test_each_weapons_top_tier_comes_from_its_own_data_and_set_tier_clamps_to_it() -> void:
	var raw: Dictionary = GameData.unwrap(GameData.load_file("weapons"))
	var w := WeaponData.new()
	for weapon in ["gun", "flamethrower", "underglow", "molotov", "wiper", "bricks"]:
		var own := int(raw[weapon].get("max_tier", raw["max_tier"]))
		assert_eq(w.max_tier(weapon), own, weapon)
		assert_eq(w.tiers(weapon).size(), own - 1, "%s has a tier for every step to its top" % weapon)
	assert_eq(w.max_tier("not_a_weapon"), int(raw["max_tier"]), "an unknown weapon falls back to the shared top")


## T-496: every tier of the board's trees, effect and value, in the board's order.
func test_tiers_match_the_boards_trees() -> void:
	var w := WeaponData.new()
	var want := {
		"gun": [["add_bullets", 1], ["add_bullets", 1], ["fire_rate_multiplier", 1.2], ["fire_rate_multiplier", 1.2], ["add_bullets", 1], ["fire_rate_multiplier", 1.2], ["fire_rate_multiplier", 4]],
		"flamethrower": [["size_multiplier", 1.2], ["damage_multiplier", 1.2], ["size_multiplier", 1.3], ["add_burn_flash_seconds", 1], ["size_multiplier", 1.3], ["add_burn_flash_seconds", 1], ["always_on", 1]],
		"molotov": [["fire_radius_multiplier", 1.2], ["throw_interval_multiplier", 0.8], ["add_molotovs", 1], ["add_molotovs", 1], ["throw_interval_multiplier", 0.7], ["fire_radius_multiplier", 1.3], ["add_molotovs", 1]],
		"bricks": [["radius_multiplier", 1.4], ["damage_multiplier", 1.5], ["knockback_multiplier", 1.5], ["radius_multiplier", 1.5], ["damage_multiplier", 1.5], ["knockback_multiplier", 1.5], ["widest_wave", 3]],
		"wiper": [["length_multiplier", 1.2], ["sweep_speed_multiplier", 1.25], ["knockback_multiplier", 1.5], ["length_multiplier", 1.3], ["sweep_speed_multiplier", 1.3], ["length_multiplier", 1.3]],
	}
	for weapon in want:
		var tiers := w.tiers(weapon)
		assert_eq(tiers.size(), want[weapon].size(), weapon)
		for i in tiers.size():
			assert_eq(int(tiers[i].tier), i + 2, "%s tier number" % weapon)
			assert_eq(String(tiers[i].effect), want[weapon][i][0], "%s tier %d effect" % [weapon, i + 2])
			assert_almost_eq(float(tiers[i].value), float(want[weapon][i][1]), 0.0001, "%s tier %d value" % [weapon, i + 2])


## T-496: Neon Underglow's block is the board's "unchanged" one (T-166's numbers).
func test_underglow_block_is_unchanged() -> void:
	var u: Dictionary = GameData.unwrap(GameData.load_file("weapons"))["underglow"]
	var effects := []
	for t in u["tiers"]:
		effects.append([String(t["effect"]), float(t["value"])])
	assert_eq(effects, [["radius_multiplier", 1.2], ["damage_multiplier", 1.5], ["tick_interval_multiplier", 0.75], ["radius_multiplier", 1.25], ["damage_multiplier", 1.5], ["tick_interval_multiplier", 0.67], ["radius_multiplier", 1.3]])
	assert_eq([u["damage"], u["radius"], u["tick_interval"]], [2.0, 2.5, 1.0])
