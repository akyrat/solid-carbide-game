extends GutTest
## Task T-541: the rail grinding prototype (Drifting, Content, "Rail grinding (task T-541)"; the
## rail format: Level design, Content, "Rails (task T-541)"). Rails load from a level file; a car
## that lands on a rail moving along it locks on, slides along it and leaves at its end; one
## landing across it doesn't; Jump while grinding hops off and can land on a second rail; a grind
## that ends pays the GRIND! trick (combo.json "rail_grind"); the playtest switch starts runs with
## the Jump power-up and is off in the committed data.

const CarScript := preload("res://scripts/driving/car.gd")
const Rails := preload("res://scripts/level/rails.gd")
const RailGrind := preload("res://scripts/driving/rail_grind.gd")
const RailDrawing := preload("res://scripts/level/rail_drawing.gd")
const TrickPopupsScript := preload("res://scripts/hud/trick_popups.gd")
const GAME_MAP := "res://data/level/kaiju_city_map.json"

## Two level rails along x (east), 3.5 units apart, at height 1: the jump pair's layout.
const LAYOUT := {"rails": [
	{"id": "rail-a", "x1": 0.0, "y1": 0.0, "z1": 1.0, "x2": 20.0, "y2": 0.0, "z2": 1.0},
	{"id": "rail-b", "x1": 0.0, "y1": 3.5, "z1": 1.0, "x2": 30.0, "y2": 3.5},
]}

var _world: Node2D


func before_each() -> void:
	_world = Node2D.new()
	add_child_autofree(_world)
	RunState.jump_at_start_override = -1


func after_each() -> void:
	RunState.jump_at_start_override = -1


## A car with no ground source (flat street at 0), the layout's rails, Jump at `jump_tier`, at
## `pos` heading `heading` (radians) with flat velocity `vel`, in the air at `height` going up
## at `vz`.
func _car(pos: Vector2, vel: Vector2, height: float, vz: float, jump_tier := 0, layout := LAYOUT) -> CharacterBody2D:
	var car: CharacterBody2D = CarScript.new()
	car.model.set_position(pos)
	car.model.rotation = atan2(vel.y, vel.x)
	_world.add_child(car)
	car.set_physics_process(false)
	car.use_keyboard = false
	car.model.set_velocity(vel)
	car.grind.rails = Rails.from_layout(layout)
	car.jump.set_tier(jump_tier)
	if height > 0.0 or vz > 0.0:
		car.height_model.height = height
		car.height_model.leave_rail(vz)
	return car


## Steps until `cond` holds or `max_steps` pass; returns the steps taken.
func _step_until(car, cond: Callable, max_steps := 1000) -> int:
	for i in max_steps:
		if cond.call():
			return i
		car.physics_step()
	return max_steps


# --- The format -----------------------------------------------------------------------------

func test_rails_load_from_the_level_format() -> void:
	var rails := Rails.from_layout(LAYOUT)
	assert_eq(rails.size(), 2)
	assert_eq(rails[0].id, "rail-a")
	assert_eq(rails[0].a, Vector2(0, 0))
	assert_eq(rails[0].b, Vector2(20, 0))
	assert_almost_eq(float(rails[0].length), 20.0, 1e-6)
	assert_eq(rails[0].dir, Vector2.RIGHT)
	assert_almost_eq(float(rails[1].zb), 1.0, 1e-6, "z2 left out: a level rail at z1")


func test_a_sloped_rail_changes_height_in_a_straight_line() -> void:
	var r := Rails.make("r", Vector2(0, 0), Vector2(0, -10), 3.0, 6.0)
	assert_almost_eq(Rails.height_at(r, 0.0), 3.0, 1e-6)
	assert_almost_eq(Rails.height_at(r, 5.0), 4.5, 1e-6)
	assert_almost_eq(Rails.height_at(r, 10.0), 6.0, 1e-6)
	assert_almost_eq(Rails.height_at(r, 14.0), 6.0, 1e-6, "held past the end")


func test_bad_rail_entries_are_skipped() -> void:
	var layout := {"rails": [
		{"id": "no-end", "x1": 0, "y1": 0, "z1": 1},
		{"id": "street", "x1": 0, "y1": 0, "z1": 0, "x2": 5, "y2": 0},
		{"id": "short", "x1": 0, "y1": 0, "z1": 1, "x2": 0.5, "y2": 0},
		{"id": "text", "x1": "a", "y1": 0, "z1": 1, "x2": 5, "y2": 0},
		{"id": "ok", "x1": 0, "y1": 0, "z1": 1, "x2": 5, "y2": 0},
	]}
	var rails := Rails.from_layout(layout)
	assert_eq(rails.size(), 1)
	assert_eq(rails[0].id, "ok")
	assert_eq(Rails.from_layout({}).size(), 0, "a level with no rails")


func test_the_game_map_has_no_rails() -> void:
	# The board, 2026-11-06 (T-546): the default map has none; rails come from the creator's levels.
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GAME_MAP))
	assert_eq((data.get("rails", []) as Array).size(), 0, "no rails in the game's map file")
	assert_eq(Rails.from_layout(data).size(), 0, "the map loads with no rails")


func test_two_parallel_rails_can_be_a_first_tier_jump_apart() -> void:
	# Two parallel rails at the same height, no further apart than a Jump tier 1 hop carries
	# the car sideways at cruise speed (11 units/s turned jump_angle_deg, over the hop's airtime)
	# plus the reach. The test layout's pair (3.5 apart) is the example.
	var rails := Rails.from_layout(LAYOUT)
	var j = preload("res://scripts/driving/jump_power_up.gd").new()
	j.set_tier(1)
	var g = RailGrind.new()
	var carry: float = 11.0 * sin(deg_to_rad(g.jump_angle_deg)) * j.airtime_for(j.takeoff_speed, 12.0) + g.reach
	var found := false
	for a in rails:
		for b in rails:
			if a == b or absf(float(a.dir.dot(b.dir))) < 0.999 or absf(float(a.za) - float(b.za)) > 0.01:
				continue
			var gap := Rails.side_distance(b, a.a)
			if gap > 0.5 and gap <= carry:
				found = true
	assert_true(found, "two parallel rails within %.2f units" % carry)


# --- Locking on, sliding, leaving -----------------------------------------------------------

func test_landing_along_a_rail_locks_on_slides_and_leaves_at_its_end() -> void:
	var car := _car(Vector2(2, 0.3), Vector2(10, 0), 1.6, 0.0)
	var ended: Array = []
	car.grind.grind_ended.connect(func(reason: String, seconds: float, length: float) -> void:
		ended.append([reason, seconds, length]))
	var steps := _step_until(car, func() -> bool: return car.grind.active, 100)
	assert_lt(steps, 100, "locked on")
	assert_eq(car.grind.rail_index, 0)
	assert_false(car.airborne)
	assert_almost_eq(car.height, 1.0, 1e-6, "on the bar")
	assert_almost_eq(car.model.get_position().y, 0.0, 1e-6, "snapped onto the rail's line")
	# It slides along, slowing by DECEL, steering doesn't take it off.
	var x0: float = car.model.get_position().x
	var v0: float = car.grind.speed
	car.scripted_input = [true, false, 1.0]
	for i in 10:
		car.physics_step()
	assert_true(car.grind.active, "still on the rail with W and A held")
	assert_gt(car.model.get_position().x, x0 + 1.5)
	assert_almost_eq(car.model.get_position().y, 0.0, 1e-6)
	assert_almost_eq(car.grind.speed, v0 - car.grind.decel * 10 * car.model.dt, 1e-6)
	assert_almost_eq(car.model.get_velocity().x, car.grind.speed, 1e-6, "the car's speed is the grind's")
	car.scripted_input = [false, false, 0.0]
	_step_until(car, func() -> bool: return not car.grind.active, 500)
	assert_false(car.grind.active)
	assert_eq(ended.size(), 1)
	assert_eq(ended[0][0], "end", "left at the rail's end")
	assert_gt(float(ended[0][1]), 1.0, "its seconds")
	assert_true(car.airborne, "off the end of a bar at height: it falls")
	assert_gt(car.model.get_position().x, 19.9)
	_step_until(car, func() -> bool: return not car.airborne, 200)
	assert_false(car.grind.active, "doesn't catch the rail it left")
	assert_almost_eq(car.height, 0.0, 1e-6, "landed on the street")


func test_landing_across_a_rail_does_not_lock_on() -> void:
	var car := _car(Vector2(10, -0.6), Vector2(0, 10), 1.6, 0.0)
	_step_until(car, func() -> bool: return not car.airborne, 200)
	assert_eq(car.grind.grinds, 0, "straight across")
	var diag := _car(Vector2(10, -0.6), Vector2(4.2, 9.1), 1.6, 0.0)  # 65 degrees off the rail
	_step_until(diag, func() -> bool: return not diag.airborne, 200)
	assert_eq(diag.grind.grinds, 0, "past max_angle_deg (60)")
	var close := _car(Vector2(2, -0.6), Vector2(6, 8), 1.6, 0.0)  # 53 degrees off: catches since 2026-11-06
	_step_until(close, func() -> bool: return close.grind.active or not close.airborne, 200)
	assert_true(close.grind.active, "within max_angle_deg")


func test_rising_or_too_far_or_too_slow_does_not_lock_on() -> void:
	var g = RailGrind.new()
	g.rails = Rails.from_layout(LAYOUT)
	assert_true(g.find(Vector2(5, 0.5), Vector2(10, 0), 1.0, -1.0).has("index"), "the reference catch")
	assert_eq(g.find(Vector2(5, 0.5), Vector2(10, 0), 1.0, 2.0), {}, "going up")
	assert_eq(g.find(Vector2(5, -g.reach - 0.1), Vector2(10, 0), 1.0, -1.0), {}, "beside it")
	assert_true(g.find(Vector2(5, -1.9), Vector2(10, 0), 1.0, -1.0).has("index"), "1.9 units beside it catches (was 1)")
	assert_eq(g.find(Vector2(5, 0.0), Vector2(1, 0), 1.0, -1.0), {}, "too slow")
	assert_eq(g.find(Vector2(5, 0.0), Vector2(10, 0), 1.0 + g.catch_above + 0.1, -1.0), {}, "above it")
	assert_eq(g.find(Vector2(5, 0.0), Vector2(10, 0), 1.0 - g.catch_below - 0.1, -1.0), {}, "under it")
	assert_eq(g.find(Vector2(-g.end_margin - 0.2, 0.0), Vector2(10, 0), 1.0, -1.0), {}, "past its end")
	assert_eq(int(g.find(Vector2(-0.4, 0.0), Vector2(10, 0), 1.0, -1.0).s), 0, "just past an end: from the end")


func test_a_car_on_the_ground_never_locks_on() -> void:
	var car := _car(Vector2(2, 0), Vector2(10, 0), 0.0, 0.0)
	for i in 50:
		car.physics_step()
	assert_eq(car.grind.grinds, 0)


func test_grinding_backwards_along_a_rail_works_either_way() -> void:
	var car := _car(Vector2(18, 0.2), Vector2(-10, 0), 1.6, 0.0)
	_step_until(car, func() -> bool: return car.grind.active, 100)
	assert_true(car.grind.active)
	assert_eq(car.grind.direction, -1.0)
	var x0: float = car.model.get_position().x
	car.physics_step()
	assert_lt(car.model.get_position().x, x0)


func test_too_slow_drops_the_car_off_beside_the_rail() -> void:
	var car := _car(Vector2(2, 0.2), Vector2(RailGrind.DEFAULTS.end_speed + 0.5, 0), 1.6, 0.0)
	var reasons: Array = []
	car.grind.grind_ended.connect(func(reason: String, _s: float, _l: float) -> void: reasons.append(reason))
	_step_until(car, func() -> bool: return car.grind.active, 100)
	assert_true(car.grind.active)
	car.scripted_input = [false, false, 1.0]  # A: the nose turns left of the rail line
	for i in 5:
		car.physics_step()
	car.scripted_input = [false, false, 0.0]
	_step_until(car, func() -> bool: return not car.grind.active, 200)
	assert_eq(reasons, ["slow"])
	assert_true(car.airborne)
	assert_lt(car.model.get_velocity().y, -1.0, "a sideways push off the bar, to the nose's side")


# --- Jumping between rails ------------------------------------------------------------------

func test_jump_while_grinding_hops_off_and_lands_on_the_second_rail() -> void:
	var car := _car(Vector2(1, 0.2), Vector2(10, 0), 1.6, 0.0, 1)
	var started: Array = []
	car.grind.grind_started.connect(func(i: int) -> void: started.append(i))
	var ended: Array = []
	car.grind.grind_ended.connect(func(reason: String, _s: float, _l: float) -> void: ended.append(reason))
	_step_until(car, func() -> bool: return car.grind.active, 100)
	assert_eq(started, [0])
	# D held (steer < 0, right): the nose turns right of the rail line; rail-b lies south of
	# rail-a, the right of a car going east.
	car.scripted_input = [false, false, -1.0]
	car.physics_step()
	car.press_jump()
	car.physics_step()
	assert_false(car.grind.active, "hopped off")
	assert_eq(ended, ["jump"])
	assert_true(car.airborne)
	assert_gt(car.vertical_speed, 0.0, "going up")
	assert_gt(car.model.get_velocity().y, 0.0, "toward the right")
	var v: Vector2 = car.model.get_velocity()
	assert_almost_eq(rad_to_deg(atan2(v.y, v.x)), car.grind.jump_angle_deg, 1e-3, "slightly diagonal: jump_angle_deg off the rail")
	assert_eq(car.jump.hops, 1)
	_step_until(car, func() -> bool: return car.grind.active or not car.airborne, 200)
	assert_true(car.grind.active, "landed on the second rail")
	assert_eq(started, [0, 1])
	assert_almost_eq(car.model.get_position().y, 3.5, 1e-6)


func test_a_jump_pressed_between_steps_while_grinding_is_kept_for_the_next_step() -> void:
	# A press that arrives after a grind step (from the keyboard, or a listener of `stepped`)
	# hops on the next step: the grind step doesn't throw it away.
	var car := _car(Vector2(1, 0.2), Vector2(10, 0), 1.6, 0.0, 1)
	_step_until(car, func() -> bool: return car.grind.active, 100)
	var pressed := [false]
	car.stepped.connect(func() -> void:
		if car.grind.active and not pressed[0]:
			pressed[0] = true
			car.press_jump())
	car.physics_step()
	assert_true(pressed[0])
	car.physics_step()
	assert_false(car.grind.active, "hopped off on the next step")
	assert_eq(car.jump.hops, 1)


func test_jump_without_the_power_up_does_nothing_on_a_rail() -> void:
	var car := _car(Vector2(1, 0.2), Vector2(10, 0), 1.6, 0.0, 0)
	_step_until(car, func() -> bool: return car.grind.active, 100)
	car.press_jump()
	car.physics_step()
	assert_true(car.grind.active)


func test_the_rail_left_is_not_caught_again_until_the_ground() -> void:
	var car := _car(Vector2(1, 0.2), Vector2(10, 0), 1.6, 0.0, 1)
	_step_until(car, func() -> bool: return car.grind.active, 100)
	car.scripted_input = [false, false, 1.0]  # A: the nose to the north, away from rail-b
	car.physics_step()
	car.press_jump()
	car.physics_step()
	assert_false(car.grind.active)
	assert_lt(car.model.get_velocity().y, 0.0, "hopping north")
	assert_eq(car.grind.exclude, 0, "rail-a is shut")
	assert_eq(car.grind.find(Vector2(5, 0.2), Vector2(10, 0), 1.0, -1.0), {}, "even right on it")
	_step_until(car, func() -> bool: return car.grind.active or not car.airborne, 200)
	assert_false(car.grind.active, "no rail where it lands")
	assert_eq(car.grind.exclude, -1, "free again once on the ground")
	assert_true(car.grind.find(Vector2(5, 0.2), Vector2(10, 0), 1.0, -1.0).has("index"))


# --- Paying the trick -----------------------------------------------------------------------

func test_a_grind_pays_the_grind_trick_from_combo_json() -> void:
	var data := ComboData.new()
	var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/combo.json"))
	var g: Dictionary = json.rail_grind
	assert_almost_eq(data.grind_add(2.0), minf(2.0 * float(g.add_per_second), float(g.max_add)), 1e-6)
	assert_almost_eq(data.grind_add(100.0), float(g.max_add), 1e-6, "held at max_add")
	assert_eq(data.grind_add(float(g.min_seconds) - 0.05), 0.0, "too short")
	assert_almost_eq(data.grind_subs(2.0), minf(2.0 * float(g.subs_per_second), float(g.max_subs)), 1e-6)
	var state: RunState = RunState.new()
	add_child_autofree(state)
	state.start_run()
	var tricks: Array = []
	state.combo_trick.connect(func(id: String, added: float, _m: float) -> void: tricks.append([id, added]))
	var subs: Array = []
	state.trick_subs_paid.connect(func(id: String, s: float) -> void: subs.append([id, s]))
	var before: float = state.combo
	state.add_grind_trick(2.0)
	assert_eq(tricks.size(), 1)
	assert_eq(tricks[0][0], "rail_grind")
	assert_almost_eq(float(tricks[0][1]), data.grind_add(2.0), 1e-6)
	assert_almost_eq(state.combo, before + data.grind_add(2.0), 1e-6, "adds to the combo")
	assert_eq(subs.size(), 1)
	assert_almost_eq(float(subs[0][1]), data.grind_subs(2.0) * before, 1e-6, "subs, times the combo before")
	state.add_grind_trick(0.1)
	assert_eq(tricks.size(), 1, "a touch of a rail pays nothing")


func test_the_grind_popup_uses_t533s_text() -> void:
	assert_eq(TrickPopupsScript.TEXTS.get("rail_grind"), "GRIND!")
	assert_eq(TrickPopupsScript.SIZES.get("rail_grind"), TrickPopupsScript.SIZE_NORMAL)


# --- The playtest switch --------------------------------------------------------------------

func test_the_playtest_switch_is_off_in_the_committed_data() -> void:
	var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/playtest.json"))
	assert_true(json.has("jump_at_start"))
	assert_eq(int(json.jump_at_start), 0, "off: runs start with no power-up")
	assert_eq(RunState.jump_at_start(), 0)
	var state: RunState = RunState.new()
	add_child_autofree(state)
	state.start_run()
	assert_eq(state.power_up_tier("jump"), 0)


func test_the_playtest_switch_starts_runs_with_the_jump_power_up() -> void:
	RunState.jump_at_start_override = 1
	var state: RunState = RunState.new()
	add_child_autofree(state)
	state.start_run()
	assert_eq(state.power_up_tier("jump"), 1)
	state.start_run()
	assert_eq(state.power_up_tier("jump"), 1, "every run")


# --- The drawing ----------------------------------------------------------------------------

func test_posts_stand_every_few_units_and_at_both_ends() -> void:
	assert_eq(RailDrawing.post_places(12.0), [0.0, 6.0, 12.0])
	assert_eq(RailDrawing.post_places(14.0), [0.0, 6.0, 12.0, 14.0])
	assert_eq(RailDrawing.post_places(12.5), [0.0, 6.0, 12.0], "one within a unit of the end is enough")


func test_screen_of_lifts_by_the_height() -> void:
	var p := RailDrawing.screen_of(Vector2(2, 1), 0.0)
	var q := RailDrawing.screen_of(Vector2(2, 1), 1.5)
	assert_eq(p, RailDrawing.ISO_TRANSFORM * Vector2(32, 16))
	assert_almost_eq(q.y, p.y - 24.0, 1e-6)
	assert_eq(q.x, p.x)


# --- The board's tweak (2026-11-06): steering on the rail and the diagonal jump -----------------

func test_the_numbers_come_from_rail_grind_json() -> void:
	var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/rail_grind.json"))
	var g = RailGrind.new()
	for k in RailGrind.DEFAULTS.keys():
		assert_true(json.has(k), k)
		assert_almost_eq(float(g.get(k)), float(json[k]), 1e-9, k)
	assert_gt(float(json.reach), 1.0, "easier to snap on than the first prototype's 1 unit")
	assert_gt(float(json.max_angle_deg), 45.0)
	assert_lt(float(json.max_angle_deg), 90.0, "a landing straight across still doesn't catch")


func test_a_and_d_spin_the_car_on_the_rail_at_the_air_turn_rate() -> void:
	var car := _car(Vector2(1, 0.2), Vector2(10, 0), 1.6, 0.0)
	_step_until(car, func() -> bool: return car.grind.active, 100)
	var h0: float = car.model.rotation
	assert_almost_eq(h0, 0.0, 1e-6, "it faces the way it landed (no snap across the rail)")
	car.scripted_input = [false, false, 1.0]
	for i in 25:
		car.physics_step()
	var want: float = -deg_to_rad(car.tuning.turn_rate_for(true) * 25 * car.model.dt)
	assert_almost_eq(car.model.rotation - h0, want, 1e-6, "A turns it as in the air")
	assert_true(car.grind.active, "still on the rail")
	assert_almost_eq(car.model.get_position().y, 0.0, 1e-6)
	assert_gt(car.model.get_velocity().x, 0.0, "still sliding along the rail")
	car.scripted_input = [false, false, -1.0]
	for i in 50:
		car.physics_step()
	assert_almost_eq(car.model.rotation - h0, -want, 1e-6, "D the other way")


func test_the_jump_goes_to_the_side_of_the_rail_line_the_nose_points_to() -> void:
	var g = RailGrind.new()
	g.rails = Rails.from_layout(LAYOUT)
	g.start({"index": 0, "s": 5.0, "speed_along": 10.0}, 0.0)
	assert_eq(g.nose_side(), 0.0, "exactly along the line")
	assert_eq(g.leave_velocity("jump"), Vector2(10, 0), "straight on")
	var a := deg_to_rad(g.jump_angle_deg)
	g.body_heading = deg_to_rad(-20.0)  # the nose a little to the north: left of a car going east
	assert_eq(g.nose_side(), 1.0)
	var v: Vector2 = g.leave_velocity("jump")
	assert_almost_eq(v.x, 10.0 * cos(a), 1e-6)
	assert_almost_eq(v.y, -10.0 * sin(a), 1e-6, "slightly left")
	g.body_heading = deg_to_rad(160.0)  # facing backwards, the nose to the south: right of the line
	assert_eq(g.nose_side(), -1.0)
	assert_almost_eq(g.leave_velocity("jump").y, 10.0 * sin(a), 1e-6, "slightly right")
	assert_almost_eq(g.leave_velocity("jump").length(), 10.0, 1e-6, "the speed is kept")


# --- Quick tuning 2 (board, 2026-11-06): no cooldown for a Jump off a rail -------------------

func test_a_jump_off_a_rail_ignores_the_regular_cooldown_and_leaves_it_alone() -> void:
	var car := _car(Vector2(1, 0.2), Vector2(10, 0), 1.6, 0.0, 1)
	_step_until(car, func() -> bool: return car.grind.active, 100)
	car.jump.cooldown_left = car.jump.cooldown_seconds  # as if it had just hopped
	var before: float = car.jump.cooldown_left
	car.press_jump()
	car.physics_step()
	assert_false(car.grind.active, "hopped off, cooldown or not")
	assert_true(car.airborne)
	assert_gt(car.vertical_speed, 0.0)
	assert_eq(car.jump.hops, 1)
	assert_lte(car.jump.cooldown_left, before, "not started again or extended")
	assert_gt(car.jump.cooldown_left, before - 2.0 * car.model.dt, "only ticked down as usual")


func test_two_rail_jumps_in_quick_succession() -> void:
	# rail-a, a Jump to the right onto rail-b, and at once a Jump off rail-b: well inside the
	# regular cooldown (2 s at tier 1).
	var car := _car(Vector2(1, 0.2), Vector2(10, 0), 1.6, 0.0, 1)
	_step_until(car, func() -> bool: return car.grind.active, 100)
	car.scripted_input = [false, false, -1.0]  # D: the nose right of the line, toward rail-b
	car.physics_step()
	car.scripted_input = [false, false, 0.0]
	car.press_jump()
	car.physics_step()
	var steps := _step_until(car, func() -> bool: return car.grind.active or not car.airborne, 200)
	assert_true(car.grind.active, "on rail-b")
	assert_eq(car.grind.rail_index, 1)
	assert_lt(float(steps + 2) * car.model.dt, car.jump.cooldown_seconds, "inside the regular cooldown")
	car.press_jump()
	car.physics_step()
	assert_false(car.grind.active, "jumped off rail-b at once")
	assert_eq(car.jump.hops, 2)


func test_off_the_rails_the_regular_jump_keeps_its_cooldown() -> void:
	var car := _car(Vector2(2, 10), Vector2(10, 0), 0.0, 0.0, 1)  # on the street, no rail near
	car.press_jump()
	car.physics_step()
	assert_eq(car.jump.hops, 1)
	_step_until(car, func() -> bool: return not car.airborne, 200)
	assert_gt(car.jump.cooldown_left, 0.0, "the cooldown still runs")
	car.press_jump()
	car.physics_step()
	assert_eq(car.jump.hops, 1, "a press during the cooldown does nothing on the ground")
