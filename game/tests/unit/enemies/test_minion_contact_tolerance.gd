extends GutTest
## Task T-515 (Enemies, Decisions, "Even the lowest Jump clears a minion"): the car's contact
## damage from a minion has its own height tolerance (0.5 units), so a tier 1 hop (peak ~1.04)
## clears a minion for ~0.6 s. The other tolerances (kaiju contact, meteors, crowding, weapons)
## keep their values.

const RunScene := preload("res://scenes/run/run.tscn")
const EnemyHeightScript := preload("res://scripts/enemies/enemy_height.gd")
const CarHeightScript := preload("res://scripts/driving/car_height.gd")
const DT := 0.02

var run: Node2D
var ground


func before_each() -> void:
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	run.car.set_physics_process(false)
	run.minions.enabled = false
	run.minions.clear()
	run.kaiju_boss.enabled = false
	ground = run.elevation.ground_height


func _place_car(units: Vector2) -> void:
	var car = run.car
	car.model.set_position(units)
	car.model.rotation = 0.0
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = ground
	run.sync_view()


## A minion standing right under the car's middle, on the street.
func _minion_under_car() -> Node:
	_place_car(Vector2(-60, -65.5))
	var m = run.minions.spawn_minion_at(Vector2(-60, -65.5))
	assert_true(m.touches_car(run.car.position / 16.0, run.car.rotation), "they touch")
	return m


func _hit_at(m: Node, h: float) -> bool:
	_place_car(Vector2(-60, -65.5))  # a hit knocks the car back: put it under the minion again
	m.contact_cooldown = 0.0
	run.state.invulnerable_left = 0.0
	run.car.height_model.height = h
	run.car.height_model.airborne = h > 0.0
	var r: bool = m.contact_step(DT, run.car, run.state)
	return r


func test_a_tier_1_hop_peak_clears_a_minion() -> void:
	var m := _minion_under_car()
	var d := PowerUpData.new()
	var v := float(d.at("jump", 1).takeoff_speed)
	var peak := v * v / (2.0 * CarHeightScript.GRAVITY)
	assert_gt(peak, 1.0, "the lowest hop peaks near 1.04")
	assert_false(_hit_at(m, 0.6), "well below the peak (0.6) of the lowest hop: no contact damage")
	assert_false(_hit_at(m, peak), "at the peak (%.2f): no contact damage" % peak)


func test_the_real_hop_curve_is_clear_of_a_minion_for_half_a_second() -> void:
	var m := _minion_under_car()
	var v := float(PowerUpData.new().at("jump", 1).takeoff_speed)
	var h := 0.0
	var vz := v
	var clear := 0.0
	var t := 0.0
	while t < 1.5:
		vz -= CarHeightScript.GRAVITY * DT
		h = maxf(h + vz * DT, 0.0)
		if h <= 0.0:
			break
		if not _hit_at(m, h):
			clear += DT
		t += DT
	gut.p("clear of the minion for %.2f s" % clear)
	assert_gte(clear, 0.5, "clear for at least 0.5 s")


func test_a_car_on_the_ground_is_still_hit() -> void:
	var m := _minion_under_car()
	assert_true(_hit_at(m, 0.0), "on the ground")
	assert_true(_hit_at(m, 0.4), "just off the ground (within 0.5)")


func test_a_car_on_a_rooftop_is_safe_from_the_street_below() -> void:
	var m = run.minions.spawn_minion_at(Vector2(-60, -65.45))
	_place_car(Vector2(-60, -66.3))
	assert_almost_eq(run.car.height, 3.0, 0.001)
	assert_false(m.contact_step(DT, run.car, run.state))


func test_a_car_on_a_ramp_is_hit_by_a_minion_on_the_same_ramp() -> void:
	# Find a ramp point; the car and a minion 1 unit apart on it differ in ground height by
	# the ramp's slope (0.25 a unit): about 0.25, far under 0.5.
	var found := Vector2.INF
	for y in range(-120, 121, 2):
		for x in range(-120, 121, 2):
			var p := Vector2(x, y)
			if ground.is_ramp(p) and ground.is_ramp(p + Vector2(1, 0)) and ground.height_at(p) > 0.5:
				found = p
				break
		if found != Vector2.INF:
			break
	assert_ne(found, Vector2.INF, "a ramp on the map")
	_place_car(found)
	var m = run.minions.spawn_minion_at(found + Vector2(0.5, 0))
	if not m.touches_car(run.car.position / 16.0, run.car.rotation):
		m.set_position_units(found)
	var gap := absf(run.car.height - m.body_height())
	assert_lt(gap, 0.5, "heights on the ramp differ by %.2f" % gap)
	m.contact_cooldown = 0.0
	run.state.invulnerable_left = 0.0
	assert_true(m.contact_step(DT, run.car, run.state), "hit on the ramp")


func test_the_other_tolerances_are_unchanged() -> void:
	assert_eq(EnemyHeightScript.LEVEL_TOLERANCE, 1.0)
	assert_true(EnemyHeightScript.at_car_level(0.0, 1.0), "kaiju, meteors, crowding: still 1 unit")
	assert_false(EnemyHeightScript.at_car_level(0.0, 1.1))
	assert_eq(EnemyHeightScript.MINION_CONTACT_TOLERANCE, 0.5)
	var rack = preload("res://scripts/weapons/weapons.gd")
	assert_eq(rack.LEVEL_TOLERANCE, 1.5)


func test_the_kaiju_still_hits_a_car_one_unit_up() -> void:
	run.kaiju_boss.enabled = true
	_place_car(Vector2(-60, -65.5))
	var k = run.kaiju_boss.appear_at(Vector2(-60, -65.5))
	run.car.height_model.height = 0.9
	run.car.height_model.airborne = true
	k.contact_cooldown = 0.0
	run.state.invulnerable_left = 0.0
	var before: float = run.state.health
	k.contact_step(DT, run.car, run.state)
	assert_lt(run.state.health, before, "the kaiju's 1 unit rule is unchanged")
