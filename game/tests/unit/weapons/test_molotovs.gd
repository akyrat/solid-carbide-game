extends GutTest
## Task T-169: the molotovs. Thrown from the car at random every throw interval,
## landing between the data's distances, each leaves a fire area of the data's
## radius that burns enemies only while they are inside, for the data's
## duration, times the garage damage multiplier. Tiers 2 to 8, pause, a new
## run, the target rules, the playtest switch and the placeholder look.

const RunScene := preload("res://scenes/run/run.tscn")
const FakeEnemy := preload("res://tests/fixtures/weapons/fake_enemy.gd")
const FakeBigEnemy := preload("res://tests/fixtures/weapons/fake_big_enemy.gd")
const Molotovs := preload("res://scripts/weapons/molotovs.gd")
const Fire := preload("res://scripts/weapons/molotov_fire.gd")
const Glow := preload("res://scripts/weapons/neon_underglow.gd")
const Flame := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const DT := 0.02  # one physics step (50 per second)
## Redgull red (Hud.HEART_COLOR) and the logo's red: placeholders never use them.
const REDGULL_REDS := [Color(0.86, 0.1, 0.16), Color8(135, 17, 27)]

var run: Node2D
var rack: Node
var mol
var data: WeaponData


func before_each() -> void:
	Molotovs.playtest_override = 0
	Glow.playtest_override = 0
	Flame.playtest_override = 0
	data = WeaponData.new()
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	run.car.use_keyboard = false
	rack = run.weapons
	rack.gun.set_tier(0)  # the gun's bullets would hit the test enemies too
	mol = rack.molotov
	mol.rng.seed = 12345


func after_each() -> void:
	Molotovs.playtest_override = -1
	Glow.playtest_override = -1
	Flame.playtest_override = -1
	get_tree().paused = false


func _step(steps: int) -> void:
	for i in steps:
		rack.step(DT)


func _steps_for(seconds: float) -> int:
	return int(ceil(seconds / DT - 1e-6))  # the first whole step at or past `seconds`


func _enemy_at(units: Vector2, big := false) -> Node2D:
	var e: Node2D = FakeBigEnemy.new() if big else FakeEnemy.new()
	e.position = units * 16.0
	run.add_child(e)
	return e


func _car_units() -> Vector2:
	return run.car.model.get_position()


## A fire area put down by hand at `units` with the current tier's values.
func _fire_at(units: Vector2) -> Node:
	return mol.land(units)


func _fires() -> Array:
	return rack.projectiles.filter(func(p) -> bool: return is_instance_valid(p) and p is Fire)


func _bottles() -> Array:
	return rack.projectiles.filter(func(p) -> bool: return is_instance_valid(p) and p is Molotovs.MolotovBottle)


# --- Owning it and throwing ------------------------------------------------------

func test_a_new_run_has_no_molotovs_and_upgrade_gives_them() -> void:
	assert_true(Molotovs in rack.WEAPON_SCRIPTS, "listed in WEAPON_SCRIPTS")
	assert_eq(rack.get_weapon("molotov"), mol)
	assert_eq(mol.weapon_id, "molotov")
	assert_false(mol.starts_owned)
	assert_eq(mol.tier, 0, "not owned at the start of a run")
	assert_false("molotov" in rack.owned_ids())
	_step(_steps_for(10.0))
	assert_eq(mol.bottles, 0, "not owned: nothing thrown")
	assert_true(rack.projectiles.is_empty())
	assert_true(rack.upgrade("molotov"), "the level-up's call gives them")
	assert_eq(mol.tier, 1)
	assert_true("molotov" in rack.owned_ids())


func test_seeded_throw_at_the_interval_lands_in_range_and_makes_a_fire_of_the_radius() -> void:
	rack.upgrade("molotov")
	var s: Dictionary = data.molotov_at(1)
	var start := _car_units()
	var landings := []
	mol.thrown.connect(func(_b, at: Vector2) -> void: landings.append(at))
	var interval_steps := _steps_for(s["throw_interval"])
	_step(interval_steps - 1)
	assert_eq(landings.size(), 0, "nothing before the throw interval")
	_step(1)
	assert_eq(landings.size(), int(s["molotovs_per_throw"]), "thrown at the interval")
	assert_eq(_bottles().size(), 1, "a bottle in flight")
	var at: Vector2 = landings[0]
	var d := at.distance_to(start)
	assert_between(d, float(s["throw_distance_min"]) - 1e-6, float(s["throw_distance_max"]) + 1e-6,
		"lands %.2f units away" % d)
	assert_eq(_fires().size(), 0, "no fire while the bottle flies")
	_step(_steps_for(Molotovs.FLIGHT_SECONDS))
	assert_eq(_bottles().size(), 0, "the bottle has landed")
	var fires := _fires()
	assert_eq(fires.size(), 1, "one fire area")
	var f = fires[0]
	assert_almost_eq(f.centre.x, at.x, 1e-6, "where the bottle landed")
	assert_almost_eq(f.centre.y, at.y, 1e-6)
	assert_almost_eq(f.radius, float(s["fire_radius"]), 1e-9, "the data's radius")
	assert_almost_eq(f.duration, float(s["fire_duration"]), 1e-9, "the data's duration")
	# The next throw comes one interval after the last.
	_step(interval_steps - _steps_for(Molotovs.FLIGHT_SECONDS) - 1)
	assert_eq(landings.size(), 1)
	_step(1)
	assert_eq(landings.size(), 2, "the second throw one interval later")


func test_landing_spots_are_random_around_the_car_within_the_distances() -> void:
	rack.upgrade("molotov")
	var s: Dictionary = data.molotov_at(1)
	var c := _car_units()
	var angles := []
	for i in 200:
		var p: Vector2 = mol.random_landing()
		var d := p.distance_to(c)
		assert_true(d >= float(s["throw_distance_min"]) - 1e-6 and d <= float(s["throw_distance_max"]) + 1e-6,
			"spot %d at %.2f units" % [i, d])
		angles.append((p - c).angle())
	# Every quarter around the car gets some.
	for q in 4:
		var lo := -PI + q * PI / 2.0
		assert_gt(angles.filter(func(a) -> bool: return a >= lo and a < lo + PI / 2.0).size(), 10,
			"quarter %d gets throws" % q)


func test_the_same_seed_gives_the_same_spots() -> void:
	rack.upgrade("molotov")
	mol.rng.seed = 99
	var a := [mol.random_landing(), mol.random_landing(), mol.random_landing()]
	mol.rng.seed = 99
	var b := [mol.random_landing(), mol.random_landing(), mol.random_landing()]
	assert_eq(a, b)


# --- Damage ------------------------------------------------------------------------

func test_enemy_inside_burns_with_the_datas_damage_times_the_garage_multiplier() -> void:
	rack.set_damage_bonus(25.0)
	rack.upgrade("molotov")
	var s: Dictionary = data.molotov_at(1)
	var want: float = s["damage"] * rack.damage_multiplier()
	assert_almost_eq(want, 2.5, 1e-9, "2 x 1.25")
	var spot := _car_units() + Vector2(5.0, 0.0)
	var r: float = s["fire_radius"]
	var inside := _enemy_at(spot + Vector2(r - 0.2, 0.0))
	var outside := _enemy_at(spot + Vector2(0.0, r + 0.3))
	_fire_at(spot)
	_step(1)
	assert_eq(inside.damage_taken.size(), 1, "hit on the first step inside")
	assert_almost_eq(float(inside.damage_taken[0]), want, 1e-9, "data damage x garage multiplier")
	var tick := _steps_for(s["tick_interval"])
	_step(tick - 1)
	assert_eq(inside.damage_taken.size(), 1, "no second hit before the tick interval")
	_step(1)
	assert_eq(inside.damage_taken.size(), 2, "again after the tick interval")
	_step(tick * 2)
	assert_eq(inside.damage_taken.size(), 4, "one per tick interval")
	for a in inside.damage_taken:
		assert_almost_eq(float(a), want, 1e-9)
	assert_eq(outside.damage_taken.size(), 0, "outside: no damage")
	rack.set_damage_bonus(0.0)


## The board's answer (2026-10-18): an enemy burns only while it is inside.
func test_an_enemy_that_leaves_takes_no_more_damage() -> void:
	rack.upgrade("molotov")
	var s: Dictionary = data.molotov_at(1)
	var spot := _car_units() + Vector2(-5.0, 0.0)
	var e := _enemy_at(spot)
	_fire_at(spot)
	_step(1)
	assert_eq(e.damage_taken.size(), 1)
	e.position = (spot + Vector2(float(s["fire_radius"]) + 0.5, 0.0)) * 16.0  # walks out
	_step(_steps_for(s["fire_duration"]))
	assert_eq(e.damage_taken.size(), 1, "no burning after it has left")
	assert_false(BurnFlames.is_burning(e), "T-071: no flames after it has left")


## T-071: an enemy in a fire area has flames on it, and only while it is inside.
func test_an_enemy_in_the_fire_has_flames_until_it_leaves_or_the_fire_ends() -> void:
	rack.upgrade("molotov")
	var s: Dictionary = data.molotov_at(1)
	var spot := _car_units() + Vector2(-5.0, 0.0)
	var e := _enemy_at(spot)
	_fire_at(spot)
	_step(1)
	assert_true(BurnFlames.is_burning(e), "flames while inside")
	e.position = (spot + Vector2(float(s["fire_radius"]) + 0.5, 0.0)) * 16.0
	_step(1)
	assert_false(BurnFlames.is_burning(e), "flames out when it leaves")
	e.position = spot * 16.0
	_step(1)
	assert_true(BurnFlames.is_burning(e), "back in")
	_step(_steps_for(s["fire_duration"]) + 2)
	assert_false(BurnFlames.is_burning(e), "flames out when the fire ends")


func test_big_enemy_burns_when_its_body_overlaps_the_fire() -> void:
	rack.upgrade("molotov")
	var r: float = data.molotov_at(1)["fire_radius"]
	var spot := _car_units() + Vector2(0.0, 6.0)
	var big := _enemy_at(spot + Vector2(r + 2.0, 0.0), true)
	big.radius_units = 3.0
	var small := _enemy_at(spot + Vector2(-(r + 2.0), 0.0))
	_fire_at(spot)
	_step(1)
	assert_eq(big.damage_taken.size(), 1, "body overlapping: burns")
	assert_eq(small.damage_taken.size(), 0, "centre outside: does not")


func test_it_burns_a_real_minion() -> void:
	rack.upgrade("molotov")
	var spot := _car_units() + Vector2(5.0, 0.0)
	var m: Node = run.minions.spawn_minion_at(spot)
	var health: float = m.health
	_fire_at(spot)
	_step(1)
	assert_almost_eq(m.health, health - data.molotov_at(1)["damage"], 1e-9)


# --- Duration, pause, end of run, new run ------------------------------------------

func test_a_fire_area_goes_out_after_its_duration() -> void:
	rack.upgrade("molotov")
	var s: Dictionary = data.molotov_at(1)
	var spot := _car_units() + Vector2(5.0, 0.0)
	var f = _fire_at(spot)
	_step(_steps_for(s["fire_duration"]))
	assert_true(is_instance_valid(f) and not f.is_done(), "still burning at its duration")
	_step(1)
	assert_false(f in rack.projectiles, "gone just after its duration")
	var e := _enemy_at(spot)
	_step(10)
	assert_eq(e.damage_taken.size(), 0, "a fire that went out burns nothing")


func test_fires_and_bottles_stop_while_paused() -> void:
	rack.upgrade("molotov")
	var spot := _car_units() + Vector2(5.0, 0.0)
	var f = _fire_at(spot)
	var b = mol.throw_to(_car_units() + Vector2(0.0, 5.0))
	var e := _enemy_at(spot)
	var clock: float = mol.throw_clock
	get_tree().paused = true
	await wait_physics_frames(10)
	assert_eq(f.age, 0.0, "the fire's clock stops")
	assert_eq(b.age, 0.0, "the bottle stops in the air")
	assert_eq(mol.throw_clock, clock, "no throws while paused")
	assert_eq(e.damage_taken.size(), 0, "no burning while paused")
	get_tree().paused = false
	await wait_physics_frames(2)
	assert_gt(f.age, 0.0, "goes on with the run")
	assert_gt(e.damage_taken.size(), 0)


func test_nothing_after_the_run_ends() -> void:
	rack.upgrade("molotov")
	var spot := _car_units() + Vector2(5.0, 0.0)
	var f = _fire_at(spot)
	run.state.damage_car(1e9)
	assert_false(run.state.is_running())
	var e := _enemy_at(spot)
	_step(_steps_for(10.0))
	assert_eq(e.damage_taken.size(), 0)
	assert_eq(f.age, 0.0)
	assert_eq(mol.bottles, 0, "no throws once the run is over")


func test_a_new_run_removes_fires_bottles_and_the_molotovs() -> void:
	rack.upgrade("molotov")
	mol.set_tier(5)
	var f = _fire_at(_car_units() + Vector2(5.0, 0.0))
	var b = mol.throw_to(_car_units() + Vector2(0.0, 5.0))
	run.start_run()
	await get_tree().process_frame
	assert_eq(rack.molotov, mol, "the same node, kept by the rack")
	assert_eq(mol.tier, 0, "not owned in the new run")
	assert_eq(rack.owned_ids(), ["gun"])
	assert_true(rack.projectiles.is_empty(), "no projectiles")
	assert_false(is_instance_valid(f), "the fire area is freed")
	assert_false(is_instance_valid(b), "the bottle is freed")
	assert_eq(mol.throws, 0)
	assert_eq(mol.throw_clock, 0.0)


func test_playtest_switch_gives_them_at_the_start_of_every_run() -> void:
	Molotovs.playtest_override = 1
	run.start_run()
	await get_tree().process_frame
	assert_eq(mol.tier, 1, "switch on: the run starts with them")
	Molotovs.playtest_override = 0
	run.start_run()
	await get_tree().process_frame
	assert_eq(mol.tier, 0, "switch off: without them")


func test_playtest_switch_is_read_from_the_data_file() -> void:
	Molotovs.playtest_override = -1
	var r := GameData.load_file("playtest")
	assert_true(r.ok)
	assert_true(r.data.has("molotov_at_start"))
	assert_false(bool(r.data["molotov_at_start"]), "off: the game's rule")
	assert_eq(Molotovs.playtest_switch_on(), bool(r.data["molotov_at_start"]))


# --- Tiers -----------------------------------------------------------------------------

func test_each_tier_sets_the_datas_values() -> void:
	rack.upgrade("molotov")
	for t in range(1, data.max_tier() + 1):
		mol.set_tier(t)
		assert_eq(mol.stats, data.molotov_at(t), "tier %d values" % t)
	mol.set_tier(1)
	for t in range(2, data.max_tier() + 1):
		assert_true(rack.upgrade("molotov"), "upgrade to tier %d" % t)
	assert_false(rack.upgrade("molotov"), "no upgrade past the last tier")


func test_tier_2_changes_what_weapons_json_says() -> void:
	_check_tier(2)


func test_tier_3_changes_what_weapons_json_says() -> void:
	_check_tier(3)


func test_tier_4_changes_what_weapons_json_says() -> void:
	_check_tier(4)


func test_tier_5_changes_what_weapons_json_says() -> void:
	_check_tier(5)


func test_tier_6_changes_what_weapons_json_says() -> void:
	_check_tier(6)


func test_tier_7_changes_what_weapons_json_says() -> void:
	_check_tier(7)


func test_tier_8_changes_what_weapons_json_says() -> void:
	_check_tier(8)


const STAT_KEYS := ["damage", "throw_interval", "molotovs_per_throw", "fire_radius", "fire_duration"]


## Applies tier `want` from code and checks the change weapons.json's tier list
## gives it (read from the file, not hard-coded), then plays it.
func _check_tier(want: int) -> void:
	var found := false
	for entry in data.tiers("molotov"):
		if int(entry["tier"]) != want:
			continue
		found = true
		var effect := String(entry["effect"])
		var value := float(entry["value"])
		var key: String = {
			"fire_radius_multiplier": "fire_radius",
			"throw_interval_multiplier": "throw_interval",
			"damage_multiplier": "damage",
			"add_molotovs": "molotovs_per_throw",
			"add_fire_duration_seconds": "fire_duration",
		}.get(effect, "")
		assert_ne(key, "", "tier %d effect %s is known" % [want, effect])
		rack.upgrade("molotov")
		mol.set_tier(want - 1)
		var before: Dictionary = mol.stats.duplicate()
		mol.set_tier(want)
		assert_eq(mol.tier, want)
		var expected: float = float(before[key]) + value if effect.begins_with("add_") else float(before[key]) * value
		assert_almost_eq(float(mol.stats[key]), expected, 1e-9, "tier %d: %s %s %s" % [want, key, effect, value])
		for other in STAT_KEYS:
			if other != key:
				assert_almost_eq(float(mol.stats[other]), float(before[other]), 1e-9,
					"tier %d leaves %s alone" % [want, other])
		_check_tier_in_play(want, key)
	assert_true(found, "weapons.json has a molotov tier %d" % want)


## Plays the tier: its throws, fire areas and burns carry the new value.
func _check_tier_in_play(t: int, key: String) -> void:
	var s: Dictionary = mol.stats
	match key:
		"fire_radius", "fire_duration", "damage":
			var spot := _car_units() + Vector2(5.0, 0.0)
			var e := _enemy_at(spot)
			var f = _fire_at(spot)
			_step(1)
			assert_almost_eq(f.radius, float(s["fire_radius"]), 1e-9, "tier %d fire radius" % t)
			assert_almost_eq(f.duration, float(s["fire_duration"]), 1e-9, "tier %d fire duration" % t)
			assert_almost_eq(float(e.damage_taken[0]), float(s["damage"]), 1e-9, "tier %d damage" % t)
		"throw_interval":
			mol.throw_clock = 0.0
			var n: int = mol.throws
			_step(_steps_for(s["throw_interval"]) - 1)
			assert_eq(mol.throws, n, "tier %d: not before %.3f s" % [t, s["throw_interval"]])
			_step(1)
			assert_eq(mol.throws, n + 1, "tier %d: thrown at %.3f s" % [t, s["throw_interval"]])
		"molotovs_per_throw":
			var count := []
			mol.thrown.connect(func(_b, _at) -> void: count.append(1))
			mol.throw_clock = 0.0
			_step(_steps_for(s["throw_interval"]))
			assert_eq(count.size(), int(s["molotovs_per_throw"]), "tier %d: bottles per throw" % t)


func test_damage_bonus_multiplies_every_tier() -> void:
	rack.upgrade("molotov")
	rack.set_damage_bonus(50.0)
	for t in range(1, data.max_tier() + 1):
		mol.set_tier(t)
		assert_almost_eq(float(mol.stats["damage"]), data.molotov_at(t)["damage"] * 1.5, 1e-9)
	rack.set_damage_bonus(0.0)


# --- The placeholder look ------------------------------------------------------------

func test_fire_is_drawn_on_the_ground_and_the_bottle_in_the_air() -> void:
	rack.upgrade("molotov")
	var spot := _car_units() + Vector2(5.0, 2.0)
	var b = mol.throw_to(spot)
	assert_eq(b.get_parent(), rack.draw_root, "the bottle with the shots")
	_step(_steps_for(Molotovs.FLIGHT_SECONDS / 2.0))
	assert_gt(b.height_units(), Molotovs.THROW_HEIGHT_UNITS, "up in an arc mid-flight")
	_step(_steps_for(Molotovs.FLIGHT_SECONDS))
	var f = _fires()[0]
	var root: Node = f.get_parent()
	assert_eq(root.name, Molotovs.FIRE_ROOT_NAME)
	assert_eq(root.get_parent(), run.map.view_root, "in the map's drawing (on the ground)")
	assert_eq(root.get_index(), run.drift_marks.get_index() + 1, "just after the drift marks")
	assert_almost_eq(f.position.x, spot.x * 16.0, 1e-4, "at the landing spot (flat pixels, the view makes it isometric)")
	assert_almost_eq(f.position.y, spot.y * 16.0, 1e-4)
	# A second fire goes in the same node.
	var f2 = _fire_at(spot + Vector2(1, 0))
	assert_eq(f2.get_parent(), root)


func test_placeholder_colours_are_opaque_and_not_redgull_red() -> void:
	rack.upgrade("molotov")
	var b = mol.throw_to(_car_units() + Vector2(4.0, 0.0))
	var f = _fire_at(_car_units() + Vector2(-4.0, 0.0))
	var colours: Array = b.colours() + f.colours()
	for c in colours:
		assert_eq(c.a, 1.0, "no see-through pixels")
		for red in REDGULL_REDS:
			var dh := absf(c.h - red.h)
			assert_gt(minf(dh, 1.0 - dh) * 360.0, 25.0, "colour %s hue far from Redgull red" % c)
		assert_true(c.g > 0.3 or c.s < 0.6, "colour %s is not a strong red" % c)
