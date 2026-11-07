extends GutTest
## Task T-541: the rail grinding prototype (Drifting, Content, "Rail grinding (task T-541)"; the
## rail format: Level design, Content, "Rails (task T-541)"). Rails load from a level file; a car
## that lands on a rail moving along it locks on, slides along it and leaves at its end; one
## landing across it doesn't; letting go of Space while grinding launches off and can land on a
## second rail (T-551, the grind overhaul: a grind starts only while Space is held in the air and
## lasts while it stays held); a grind that ends pays the GRIND! trick (combo.json "rail_grind");
## the playtest switch starts runs with the Jump power-up and is off in the committed data.

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
## at `vz`, Space held (T-551: a grind starts only while it is held).
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
	car.scripted_jump_held = true
	if height > 0.0 or vz > 0.0:
		car.height_model.height = height
		car.height_model.leave_rail(vz)
	return car


## T-548: D (or A for negative degrees) on the rail until the nose is `deg` degrees right of the
## travel (left for negative), then lets go.
func _face(car, deg: float) -> void:
	var steer := -1.0 if deg > 0.0 else 1.0
	for i in 300:
		var off: float = rad_to_deg(car.grind.body_heading - car.grind.travel().angle())  # unwrapped
		if absf(off) >= absf(deg):
			break
		car.scripted_input = [false, false, steer]
		car.physics_step()
	car.scripted_input = [false, false, 0.0]


## T-551: lets go of Space for one step (the launch off the rail), then holds it again, so the
## car can catch the next rail.
func _launch(car) -> void:
	car.scripted_jump_held = false
	car.physics_step()
	car.scripted_jump_held = true


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


func test_the_game_map_has_the_boards_72_rails() -> void:
	# The board, 2026-11-06 (T-547): the default map is the board's Kaiju City with its own rails.
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GAME_MAP))
	assert_eq((data.get("rails", []) as Array).size(), 72, "72 rails in the game's map file")
	assert_eq(Rails.from_layout(data).size(), 72, "all 72 load as usable rails")


func test_two_parallel_rails_can_be_a_first_tier_jump_apart() -> void:
	# Two parallel rails at the same height, no further apart than a Jump tier 1 hop carries
	# the car sideways (T-548: jump_speed with the car facing 45 degrees off the rail, over the
	# hop's airtime) plus the reach. The test layout's pair (3.5 apart) is the example.
	var rails := Rails.from_layout(LAYOUT)
	var j = preload("res://scripts/driving/jump_power_up.gd").new()
	j.set_tier(1)
	var g = RailGrind.new()
	var carry: float = g.jump_speed * sin(deg_to_rad(45.0)) * j.airtime_for(j.takeoff_speed, 12.0) + g.reach
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
	# T-548: the landing boost's part fades at boost_decline on top of decel.
	assert_almost_eq(car.grind.speed, v0 - (car.grind.decel + car.grind.boost_decline) * 10 * car.model.dt, 1e-6)
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


# --- Jumping between rails (T-551: letting go of Space launches) -----------------------------

func test_letting_go_of_space_while_grinding_launches_and_lands_on_the_second_rail() -> void:
	var car := _car(Vector2(1, 0.2), Vector2(10, 0), 1.6, 0.0)
	var started: Array = []
	car.grind.grind_started.connect(func(i: int) -> void: started.append(i))
	var ended: Array = []
	car.grind.grind_ended.connect(func(reason: String, _s: float, _l: float) -> void: ended.append(reason))
	_step_until(car, func() -> bool: return car.grind.active, 100)
	assert_eq(started, [0])
	# D held (steer < 0, right): the nose turns about 40 degrees right of the rail line; rail-b
	# lies south of rail-a, the right of a car going east.
	_face(car, 40.0)
	var facing: float = car.model.rotation
	_launch(car)
	assert_false(car.grind.active, "launched off")
	assert_eq(ended, ["jump"])
	assert_true(car.airborne)
	assert_gt(car.vertical_speed, 0.0, "going up")
	assert_gt(car.model.get_velocity().y, 0.0, "toward the right")
	var v: Vector2 = car.model.get_velocity()
	assert_almost_eq(v.angle(), wrapf(facing, -PI, PI), 1e-3, "where the car faces (T-548)")
	assert_almost_eq(v.length(), car.grind.jump_speed, 1e-3, "at jump_speed")
	assert_eq(car.jump.hops, 0, "no power-up hop: any car launches")
	_step_until(car, func() -> bool: return car.grind.active or not car.airborne, 200)
	assert_true(car.grind.active, "landed on the second rail, Space held again")
	assert_eq(started, [0, 1])
	assert_almost_eq(car.model.get_position().y, 3.5, 1e-6)


func test_a_grind_starts_only_while_space_is_held() -> void:
	var car := _car(Vector2(2, 0.3), Vector2(10, 0), 1.6, 0.0)
	car.scripted_jump_held = false
	_step_until(car, func() -> bool: return not car.airborne, 200)
	assert_eq(car.grind.grinds, 0, "falls past the rail with Space let go")
	var held := _car(Vector2(2, 0.3), Vector2(10, 0), 1.6, 0.0)
	_step_until(held, func() -> bool: return held.grind.active or not held.airborne, 200)
	assert_true(held.grind.active, "the same landing with Space held catches it")


func test_holding_space_later_in_the_fall_still_catches() -> void:
	var car := _car(Vector2(2, 0.3), Vector2(10, 0), 1.9, 0.0)
	car.scripted_jump_held = false
	car.physics_step()
	car.physics_step()
	assert_false(car.grind.active)
	car.scripted_jump_held = true
	_step_until(car, func() -> bool: return car.grind.active or not car.airborne, 200)
	assert_true(car.grind.active, "held before reaching the bar: it catches")


func test_the_grind_lasts_while_space_is_held_and_ends_on_release() -> void:
	var long_rail := {"rails": [{"id": "long", "x1": 0.0, "y1": 0.0, "x2": 200.0, "y2": 0.0, "z1": 1.0, "z2": 1.0}]}
	var car := _car(Vector2(1, 0.2), Vector2(10, 0), 1.6, 0.0, 0, long_rail)
	_step_until(car, func() -> bool: return car.grind.active, 100)
	for i in 100:
		car.physics_step()
	assert_true(car.grind.active, "2 s held: still grinding")
	car.scripted_jump_held = false
	car.physics_step()
	assert_false(car.grind.active, "let go: off at once")
	assert_true(car.airborne)


func test_a_release_between_steps_while_grinding_launches_on_the_next_step() -> void:
	# A release that arrives after a grind step (from the keyboard, or a listener of `stepped`)
	# launches on the next step.
	var car := _car(Vector2(1, 0.2), Vector2(10, 0), 1.6, 0.0)
	_step_until(car, func() -> bool: return car.grind.active, 100)
	var released := [false]
	car.stepped.connect(func() -> void:
		if car.grind.active and not released[0]:
			released[0] = true
			car.scripted_jump_held = false)
	car.physics_step()
	assert_true(released[0])
	assert_true(car.grind.active, "the step that saw it held still grinds")
	car.physics_step()
	assert_false(car.grind.active, "launched on the next step")


func test_a_space_press_while_grinding_does_nothing() -> void:
	var car := _car(Vector2(1, 0.2), Vector2(10, 0), 1.6, 0.0, 1)
	_step_until(car, func() -> bool: return car.grind.active, 100)
	car.press_jump()
	car.physics_step()
	assert_true(car.grind.active, "Space still held: grinding")
	assert_eq(car.jump.hops, 0)


func test_the_rail_left_is_not_caught_again_until_the_ground() -> void:
	var car := _car(Vector2(1, 0.2), Vector2(10, 0), 1.6, 0.0, 1)
	_step_until(car, func() -> bool: return car.grind.active, 100)
	car.scripted_input = [false, false, 1.0]  # A: the nose to the north, away from rail-b
	car.physics_step()
	_launch(car)
	assert_false(car.grind.active)
	assert_lt(car.model.get_velocity().y, 0.0, "launched north")
	assert_eq(car.grind.exclude, 0, "rail-a is shut")
	assert_eq(car.grind.find(Vector2(5, 0.2), Vector2(10, 0), 1.0, -1.0), {}, "even right on it")
	_step_until(car, func() -> bool: return car.grind.active or not car.airborne, 200)
	assert_false(car.grind.active, "no rail where it lands")
	assert_eq(car.grind.exclude, -1, "free again once on the ground")
	assert_true(car.grind.find(Vector2(5, 0.2), Vector2(10, 0), 1.0, -1.0).has("index"))


func test_off_the_end_with_space_held_the_car_flies_on_and_catches_the_next_rail() -> void:
	# T-551's proposal: the rail ends while Space is held: no launch, the car flies on along the
	# rail (still tilted) and catches the next rail it reaches.
	var layout := {"rails": [
		{"id": "first", "x1": 0.0, "y1": 0.0, "x2": 8.0, "y2": 0.0, "z1": 1.5, "z2": 1.5},
		{"id": "next", "x1": 11.0, "y1": 0.0, "x2": 30.0, "y2": 0.0, "z1": 1.0, "z2": 1.0}]}
	var car := _car(Vector2(1, 0.2), Vector2(10, 0), 2.0, 0.0, 0, layout)
	var ended: Array = []
	car.grind.grind_ended.connect(func(reason: String, _s: float, _l: float) -> void: ended.append(reason))
	_step_until(car, func() -> bool: return car.grind.active, 100)
	_step_until(car, func() -> bool: return not car.grind.active, 200)
	assert_eq(ended, ["end"], "off the end, not a launch")
	assert_true(car.airborne)
	assert_lte(car.vertical_speed, 0.0, "no launch climb: it falls")
	assert_eq(car.tilt.step, car.tilt.FRAMES, "still tilted")
	_step_until(car, func() -> bool: return car.grind.active or not car.airborne, 200)
	assert_true(car.grind.active, "caught the next rail")
	assert_eq(car.grind.rail_index, 1)


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


# --- The board's tweak (2026-11-06): steering on the rail; T-548: the jump where the car faces ---

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


func test_the_jump_goes_where_the_car_faces_at_jump_speed() -> void:
	# T-548 (the board, 2026-11-06): where the nose points, at jump_speed, whatever the travel.
	var g = RailGrind.new()
	g.rails = Rails.from_layout(LAYOUT)
	g.start({"index": 0, "s": 5.0, "speed_along": 10.0}, 0.0)
	assert_almost_eq(g.leave_velocity("jump").x, g.jump_speed, 1e-6, "straight on: jump_speed, not the rail speed")
	assert_almost_eq(g.leave_velocity("jump").y, 0.0, 1e-6)
	g.body_heading = deg_to_rad(-20.0)  # the nose a little to the north
	var v: Vector2 = g.leave_velocity("jump")
	assert_almost_eq(v.angle(), deg_to_rad(-20.0), 1e-6, "along the nose")
	assert_almost_eq(v.length(), g.jump_speed, 1e-6)
	g.body_heading = deg_to_rad(110.0)  # sideways and back
	assert_almost_eq(g.leave_velocity("jump").angle(), deg_to_rad(110.0), 1e-6)
	g.body_heading = PI  # facing backwards: it jumps backwards (west), the rail's east travel lost
	assert_almost_eq(g.leave_velocity("jump").x, -g.jump_speed, 1e-6, "backwards")
	assert_almost_eq(g.leave_velocity("jump").y, 0.0, 1e-6)


func test_a_car_turned_180_degrees_jumps_off_backwards() -> void:
	var long_rail := {"rails": [{"id": "long", "x1": 0.0, "y1": 0.0, "x2": 200.0, "y2": 0.0, "z1": 1.0, "z2": 1.0}]}
	var car := _car(Vector2(1, 0.2), Vector2(10, 0), 1.6, 0.0, 1, long_rail)
	_step_until(car, func() -> bool: return car.grind.active, 100)
	_face(car, 179.0)
	assert_true(car.grind.active, "still on the rail")
	var facing: float = car.model.rotation
	assert_gt(absf(rad_to_deg(angle_difference(0.0, facing))), 170.0, "turned round")
	assert_gt(car.grind.velocity().x, 0.0, "still sliding east")
	car.scripted_jump_held = false  # T-551: let go of Space
	car.physics_step()
	assert_false(car.grind.active)
	var v: Vector2 = car.model.get_velocity()
	assert_lt(v.x, 0.0, "flying west, against its travel on the rail")
	assert_almost_eq(v.angle(), wrapf(facing, -PI, PI), 1e-3, "along the nose")
	assert_almost_eq(v.length(), car.grind.jump_speed, 1e-3, "at jump_speed")
	assert_gt(car.vertical_speed, 0.0, "a hop")
	assert_almost_eq(car.model.get_velocity().length(), car.grind.jump_speed, 1e-3, "the old momentum gone")


# --- T-548: the landing boost -----------------------------------------------------------------

func test_landing_adds_the_boost_and_it_declines_at_its_rate() -> void:
	var g = RailGrind.new()
	g.rails = Rails.from_layout({"rails": [{"id": "long", "x1": 0.0, "y1": 0.0, "x2": 200.0, "y2": 0.0, "z1": 1.0, "z2": 1.0}]})
	g.start({"index": 0, "s": 0.0, "speed_along": 11.0}, 0.0)
	assert_almost_eq(g.speed, 11.0 + g.land_boost, 1e-9, "the boost is added on landing")
	var dt := 1.0 / 50.0
	var boost_steps := int(round(g.land_boost / g.boost_decline / dt))
	for i in boost_steps:
		g.step(dt)
	assert_almost_eq(g.speed, 11.0 + g.land_boost - (g.decel + g.boost_decline) * boost_steps * dt, 1e-6,
		"the boost's part declines at boost_decline on top of decel")
	assert_almost_eq(g.boost_left, 0.0, 1e-6, "used up after land_boost / boost_decline seconds")
	var v: float = g.speed
	for i in 50:
		g.step(dt)
	assert_almost_eq(g.speed, v - g.decel * 50 * dt, 1e-6, "then only decel")


func test_the_boost_and_jump_numbers_are_in_the_data() -> void:
	var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/rail_grind.json"))
	assert_gt(float(json.land_boost), 0.0)
	assert_gt(float(json.boost_decline), 0.0)
	assert_gt(float(json.jump_speed), 0.0)
	assert_false(json.has("jump_angle_deg"), "the diagonal hop is replaced")


func test_every_landing_boosts_again() -> void:
	# rail-a, a launch onto rail-b: the second landing adds the boost to its speed along rail-b.
	var car := _car(Vector2(1, 0.2), Vector2(10, 0), 1.6, 0.0, 1)
	_step_until(car, func() -> bool: return car.grind.active, 100)
	_face(car, 40.0)
	_launch(car)
	var along := 0.0
	for i in 200:
		along = absf(car.model.get_velocity().x)  # the speed along rail-b (east) before the catch
		car.physics_step()
		if car.grind.active or not car.airborne:
			break
	assert_true(car.grind.active, "on rail-b")
	assert_eq(car.grind.grinds, 2)
	assert_almost_eq(car.grind.speed, along + car.grind.land_boost, 0.05, "its speed along rail-b plus the boost")
	assert_gt(car.grind.speed, car.grind.jump_speed, "faster than the jump left it")


func test_a_joint_is_not_a_new_landing() -> void:
	var g = RailGrind.new()
	g.rails = Rails.from_layout({"rails": [
		{"id": "p1", "x1": 0.0, "y1": 0.0, "x2": 10.0, "y2": 0.0, "z1": 1.0, "z2": 1.0},
		{"id": "p2", "x1": 10.0, "y1": 0.0, "x2": 20.0, "y2": 0.0, "z1": 1.0, "z2": 1.0}]})
	g.start({"index": 0, "s": 9.0, "speed_along": 11.0}, 0.0)
	var dt := 1.0 / 50.0
	var steps := 0
	while g.rail_index == 0 and steps < 100:
		assert_eq(g.step(dt), "")
		steps += 1
	assert_eq(g.rail_index, 1, "across the joint")
	assert_eq(g.joints, 1)
	assert_eq(g.grinds, 1, "one grind")
	g.step(dt)
	steps += 1
	assert_almost_eq(g.speed, 11.0 + g.land_boost - (g.decel + g.boost_decline) * steps * dt, 1e-6,
		"no new boost at the joint, the first one still declining")


# --- T-551: the launch needs no power-up; the Jump power-up's tier 2 launches higher -----------

func test_the_launch_climbs_at_launch_takeoff_speed_without_the_power_up() -> void:
	var car := _car(Vector2(1, 0.2), Vector2(10, 0), 1.6, 0.0, 0)
	_step_until(car, func() -> bool: return car.grind.active, 100)
	var effects: Array = []
	car.jump_started.connect(func(kind: String, _at: Vector2, h: float) -> void: effects.append([kind, h]))
	_launch(car)
	assert_false(car.grind.active)
	# One step of gravity has already run on the launch's climb.
	assert_almost_eq(car.vertical_speed, car.grind.launch_takeoff_speed - 12.0 * car.model.dt, 1e-6)
	assert_eq(effects.size(), 1, "the jump effect's signal")
	assert_eq(effects[0][0], "rail_launch")
	assert_almost_eq(float(effects[0][1]), 1.0, 1e-6, "from the bar's height")


func test_with_jump_tier_2_the_launch_uses_its_higher_takeoff() -> void:
	var car := _car(Vector2(1, 0.2), Vector2(10, 0), 1.6, 0.0, 2)
	assert_gt(car.jump.takeoff_speed, car.grind.launch_takeoff_speed)
	assert_almost_eq(car.launch_takeoff_speed(), car.jump.takeoff_speed, 1e-9)
	var tier1 := _car(Vector2(1, 0.2), Vector2(10, 0), 1.6, 0.0, 1)
	assert_almost_eq(tier1.launch_takeoff_speed(), maxf(tier1.grind.launch_takeoff_speed, tier1.jump.takeoff_speed), 1e-9)


func test_two_rail_launches_in_quick_succession() -> void:
	# rail-a, a launch to the right onto rail-b, and at once a launch off rail-b.
	var car := _car(Vector2(1, 0.2), Vector2(10, 0), 1.6, 0.0)
	_step_until(car, func() -> bool: return car.grind.active, 100)
	_face(car, 40.0)  # D: the nose 40 degrees right of the line, toward rail-b
	_launch(car)
	_step_until(car, func() -> bool: return car.grind.active or not car.airborne, 200)
	assert_true(car.grind.active, "on rail-b")
	assert_eq(car.grind.rail_index, 1)
	car.scripted_jump_held = false
	car.physics_step()
	assert_false(car.grind.active, "launched off rail-b at once")
