extends GutTest
## Task T-463: Rusty Overcoat. With it owned, a minion the car touches takes the owned tier's
## contact_damage (power_ups.json) with the red hit flash, again only after the tier's
## repeat_cooldown_seconds; the kaiju only when the tier's hits_kaiju is true; without it
## contact deals no damage to the enemy.

const RunScene := preload("res://scenes/run/run.tscn")
const KaijuBossScript := preload("res://scripts/enemies/kaiju_boss.gd")
const KaijuScript := preload("res://scripts/enemies/kaiju.gd")
const FlameScript := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const DT := 0.02

var run: Node2D
var spawner: Node
var pu := PowerUpData.new()


func before_each() -> void:
	KaijuBossScript.playtest_override = -1.0
	FlameScript.playtest_override = 0
	run = RunScene.instantiate()
	add_child_autofree(run)
	spawner = run.minions
	spawner.enabled = false
	run.car.use_keyboard = false


func after_each() -> void:
	get_tree().paused = false
	KaijuBossScript.playtest_override = -2.0
	FlameScript.playtest_override = -1


func _car_units() -> Vector2:
	return run.car.position / 16.0


func _own(tier: int) -> void:
	for i in tier:
		run.state.grant_power_up("rusty_overcoat")
	assert_eq(run.state.power_up_tier("rusty_overcoat"), tier)


func _touching_minion() -> Node:
	var offset := Vector2(0.9, 0.0).rotated(run.car.rotation)
	var m: Node = spawner.spawn_minion_at(_car_units() + offset)
	assert_true(m.touches_car(_car_units(), run.car.rotation))
	return m


func _keep_car_healthy() -> void:
	run.state.health = run.state.max_health
	run.state.invulnerable_left = 0.0


func test_each_tier_damages_a_touching_minion_and_flashes_red() -> void:
	for tier in range(1, 5):
		run.state.grant_power_up("rusty_overcoat")
		assert_eq(run.state.power_up_tier("rusty_overcoat"), tier)
		var m: Node = _touching_minion()
		m.health = 100.0
		m.max_health = 100.0
		m.contact_step(DT, run.car, run.state)
		var dmg: float = pu.at("rusty_overcoat", tier)["contact_damage"]
		assert_almost_eq(100.0 - m.health, dmg, 0.0001, "tier %d takes its damage" % tier)
		assert_true(m.hit_tint.is_active(), "tier %d: the red flash" % tier)
		assert_eq(m.sprite.modulate, HitTint.proto().color, "tier %d: tinted red" % tier)
		m.queue_free()
		_keep_car_healthy()


func test_the_car_still_gets_hit() -> void:
	_own(1)
	var m := _touching_minion()
	var before: float = run.state.health
	assert_true(m.contact_step(DT, run.car, run.state), "the minion still hits the car")
	assert_lt(run.state.health, before)
	assert_lt(m.health, m.max_health)


func test_tier_2_two_touches_kill_and_tier_3_one_touch_kills() -> void:
	_own(3)
	var m := _touching_minion()
	m.contact_step(DT, run.car, run.state)
	assert_true(m.is_dead(), "tier 3: 4 damage kills a 4-health minion")
	run.state.start_run()
	_own(2)
	var m2 := _touching_minion()
	m2.contact_step(DT, run.car, run.state)
	assert_false(m2.is_dead())
	for i in int(0.5 / DT) + 2:
		_keep_car_healthy()
		m2.contact_step(DT, run.car, run.state)
	assert_true(m2.is_dead(), "tier 2: the second touch kills")


func test_repeat_follows_the_per_enemy_cooldown() -> void:
	_own(1)
	var m := _touching_minion()
	m.health = 1000.0
	var cd: float = pu.at("rusty_overcoat", 1)["repeat_cooldown_seconds"]
	var dmg: float = pu.at("rusty_overcoat", 1)["contact_damage"]
	var seconds := 2.0
	var hits := 0
	var last: float = m.health
	for i in int(round(seconds / DT)):
		_keep_car_healthy()
		m.contact_step(DT, run.car, run.state)
		if m.health < last:
			hits += 1
			last = m.health
	assert_almost_eq(1000.0 - m.health, dmg * hits, 0.0001)
	assert_between(hits, int(seconds / cd) - 1, int(seconds / cd) + 1, "about one hit per cooldown")
	# A second minion has its own cooldown.
	var other := _touching_minion()
	other.health = 1000.0
	other.contact_step(DT, run.car, run.state)
	assert_almost_eq(1000.0 - other.health, dmg, 0.0001, "another minion is hit at once")


func test_not_touching_no_damage() -> void:
	_own(4)
	var m: Node = spawner.spawn_minion_at(_car_units() + Vector2(4.0, 0.0))
	m.contact_step(DT, run.car, run.state)
	assert_eq(m.health, m.max_health)


func test_without_the_power_up_contact_deals_no_damage_to_the_minion() -> void:
	var m := _touching_minion()
	for i in 100:
		_keep_car_healthy()
		m.contact_step(DT, run.car, run.state)
	assert_eq(m.health, m.max_health)
	assert_false(m.hit_tint.is_active())


func _kaiju() -> Node:
	var offset := Vector2(KaijuScript.RADIUS_UNITS + 0.4, 0.0).rotated(run.car.rotation)
	var k: Node = run.kaiju_boss.appear_at(_car_units() + offset)
	assert_true(k.touches_car(_car_units(), run.car.rotation))
	return k


func test_the_kaiju_is_hit_only_where_the_data_says() -> void:
	for tier in range(1, 5):
		run.state.start_run()
		_own(tier)
		var k := _kaiju()
		var before: float = k.health
		k.contact_step(DT, run.car, run.state)
		var data: Dictionary = pu.at("rusty_overcoat", tier)
		if data["hits_kaiju"]:
			assert_almost_eq(before - k.health, float(data["contact_damage"]), 0.0001, "tier %d hits the kaiju" % tier)
		else:
			assert_eq(k.health, before, "tier %d does not hit the kaiju" % tier)
		k.queue_free()
	assert_true(pu.at("rusty_overcoat", 4)["hits_kaiju"])
	assert_false(pu.at("rusty_overcoat", 1)["hits_kaiju"])


func test_no_power_up_the_kaiju_takes_nothing() -> void:
	var k := _kaiju()
	var before: float = k.health
	k.contact_step(DT, run.car, run.state)
	assert_eq(k.health, before)
