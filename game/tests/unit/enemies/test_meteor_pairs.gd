extends GutTest
## Task T-539 (Enemies, Decisions, "Paired meteors hurt the kaiju"): the
## kaiju's meteors land in pairs pair_distance_units apart; a drifting car
## crossing between a landed pair hurts the kaiju by pair_damage_to_kaiju and
## breaks both boulders, with the beam, the break-up and the kaiju's hit flash;
## driving through without drifting does nothing; a pair pays once.

const RunScene := preload("res://scenes/run/run.tscn")
const KaijuBossScript := preload("res://scripts/enemies/kaiju_boss.gd")
const FlameScript := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const PairFx := preload("res://scripts/enemies/meteor_pair_fx.gd")
const DT := 0.02

var run: Node2D
var boss: Node
var met: Node
var m: Dictionary
var kaiju: Node


func before_each() -> void:
	KaijuBossScript.playtest_override = -1.0
	FlameScript.playtest_override = 0
	run = RunScene.instantiate()
	add_child_autofree(run)
	boss = run.kaiju_boss
	boss.rng.seed = 539
	met = boss.meteors
	met.rng.seed = 539
	met.enabled = false  # no scheduled attacks: each test drops its own
	run.minions.enabled = false
	run.car.use_keyboard = false
	m = EnemyData.new().meteor_attack()
	kaiju = _kaiju_near()


func after_each() -> void:
	KaijuBossScript.playtest_override = -2.0
	FlameScript.playtest_override = -1


func _car_units() -> Vector2:
	return run.car.position / 16.0


func _kaiju_near(distance: float = 16.0) -> Node:
	for i in 64:
		var p := _car_units() + Vector2.RIGHT.rotated(TAU * i / 64.0) * distance
		if boss.is_free_spot(p):
			var k: Node = boss.appear_at(p)
			boss.enabled = false
			return k
	fail_test("no free spot for the kaiju")
	return null


func _steps(seconds: float) -> void:
	for i in int(round(seconds / DT)):
		met.step(DT)


## A pair picked and landed (the car parked away from both spots).
func _landed_pair() -> Dictionary:
	var pr = met.pick_pair()
	assert_not_null(pr, "a pair is found near the car")
	if pr == null:
		return {}
	var pair: Dictionary = met.add_pair_warnings(pr[0], pr[1])
	_steps(m["warning_seconds"] + 0.1)
	assert_eq(pair.landed, 2, "both landed")
	return pair


## Moves the car across the pair's line, through its middle, in two steps:
## `drifting` sets the car's own drift state for the crossing step.
func _cross(pair: Dictionary, drifting: bool, offset_along := 0.0) -> void:
	var mid: Vector2 = (pair.a + pair.b) / 2.0
	var along: Vector2 = (pair.b - pair.a).normalized()
	var side := Vector2(-along.y, along.x)
	var at := mid + along * offset_along
	run.car.model.is_drifting = false
	run.car.position = (at - side * 1.0) * 16.0
	met.step(DT)
	run.car.model.is_drifting = drifting
	run.car.position = (at + side * 1.0) * 16.0
	met.step(DT)
	run.car.model.is_drifting = false


func _bodies_on_map(pair: Dictionary) -> int:
	var n := 0
	for b in run.map.meteor_boulders:
		var u := Vector2(float(b.x), float(b.y))
		if u.distance_to(pair.a) < 0.01 or u.distance_to(pair.b) < 0.01:
			n += 1
	return n


func test_the_data_has_whole_pairs_at_a_drivable_distance() -> void:
	assert_eq(int(m["meteors_per_attack"]) % 2, 0, "whole pairs")
	var apart: float = run.map.boulder_diameter() + m["boulder_clearance_units"]
	assert_gte(m["pair_distance_units"], apart, "the two of a pair keep the boulders' clearance")
	assert_gt(m["pair_distance_units"] - run.map.boulder_diameter(), 2.0, "the gap is wider than a car's length")
	assert_gt(m["pair_damage_to_kaiju"], 0.0)
	assert_lt(m["pair_damage_to_kaiju"], EnemyData.new().kaiju()["health"], "a pair alone does not kill it")


func test_meteors_land_in_pairs_at_the_pair_distance() -> void:
	var seen := 0
	for attack in 6:
		met.clear()
		var spots: Array = met.drop_meteors()
		assert_eq(spots.size() % 2, 0, "whole pairs only")
		assert_eq(met.pairs.size() * 2, spots.size(), "every meteor is in a pair")
		for pr in met.pairs:
			seen += 1
			assert_almost_eq(pr.a.distance_to(pr.b), float(m["pair_distance_units"]), 0.001, "the data's distance")
			assert_true(run.map.can_place_meteor_boulder(pr.a))
			assert_lte(pr.a.distance_to(_car_units()), m["land_within_units_of_car"] + 0.01, "near the car")
			assert_lte(pr.b.distance_to(_car_units()), m["land_within_units_of_car"] + 0.01, "the partner too")
			assert_true(run.map.can_place_meteor_boulder(pr.b))
			assert_true(met.gap_is_clear(pr.a, pr.b), "open ground between the two")
			var ws: Array = met.warnings.filter(func(w) -> bool: return w.pair == pr)
			assert_eq(ws.size(), 2, "two warning circles share the pair")
	assert_gte(seen, 10, "pairs are found (2 per attack)")
	met.clear()
	met.drop_meteors()
	assert_eq(met.warnings.size(), int(m["meteors_per_attack"]), "the data's number of meteors at once")


func test_a_drift_through_a_landed_pair_hurts_the_kaiju_and_breaks_both() -> void:
	var pair := _landed_pair()
	assert_eq(_bodies_on_map(pair), 2, "both boulders on the map")
	var struck := []
	met.pair_struck.connect(func(a: Vector2, b: Vector2, dmg: float) -> void: struck.append(dmg))
	var health: float = kaiju.health
	_cross(pair, true)
	assert_eq(struck.size(), 1, "the pair struck")
	assert_almost_eq(kaiju.health, health - m["pair_damage_to_kaiju"], 0.001, "the data's damage")
	assert_eq(_bodies_on_map(pair), 0, "both boulders destroyed at once")
	for b in met.standing_boulders:
		assert_false(b.pair == pair, "no longer ageing")
	assert_eq(met.pairs.size(), 0, "the pair is spent")
	# The effects: the beam to the kaiju, the two break-ups and the kaiju's hit flash.
	assert_eq(met.links.size(), 1, "the beam from the pair to the kaiju")
	assert_eq(met.links[0].kaiju, kaiju)
	assert_almost_eq(met.links[0].from, (pair.a + pair.b) / 2.0, Vector2(0.001, 0.001))
	assert_eq(met.breakups.size(), 2, "a break-up at each boulder")
	assert_true(kaiju.hit_tint.is_active(), "the kaiju's hit flash")
	# They play out and go.
	_steps(maxf(PairFx.LINK_SECONDS, PairFx.BREAKUP_SECONDS) + 0.05)
	assert_eq(met.links.size(), 0)
	assert_eq(met.breakups.size(), 0)


func test_driving_through_without_drifting_does_nothing() -> void:
	var pair := _landed_pair()
	var health: float = kaiju.health
	_cross(pair, false)
	assert_eq(kaiju.health, health, "no damage")
	assert_eq(_bodies_on_map(pair), 2, "both boulders stay")
	assert_eq(met.links.size(), 0)
	assert_true(met.is_pair_armed(pair), "still armed")


func test_a_pair_pays_once() -> void:
	var pair := _landed_pair()
	var health: float = kaiju.health
	_cross(pair, true)
	_cross(pair, true)
	assert_true(met.strike_pair(pair) == false, "a paid pair cannot strike again")
	assert_almost_eq(kaiju.health, health - m["pair_damage_to_kaiju"], 0.001, "paid only once")


func test_a_drift_beside_the_pair_does_not_count() -> void:
	var pair := _landed_pair()
	var health: float = kaiju.health
	# Crossing the pair's line extended, beyond a boulder.
	_cross(pair, true, float(m["pair_distance_units"]) / 2.0 + 3.0)
	assert_eq(kaiju.health, health)
	assert_eq(_bodies_on_map(pair), 2)


func test_nothing_before_both_have_landed() -> void:
	var pr = met.pick_pair()
	var pair: Dictionary = met.add_pair_warnings(pr[0], pr[1])
	var health: float = kaiju.health
	_cross(pair, true)
	assert_eq(kaiju.health, health, "the warnings alone do not pay")
	assert_false(met.is_pair_armed(pair))


func test_a_faded_pair_pays_nothing() -> void:
	var pair := _landed_pair()
	run.car.position = (pair.a + (pair.a - pair.b).normalized() * 20.0) * 16.0  # away
	_steps(m["boulder_lifetime_seconds"] + m["boulder_fade_seconds"] + 0.2)
	assert_eq(_bodies_on_map(pair), 0, "faded away")
	var health: float = kaiju.health
	_cross(pair, true)
	assert_eq(kaiju.health, health)
	assert_eq(met.pairs.size(), 0, "forgotten")


func test_a_new_run_clears_the_pairs_and_effects() -> void:
	var pair := _landed_pair()
	_cross(pair, true)
	met.drop_meteors()
	met.clear()
	assert_eq(met.pairs.size(), 0)
	assert_eq(met.links.size(), 0)
	assert_eq(met.breakups.size(), 0)


func test_the_ground_and_sky_drawings_run_with_pairs_and_strikes() -> void:
	# The drawings must not error with pairs, a strike's beam and break-ups (a parse or
	# runtime error there blanks the run scene).
	var pair := _landed_pair()
	met.drop_meteors()
	met.ground_draw.queue_redraw()
	await get_tree().process_frame
	_cross(pair, true)
	met.sky_draw.queue_redraw()
	await get_tree().process_frame
	assert_eq(met.links.size(), 1)
