extends GutTest
## Task T-041: the starting gun. It fires only with an enemy in range, at the
## data's interval; its bullets go for the closest enemy (T-408: the volley's
## targets, 1 below tier 6, then 3 and 5) and damage by the data's amount; every upgrade tier takes effect;
## a new run starts with the base gun; the weapon rack's plumbing.

const RunScene := preload("res://scenes/run/run.tscn")
## T-042's playtest switch would give the flamethrower too; these tests run the game's rule.
const FlameScript := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
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
	FlameScript.playtest_override = 0
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
	FlameScript.playtest_override = -1
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
	assert_eq(near.health, 100.0 - damage, "hit for the data's damage (4)")
	assert_eq(mid.health, 100.0, "the others untouched")
	assert_eq(far.health, 100.0)
	assert_eq(rack.projectiles.size(), 0, "the bullet is gone after its hit")


## T-170: of the weapons only the wiper pushes; the gun's bullets never move an
## enemy (Weapons, Decisions), a real minion or one recording every push.
func test_bullets_never_move_an_enemy() -> void:
	var real: Node = _minion(Vector2(-5.0, 0.0), 100.0)
	var fake: Node2D = preload("res://tests/fixtures/weapons/fake_minion.gd").new()
	fake.position = (_car_units() + Vector2(5.0, 0.5)) * 16.0
	run.add_child(fake)
	var real_at: Vector2 = real.position
	var fake_at: Vector2 = fake.position
	gun.set_tier(6)  # 3 bullets a volley over up to 3 targets: both are shot at
	_run_for(gun.fire_interval() * 3 + 1.0)
	assert_lt(real.health, 100.0, "the real minion was hit")
	assert_gt(fake.damage_taken.size(), 0, "the recording one was hit")
	assert_false(real.is_knocked_back(), "no push on the real minion")
	assert_eq(real.position, real_at, "the real minion did not move")
	assert_eq(fake.pushes, [], "no knockback call")
	assert_eq(fake.position, fake_at, "did not move")


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
	# The bullet's hit circle (1 unit) plus the minion's body (1.0 since T-379):
	# a minion beside the bullet's line, 1.4 units off it, is hit.
	gun.fire_clock = -100.0  # no volley of its own: one bullet aimed by hand along +x
	var target: Node = _minion(Vector2(8.0, 0.0), 100.0)
	var beside: Node = _minion(Vector2(4.0, 1.4), 100.0)
	var missed: Node = _minion(Vector2(2.0, -2.1), 100.0)
	gun.fire_at(_car_units() + Vector2(8.0, 0.0), target)
	_run_for(0.3)
	assert_eq(beside.health, 100.0 - float(data.gun_at(1)["damage"]), "hit 1.4 units off the line")
	assert_eq(target.health, 100.0, "the bullet stopped at the first hit")
	assert_eq(missed.health, 100.0, "2.1 units off the line: missed")


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


## T-408: tier 1's bullet damage is at least a minion's health: one bullet, one kill.
func test_tier_1_one_bullet_kills_a_minion() -> void:
	var m: Node = _minion(Vector2(5.0, 0.0))  # the data's health
	assert_gte(float(gun.stats["damage"]), m.max_health, "damage >= a minion's health")
	watch_signals(m)
	_run_for(gun.fire_interval())
	assert_eq(shots.size(), 1, "one bullet fired")
	_run_for(0.5)  # 5 units at 15 units/s
	assert_signal_emit_count(m, "died", 1, "killed by that one bullet")


## Below tier 6 the whole volley goes at the closest enemy, delay_between_bullets apart.
func test_below_tier_6_the_volley_aims_at_the_closest_only() -> void:
	gun.set_tier(3)  # 3 bullets, 1 target
	var near: Node = _minion(Vector2(3.0, 0.0), 100.0)
	var second: Node = _minion(Vector2(0.0, -7.0), 100.0)
	_run_for(gun.fire_interval() + 0.2)
	assert_eq(shots.size(), 3)
	for i in 3:
		assert_eq(shots[i][1], near, "bullet %d: the closest" % (i + 1))
	var gap: float = data.gun_at(3)["delay_between_bullets"]
	assert_almost_eq(shots[1][0] - shots[0][0], gap, STEP_TOLERANCE, "0.05 s apart")
	assert_almost_eq(shots[2][0] - shots[1][0], gap, STEP_TOLERANCE)
	assert_eq(second.health, 100.0, "the second closest untouched")


## Below tier 6, a target that dies mid-volley: the rest go at the closest living enemy.
func test_below_tier_6_a_dead_target_passes_the_rest_to_the_next_closest() -> void:
	gun.set_tier(3)
	var near: Node = _minion(Vector2(3.0, 0.0), 100.0)
	var second: Node = _minion(Vector2(0.0, -7.0), 100.0)
	var third: Node = _minion(Vector2(9.0, 0.0), 100.0)
	_run_for(gun.fire_interval())
	assert_eq(shots.size(), 1)
	near.take_damage(1000.0)  # dies before bullet 2 leaves
	_run_for(0.2)
	assert_eq(shots.size(), 3)
	assert_eq(shots[0][1], near)
	assert_eq(shots[1][1], second, "bullet 2: the closest living one")
	assert_eq(shots[2][1], second, "bullet 3 too")
	assert_eq(third.health, 100.0, "the farther one untouched")


## Below tier 6, a target the bullets in flight will already kill is skipped: with one-shot
## minions each bullet of the volley goes to the next closest, so +1 bullet counts.
func test_below_tier_6_bullets_skip_a_minion_already_doomed() -> void:
	gun.set_tier(3)  # 3 bullets, 1 target
	var near: Node = _minion(Vector2(3.0, 0.0))  # the data's health: one bullet kills
	var second: Node = _minion(Vector2(0.0, -6.0))
	var third: Node = _minion(Vector2(-9.0, 0.0))
	watch_signals(near)
	watch_signals(second)
	watch_signals(third)
	_run_for(gun.fire_interval() + 0.2)
	assert_eq(shots.map(func(x): return x[1]), [near, second, third], "one bullet each, closest first")
	_run_for(1.0)
	assert_signal_emit_count(near, "died", 1)
	assert_signal_emit_count(second, "died", 1)
	assert_signal_emit_count(third, "died", 1)
	assert_eq(gun.is_doomed(near), false, "a dead enemy is not counted as doomed")


## A tough enemy (the kaiju's case) is not doomed by one bullet: the volley stays on it.
func test_below_tier_6_a_tough_target_keeps_the_whole_volley() -> void:
	gun.set_tier(3)
	var tough: Node = _minion(Vector2(3.0, 0.0), 100.0)
	_minion(Vector2(0.0, -6.0))
	_run_for(gun.fire_interval() + 0.2)
	assert_eq(shots.map(func(x): return x[1]), [tough, tough, tough])


## From tier 6 a volley aims at the 3 closest at once; tier 7's 4th bullet goes round to the closest.
func test_from_tier_6_the_volley_spreads_over_up_to_3_at_once() -> void:
	var a: Node = _minion(Vector2(2.0, 0.0), 1000.0)
	var b: Node = _minion(Vector2(0.0, 4.0), 1000.0)
	var c: Node = _minion(Vector2(-6.0, 0.0), 1000.0)
	var d: Node = _minion(Vector2(0.0, -9.0), 1000.0)
	gun.set_tier(6)
	_run_for(gun.fire_interval())
	assert_eq(shots.map(func(x): return x[1]), [a, b, c], "the 3 closest, closest first")
	assert_eq(shots[2][0], shots[0][0], "fired at the same moment")
	gun.set_tier(7)
	shots.clear()
	gun.fire_clock = 0.0
	_run_for(gun.fire_interval())
	assert_eq(shots.map(func(x): return x[1]), [a, b, c, a], "4 bullets round the 3 targets")
	assert_false(shots.any(func(x): return x[1] == d), "the 4th closest is never aimed at")


func test_from_tier_6_one_enemy_takes_the_whole_volley_at_once() -> void:
	var only: Node = _minion(Vector2(4.0, 0.0), 1000.0)
	gun.set_tier(6)
	_run_for(gun.fire_interval())
	assert_eq(shots.size(), 3)
	for x in shots:
		assert_eq(x[1], only)
		assert_eq(x[0], shots[0][0])


## Tier 11: up to 5 targets, one bullet each, all at once.
func test_tier_11_spreads_over_up_to_5() -> void:
	var ms := []
	for i in 6:
		ms.append(_minion(Vector2(2.0 + i * 1.5, float(i % 2)), 1000.0))
	gun.set_tier(11)
	_run_for(gun.fire_interval())
	assert_eq(shots.map(func(x): return x[1]), ms.slice(0, 5), "the 5 closest, one bullet each")
	assert_eq(shots[4][0], shots[0][0], "fired at the same moment")


## T-422's data guard: a volley of 0 bullets is no volley, not an empty queue.
func test_no_bullets_fires_nothing() -> void:
	_minion(Vector2(4.0, 0.0), 1000.0)
	gun.stats["bullets"] = 0
	_run_for(gun.fire_interval() * 2)
	assert_eq(shots.size(), 0)
	assert_eq(gun.volleys, 0)


func test_every_tier_applies_the_data_values() -> void:
	assert_eq(gun.max_tier(), 11, "the gun's own last tier")
	assert_eq(gun.max_tier(), data.max_tier("gun"))
	for t in range(1, gun.max_tier() + 1):
		gun.set_tier(t)
		var want: Dictionary = data.gun_at(t)
		for key in want:
			assert_eq(gun.stats[key], want[key], "tier %d %s" % [t, key])
	assert_false(gun.upgrade(), "no upgrade past the last tier")
	assert_eq(gun.tier, 11)


func test_upgrade_steps_through_the_tiers() -> void:
	for t in range(2, 12):
		assert_true(rack.upgrade("gun"), "upgrade to tier %d" % t)
		assert_eq(gun.tier, t)
	assert_false(rack.upgrade("gun"))
	assert_false(rack.upgrade("no_such_weapon"))


func test_level_ups_offer_the_gun_up_to_tier_11() -> void:
	gun.set_tier(10)
	assert_true(rack.offers.available_offers().has("upgrade_gun"), "tier 10: offered")
	gun.set_tier(11)
	assert_false(rack.offers.available_offers().has("upgrade_gun"), "tier 11: the last")


func test_bullet_tiers_add_one_bullet() -> void:
	_minion(Vector2(4.0, 0.0), 100000.0)
	for t in [2, 3, 7, 8]:
		gun.set_tier(t)
		shots.clear()
		gun.fire_clock = 0.0
		_run_for(gun.fire_interval() + 0.4)
		assert_eq(shots.size(), int(data.gun_at(t)["bullets"]), "tier %d bullets per volley" % t)
		assert_eq(shots.size(), int(data.gun_at(t - 1)["bullets"]) + 1, "tier %d: +1 bullet" % t)


func test_fire_rate_tiers_shorten_the_interval() -> void:
	_minion(Vector2(4.0, 0.0), 100000.0)
	for t in [4, 5, 9, 10]:
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


func test_range_stays_12_at_every_tier() -> void:
	var at_13: Node = _minion(Vector2(13.0, 0.0), 100.0)
	gun.set_tier(11)
	_run_for(3.0)
	assert_eq(shots.size(), 0, "tier 11: 13 units is still out of range (12)")
	assert_eq(at_13.health, 100.0)


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


func test_bullet_art_is_opaque_and_avoids_heart_red() -> void:
	const BulletScript := preload("res://scripts/weapons/bullet.gd")
	var img: Image = BulletScript.ART.get_image()
	assert_eq(img.get_width(), BulletScript.ART_FRAME * BulletScript.ART_FRAMES, "two pulse frames side by side")
	assert_eq(img.get_height(), BulletScript.ART_FRAME)
	var opaque := 0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			assert_true(c.a == 0.0 or c.a == 1.0, "no see-through pixels")
			if c.a == 1.0:
				opaque += 1
				assert_false(c.r > 0.5 and c.g < 0.35 and c.b < 0.35, "%s is not red" % c)
	assert_gt(opaque, 60, "the bullet is drawn")


func test_bullet_pulses_between_its_two_frames_as_it_flies() -> void:
	const BulletScript := preload("res://scripts/weapons/bullet.gd")
	var b = BulletScript.new()
	add_child_autofree(b)
	b.setup(null, Vector2.ZERO, Vector2.RIGHT, {"bullet_speed": 15.0, "damage": 1.0, "bullet_hit_radius": 1.0,
		"pierce_hits": 0, "missed_bullet_max_travel": 50.0})
	assert_eq(b.frame, 0)
	b.step(0.03)  # 0.45 units flown
	assert_eq(b.frame, 1, "the second frame after a pulse's length")
	b.step(0.03)
	assert_eq(b.frame, 0, "and back")


class FakeEnemy:
	extends Node2D
	var units := Vector2.ZERO
	var damage_taken := 0.0

	func position_units() -> Vector2:
		return units

	func hit_radius_units() -> float:
		return 2.0

	func take_damage(amount: float, _source := "") -> void:
		damage_taken += amount
