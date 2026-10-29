extends GutTest
## Task T-326: weapons hit only enemies on their own height level (Weapons,
## Decisions, "Weapons hit only enemies on the car's own level"). For each of
## the six weapons, one enemy on the hit's level and one on another level, both
## within reach: only the one on the level is damaged (and, for the wiper and
## Bricks, pushed). A molotov's fire burns on its own level, wherever the car
## is. The starting gun neither aims at nor hits an enemy on another level. The
## proposals: a ramp's in-between heights within LEVEL_TOLERANCE count, the
## kaiju is on every level, in the air the level under the car counts. A map
## without heights (the MVP map) hits every enemy as before.
##
## The car's map here is a test ground (a GroundHeight): a rooftop of height 3
## round the car, the street (0) beyond it. The test minions report their own
## height (fake_level_minion.gd); the last test uses the real elevation map and
## real minions.

const RunScene := preload("res://scenes/run/run.tscn")
const LevelMinion := preload("res://tests/fixtures/weapons/fake_level_minion.gd")
const FakeEnemy := preload("res://tests/fixtures/weapons/fake_enemy.gd")
const Bricks := preload("res://scripts/weapons/bricks.gd")
const Wiper := preload("res://scripts/weapons/windshield_wiper.gd")
const Flame := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const Glow := preload("res://scripts/weapons/neon_underglow.gd")
const Molotovs := preload("res://scripts/weapons/molotovs.gd")
const DT := 0.02
const ROOF := 3.0

var run: Node2D
var rack: Node
## The test ground's rooftop, centred on the car's start (flat world, units).
var roof_rect: Rect2


func before_each() -> void:
	for s in [Bricks, Wiper, Flame, Glow, Molotovs]:
		s.playtest_override = 0
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	run.car.use_keyboard = false
	run.car.scripted_input = [false, false, 0.0]
	rack = run.weapons
	rack.gun.set_tier(0)  # each test gives the weapon it checks
	var c: Vector2 = run.car.model.get_position()
	roof_rect = Rect2(c - Vector2(10.0, 10.0), Vector2(20.0, 20.0))
	var g := GroundHeight.new()
	g.load_data({"platforms": [{"id": "roof", "x": roof_rect.position.x, "y": roof_rect.position.y,
		"w": roof_rect.size.x, "h": roof_rect.size.y, "height": ROOF}]})
	run.car.ground = g  # the car stands on the rooftop


func after_each() -> void:
	for s in [Bricks, Wiper, Flame, Glow, Molotovs]:
		s.playtest_override = -1
	get_tree().paused = false


func _car() -> Vector2:
	return run.car.model.get_position()


## A test minion at `units` whose body is at `height`.
func _minion(units: Vector2, height: float) -> Node2D:
	var m: Node2D = LevelMinion.new()
	m.level_height = height
	m.position = units * 16.0
	run.add_child(m)
	return m


func _step(steps: int) -> void:
	for i in steps:
		rack.step(DT)


# --- The rack's rule ---------------------------------------------------------------

func test_the_cars_level_is_the_ground_under_it() -> void:
	assert_almost_eq(run.car.height, ROOF, 1e-6, "the car stands on the test rooftop")
	assert_almost_eq(rack.car_level(), ROOF, 1e-6)
	assert_almost_eq(rack.level_at(roof_rect.end + Vector2(5.0, 5.0)), 0.0, 1e-6, "the street")


func test_a_level_counts_enemies_within_the_tolerance_and_the_kaiju_everywhere() -> void:
	assert_eq(rack.LEVEL_TOLERANCE, 1.5, "the proposal")
	var same := _minion(_car(), ROOF)
	var ramp_near := _minion(_car(), ROOF - 1.4)  # part way up a ramp
	var ramp_far := _minion(_car(), ROOF - 1.6)
	var street := _minion(_car(), 0.0)
	var high := _minion(_car(), 6.0)
	var kaiju := _minion(_car(), 0.0)
	kaiju.as_kaiju(3.0)
	var no_height := FakeEnemy.new()
	run.add_child(no_height)
	var on: Array = rack.enemies_at_car_level()
	for e in [same, ramp_near, kaiju, no_height]:
		assert_true(e in on, "%s on the car's level" % e.name)
	for e in [ramp_far, street, high]:
		assert_false(e in on, "%s on another level" % e.name)
	assert_eq(rack.enemies_at_level(NAN).size(), rack.living_enemies().size(), "no level: every enemy")


func test_in_the_air_the_level_under_the_car_counts() -> void:
	run.car.height_model.height = ROOF + 5.0
	run.car.height_model.airborne = true
	assert_almost_eq(rack.car_level(), ROOF, 1e-6, "the rooftop under the car")
	rack.upgrade("underglow")
	var on_roof := _minion(_car() + Vector2(1.0, 0.0), ROOF)
	var street := _minion(_car() + Vector2(-1.0, 0.0), 0.0)
	_step(1)
	assert_eq(on_roof.damage_taken.size(), 1, "the level under the car is hit while in the air")
	assert_eq(street.damage_taken.size(), 0)
	run.car.height_model.airborne = false


func test_without_a_ground_every_enemy_is_hit_as_before() -> void:
	run.car.ground = null  # a map without heights (the MVP map)
	assert_true(is_nan(rack.car_level()))
	rack.upgrade("underglow")
	var a := _minion(_car() + Vector2(1.0, 0.0), 0.0)
	var b := _minion(_car() + Vector2(-1.0, 0.0), 6.0)
	_step(1)
	assert_eq(a.damage_taken.size(), 1)
	assert_eq(b.damage_taken.size(), 1, "every height is hit with no ground")


# --- Each weapon ---------------------------------------------------------------------

func test_the_starting_gun_never_fires_at_an_enemy_on_another_level() -> void:
	rack.gun.set_tier(1)
	var below := _minion(_car() + Vector2(5.0, 0.0), 0.0)
	rack.gun.fire_clock = rack.gun.fire_interval()
	_step(150)
	assert_eq(rack.gun.volleys, 0, "no volley at an enemy on another level")
	assert_eq(below.damage_taken.size(), 0)


func test_the_starting_gun_hits_its_level_and_flies_past_another() -> void:
	rack.gun.set_tier(1)
	var target := _minion(_car() + Vector2(8.0, 0.0), ROOF)
	var in_the_way := _minion(_car() + Vector2(4.0, 0.0), 0.0)  # on the bullet's line, below
	rack.gun.fire_clock = rack.gun.fire_interval()
	_step(60)
	assert_eq(rack.gun.volleys, 1)
	assert_eq(in_the_way.damage_taken.size(), 0, "the bullet flies past the enemy on another level")
	assert_gt(target.damage_taken.size(), 0, "and hits the one on its level")


func test_the_flamethrower_burns_only_its_level() -> void:
	rack.upgrade("flamethrower")
	var flame = rack.flamethrower
	var behind := _car() + Vector2(0.0, Flame.EXHAUST_OFFSET_UNITS + 0.3)
	var same := _minion(behind, ROOF)
	var other := _minion(behind, 0.0)
	run.car.model.is_drifting = true
	run.car.model.vx = 5.0
	run.car.model.vy = 0.0
	flame.step(DT)
	assert_eq(same.damage_taken.size(), 1, "the enemy on the car's level burns")
	assert_eq(other.damage_taken.size(), 0, "the one on another level does not")


func test_the_underglow_hits_only_its_level() -> void:
	rack.upgrade("underglow")
	var same := _minion(_car() + Vector2(1.0, 0.0), ROOF)
	var other := _minion(_car() + Vector2(0.0, 1.0), 0.0)
	_step(60)
	assert_gt(same.damage_taken.size(), 1)
	assert_eq(other.damage_taken.size(), 0)


func test_the_wiper_hits_and_pushes_only_its_level() -> void:
	rack.upgrade("wiper")
	var wiper = rack.wiper
	var at: Vector2 = wiper.pivot_units() + wiper.forward() * 1.2
	var same := _minion(at, ROOF)
	var other := _minion(at, 0.0)
	var pass_s: float = float(wiper.stats["sweep_arc_degrees"]) / float(wiper.stats["sweep_degrees_per_second"])
	_step(int(ceil(pass_s / DT)) + 1)
	assert_eq(same.damage_taken.size(), 1, "hit")
	assert_eq(same.pushes.size(), 1, "and pushed")
	assert_eq(other.damage_taken.size(), 0, "another level: not hit")
	assert_eq(other.pushes.size(), 0, "nor pushed")


func test_bricks_hits_and_pushes_only_the_level_where_the_car_lands() -> void:
	rack.upgrade("bricks")
	var same := _minion(_car() + Vector2(1.5, 0.0), ROOF)
	var other := _minion(_car() + Vector2(-1.5, 0.0), 0.0)
	var hit: Array = rack.bricks.send_wave(_car())
	assert_eq(hit, [same])
	assert_eq(same.damage_taken.size(), 1)
	assert_eq(same.pushes.size(), 1)
	assert_eq(other.damage_taken.size(), 0)
	assert_eq(other.pushes.size(), 0)


func test_bricks_landing_on_the_street_hits_the_street() -> void:
	rack.upgrade("bricks")
	var spot := roof_rect.end + Vector2(6.0, 6.0)
	var street := _minion(spot + Vector2(1.0, 0.0), 0.0)
	var roof := _minion(spot + Vector2(-1.0, 0.0), ROOF)
	assert_eq(rack.bricks.send_wave(spot), [street])
	assert_eq(roof.damage_taken.size(), 0)


func test_a_molotov_fire_burns_only_its_own_level_wherever_the_car_is() -> void:
	rack.upgrade("molotov")
	var spot := roof_rect.end + Vector2(6.0, 6.0)  # the street, the car on the rooftop
	var street := _minion(spot, 0.0)
	var roof_height := _minion(spot + Vector2(0.3, 0.0), ROOF)
	var fire: Node = rack.molotov.land(spot)
	assert_almost_eq(float(fire.level), 0.0, 1e-6, "the street's level")
	_step(1)
	assert_eq(street.damage_taken.size(), 1, "the fire burns the enemy on its level")
	assert_eq(roof_height.damage_taken.size(), 0, "not the car's level")


func test_a_molotov_fire_on_the_rooftop_burns_the_rooftop() -> void:
	rack.upgrade("molotov")
	var spot := _car() + Vector2(4.0, 0.0)
	var roof := _minion(spot, ROOF)
	var street := _minion(spot + Vector2(0.3, 0.0), 0.0)
	rack.molotov.land(spot)
	_step(1)
	assert_eq(roof.damage_taken.size(), 1)
	assert_eq(street.damage_taken.size(), 0)


func test_the_kaiju_on_the_street_is_hit_from_the_rooftop() -> void:
	rack.upgrade("underglow")
	var kaiju := _minion(_car() + Vector2(2.0, 0.0), 0.0)
	kaiju.as_kaiju(1.0)
	_step(1)
	assert_eq(kaiju.damage_taken.size(), 1)


# --- The real elevation map ---------------------------------------------------------

func test_on_the_elevation_map_a_rooftop_underglow_spares_the_street_below() -> void:
	var real: GroundHeight = run.elevation.ground_height
	run.car.ground = null
	run.car.model.x = -60.0
	run.car.model.y = -67.2  # on roof-nw-3, 1.2 units from its south edge
	run.car.position = Vector2(run.car.model.x, run.car.model.y) * 16.0
	run.car.ground = real
	assert_almost_eq(run.car.height, 3.0, 1e-6, "on the rooftop")
	rack.upgrade("underglow")
	var on_roof: Node = run.minions.spawn_minion_at(Vector2(-58.5, -67.5))
	var below: Node = run.minions.spawn_minion_at(Vector2(-60.0, -65.2))
	for m in [on_roof, below]:
		m.max_health = 100.0
		m.health = 100.0
	assert_almost_eq(float(on_roof.body_height()), 3.0, 1e-6)
	assert_almost_eq(float(below.body_height()), 0.0, 1e-6)
	assert_lt(below.position_units().distance_to(rack.car_units()), rack.underglow.radius(), "within the ring")
	_step(1)
	assert_lt(on_roof.health, 100.0, "the minion beside the car on the rooftop is hit")
	assert_eq(below.health, 100.0, "the one on the street below is not")
