extends GutTest
## Task T-601 (Drifting, Decisions, "The car never locks against a wall"): the car's nose pinned on a
## wall with W held must turn off it with W and A or D, and S must reverse it promptly.
##
## Two walls: a raised platform's side (data/level/elevation_test.json, read only: 16 x 16 at
## (-8, -8), height 3; its north side y = -8; the short buildings of the run's map are such
## platforms, T-405) and a building's side (a StaticBody2D, as the skyscrapers and the map's edge).
## The car starts with its nose just short of the wall at an angle off straight-on (0, 20, 45 and 70
## degrees, 70 the shallow one), W is held 1 s so it is pressed on it, then:
## - W with A, or W with D: it must be off the wall (its nose no longer points into the wall and it
##   has moved ESCAPE_UNITS from where it was pinned) within ESCAPE_MARGIN_SECONDS of the time the
##   turn itself takes at the full turn rate (the turn away from the wall is 90 degrees less the
##   angle, the turn through it 90 degrees plus the angle: 0.47 s straight on), and never later than
##   ESCAPE_MAX_SECONDS;
## - S alone, with the nose into the wall (0, 20, 45 degrees): its forward speed must be below 0 and
##   it must be REVERSE_AWAY_UNITS further from the wall within REVERSE_SECONDS. At 70 degrees W does
##   not hold the car on the wall at all (it drives along it at speed and past its end), so S there
##   must brake exactly as on the open road from the same speed: the wall adds no delay.
## Before the fix every platform case stayed where it was (the lock; the cause in
## game/docs/driving/collisions.md, "Against a raised area's side (T-601)"): test_the_old_stop_locks
## keeps that reproduction, with the slide turned off.

const CarScript := preload("res://scripts/driving/car.gd")
const CarHeightScript := preload("res://scripts/driving/car_height.gd")
const GroundHeightScript := preload("res://scripts/level/ground_height.gd")
const U := 16.0
const STEPS_PER_S := 50.0
const PIN_STEPS := 50
## The proposed limits (T-601's result notes): a full-rate turn of 90 degrees takes 0.47 s.
const ESCAPE_MARGIN_SECONDS := 0.15
const ESCAPE_MAX_SECONDS := 1.0
const ESCAPE_UNITS := 1.0
const REVERSE_SECONDS := 0.5
const REVERSE_AWAY_UNITS := 0.5
const ANGLES := [0.0, 20.0, 45.0, 70.0]

var _world: Node2D
var _saved_contact := {}


func before_each() -> void:
	_world = Node2D.new()
	add_child_autofree(_world)
	_saved_contact = CarHeightScript.wall_contact_config().duplicate()


func after_each() -> void:
	CarHeightScript._wall_contact = _saved_contact


func _car(start: Vector2, rotation: float, ground = null) -> CharacterBody2D:
	var car: CharacterBody2D = CarScript.new()
	car.model.set_position(start)
	car.model.rotation = rotation
	_world.add_child(car)
	car.set_physics_process(false)
	car.use_keyboard = false
	car.detect_tricks = false
	if ground != null:
		car.ground = ground
	return car


func _building() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = CarScript.LAYER_OBSTACLES
	body.collision_mask = 0
	var shape := RectangleShape2D.new()
	var r := Rect2(-10, -12, 20, 2)
	shape.size = r.size * U
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = r.get_center() * U
	body.add_child(cs)
	_world.add_child(body)


## A car with its nose 0.02 units short of the wall, `off_deg` off straight-on, pressed on it with W
## for PIN_STEPS steps. Returns {car, n (the wall's normal, out of it), face (the wall's y)}.
func _pinned(kind: String, off_deg: float) -> Dictionary:
	var car
	var n: Vector2
	var face: float
	var r := deg_to_rad(off_deg)
	if kind == "building":
		_building()
		n = Vector2(0, 1)
		face = -10.0
		# The body is a 1 x 1 square: its nose corner reaches 0.5 (cos + sin) from the centre.
		car = _car(Vector2(0, face + 0.5 * (cos(r) + sin(r)) + 0.02), -PI / 2.0 + r)
	else:
		n = Vector2(0, -1)
		face = -8.0
		# The drawn outline is 3 x 1: its nose corner reaches 1.5 cos + 0.5 sin.
		car = _car(Vector2(0, face - (1.5 * cos(r) + 0.5 * sin(r)) - 0.02), PI / 2.0 + r,
			GroundHeightScript.from_file())
	await wait_physics_frames(2)
	car.scripted_input = [true, false, 0.0]
	for i in PIN_STEPS:
		car.physics_step()
	return {"car": car, "n": n, "face": face}


## Steps until the car is off the wall with `input` held (or -1 within max_steps).
func _escape_steps(p: Dictionary, input: Array, max_steps: int = 150) -> int:
	var car = p.car
	var n: Vector2 = p.n
	var at: Vector2 = car.model.get_position()
	car.scripted_input = input
	for i in max_steps:
		car.physics_step()
		var nose := Vector2(cos(car.model.rotation), sin(car.model.rotation))
		if nose.dot(n) >= 0.0 and car.model.get_position().distance_to(at) >= ESCAPE_UNITS:
			return i + 1
	return -1


## Steps until S has the car reversing and REVERSE_AWAY_UNITS further from the wall (or -1).
func _reverse_steps(p: Dictionary, max_steps: int = 150) -> int:
	var car = p.car
	var n: Vector2 = p.n
	var at: Vector2 = car.model.get_position()
	car.scripted_input = [false, true, 0.0]
	for i in max_steps:
		car.physics_step()
		if car.model.forward_speed() < 0.0 and (car.model.get_position() - at).dot(n) >= REVERSE_AWAY_UNITS:
			return i + 1
	return -1


func _check_escape(kind: String, steer: float) -> void:
	for off in ANGLES:
		before_each()
		var p := await _pinned(kind, off)
		var car = p.car
		var nose := Vector2(cos(car.model.rotation), sin(car.model.rotation))
		# A (steer +1) turns the nose counter-clockwise on screen (rotation falls).
		var turning := nose.rotated(-0.1 * steer)
		var through: bool = turning.dot(p.n) < nose.dot(p.n)
		var turn_deg: float = 90.0 + off if through else 90.0 - off
		var turn_s: float = turn_deg / float(car.tuning.turn_rate())
		var steps := _escape_steps(p, [true, false, steer])
		var what := "%s, %d degrees, W + %s" % [kind, off, "A" if steer > 0.0 else "D"]
		gut.p("T-601 %s: off the wall after %d steps (%.2f s; the %d-degree turn alone %.2f s)" % [
			what, steps, steps / STEPS_PER_S, turn_deg, turn_s])
		assert_gt(steps, 0, "%s: the car gets off the wall" % what)
		assert_lte(steps / STEPS_PER_S, turn_s + ESCAPE_MARGIN_SECONDS, "%s: within the turn's time + %.2f s" % [what, ESCAPE_MARGIN_SECONDS])
		assert_lte(steps / STEPS_PER_S, ESCAPE_MAX_SECONDS, "%s: within %.1f s" % [what, ESCAPE_MAX_SECONDS])


func _check_reverse(kind: String) -> void:
	for off in [0.0, 20.0, 45.0]:
		before_each()
		var p := await _pinned(kind, off)
		var steps := _reverse_steps(p)
		var what := "%s, %d degrees, S" % [kind, off]
		gut.p("T-601 %s: reversing and %.1f units off after %d steps (%.2f s)" % [what, REVERSE_AWAY_UNITS, steps, steps / STEPS_PER_S])
		assert_gt(steps, 0, "%s: the car reverses off the wall" % what)
		assert_lte(steps / STEPS_PER_S, REVERSE_SECONDS, "%s: within %.1f s" % [what, REVERSE_SECONDS])


## At 70 degrees: S brakes from the speed the car has along the wall in exactly the steps the open
## road takes from that speed (fwd / the ramp rate per step), plus at most one step.
func _check_shallow_brake(kind: String) -> void:
	var p := await _pinned(kind, 70.0)
	var car = p.car
	var f0: float = car.model.forward_speed()
	var per_step: float = car.tuning.ramp_delta(car.model.dt)
	var expected := ceili(f0 / per_step)
	car.scripted_input = [false, true, 0.0]
	var steps := -1
	for i in 300:
		car.physics_step()
		if car.model.forward_speed() < 0.0:
			steps = i + 1
			break
	gut.p("T-601 %s, 70 degrees, S: reversing after %d steps (%.2f s) from %.2f units/s; the open road %d steps" % [
		kind, steps, steps / STEPS_PER_S, f0, expected])
	assert_gt(steps, 0, "%s, 70 degrees: S reverses" % kind)
	assert_lte(steps, expected + 1, "%s, 70 degrees: S brakes as on the open road" % kind)


func test_platform_side_shallow_s_brakes_as_on_the_road() -> void:
	await _check_shallow_brake("platform")


func test_building_shallow_s_brakes_as_on_the_road() -> void:
	await _check_shallow_brake("building")


## The board's case: pressed on the wall, W with A or D held a moment (0.3 s, the old lock), then
## W let go and S held. S must have the car reversing within REVERSE_SECONDS plus the open road's
## braking from the speed the car really moved at on the step before S (no stored speed the car
## never had: before T-601 the locked car kept W's speed, up to the top speed, while standing still,
## and S first had to brake all of it, 2.3 s from the top speed).
func _check_s_after_steer(kind: String, steer: float) -> void:
	for off in ANGLES:
		before_each()
		var p := await _pinned(kind, off)
		var car = p.car
		car.scripted_input = [true, false, steer]
		var last: Vector2 = car.model.get_position()
		for i in 15:
			last = car.model.get_position()
			car.physics_step()
		var real: float = (car.model.get_position() - last).length() / car.model.dt
		var f0: float = car.model.forward_speed()
		var per_step: float = car.tuning.ramp_delta(car.model.dt)
		car.scripted_input = [false, true, 0.0]
		var steps := -1
		for i in 300:
			car.physics_step()
			if car.model.forward_speed() < 0.0:
				steps = i + 1
				break
		var what := "%s, %d degrees, W + %s then S" % [kind, off, "A" if steer > 0.0 else "D"]
		gut.p("T-601 %s: reversing after %d steps (%.2f s); forward speed %.2f, real speed %.2f units/s" % [
			what, steps, steps / STEPS_PER_S, f0, real])
		assert_gt(steps, 0, "%s: S reverses" % what)
		assert_lte(steps / STEPS_PER_S, REVERSE_SECONDS + ceilf(maxf(0.0, real) / per_step) / STEPS_PER_S,
			"%s: S brakes only the speed the car really had" % what)


func test_platform_side_s_after_w_and_a() -> void:
	await _check_s_after_steer("platform", 1.0)


func test_platform_side_s_after_w_and_d() -> void:
	await _check_s_after_steer("platform", -1.0)


func test_building_s_after_w_and_a() -> void:
	await _check_s_after_steer("building", 1.0)


func test_platform_side_w_and_a_turns_off() -> void:
	await _check_escape("platform", 1.0)


func test_platform_side_w_and_d_turns_off() -> void:
	await _check_escape("platform", -1.0)


func test_platform_side_s_reverses() -> void:
	await _check_reverse("platform")


func test_building_w_and_a_turns_off() -> void:
	await _check_escape("building", 1.0)


func test_building_w_and_d_turns_off() -> void:
	await _check_escape("building", -1.0)


func test_building_s_reverses() -> void:
	await _check_reverse("building")


## The reproduction (before T-601): with the old stop (slide off), the car pinned on a platform's
## side with W and A or D held does not move or turn at all for a whole second.
func test_the_old_stop_locks() -> void:
	CarHeightScript._wall_contact = {"slide_on": false, "pivot_max_push": 0.15, "pivot_push_tries": 6}
	for steer in [1.0, -1.0]:
		before_each()
		CarHeightScript._wall_contact = {"slide_on": false, "pivot_max_push": 0.15, "pivot_push_tries": 6}
		var p := await _pinned("platform", 0.0)
		var car = p.car
		car.scripted_input = [true, false, steer]
		for i in 10:
			car.physics_step()
		var at: Vector2 = car.model.get_position()
		var rot: float = car.model.rotation
		for i in 50:
			car.physics_step()
		assert_lt(car.model.get_position().distance_to(at), 0.01, "old stop: the car does not move")
		assert_lt(absf(car.model.rotation - rot), 0.01, "old stop: the car does not turn")


## The slide keeps the hit: pinned on the side the car still counts as touching it (one hit, the
## bounce runs) and a held W against it keeps the car on the wall's side of the side, never in it.
func test_never_inside_the_platform() -> void:
	for off in ANGLES:
		before_each()
		var p := await _pinned("platform", off)
		var car = p.car
		var ground = car.ground
		car.scripted_input = [true, false, 1.0]
		for i in 60:
			car.physics_step()
			for o in CarHeightScript.OUTLINE:
				var q: Vector2 = car.model.get_position() + o.rotated(car.model.rotation)
				assert_lt(float(ground.height_at(q)), 0.5, "%d degrees: the outline stays off the platform (step %d)" % [off, i])
