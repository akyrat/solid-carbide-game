extends GutTest
## Task T-502: the Polarized Steering Wheel. Let go of W, steer, press W again with
## the nose at least the threshold angle away from the travel: a speed burst, growing
## with the tier as in power_ups.json. Pressing W again facing roughly where the car
## moves, holding W throughout, a coast that lasts too long or has S in it: none.
## Tier 4 also sends Bricks' tier 1 wave at the car (radius 4, damage 6, minions
## pushed 4, the kaiju damaged and never pushed), owned Bricks or not; below tier 4
## no wave. The burst plays the stronger motion lines.

const CarScript := preload("res://scripts/driving/car.gd")
const WheelScript := preload("res://scripts/driving/polarized_steering_wheel.gd")
const BoostEffectScript := preload("res://scripts/driving/boost_effect.gd")
const RunScene := preload("res://scenes/run/run.tscn")
const FakeMinion := preload("res://tests/fixtures/weapons/fake_minion.gd")
const Bricks := preload("res://scripts/weapons/bricks.gd")
const ID := "polarized_steering_wheel"

var _world: Node2D
var _data := PowerUpData.new()


func before_each() -> void:
	_world = Node2D.new()
	add_child_autofree(_world)


func after_each() -> void:
	Bricks.playtest_override = -1
	get_tree().paused = false


func _car(tier := 0) -> CharacterBody2D:
	var car: CharacterBody2D = CarScript.new()
	_world.add_child(car)
	car.set_physics_process(false)
	car.use_keyboard = false
	car.detect_tricks = false
	car.polarized.set_tier(tier)
	return car


func _steps(car, n: int, w: bool, s: bool, steer := 0.0) -> void:
	car.scripted_input = [w, s, steer]
	for i in n:
		car.physics_step()


## The angle (degrees) between the car's nose and its travel now.
func _angle(car) -> float:
	return WheelScript.angle_between(car.model.rotation, car.model.get_velocity())


## Drives up to speed, lets go of W and steers until the nose is `degrees` away from
## the travel (or steers `steps` steps when given). Returns the coast's steps.
func _lift_and_steer(car, degrees: float, steps := -1) -> int:
	_steps(car, 100, true, false)
	var n := 0
	car.scripted_input = [false, false, 1.0]
	if steps >= 0:
		for i in steps:
			car.physics_step()
		return steps
	while _angle(car) < degrees and n < 200:
		car.physics_step()
		n += 1
	return n


## One step with W pressed again, no steering.
func _press_w(car) -> void:
	_steps(car, 1, true, false)


# --- The data ---------------------------------------------------------------------

func test_power_ups_json_has_four_tiers_with_bursts_and_the_tier_4_shock() -> void:
	assert_true(_data.ids().has(ID))
	assert_true(PowerUpData.IDS.has(ID))
	assert_eq(_data.max_tier(ID), 4)
	assert_eq(_data.icon(ID), "res://art/power_ups/polarized_steering_wheel.png")
	assert_true(ResourceLoader.exists(_data.icon(ID)), "the placeholder icon exists")
	var want := [1.2, 1.3, 1.4, 1.45]
	for tier in range(1, 5):
		var raw: Dictionary = _data.tiers(ID)[tier - 1]
		assert_true(bool(raw.get("proposal", false)), "tier %d is a proposal" % tier)
		assert_ne(String(raw.get("reason", "")), "", "tier %d has a reason" % tier)
		var t := _data.at(ID, tier)
		assert_almost_eq(float(t.burst_speed_multiplier), want[tier - 1], 1e-9, "tier %d burst" % tier)
		assert_almost_eq(float(t.burst_seconds), 0.5, 1e-9)
		assert_almost_eq(float(t.min_angle_degrees), 60.0, 1e-9)
		assert_eq(int(t.shock_bricks_tier), 1 if tier == 4 else 0, "only tier 4 has the shock")
		var w = WheelScript.new()
		w.set_tier(tier)
		assert_almost_eq(w.burst_speed_multiplier, float(t.burst_speed_multiplier), 1e-9)
		assert_almost_eq(w.max_coast_seconds, float(t.max_coast_seconds), 1e-9)


# --- When it bursts -------------------------------------------------------------------

func test_lift_steer_and_press_w_turned_away_gives_a_burst() -> void:
	var car := _car(1)
	var fired := []
	car.polarized.fired.connect(func(sp, sec, ang): fired.append([sp, sec, ang]))
	var coast := _lift_and_steer(car, 75.0)
	assert_lt(coast * car.model.dt, car.polarized.max_coast_seconds, "turned within the coast limit")
	var speed_before: float = car.model.total_speed()
	_press_w(car)
	assert_eq(fired.size(), 1, "one burst")
	assert_gte(fired[0][2], 60.0, "earned at 60 degrees or more")
	var want: float = maxf(speed_before, car.tuning.forward_speed) * 1.2
	assert_almost_eq(fired[0][0], want, 1e-4, "+20% of the speed carried in")
	assert_true(car.polarized.is_bursting())
	assert_almost_eq(car.model.forward_speed(), want, 1e-4, "the forward speed is lifted at once")
	# It lasts burst_seconds, then ends on its own.
	_steps(car, int(round(0.5 / car.model.dt)) - 2, true, false)
	assert_true(car.polarized.is_bursting())
	_steps(car, 3, true, false)
	assert_false(car.polarized.is_bursting(), "over after half a second")


func test_the_threshold_is_the_datas_angle() -> void:
	# Just under 60 degrees: none. Just over: a burst.
	var under := _car(1)
	_steps(under, 100, true, false)
	under.scripted_input = [false, false, 1.0]
	var n := 0
	while n < 200:
		under.physics_step()
		n += 1
		# Stop on the last step that is still under 60 (the next one would cross it).
		var next := _angle(under) + 4.0
		if next >= 60.0:
			break
	assert_lt(_angle(under), 60.0)
	_press_w(under)
	assert_eq(under.polarized.bursts_fired, 0, "%.1f degrees: no burst" % under.polarized.last_press_angle)
	var over := _car(1)
	_lift_and_steer(over, 61.0)
	_press_w(over)
	assert_eq(over.polarized.bursts_fired, 1, "%.1f degrees: a burst" % over.polarized.last_press_angle)


func test_pressing_w_again_facing_roughly_where_it_moves_gives_none() -> void:
	var car := _car(4)
	_steps(car, 100, true, false)
	_steps(car, 15, false, false)  # a straight coast
	_press_w(car)
	assert_eq(car.polarized.bursts_fired, 0, "straight: none")
	_steps(car, 100, true, false)
	_lift_and_steer(car, 0.0, 4)  # a small turn, about 15 degrees
	assert_lt(_angle(car), 30.0)
	_press_w(car)
	assert_eq(car.polarized.bursts_fired, 0, "a small turn: none")
	assert_eq(car.polarized.shocks_sent, 0)


func test_holding_w_throughout_gives_none() -> void:
	var car := _car(4)
	_steps(car, 100, true, false)
	# A held W + steer drift turns the nose far from the travel, but W is never pressed again.
	_steps(car, 120, true, false, 1.0)
	assert_gt(_angle(car), 60.0, "the drift has a big angle")
	_steps(car, 60, true, false, -1.0)
	assert_eq(car.polarized.bursts_fired, 0)


func test_too_long_a_coast_or_s_in_it_or_not_owned_gives_none() -> void:
	# Too long: steer round, then keep coasting past max_coast_seconds.
	var long_coast := _car(1)
	var coast := _lift_and_steer(long_coast, 75.0)
	var limit := int(ceil(long_coast.polarized.max_coast_seconds / long_coast.model.dt))
	_steps(long_coast, limit - coast + 2, false, false)
	assert_gt(_angle(long_coast), 60.0, "still turned away")
	_press_w(long_coast)
	assert_eq(long_coast.polarized.bursts_fired, 0, "the coast lasted too long")
	# S during the coast: braking is not a coast.
	var braked := _car(1)
	_lift_and_steer(braked, 75.0)
	_steps(braked, 2, false, true)
	_steps(braked, 1, false, false, 1.0)
	_press_w(braked)
	assert_eq(braked.polarized.bursts_fired, 0, "S in the coast")
	# Not owned: the same move does nothing, and the car drives as before.
	var plain := _car(0)
	_lift_and_steer(plain, 75.0)
	_press_w(plain)
	assert_eq(plain.polarized.bursts_fired, 0, "not owned")


func test_the_burst_grows_from_tier_1_to_4_as_in_the_data() -> void:
	var speeds := []
	for tier in range(1, 5):
		var car := _car(tier)
		_lift_and_steer(car, 75.0, 22)
		var carried: float = maxf(car.model.total_speed(), car.tuning.forward_speed)
		_press_w(car)
		assert_eq(car.polarized.bursts_fired, 1, "tier %d bursts" % tier)
		var mult := float(_data.at(ID, tier).burst_speed_multiplier)
		assert_almost_eq(car.polarized.burst_speed, carried * mult, 1e-4, "tier %d burst speed" % tier)
		assert_almost_eq(car.model.forward_speed(), carried * mult, 1e-4)
		speeds.append(car.polarized.burst_speed)
	for i in range(1, 4):
		assert_gt(speeds[i], speeds[i - 1], "tier %d is bigger than tier %d" % [i + 1, i])


func test_no_cooldown_between_bursts() -> void:
	var car := _car(2)
	_lift_and_steer(car, 75.0)
	_press_w(car)
	_steps(car, 3, true, false)
	assert_true(car.polarized.is_bursting())
	car.scripted_input = [false, false, -1.0]
	var n := 0
	while _angle(car) < 75.0 and n < 100:
		car.physics_step()
		n += 1
	_press_w(car)
	assert_eq(car.polarized.bursts_fired, 2, "a second burst right after the first")


func test_the_burst_shows_the_stronger_motion_lines() -> void:
	var car := _car(1)
	var fx = BoostEffectScript.new()
	_world.add_child(fx)
	fx.bind(car)
	_lift_and_steer(car, 75.0)
	_press_w(car)
	assert_eq(fx.strong_count(), 1, "a strong burst")
	var strong := 0
	for d in fx.drawn():
		strong += 1
	assert_gte(strong, 3, "three sets of lines")
	fx.advance(0.45)
	assert_eq(fx.strong_count(), 1, "still showing during the burst (it loops)")
	fx.advance(0.1)
	assert_eq(fx.strong_count(), 0, "gone once the burst is over")


# --- The tier 4 shock (in a run) ------------------------------------------------------

func _run() -> Node2D:
	Bricks.playtest_override = 0
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	run.car.use_keyboard = false
	run.car.scripted_input = [false, false, 0.0]
	run.weapons.gun.set_tier(0)  # the gun's bullets would hit the test enemies too
	return run


func _give(run, tier: int) -> void:
	for i in tier:
		run.state.grant_power_up(ID)
	assert_eq(run.car.polarized.tier, tier, "the run gives the car the tier")


## Stages enemies around where the car is, then presses W: a minion 2 units away, a
## stand-in kaiju 3 units away, a minion 7 units away (outside radius 4).
func _burst_with_enemies(run) -> Dictionary:
	var car = run.car
	_lift_and_steer(car, 75.0)
	var at: Vector2 = car.model.get_position() + car.model.get_velocity() * car.model.dt
	var near := FakeMinion.new()
	near.position = (at + Vector2(0.0, 2.0)) * 16.0
	run.add_child(near)
	var kaiju := FakeMinion.new()
	kaiju.as_kaiju(0.5)
	kaiju.position = (at + Vector2(-3.0, 0.0)) * 16.0
	run.add_child(kaiju)
	var far := FakeMinion.new()
	far.position = (at + Vector2(7.0, 0.0)) * 16.0
	run.add_child(far)
	_press_w(car)
	return {"near": near, "kaiju": kaiju, "far": far}


func test_tier_4_burst_sends_one_bricks_tier_1_wave_without_bricks() -> void:
	var run := _run()
	_give(run, 4)
	assert_false(run.weapons.bricks.is_owned(), "the car does not own Bricks")
	var waves := []
	run.polarized_shock.shock_sent.connect(func(c, n): waves.append([c, n]))
	var e := _burst_with_enemies(run)
	assert_eq(run.car.polarized.bursts_fired, 1)
	assert_eq(waves.size(), 1, "one wave")
	assert_almost_eq(run.polarized_shock.bricks.radius(), 4.0, 1e-9, "radius 4")
	assert_eq(e.near.damage_taken, [6.0], "the minion in reach takes 6")
	assert_eq(e.near.pushes.size(), 1, "and is pushed")
	assert_almost_eq(float(e.near.pushes[0][1]), 4.0, 1e-9, "4 units")
	assert_eq(e.kaiju.damage_taken, [6.0], "the kaiju takes 6")
	assert_eq(e.kaiju.pushes.size(), 0, "the kaiju is never pushed")
	assert_eq(e.far.damage_taken.size(), 0, "outside radius 4: untouched")
	assert_eq(run.weapons.bricks.waves, 0, "the rack's Bricks sent nothing")
	assert_not_null(run.polarized_shock.last_wave(), "the wave is drawn")
	assert_eq(run.polarized_shock.last_wave().get_parent(), run.weapons.draw_root, "as a rack projectile")


func test_tier_4_shock_is_the_tier_1_wave_even_with_bricks_owned_at_its_top_tier() -> void:
	var run := _run()
	while run.weapons.upgrade("bricks"):
		pass
	assert_eq(run.weapons.bricks.tier, run.weapons.bricks.max_tier())
	_give(run, 4)
	var e := _burst_with_enemies(run)
	assert_eq(run.polarized_shock.shocks, 1)
	assert_almost_eq(run.polarized_shock.bricks.radius(), 4.0, 1e-9, "still radius 4")
	assert_eq(run.polarized_shock.bricks.rings(), 1, "the normal wave, not the rings")
	assert_eq(e.near.damage_taken, [6.0])
	assert_eq(e.kaiju.pushes.size(), 0)
	assert_eq(e.far.damage_taken.size(), 0)


func test_below_tier_4_a_burst_sends_no_wave() -> void:
	var run := _run()
	_give(run, 3)
	var e := _burst_with_enemies(run)
	assert_eq(run.car.polarized.bursts_fired, 1, "a burst")
	assert_eq(run.polarized_shock.shocks, 0, "no wave")
	assert_eq(e.near.damage_taken.size(), 0)
	assert_eq(e.kaiju.damage_taken.size(), 0)
