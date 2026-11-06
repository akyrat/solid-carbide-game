extends GutTest
## Task T-531 (Enemies, Decisions, "Minion deaths"): a dying minion plays a death animation,
## spills a physics-simulated green liquid, and lies as a corpse that the car and the knockback
## weapons (the bricks wave, the wiper, the Polarized Steering Wheel's shock) knock about; every
## hit restarts a 2 s timer, after which the corpse and its liquid fade and are freed. The caps
## on corpses, droplets and pools hold under a mass death.

const RunScene := preload("res://scenes/run/run.tscn")
const Bricks := preload("res://scripts/weapons/bricks.gd")
const Wiper := preload("res://scripts/weapons/windshield_wiper.gd")
const Flame := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const Glow := preload("res://scripts/weapons/neon_underglow.gd")
const Molotovs := preload("res://scripts/weapons/molotovs.gd")
const ISO := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
const DT := 0.02  # one physics step (50 per second)

var run: Node2D
var spawner: Node
var corpses
var data: EnemyData
var death: Dictionary


func before_each() -> void:
	for s in [Bricks, Wiper, Flame, Glow, Molotovs]:
		s.playtest_override = 0
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	run.car.set_physics_process(false)
	run.kaiju_boss.enabled = false
	spawner = run.minions
	spawner.enabled = false
	spawner.clear()
	spawner.rng.seed = 531
	run.weapons.gun.set_tier(0)
	corpses = spawner.corpses
	corpses.rng.seed = 531
	data = EnemyData.new()
	death = data.minion_death()


func after_each() -> void:
	for s in [Bricks, Wiper, Flame, Glow, Molotovs]:
		s.playtest_override = -1
	get_tree().paused = false


func _place_car(units: Vector2, velocity := Vector2.ZERO) -> void:
	var car = run.car
	car.model.set_position(units)
	car.model.rotation = 0.0
	car.model.set_velocity(velocity)
	car._sync_from_model()
	car.ground = run.elevation.ground_height
	run.sync_view()


## A minion at `units` killed at once; returns its body (now a corpse).
func _kill_at(units: Vector2) -> Node:
	var m: Node = spawner.spawn_minion_at(units)
	m.take_damage(100000.0)
	return m


func _step(seconds: float, car_parked := true) -> void:
	var t := 0.0
	while t < seconds - 0.000001:
		corpses.step(DT, run.car, Rect2())
		t += DT


func _killed_count() -> Array:
	var tally := [0]
	spawner.minion_killed.connect(func(_m: Node, _n: int) -> void: tally[0] += 1)
	return tally


# --- The data ------------------------------------------------------------------------

func test_the_numbers_are_in_the_data_with_the_boards_two_seconds() -> void:
	assert_false(death.is_empty(), "minion.death")
	assert_eq(death["corpse_seconds"], 2.0, "the board's 2 seconds")
	for k in ["animation_seconds", "fade_seconds", "max_corpses", "slide_seconds", "knock_scale_bricks", "knock_scale_wiper",
			"knock_scale_shock", "knock_car_per_speed", "droplets_per_death", "max_droplets", "max_pools", "droplet_gravity"]:
		assert_true(death.has(k), k)
	assert_false(data.minion().has("death"), "minion() stays the flat stats")


# --- The state sequence --------------------------------------------------------------

func test_a_dying_minion_plays_its_death_animation_then_lies_as_a_corpse() -> void:
	var m: Node = spawner.spawn_minion_at(Vector2(10, 10))
	var s: Node2D = m.sprite
	assert_eq(s.animation(), "walk")
	m.take_damage(100000.0)
	assert_true(m.is_dead())
	assert_true(m.is_corpse(), "kept as a corpse")
	assert_true(is_instance_valid(s), "its drawing stays")
	assert_eq(m.sprite, s)
	assert_eq(s.animation(), "death", "playing the death animation")
	assert_eq(s.death_progress(), 0.0)
	assert_false(m.is_in_group("enemies"))
	assert_false(m.is_in_group("minions"))
	assert_true(m.is_in_group("minion_corpses"))
	assert_false(spawner.minions.has(m))
	assert_eq(m.collision_layer, 0, "on no collision layer")
	var half: float = death["animation_seconds"] / 2.0
	for i in roundi(half / DT):
		s.advance(DT)
	assert_between(s.death_progress(), 0.4, 0.6, "half way")
	var tipped: Transform2D = s.death_transform()
	assert_ne(tipped, Transform2D.IDENTITY, "tipping over")
	for i in roundi(half / DT) + 5:
		s.advance(DT)
	assert_eq(s.death_progress(), 1.0, "then it lies")
	assert_almost_eq(s.death_transform().get_rotation(), s.death_side * s.DEATH_TIP, 0.15, "tipped over, in its facing's side")
	s.facing = Vector2.LEFT
	s.start_death(0.5)
	assert_eq(s.death_side, -1.0, "tips the other way when facing left")


func test_the_death_art_hook_frames_follow_the_animation_and_hold_the_last() -> void:
	var s: Node2D = spawner.spawn_minion_at(Vector2(10, 10)).sprite
	s.start_death(0.5)
	assert_eq(s.death_frame(8), 0)
	s.death_seconds = 0.26
	assert_eq(s.death_frame(8), 4)
	s.death_seconds = 5.0
	s.advance(DT)
	assert_eq(s.death_frame(8), 7, "the last frame is held")


func test_coins_and_the_kill_are_counted_once_at_death_as_before() -> void:
	var killed := _killed_count()
	var m := _kill_at(Vector2(12, 12))
	assert_eq(killed[0], 1)
	m.take_damage(5.0)
	assert_eq(killed[0], 1, "a corpse cannot be killed again")


# --- The spill ------------------------------------------------------------------------

func test_the_droplets_move_under_gravity_and_settle_into_pools_on_the_street() -> void:
	corpses.settings["droplet_speed_min"] = 1.0
	corpses.settings["droplet_speed_max"] = 2.0
	var m := _kill_at(Vector2(10, 10))
	assert_eq(corpses.spills.size(), 1)
	var sp: Node2D = corpses.spills[0]["node"]
	assert_eq(sp.droplet_count(), int(death["droplets_per_death"]))
	var h0: float = sp.droplet_height(0)
	_step(0.1)
	assert_gt(sp.droplet_height(0), h0, "rising")
	var vy_before: float = sp.droplet_height(0)
	_step(0.1)
	var rise2: float = sp.droplet_height(0) - vy_before
	assert_lt(rise2, vy_before - h0, "slowed by gravity")
	_step(1.0)
	assert_eq(sp.droplet_count(), 0, "every droplet has landed")
	assert_gt(sp.pool_count(), 0, "in pools")
	assert_lt(sp.pool_count(), int(death["droplets_per_death"]) + 1)
	var origin_y: float = (ISO * (Vector2(10, 10) * 16.0)).y
	for i in sp.pool_count():
		assert_almost_eq(sp.pool_screen(i).y, origin_y, 24.0, "on the street ground")
		assert_gt(sp.pool_final_radius(i), 0.0)
		assert_lte(sp.pool_final_radius(i), float(death["pool_max_radius_px"]))
	assert_true(m.is_corpse())


func test_the_pools_spread_after_they_land() -> void:
	_kill_at(Vector2(10, 10))
	var sp: Node2D = corpses.spills[0]["node"]
	_step(0.8)
	assert_gt(sp.pool_count(), 0)
	var grown := 0
	for i in sp.pool_count():
		if sp.pool_radius(i) > 1.0:
			grown += 1
	assert_gt(grown, 0, "spread from a speck")
	_step(0.5)
	for i in sp.pool_count():
		assert_almost_eq(sp.pool_radius(i), sp.pool_final_radius(i), 0.001, "to their size")


func test_a_death_on_a_rooftop_spills_on_the_rooftop() -> void:
	# roof-nw-3 (-96..-12, -96..-66) is 3 units high.
	var at := Vector2(-60, -85)
	assert_almost_eq(run.elevation.ground_height.height_at(at), 3.0, 0.001, "a rooftop")
	corpses.settings["droplet_speed_min"] = 1.0
	corpses.settings["droplet_speed_max"] = 2.0
	var m := _kill_at(at)
	assert_almost_eq(m.ground_height(), 3.0, 0.001)
	var sp: Node2D = corpses.spills[0]["node"]
	assert_gt(sp.droplet_height(0), 3.0, "starts above the roof")
	_step(1.5)
	assert_eq(sp.droplet_count(), 0)
	assert_gt(sp.pool_count(), 0)
	var origin_y: float = (ISO * (at * 16.0)).y
	for i in sp.pool_count():
		# On the roof the pool is drawn 3 units (48 px) up from where the same spot on the street would be.
		assert_almost_eq(sp.pool_screen(i).y, origin_y - 48.0, 24.0, "on the rooftop, not the street below")


func test_a_droplet_thrown_off_a_roofs_edge_lands_on_the_street_below() -> void:
	var at := Vector2(-60, -67.0)  # just inside roof-nw-3's south edge (y -66)
	var sp: Node2D = load("res://scripts/enemies/minion_spill.gd").new()
	add_child_autofree(sp)
	sp.ground = run.elevation.ground_height
	var s := {"droplet_speed_min": 6.0, "droplet_speed_max": 6.0, "droplet_up_min": 1.0, "droplet_up_max": 1.0, "droplet_gravity": 24.0}
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	sp.burst(at, 3.3, 40, s, rng)
	for i in 100:
		sp.step(DT)
	assert_eq(sp.droplet_count(), 0)
	var low := 0
	var high := 0
	for i in sp.pool_count():
		var back: float = sp.pool_screen(i).y
		if back > (ISO * (at * 16.0)).y - 24.0:
			low += 1
		else:
			high += 1
	assert_gt(low, 0, "some landed on the street")
	assert_gt(high, 0, "some on the roof")


# --- Knocks, the timer and the fade ---------------------------------------------------

func test_the_car_knocks_a_corpse_away_and_restarts_the_timer() -> void:
	_place_car(Vector2(18.9, 10), Vector2.ZERO)
	var m := _kill_at(Vector2(20, 10))
	_step(1.5)
	assert_lt(m.corpse_timer, 0.6, "a parked car does not hit it: the timer runs down")
	assert_eq(m.position_units().x, 20.0, "and does not move it")
	var x0: float = m.position_units().x
	_place_car(Vector2(18.9, 10), Vector2(12, 0))
	_step(DT)
	assert_gt(m.corpse_timer, 1.9, "the hit restarted the 2 s")
	_step(0.6)
	assert_gt(m.position_units().x, x0 + 1.0, "pushed away from the car")
	assert_almost_eq(m.position_units().y, 10.0, 0.5, "straight away")
	assert_lte(m.position_units().x - x0, float(death["knock_car_max"]) + 0.2)


func test_a_stopped_car_does_not_keep_a_corpse_alive() -> void:
	_place_car(Vector2(18.9, 10), Vector2.ZERO)
	var m := _kill_at(Vector2(20, 10))
	_step(2.1)
	assert_true(m.corpse_fade_left >= 0.0, "fading")


func test_after_two_seconds_with_no_hit_the_corpse_and_its_liquid_fade_and_are_freed() -> void:
	var m := _kill_at(Vector2(30, 30))
	var sp: Node2D = corpses.spills[0]["node"]
	_step(1.9)
	assert_eq(m.corpse_alpha(), 1.0, "whole at 1.9 s")
	assert_false(sp.is_fading())
	_step(0.2)
	assert_lt(m.corpse_alpha(), 1.0, "fading after 2 s")
	assert_true(sp.is_fading(), "the liquid fades with it")
	assert_lt(sp.modulate.a, 1.0)
	_step(float(death["fade_seconds"]) + 0.1)
	await wait_process_frames(2)
	assert_false(is_instance_valid(m), "freed")
	assert_false(is_instance_valid(sp), "its liquid freed")
	assert_eq(corpses.corpse_count(), 0)
	assert_eq(corpses.spills.size(), 0)


func test_every_hit_restarts_the_two_seconds_even_while_fading() -> void:
	var m := _kill_at(Vector2(30, 30))
	_step(1.9)
	m.knock_corpse(Vector2.RIGHT, 1.0)
	_step(1.9)
	assert_true(is_instance_valid(m))
	assert_eq(m.corpse_alpha(), 1.0, "still whole")
	_step(0.2)
	assert_lt(m.corpse_alpha(), 1.0)
	m.knock_corpse(Vector2.RIGHT, 1.0)
	assert_eq(m.corpse_alpha(), 1.0, "a hit while it fades brings it back whole")


func test_a_knocked_corpse_slides_slowing_to_rest_and_stops_at_a_wall() -> void:
	var m := _kill_at(Vector2(30, 30))
	var x0: float = m.position_units().x
	m.knock_corpse(Vector2.RIGHT, 4.0)
	_step(0.1)
	var x1: float = m.position_units().x
	_step(0.1)
	var x2: float = m.position_units().x
	assert_gt(x1, x0)
	assert_lt(x2 - x1, x1 - x0, "slowing down")
	_step(1.0)
	assert_almost_eq(m.position_units().x - x0, 4.0, 0.3, "slid the knock's distance")
	assert_false(m.is_sliding())


func test_the_bricks_wave_knocks_corpses_and_restarts_their_timer() -> void:
	var rack = run.weapons
	_place_car(Vector2(10, 10))
	var m := _kill_at(Vector2(12, 10))
	_step(1.0)
	var t0: float = m.corpse_timer
	rack.bricks.set_tier(1)
	rack.bricks.send_wave(Vector2(10, 10))
	assert_gt(m.corpse_timer, t0, "restarted")
	_step(0.8)
	assert_almost_eq(m.position_units().x - 12.0, rack.bricks.stats["knockback_distance"] * death["knock_scale_bricks"], 0.4, "knocked")
	assert_true(m.is_corpse(), "and it stays a corpse, unhurt")


func test_the_shock_of_the_polarized_steering_wheel_knocks_corpses() -> void:
	_place_car(Vector2(10, 10))
	var m := _kill_at(Vector2(12, 10))
	_step(1.0)
	var t0: float = m.corpse_timer
	run.polarized_shock.send(Vector2(10, 10), 1)
	assert_gt(m.corpse_timer, t0)
	_step(0.8)
	assert_gt(m.position_units().x, 12.0 + 3.0, "pushed")


func test_the_wiper_knocks_corpses_it_sweeps() -> void:
	var rack = run.weapons
	_place_car(Vector2(10, 10))
	assert_true(rack.upgrade("wiper"))
	var w = rack.wiper
	var ahead: Vector2 = w.pivot_units() + w.forward() * 1.5
	var m := _kill_at(ahead)
	var p0: Vector2 = m.position_units()
	for i in 200:
		w.step(DT)
		corpses.step(DT, run.car, Rect2())
		if m.position_units().distance_to(p0) > 1.0:
			break
	assert_gt(m.position_units().distance_to(p0), 1.0, "the arm pushed it")
	assert_gt(m.corpse_timer, 1.0, "and restarted its timer")


func test_other_weapons_do_not_push_corpses() -> void:
	var m := _kill_at(Vector2(30, 30))
	assert_false(m.knock_by_weapon(Vector2.RIGHT, 4.0, "underglow"), "the underglow's ticks would pin a corpse forever")
	assert_false(m.knock_by_weapon(Vector2.RIGHT, 4.0, "gun"))
	assert_true(m.knock_by_weapon(Vector2.RIGHT, 4.0, "bricks"))


# --- A corpse is no enemy ---------------------------------------------------------------

func test_a_corpse_never_damages_the_car_is_never_targeted_and_blocks_nobody() -> void:
	_place_car(Vector2(10, 10))
	var m := _kill_at(Vector2(10.5, 10))
	var hearts: float = run.state.health
	spawner.enabled = true
	spawner.visible_rect_override = Rect2(-100000, -100000, 200000, 200000)
	for i in 10:
		spawner.move_step(DT)
	assert_false(m.contact_step(DT, run.car, run.state), "no contact damage")
	assert_eq(run.state.health, hearts, "the car is unhurt")
	var rack = run.weapons
	assert_false(rack.is_target(m))
	assert_false(rack.living_enemies().has(m))
	assert_true(rack.corpses().has(m), "but the knockback weapons find it")
	assert_eq(m.collision_layer, 0)
	assert_eq(m.collision_mask, 1, "it stops at walls")
	var other: Node = spawner.spawn_minion_at(Vector2(10.5, 10))
	assert_eq(other.collision_mask & m.collision_layer, 0, "no minion collides with a corpse")


func test_nothing_but_the_corpse_list_holds_a_corpse_and_a_new_run_clears_them() -> void:
	_kill_at(Vector2(30, 30))
	_kill_at(Vector2(32, 30))
	assert_eq(corpses.corpse_count(), 2)
	spawner.clear()
	assert_eq(corpses.corpse_count(), 0)
	assert_eq(corpses.spills.size(), 0)


# --- The caps -----------------------------------------------------------------------------

func test_the_caps_hold_under_a_mass_death() -> void:
	var cap := int(death["max_corpses"])
	for i in 200:
		_kill_at(Vector2(20 + (i % 20) * 1.2, 20 + (i / 20) * 1.2))
		assert_lte(corpses.corpse_count(), 2 * cap, "never more than twice the cap")
		assert_lte(corpses.whole_corpse_count(), cap, "never more whole corpses than the cap")
		assert_lte(corpses.droplet_count(), int(death["max_droplets"]), "droplet cap")
	for i in 150:
		corpses.step(DT, run.car, Rect2())
		assert_lte(corpses.droplet_count(), int(death["max_droplets"]))
		assert_lte(corpses.pool_count(), int(death["max_pools"]), "pool cap")
	assert_lte(corpses.whole_corpse_count(), cap)
	_step(2.6)
	await wait_process_frames(2)
	assert_eq(corpses.corpse_count(), 0, "all gone after their time")
	assert_eq(corpses.spills.size(), 0)


func test_the_oldest_corpse_fades_first_when_the_cap_is_passed() -> void:
	var cap := int(death["max_corpses"])
	var first := _kill_at(Vector2(40, 40))
	for i in cap:
		_kill_at(Vector2(41 + i * 1.1, 40))
	assert_gte(first.corpse_fade_left, 0.0, "the oldest is fading")
	assert_eq(corpses.whole_corpse_count(), cap)


func test_a_corpse_far_off_the_screen_is_freed() -> void:
	var m := _kill_at(Vector2(30, 30))
	corpses.step(DT, run.car, Rect2(-10, -10, 20, 20))
	await wait_process_frames(2)
	assert_false(is_instance_valid(m))


func test_with_corpses_off_a_dead_minion_is_freed_as_before() -> void:
	corpses.enabled = false
	var m: Node = spawner.spawn_minion_at(Vector2(30, 30))
	m.take_damage(100000.0)
	assert_false(m.is_corpse())
	await wait_process_frames(2)
	assert_false(is_instance_valid(m))
