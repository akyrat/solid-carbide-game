extends GutTest
## Task T-046: the kaiju's meteor attack. Attacks on the data's schedule after
## the kaiju appears, a windup, warning circles shown for warning_seconds
## before the meteors land where they showed, a hit on the car (damage and
## knockback) only when it lands on it, a boulder through the map's
## add_meteor_boulder() only where its placement check accepts (the car
## bounces off it), pausing, a new run, and the placeholders' colours.

const RunScene := preload("res://scenes/run/run.tscn")
const KaijuBossScript := preload("res://scripts/enemies/kaiju_boss.gd")
const MeteorsScript := preload("res://scripts/enemies/kaiju_meteors.gd")
const FlameScript := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const DT := 0.02

var run: Node2D
var boss: Node
var met: Node
var data: EnemyData
var m: Dictionary


func before_each() -> void:
	KaijuBossScript.playtest_override = -1.0
	FlameScript.playtest_override = 0
	run = RunScene.instantiate()
	add_child_autofree(run)
	boss = run.kaiju_boss
	boss.rng.seed = 46
	met = boss.meteors
	met.rng.seed = 46
	run.minions.enabled = false
	run.car.use_keyboard = false
	data = EnemyData.new()
	m = data.meteor_attack()


func after_each() -> void:
	get_tree().paused = false
	KaijuBossScript.playtest_override = -2.0
	FlameScript.playtest_override = -1


func _car_units() -> Vector2:
	return run.car.position / 16.0


## Puts the kaiju on the map `distance` units from the car, standing still
## (the boss is disabled so it does not walk; the meteors still see it).
func _kaiju_near(distance: float = 14.0) -> Node:
	for i in 64:
		var p := _car_units() + Vector2.RIGHT.rotated(TAU * i / 64.0) * distance
		if boss.is_free_spot(p):
			var k: Node = boss.appear_at(p)
			boss.enabled = false
			return k
	fail_test("no free spot for the kaiju")
	return null


## Runs `seconds` of meteor steps.
func _steps(seconds: float) -> void:
	for i in int(round(seconds / DT)):
		met.step(DT)


## A spot the map accepts for a boulder, `distance` units from the car and clear of the kaiju.
func _good_spot(distance: float) -> Vector2:
	for i in 64:
		var p := _car_units() + Vector2.RIGHT.rotated(TAU * i / 64.0 + 0.3) * distance
		if met.is_good_spot(p):
			return p
	fail_test("no good spot %.1f from the car" % distance)
	return Vector2.ZERO


func test_the_attack_is_part_of_the_kaiju_boss() -> void:
	assert_not_null(met, "run.kaiju_boss.meteors")
	assert_eq(met.get_parent(), boss)
	assert_eq(met.car, run.car)
	assert_eq(met.map, run.map)
	assert_eq(met.ground_draw.get_parent(), run.map.view_root, "warnings on the ground, in the map's drawing")
	assert_gt(met.ground_draw.get_index(), run.map.ground_tiles.get_index(), "over the ground tiles")
	assert_lt(met.ground_draw.get_index(), run.map.buildings_draw.get_index(), "under the buildings")


func test_no_attack_without_the_kaiju() -> void:
	var started := []
	met.attack_started.connect(func() -> void: started.append(1))
	_steps(30.0)
	assert_eq(started.size(), 0)
	assert_eq(met.warnings.size(), 0)


func test_attacks_follow_the_data_schedule() -> void:
	_kaiju_near()
	var starts := []
	met.attack_started.connect(func() -> void: starts.append(met.fight_time))
	var fight: float = m["first_attack_after_seconds"] + 3.0 * m["seconds_between_attacks"] - 0.5
	_steps(fight)
	var expected: Array = data.meteor_attack_times(fight)
	assert_eq(starts.size(), expected.size(), "as many attacks as the data's times")
	for i in mini(starts.size(), expected.size()):
		assert_almost_eq(starts[i], expected[i], DT * 1.5, "attack %d at the data's time" % i)


func test_warnings_show_for_two_seconds_then_meteors_land_where_they_showed() -> void:
	_kaiju_near()
	assert_eq(m["warning_seconds"], 2.0, "the decided 2 seconds")
	var shown := []
	var landed := []
	met.warnings_shown.connect(func(spots: Array) -> void: shown.append_array(spots))
	met.meteor_landed.connect(func(u: Vector2, _hit: bool) -> void: landed.append(u))
	met.start_attack()
	assert_true(met.is_winding_up(), "the short windup first")
	_steps(m["windup_seconds"])
	assert_false(met.is_winding_up())
	assert_eq(shown.size(), int(m["meteors_per_attack"]), "the data's number of meteors at once")
	assert_eq(met.warnings.size(), shown.size(), "a warning circle for each")
	for p in shown:
		assert_lte(p.distance_to(_car_units()), m["land_within_units_of_car"] + 0.01, "near the car")
		assert_true(run.map.can_place_meteor_boulder(p), "where the placement check accepts a boulder")
	# Still showing just before 2 seconds, nothing landed.
	_steps(m["warning_seconds"] - 0.1)
	assert_eq(landed.size(), 0, "nothing lands before 2 seconds")
	assert_eq(met.warnings.size(), shown.size(), "the circles still show")
	_steps(0.12)
	assert_eq(landed.size(), shown.size(), "all landed at 2 seconds")
	assert_eq(met.warnings.size(), 0, "the circles are gone")
	for i in shown.size():
		assert_eq(landed[i], shown[i], "landed where its circle showed")


func test_a_meteor_on_the_car_damages_it_and_knocks_it_back() -> void:
	var health: float = run.state.health
	var spot := _car_units() + Vector2(0.6, 0.0)
	var hit: bool = met.land(spot)
	assert_true(hit)
	assert_almost_eq(run.state.health, health - m["impact_damage"], 0.001, "the data's impact damage")
	var kb: Vector2 = run.car.pending_knockback()
	assert_almost_eq(kb.length(), m["knockback"], 0.001, "the data's knockback")
	assert_gt(kb.dot(_car_units() - spot), 0.0, "away from where it landed")


func test_a_meteor_elsewhere_does_not_hit_the_car() -> void:
	var health: float = run.state.health
	var spot := _good_spot(m["impact_radius_units"] + 3.0)
	var hit: bool = met.land(spot)
	assert_false(hit)
	assert_eq(run.state.health, health, "no damage")
	assert_eq(run.car.pending_knockback(), Vector2.ZERO, "no knockback")


func test_through_the_attack_a_meteor_on_the_car_hits_it() -> void:
	_kaiju_near()
	var health: float = run.state.health
	met.add_warning(_car_units())
	_steps(m["warning_seconds"] + DT)
	assert_almost_eq(run.state.health, health - m["impact_damage"], 0.001)


func test_each_landed_meteor_leaves_a_boulder_through_the_maps_function() -> void:
	_kaiju_near()
	var before: int = run.map.meteor_boulders.size()
	var placed := []
	met.boulder_placed.connect(func(u: Vector2, body: Node) -> void: placed.append([u, body]))
	met.start_attack()
	_steps(m["windup_seconds"] + m["warning_seconds"] + 0.1)
	var n: int = int(m["meteors_per_attack"])
	# A meteor that landed on the car keeps its boulder until the car is off the spot.
	assert_eq(placed.size() + met.pending_boulders.size(), n, "one boulder per meteor")
	assert_gt(placed.size(), 0)
	assert_eq(run.map.meteor_boulders.size(), before + placed.size(), "added through map.add_meteor_boulder")
	for pb in placed:
		var u: Vector2 = pb[0]
		assert_true(pb[1] in run.map.meteor_boulder_bodies, "the map's meteor boulder body")
		var found := false
		for b in run.map.meteor_boulders:
			if Vector2(b.x, b.y).distance_to(u) < 0.001:
				found = true
				assert_eq(float(b.diameter), run.map.boulder_diameter(), "a plain boulder of the map's size")
		assert_true(found, "a boulder where it landed")
	assert_eq(run.map.meteor_challenge_ids().size(), 0, "no challenge comes with it")


func test_every_picked_spot_passes_the_placement_check() -> void:
	_kaiju_near()
	var calls := 0
	for i in 40:
		var p = met.pick_spot()
		if p == null:
			continue
		calls += 1
		assert_true(run.map.can_place_meteor_boulder(p), "accepted by the placement check: %s" % p)
		assert_lte(p.distance_to(_car_units()), m["land_within_units_of_car"] + 0.01)
	assert_gt(calls, 30, "spots are found near the car")


func test_no_boulder_where_the_placement_check_refuses() -> void:
	# A spot on a building: the check refuses it, so the meteor leaves no boulder.
	var b: Dictionary = run.map.layout.buildings[0]
	var on_building: Vector2 = run.map.rect_of(b).get_center()
	assert_false(run.map.can_place_meteor_boulder(on_building))
	var before: int = run.map.meteor_boulders.size()
	met.land(on_building)
	assert_eq(run.map.meteor_boulders.size(), before, "no boulder on a refused spot")
	# Spots never overlap each other: a second meteor at the same spot leaves no second boulder.
	var spot := _good_spot(6.0)
	met.land(spot)
	met.land(spot)
	assert_eq(run.map.meteor_boulders.size(), before + 1, "only one boulder")


func test_a_meteor_on_the_car_leaves_its_boulder_once_the_car_is_off_the_spot() -> void:
	var spot := _car_units() + Vector2(0.4, 0.0)
	var before: int = run.map.meteor_boulders.size()
	met.land(spot)
	assert_eq(run.map.meteor_boulders.size(), before, "not on top of the car")
	assert_eq(met.pending_boulders.size(), 1)
	await wait_physics_frames(30)  # the knockback carries the car away
	met.step(DT)
	assert_eq(run.map.meteor_boulders.size(), before + 1, "the boulder appears once the car has left")
	assert_eq(met.pending_boulders.size(), 0)


func test_the_car_bounces_off_a_meteor_boulder() -> void:
	var car: Node2D = run.car
	var c := _car_units()
	# A boulder in front of the car (the way it faces).
	var ahead := Vector2.RIGHT.rotated(car.rotation)
	var spot := c + ahead * 4.0
	if not run.map.can_place_meteor_boulder(spot):
		spot = _good_spot(4.0)
		ahead = (spot - c).normalized()
	met.land(spot)
	assert_eq(met.pending_boulders.size(), 0, "placed at once")
	var hits := []
	car.hit_obstacle.connect(func(collider: Object, _s: int, _n: Vector2, _v: float) -> void: hits.append(collider))
	# Drive the car's body straight at it.
	car.model.vx = ahead.x * 12.0
	car.model.vy = ahead.y * 12.0
	car.model.rotation = ahead.angle()
	for i in 40:
		await wait_physics_frames(1)
		if not hits.is_empty():
			break
	assert_false(hits.is_empty(), "the car hit the meteor boulder")
	if not hits.is_empty():
		assert_true(hits[0] in run.map.meteor_boulder_bodies, "the meteor boulder's body")
	assert_gt(_car_units().distance_to(spot), run.map.boulder_diameter() / 2.0, "it did not drive into it")


func test_meteors_and_warnings_stop_while_paused() -> void:
	_kaiju_near()
	boss.enabled = true
	met.start_attack()
	met.windup_left = 0.001
	await wait_physics_frames(2)
	assert_gt(met.warnings.size(), 0, "warnings showing")
	var left: float = met.warnings[0].time_left
	var fight: float = met.fight_time
	var boulders: int = run.map.meteor_boulders.size()
	get_tree().paused = true
	await wait_physics_frames(int(m["warning_seconds"] * 60.0) + 30)
	assert_eq(met.warnings[0].time_left, left, "the warning's countdown stopped")
	assert_eq(met.fight_time, fight, "the attack clock stopped")
	assert_eq(run.map.meteor_boulders.size(), boulders, "nothing landed while paused")
	get_tree().paused = false
	await wait_physics_frames(3)
	assert_lt(met.warnings[0].time_left if not met.warnings.is_empty() else -1.0, left, "counting again")


func test_nothing_lands_after_the_run_ends() -> void:
	_kaiju_near()
	met.add_warning(_good_spot(6.0))
	run.state.damage_car(100000.0)
	var before: int = run.map.meteor_boulders.size()
	_steps(m["warning_seconds"] + 0.5)
	assert_eq(run.map.meteor_boulders.size(), before)


func test_a_new_run_clears_the_attack() -> void:
	_kaiju_near()
	met.add_warning(_good_spot(6.0))
	met.start_attack()
	run.start_run()
	assert_eq(met.warnings.size(), 0)
	assert_false(met.is_winding_up())
	assert_eq(met.map, run.map, "follows the new map")
	assert_eq(met.ground_draw.get_parent(), run.map.view_root)
	assert_eq(met.fight_time, 0.0)


func test_tests_do_not_depend_on_the_playtest_switch() -> void:
	assert_eq(boss.early_arrival_seconds, -1.0, "the switch is overridden off in these tests")


func test_placeholders_are_not_redgull_red() -> void:
	var redgull := Color(0.86, 0.1, 0.16)
	for c in [MeteorsScript.WARNING_COLOR, MeteorsScript.WARNING_FILL, MeteorsScript.METEOR_COLOR,
			MeteorsScript.METEOR_GLOW, MeteorsScript.METEOR_OUTLINE, MeteorsScript.DUST_COLOR,
			MeteorsScript.WINDUP_COLOR]:
		var reddish: bool = c.r > 0.6 and c.g < 0.35 and c.b < 0.35
		assert_false(reddish, "no red: %s" % c)
		assert_gt(Vector3(c.r, c.g, c.b).distance_to(Vector3(redgull.r, redgull.g, redgull.b)), 0.5,
			"far from Redgull red: %s" % c)


# ---- Boulders fade away (task T-142) ---------------------------------------------------------

## Lands one meteor on a good spot far from the car and returns its boulder body.
func _landed_boulder() -> Node:
	_kaiju_near()
	met.enabled = false  # no scheduled attacks: only this one meteor
	var spot := _good_spot(8.0)
	var got := []
	met.boulder_placed.connect(func(_u: Vector2, body: Node) -> void: got.append(body))
	met.add_warning(spot)
	_steps(m["warning_seconds"] + DT)
	assert_eq(got.size(), 1, "the boulder is placed")
	return got[0]


func _sprite_of(body: Node) -> Node:
	return run.map._boulder_sprite_by_key.get(body.get_meta("boulder_key"))


func test_boulder_is_fully_visible_and_blocking_just_before_the_lifetime() -> void:
	var body := _landed_boulder()
	_steps(m["boulder_lifetime_seconds"] - 0.5)
	assert_true(is_instance_valid(body) and body.is_inside_tree(), "still in the scene")
	assert_true(body in run.map.meteor_boulder_bodies, "still a body on the map")
	assert_eq(run.map.meteor_boulders.size(), 1)
	var sp := _sprite_of(body)
	if sp != null:
		assert_almost_eq(sp.modulate.a, 1.0, 0.001, "fully visible")
	assert_false(run.map.can_place_meteor_boulder(Vector2(body.get_child(0).position / 16.0)), "its spot still blocked")


func test_boulder_fades_after_the_lifetime_then_is_removed() -> void:
	var body := _landed_boulder()
	var sp := _sprite_of(body)
	_steps(m["boulder_lifetime_seconds"] + m["boulder_fade_seconds"] / 2.0)
	assert_true(is_instance_valid(body) and body.is_inside_tree(), "still there while it fades")
	if sp != null:
		assert_lt(sp.modulate.a, 1.0, "going transparent")
		assert_gt(sp.modulate.a, 0.0, "not yet gone")
		var half: float = sp.modulate.a
		_steps(m["boulder_fade_seconds"] / 4.0)
		assert_lt(sp.modulate.a, half, "fainter over the fade")
	var centre: Vector2 = body.get_child(0).position / 16.0
	_steps(m["boulder_fade_seconds"])
	assert_false(is_instance_valid(body) and body.is_inside_tree(), "no longer in the scene")
	assert_false(body in run.map.meteor_boulder_bodies)
	assert_eq(run.map.meteor_boulders.size(), 0)
	assert_eq(met.standing_boulders.size(), 0)
	assert_true(run.map.can_place_meteor_boulder(centre), "it blocks nothing now")


func test_a_removed_boulder_has_left_the_physics_world() -> void:
	var body := _landed_boulder()
	assert_eq(body.get_parent(), run.map.physics_root, "in the physics world while it stands")
	_steps(m["boulder_lifetime_seconds"] + m["boulder_fade_seconds"] + 0.1)
	assert_null(body.get_parent(), "taken out of the physics world, so the car cannot hit it")


func test_the_maps_own_boulders_are_not_removed() -> void:
	var own: int = run.map.boulder_bodies.size()
	var all_before: int = run.map.all_boulders().size()
	var body := _landed_boulder()
	_steps(m["boulder_lifetime_seconds"] + m["boulder_fade_seconds"] + 1.0)
	assert_false(is_instance_valid(body) and body.is_inside_tree())
	assert_eq(run.map.boulder_bodies.size(), own)
	assert_eq(run.map.all_boulders().size(), all_before, "back to the map's own boulders")
	for b in run.map.boulder_bodies:
		assert_true(is_instance_valid(b) and b.is_inside_tree())


func test_the_lifetime_and_fade_come_from_the_data() -> void:
	assert_eq(float(m["boulder_lifetime_seconds"]), 10.0)
	assert_gt(m["boulder_fade_seconds"], 0.0)
	met._stats = met._stats.duplicate()
	met._stats["boulder_lifetime_seconds"] = 3.0
	met._stats["boulder_fade_seconds"] = 1.0
	var body := _landed_boulder()
	_steps(2.5)
	assert_true(is_instance_valid(body) and body.is_inside_tree())
	_steps(1.6)
	assert_false(is_instance_valid(body) and body.is_inside_tree(), "gone at lifetime + fade from the data")
