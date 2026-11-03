extends GutTest
## Task T-414: weapons during the wreck (Weapons, Decisions, "Weapons during the
## wreck"): molotov fires, burning enemies and the underglow keep going, Bricks go
## off on a landing, and the gun, molotov throws, wiper and exhaust flamethrower
## fire nothing new. Once the run is over a later weapon in the same step does
## nothing. Molotovs never land in a building or off the map ("Molotovs land
## where enemies can be").

const RunScene := preload("res://scenes/run/run.tscn")
const FakeEnemy := preload("res://tests/fixtures/weapons/fake_enemy.gd")
const Bricks := preload("res://scripts/weapons/bricks.gd")
const Wiper := preload("res://scripts/weapons/windshield_wiper.gd")
const Flame := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const Glow := preload("res://scripts/weapons/neon_underglow.gd")
const Molotovs := preload("res://scripts/weapons/molotovs.gd")
const ShortPlatforms := preload("res://scripts/level/short_platforms.gd")
const DT := 0.02

var run: Node2D
var rack: Node


func before_each() -> void:
	for s in [Bricks, Wiper, Flame, Glow, Molotovs]:
		s.playtest_override = 0
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	run.car.use_keyboard = false
	run.car.scripted_input = [false, false, 0.0]
	rack = run.weapons


func after_each() -> void:
	for s in [Bricks, Wiper, Flame, Glow, Molotovs]:
		s.playtest_override = -1
	get_tree().paused = false


func _enemy(units: Vector2) -> Node2D:
	var e: Node2D = FakeEnemy.new()
	e.position = units * 16.0
	run.add_child(e)
	return e


func _car() -> Vector2:
	return run.car.model.get_position()


func _wreck() -> void:
	run.state.health = 1.0
	run.state.damage_car(1.0)
	assert_true(run.state.is_wrecked(), "the car is wrecked")
	assert_false(run.state.is_running())


func test_a_molotov_fire_keeps_damaging_during_the_wreck() -> void:
	rack.gun.set_tier(0)
	rack.upgrade("molotov")
	var e := _enemy(_car() + Vector2(2, 0))
	rack.molotov.land(_car() + Vector2(2, 0))
	_wreck()
	for i in 100:
		rack.step(DT)
	assert_gt(e.total_damage(), 0.0, "the fire damaged the enemy while wrecked")
	assert_eq(rack.molotov.throws, 0, "nothing thrown")


func test_the_underglow_keeps_ticking_during_the_wreck() -> void:
	rack.gun.set_tier(0)
	rack.upgrade("underglow")
	var e := _enemy(_car() + Vector2(1, 0))
	_wreck()
	for i in 100:
		rack.step(DT)
	assert_gt(e.total_damage(), 0.0)


func test_bricks_go_off_when_the_wrecked_car_lands() -> void:
	rack.gun.set_tier(0)
	rack.upgrade("bricks")
	var e := _enemy(_car() + Vector2(1, 0))
	run.car.height_model.airborne = true
	for i in 40:
		rack.step(DT)
	_wreck()
	for i in 40:
		rack.step(DT)
	assert_eq(e.total_damage(), 0.0, "still in the air")
	run.car.height_model.airborne = false
	rack.step(DT)
	assert_eq(rack.bricks.waves, 1, "a wave on the landing")
	assert_gt(e.total_damage(), 0.0)


func test_the_gun_fires_nothing_during_the_wreck() -> void:
	var e := _enemy(_car() + Vector2(3, 0))
	_wreck()
	for i in 100:
		rack.step(DT)
	assert_eq(rack.gun.volleys, 0)
	assert_eq(rack.projectiles.size(), 0)
	assert_eq(e.total_damage(), 0.0)


func test_no_molotov_is_thrown_during_the_wreck() -> void:
	rack.gun.set_tier(0)
	rack.upgrade("molotov")
	_wreck()
	for i in 400:
		rack.step(DT)
	assert_eq(rack.molotov.throws, 0)
	assert_eq(rack.molotov.bottles, 0)


func test_the_wiper_and_the_flamethrower_do_nothing_new_during_the_wreck() -> void:
	rack.gun.set_tier(0)
	rack.upgrade("wiper")
	rack.upgrade("flamethrower")
	var e := _enemy(_car() + Vector2(1, 0))
	run.car.model.is_drifting = true
	_wreck()
	for i in 100:
		rack.step(DT)
	assert_eq(e.total_damage(), 0.0, "neither hit anything")
	assert_false(rack.flamethrower.is_burning(e))


func test_a_burn_tint_on_an_enemy_runs_out_during_the_wreck() -> void:
	rack.gun.set_tier(0)
	rack.upgrade("flamethrower")
	var e := _enemy(_car() + Vector2(1, 0))
	rack.flamethrower._start_burn(e)
	assert_true(rack.flamethrower.is_burning(e))
	_wreck()
	for i in 200:
		rack.step(DT)
	assert_false(rack.flamethrower.is_burning(e), "the burn ended")


## T-497: the burn already on an enemy keeps hurting it during the wreck (afterburn).
func test_a_burning_enemy_keeps_taking_damage_during_the_wreck() -> void:
	rack.gun.set_tier(0)
	rack.upgrade("flamethrower")
	rack.flamethrower.stats["burn_flash_seconds"] = 1.0
	var e := _enemy(_car() + Vector2(1, 0))
	rack.flamethrower._start_burn(e)
	_wreck()
	for i in 200:
		rack.step(DT)
	assert_eq(e.damage_taken.size(), 5, "one hit every 0.2 s for its 1 s burn, then none")
	assert_false(rack.flamethrower.is_burning(e))


func test_bullets_in_flight_keep_moving_during_the_wreck() -> void:
	rack.upgrade("gun")
	var e := _enemy(_car() + Vector2(6, 0))
	rack.gun.fire_at(e.position_units(), e)
	var b = rack.projectiles[0]
	var before: Vector2 = b.position
	_wreck()
	rack.step(DT)
	assert_ne(b.position, before, "the bullet moved")


func test_after_the_run_ends_no_later_weapon_damages_in_the_same_step() -> void:
	rack.gun.set_tier(0)
	rack.upgrade("underglow")
	var e := _enemy(_car() + Vector2(1, 0))
	# An earlier weapon in the step ends the run (a kaiju kill).
	var ender: Node = autofree(EndsRun.new())
	ender.state = run.state
	ender.rack = rack
	rack.weapons = {"a": ender, "b": rack.underglow}
	rack.step(DT)
	assert_true(ender.stepped)
	assert_false(run.state.is_running())
	assert_eq(e.total_damage(), 0.0, "the underglow after it did nothing")


func test_a_projectile_after_the_run_ends_does_nothing() -> void:
	var a: Node2D = autofree(Marker.new())
	var b: Node2D = autofree(Marker.new())
	a.on_step = func() -> void: run.state.kaiju_killed()
	rack.projectiles = [a, b]
	rack.step(DT)
	assert_eq(a.steps, 1)
	assert_eq(b.steps, 0, "the second projectile did not step")


func test_molotovs_never_land_in_a_building_or_off_the_map() -> void:
	rack.gun.set_tier(0)
	rack.upgrade("molotov")
	var m = rack.molotov
	m.rng.seed = 7
	var map = run.map
	var area: Rect2 = map.rect_of(map.layout.map.rect)
	var bad := 0
	for i in 1000:
		var spot: Vector2 = m.random_landing()
		if not area.has_point(spot):
			bad += 1
			continue
		for bd in map.layout.buildings:
			if ShortPlatforms.is_platform_entry(bd):
				continue
			if map.rect_of(bd).has_point(spot):
				bad += 1
				break
	assert_eq(bad, 0, "spots in a building or off the map")


func test_a_landing_inside_a_building_is_rejected_and_a_platform_is_accepted() -> void:
	var m = rack.molotov
	var map = run.map
	var solid = null
	for bd in map.layout.buildings:
		if not ShortPlatforms.is_platform_entry(bd):
			solid = bd
			break
	if solid != null:
		assert_false(m.is_valid_landing(map.rect_of(solid).get_center()))
	assert_false(m.is_valid_landing(Vector2(-100000, -100000)), "off the map")


class EndsRun:
	extends Node
	var state: Node
	var rack: Node
	var stepped := false
	var tier := 1
	func is_owned() -> bool:
		return true
	func step(_dt: float) -> void:
		stepped = true
		state.kaiju_killed()
	func step_wrecked(_dt: float) -> void:
		pass


class Marker:
	extends Node2D
	var steps := 0
	var on_step = null
	func step(_dt: float) -> void:
		steps += 1
		if on_step != null:
			on_step.call()
	func is_done() -> bool:
		return false
