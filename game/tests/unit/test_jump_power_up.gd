extends GutTest
## Task T-461: Jump. With the power-up owned, a Space press on the ground makes
## a small hop through the car's own height model (car_height.gd, hop()): it
## takes off at the tier's takeoff_speed from power_ups.json, falls with the
## height model's gravity and lands. Without it, Space changes nothing. A hop
## with an air spin pays the airtime and AIR 180 mission goals through the
## car's existing trick signals.

const CarScript := preload("res://scripts/driving/car.gd")
const CarHeightScript := preload("res://scripts/driving/car_height.gd")
const JumpScript := preload("res://scripts/driving/jump_power_up.gd")
const GroundHeightScript := preload("res://scripts/level/ground_height.gd")
const TrickDetector := preload("res://scripts/driving/trick_detector.gd")
const LAYOUT := "res://data/level/elevation_sample_map.json"

const A := 1.0

var _world: Node2D
var _data := PowerUpData.new()


func before_each() -> void:
	_world = Node2D.new()
	add_child_autofree(_world)


## A car at `start` on the elevation map's ground (with_ground) or with no
## ground source (the height model's flat 0), Jump at `tier`.
func _car(tier: int, with_ground := true, start := Vector2.INF) -> CharacterBody2D:
	var car: CharacterBody2D = CarScript.new()
	if with_ground:
		var g = GroundHeightScript.from_file(LAYOUT)
		if start == Vector2.INF:
			start = _street_point(g, 4.0)
		car.model.set_position(start)
	_world.add_child(car)
	car.set_physics_process(false)
	car.use_keyboard = false
	if with_ground:
		car.ground = GroundHeightScript.from_file(LAYOUT)
	car.jump.set_tier(tier)
	return car


## A street point (height 0, no ramp) with street all round it for `r` units.
func _street_point(g, r: float) -> Vector2:
	for y in range(-120, 121, 4):
		for x in range(-120, 121, 4):
			var p := Vector2(x, y)
			var ok := true
			for off in [Vector2.ZERO, Vector2(r, 0), Vector2(-r, 0), Vector2(0, r), Vector2(0, -r)]:
				if g.is_ramp(p + off) or g.height_at(p + off) != 0.0:
					ok = false
			if ok:
				return p
	return Vector2.INF


## Presses Space, then steps until the car lands. Returns [steps in the air, peak height].
func _hop(car, steer := 0.0) -> Array:
	car.scripted_input = [false, false, steer]
	car.press_jump()
	car.physics_step()
	var steps := 1 if car.airborne else 0
	var peak: float = car.height
	while car.airborne and steps < 1000:
		car.physics_step()
		steps += 1
		peak = maxf(peak, car.height)
	car.scripted_input = [false, false, 0.0]
	return [steps, peak]


func test_tier_numbers_come_from_power_ups_json() -> void:
	for tier in range(1, _data.max_tier("jump") + 1):
		var j = JumpScript.new()
		j.set_tier(tier)
		var t: Dictionary = _data.at("jump", tier)
		assert_almost_eq(j.takeoff_speed, float(t.takeoff_speed), 1e-9, "tier %d" % tier)
		assert_almost_eq(j.cooldown_seconds, float(t.cooldown_seconds), 1e-9, "tier %d" % tier)


## Acceptance 1: per tier, the hop's airtime and peak match the takeoff speed
## under the height model's gravity (closed form 2v/g and v^2/2g; the 50 Hz
## semi-implicit steps land within a step and a little under the peak).
func test_each_tier_hops_to_its_height_and_lands() -> void:
	var g := CarHeightScript.GRAVITY
	for tier in range(1, _data.max_tier("jump") + 1):
		var car := _car(tier)
		var dt: float = car.model.dt
		var vz: float = float(_data.at("jump", tier).takeoff_speed)
		var r := _hop(car)
		var want_steps: float = JumpScript.airtime_for(vz, g) / dt
		assert_almost_eq(float(r[0]), want_steps, 1.5, "tier %d airtime steps (%d)" % [tier, r[0]])
		assert_almost_eq(float(r[1]), JumpScript.peak_for(vz, g), 0.1, "tier %d peak %.3f" % [tier, r[1]])
		assert_false(car.airborne, "tier %d landed" % tier)
		assert_almost_eq(car.height, 0.0, 1e-9, "tier %d back on the street" % tier)
		assert_eq(car.jump.hops, 1)


func test_higher_tiers_hop_higher_and_longer() -> void:
	var last := [0, 0.0]
	for tier in range(1, _data.max_tier("jump") + 1):
		var r := _hop(_car(tier))
		assert_gt(r[0], last[0], "tier %d longer" % tier)
		assert_gt(r[1], last[1], "tier %d higher" % tier)
		last = r


func test_the_hop_uses_the_height_paths_signals() -> void:
	var car := _car(1)
	var seen := []
	car.height_model.took_off.connect(func(from_ramp, vz): seen.append(["off", from_ramp, vz]))
	car.height_model.hopped.connect(func(vz): seen.append(["hop", vz]))
	car.height_model.landed.connect(func(v): seen.append(["land"]))
	_hop(car)
	assert_eq(seen.size(), 3)
	assert_eq(seen[0], ["off", false, 5.0])
	assert_eq(seen[1], ["hop", 5.0])
	assert_eq(seen[2], ["land"])


## The run's own map, or any car with no ground source, hops over flat ground at 0.
func test_the_hop_works_with_no_ground_source() -> void:
	var car := _car(2, false)
	var r: Array = _hop(car)
	var want: float = JumpScript.airtime_for(8.0, CarHeightScript.GRAVITY) / car.model.dt
	assert_almost_eq(float(r[0]), want, 1.5)
	assert_gt(r[1], 1.0)
	assert_false(car.airborne)
	assert_eq(car.height, 0.0)


## Acceptance 2: without the power-up, Space changes nothing in height or speed.
func test_without_the_power_up_space_changes_nothing() -> void:
	var a := _car(0)
	var b := _car(0, true, a.model.get_position())
	for car in [a, b]:
		car.scripted_input = [true, false, 0.0]
	for i in 80:
		if i % 10 == 0:
			a.press_jump()
		a.physics_step()
		b.physics_step()
		assert_false(a.airborne)
		assert_eq(a.height, b.height, "step %d height" % i)
		assert_eq(a.vertical_speed, 0.0)
		assert_eq(a.model.get_velocity(), b.model.get_velocity(), "step %d speed" % i)
		assert_eq(a.model.get_position(), b.model.get_position(), "step %d place" % i)
	assert_eq(a.jump.hops, 0)


## Also with no ground source (the old flat run path).
func test_without_the_power_up_space_changes_nothing_with_no_ground() -> void:
	var car := _car(0, false)
	car.scripted_input = [true, false, 0.0]
	for i in 20:
		car.press_jump()
		car.physics_step()
		assert_eq(car.height, 0.0)
		assert_false(car.airborne)


## Proposal: only on the ground (no double jump) and the cooldown counts from the takeoff.
func test_no_double_jump_and_the_cooldown_holds_the_next_hop() -> void:
	var car := _car(1)
	car.scripted_input = [false, false, 0.0]
	car.press_jump()
	car.physics_step()
	assert_true(car.airborne)
	var vz: float = car.vertical_speed
	car.press_jump()
	car.physics_step()
	assert_lt(car.vertical_speed, vz, "a press in the air does not lift it again")
	assert_eq(car.jump.hops, 1)
	while car.airborne:
		car.physics_step()
	# Landed before the 2 s cooldown is over: a press does nothing.
	assert_gt(car.jump.cooldown_left, 0.0)
	car.press_jump()
	car.physics_step()
	assert_false(car.airborne, "still on cooldown")
	while car.jump.cooldown_left > 0.0:
		car.physics_step()
	car.press_jump()
	car.physics_step()
	assert_true(car.airborne, "the cooldown is over")
	assert_eq(car.jump.hops, 2)


## A held Space is one press: the car gets one hop per press_jump(), never one per step.
func test_a_press_is_used_once() -> void:
	var car := _car(4)
	car.press_jump()
	car.physics_step()
	while car.airborne:
		car.physics_step()
	for i in 200:
		car.physics_step()
	assert_eq(car.jump.hops, 1)


## The hop keeps the car's flat speed: it flies on with the velocity it had.
func test_the_hop_keeps_the_flat_speed() -> void:
	var car := _car(2)
	car.scripted_input = [true, false, 0.0]
	for i in 30:
		car.physics_step()
	var v: Vector2 = car.model.get_velocity()
	car.press_jump()
	car.physics_step()
	assert_true(car.airborne)
	assert_almost_eq(car.model.get_velocity().length(), v.length(), 1e-6)


func test_the_run_gives_the_car_the_owned_tier() -> void:
	var run: Node = preload("res://scenes/run/run.tscn").instantiate()
	add_child_autofree(run)
	assert_eq(run.car.jump.tier, 0, "a new run owns none")
	run.state.grant_power_up("jump")
	assert_eq(run.car.jump.tier, 1)
	run.state.grant_power_up("jump")
	assert_eq(run.car.jump.tier, 2)
	assert_almost_eq(run.car.jump.takeoff_speed, float(_data.at("jump", 2).takeoff_speed), 1e-9)


## Acceptance 3: a hop with an air spin advances the mission tracker's airtime and
## AIR 180 goals, through the car's own trick signals (as RunState feeds them).
func test_a_hop_with_a_spin_counts_for_the_airtime_and_air_180_goals() -> void:
	var m := RunMissions.new()
	m.missions = [[
		{"trick": TrickDetector.TRICK_AIRTIME, "kind": "seconds", "amount": 10.0},
		{"trick": TrickDetector.TRICK_AIR_ONE_EIGHTY, "kind": "count", "amount": 2.0},
	]]
	m.current = 0
	m._load_current()
	var car := _car(3)
	car.trick.connect(func(id: String) -> void: m.on_trick(id, car.tricks.last_trick_seconds))
	car.airtime_trick.connect(m.on_airtime)
	var r := _hop(car, A)
	car.physics_step()
	var seconds: float = float(r[0]) * car.model.dt
	assert_almost_eq(float(m.progress[0]), seconds, 0.05, "airtime goal: the hop's %.2f s" % seconds)
	assert_eq(float(m.progress[1]), 1.0, "one AIR 180")
	assert_eq(car.tricks.counts.get(TrickDetector.TRICK_AIR_ONE_EIGHTY, 0), 1)
