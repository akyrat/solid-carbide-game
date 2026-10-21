extends GutTest
## Task T-184: how the platform's sides meet the car (car_height.gd's walk,
## car.gd's bounce off a side, GroundHeight.area_index_at and side_normal).
## Every case is a proposal for the board's playtest (Drifting, Content,
## "Elevation: the platform's sides").
##
## The test data's proposals (data/level/elevation_test.json): platform 16 x 16
## at (-8, -8), height 3; ramp on its east side, 12 x 8 at (8, -4), height
## (20 - x) / 4: 3 at x = 8, 0 at x = 20. Headings: rotation 0 east, PI / 2
## south (+y), PI west, -PI / 2 north.

const CarScript := preload("res://scripts/driving/car.gd")
const CarHeight := preload("res://scripts/driving/car_height.gd")
const GroundHeightScript := preload("res://scripts/level/ground_height.gd")
const EPS := 1e-6
const PLATFORM := Rect2(-8, -8, 16, 16)
const RAMP := Rect2(8, -4, 12, 8)

var _world: Node2D
var _ground
var _hits := []


func before_each() -> void:
	_world = Node2D.new()
	add_child_autofree(_world)
	_ground = GroundHeightScript.from_file()
	_hits = []


## A car at start (units) facing rotation, on the test ground, W held.
func _car(start: Vector2, rotation: float) -> CharacterBody2D:
	var car: CharacterBody2D = CarScript.new()
	car.model.set_position(start)
	car.model.rotation = rotation
	_world.add_child(car)
	car.set_physics_process(false)
	car.use_keyboard = false
	car.detect_tricks = false
	car.scripted_input = [true, false, 0.0]
	car.ground = _ground
	car.hit_obstacle.connect(func(c, i, n, s): _hits.append([c, i, n, s]))
	return car


## A bare height model on the test ground, in the air at point.
func _air(point: Vector2, h: float, vz: float) -> RefCounted:
	var m = CarHeight.new()
	m.ground = _ground
	m.reset(point)
	m.airborne = true
	m.height = h
	m.vertical_speed = vz
	return m


static func _inside(rect: Rect2, p: Vector2) -> bool:
	return p.x >= rect.position.x and p.x <= rect.end.x and p.y >= rect.position.y and p.y <= rect.end.y


# --- The ground's areas and sides -------------------------------------------

func test_area_index_and_side_normal() -> void:
	assert_eq(_ground.area_index_at(Vector2(30, 30)), -1, "street")
	assert_eq(_ground.area_index_at(Vector2(0, 0)), 0, "the platform")
	assert_eq(_ground.area_index_at(Vector2(14, 0)), 1, "the ramp: platforms.size() + 0")
	assert_eq(_ground.side_normal(0, Vector2(0, -8.1), Vector2(0, -7.9)), Vector2.UP)
	assert_eq(_ground.side_normal(0, Vector2(-8.1, 0), Vector2(-7.9, 0)), Vector2.LEFT)
	assert_eq(_ground.side_normal(0, Vector2(0, 8.1), Vector2(0, 7.9)), Vector2.DOWN)
	assert_eq(_ground.side_normal(1, Vector2(14, 4.1), Vector2(14, 3.9)), Vector2.DOWN)
	# A corner: crosses x = -8 first (halfway), then y = -8 (two thirds of the
	# way), so it enters through the north side; and the other way round.
	assert_eq(_ground.side_normal(0, Vector2(-8.05, -8.2), Vector2(-7.95, -7.9)), Vector2.UP)
	assert_eq(_ground.side_normal(0, Vector2(-8.2, -8.05), Vector2(-7.9, -7.95)), Vector2.LEFT)


# --- 1. A drop-off edge met from the ground below ----------------------------

func test_drop_off_edge_from_below_bounces_like_a_wall() -> void:
	var car := _car(Vector2(0, -14), PI / 2.0)  # south, towards the north side y = -8
	var hit_step := -1
	var v_before := Vector2.ZERO
	for i in 150:
		var v0: Vector2 = car.model.get_velocity()
		car.physics_step()
		var pos: Vector2 = car.model.get_position()
		assert_true(pos.y < -8.0, "never inside the platform (step %d)" % i)
		assert_false(car.airborne, "stays on the ground (step %d)" % i)
		assert_eq(car.height, 0.0, "stays at street height (step %d)" % i)
		if hit_step < 0 and _hits.size() > 0:
			hit_step = i
			v_before = v0
			# Bounce: the speed into the side comes back x wall_bounce.
			var impact: float = _hits[0][3]
			assert_gt(impact, 5.0, "it hit at speed")
			assert_almost_eq(car.model.get_velocity().y, -impact * float(car.tuning.wall_bounce), 1e-4)
			assert_gt(pos.y, -8.0 - CarHeight.SAMPLE_STEP - EPS, "stopped at the side")
	assert_gt(hit_step, 0, "it reached the side")
	assert_eq(_hits.size(), 1, "pressed against the side with W held: one hit")
	assert_eq(_hits[0][0], _ground, "the collider is the ground")
	assert_eq(_hits[0][1], 0, "the platform's area index")
	assert_eq(_hits[0][2], Vector2.UP, "the north side's normal")


func test_drop_off_edge_hit_rearms_after_backing_off() -> void:
	var car := _car(Vector2(0, -12), PI / 2.0)
	for i in 60:
		car.physics_step()
	assert_eq(_hits.size(), 1)
	car.scripted_input = [false, true, 0.0]  # reverse away
	for i in 40:
		car.physics_step()
	car.scripted_input = [true, false, 0.0]
	for i in 80:
		car.physics_step()
	assert_eq(_hits.size(), 2, "a new hit after leaving the side")


func test_car_high_enough_clears_the_side() -> void:
	var m := _air(Vector2(0, -8.3), 3.5, 0.0)
	var res: Dictionary = m.step(Vector2(0, -8.3), Vector2(0, -7.9), Vector2(0, 20), 0.02)
	assert_false(res.wall, "above the top: no wall")
	assert_true(m.airborne)
	assert_gt(m.height, 3.0)


func test_car_in_the_air_below_the_top_meets_the_side() -> void:
	var m := _air(Vector2(0, -8.3), 2.5, 0.0)
	var res: Dictionary = m.step(Vector2(0, -8.3), Vector2(0, -7.9), Vector2(0, 20), 0.02)
	assert_true(res.wall)
	assert_lt(res.point.y, -8.0, "stopped outside")
	assert_eq(res.normal, Vector2.UP)
	assert_almost_eq(res.wall_height, 3.0, EPS)
	assert_true(m.airborne, "still in the air, beside the platform")
	assert_lt(m.height, 2.5, "falling")


# --- 2. Landing ---------------------------------------------------------------

func test_ramp_jump_lands_on_top() -> void:
	var car := _car(Vector2(19.5, 0), PI)
	var was_air := false
	for i in 300:
		car.physics_step()
		if car.airborne:
			was_air = true
		elif was_air:
			assert_true(_inside(PLATFORM, car.model.get_position()), "over the top")
			assert_almost_eq(car.height, 3.0, EPS, "on the top")
			assert_eq(car.vertical_speed, 0.0)
			return
	fail_test("never landed")


func test_jump_ending_over_the_top_lands_on_top() -> void:
	# In the air beside the north side, above the top, flying south over it.
	var m := _air(Vector2(0, -9), 3.4, 1.0)
	var pos := Vector2(0, -9)
	var v := Vector2(0, 11)
	for i in 200:
		var next := pos + v * 0.02
		var res: Dictionary = m.step(pos, next, v, 0.02)
		assert_false(res.wall)
		pos = next
		if not m.airborne:
			assert_true(_inside(PLATFORM, pos))
			assert_almost_eq(m.height, 3.0, EPS)
			assert_eq(m.vertical_speed, 0.0)
			return
	fail_test("never landed")


func test_jump_ending_off_the_platform_lands_on_the_ground() -> void:
	# Off the west drop-off edge at speed: it flies past the edge and lands on the street.
	var car := _car(Vector2(0, 0), PI)
	var was_air := false
	for i in 300:
		car.physics_step()
		if car.airborne:
			was_air = true
		elif was_air:
			assert_false(_inside(PLATFORM, car.model.get_position()), "beside the platform")
			assert_almost_eq(car.height, 0.0, EPS, "on the ground")
			assert_eq(car.vertical_speed, 0.0)
			return
	fail_test("never landed")


func test_jump_ending_beside_the_platform_lands_on_the_ground() -> void:
	# Low, beside the north side and flying away from it.
	var m := _air(Vector2(0, -9), 0.5, 0.0)
	var pos := Vector2(0, -9)
	var v := Vector2(0, -11)
	for i in 100:
		var next := pos + v * 0.02
		m.step(pos, next, v, 0.02)
		pos = next
		if not m.airborne:
			assert_almost_eq(m.height, 0.0, EPS)
			return
	fail_test("never landed")


## Over a range of jumps towards the platform and the ramp (heights, vertical
## speeds, headings, speeds), the car never ends a physics step lower than the
## ground under it: never inside the platform or the ramp below its top.
func test_no_step_ends_inside_the_platform_below_its_top() -> void:
	var checked := 0
	var walls := 0
	var landed_on_top := 0
	var starts := [
		[Vector2(0, -12), PI / 2.0],    # north of it, heading south
		[Vector2(-12, 2), 0.0],         # west of it, heading east
		[Vector2(3, 12), -PI / 2.0],    # south of it, heading north
		[Vector2(-12, -12), PI / 4.0],  # north-west, heading at the corner
		[Vector2(14, -9), PI / 2.0],    # north of the ramp, heading south
	]
	for s in starts:
		for h in [0.3, 1.0, 2.0, 2.9, 3.2, 4.0, 6.0]:
			for vz in [-2.0, 0.0, 3.0, 6.0]:
				for steer in [0.0, 0.5]:
					var car := _car(s[0], s[1])
					car.scripted_input = [true, false, steer]
					car.height_model.airborne = true
					car.height_model.height = h
					car.height_model.vertical_speed = vz
					# T-219 (board: no drifting in the air): the car keeps its
					# velocity in the air, so it is launched at cruise speed
					# along its heading, as if it had jumped.
					car.model.set_velocity(Vector2.from_angle(s[1]) * car.tuning.forward_speed)
					var was_air := true
					for i in 150:
						car.physics_step()
						var pos: Vector2 = car.model.get_position()
						var under: float = _ground.height_at(pos)
						assert_true(car.height >= under - EPS,
							"start %s h %s vz %s steer %s step %d: height %s under ground %s at %s"
							% [s[0], h, vz, steer, i, car.height, under, pos])
						if _inside(PLATFORM, pos):
							assert_true(car.height >= 3.0 - EPS, "inside the platform below its top")
						if was_air and not car.airborne and _inside(PLATFORM, pos):
							landed_on_top += 1
						was_air = car.airborne
						checked += 1
					walls += _hits.size()
					_hits = []
					car.free()
	assert_gt(checked, 10000)
	assert_gt(walls, 10, "some jumps met a side")
	assert_gt(landed_on_top, 10, "some jumps landed on the top")


# --- 3. The ramp's sides --------------------------------------------------------

func test_driving_off_the_ramps_side_falls_to_the_ground() -> void:
	var car := _car(Vector2(14, 0), -PI / 2.0)  # on the ramp (height 1.5), heading north
	assert_almost_eq(car.height, 1.5, EPS)
	var took := []
	car.height_model.took_off.connect(func(from_ramp, vz): took.append([from_ramp, vz]))
	var landed := false
	var air_steps := 0
	for i in 200:
		car.physics_step()
		var pos: Vector2 = car.model.get_position()
		if took.size() == 1 and air_steps == 0 and car.airborne:
			assert_lt(pos.y, -4.0, "past the ramp's side")
			assert_almost_eq(car.height, 1.5, 0.01, "left at the ramp's height there, no snap down")
			assert_eq(took[0], [false, 0.0], "a fall, not a ramp takeoff")
		if car.airborne:
			air_steps += 1
		elif air_steps > 0:
			assert_almost_eq(car.height, 0.0, EPS, "landed on the ground")
			landed = true
			break
	assert_true(landed)
	assert_gt(air_steps, 3, "it fell with gravity over several steps")
	assert_eq(_hits.size(), 0, "no wall going down")


func test_driving_into_the_ramps_side_from_the_ground_is_a_wall() -> void:
	var car := _car(Vector2(14, -10), PI / 2.0)  # beside the ramp, heading south
	var side_heights := []
	for i in 120:
		var before: Vector2 = car.model.get_position()
		var res: Dictionary = car.height_model._walk(before, before + car.model.get_velocity() * car.model.dt, car.model.dt)
		if res.wall:
			side_heights.append(res.wall_height)
		car.physics_step()
		assert_lt(car.model.get_position().y, -4.0, "never on the ramp (step %d)" % i)
		assert_eq(car.height, 0.0)
		assert_false(car.airborne)
	assert_eq(_hits.size(), 1)
	assert_eq(_hits[0][1], 1, "the ramp's area index")
	assert_eq(_hits[0][2], Vector2.UP)
	assert_almost_eq(side_heights[0], (20.0 - 14.0) / 4.0, 0.02, "as high as the ramp there")


func test_ramp_side_lower_than_a_curb_is_driven_over() -> void:
	# Near the ramp's foot the side is lower than STEP_CLIMB_MAX: the car drives on.
	var car := _car(Vector2(19.85, -6), PI / 2.0)
	var on_ramp := false
	for i in 30:
		car.physics_step()
		if _ground.is_ramp(car.model.get_position()):
			on_ramp = true
			assert_false(car.airborne)
			assert_almost_eq(car.height, _ground.height_at(car.model.get_position()), EPS)
	assert_true(on_ramp)
	assert_eq(_hits.size(), 0)


func test_climbing_and_going_down_the_ramp_are_not_walls_or_drops() -> void:
	var car := _car(Vector2(19.5, 0), PI)  # up the ramp
	for i in 40:
		car.physics_step()
		if _ground.is_ramp(car.model.get_position()):
			assert_false(car.airborne)
	assert_eq(_hits.size(), 0)
	var down := _car(Vector2(9, 0), 0.0)  # from the ramp's top down its slope, east
	down.scripted_input = [false, false, 0.0]
	down.model.set_velocity(Vector2(3, 0))
	for i in 40:
		down.physics_step()
		if _ground.is_ramp(down.model.get_position()):
			assert_false(down.airborne)
			assert_almost_eq(down.height, _ground.height_at(down.model.get_position()), EPS)
	assert_eq(_hits.size(), 0)
