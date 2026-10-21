extends GutTest
## Task T-042: the exhaust flamethrower. On only while drifting (and the
## linger after), damaging enemies inside its area as weapons.json describes,
## the upgrade tiers, a new run starting without it, the playtest switch and
## the placeholder drawing, and its place in the weapon rack (run.weapons, T-041).

const RunScene := preload("res://scenes/run/run.tscn")
const FakeEnemy := preload("res://tests/fixtures/weapons/fake_enemy.gd")
const FakeBigEnemy := preload("res://tests/fixtures/weapons/fake_big_enemy.gd")
const Flame := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const CarTuning := preload("res://scripts/driving/car_tuning.gd")
const DT := 0.02  # one physics step (50 per second)
## Redgull red (Hud.HEART_COLOR): placeholders never use it.
const REDGULL_RED := Color(0.86, 0.1, 0.16)

var run: Node2D
var rack: Node
var flame
var data: WeaponData


func before_each() -> void:
	Flame.playtest_override = 0  # runs start without it unless a test gives it
	data = WeaponData.new()
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	run.car.use_keyboard = false
	rack = run.weapons
	rack.gun.set_tier(0)  # the gun's bullets would hit the test enemies too
	flame = rack.flamethrower
	assert_true(rack.upgrade("flamethrower"), "the level-up's call gives it")


func after_each() -> void:
	Flame.playtest_override = -1
	get_tree().paused = false


## The car stands at the map's centre, nose along -y; "behind" is +y.
## Sets its drift state by hand (moving fast enough, or not drifting) and steps
## only the flamethrower, so the car does not move.
func _hold(drifting: bool, steps: int) -> void:
	run.car.model.is_drifting = drifting
	run.car.model.vx = 5.0 if drifting else 0.0
	run.car.model.vy = 0.0
	for i in steps:
		flame.step(DT)


## One car physics step, then the weapons' step (as in a running game).
func _drive(steps: int) -> void:
	for i in steps:
		run.car.physics_step()
		rack.step(DT)


## A test enemy inside the run (the rack only targets the run's own enemies).
func _enemy_at(units: Vector2, big := false) -> Node2D:
	var e: Node2D = FakeBigEnemy.new() if big else FakeEnemy.new()
	e.position = units * 16.0
	run.add_child(e)
	return e


## A point straight behind the car, `back` units from its centre.
func _behind(back: float) -> Vector2:
	return run.car.model.get_position() + Vector2(0.0, back)


## Resets the flamethrower as a new run does, then sets `tier`.
func _fresh(tier: int) -> void:
	flame.reset_for_run()
	flame.set_tier(tier)


# --- On only while drifting ---------------------------------------------

func test_flames_on_only_while_drifting_and_off_after_the_linger() -> void:
	var car = run.car
	# Driving straight: W held, no steering. Never on.
	car.scripted_input = [true, false, 0.0]
	for i in 30:
		_drive(1)
		assert_false(flame.active, "straight driving, step %d: no flame" % i)
	assert_false(flame.flame_drawing.emitting, "no flames drawn")
	# Drifting: W with A. On from the first step.
	car.scripted_input = [true, false, 1.0]
	for i in 20:
		_drive(1)
		assert_true(car.model.is_drifting)
		assert_true(flame.active, "drifting, step %d: flame on" % i)
	assert_true(flame.flame_drawing.emitting, "flames drawn while drifting")
	# Stop drifting: on for the data's linger (0.2 s = 10 steps), then off.
	var linger_steps := int(round(data.flame_at(1)["linger"] / DT))
	car.scripted_input = [true, false, 0.0]
	for i in linger_steps - 1:
		_drive(1)
		assert_true(flame.active, "linger, step %d" % i)
	_drive(1)
	assert_false(flame.active, "off once the linger is over")
	for i in 30:
		_drive(1)
		assert_false(flame.active, "stays off while not drifting")
	assert_false(flame.flame_drawing.emitting, "flames no longer drawn")


func test_steering_while_standing_still_does_not_light_it() -> void:
	run.car.scripted_input = [false, false, 1.0]
	for i in 20:
		_drive(1)
	assert_false(flame.active, "A alone is not a drift")


func test_drifting_slower_than_the_minimum_speed_does_not_light_it() -> void:
	run.car.model.is_drifting = true
	run.car.model.vx = data.flame_at(1)["min_speed"] * 0.5
	flame.step(DT)
	assert_false(flame.active)
	run.car.model.vx = data.flame_at(1)["min_speed"]
	flame.step(DT)
	assert_true(flame.active)


# --- Damage --------------------------------------------------------------

func test_enemy_inside_takes_the_datas_damage_and_one_outside_does_not() -> void:
	var s: Dictionary = data.flame_at(1)
	var inside := _enemy_at(_behind(1.2))
	var in_front := _enemy_at(_behind(-2.0))
	var beside := _enemy_at(_behind(1.2) + Vector2(4.0, 0.0))
	var far_behind := _enemy_at(_behind(s["inner_edge"] + s["area_depth"] + 0.5))
	_hold(true, 1)
	assert_eq(inside.damage_taken, [s["damage"]], "one hit at once on entering")
	# One second of flame: a hit on entering plus one every tick_interval.
	_hold(true, 49)
	var ticks := int(round(1.0 / s["tick_interval"]))
	assert_eq(inside.damage_taken.size(), 1 + ticks, "entering hit + 5 ticks in 1 s")
	for a in inside.damage_taken:
		assert_almost_eq(float(a), float(s["damage"]), 1e-9, "each hit is the data's damage")
	assert_almost_eq(inside.total_damage(), s["damage"] * (1 + ticks), 1e-9)
	assert_eq(in_front.damage_taken.size(), 0, "in front of the car: no damage")
	assert_eq(beside.damage_taken.size(), 0, "beside the area: no damage")
	assert_eq(far_behind.damage_taken.size(), 0, "past the area's far edge: no damage")


## Board, 2026-10-14: an enemy that reports its body size (the kaiju) is burnt
## when its body overlaps the flames; others (minions) only when their centre is in.
func test_big_enemy_is_burnt_when_its_body_overlaps_the_flames() -> void:
	var s: Dictionary = data.flame_at(1)
	_hold(true, 60)  # full size
	var far_edge: float = s["inner_edge"] + s["area_depth"]
	var big := _enemy_at(_behind(far_edge + 2.0), true)
	big.radius_units = 3.0  # centre 2 units past the far edge, body reaching 1 unit in
	var small := _enemy_at(_behind(far_edge + 2.0) + Vector2(0.5, 0.0))  # same spot, no size: centre rule
	var too_far := _enemy_at(_behind(far_edge + 4.0) + Vector2(-0.5, 0.0), true)
	too_far.radius_units = 3.0  # body stops 1 unit short of the flames
	assert_false(flame.contains_point(big.position_units()), "the big one's centre is outside")
	_hold(true, 1)
	assert_eq(big.damage_taken, [s["damage"]], "body overlapping: the entering hit")
	assert_eq(small.damage_taken.size(), 0, "no size reported: centre outside, no damage")
	assert_eq(too_far.damage_taken.size(), 0, "body not reaching the flames: no damage")
	_hold(true, int(round(s["tick_interval"] / DT)))
	assert_eq(big.damage_taken.size(), 2, "and the ticks")


## T-170: of the weapons only the wiper pushes; the flamethrower never moves an
## enemy (Weapons, Decisions), a real minion or one recording every push.
func test_flame_never_moves_an_enemy() -> void:
	var real: Node = run.minions.spawn_minion_at(_behind(1.2) + Vector2(0.4, 0.0))
	real.max_health = 1000.0
	real.health = 1000.0
	var fake: Node2D = preload("res://tests/fixtures/weapons/fake_minion.gd").new()
	fake.position = (_behind(1.2) + Vector2(-0.4, 0.0)) * 16.0
	run.add_child(fake)
	var real_at: Vector2 = real.position
	var fake_at: Vector2 = fake.position
	_hold(true, 50)
	assert_lt(real.health, 1000.0, "the real minion was burnt")
	assert_gt(fake.damage_taken.size(), 0, "the recording one was burnt")
	assert_false(real.is_knocked_back(), "no push on the real minion")
	assert_eq(real.position, real_at, "the real minion did not move")
	assert_eq(fake.pushes, [], "no knockback call")
	assert_eq(fake.position, fake_at, "did not move")


func test_no_damage_while_not_drifting() -> void:
	var e := _enemy_at(_behind(1.2))
	_hold(false, 50)
	assert_eq(e.damage_taken.size(), 0)


func test_flame_grows_from_half_to_full_size_over_the_ramp() -> void:
	var s: Dictionary = data.flame_at(1)
	var half_reach: float = s["inner_edge"] + s["area_depth"] * s["ramp_start_fraction"]
	var full_reach: float = s["inner_edge"] + s["area_depth"]
	var e := _enemy_at(_behind((half_reach + full_reach) / 2.0))
	_hold(true, 1)
	assert_eq(e.damage_taken.size(), 0, "out of reach at the start of the drift")
	assert_almost_eq(flame.size_fraction(), 0.5, 0.03)
	_hold(true, int(round(s["ramp_seconds"] / DT)))
	assert_almost_eq(flame.size_fraction(), 1.0, 1e-9, "full size after the ramp")
	assert_gt(e.damage_taken.size(), 0, "reached once the flame has grown")


func test_area_is_the_same_size_whichever_way_the_car_faces() -> void:
	_hold(true, 60)
	var straight: Dictionary = flame.area()
	run.car.model.rotation = PI / 4.0
	_hold(true, 1)
	assert_eq(flame.area(), straight, "the fix: no diagonal growth")


func test_flame_kills_a_real_minion() -> void:
	var m: Node = run.minions.spawn_minion_at(_behind(1.2))
	var health: float = m.health
	var s: Dictionary = data.flame_at(1)
	_hold(true, 1)
	assert_almost_eq(m.health, health - s["damage"], 1e-9, "the minion took the entering hit")
	var steps := int(round(s["tick_interval"] / DT)) - 1
	_hold(true, steps)
	assert_true(m.is_dead(), "4 health: dead after the entering hit and one tick")


func test_entering_hit_flashes_the_enemy_for_the_burn_time() -> void:
	var s: Dictionary = data.flame_at(1)
	var e := _enemy_at(_behind(1.2))
	_hold(true, 1)
	assert_true(flame.is_burning(e))
	assert_eq(e.sprite.modulate, flame.burn_tint, "orange tint")
	assert_true(BurnFlames.is_burning(e), "T-071: the flames are drawn on it")
	_hold(false, int(round(s["burn_flash_seconds"] / DT)) + 1)
	assert_false(flame.is_burning(e))
	assert_eq(e.sprite.modulate, Color.WHITE, "tint back to normal")
	assert_false(BurnFlames.is_burning(e), "T-071: and the flames go with the flash")


func test_paused_game_stops_the_flame() -> void:
	var e := _enemy_at(_behind(1.2))
	run.car.scripted_input = [true, false, 1.0]
	get_tree().paused = true
	await wait_physics_frames(10)
	assert_eq(e.damage_taken.size(), 0, "no damage while paused")
	assert_false(flame.active)


# --- Upgrade tiers -------------------------------------------------------

func test_each_tier_sets_the_datas_values() -> void:
	for t in range(1, data.max_tier() + 1):
		flame.set_tier(t)
		assert_eq(flame.tier, t)
		assert_eq(flame.stats, data.flame_at(t), "tier %d values" % t)
	_fresh(1)
	for t in range(2, data.max_tier() + 1):
		assert_true(flame.upgrade(), "upgrade to tier %d" % t)
		assert_eq(flame.stats, data.flame_at(t))
	assert_false(flame.upgrade(), "no upgrade past the last tier")
	assert_true(flame.is_max_tier())


## Tiers 2, 4 and 6 (bigger plume): an enemy just past the last tier's full
## reach is burnt only after the upgrade.
func test_size_tiers_reach_further() -> void:
	for t in [2, 4, 6]:
		var before: Dictionary = data.flame_at(t - 1)
		var after: Dictionary = data.flame_at(t)
		assert_gt(after["area_depth"], before["area_depth"], "tier %d deeper" % t)
		assert_gt(after["area_width"], before["area_width"], "tier %d wider" % t)
		var back: float = before["inner_edge"] + (before["area_depth"] + after["area_depth"]) / 2.0
		for tier_now in [t - 1, t]:
			_fresh(tier_now)
			var e := _enemy_at(_behind(back))
			_hold(true, 60)
			if tier_now == t:
				assert_gt(e.damage_taken.size(), 0, "tier %d reaches %.2f" % [t, back])
			else:
				assert_eq(e.damage_taken.size(), 0, "tier %d does not reach %.2f" % [tier_now, back])
			e.remove_from_group("enemies")
			_hold(false, 20)


func test_tier_3_hotter_flame_deals_more_damage() -> void:
	_fresh(3)
	var e := _enemy_at(_behind(1.2))
	_hold(true, 1)
	var want: float = data.flame_at(3)["damage"]
	assert_gt(want, float(data.flame_at(2)["damage"]))
	assert_almost_eq(float(e.damage_taken[0]), want, 1e-9, "2 x 1.2 = 2.4, not rounded")


func test_tier_5_burn_flash_lasts_longer() -> void:
	var short_s: float = data.flame_at(4)["burn_flash_seconds"]
	var long_s: float = data.flame_at(5)["burn_flash_seconds"]
	assert_gt(long_s, short_s)
	for t in [4, 5]:
		_fresh(t)
		var e := _enemy_at(_behind(1.2))
		_hold(true, 1)
		e.remove_from_group("enemies")
		_hold(false, int(round(short_s / DT)) + 1)
		if t == 4:
			assert_false(flame.is_burning(e), "tier 4: flash over")
		else:
			assert_true(flame.is_burning(e), "tier 5: still flashing")
			_hold(false, int(round((long_s - short_s) / DT)) + 1)
			assert_false(flame.is_burning(e), "tier 5: over after its longer time")


func test_tier_7_steering_makes_the_car_turn_faster() -> void:
	var base: float = run.car.model.tuning.turn_speed
	flame.set_tier(6)
	assert_almost_eq(run.car.model.tuning.turn_speed, base, 1e-9)
	flame.set_tier(7)
	var m: float = data.flame_at(7)["turn_speed_multiplier"]
	assert_almost_eq(run.car.model.tuning.turn_speed, base * m, 1e-9, "turn speed x 1.2")
	flame.set_tier(8)
	assert_almost_eq(run.car.model.tuning.turn_speed, base * m, 1e-9, "applied once")


func test_tier_8_always_on_without_drifting_at_full_size() -> void:
	_fresh(7)
	_hold(false, 1)
	assert_false(flame.active)
	_fresh(8)
	var s: Dictionary = data.flame_at(8)
	var e := _enemy_at(_behind(s["inner_edge"] + s["area_depth"] * 0.95))
	_hold(false, 1)
	assert_true(flame.active, "on without a drift")
	assert_eq(flame.size_fraction(), 1.0, "full size at once")
	assert_eq(e.damage_taken.size(), 1)


# --- A new run -------------------------------------------------------------

func test_a_new_run_starts_without_the_flamethrower() -> void:
	flame.set_tier(7)
	run.car.scripted_input = [true, false, 1.0]
	_drive(5)
	assert_true(flame.flame_drawing.emitting)
	run.start_run()
	await get_tree().process_frame  # the old map and car are freed (no orphans)
	assert_eq(rack.flamethrower, flame, "the same node, kept by the rack")
	assert_eq(flame.tier, 0, "not owned in the new run")
	assert_false(flame.is_owned())
	assert_eq(rack.owned_ids(), ["gun"], "the new run has only the starting gun")
	assert_false(flame.active)
	assert_false(flame.flame_drawing.emitting, "no flames drawn")
	assert_almost_eq(run.car.model.tuning.turn_speed, CarTuning.new().turn_speed, 1e-9,
		"the new car steers at its normal speed")
	rack.gun.set_tier(0)
	var e := _enemy_at(_behind(1.2))
	run.car.scripted_input = [true, false, 1.0]
	_drive(30)
	assert_eq(e.damage_taken.size(), 0, "drifting in the new run burns nothing")
	assert_false(flame.flame_drawing.emitting)


func test_playtest_switch_gives_it_at_the_start_of_every_run() -> void:
	Flame.playtest_override = 1
	flame.set_tier(5)
	run.start_run()
	await get_tree().process_frame  # the old map and car are freed (no orphans)
	assert_eq(flame.tier, 1, "switch on: the run starts with it, at tier 1")
	assert_eq(rack.owned_ids().size(), 2, "the gun and the flamethrower")
	assert_true("flamethrower" in rack.owned_ids())
	Flame.playtest_override = 0
	run.start_run()
	await get_tree().process_frame  # the old map and car are freed (no orphans)
	assert_eq(flame.tier, 0, "switch off: without it")


func test_playtest_switch_is_read_from_the_data_file() -> void:
	Flame.playtest_override = -1
	var r := GameData.load_file("playtest")
	assert_true(r.ok, "data/playtest.json loads through the loader")
	assert_true(r.data is Dictionary, "a dictionary of independent switches")
	assert_true(r.data.has("flamethrower_at_start"))
	assert_eq(Flame.playtest_switch_on(), bool(r.data["flamethrower_at_start"]))


# --- The weapon rack and the drawing ---------------------------------------

func test_it_is_one_of_the_racks_weapons() -> void:
	assert_true(Flame in rack.WEAPON_SCRIPTS, "listed in WEAPON_SCRIPTS")
	assert_eq(rack.get_weapon("flamethrower"), flame)
	assert_eq(flame.weapon_id, "flamethrower")
	assert_false(flame.starts_owned, "not owned at the start (Weapons, Decisions)")
	assert_eq(flame.rack, rack)
	# Stepped by the rack: a drift lights it through rack.step().
	run.car.scripted_input = [true, false, 1.0]
	run.car.physics_step()
	rack.step(DT)
	assert_true(flame.active, "the rack steps it while owned")
	# Not owned: the rack does not step it.
	flame.set_tier(0)
	_drive(5)
	assert_false(flame.active)
	assert_true(flame.upgrade(), "upgrade() from 0 gives it again")
	assert_eq(flame.tier, 1)


func test_drawing_sits_under_the_car_on_its_exhaust() -> void:
	var d: Node2D = flame.flame_drawing
	assert_eq(d.get_parent(), run.view_root, "in the car's drawing")
	assert_lt(d.get_index(), run.car_sprite.get_index(), "drawn under the car")
	run.car.scripted_input = [true, false, 1.0]
	for i in 10:
		_drive(1)
	var rot: float = run.car.model.rotation
	var back := -Vector2(cos(rot), sin(rot))
	var want: Vector2 = Flame.ISO_TRANSFORM * ((run.car.model.get_position() + back * Flame.EXHAUST_OFFSET_UNITS) * 16.0)
	assert_almost_eq(d.position.x, want.x, 0.01)
	assert_almost_eq(d.position.y, want.y, 0.01)
	assert_almost_eq(d.rotation, Flame.ISO_TRANSFORM.basis_xform(back).angle(), 0.001, "pointing back")


func test_flame_art_is_opaque_and_not_redgull_red() -> void:
	var img: Image = flame.flame_drawing.SHEET.get_image()
	assert_eq(img.get_width(), 8 * 224, "8 columns of 224 px cells")
	assert_eq(img.get_height(), 8 * 224, "8 rows: 2 frames x 32 directions")
	var seen := {}
	for y in range(0, img.get_height(), 2):
		for x in range(0, img.get_width(), 2):
			var c := img.get_pixel(x, y)
			assert_true(c.a == 0.0 or c.a == 1.0, "no see-through pixels")
			if c.a == 1.0:
				seen[c] = true
	assert_gt(seen.size(), 5, "the art has its colours")
	for c in seen:
		var dh := absf(c.h - REDGULL_RED.h)
		var near_red: bool = minf(dh, 1.0 - dh) * 360.0 < 15.0 and c.s > 0.5 and c.v < 0.7 and c.v > 0.2
		assert_false(near_red, "colour %s is not Redgull red" % c)


func test_flame_drawing_picks_the_cell_of_its_direction() -> void:
	var D = flame.flame_drawing.get_script()
	assert_eq(D.direction_index(0.0), 0, "pointing right")
	assert_eq(D.direction_index(PI / 2.0), 8, "pointing down the screen")
	assert_eq(D.direction_index(-PI / 2.0), 24, "pointing up the screen")
	assert_eq(D.direction_index(PI), 16)
	assert_eq(D.direction_index(-PI + 0.001), 16, "wraps")
	assert_eq(D.cell_index(5, 0), 5)
	assert_eq(D.cell_index(5, 1), 37, "the second flicker frame")
