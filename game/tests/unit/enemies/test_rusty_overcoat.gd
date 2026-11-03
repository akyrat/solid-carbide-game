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
	for tier in range(1, 3):
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


func test_tier_1_two_touches_kill_and_tier_2_one_touch_kills() -> void:
	_own(2)
	var m := _touching_minion()
	m.contact_step(DT, run.car, run.state)
	assert_true(m.is_dead(), "tier 2: 5 damage kills a 4-health minion")
	run.state.start_run()
	_own(1)
	var m2 := _touching_minion()
	m2.contact_step(DT, run.car, run.state)
	assert_false(m2.is_dead())
	for i in int(0.5 / DT) + 2:
		_keep_car_healthy()
		m2.contact_step(DT, run.car, run.state)
	assert_true(m2.is_dead(), "tier 1: the second touch kills")


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
	_own(2)
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
	for tier in range(1, 3):
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
	assert_true(pu.at("rusty_overcoat", 2)["hits_kaiju"])
	assert_false(pu.at("rusty_overcoat", 1)["hits_kaiju"])


func test_no_power_up_the_kaiju_takes_nothing() -> void:
	var k := _kaiju()
	var before: float = k.health
	k.contact_step(DT, run.car, run.state)
	assert_eq(k.health, before)


# T-477: the overcoat never stops the enemy's own hit on the car.
func test_a_minion_the_overcoat_kills_still_hits_the_car() -> void:
	for tier in range(1, 3):
		run.state.start_run()
		_own(tier)
		var m := _touching_minion()
		m.health = 1.0
		var before: float = run.state.health
		assert_true(m.contact_step(DT, run.car, run.state), "tier %d: it hits the car" % tier)
		assert_true(m.is_dead(), "tier %d: and the overcoat killed it" % tier)
		assert_lt(run.state.health, before, "tier %d: the car lost health" % tier)


func test_a_weapon_damaged_minion_killed_on_touch_still_hits_the_car() -> void:
	_own(2)
	var m := _touching_minion()
	m.take_damage(1.0, "neon_zone")
	assert_false(m.is_dead())
	var before: float = run.state.health
	m.contact_step(DT, run.car, run.state)
	assert_true(m.is_dead())
	assert_lt(run.state.health, before)


func test_invulnerability_still_stops_a_second_hit_with_and_without_overcoat() -> void:
	for tier in [0, 2]:
		run.state.start_run()
		if tier > 0:
			_own(tier)
		var a := _touching_minion()
		a.health = 1.0
		assert_true(a.contact_step(DT, run.car, run.state))
		var after_first: float = run.state.health
		assert_true(run.state.is_invulnerable())
		var b := _touching_minion()
		b.health = 1.0
		assert_false(b.contact_step(DT, run.car, run.state), "tier %d: no second hit" % tier)
		assert_eq(run.state.health, after_first)


func test_the_kaiju_the_overcoat_kills_still_gets_its_hit_in() -> void:
	# Killing the kaiju wins the run, and damage_car() does nothing once the run is over, so
	# the proof is the hit going through while the kaiju has a little health left.
	_own(2)
	var k := _kaiju()
	var dmg: float = pu.at("rusty_overcoat", 2)["contact_damage"]
	k.health = dmg + 1.0
	var before: float = run.state.health
	assert_true(k.contact_step(DT, run.car, run.state), "it hits the car")
	assert_lt(run.state.health, before)
	# And the same step with the kill in it: the step still reaches the car's hit.
	_keep_car_healthy()
	k.contact_cooldown = 0.0
	k.overcoat_cooldown = 0.0
	k.health = dmg
	assert_true(k.contact_step(DT, run.car, run.state), "killed in the step, it still hits")
	assert_true(k.is_dead())
