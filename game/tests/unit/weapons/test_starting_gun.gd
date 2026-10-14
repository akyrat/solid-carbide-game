extends GutTest
## Task T-041: the starting gun. It fires only with an enemy in range, at the
## data's interval; its bullets go for the closest enemy (then the next
## closest) and damage by the data's amount; every upgrade tier takes effect;
## a new run starts with the base gun; the weapon rack's plumbing.

const RunScene := preload("res://scenes/run/run.tscn")
const DT := 0.02  # one physics step (50 per second)
const STEP_TOLERANCE := DT + 0.000001

var run: Node2D
var rack: Node
var gun: Node
var spawner: Node
var data: WeaponData
## [time, target] for every bullet fired.
var shots: Array = []
var clock := 0.0


func before_each() -> void:
	run = RunScene.instantiate()
	add_child_autofree(run)
	spawner = run.minions
	spawner.enabled = false  # no spawning or walking: the test places minions
	rack = run.weapons
	gun = rack.gun
	data = WeaponData.new()
	shots = []
	clock = 0.0
	gun.fired.connect(func(_b: Node, target: Node) -> void: shots.append([clock, target]))


func after_each() -> void:
	get_tree().paused = false


func _car_units() -> Vector2:
	return run.car.position / 16.0


## A minion `offset` units from the car that stays put; `health` overrides its health.
func _minion(offset: Vector2, health: float = -1.0) -> Node:
	var m: Node = spawner.spawn_minion_at(_car_units() + offset)
	if health > 0.0:
		m.max_health = health
		m.health = health
	return m


## Steps the weapons by hand for `seconds`, keeping the car at full health.
func _run_for(seconds: float) -> void:
	var t := 0.0
	while t < seconds - 0.000001:
		rack.step(DT)
		clock += DT
		t += DT
		run.state.health = run.state.max_health


func _assert_base_stats(g: Node) -> void:
	var base: Dictionary = data.gun_at(1)
	for key in base:
		assert_eq(g.stats[key], base[key], "base %s" % key)


func test_run_has_the_rack_with_the_gun() -> void:
	assert_not_null(rack, "run.weapons")
	assert_not_null(gun, "run.weapons.gun")
	assert_eq(gun.tier, 1, "the run starts with the gun at tier 1")
	assert_eq(rack.owned_ids(), ["gun"], "and nothing else")
	assert_eq(rack.car, run.car)
	assert_lt(rack.draw_root.get_index(), run.view_root.get_index(), "bullets drawn before the car's View")
	assert_gt(rack.draw_root.get_index(), spawner.draw_root.get_index(), "and after the minions")


func test_never_fires_without_an_enemy_in_range() -> void:
	_run_for(10.0)
	assert_eq(shots.size(), 0, "no enemies at all: no shots")
	var far: Node = _minion(Vector2(gun.stats["range"] + 0.5, 0.0))
	_run_for(10.0)
	assert_eq(shots.size(), 0, "an enemy just out of range: no shots")
	assert_eq(rack.projectiles.size(), 0)
	assert_eq(far.health, far.max_health)
	assert_gt(gun.checks, 10, "the gun kept checking")


func test_fires_at_the_data_interval_with_an_enemy_in_range() -> void:
	var interval: float = data.gun_at(1)["fire_interval"]
	assert_almost_eq(interval, 1.26, 0.000001, "T-040's data: 1.2 / 1 + 0.06")
	_minion(Vector2(6.0, 0.0), 1000.0)
	_run_for(10.0)
	assert_eq(shots.size(), int(10.0 / interval), "one shot per interval")
	assert_almost_eq(shots[0][0], interval, STEP_TOLERANCE, "the first check is one interval in")
	for i in range(1, shots.size()):
		assert_almost_eq(shots[i][0] - shots[i - 1][0], interval, STEP_TOLERANCE, "shot %d" % i)


func test_checks_only_once_per_interval() -> void:
	# An enemy that comes into range just after a check waits for the next one.
	var interval: float = data.gun_at(1)["fire_interval"]
	_run_for(interval + DT)  # one empty check done
	assert_eq(gun.checks, 1)
	_minion(Vector2(5.0, 0.0), 1000.0)
	_run_for(interval - 3.0 * DT)
	assert_eq(shots.size(), 0, "not shot before the next check")
	_run_for(3.0 * DT)
	assert_eq(shots.size(), 1, "shot at the next check")


func test_bullet_goes_for_the_closest_enemy_and_damages_it_by_the_data_amount() -> void:
	var damage: float = data.gun_at(1)["damage"]
	var far: Node = _minion(Vector2(0.0, 9.0), 100.0)
	var near: Node = _minion(Vector2(-5.0, 0.0), 100.0)
	var mid: Node = _minion(Vector2(4.0, 5.0), 100.0)
	_run_for(gun.fire_interval())
	assert_eq(shots.size(), 1)
	assert_eq(shots[0][1], near, "the closest enemy is the target")
	var bullet: Node = rack.projectiles[0]
	assert_almost_eq(bullet.direction.angle_to(Vector2.LEFT), 0.0, 0.0001, "aimed straight at it")
	_run_for(1.0)  # 5 units at 15 units/s
	assert_eq(near.health, 100.0 - damage, "hit for the data's damage (2)")
	assert_eq(mid.health, 100.0, "the others untouched")
	assert_eq(far.health, 100.0)
	assert_eq(rack.projectiles.size(), 0, "the bullet is gone after its hit")


func test_bullets_kill_a_minion_through_take_damage() -> void:
	var m: Node = _minion(Vector2(6.0, 0.0))  # the data's health (4)
	watch_signals(m)
	var damage: float = data.gun_at(1)["damage"]
	var hits_needed := int(ceil(m.max_health / damage))
	_run_for(gun.fire_interval() * hits_needed + 1.0)
	assert_signal_emit_count(m, "died", 1, "dies after %d hits" % hits_needed)
	assert_true(m.is_dead())


func test_bullet_flies_at_the_data_speed_from_the_car_centre() -> void:
	var speed: float = data.gun_at(1)["bullet_speed"]
	_minion(Vector2(0.0, -11.0), 100.0)
	_run_for(gun.fire_interval())
	var b: Node = rack.projectiles[0]
	var start: Vector2 = b.units
	assert_almost_eq(start.distance_to(_car_units()), 0.0, 0.0001, "fired from the car's centre")
	_run_for(0.2)
	assert_almost_eq(b.units.distance_to(start), speed * 0.2, 0.001, "15 units per second")


func test_bullet_hits_within_its_hit_radius() -> void:
	# The bullet's hit circle (1 unit) plus the minion's body (0.5): a minion
	# beside the bullet's line, 1.4 units off it, is hit.
	gun.fire_clock = -100.0  # no volley of its own: one bullet aimed by hand along +x
	var target: Node = _minion(Vector2(8.0, 0.0), 100.0)
	var beside: Node = _minion(Vector2(4.0, 1.4), 100.0)
	var missed: Node = _minion(Vector2(2.0, -1.6), 100.0)
	gun.fire_at(_car_units() + Vector2(8.0, 0.0), target)
	_run_for(0.3)
	assert_eq(beside.health, 100.0 - float(data.gun_at(1)["damage"]), "hit 1.4 units off the line")
	assert_eq(target.health, 100.0, "the bullet stopped at the first hit")
	assert_eq(missed.health, 100.0, "1.6 units off the line: missed")


func test_a_bullet_that_misses_is_removed_past_the_range() -> void:
	var b: Node = gun.fire_at(_car_units() + Vector2(1.0, 0.0))
	var reach: float = data.gun_at(1)["missed_bullet_max_travel"]
	var steps_to_range := int(reach / (float(data.gun_at(1)["bullet_speed"]) * DT))
	for i in steps_to_range - 1:
		rack.step(DT)
	assert_true(rack.projectiles.has(b), "still flying inside the range")
	for i in 3:
		rack.step(DT)
	assert_false(rack.projectiles.has(b), "removed once past the range")


func test_volley_goes_round_the_enemies_closest_first() -> void:
	gun.set_tier(2)  # 3 bullets
	var near: Node = _minion(Vector2(3.0, 0.0), 100.0)
	var second: Node = _minion(Vector2(0.0, -7.0), 100.0)
	_run_for(gun.fire_interval() + 0.2)
	assert_eq(shots.size(), 3)
	assert_eq(shots[0][1], near, "bullet 1: closest")
	assert_eq(shots[1][1], second, "bullet 2: second closest")
	assert_eq(shots[2][1], near, "bullet 3: closest again")
	var gap: float = data.gun_at(2)["delay_between_bullets"]
	assert_almost_eq(shots[1][0] - shots[0][0], gap, STEP_TOLERANCE, "0.05 s apart")
	assert_almost_eq(shots[2][0] - shots[1][0], gap, STEP_TOLERANCE)


func test_every_tier_applies_the_data_values() -> void:
	for t in range(1, data.max_tier() + 1):
		gun.set_tier(t)
		var want: Dictionary = data.gun_at(t)
		for key in want:
			assert_eq(gun.stats[key], want[key], "tier %d %s" % [t, key])
	assert_false(gun.upgrade(), "no upgrade past the last tier")
	assert_eq(gun.tier, data.max_tier())


func test_upgrade_steps_through_the_tiers() -> void:
	for t in range(2, data.max_tier() + 1):
		assert_true(rack.upgrade("gun"), "upgrade to tier %d" % t)
		assert_eq(gun.tier, t)
	assert_false(rack.upgrade("gun"))
	assert_false(rack.upgrade("no_such_weapon"))


func test_tier_2_and_6_fire_more_bullets() -> void:
	_minion(Vector2(4.0, 0.0), 1000.0)
	for t in [2, 6]:
		gun.set_tier(t)
		shots.clear()
		gun.fire_clock = 0.0
		_run_for(gun.fire_interval() + 0.4)
		assert_eq(shots.size(), int(data.gun_at(t)["bullets"]), "tier %d bullets per volley" % t)


func test_fire_rate_tiers_shorten_the_interval() -> void:
	_minion(Vector2(4.0, 0.0), 100000.0)
	for t in [3, 4, 7]:
		gun.set_tier(t)
		shots.clear()
		gun.fire_clock = 0.0
		_run_for(4.0 * gun.fire_interval() + 0.3)
		var want: float = data.gun_at(t)["fire_interval"]
		assert_lt(want, data.gun_at(t - 1)["fire_interval"], "tier %d is faster" % t)
		var bullets: int = data.gun_at(t)["bullets"]
		# First bullet of each volley, `bullets` shots apart.
		var first: float = shots[0][0]
		var second: float = shots[bullets][0]
		assert_almost_eq(second - first, want, STEP_TOLERANCE, "tier %d interval" % t)


func test_reach_tier_widens_the_range() -> void:
	var at_15: Node = _minion(Vector2(15.0, 0.0), 100.0)
	gun.set_tier(4)
	_run_for(3.0)
	assert_eq(shots.size(), 0, "tier 4: 15 units is out of range (12)")
	gun.set_tier(5)
	_run_for(gun.fire_interval())
	assert_gt(shots.size(), 0, "tier 5: in range (18)")
	assert_eq(shots[0][1], at_15)


func test_pierce_tier_hits_two_enemies_in_line() -> void:
	gun.set_tier(7)
	var first: Node = _minion(Vector2(4.0, 0.0), 100.0)
	var second: Node = _minion(Vector2(7.0, 0.0), 100.0)
	var behind: Node = _minion(Vector2(10.0, 0.0), 100.0)
	gun.fire_at(_car_units() + Vector2(10.0, 0.0))
	gun.fire_clock = -100.0
	_run_for(1.0)
	assert_eq(first.health, 98.0, "tier 7: hits the first")
	assert_eq(second.health, 100.0, "and stops")
	gun.set_tier(8)
	gun.fire_at(_car_units() + Vector2(10.0, 0.0))
	gun.fire_clock = -100.0
	_run_for(1.0)
	assert_eq(first.health, 96.0, "tier 8: hits the first")
	assert_eq(second.health, 98.0, "passes through to the second")
	assert_eq(behind.health, 100.0, "and is gone after the second")


func test_new_run_starts_with_the_base_gun() -> void:
	_minion(Vector2(4.0, 0.0), 1000.0)
	gun.set_tier(6)
	_run_for(gun.fire_interval() + 0.1)
	assert_gt(rack.projectiles.size(), 0)
	run.start_run()
	assert_eq(rack.gun, gun, "the same gun node")
	assert_eq(gun.tier, 1, "tier 1 again")
	_assert_base_stats(gun)
	assert_eq(rack.owned_ids(), ["gun"], "only the gun")
	assert_eq(rack.projectiles.size(), 0, "no bullets left over")
	assert_eq(gun.fire_clock, 0.0, "the timer starts again")
	assert_eq(rack.car, run.car, "follows the new car")


func test_new_run_from_the_main_menu_starts_with_the_base_gun() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()
	await wait_process_frames(2)
	var g: Node = game.run.weapons.gun
	assert_eq(g.tier, 1)
	g.set_tier(8)
	game.run.start_run()
	assert_eq(game.run.weapons.gun.tier, 1, "a new run resets the upgrades")
	_assert_base_stats(game.run.weapons.gun)


func test_targets_any_damageable_enemy_in_the_group() -> void:
	# The kaiju (T-045) joins the group "enemies" with take_damage(); the gun
	# finds it without knowing about it. A stand-in:
	var big := FakeEnemy.new()
	big.units = _car_units() + Vector2(0.0, 6.0)
	run.add_child(big)
	big.add_to_group("enemies")
	_run_for(gun.fire_interval() + 0.6)
	assert_eq(shots.size(), 1)
	assert_eq(shots[0][1], big)
	assert_eq(big.damage_taken, float(data.gun_at(1)["damage"]))
	big.queue_free()


func test_nothing_fires_while_paused_or_after_the_run_ends() -> void:
	_minion(Vector2(4.0, 0.0), 1000.0)
	await wait_physics_frames(2)
	get_tree().paused = true
	var before: int = gun.checks
	await wait_physics_frames(int(2.0 / DT))
	assert_eq(gun.checks, before, "paused: the gun's clock stands still")
	get_tree().paused = false
	run.state.time_left = 0.0001
	run.state.advance(1.0)
	assert_false(run.state.is_running())
	_run_for(5.0)
	assert_eq(shots.size(), 0, "nothing after the run ends")


func test_placeholder_bullet_avoids_redgull_red() -> void:
	const BulletScript := preload("res://scripts/weapons/bullet.gd")
	for c in [BulletScript.CORE_COLOR, BulletScript.GLOW_COLOR, BulletScript.OUTLINE_COLOR]:
		var reddish: bool = c.r > 0.5 and c.g < 0.35 and c.b < 0.35
		assert_false(reddish, "%s is not red" % c)


class FakeEnemy:
	extends Node2D
	var units := Vector2.ZERO
	var damage_taken := 0.0

	func position_units() -> Vector2:
		return units

	func hit_radius_units() -> float:
		return 2.0

	func take_damage(amount: float) -> void:
		damage_taken += amount
