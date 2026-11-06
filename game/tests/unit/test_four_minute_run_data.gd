extends GutTest
## Task T-520 (the 4-minute run): weapons with 5 tiers (docs/weapons.md, Decisions, "Shorter trees:
## 5 tiers"), power-ups with 2 tiers (Drifting, Decisions, "Two tiers and three slots"), and the
## sub goals set for about 12 gift packs in the 3-minute build (run.json, build_pace).

const RunScene := preload("res://scenes/run/run.tscn")
const RackScript := preload("res://scripts/weapons/weapons.gd")

const WEAPONS := ["gun", "flamethrower", "underglow", "molotov", "wiper", "bricks"]

## The docs' merged tiers: {weapon: {tier: [[effect, value], ...]}}.
const TREES := {
	"gun": {
		2: [["add_bullets", 2]],
		3: [["fire_rate_multiplier", 1.44]],
		4: [["add_bullets", 1], ["fire_rate_multiplier", 1.2]],
		5: [["fire_rate_multiplier", 4]],
	},
	"flamethrower": {
		2: [["size_multiplier", 1.56]],
		3: [["damage_multiplier", 1.2], ["size_multiplier", 1.3]],
		4: [["add_burn_flash_seconds", 2]],
		5: [["always_on", 1]],
	},
	"underglow": {
		2: [["radius_multiplier", 1.5]],
		3: [["damage_multiplier", 2.25]],
		4: [["tick_interval_multiplier", 0.5]],
		5: [["radius_multiplier", 1.3]],
	},
	"molotov": {
		2: [["fire_radius_multiplier", 1.56]],
		3: [["add_molotovs", 2]],
		4: [["throw_interval_multiplier", 0.56]],
		5: [["add_molotovs", 1]],
	},
	"wiper": {
		2: [["length_multiplier", 1.56]],
		3: [["sweep_speed_multiplier", 1.625]],
		4: [["knockback_multiplier", 1.5], ["length_multiplier", 1.3]],
		5: [["add_back_wiper", 1]],
	},
	"bricks": {
		2: [["radius_multiplier", 2.1]],
		3: [["damage_multiplier", 2.25]],
		4: [["knockback_multiplier", 2.25]],
		5: [["widest_wave", 3]],
	},
}


func after_each() -> void:
	RackScript.all_weapons_override = -1
	RackScript.weapon_tier_override = -1


func _tiers_of(w: WeaponData, weapon: String, tier: int) -> Array:
	var out := []
	for t in w.tiers(weapon):
		if int(t["tier"]) == tier:
			out.append([String(t["effect"]), float(t["value"])])
	return out


func test_every_weapon_has_five_tiers_with_the_docs_numbers() -> void:
	var w := WeaponData.new()
	assert_eq(w.max_tier(), 5)
	for weapon in WEAPONS:
		assert_eq(w.max_tier(weapon), 5, weapon)
		var seen := {}
		for t in w.tiers(weapon):
			seen[int(t["tier"])] = true
		assert_eq(seen.keys(), [2, 3, 4, 5], weapon + " has tiers 2 to 5 only")
		for tier in [2, 3, 4, 5]:
			var want: Array = TREES[weapon][tier]
			var got := _tiers_of(w, weapon, tier)
			assert_eq(got.size(), want.size(), "%s tier %d entries" % [weapon, tier])
			for i in mini(got.size(), want.size()):
				assert_eq(got[i][0], want[i][0], "%s tier %d effect" % [weapon, tier])
				assert_almost_eq(got[i][1], float(want[i][1]), 0.00001, "%s tier %d value" % [weapon, tier])


func test_tier_5_is_the_old_tier_8_power() -> void:
	var w := WeaponData.new()
	var g := w.gun_at(5)
	assert_eq(g.bullets, 4, "1 + 2 + 1")
	assert_almost_eq(g.fire_interval, 1.2 / (1.44 * 1.2 * 4.0) + 0.06, 0.0001, "rate x6.912")
	assert_almost_eq(w.flame_at(5).size_multiplier, 0.625 * 1.56 * 1.3, 0.0001)
	assert_true(w.flame_at(5).always_on)
	assert_almost_eq(w.flame_at(5).burn_flash_seconds, 0.38 + 2.0, 0.0001)
	assert_almost_eq(w.underglow_at(5).radius, 2.5 * 1.5 * 1.3, 0.0001)
	assert_eq(w.molotov_at(5).molotovs_per_throw, 4)
	assert_true(w.wiper_at(5).back_wiper)
	assert_almost_eq(w.wiper_at(5).length, 2.5 * 1.56 * 1.3, 0.0001)
	var b := w.bricks_at(5)
	assert_eq(b.rings, 3)
	# Widest wave: rings at the tier 4 radius x1, x2, x3 (the radius times 3 is the outer ring).
	assert_almost_eq(b.radius, w.bricks_at(4).radius * 3.0, 0.0001)
	assert_almost_eq(w.bricks_at(4).radius, 4.0 * 2.1, 0.0001)


func test_underglow_tier_5_is_marked_a_placeholder() -> void:
	var raw: Dictionary = GameData.load_file("weapons").data
	assert_string_contains(String(raw["underglow"]["_comment"]), "PLACEHOLDER")


func test_every_power_up_has_two_tiers_and_tier_2_is_the_old_tier_4() -> void:
	var d := PowerUpData.new()
	assert_eq(d.max_tier(), 2)
	var old_tier_4 := {
		"rev_charge": {"charge_seconds": 0.7, "boost_speed_multiplier": 1.9, "boost_seconds": 1.5},
		"jump": {"takeoff_speed": 8.0, "cooldown_seconds": 1.1},
		"bouncy_bumpers": {"bounce_distance_multiplier": 3.9},
		"rusty_overcoat": {"contact_damage": 5.0, "repeat_cooldown_seconds": 0.3, "hits_kaiju": true},
		"polarized_steering_wheel": {"burst_speed_multiplier": 1.45, "shock_bricks_tier": 1},
	}
	assert_eq(d.ids().size(), 5)
	for id in d.ids():
		assert_eq(d.max_tier(id), 2, id)
		assert_eq(d.tiers(id).size(), 2, id)
		var t2 := d.at(id, 2)
		for key in old_tier_4[id]:
			assert_eq(t2[key], old_tier_4[id][key], "%s tier 2 %s is the old tier 4's" % [id, key])


func test_sub_goals_fit_the_three_minute_pace() -> void:
	var raw: Dictionary = GameData.load_file("run").data
	var pace: Dictionary = raw["build_pace"]
	var rd := RunData.new()
	var level_ups := int(pace["target_gift_packs"])
	assert_eq(level_ups, 12)
	assert_eq(rd.max_level(), level_ups + 1, "12 level-ups: levels 1 to 13")
	var total := 0.0
	for l in range(1, level_ups + 1):
		total += rd.xp_needed(l)
		if l > 1:
			assert_gt(rd.xp_needed(l), rd.xp_needed(l - 1), "the goals grow")
	assert_eq(rd.xp_needed(rd.max_level()), 0.0)
	assert_eq(float(pace["build_seconds"]), 180.0, "the kaiju arrives at 3:00")
	var earned := float(pace["subs_per_second"]) * float(pace["build_seconds"])
	assert_lte(total, earned, "all 12 sub goals (%d) fit what a steady player earns in 3:00 (%d)" % [total, earned])
	assert_gte(total, earned * 0.8, "and are not so small that the packs come far before 3:00")
	# The rate is built from the drift pay and the trick pay the data really has.
	assert_eq(rd.drift_xp_per_second(), 10.0)
	assert_gt(ComboData.new().trick_subs("three_sixty"), 0.0)


func test_playtest_tier_switch_and_god_mode_cap_at_5_and_2() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	RackScript.all_weapons_override = 1
	RackScript.weapon_tier_override = 99
	run.weapons.reset_for_run()
	for id in run.weapons.weapons:
		assert_eq(run.weapons.get_weapon(id).tier, 5, id + " capped at 5")
	var god: Node = run.god_mode
	for e in god.entries():
		var want := 2 if e.kind == "power_up" else 5
		assert_eq(e.last_tier, want, "%s %s" % [e.kind, e.id])
		assert_eq(god.set_tier(e.kind, e.id, 99), want)
