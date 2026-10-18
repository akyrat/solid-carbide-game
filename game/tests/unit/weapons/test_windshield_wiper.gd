extends GutTest
## Task T-170: the windshield wiper. One arm in front of the car sweeping back
## and forth across a semicircle, turning with the car. An enemy it hits takes
## the data's damage times the garage damage multiplier; minions are pushed away
## from the car through their knockback call, the kaiju never. Tiers 2 to 8,
## pause and end of run, a new run without it, the playtest switch and the
## placeholder blade.

const RunScene := preload("res://scenes/run/run.tscn")
const FakeEnemy := preload("res://tests/fixtures/weapons/fake_enemy.gd")
const FakeBigEnemy := preload("res://tests/fixtures/weapons/fake_big_enemy.gd")
const FakeMinion := preload("res://tests/fixtures/weapons/fake_minion.gd")
const Wiper := preload("res://scripts/weapons/windshield_wiper.gd")
const Flame := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const Glow := preload("res://scripts/weapons/neon_underglow.gd")
const Molotovs := preload("res://scripts/weapons/molotovs.gd")
const DT := 0.02  # one physics step (50 per second)
## Redgull red (Hud.HEART_COLOR) and the logo's red: placeholders never use them.
const REDGULL_REDS := [Color(0.86, 0.1, 0.16), Color8(135, 17, 27)]

var run: Node2D
var rack: Node
var wiper
var data: WeaponData


func before_each() -> void:
	Wiper.playtest_override = 0
	Flame.playtest_override = 0
	Glow.playtest_override = 0
	Molotovs.playtest_override = 0
	data = WeaponData.new()
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	run.car.use_keyboard = false
	rack = run.weapons
	rack.gun.set_tier(0)  # the gun's bullets would hit the test enemies too
	wiper = rack.wiper


func after_each() -> void:
	Wiper.playtest_override = -1
	Flame.playtest_override = -1
	Glow.playtest_override = -1
	Molotovs.playtest_override = -1
	rack.set_damage_bonus(0.0)
	get_tree().paused = false


## Steps the rack (only the wiper is owned), the car standing still.
func _step(steps: int) -> void:
	for i in steps:
		rack.step(DT)


func _steps_for(seconds: float) -> int:
	return int(ceil(seconds / DT - 1e-6))


## A test enemy at `units` (flat world).
func _place(e: Node2D, units: Vector2) -> Node2D:
	e.position = units * 16.0
	run.add_child(e)
	return e


## A point `d` units straight ahead of the arm's pivot (the middle of the sweep).
func _ahead(d: float) -> Vector2:
	return wiper.pivot_units() + wiper.forward() * d


func _car() -> Vector2:
	return run.car.model.get_position()


## The seconds of one pass (one end to the other) at the wiper's tier now.
func _pass_seconds() -> float:
	return float(wiper.stats["sweep_arc_degrees"]) / float(wiper.stats["sweep_degrees_per_second"])


# --- Owning it -------------------------------------------------------------------

func test_a_new_run_has_no_wiper_and_upgrade_gives_it() -> void:
	assert_true(Wiper in rack.WEAPON_SCRIPTS, "listed in WEAPON_SCRIPTS")
	assert_eq(rack.get_weapon("wiper"), wiper)
	assert_eq(wiper.weapon_id, "wiper")
	assert_false(wiper.starts_owned)
	assert_eq(wiper.tier, 0, "not owned at the start of a run")
	assert_false("wiper" in rack.owned_ids())
	var e := _place(FakeMinion.new(), _ahead(1.0))
	var a0: float = wiper.sweep_angle
	_step(100)
	assert_eq(e.damage_taken.size(), 0, "not owned: no damage")
	assert_eq(wiper.sweep_angle, a0, "not owned: no sweep")
	assert_true(rack.upgrade("wiper"), "the level-up's call gives it")
	assert_eq(wiper.tier, 1)
	assert_true("wiper" in rack.owned_ids())


# --- The sweep -----------------------------------------------------------------------

func test_the_arm_sweeps_back_and_forth_across_a_semicircle_in_front() -> void:
	rack.upgrade("wiper")
	var s: Dictionary = data.wiper_at(1)
	var half: float = s["sweep_arc_degrees"] / 2.0
	assert_almost_eq(half, 90.0, 1e-9, "the semicircle")
	var lo := INF
	var hi := -INF
	var turns := 0
	var last_dir: float = wiper.sweep_dir
	var prev: float = wiper.sweep_angle
	var per_step: float = s["sweep_degrees_per_second"] * DT
	for i in _steps_for(3.0):
		_step(1)
		var a: float = wiper.sweep_angle
		lo = minf(lo, a)
		hi = maxf(hi, a)
		assert_lte(absf(a - prev), per_step + 1e-6, "moves at most the data's speed in a step")
		if wiper.sweep_dir != last_dir:
			turns += 1
			last_dir = wiper.sweep_dir
		prev = a
		# Always in front of the car: the arm never points backwards.
		assert_gte(wiper.arm_direction().dot(wiper.forward()), -1e-6, "step %d: in front" % i)
		assert_gte((wiper.tip_units() - _car()).dot(wiper.forward()), 0.0, "tip ahead of the car's centre")
	assert_almost_eq(lo, -half, per_step, "reaches one end")
	assert_almost_eq(hi, half, per_step, "and the other")
	# 3 s at 240 degrees per second = 720 degrees = 4 passes: it turns back 3 or 4 times.
	assert_between(turns, 3, 4, "back and forth")
	assert_eq(wiper.pass_index, turns)


func test_the_semicircle_turns_with_the_car() -> void:
	rack.upgrade("wiper")
	_step(7)
	var angle: float = wiper.sweep_angle
	var rot0: float = run.car.model.rotation
	var tip0: Vector2 = wiper.tip_units() - _car()
	run.car.model.rotation = rot0 + PI / 3.0
	var tip1: Vector2 = wiper.tip_units() - _car()
	assert_eq(wiper.sweep_angle, angle, "the sweep angle is the car's own")
	assert_almost_eq(tip1.angle_to(tip0), -PI / 3.0, 1e-6, "the tip turned with the car")
	assert_almost_eq(tip1.length(), tip0.length(), 1e-6)
	assert_almost_eq(wiper.forward().angle_to(Vector2(cos(rot0 + PI / 3.0), sin(rot0 + PI / 3.0))), 0.0, 1e-6)
	# Sweeping on, it stays in front of the turned car.
	for i in 60:
		_step(1)
		assert_gte(wiper.arm_direction().dot(wiper.forward()), -1e-6)
	# An enemy straight ahead of the turned car is reached; one where "ahead"
	# used to be (now behind and to the side) is not.
	var ahead := _place(FakeBigEnemy.new(), _ahead(1.0))
	ahead.radius_units = 0.3
	var behind := _place(FakeBigEnemy.new(), _car() - wiper.forward() * 1.5)
	behind.radius_units = 0.3
	_step(_steps_for(_pass_seconds() * 2.0))
	assert_gt(ahead.damage_taken.size(), 0, "ahead of the turned car: hit")
	assert_eq(behind.damage_taken.size(), 0, "behind the car: never hit")


# --- Damage and knockback ----------------------------------------------------------------

func test_a_minion_it_reaches_takes_the_damage_and_is_pushed_away_from_the_car() -> void:
	rack.set_damage_bonus(25.0)
	rack.upgrade("wiper")
	var s: Dictionary = data.wiper_at(1)
	var want: float = s["damage"] * rack.damage_multiplier()
	assert_almost_eq(want, 3.75, 1e-9, "3 x 1.25")
	var m: Node2D = _place(FakeMinion.new(), _ahead(1.2) + wiper.forward().orthogonal() * 0.3)
	var before: float = m.position_units().distance_to(_car())
	var away: Vector2 = (m.position_units() - _car()).normalized()
	_step(_steps_for(_pass_seconds()))
	assert_eq(m.damage_taken.size(), 1, "one hit in the pass")
	assert_almost_eq(float(m.damage_taken[0]), want, 1e-9, "data damage x garage multiplier")
	assert_eq(m.pushes.size(), 1, "pushed through the knockback call")
	assert_almost_eq(float(m.pushes[0][1]), float(s["knockback_distance"]), 1e-9, "the data's distance")
	assert_almost_eq((m.pushes[0][0] as Vector2).dot(away), 1.0, 1e-6, "straight away from the car")
	assert_almost_eq(m.position_units().distance_to(_car()), before + s["knockback_distance"], 1e-6,
		"moved away from the car")


func test_a_real_minion_is_damaged_and_knocked_back() -> void:
	rack.upgrade("wiper")
	var s: Dictionary = data.wiper_at(1)
	var m: Node = run.minions.spawn_minion_at(_ahead(1.0))
	m.max_health = 100.0
	m.health = 100.0
	var start: float = m.position_units().distance_to(_car())
	var hit_step := -1
	for i in _steps_for(_pass_seconds()):
		_step(1)
		if m.is_knocked_back():
			hit_step = i
			break
	assert_gt(hit_step, -1, "hit within one pass")
	assert_almost_eq(m.health, 100.0 - float(s["damage"]), 1e-9, "the data's damage through take_damage")
	# The minion's own step carries the push out (as the spawner does).
	while m.is_knocked_back():
		m.walk(DT, _car())
	assert_almost_eq(m.position_units().distance_to(_car()), start + s["knockback_distance"], 0.05,
		"pushed the data's distance away from the car")


func test_the_kaiju_is_damaged_but_never_pushed() -> void:
	rack.upgrade("wiper")
	var s: Dictionary = data.wiper_at(1)
	assert_false(s["knockback_kaiju"], "the data: minions only")
	# A big enemy without the knockback call, and one that has it but is in the kaiju group.
	var big: Node2D = _place(FakeBigEnemy.new(), _ahead(2.5))
	big.radius_units = 1.5
	var kaiju: Node2D = _place(FakeMinion.new(), _ahead(2.5) + wiper.forward().orthogonal() * 0.5)
	kaiju.as_kaiju(1.5)
	var big_at: Vector2 = big.position
	var kaiju_at: Vector2 = kaiju.position
	_step(_steps_for(_pass_seconds() * 3.0))
	assert_gt(big.damage_taken.size(), 0, "the big enemy is damaged")
	assert_gt(kaiju.damage_taken.size(), 0, "the kaiju stand-in is damaged")
	for a in big.damage_taken + kaiju.damage_taken:
		assert_almost_eq(float(a), float(s["damage"]), 1e-9)
	assert_eq(big.position, big_at, "not moved")
	assert_eq(kaiju.pushes, [], "no knockback call on the kaiju")
	assert_eq(kaiju.position, kaiju_at, "not moved")
	assert_false(wiper.pushes(kaiju))


func test_the_real_kaiju_is_damaged_and_not_moved() -> void:
	rack.upgrade("wiper")
	var k: Node = preload("res://scripts/enemies/kaiju.gd").new()
	run.add_child(k)
	k.set_position_units(_ahead(2.5))
	k.max_health = 1000.0
	k.health = 1000.0
	var health: float = k.health
	var at: Vector2 = k.position
	_step(_steps_for(_pass_seconds()))
	assert_lt(k.health, health, "the wiper damages the kaiju")
	assert_eq(k.position, at, "and never moves it")
	assert_false(wiper.pushes(k))


func test_one_hit_per_pass_and_never_within_the_cooldown() -> void:
	rack.upgrade("wiper")
	var s: Dictionary = data.wiper_at(1)
	var e: Node2D = _place(FakeBigEnemy.new(), _ahead(1.5))
	e.radius_units = 0.8  # a wide body: the arm touches it for several steps each pass
	var times := []
	var passes := []
	var clock := [0.0]
	wiper.enemy_hit.connect(func(_e: Node, _a: float, _p: bool) -> void:
		times.append(clock[0])
		passes.append(wiper.pass_index))
	for i in _steps_for(4.0):
		clock[0] += DT
		_step(1)
	assert_gte(times.size(), 4, "hit on most passes over 4 s (about 5 passes)")
	for i in range(1, times.size()):
		assert_ne(passes[i], passes[i - 1], "never twice in one pass")
		assert_gte(times[i] - times[i - 1], float(s["hit_cooldown"]) - 1e-6, "never within the cooldown")


func test_enemies_out_of_reach_or_behind_are_never_hit() -> void:
	rack.upgrade("wiper")
	var s: Dictionary = data.wiper_at(1)
	var far: Node2D = _place(FakeEnemy.new(), _ahead(s["length"] + 0.5 + 0.2))  # body 0.5 past the tip
	var behind: Node2D = _place(FakeEnemy.new(), _car() - wiper.forward() * 1.5)
	_step(_steps_for(3.0))
	assert_eq(far.damage_taken.size(), 0, "past the arm's reach")
	assert_eq(behind.damage_taken.size(), 0, "behind the car")


# --- Pause, end of run, new run -----------------------------------------------------------

func test_it_stops_while_paused() -> void:
	rack.upgrade("wiper")
	var e: Node2D = _place(FakeMinion.new(), _ahead(1.0))
	await wait_physics_frames(2)
	get_tree().paused = true
	var a: float = wiper.sweep_angle
	var hits_before: int = e.damage_taken.size()
	await wait_physics_frames(40)
	assert_eq(wiper.sweep_angle, a, "no sweep while paused")
	assert_eq(e.damage_taken.size(), hits_before, "no damage while paused")
	get_tree().paused = false
	await wait_physics_frames(3)
	assert_ne(wiper.sweep_angle, a, "sweeps again once the run goes on")


func test_it_stops_once_the_run_ends() -> void:
	rack.upgrade("wiper")
	run.state.damage_car(1e9)  # the car is destroyed: the run is lost
	assert_false(run.state.is_running())
	var a: float = wiper.sweep_angle
	var e: Node2D = _place(FakeMinion.new(), _ahead(1.0))
	_step(100)
	assert_eq(wiper.sweep_angle, a)
	assert_eq(e.damage_taken.size(), 0, "no damage once the run is over")


func test_a_new_run_removes_the_wiper() -> void:
	rack.upgrade("wiper")
	wiper.set_tier(6)
	_place(FakeMinion.new(), _ahead(1.0))
	_step(40)
	assert_true(wiper.drawing.visible)
	run.start_run()
	await get_tree().process_frame
	assert_eq(rack.wiper, wiper, "the same node, kept by the rack")
	assert_eq(wiper.tier, 0, "not owned in the new run")
	assert_eq(rack.owned_ids(), ["gun"])
	assert_eq(wiper.hits, 0)
	assert_eq(wiper.pass_index, 0)
	assert_false(wiper.drawing.visible, "no blade drawn")
	rack.gun.set_tier(0)
	var e: Node2D = _place(FakeMinion.new(), _ahead(1.0))
	_step(100)
	assert_eq(e.damage_taken.size(), 0, "the new run's car hurts nothing")


func test_playtest_switch_gives_it_at_the_start_of_every_run() -> void:
	Wiper.playtest_override = 1
	run.start_run()
	await get_tree().process_frame
	assert_eq(wiper.tier, 1, "switch on: the run starts with it at tier 1")
	Wiper.playtest_override = 0
	run.start_run()
	await get_tree().process_frame
	assert_eq(wiper.tier, 0, "switch off: without it")


func test_playtest_switch_is_read_from_the_data_file() -> void:
	Wiper.playtest_override = -1
	var r := GameData.load_file("playtest")
	assert_true(r.ok)
	assert_true(r.data.has("wiper_at_start"))
	assert_false(bool(r.data["wiper_at_start"]), "off: the game's rule")
	assert_eq(Wiper.playtest_switch_on(), bool(r.data["wiper_at_start"]))


# --- Tiers ------------------------------------------------------------------------------------

func test_each_tier_sets_the_datas_values() -> void:
	rack.upgrade("wiper")
	for t in range(1, data.max_tier() + 1):
		wiper.set_tier(t)
		assert_eq(wiper.stats, data.wiper_at(t), "tier %d values" % t)
	wiper.set_tier(1)
	for t in range(2, data.max_tier() + 1):
		assert_true(rack.upgrade("wiper"), "upgrade to tier %d" % t)
	assert_false(rack.upgrade("wiper"), "no upgrade past the last tier")


func test_damage_bonus_multiplies_every_tier() -> void:
	rack.upgrade("wiper")
	rack.set_damage_bonus(50.0)
	for t in range(1, data.max_tier() + 1):
		wiper.set_tier(t)
		assert_almost_eq(float(wiper.stats["damage"]), data.wiper_at(t)["damage"] * 1.5, 1e-9)


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


const TIER_KEYS := {
	"length_multiplier": "length",
	"damage_multiplier": "damage",
	"sweep_speed_multiplier": "sweep_degrees_per_second",
	"knockback_multiplier": "knockback_distance",
}


## Applies tier `want` from code and checks the change weapons.json's tier list
## gives it (read from the file, not hard-coded), then plays it.
func _check_tier(want: int) -> void:
	var found := false
	for entry in data.tiers("wiper"):
		var t := int(entry["tier"])
		if t != want:
			continue
		found = true
		var effect := String(entry["effect"])
		var value := float(entry["value"])
		var key: String = TIER_KEYS.get(effect, "")
		assert_ne(key, "", "tier %d effect %s is known" % [t, effect])
		wiper.set_tier(t - 1)
		var before: Dictionary = wiper.stats.duplicate()
		wiper.set_tier(t)
		assert_eq(wiper.tier, t)
		assert_almost_eq(float(wiper.stats[key]), float(before[key]) * value, 1e-9,
			"tier %d: %s x %s" % [t, key, value])
		for other in TIER_KEYS.values():
			if other != key:
				assert_almost_eq(float(wiper.stats[other]), float(before[other]), 1e-9,
					"tier %d leaves %s alone" % [t, other])
		_check_tier_in_play(t, key, before)
	assert_true(found, "weapons.json has a wiper tier %d" % want)


## Plays the tier's change: a longer arm reaches an enemy the last tier did not,
## more damage per hit, a faster sweep, a longer push.
func _check_tier_in_play(t: int, key: String, before: Dictionary) -> void:
	match key:
		"length":
			var d: float = (float(before["length"]) + float(wiper.stats["length"])) / 2.0 + 0.5
			for tier_now in [t - 1, t]:
				wiper.reset_for_run()
				wiper.set_tier(tier_now)
				var e: Node2D = _place(FakeEnemy.new(), _ahead(d))
				_step(_steps_for(_pass_seconds()))
				if tier_now == t:
					assert_eq(e.damage_taken.size(), 1, "tier %d reaches %.2f" % [t, d])
				else:
					assert_eq(e.damage_taken.size(), 0, "tier %d does not reach %.2f" % [tier_now, d])
				e.remove_from_group("enemies")
		"damage":
			wiper.reset_for_run()
			wiper.set_tier(t)
			var e: Node2D = _place(FakeEnemy.new(), _ahead(1.0))
			_step(_steps_for(_pass_seconds()))
			assert_eq(e.damage_taken.size(), 1)
			assert_almost_eq(float(e.damage_taken[0]), float(wiper.stats["damage"]), 1e-9, "tier %d damage" % t)
			assert_gt(float(e.damage_taken[0]), float(before["damage"]))
			e.remove_from_group("enemies")
		"sweep_degrees_per_second":
			var steps := {}
			for tier_now in [t - 1, t]:
				wiper.reset_for_run()
				wiper.set_tier(tier_now)
				var n := 0
				while wiper.pass_index == 0 and n < 1000:
					_step(1)
					n += 1
				steps[tier_now] = n
				var want_n := _steps_for(float(wiper.stats["sweep_arc_degrees"]) / float(wiper.stats["sweep_degrees_per_second"]))
				assert_between(n, want_n - 1, want_n + 1, "tier %d: one pass in %d steps" % [tier_now, want_n])
			assert_lt(steps[t], steps[t - 1], "tier %d sweeps faster" % t)
		"knockback_distance":
			wiper.reset_for_run()
			wiper.set_tier(t)
			var m: Node2D = _place(FakeMinion.new(), _ahead(1.0))
			_step(_steps_for(_pass_seconds()))
			assert_eq(m.pushes.size(), 1)
			assert_almost_eq(float(m.pushes[0][1]), float(wiper.stats["knockback_distance"]), 1e-9,
				"tier %d push" % t)
			assert_gt(float(m.pushes[0][1]), float(before["knockback_distance"]))
			m.remove_from_group("enemies")


# --- The placeholder blade --------------------------------------------------------------

func test_blade_is_drawn_in_front_of_the_car_while_owned() -> void:
	assert_true(wiper.drawing == null or not wiper.drawing.visible, "not owned: no blade")
	rack.upgrade("wiper")
	var d: Node2D = wiper.drawing
	assert_not_null(d)
	assert_eq(d.get_parent(), run.view_root, "in the car's drawing")
	assert_true(d.visible)
	for i in 30:
		_step(1)
		var pivot: Vector2 = Wiper.ISO_TRANSFORM * (wiper.pivot_units() * 16.0)
		var tip: Vector2 = Wiper.ISO_TRANSFORM * (wiper.tip_units() * 16.0)
		assert_almost_eq(d.position.distance_to(pivot), 0.0, 0.01, "on the car's nose")
		assert_almost_eq((d.position + d.arm_px).distance_to(tip), 0.0, 0.01, "out to the arm's tip")
		var over: bool = d.get_index() > run.car_sprite.get_index()
		assert_eq(over, wiper.drawn_over_car(), "over the car when pointing down the screen, under it otherwise")
	# Driving: it follows the car.
	run.car.scripted_input = [true, false, 1.0]
	for i in 20:
		run.car.physics_step()
		rack.step(DT)
	var want: Vector2 = Wiper.ISO_TRANSFORM * (wiper.pivot_units() * 16.0)
	assert_almost_eq(d.position.distance_to(want), 0.0, 0.01, "follows the car")
	wiper.set_tier(8)
	assert_almost_eq(wiper.length(), data.wiper_at(8)["length"], 1e-9)
	_step(1)
	var tip8: Vector2 = Wiper.ISO_TRANSFORM * (wiper.tip_units() * 16.0)
	assert_almost_eq((d.position + d.arm_px).distance_to(tip8), 0.0, 0.01, "grows with the length tiers")


func test_blade_goes_over_and_under_the_car_with_its_direction() -> void:
	rack.upgrade("wiper")
	# Nose down the screen (flat +x +y): the blade is in front of the car on screen.
	run.car.model.rotation = PI / 4.0
	_step(1)
	assert_true(wiper.drawn_over_car())
	assert_gt(wiper.drawing.get_index(), run.car_sprite.get_index(), "over the car")
	# Nose up the screen: behind the car on screen, drawn under it.
	run.car.model.rotation = -3.0 * PI / 4.0
	_step(1)
	assert_false(wiper.drawn_over_car())
	assert_lt(wiper.drawing.get_index(), run.car_sprite.get_index(), "under the car")


func test_blade_colours_are_opaque_and_not_redgull_red() -> void:
	rack.upgrade("wiper")
	for c in wiper.drawing.colours():
		assert_eq(c.a, 1.0, "no see-through pixels")
		for red in REDGULL_REDS:
			var dh := absf(c.h - red.h)
			assert_true(c.s < 0.35 or minf(dh, 1.0 - dh) * 360.0 > 30.0, "colour %s is not Redgull red" % c)
		assert_false(c.r > c.g + 0.2 and c.r > c.b + 0.2, "colour %s is not a red" % c)
