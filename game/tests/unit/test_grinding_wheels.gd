extends GutTest
## Task T-586: Grinding Wheels (Drifting, Decisions, "Grinding Wheels, a driving power-up"; Content,
## "Grinding Wheels (task T-586)"). In power_ups.json and offered like the other driving power-ups;
## while grinding with it a stack builds each full second up to 3; the sparks go yellow, orange
## after 1 s, red after 2 s (fading between); the launch is max(grind speed, floor 6) x 1, 1.33,
## 1.67, 2 by stacks; the stacks start again on every new grind. Without it nothing changes.

const CarScript := preload("res://scripts/driving/car.gd")
const Rails := preload("res://scripts/level/rails.gd")
const RailGrind := preload("res://scripts/driving/rail_grind.gd")
const RailSparks := preload("res://scripts/driving/rail_sparks.gd")
const GrindingWheels := preload("res://scripts/driving/grinding_wheels.gd")
const RunScene := preload("res://scenes/run/run.tscn")
const ID := "grinding_wheels"

## A long rail along x at height 1, and a second one 3.5 units south (the jump pair).
const LAYOUT := {"rails": [
	{"id": "long", "x1": 0.0, "y1": 0.0, "z1": 1.0, "x2": 400.0, "y2": 0.0, "z2": 1.0},
	{"id": "next", "x1": 0.0, "y1": 3.5, "z1": 1.0, "x2": 400.0, "y2": 3.5, "z2": 1.0},
]}

var _world: Node2D


func before_each() -> void:
	_world = Node2D.new()
	add_child_autofree(_world)
	RunState.jump_at_start_override = -1


func after_each() -> void:
	RunState.jump_at_start_override = -1


## A car falling onto the long rail with Space held, Grinding Wheels at `tier`.
func _car(tier: int) -> CharacterBody2D:
	var car: CharacterBody2D = CarScript.new()
	car.model.set_position(Vector2(1, 0.2))
	car.model.rotation = 0.0
	_world.add_child(car)
	car.set_physics_process(false)
	car.use_keyboard = false
	car.model.set_velocity(Vector2(10, 0))
	car.grind.rails = Rails.from_layout(LAYOUT)
	car.grinding_wheels.set_tier(tier)
	car.scripted_jump_held = true
	car.height_model.height = 1.6
	car.height_model.leave_rail(0.0)
	return car


func _step_until(car, cond: Callable, max_steps := 1000) -> int:
	for i in max_steps:
		if cond.call():
			return i
		car.physics_step()
	return max_steps


## On the rail, grinds `seconds` (whole physics steps), then lets go of Space; returns
## [the grind's seconds, the floored grind speed just before the launch, the launch's flat speed].
func _grind_and_launch(car, seconds: float) -> Array:
	_step_until(car, func() -> bool: return car.grind.active, 100)
	assert_true(car.grind.active, "grinding")
	var steps := roundi(seconds / car.model.dt)
	for i in steps:
		car.physics_step()
	assert_true(car.grind.active, "still grinding after %s s" % seconds)
	var secs: float = car.grind.seconds
	var base := maxf(float(car.grind.speed), float(car.grind.launch_min_speed))
	car.scripted_jump_held = false
	car.physics_step()
	assert_false(car.grind.active, "launched")
	return [secs, base, car.model.get_velocity().length()]


# --- The data and the offers ---------------------------------------------------------------

func test_it_is_in_power_ups_json_with_one_tier_and_the_icon() -> void:
	var d := PowerUpData.new()
	assert_true(d.is_ok(), d.error)
	assert_true(PowerUpData.IDS.has(ID))
	assert_true(d.ids().has(ID))
	assert_eq(d.max_tier(ID), 1, "one tier for now (the board)")
	assert_eq(d.icon(ID), "res://art/power_ups/grinding_wheels.png")
	assert_true(FileAccess.file_exists(d.icon(ID)), "the placeholder icon is there")
	var t := d.at(ID, 1)
	assert_eq(int(t.max_stacks), 3)
	assert_almost_eq(float(t.stack_seconds), 1.0, 1e-9)
	assert_almost_eq(float(t.max_launch_boost), 1.0, 1e-9, "+100% at 3 stacks")
	var raw: Dictionary = d.tiers(ID)[0]
	assert_true(bool(raw.proposal))
	assert_ne(String(raw.reason), "")


func test_its_card_uses_t585s_texts() -> void:
	var d := PowerUpData.new()
	assert_eq(PowerUpScreen.name_of(ID), "Grinding Wheels")
	assert_eq(PowerUpScreen.describe(d, ID, 1),
		"Grind a rail: sparks heat up; a longer grind, a faster launch. Burns not covered.")


func test_it_is_offered_and_taken_like_the_others_and_counts_against_the_cap() -> void:
	var state := RunState.new()
	state.mission_seed = 1
	state.start_run()
	var data := PowerUpData.new()
	var offers := PowerUpOffers.new()
	offers.bind(state, data)
	assert_true(offers.available_offers().has(ID), "a fresh car can be offered it")
	assert_eq(offers.offered_tier(ID), 1)
	assert_eq(state.grant_power_up(ID), 1, "taken at tier 1")
	assert_eq(state.grant_power_up(ID), 1, "and held there: one tier")
	assert_false(offers.available_offers().has(ID), "never offered again at its last tier")
	# The cap (slots.json max_power_ups 3): with two others owned the slots are full.
	state.grant_power_up("jump")
	state.grant_power_up("rev_charge")
	assert_eq(state.owned_power_ups().size(), state.slot_rules.max_power_ups(), "it fills a slot")
	assert_eq(offers.available_offers(), ["rev_charge", "jump"], "only the owned ones' next tiers")
	offers.free()
	state.free()


func test_the_run_gives_the_car_the_owned_tier() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	run.car.use_keyboard = false
	assert_eq(run.car.grinding_wheels.tier, 0, "not owned at the start")
	assert_same(run.car.grind.wheels, run.car.grinding_wheels, "the grind reads the car's wheels")
	run.state.grant_power_up(ID)
	assert_eq(run.car.grinding_wheels.tier, 1, "the run gives the car the tier")


# --- Stacks and the launch -----------------------------------------------------------------

func test_stacks_build_one_per_full_second_up_to_3() -> void:
	var w = GrindingWheels.new()
	w.set_tier(1)
	var want := {0.0: 0, 0.5: 0, 0.98: 0, 1.0: 1, 1.9: 1, 2.0: 2, 2.99: 2, 3.0: 3, 5.0: 3, 30.0: 3}
	for s in want:
		assert_eq(w.stacks(s), want[s], "%s s" % s)
	# 50 steps of 0.02 s add up to just under 1 in floats; still a full second.
	var t := 0.0
	for i in 50:
		t += 0.02
	assert_eq(w.stacks(t), 1)
	var mult := [1.0, 4.0 / 3.0, 5.0 / 3.0, 2.0]
	for k in 4:
		assert_almost_eq(w.launch_multiplier(float(k) + 0.5), mult[k], 1e-9, "%d stacks" % k)
	var none = GrindingWheels.new()
	assert_eq(none.stacks(5.0), 0, "not owned: no stacks")
	assert_almost_eq(none.launch_multiplier(5.0), 1.0, 1e-9)


func test_the_launch_is_the_grind_speed_times_1_133_167_2_by_stacks() -> void:
	var mult := [1.0, 4.0 / 3.0, 5.0 / 3.0, 2.0]
	for k in 4:
		var car := _car(1)
		var r := _grind_and_launch(car, float(k) + 0.5)
		assert_eq(car.grinding_wheels.stacks(r[0]), k, "%d stacks after %s s" % [k, r[0]])
		assert_almost_eq(r[2], r[1] * mult[k], 1e-3, "%d stacks: x%s" % [k, mult[k]])
		car.free()


func test_more_than_3_seconds_stays_at_2x() -> void:
	var car := _car(1)
	var r := _grind_and_launch(car, 4.5)
	assert_eq(car.grinding_wheels.stacks(r[0]), 3)
	assert_almost_eq(r[2], r[1] * 2.0, 1e-3)
	car.free()


func test_the_floor_applies_before_the_boost() -> void:
	# The ticket: the floor (launch_min_speed 6) first, then the boost: a 3 units/s grind held 3 s
	# launches at 6 x 2 = 12, not max(3 x 2, 6) = 6.
	var g = RailGrind.new()
	g.rails = Rails.from_layout(LAYOUT)
	var w = GrindingWheels.new()
	w.set_tier(1)
	g.wheels = w
	g.start({"index": 0, "s": 5.0, "speed_along": 10.0}, 0.0)
	g.speed = 3.0
	g.seconds = 3.0
	assert_almost_eq(g.launch_speed(), 12.0, 1e-9)
	g.seconds = 0.5
	assert_almost_eq(g.launch_speed(), 6.0, 1e-9, "0 stacks: the floor alone, as without it")
	g.speed = 15.0
	g.seconds = 2.0
	assert_almost_eq(g.launch_speed(), 25.0, 1e-9, "15 x 5/3")
	assert_almost_eq(g.leave_velocity("jump").length(), 25.0, 1e-9, "the jump leaves at it")
	assert_almost_eq(g.leave_velocity("end").length(), 15.0, 1e-9, "off the end: no boost")
	assert_almost_eq(g.leave_velocity("slow").dot(g.travel()), 15.0, 1e-9, "a slow drop: no boost")


func test_stacks_start_again_on_every_new_grind() -> void:
	var car := _car(1)
	var r := _grind_and_launch(car, 3.2)
	assert_eq(car.grinding_wheels.stacks(r[0]), 3, "3 stacks on the first rail")
	# Turn toward the next rail while flying, hold Space again and catch it.
	car.scripted_jump_held = true
	car.model.set_velocity(Vector2(6, 6))
	_step_until(car, func() -> bool: return car.grind.active, 200)
	assert_true(car.grind.active, "caught the next rail")
	assert_eq(car.grind.rail_index, 1)
	assert_eq(car.grinding_wheels.stacks(car.grind.seconds), 0, "a new grind starts at 0 stacks")
	car.physics_step()
	assert_eq(RailSparks.colours_for(car), car.grinding_wheels.heat_colours[0], "yellow again")
	car.free()


# --- The sparks ----------------------------------------------------------------------------

func test_the_sparks_go_yellow_orange_red_fading_between() -> void:
	var w = GrindingWheels.new()
	w.set_tier(1)
	assert_eq(w.heat_colours.size(), 3, "yellow, orange, red")
	var yellow: Array = w.heat_colours[0]
	var orange: Array = w.heat_colours[1]
	var red: Array = w.heat_colours[2]
	assert_eq(w.spark_colours(0.0), yellow)
	assert_eq(w.spark_colours(0.9), yellow, "yellow until 1 s")
	assert_eq(w.spark_colours(1.5), orange, "orange after 1 s")
	assert_eq(w.spark_colours(1.99), orange)
	assert_eq(w.spark_colours(2.5), red, "red after 2 s")
	assert_eq(w.spark_colours(10.0), red)
	# Fading: halfway through the 0.25 s fade the shades are halfway between.
	var mid: Array = w.spark_colours(1.0 + w.colour_fade_seconds / 2.0)
	for i in yellow.size():
		var want: Color = (yellow[i] as Color).lerp(orange[i], 0.5)
		assert_almost_eq(mid[i].r, want.r, 1e-4)
		assert_almost_eq(mid[i].g, want.g, 1e-4)
		assert_almost_eq(mid[i].b, want.b, 1e-4)
	assert_almost_eq(w.heat(2.0 + w.colour_fade_seconds / 2.0), 1.5, 1e-6, "orange to red")
	# Yellow is yellower than orange, orange than red (less green each step).
	assert_gt(yellow[2].g, orange[2].g)
	assert_gt(orange[2].g, red[2].g)


func test_grinding_sparks_take_the_heat_colours() -> void:
	var car := _car(1)
	var sparks: Node2D = RailSparks.new()
	add_child_autofree(sparks)
	_step_until(car, func() -> bool: return car.grind.active, 100)
	var w = car.grinding_wheels
	var seen := {}  # heat index -> colours of sparks made in that second
	for i in roundi(3.0 / car.model.dt):
		var before: int = sparks.spawned
		car.physics_step()
		sparks.step(car, car.model.dt)
		var made: int = sparks.spawned - before
		var secs: float = car.grind.seconds
		if made > 0 and fmod(secs, 1.0) > w.colour_fade_seconds + 0.05:
			var heat := int(floor(secs + 1e-6))
			var newest: Array = sparks.sparks.slice(sparks.sparks.size() - made)
			for s in newest:
				assert_true(w.heat_colours[heat].has(s.color), "spark at %s s is heat %d" % [secs, heat])
				seen[heat] = true
	assert_eq(seen.keys().size(), 3, "yellow, orange and red sparks were made")
	car.free()


func test_without_it_the_sparks_and_the_launch_are_unchanged() -> void:
	var car := _car(0)
	var sparks: Node2D = RailSparks.new()
	add_child_autofree(sparks)
	_step_until(car, func() -> bool: return car.grind.active, 100)
	for i in roundi(2.5 / car.model.dt):
		car.physics_step()
		sparks.step(car, car.model.dt)
	assert_eq(RailSparks.colours_for(car), RailSparks.SPARK_COLORS)
	for s in sparks.sparks:
		assert_true(RailSparks.SPARK_COLORS.has(s.color), "the plain spark colours")
	var base := maxf(float(car.grind.speed), float(car.grind.launch_min_speed))
	car.scripted_jump_held = false
	car.physics_step()
	assert_almost_eq(car.model.get_velocity().length(), base, 1e-3, "the plain T-578 launch")
	car.free()
