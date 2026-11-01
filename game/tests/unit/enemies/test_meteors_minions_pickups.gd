extends GutTest
## Task T-418: a meteor hurts minions where it lands, pushes coins and health pickups out of the
## boulder it leaves, misses a car jumping over it, and the data guards (Enemies, Decisions,
## "Meteors hit minions and push pickups aside").

const RunScene := preload("res://scenes/run/run.tscn")
const KaijuBossScript := preload("res://scripts/enemies/kaiju_boss.gd")
const FlameScript := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const SpawnerScript := preload("res://scripts/enemies/minion_spawner.gd")
const DT := 0.02

var run: Node2D
var met: Node
var m: Dictionary


func before_each() -> void:
	KaijuBossScript.playtest_override = -1.0
	FlameScript.playtest_override = 0
	run = RunScene.instantiate()
	add_child_autofree(run)
	met = run.kaiju_boss.meteors
	met.rng.seed = 418
	run.minions.enabled = false
	run.car.use_keyboard = false
	m = EnemyData.new().meteor_attack()


func after_each() -> void:
	KaijuBossScript.playtest_override = -2.0
	FlameScript.playtest_override = -1


func _car_units() -> Vector2:
	return run.car.position / 16.0


func _spot(distance: float) -> Vector2:
	for i in 64:
		var p := _car_units() + Vector2.RIGHT.rotated(TAU * i / 64.0 + 0.3) * distance
		if met.is_good_spot(p):
			return p
	fail_test("no good spot")
	return Vector2.ZERO


func test_a_meteor_damages_a_minion_where_it_lands() -> void:
	var spot := _spot(8.0)
	var minion: Node = run.minions.spawn_minion_at(spot)
	var before: float = minion.health
	met.land(spot)
	assert_lt(minion.health, before, "the minion lost health")
	assert_almost_eq(before - minion.health, float(m["minion_damage"]), 0.001)


func test_a_minion_far_from_the_landing_is_not_hurt() -> void:
	var spot := _spot(8.0)
	var minion: Node = run.minions.spawn_minion_at(spot + Vector2(m["impact_radius_units"] + 3.0, 0.0))
	var before: float = minion.health
	met.land(spot)
	assert_eq(minion.health, before)


func test_a_coin_and_a_health_pickup_on_a_boulders_spot_end_up_outside_it() -> void:
	var spot := _spot(8.0)
	var coin: Node = run.minions.spawn_coin_at(spot + Vector2(0.3, 0.2))
	var heart: Node = run.minions.spawn_health_pickup_at(spot)  # dead centre
	var r: float = run.map.boulder_diameter() / 2.0
	met.land(spot)
	assert_eq(run.map.meteor_boulders.size(), 1, "the boulder is there")
	for p in [coin, heart]:
		assert_true(is_instance_valid(p) and not p.is_taken(), "still there")
		assert_gte(p.position_units().distance_to(spot), r + 0.5 - 0.001, "outside the boulder")
		assert_true(p.is_in_group("coins") or p.is_in_group("health_pickups"))
		assert_true(p in run.minions.coins or p in run.minions.health_pickups, "still tracked")


func test_a_pushed_pickup_can_still_be_collected() -> void:
	var spot := _spot(8.0)
	var coin: Node = run.minions.spawn_coin_at(spot)
	var coins_before: int = run.state.coins
	met.land(spot)
	run.car.position = coin.position
	coin.collect()
	assert_eq(run.state.coins, coins_before + coin.value, "collectable")


func test_a_pickup_far_from_the_boulder_stays_put() -> void:
	var spot := _spot(8.0)
	var coin: Node = run.minions.spawn_coin_at(spot + Vector2(6.0, 0.0))
	var at: Vector2 = coin.position
	met.land(spot)
	assert_eq(coin.position, at)


func test_a_car_high_above_the_landing_takes_no_damage() -> void:
	var spot := _car_units() + Vector2(0.5, 0.0)
	run.car.height_model.height = 2.5
	var before: float = run.state.health
	assert_false(met.land(spot), "no hit")
	assert_eq(run.state.health, before)


func test_a_car_at_the_same_level_is_hit() -> void:
	var spot := _car_units() + Vector2(0.5, 0.0)
	run.car.height_model.height = 0.0
	var before: float = run.state.health
	assert_true(met.land(spot))
	assert_lt(run.state.health, before)


func test_a_car_one_unit_up_is_still_hit() -> void:
	var spot := _car_units() + Vector2(0.5, 0.0)
	run.car.height_model.height = 1.0
	assert_true(met.land(spot), "within 1 unit: the same rule as contact damage")


func test_a_zero_gap_between_attacks_does_not_hang_and_reports_an_error() -> void:
	var data := EnemyData.new()
	data._data["meteor_attack"]["seconds_between_attacks"] = 0
	var times := data.meteor_attack_times(60.0)
	assert_push_error("seconds_between_attacks must be above 0")
	assert_eq(times.size(), 1, "only the first attack")
	data._data["meteor_attack"]["seconds_between_attacks"] = -3
	data.meteor_attack_times(60.0)
	assert_push_error("seconds_between_attacks must be above 0")


func test_a_zero_gap_does_not_make_the_clock_attack_every_step() -> void:
	met._stats["seconds_between_attacks"] = 0.0
	var k: Node = run.kaiju_boss.appear_at(_car_units() + Vector2(14.0, 0.0))
	run.kaiju_boss.enabled = false
	var starts := []
	met.attack_started.connect(func() -> void: starts.append(1))
	for i in int(20.0 / DT):
		met.step(DT)
	assert_lt(starts.size(), 400, "bounded by the minimum gap")
	assert_lte(float(starts.size()), 20.0 / met.MIN_ATTACK_GAP + 1.0)
	assert_not_null(k)


func test_a_missing_spawn_interval_uses_the_default() -> void:
	# T-443: the timer's two intervals; missing or not above 0 falls back to the default, reported.
	var sp := SpawnerScript.new()
	sp._spawning = {"spawn_interval_at_start_seconds": 1.25, "spawn_interval_at_boss_time_seconds": 1.25, "growth_until_seconds": 420.0}
	assert_almost_eq(sp.spawn_interval(), 1.25, 0.0001)
	sp._spawning = {}
	assert_eq(sp.spawn_interval(), SpawnerScript.DEFAULT_SPAWN_INTERVAL)
	sp._spawning = {"spawn_interval_at_start_seconds": 0.0, "spawn_interval_at_boss_time_seconds": 0.3, "growth_until_seconds": 420.0}
	assert_eq(sp.spawn_interval(), SpawnerScript.DEFAULT_SPAWN_INTERVAL)
	assert_push_error("spawn_interval_at_start_seconds and spawn_interval_at_boss_time_seconds must be above 0")
	assert_push_error("spawn_interval_at_start_seconds and spawn_interval_at_boss_time_seconds must be above 0")
	sp.free()
