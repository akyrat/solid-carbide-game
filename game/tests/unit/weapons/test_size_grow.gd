extends GutTest
## Task T-286: a weapon grows on screen when a size tier is picked. The drawn
## size runs from the old size to the new one over SizeGrow.DURATION with a small
## overshoot and settles exactly on the data's size; the damage area follows the
## drawn size; a tier that does not change the size plays no grow; it stands
## still while the game is paused.

const RunScene := preload("res://scenes/run/run.tscn")
const FakeMinion := preload("res://tests/fixtures/weapons/fake_minion.gd")
const Wiper := preload("res://scripts/weapons/windshield_wiper.gd")
const Flame := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const Glow := preload("res://scripts/weapons/neon_underglow.gd")
const Molotovs := preload("res://scripts/weapons/molotovs.gd")
const DT := 0.02  # one physics step (50 per second)

var run: Node2D
var rack: Node
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
	rack.gun.set_tier(0)


func after_each() -> void:
	Wiper.playtest_override = -1
	Flame.playtest_override = -1
	Glow.playtest_override = -1
	Molotovs.playtest_override = -1
	get_tree().paused = false


func _step(steps: int) -> void:
	for i in steps:
		rack.step(DT)


func _steps(seconds: float) -> int:
	return int(ceil(seconds / DT - 1e-6))


## The weapon at tier 1 (just got), with the size it shows.
func _own(id: String):
	assert_true(rack.upgrade(id))
	return rack.get_weapon(id)


## The weapon's shown size, and the data's size at a tier, for the three size weapons.
func _shown(id: String, w) -> float:
	match id:
		"wiper": return w.length()
		"underglow": return w.radius()
		_: return w.grow.value


func _data_size(id: String, t: int) -> float:
	match id:
		"wiper": return float(data.wiper_at(t)["length"])
		"underglow": return float(data.underglow_at(t)["radius"])
		_: return float(data.flame_at(t)["size_multiplier"])


# --- The curve ------------------------------------------------------------------------

func test_the_curve_starts_at_the_old_size_overshoots_and_settles() -> void:
	assert_almost_eq(SizeGrow.value_at(2.0, 3.0, 0.0), 2.0, 1e-6)
	assert_almost_eq(SizeGrow.value_at(2.0, 3.0, SizeGrow.DURATION), 3.0, 1e-6)
	var peak := 0.0
	var t := 0.0
	while t <= SizeGrow.DURATION:
		peak = maxf(peak, SizeGrow.value_at(2.0, 3.0, t))
		t += 0.005
	assert_gt(peak, 3.0, "a small overshoot")
	assert_lt(peak, 3.0 + 0.3, "but only a small one")


# --- Each size weapon grows on a size tier --------------------------------------------

func test_each_weapon_grows_from_the_old_size_to_the_data_size() -> void:
	# Tier 2 is a size tier for all three.
	for id in ["wiper", "underglow", "flamethrower"]:
		var w = _own(id)
		var old := _data_size(id, 1)
		var new := _data_size(id, 2)
		assert_ne(old, new)
		w.upgrade()
		assert_eq(w.tier, 2)
		assert_almost_eq(_shown(id, w), old, 1e-6, "%s starts the grow at its old size" % id)
		assert_true(w.grow.active, "%s grows" % id)
		_step(_steps(SizeGrow.DURATION / 2.0))
		var mid := _shown(id, w)
		assert_gt(mid, old, "%s has grown part way" % id)
		var passed := mid > new
		for i in _steps(SizeGrow.DURATION):
			_step(1)
			passed = passed or _shown(id, w) > new + 1e-6
		assert_true(passed, "%s overshoots a little" % id)
		assert_eq(_shown(id, w), new, "%s settles exactly on the data's new size" % id)
		assert_false(w.grow.active)


func test_every_size_tier_in_the_data_grows_to_its_size() -> void:
	var size_tiers := {"wiper": [2, 6], "underglow": [2, 5, 8], "flamethrower": [2, 4, 6]}
	for id in size_tiers:
		var w = _own(id)
		for t in range(2, 9):
			w.upgrade()
			var prev := _data_size(id, t - 1)
			var new := _data_size(id, t)
			if t in size_tiers[id]:
				assert_gt(new, prev, "%s tier %d is a size tier" % [id, t])
				assert_true(w.grow.active, "%s tier %d grows" % [id, t])
				assert_almost_eq(_shown(id, w), prev, 1e-6)
			else:
				assert_eq(new, prev, "%s tier %d keeps the size" % [id, t])
				assert_false(w.grow.active, "%s tier %d plays no grow" % [id, t])
			_step(_steps(SizeGrow.DURATION) + 1)
			assert_eq(_shown(id, w), new)


func test_a_tier_that_keeps_the_size_plays_no_grow() -> void:
	var w = _own("wiper")
	w.upgrade()
	_step(_steps(SizeGrow.DURATION) + 1)
	w.upgrade()  # tier 3: damage
	assert_eq(w.tier, 3)
	assert_false(w.grow.active)
	assert_eq(w.length(), _data_size("wiper", 3))


func test_getting_the_weapon_or_a_new_run_does_not_grow() -> void:
	var w = _own("underglow")
	assert_false(w.grow.active, "getting it shows its size at once")
	assert_eq(w.radius(), _data_size("underglow", 1))
	w.set_tier(8)
	w.reset_for_run()
	assert_false(w.grow.active)
	assert_eq(w.radius(), _data_size("underglow", 0 + 1))


func test_the_grow_stands_still_while_paused() -> void:
	var w = _own("wiper")
	w.upgrade()
	await wait_physics_frames(2)
	get_tree().paused = true
	var before: float = w.length()
	await wait_physics_frames(30)
	assert_eq(w.length(), before, "no growing while paused")
	assert_true(w.grow.active)
	get_tree().paused = false
	await wait_physics_frames(40)
	assert_eq(w.length(), _data_size("wiper", 2), "it carries on and settles once the game resumes")


# --- The damage area follows the drawn size ---------------------------------------------

func test_the_wiper_hits_what_its_drawn_arm_reaches() -> void:
	var w = _own("wiper")
	w.upgrade()  # tier 2: 3.0 long, from 2.5
	var base: float = _data_size("wiper", 1)
	var m: Node2D = FakeMinion.new()
	# 0.1 units beyond the old reach plus the minion's body: outside now, inside later.
	var pos: Vector2 = w.pivot_units() + w.forward() * (base + 0.5 + 0.2)
	m.position = pos * 16.0
	run.add_child(m)
	assert_false(w._touches_swept(m, -1.0, 1.0), "outside the arm as drawn at the start of the grow")
	w.grow.advance(SizeGrow.DURATION)  # not the rack's step: the arm would also push the minion away
	assert_true(w._touches_swept(m, -1.0, 1.0), "inside once the arm has grown to reach it")
	assert_almost_eq(w.tip_units().distance_to(w.pivot_units()), _data_size("wiper", 2), 1e-4)


func test_the_underglow_circle_follows_the_drawn_radius() -> void:
	var g = _own("underglow")
	g.upgrade()
	var p: Vector2 = g.car_units() + Vector2(_data_size("underglow", 1) + 0.1, 0.0)
	assert_false(g.contains_point(p), "outside the circle as drawn at the start")
	for i in _steps(SizeGrow.DURATION) + 1:
		_step(1)
		var drawn: float = g.drawing.radius_px / 16.0
		assert_almost_eq(drawn, g.radius(), 1e-4, "the drawn ring is the damage circle at every step")
	assert_true(g.contains_point(p), "inside once the circle has grown")


func test_the_flame_area_follows_the_drawn_scale() -> void:
	var f = _own("flamethrower")
	f.set_tier(5)
	f.grow.snap(f.grow.target)  # tier 5's size, settled
	f.upgrade()  # tier 6: size x1.3
	assert_true(f.grow.active)
	var old: float = _data_size("flamethrower", 5)
	assert_almost_eq(f.drawn_scale(), old * f.size_fraction(), 1e-6)
	var length_start := _depth(f)
	_step(_steps(SizeGrow.DURATION) + 1)
	var length_end := _depth(f)
	assert_gt(length_end, length_start, "the hit outline grew with the flame")
	assert_almost_eq(f.flame_drawing.scale.x, f.drawn_scale(), 1e-6, "the drawing uses the same scale")
	assert_almost_eq(length_end / length_start, _data_size("flamethrower", 6) / old, 0.02)


func _depth(f) -> float:
	var best := 0.0
	var base: Vector2 = f.exhaust_units()
	for p in f.hit_polygon():
		best = maxf(best, p.distance_to(base))
	return best
