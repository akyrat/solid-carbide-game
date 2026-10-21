extends GutTest
## Enemy data (task T-039): loads through the loader, minion numbers grow but never toughen,
## the kaiju's time to kill with the MVP weapons matches the figures in T-039's result notes,
## and the kaiju always drops a few coins (T-119).

# Assumptions behind the kaiju figures (T-039, Result notes): every gun bullet hits the kaiju
# (no minion is closer than it), the flame is on the kaiju this share of the fight, and the
# garage's damage bonus adds a percentage to every weapon's damage.
const FLAME_ON_KAIJU_SHARE := 0.3


func test_loads_through_loader() -> void:
	var r := GameData.load_file("enemies")
	assert_true(r.ok, r.error)
	var e := EnemyData.new()
	assert_true(e.is_ok(), e.error)
	assert_eq(float(GameData.unwrap(GameData.get_value(r.data, "kaiju.health"))), 500.0)
	assert_false(GameData.get_value(r.data, "minion.armor").ok)


func test_missing_file_gives_clear_error() -> void:
	var e := EnemyData.new("no_such_enemies_file")
	assert_false(e.is_ok())
	assert_string_contains(e.error, "not found")


func test_every_section_has_its_numbers() -> void:
	var e := EnemyData.new()
	var keys := ["health", "move_speed", "contact_damage", "contact_damage_interval", "knockback"]
	assert_eq_deep(_sorted(e.minion().keys()), _sorted(keys))
	assert_eq_deep(_sorted(e.kaiju().keys()), _sorted(keys))
	assert_eq_deep(_sorted(e.spawning().keys()), _sorted(["minions_at_start", "minions_at_boss_time",
		"growth_until_seconds", "spawn_interval_seconds", "spawn_margin_units"]))
	assert_eq_deep(_sorted(e.coins().keys()), _sorted(["drop_chance", "coins_per_drop"]))
	assert_eq_deep(_sorted(e.kaiju_coins().keys()), _sorted(["drop_chance", "coins_per_drop"]))
	assert_eq_deep(_sorted(e.meteor_attack().keys()), _sorted(["first_attack_after_seconds",
		"seconds_between_attacks", "windup_seconds", "meteors_per_attack", "warning_seconds",
		"land_within_units_of_car", "impact_radius_units", "impact_damage", "knockback",
		"boulder_lifetime_seconds", "boulder_fade_seconds", "boulder_clearance_units"]))
	for section in [e.minion(), e.kaiju(), e.spawning(), e.coins(), e.kaiju_coins(), e.meteor_attack()]:
		for k in section:
			assert_gt(section[k], 0.0, "%s is positive" % k)
	assert_true(e.coins().drop_chance <= 1.0)


func test_minion_count_grows_over_the_7_minutes() -> void:
	var e := EnemyData.new()
	var start := e.minions_wanted(0.0)
	var boss := e.minions_wanted(420.0)
	assert_eq(start, 12)
	assert_eq(boss, 20)
	assert_gt(boss, start)
	# Never goes down along the way, and is held during the kaiju's minute.
	var last := start
	for s in range(0, 421, 10):
		var n := e.minions_wanted(float(s))
		assert_true(n >= last, "count at %d s is not below the one before" % s)
		last = n
	assert_eq(e.minions_wanted(480.0), boss)
	# "Slightly": less than double.
	assert_lt(boss, 2 * start)


func test_minion_stats_do_not_change_over_time() -> void:
	# The stats are plain numbers with no time input; the only growth key is in spawning.
	var e := EnemyData.new()
	var early := e.minion()
	e.minions_wanted(420.0)
	assert_eq_deep(e.minion(), early)
	assert_eq(early.health, 4.0)
	assert_eq(early.contact_damage, 5.0)
	var r := GameData.load_file("enemies")
	for k in r.data["minion"]:
		assert_false(String(k).contains("growth") or String(k).contains("scale") or String(k).contains("per_minute"),
			"minion has no time scaling key (%s)" % k)
	for k in r.data["kaiju"]:
		assert_false(String(k).contains("growth") or String(k).contains("scale"), "kaiju has no scaling key (%s)" % k)


func test_combo_raises_the_count() -> void:
	var e := EnemyData.new()
	var combo := ComboData.new()
	assert_eq(e.minions_wanted(0.0, combo.spawn_multiplier(combo.start_multiplier())), 12)
	assert_eq(e.minions_wanted(420.0, combo.spawn_multiplier(combo.max_multiplier())), 35)


func test_expected_coins_per_kill() -> void:
	assert_almost_eq(EnemyData.new().expected_coins_per_kill(), 1.2, 0.0001)


func test_kaiju_always_drops_a_few_coins() -> void:
	# The board's decision (Enemies, Decisions, 2026-10-13): always, a few coins (T-119).
	var e := EnemyData.new()
	var k := e.kaiju_coins()
	assert_eq(k.drop_chance, 1.0, "the kaiju always drops coins")
	assert_eq(k.coins_per_drop, 10.0)
	assert_eq(e.kaiju_coins_on_defeat(), 10)
	assert_gt(e.kaiju_coins_on_defeat(), 0)
	# "A few": a handful of minion drops, and a small part of an average run's ~250 coins.
	var minion_drop: float = e.coins().coins_per_drop
	assert_true(e.kaiju_coins_on_defeat() >= 2 * minion_drop, "more than a single minion drop")
	assert_true(e.kaiju_coins_on_defeat() <= 10 * minion_drop, "no more than a handful of minion drops")
	assert_lt(float(e.kaiju_coins_on_defeat()), 250.0 * 0.1, "under a tenth of an average run")


func test_meteor_attacks_in_the_kaiju_minute() -> void:
	var e := EnemyData.new()
	var times := e.meteor_attack_times(60.0)
	assert_eq_deep(times, [5.0, 13.0, 21.0, 29.0, 37.0, 45.0, 53.0])
	var m := e.meteor_attack()
	assert_eq(m.warning_seconds, 2.0, "warning circle is decided at 2 s")
	# The last attack's meteors land before the 60 seconds are up.
	assert_lt(times[-1] + m.windup_seconds + m.warning_seconds, 60.0)
	assert_eq(times.size() * int(m.meteors_per_attack), 21)


func test_kaiju_time_to_kill_matches_result_notes() -> void:
	# [gun tier, flame tier (0 = no flame), garage damage bonus level, seconds in the result notes]
	var cases := [
		[1, 0, 0, 315.0],   # start of a run: the gun alone, never upgraded
		[4, 4, 0, 48.5],    # average run (level 8): flame, gun tier 4, flame tier 4
		[4, 4, 5, 38.8],    # the same with garage damage bonus level 5 (+25%)
		[6, 6, 0, 33.8],    # top level (12): gun tier 6, flame tier 6
		[8, 0, 0, 37.7],    # every pick on the gun, no flame
		[8, 4, 10, 19.8],   # gun tier 8, flame tier 4, garage bonus maxed (+50%)
	]
	for c in cases:
		assert_almost_eq(_kaiju_seconds(c[0], c[1], c[2]), c[3], 0.05,
			"gun %d, flame %d, garage %d" % [c[0], c[1], c[2]])
	# The average run brings it down inside the 60 seconds; the gun alone does not.
	assert_lt(_kaiju_seconds(4, 4, 0), 60.0)
	assert_gt(_kaiju_seconds(1, 0, 0), 60.0)


func _kaiju_seconds(gun_tier: int, flame_tier: int, garage_level: int) -> float:
	var w := WeaponData.new()
	var g := w.gun_at(gun_tier)
	var dps: float = g.bullets * g.damage / g.fire_interval
	if flame_tier > 0:
		var f := w.flame_at(flame_tier)
		dps += f.damage / f.tick_interval * FLAME_ON_KAIJU_SHARE
	var bonus := 0.0
	if garage_level > 0:
		bonus = float(GarageData.new().value("damage_bonus", garage_level)) / 100.0
	dps *= 1.0 + bonus
	return EnemyData.new().kaiju().health / dps


func _sorted(a: Array) -> Array:
	var b := a.duplicate()
	b.sort()
	return b
