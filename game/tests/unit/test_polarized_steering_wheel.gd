extends GutTest
## Task T-502, reworked by T-603 (Drifting, Decisions, "The Polarized Steering Wheel bursts
## after an alternate drift"): each ALT DRIFT! the trick detector pays, on the ground and
## outside the cooldown, multiplies the car's velocity along its travel by the tier's
## multiplier (x1.1, x1.225), held 0.5 s, then faded back in 0.25 s to exactly the speed the
## car would have had (checked against a twin car without the wheel). Lift, steer and W
## again gives nothing any more. The cooldown (T-527) and the tier 2 shock (Bricks' tier 1
## wave: radius 4, damage 6, minions pushed 4, the kaiju damaged and never pushed) stay.
## The burst plays the stronger motion lines and two ground arrows (polarized_arrows.gd).

const CarScript := preload("res://scripts/driving/car.gd")
const CarModelScript := preload("res://scripts/driving/car_model.gd")
const WheelScript := preload("res://scripts/driving/polarized_steering_wheel.gd")
const BoostEffectScript := preload("res://scripts/driving/boost_effect.gd")
const ArrowsScript := preload("res://scripts/driving/polarized_arrows.gd")
const PowerUpScreen := preload("res://scripts/ui/power_up_screen.gd")
const RunScene := preload("res://scenes/run/run.tscn")
const FakeMinion := preload("res://tests/fixtures/weapons/fake_minion.gd")
const Bricks := preload("res://scripts/weapons/bricks.gd")
const ID := "polarized_steering_wheel"
## The forward drift's length before the switch (steps; at least 0.3 s = 15 steps).
const FWD_STEPS := 25

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
	car.detect_tricks = true
	car.polarized.set_tier(tier)
	return car


## n steps of the same keys for every car in `cars`.
func _steps(cars: Array, n: int, w: bool, s: bool, steer := 0.0) -> void:
	for i in n:
		for car in cars:
			car.scripted_input = [w, s, steer]
			car.physics_step()


## Drives up to speed, drifts forward (W + A) for FWD_STEPS, then switches to a backward
## drift (S + A) until the first car's trick detector pays the alternate drift (at most 40
## steps). Returns the backward drift's steps.
func _alt_drift(cars: Array) -> int:
	_steps(cars, 100, true, false)
	_steps(cars, FWD_STEPS, true, false, 1.0)
	var paid: int = cars[0].tricks.counts.get("alternate_drift", 0)
	var n := 0
	while int(cars[0].tricks.counts.get("alternate_drift", 0)) == paid and n < 40:
		_steps(cars, 1, false, true, 1.0)
		n += 1
	return n


## The angle (degrees) between the car's nose and its travel now.
func _angle(car) -> float:
	var v: Vector2 = car.model.get_velocity()
	if v.length() < 1e-6:
		return 0.0
	return rad_to_deg(absf(Vector2.from_angle(car.model.rotation).angle_to(v)))


# --- The data ---------------------------------------------------------------------

func test_power_ups_json_has_the_halved_bursts_the_fade_and_the_tier_2_shock() -> void:
	assert_true(_data.ids().has(ID))
	assert_eq(_data.max_tier(ID), 2)
	assert_true(ResourceLoader.exists(_data.icon(ID)), "the icon exists")
	var want := [1.1, 1.225]
	for tier in range(1, 3):
		var raw: Dictionary = _data.tiers(ID)[tier - 1]
		assert_true(bool(raw.get("proposal", false)), "tier %d is a proposal" % tier)
		assert_string_contains(String(raw.get("reason", "")), "T-603")
		for gone in ["min_angle_degrees", "max_coast_seconds", "min_speed"]:
			assert_false(raw.has(gone), "the old trigger's %s is gone" % gone)
		var t := _data.at(ID, tier)
		assert_almost_eq(float(t.burst_speed_multiplier), want[tier - 1], 1e-9, "tier %d burst" % tier)
		assert_almost_eq(float(t.burst_seconds), 0.5, 1e-9)
		assert_almost_eq(float(t.fade_seconds), 0.25, 1e-9)
		assert_eq(int(t.shock_bricks_tier), 1 if tier == 2 else 0, "only tier 2 has the shock")
		var w = WheelScript.new()
		w.set_tier(tier)
		assert_almost_eq(w.burst_speed_multiplier, want[tier - 1], 1e-9)
		assert_almost_eq(w.fade_seconds, 0.25, 1e-9)


func test_the_cards_show_t602s_texts_with_10_and_23_percent() -> void:
	assert_eq(PowerUpScreen.describe(_data, ID, 1), "Pull an ALT DRIFT: +10% speed burst.")
	assert_eq(PowerUpScreen.describe(_data, ID, 2),
			"+23% burst after each ALT DRIFT!, and a shock shoves minions.")


# --- The burst ----------------------------------------------------------------------

func test_an_alt_drift_gives_the_tiers_burst_held_half_a_second_then_faded_in_a_quarter() -> void:
	for tier in range(1, 3):
		var mult := float(_data.at(ID, tier).burst_speed_multiplier)
		var car := _car(tier)
		var twin := _car(0)  # the same driving without the wheel: the speed the car would have had
		var fired := []
		car.polarized.fired.connect(func(sp, sec, d): fired.append([sp, sec, d]))
		_alt_drift([car, twin])
		assert_eq(fired.size(), 1, "tier %d: one burst on the ALT DRIFT!" % tier)
		assert_eq(twin.polarized.bursts_fired, 0)
		var vt: Vector2 = twin.model.get_velocity()
		assert_gt(vt.length(), 5.0, "the car is moving")
		assert_almost_eq(car.model.get_velocity().distance_to(vt * mult), 0.0, 1e-4,
				"tier %d: x%.3f at once, along the travel" % [tier, mult])
		assert_almost_eq(float(fired[0][0]), vt.length() * mult, 1e-4, "the signal's speed")
		assert_almost_eq(float(fired[0][1]), 0.5, 1e-9, "held 0.5 s")
		assert_almost_eq((fired[0][2] as Vector2).dot(vt.normalized()), 1.0, 1e-6, "its direction is the travel")
		# The hold: 25 steps (0.5 s) at the full multiplier, the backward drift going on.
		for k in range(1, 26):
			_steps([car, twin], 1, false, true, 1.0 if k < 10 else 0.0)
			var want: Vector2 = twin.model.get_velocity() * mult
			assert_almost_eq(car.model.get_velocity().distance_to(want), 0.0, 1e-4,
					"tier %d hold step %d" % [tier, k])
		assert_true(car.polarized.is_bursting())
		# The fade: a straight line from the multiplier down to 1 over 0.25 s.
		for k in range(26, 38):
			_steps([car, twin], 1, true, false)
			var f := 1.0 + (mult - 1.0) * (0.25 - (k - 25) * 0.02) / 0.25
			assert_true(car.polarized.is_fading(), "tier %d fading at step %d" % [tier, k])
			assert_almost_eq(car.model.get_velocity().distance_to(twin.model.get_velocity() * f), 0.0, 1e-4,
					"tier %d fade step %d: x%.4f" % [tier, k, f])
		_steps([car, twin], 1, true, false)
		assert_false(car.polarized.is_bursting(), "tier %d: over 0.75 s after the payout" % tier)
		assert_almost_eq(car.model.get_velocity().distance_to(twin.model.get_velocity()), 0.0, 1e-4,
				"the speed the car would have had")
		_steps([car, twin], 30, true, false)
		assert_almost_eq(car.model.get_velocity().distance_to(twin.model.get_velocity()), 0.0, 1e-4,
				"and it stays the twin's")


func test_the_burst_pushes_along_the_travel_whichever_way_the_nose_points() -> void:
	# The car moving backwards (nose east, travel west and a little south): the burst
	# scales the travel, it does not push the nose's way.
	var wheel = WheelScript.new()
	wheel.set_tier(1)
	var m = CarModelScript.new()
	m.rotation = 0.0
	m.set_velocity(Vector2(-10.0, 2.0))
	wheel.on_alternate_drift(m, false)
	assert_almost_eq(m.get_velocity().distance_to(Vector2(-11.0, 2.2)), 0.0, 1e-4, "x1.1 along the travel")
	assert_almost_eq(wheel.burst_direction.dot(Vector2(-10.0, 2.0).normalized()), 1.0, 1e-6)
	assert_lt(wheel.burst_direction.dot(Vector2.from_angle(m.rotation)), 0.0, "against the nose")
	# In the car: at the switch into the backward drift the travel is far from the nose,
	# and the burst still follows the travel.
	var car := _car(2)
	var twin := _car(0)
	_alt_drift([car, twin])
	var vt: Vector2 = twin.model.get_velocity()
	assert_gt(_angle(twin), 20.0, "the nose is %.0f degrees off the travel" % _angle(twin))
	assert_almost_eq(car.polarized.burst_direction.dot(vt.normalized()), 1.0, 1e-6)


func test_lift_steer_and_w_again_gives_no_burst_any_more() -> void:
	var car := _car(2)
	_steps([car], 100, true, false)
	var n := 0
	car.scripted_input = [false, false, 1.0]
	while _angle(car) < 75.0 and n < 200:
		car.physics_step()
		n += 1
	assert_gte(_angle(car), 75.0, "the old move: nose turned away during a coast")
	_steps([car], 30, true, false)
	assert_eq(car.polarized.bursts_fired, 0, "no burst")
	assert_eq(car.polarized.shocks_sent, 0, "no shock")
	assert_eq(car.polarized.factor, 1.0)


func test_a_held_drift_or_a_plain_drift_switch_on_the_other_side_gives_none() -> void:
	var car := _car(1)
	_steps([car], 100, true, false)
	_steps([car], 120, true, false, 1.0)
	_steps([car], 60, true, false, -1.0)
	assert_eq(car.polarized.bursts_fired, 0, "a held W drift: none")
	# W + A then S + D: the steering side changed, so no ALT DRIFT! and no burst.
	_steps([car], FWD_STEPS, true, false, 1.0)
	_steps([car], 25, false, true, -1.0)
	assert_eq(int(car.tricks.counts.get("alternate_drift", 0)), 0)
	assert_eq(car.polarized.bursts_fired, 0)


func test_not_owned_an_alt_drift_changes_nothing() -> void:
	var car := _car(0)
	var plain := _car(0)
	plain.detect_tricks = false
	_alt_drift([car, plain])
	_steps([car, plain], 40, true, false)
	assert_eq(int(car.tricks.counts.get("alternate_drift", 0)), 1, "the trick was paid")
	assert_eq(car.polarized.bursts_fired, 0)
	assert_almost_eq(car.model.get_velocity().distance_to(plain.model.get_velocity()), 0.0, 1e-4)


func test_in_the_air_an_alt_drift_gives_no_burst() -> void:
	var wheel = WheelScript.new()
	wheel.set_tier(1)
	var m = CarModelScript.new()
	m.set_velocity(Vector2(10.0, 0.0))
	wheel.on_alternate_drift(m, true)
	assert_eq(wheel.bursts_fired, 0)
	assert_eq(m.get_velocity(), Vector2(10.0, 0.0))


func test_end_burst_keeps_the_velocity_and_stops_scaling() -> void:
	var car := _car(1)
	_alt_drift([car])
	assert_true(car.polarized.is_bursting())
	var v: Vector2 = car.model.get_velocity()
	car.polarized.end_burst()  # a wall hit, a rail, the wreck
	assert_eq(car.model.get_velocity(), v, "the speed it has is kept")
	assert_false(car.polarized.is_bursting())
	assert_eq(car.polarized.factor, 1.0)


# --- The cooldown (T-527) -----------------------------------------------------------------

func test_every_wheel_tier_has_a_cooldown_the_wheel_reads() -> void:
	for tier in range(1, 3):
		var car := _car(tier)
		var secs := float(_data.at(ID, tier).get("cooldown_seconds", 0.0))
		assert_gt(secs, 0.0, "tier %d has cooldown_seconds" % tier)
		assert_eq(car.polarized.cooldown_seconds, secs)
	assert_eq(_car(0).polarized.cooldown_seconds, 0.0, "not owned: none")


func test_an_alt_drift_during_the_cooldown_gives_no_burst_and_the_next_one_after_does() -> void:
	var car := _car(2)
	_alt_drift([car])
	assert_eq(car.polarized.bursts_fired, 1)
	assert_eq(car.polarized.shocks_sent, 1, "tier 2's shock")
	assert_false(car.polarized.is_ready())
	# Straight back into a forward drift on the same side: a second ALT DRIFT!.
	_steps([car], 20, true, false, 1.0)
	assert_eq(int(car.tricks.counts.get("alternate_drift", 0)), 2, "the second switch pays")
	assert_eq(car.polarized.alternate_drifts, 2)
	assert_eq(car.polarized.bursts_fired, 1, "during the cooldown: no second burst")
	assert_eq(car.polarized.shocks_sent, 1, "and no second shock")
	var guard := 0
	while not car.polarized.is_ready() and guard < 2000:
		_steps([car], 1, true, false)
		guard += 1
	assert_true(car.polarized.is_ready())
	_alt_drift([car])
	assert_eq(car.polarized.bursts_fired, 2, "after the cooldown: a burst")
	assert_eq(car.polarized.shocks_sent, 2)


func test_cooldown_fraction_goes_from_1_to_0_and_ready_again_fires_once() -> void:
	var car := _car(1)
	var wheel = car.polarized
	watch_signals(wheel)
	assert_true(wheel.is_ready())
	assert_eq(wheel.cooldown_fraction_left(), 0.0)
	_alt_drift([car])
	assert_almost_eq(wheel.cooldown_fraction_left(), 1.0, 0.02, "just after a burst")
	assert_signal_not_emitted(wheel, "ready_again")
	var steps := int(wheel.cooldown_seconds / car.model.dt)
	_steps([car], steps / 2, true, false)
	assert_almost_eq(wheel.cooldown_fraction_left(), 0.5, 0.05, "halfway")
	_steps([car], steps / 2 + 3, true, false)
	assert_eq(wheel.cooldown_fraction_left(), 0.0)
	assert_true(wheel.is_ready())
	assert_signal_emit_count(wheel, "ready_again", 1)
	assert_signal_emit_count(wheel, "burst_ended", 1)


## The bot's idea in small (game/tools/speed_bot.gd): chain alternate drifts for 40 s.
## With the cooldown and the fade the speed does not keep growing burst after burst.
func test_chained_alt_drift_bursts_do_not_keep_growing() -> void:
	for tier in range(1, 3):
		var car := _car(tier)
		var first_half := 0.0
		var second_half := 0.0
		var steps := 2000
		for i in steps:
			var phase := i % 60
			# 0.4 s of W + A, 0.4 s of S + A, 0.4 s of W straight.
			var w := phase < 20 or phase >= 40
			var s := phase >= 20 and phase < 40
			car.scripted_input = [w, s, 1.0 if phase < 40 else 0.0]
			car.physics_step()
			var v: float = car.model.get_velocity().length()
			if i < steps / 2:
				first_half = maxf(first_half, v)
			else:
				second_half = maxf(second_half, v)
		assert_gt(car.polarized.bursts_fired, 5, "tier %d fired several bursts" % tier)
		assert_lte(second_half, first_half + 0.5, "tier %d: no growth from the first 20 s to the last 20 s" % tier)


func test_reset_clears_the_cooldown_and_the_burst() -> void:
	var car := _car(1)
	_alt_drift([car])
	car.polarized.reset()
	assert_true(car.polarized.is_ready())
	assert_false(car.polarized.is_bursting())


# --- The effects ----------------------------------------------------------------------------

func test_the_burst_shows_the_stronger_motion_lines() -> void:
	var car := _car(1)
	var fx = BoostEffectScript.new()
	_world.add_child(fx)
	fx.bind(car)
	_alt_drift([car])
	assert_eq(fx.strong_count(), 1, "a strong burst")
	assert_gte(fx.drawn().size(), 3, "three sets of lines")
	fx.advance(0.45)
	assert_eq(fx.strong_count(), 1, "still showing during the burst (it loops)")
	fx.advance(0.1)
	assert_eq(fx.strong_count(), 0, "gone once the burst is over")


func test_the_arrows_show_at_both_sides_along_the_travel_and_fade_out() -> void:
	var car := _car(1)
	var fx = BoostEffectScript.new()
	_world.add_child(fx)
	fx.bind(car)
	var arrows = fx.arrows
	assert_not_null(arrows, "the boost effect carries the arrows")
	assert_eq(arrows.get_parent(), fx)
	_alt_drift([car])
	var travel: Vector2 = car.polarized.burst_direction
	assert_almost_eq(travel.dot(car.model.get_velocity().normalized()), 1.0, 1e-6)
	assert_eq(arrows.pair_count(), 1, "one pair")
	var d: Array = arrows.drawn()
	assert_eq(d.size(), 2, "two arrows")
	var centre: Vector2 = car.model.get_position()
	var across := Vector2(-travel.y, travel.x)
	var sides := []
	for a in d:
		var dir: Vector2 = (a.tip - a.tail).normalized()
		assert_almost_eq(dir.dot(travel), 1.0, 1e-6, "points along the travel at the payout")
		var mid: Vector2 = (a.tip + a.tail) * 0.5
		var off: float = (mid - centre).dot(across)
		assert_almost_eq(absf(off), arrows.side_units, 1e-4, "at the car's side")
		sides.append(signf(off))
		assert_almost_eq(float(a.alpha), 1.0, 1e-9, "full at first")
		assert_eq(a.points.size(), 7, "a shaft and a head")
	assert_eq(sides.size(), 2)
	assert_ne(sides[0], sides[1], "one on each side")
	var fills := [d[0].fill.to_html(false), d[1].fill.to_html(false)]
	assert_true(fills.has(ArrowsScript.CYAN.to_html(false)), "the wheel's cyan")
	assert_true(fills.has(ArrowsScript.MAGENTA.to_html(false)), "and magenta")
	# They follow the car; their direction stays the payout's.
	_steps([car], 10, true, false, -1.0)
	for a in arrows.drawn():
		assert_almost_eq((a.tip - a.tail).normalized().dot(travel), 1.0, 1e-6, "still the payout's direction")
	arrows.advance(0.3)
	var faded: float = arrows.drawn()[0].alpha
	assert_lt(faded, 1.0, "fading")
	assert_gt(faded, 0.0)
	arrows.advance(0.21)
	assert_eq(arrows.pair_count(), 0, "gone after 0.5 s")
	assert_eq(arrows.drawn().size(), 0)


func test_in_a_run_the_arrows_are_drawn_under_the_car() -> void:
	var run := _run()
	var fx: Node2D = run.boost_effect
	assert_not_null(fx.arrows)
	assert_eq(fx.arrows.view_transform, fx.view_transform, "flat on the ground, in the view's projection")
	assert_lt(fx.get_index(), run.car_sprite.get_index(), "under the car's sprite")
	_give(run, 1)
	_alt_drift([run.car])
	assert_eq(run.car.polarized.bursts_fired, 1, "the run's car bursts on the ALT DRIFT!")
	assert_eq(fx.arrows.pair_count(), 1, "and the arrows show")


# --- The tier 2 (last tier) shock (in a run) ------------------------------------------------------

func _run() -> Node2D:
	Bricks.playtest_override = 0
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	run.car.use_keyboard = false
	run.car.set_physics_process(false)
	run.car.scripted_input = [false, false, 0.0]
	run.car.detect_tricks = true
	run.weapons.gun.set_tier(0)  # the gun's bullets would hit the test enemies too
	return run


func _give(run, tier: int) -> void:
	for i in tier:
		run.state.grant_power_up(ID)
	assert_eq(run.car.polarized.tier, tier, "the run gives the car the tier")


## Drives to one step before the ALT DRIFT! pays, stages enemies around where the car
## will be (a minion 2 units away, a stand-in kaiju 3 units away, a minion 7 units away,
## outside radius 4), then takes the paying step.
func _burst_with_enemies(run) -> Dictionary:
	var car = run.car
	_steps([car], 100, true, false)
	_steps([car], FWD_STEPS, true, false, 1.0)
	var need := float(car.tuning.alternate_min_drift_seconds)
	var n := 0
	while n < 40:
		_steps([car], 1, false, true, 1.0)
		n += 1
		if car.tricks._seg_time >= need - car.model.dt - 1e-6:
			break
	assert_eq(car.polarized.bursts_fired, 0, "not yet")
	var at: Vector2 = car.model.get_position()
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
	_steps([car], 1, false, true, 1.0)
	return {"near": near, "kaiju": kaiju, "far": far}


func test_tier_2_burst_sends_one_bricks_tier_1_wave_without_bricks() -> void:
	var run := _run()
	_give(run, 2)
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


func test_tier_2_shock_is_the_tier_1_wave_even_with_bricks_owned_at_its_top_tier() -> void:
	var run := _run()
	while run.weapons.upgrade("bricks"):
		pass
	assert_eq(run.weapons.bricks.tier, run.weapons.bricks.max_tier())
	_give(run, 2)
	var e := _burst_with_enemies(run)
	assert_eq(run.polarized_shock.shocks, 1)
	assert_almost_eq(run.polarized_shock.bricks.radius(), 4.0, 1e-9, "still radius 4")
	assert_eq(run.polarized_shock.bricks.rings(), 1, "the normal wave, not the rings")
	assert_eq(e.near.damage_taken, [6.0])
	assert_eq(e.kaiju.pushes.size(), 0)
	assert_eq(e.far.damage_taken.size(), 0)


func test_below_tier_2_a_burst_sends_no_wave() -> void:
	var run := _run()
	_give(run, 1)
	var e := _burst_with_enemies(run)
	assert_eq(run.car.polarized.bursts_fired, 1, "a burst")
	assert_eq(run.polarized_shock.shocks, 0, "no wave")
	assert_eq(e.near.damage_taken.size(), 0)
	assert_eq(e.kaiju.damage_taken.size(), 0)
