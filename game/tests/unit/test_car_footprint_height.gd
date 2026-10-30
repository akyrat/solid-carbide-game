extends GutTest
## Task T-411: the car's height uses its whole drawn footprint (1 wide, 3 long,
## Drifting, Decisions, 2026-10-07), not only its centre, for the sides of
## raised areas (rooftops, ramps, T-405's short-building platforms).
##
## Before T-411 car_height.gd walked only the centre's path, so the drawn front
## 1.5 units passed over a side before the centre stopped, and turning was never
## checked. These tests drive the real car (car.gd) and check every point of the
## drawn outline after every physics step.
##
## Test ground (data/level/elevation_test.json): platform 16 x 16 at (-8, -8),
## height 3; ramp on its east side, 12 x 8 at (8, -4), 3 at x = 8, 0 at x = 20.
## Headings: rotation 0 east, PI / 2 south (+y), PI west, -PI / 2 north.

const CarScript := preload("res://scripts/driving/car.gd")
const CarHeight := preload("res://scripts/driving/car_height.gd")
const GroundHeightScript := preload("res://scripts/level/ground_height.gd")
const EPS := 1e-6
## How far an outline point may reach into a side: one walk piece.
const TOLERANCE := 0.05
const PLATFORM := Rect2(-8, -8, 16, 16)
const RAMP := Rect2(8, -4, 12, 8)
## The drawn car (car_flat.json): 3 long, 1 wide, around its centre.
const HALF_LENGTH := 1.5
const HALF_WIDTH := 0.5

var _world: Node2D
var _ground
var _hits := []


func before_each() -> void:
	_world = Node2D.new()
	add_child_autofree(_world)
	_ground = GroundHeightScript.from_file()
	_hits = []


func _car(start: Vector2, rotation: float, ground = null) -> CharacterBody2D:
	var car: CharacterBody2D = CarScript.new()
	car.model.set_position(start)
	car.model.rotation = rotation
	_world.add_child(car)
	car.set_physics_process(false)
	car.use_keyboard = false
	car.detect_tricks = false
	car.scripted_input = [true, false, 0.0]
	car.ground = _ground if ground == null else ground
	car.hit_obstacle.connect(func(c, i, n, s): _hits.append([c, i, n, s]))
	return car


## The drawn outline's corners and edge points, in flat units (independent of
## car_height.gd's own list, so the test checks it rather than copies it).
static func _outline(centre: Vector2, rotation: float) -> Array:
	var out := []
	for i in 7:
		var x := -HALF_LENGTH + i * 0.5
		out.append(centre + Vector2(x, -HALF_WIDTH).rotated(rotation))
		out.append(centre + Vector2(x, HALF_WIDTH).rotated(rotation))
	for y in [-0.25, 0.0, 0.25]:
		out.append(centre + Vector2(HALF_LENGTH, y).rotated(rotation))
		out.append(centre + Vector2(-HALF_LENGTH, y).rotated(rotation))
	return out


## How far point is inside rect (0 outside).
static func _depth(rect: Rect2, p: Vector2) -> float:
	if p.x <= rect.position.x or p.x >= rect.end.x or p.y <= rect.position.y or p.y >= rect.end.y:
		return 0.0
	return minf(minf(p.x - rect.position.x, rect.end.x - p.x), minf(p.y - rect.position.y, rect.end.y - p.y))


## The deepest any outline point of car is inside rect.
func _deepest(car: CharacterBody2D, rect: Rect2) -> float:
	var worst := 0.0
	for p in _outline(car.model.get_position(), car.model.rotation):
		worst = maxf(worst, _depth(rect, p))
	return worst


# --- The drawn body stops at a side -------------------------------------------------

func test_head_on_the_bumper_stops_at_the_side() -> void:
	var car := _car(Vector2(0, -14), PI / 2.0)  # south, towards the north side y = -8
	for i in 150:
		car.physics_step()
		assert_true(_deepest(car, PLATFORM) <= TOLERANCE, "step %d: the drawn car %.3f inside the side" % [i, _deepest(car, PLATFORM)])
		assert_eq(car.height, 0.0)
		assert_false(car.airborne)
	assert_eq(_hits.size(), 1, "one hit, W held against it")
	assert_eq(_hits[0][2], Vector2.UP)
	assert_almost_eq(car.model.get_position().y, -8.0 - HALF_LENGTH, 0.3, "the centre waits a half car length out")


func test_at_45_degrees_no_corner_enters() -> void:
	var car := _car(Vector2(-6, -16), PI / 4.0)  # south-east, towards the north side
	for i in 150:
		car.physics_step()
		assert_true(_deepest(car, PLATFORM) <= TOLERANCE, "step %d: %.3f inside" % [i, _deepest(car, PLATFORM)])
		assert_eq(car.height, 0.0)
	# One hit on the platform's north side. Task T-435: the car now really
	# bounces off it with W held, so further east it meets the ramp's north side
	# too (a second, different wall); no other hits.
	assert_between(_hits.size(), 1, 2)
	assert_eq(_hits[0][1], 0, "first, the platform's side")
	if _hits.size() == 2:
		assert_eq(_hits[1][1], 1, "then the ramp's side")
	for h in _hits:
		assert_eq(h[2], Vector2.UP, "north sides only")


func test_steering_into_a_side_from_standing_never_sweeps_the_nose_in() -> void:
	# Beside the north side, heading east, W and D: the nose turns south into it.
	var car := _car(Vector2(-4, -8.7), 0.0)
	car.scripted_input = [true, false, -1.0]
	for i in 100:
		car.physics_step()
		assert_true(_deepest(car, PLATFORM) <= TOLERANCE, "step %d: %.3f inside" % [i, _deepest(car, PLATFORM)])
	assert_gt(_hits.size(), 0, "it met the side")


func test_spinning_in_the_air_beside_a_side_never_sweeps_the_tail_in() -> void:
	var car := _car(Vector2(0, -9.0), 0.0)
	car.model.set_velocity(Vector2.ZERO)
	car.height_model.airborne = true
	car.height_model.height = 1.0
	car.height_model.vertical_speed = 4.0
	car.scripted_input = [false, false, 1.0]
	for i in 30:
		car.physics_step()
		if not car.airborne:
			break
		assert_true(_deepest(car, PLATFORM) <= TOLERANCE or car.height >= 3.0,
			"step %d: %.3f inside below the top" % [i, _deepest(car, PLATFORM)])


func test_height_3_next_to_6_bounces_at_the_bumper() -> void:
	var g = GroundHeightScript.new()
	g.load_data({"platforms": [
		{"id": "low", "x": -20, "y": -10, "w": 40, "h": 20, "height": 3.0},
		{"id": "high", "x": 0, "y": -10, "w": 10, "h": 20, "height": 6.0, "on": "low"},
	]})
	var car := _car(Vector2(-8, 0), 0.0, g)  # on 3, heading east into 6's west side
	assert_almost_eq(car.height, 3.0, EPS)
	for i in 120:
		car.physics_step()
		var worst := 0.0
		for p in _outline(car.model.get_position(), car.model.rotation):
			worst = maxf(worst, _depth(Rect2(0, -10, 10, 20), p))
		assert_true(worst <= TOLERANCE, "step %d: %.3f into the height-6 area" % [i, worst])
		assert_almost_eq(car.height, 3.0, EPS)
	assert_eq(_hits.size(), 1)


# --- No false walls --------------------------------------------------------------------

func test_touching_platforms_cross_with_no_wall() -> void:
	var g = GroundHeightScript.new()
	g.load_data({"platforms": [
		{"id": "a", "x": -20, "y": -4, "w": 10, "h": 8, "height": 3.0},
		{"id": "b", "x": -10, "y": -4, "w": 10, "h": 8, "height": 3.0},
		{"id": "c", "x": 0, "y": -4, "w": 10, "h": 8, "height": 3.0},
	]})
	for angle in [0.0, 0.3, -0.3]:
		var car := _car(Vector2(-17, 0), angle, g)
		for i in 60:
			car.physics_step()
			if absf(car.model.get_position().y) < 2.5 and car.model.get_position().x < 8.0:
				assert_almost_eq(car.height, 3.0, 0.01, "angle %s step %d" % [angle, i])
		assert_eq(_hits.size(), 0, "angle %s: no wall at the joins" % angle)
		car.free()


func test_up_the_ramp_at_three_speeds_no_false_wall_and_follows_the_slope() -> void:
	for speed in [4.0, 11.0, 16.5]:
		var car := _car(Vector2(19.5, 0), PI)
		car.scripted_input = [speed == 11.0, false, 0.0]
		car.model.set_velocity(Vector2(-speed, 0))
		for i in 40:
			if speed != 11.0:
				car.model.set_velocity(Vector2(-speed, 0))  # hold the speed
			car.physics_step()
			var pos: Vector2 = car.model.get_position()
			if _ground.is_ramp(pos) and not car.airborne:
				assert_almost_eq(car.height, _ground.height_at(pos), 0.01, "speed %s step %d" % [speed, i])
		assert_eq(_hits.size(), 0, "speed %s: no wall on the ramp" % speed)
		car.free()


func test_onto_the_ramp_at_an_angle_its_side_is_no_wall_for_the_body_on_it() -> void:
	# From the foot's south-east, heading up the ramp at an angle: the rear
	# corners cross the ramp's south side while the centre is already on it.
	# PI + 0.35 heads west-north-west (from the south-east), PI - 0.35 west-south-west.
	for angle in [PI + 0.35, PI - 0.35]:
		var start := Vector2(21.5, 2.5) if angle > PI else Vector2(21.5, -2.5)
		var car := _car(start, angle)
		var on_ramp := 0
		for i in 50:
			car.physics_step()
			var pos: Vector2 = car.model.get_position()
			if _ground.is_ramp(pos) and not car.airborne:
				on_ramp += 1
				assert_almost_eq(car.height, _ground.height_at(pos), 0.01)
		assert_gt(on_ramp, 10, "angle %s: it drove up the ramp" % angle)
		assert_eq(_hits.size(), 0, "angle %s: no wall" % angle)
		_hits = []
		car.free()


# --- The roof edge (today's rule: the car tips off when its centre passes the edge) -----

func test_roof_edge_at_low_speed_tips_off_when_the_centre_passes() -> void:
	var car := _car(Vector2(0, 6.5), PI / 2.0)  # on the top, heading south to y = 8
	car.scripted_input = [false, false, 0.0]
	var took := []
	car.height_model.took_off.connect(func(from_ramp, vz): took.append([from_ramp, car.model.get_position().y]))
	for i in 200:
		car.model.set_velocity(Vector2(0, 2))
		car.physics_step()
		if took.size() > 0:
			break
	assert_eq(took.size(), 1)
	assert_false(took[0][0], "a fall")
	assert_almost_eq(float(took[0][1]), 8.0, 0.1, "when the centre passes the edge")


# --- Ramps launch off their top, faster is higher (board, 2026-10-30) -----------------

func _peak_off_free_ramp(speed: float) -> Dictionary:
	var g = GroundHeightScript.new()
	g.load_data({"platforms": [], "ramps": [
		{"id": "r", "side": "east", "x": 0, "y": -2, "w": 4, "h": 4, "bottom_height": 0.0, "top_height": 2.0},
	]})
	var car := _car(Vector2(5.5, 0), PI, g)
	car.scripted_input = [false, false, 0.0]
	var out := {"from_ramp": false, "vz": 0.0, "peak": 0.0}
	car.height_model.took_off.connect(func(from_ramp, vz):
		out.from_ramp = from_ramp
		out.vz = vz)
	for i in 150:
		if not car.airborne:
			car.model.set_velocity(Vector2(-speed, 0))
		car.physics_step()
		out.peak = maxf(out.peak, car.height)
	car.free()
	return out


func test_a_free_standing_ramp_launches_higher_when_faster() -> void:
	var slow := _peak_off_free_ramp(11.0)
	var fast := _peak_off_free_ramp(16.5)
	assert_true(slow.from_ramp and fast.from_ramp, "both launch off the top")
	assert_gt(slow.vz, 0.0)
	assert_gt(fast.peak, slow.peak, "faster flies higher")
	assert_eq(_hits.size(), 0)


# --- The cost ----------------------------------------------------------------------------

func test_a_step_costs_under_half_a_millisecond_on_the_sample_map() -> void:
	var g = GroundHeightScript.from_file("res://data/level/elevation_sample_map.json")
	var m = CarHeight.new()
	m.ground = g
	var areas: Array = []
	for p in g.platforms:
		areas.append(p.rect)
	for r in g.ramps:
		areas.append(r.rect)
	var calls := 0
	var t0 := Time.get_ticks_usec()
	for rect in areas:
		for k in 8:
			var dir := Vector2.from_angle(k * PI / 4.0)
			var centre: Vector2 = rect.get_center() + dir * (maxf(rect.size.x, rect.size.y) * 0.5 + 0.5)
			m.reset(centre)
			var v := -dir * 16.5
			m.step(centre, centre + v * 0.02, v, 0.02, k * 0.7, k * 0.7 + 0.1)
			calls += 1
	var avg_ms := float(Time.get_ticks_usec() - t0) / 1000.0 / float(calls)
	gut.p("CarHeight.step: %.3f ms average over %d calls" % [avg_ms, calls])
	assert_lt(avg_ms, 0.5)
