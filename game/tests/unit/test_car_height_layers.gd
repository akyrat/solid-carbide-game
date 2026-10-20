extends GutTest
## Task T-195: the car's height (car.gd and car_height.gd, the real code) on
## the elevation sample map's three layers (data/level/elevation_sample_map.json):
## the street (0), the first-floor rooftops (3) and the second-floor rooftops (6).
##
## The areas and ramps are picked from the file by their heights, never by
## coordinates, so a layout change doesn't break the tests: a 0-to-3 ramp, a
## 3-to-6 ramp, a side of a height-6 area with the height-3 area (or the
## street) past it.
##
## The last test runs in the sample map scene itself (T-196): the MVP map's tall
## buildings and boulders block the car on the street, on height 3, on height 6
## and in the air.

const CarScript := preload("res://scripts/driving/car.gd")
const CarHeight := preload("res://scripts/driving/car_height.gd")
const GroundHeightScript := preload("res://scripts/level/ground_height.gd")
const SampleScene := preload("res://scenes/elevation_sample/elevation_sample_map.tscn")
const MvpMapScript := preload("res://scripts/level/mvp_map.gd")
const LAYOUT := "res://data/level/elevation_sample_map.json"
const EPS := 1e-6

var _world: Node2D
var _ground
var _hits := []


func before_each() -> void:
	_world = Node2D.new()
	add_child_autofree(_world)
	_ground = GroundHeightScript.from_file(LAYOUT)
	_hits = []


## A car at start (units) facing rotation, on the sample map's ground, W held.
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


# --- Picking areas and ramps from the file, by their heights ------------------------

## The direction a ramp climbs, from its foot to its top (ground_height.gd's sides).
static func climb_dir(r: Dictionary) -> Vector2:
	match str(r.side):
		"east":
			return Vector2.LEFT
		"west":
			return Vector2.RIGHT
		"south":
			return Vector2.UP
		_:
			return Vector2.DOWN


static func ramp_length(r: Dictionary) -> float:
	var d := climb_dir(r)
	return r.rect.size.x if d.x != 0.0 else r.rect.size.y


static func foot_centre(r: Dictionary) -> Vector2:
	return r.rect.get_center() - climb_dir(r) * ramp_length(r) / 2.0


static func top_centre(r: Dictionary) -> Vector2:
	return r.rect.get_center() + climb_dir(r) * ramp_length(r) / 2.0


func _ramp(bottom: float, top: float) -> Dictionary:
	for r in _ground.ramps:
		if is_equal_approx(float(r.bottom_height), bottom) and is_equal_approx(float(r.top_height), top):
			return r
	return {}


## The point on a rectangle's side with outward normal n, at fraction f along it.
static func side_point(rect: Rect2, n: Vector2, f: float) -> Vector2:
	if n == Vector2.UP:
		return Vector2(lerpf(rect.position.x, rect.end.x, f), rect.position.y)
	if n == Vector2.DOWN:
		return Vector2(lerpf(rect.position.x, rect.end.x, f), rect.end.y)
	if n == Vector2.LEFT:
		return Vector2(rect.position.x, lerpf(rect.position.y, rect.end.y, f))
	return Vector2(rect.end.x, lerpf(rect.position.y, rect.end.y, f))


## The ground along a straight line, every half unit from `from` to `to` units
## from point along dir, is flat at height h and never a ramp (with 1 unit
## either side, so a car going straight stays on it).
func _flat_line(point: Vector2, dir: Vector2, from: float, to: float, h: float) -> bool:
	var across := Vector2(-dir.y, dir.x)
	var k := from
	while k <= to + EPS:
		for off in [-1.0, 0.0, 1.0]:
			var p: Vector2 = point + dir * k + across * off
			if _ground.is_ramp(p) or not is_equal_approx(_ground.height_at(p), h):
				return false
		k += 0.5
	return true


## A side of a height-6 area with flat height-6 ground inside it (`inside` units)
## and flat ground at `below` past it (`outside` units), no ramp on either:
## {"point" (on the side), "normal" (outward), "platform", "index"}, or {}.
func _side_of_6_over(below: float, inside: float = 6.0, outside: float = 14.0) -> Dictionary:
	for i in _ground.platforms.size():
		var p: Dictionary = _ground.platforms[i]
		if not is_equal_approx(float(p.height), 6.0):
			continue
		for n in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			for f in [0.5, 0.35, 0.65, 0.2, 0.8]:
				var e := side_point(p.rect, n, f)
				if _flat_line(e, -n, 0.5, inside, 6.0) and _flat_line(e, n, 0.5, outside, below):
					return {"point": e, "normal": n, "platform": p, "index": i}
	return {}


func test_the_file_has_the_three_layers_and_both_ramps() -> void:
	var heights := {}
	for p in _ground.platforms:
		heights[float(p.height)] = true
	assert_true(heights.has(3.0), "an area at height 3")
	assert_true(heights.has(6.0), "an area at height 6")
	assert_false(_ramp(0.0, 3.0).is_empty(), "a 0-to-3 ramp")
	assert_false(_ramp(3.0, 6.0).is_empty(), "a 3-to-6 ramp")


# --- Up the ramps ---------------------------------------------------------------------

## Drives straight up ramp r from `before` units in front of its foot: on the
## ramp, the height is the ground's height under the car on every step.
func _check_climb(r: Dictionary, below: float) -> void:
	var dir := climb_dir(r)
	var start := foot_centre(r) - dir * 2.0
	assert_almost_eq(_ground.height_at(start), below, EPS, "the ground in front of the foot")
	var car := _car(start, dir.angle())
	assert_almost_eq(car.height, below, EPS)
	var on_ramp := 0
	var last_h := below
	for i in 300:
		car.physics_step()
		var pos: Vector2 = car.model.get_position()
		if _ground.ramp_at(pos).get("id", "") == r.id:
			on_ramp += 1
			assert_false(car.airborne, "on the ramp, step %d" % i)
			assert_almost_eq(car.height, _ground.height_at(pos), EPS, "step %d" % i)
			assert_true(car.height >= last_h - EPS, "climbing, step %d" % i)
			last_h = car.height
		elif on_ramp > 0:
			break
	assert_gt(on_ramp, 10, "the car drove a while up %s" % r.id)
	assert_almost_eq(last_h, float(r.top_height), 0.3, "it reached the top")
	assert_eq(_hits.size(), 0, "no wall on the way up")


func test_up_a_0_to_3_ramp_the_height_follows_the_ramp() -> void:
	_check_climb(_ramp(0.0, 3.0), 0.0)


func test_up_a_3_to_6_ramp_the_height_follows_the_ramp() -> void:
	# Its foot is on a height-3 rooftop, not on the street.
	_check_climb(_ramp(3.0, 6.0), 3.0)


func test_off_a_3_to_6_ramps_top_at_cruise_speed_it_takes_off_with_the_slope() -> void:
	var r := _ramp(3.0, 6.0)
	var dir := climb_dir(r)
	# On the ramp 1 unit below its top, at rest: W snaps to cruise speed and the
	# car reaches the top a few steps later, still close to cruise.
	var car := _car(top_centre(r) - dir * 1.0, dir.angle())
	var took := []
	car.height_model.took_off.connect(func(from_ramp, vz): took.append([from_ramp, vz]))
	var cruise: float = car.tuning.forward_speed
	for i in 100:
		var before: Vector2 = car.model.get_position()
		var h_before: float = car.height
		car.physics_step()
		if car.airborne:
			var pos: Vector2 = car.model.get_position()
			assert_eq(_ground.ramp_at(before).get("id", ""), r.id, "it left from the 3-to-6 ramp")
			assert_false(_ground.is_ramp(pos), "past its top")
			var v: Vector2 = car.model.get_velocity()
			# W snaps to cruise speed, then climbs toward top speed: a few steps
			# later it is still within a unit/s of cruise.
			assert_between(v.length(), cruise, cruise + 1.0, "at cruise speed")
			var expected: float = CarHeight.ramp_vertical_speed(r, v) * CarHeight.RAMP_TAKEOFF_FACTOR
			assert_almost_eq(car.vertical_speed, expected, EPS, "ramp_vertical_speed x RAMP_TAKEOFF_FACTOR")
			assert_almost_eq(expected, v.dot(dir) * 3.0 / ramp_length(r) * CarHeight.RAMP_TAKEOFF_FACTOR, EPS)
			assert_gt(expected, 0.0)
			assert_almost_eq(car.height, h_before + expected * car.model.dt, EPS, "along the slope's line")
			assert_gt(car.height, 6.0, "above the height-6 rooftop")
			assert_eq(took.size(), 1)
			assert_true(took[0][0], "a ramp takeoff")
			return
	fail_test("never left the 3-to-6 ramp's top")


# --- Off a height-6 edge ----------------------------------------------------------------

## Drives straight off the side s (from _side_of_6_over) from 5 units inside it:
## the car falls off the edge and lands on the ground `below` past it.
func _check_drop(s: Dictionary, below: float) -> void:
	var n: Vector2 = s.normal
	var car := _car(s.point - n * 5.0, n.angle())
	assert_almost_eq(car.height, 6.0, EPS, "on the height-6 rooftop")
	var took := []
	var landings := []
	car.height_model.took_off.connect(func(from_ramp, vz): took.append([from_ramp, vz]))
	car.height_model.landed.connect(func(vz): landings.append(vz))
	var was_air := false
	for i in 300:
		car.physics_step()
		var pos: Vector2 = car.model.get_position()
		assert_true(car.height >= _ground.height_at(pos) - EPS, "never under the ground, step %d" % i)
		if car.airborne:
			was_air = true
		elif was_air:
			assert_gt((pos - s.point).dot(n), 0.0, "past the edge")
			assert_almost_eq(_ground.height_at(pos), below, EPS, "the ground under it")
			assert_almost_eq(car.height, below, EPS, "landed at %s" % below)
			assert_eq(car.vertical_speed, 0.0)
			assert_eq(took, [[false, 0.0]], "a fall off the edge, not a ramp takeoff")
			assert_eq(landings.size(), 1)
			assert_lt(landings[0], 0.0, "it was falling")
			assert_eq(_hits.size(), 0, "no wall")
			return
	fail_test("never landed")


func test_off_a_height_6_edge_it_lands_on_the_height_3_area_under_it() -> void:
	var s := _side_of_6_over(3.0)
	assert_false(s.is_empty(), "a height-6 side with the height-3 area past it")
	if not s.is_empty():
		_check_drop(s, 3.0)


func test_off_a_height_6_edge_it_lands_on_the_street_under_it() -> void:
	var s := _side_of_6_over(0.0)
	assert_false(s.is_empty(), "a height-6 side with the street past it")
	if not s.is_empty():
		_check_drop(s, 0.0)


# --- On a height-3 rooftop, the side of a height-6 area ---------------------------------

func test_on_a_height_3_rooftop_the_side_of_a_height_6_area_is_a_wall() -> void:
	var s := _side_of_6_over(3.0)
	assert_false(s.is_empty())
	if s.is_empty():
		return
	var n: Vector2 = s.normal
	var rect: Rect2 = s.platform.rect
	var car := _car(s.point + n * 6.0, (-n).angle())  # on the height-3 rooftop, heading at the side
	assert_almost_eq(car.height, 3.0, EPS)
	var hit_step := -1
	for i in 120:
		car.physics_step()
		var pos: Vector2 = car.model.get_position()
		assert_gt((pos - s.point).dot(n), 0.0, "never inside the height-6 area (step %d)" % i)
		assert_false(car.airborne, "stays on the rooftop (step %d)" % i)
		assert_almost_eq(car.height, 3.0, EPS, "stays at height 3 (step %d)" % i)
		if hit_step < 0 and _hits.size() > 0:
			hit_step = i
			var impact: float = _hits[0][3]
			assert_gt(impact, 5.0, "it hit at speed")
			# The bounce: the speed into the side comes back x wall_bounce.
			assert_almost_eq(car.model.get_velocity().dot(n), impact * float(car.tuning.wall_bounce), 1e-4)
	assert_gt(hit_step, 0, "it reached the side")
	assert_eq(_hits.size(), 1, "pressed against it with W held: one hit")
	assert_eq(_hits[0][0], _ground, "the collider is the ground")
	assert_eq(_hits[0][1], s.index, "the height-6 area's index")
	assert_eq(_hits[0][2], n, "the side's outward normal")
	assert_false(rect.has_point(car.model.get_position()))


# --- In the sample map scene: buildings and boulders block at every height --------------

## An obstacle of the map: {"kind", "rect" (its bounds), "centre", "radius" (boulders)}.
func _obstacles(data: Dictionary) -> Array:
	var out := []
	for b in data.buildings:
		var r := MvpMapScript.rect_of(b)
		out.append({"kind": "building", "rect": r, "centre": r.get_center(), "radius": 0.0})
	for copy in data.pattern_copies:
		for b in copy.boulders:
			var c := Vector2(float(b.x), float(b.y))
			var rad := float(b.diameter) / 2.0
			out.append({"kind": "boulder", "rect": Rect2(c - Vector2(rad, rad), Vector2(rad, rad) * 2.0),
				"centre": c, "radius": rad})
	return out


## Where the obstacle's surface faces direction s (outward), on the line through its centre.
static func _surface(o: Dictionary, s: Vector2) -> Vector2:
	if o.kind == "boulder":
		return o.centre + s * o.radius
	return side_point(o.rect, s, 0.5)


## True when the car's centre is inside the obstacle (its 1 x 1 body would overlap it more).
static func _inside_obstacle(o: Dictionary, p: Vector2) -> bool:
	if o.kind == "boulder":
		return p.distance_to(o.centre) < o.radius
	return o.rect.has_point(p)


## An approach to obstacle o from direction s: a clear, flat street strip 6 units
## long in front of it (no other obstacle, rooftop or ramp, inside the map).
## Returns the strip's rectangle (with the obstacle, grown by 2), or an empty Rect2.
func _approach(o: Dictionary, s: Vector2, all: Array, map_rect: Rect2) -> Rect2:
	var surface := _surface(o, s)
	var strip := Rect2(surface, Vector2.ZERO).expand(surface + s * 6.0).grow(1.5)
	var pad: Rect2 = strip.merge(o.rect).grow(2.0)
	if not map_rect.grow(-2.0).encloses(pad):
		return Rect2()
	for other in all:
		if other != o and other.rect.grow(1.0).intersects(strip):
			return Rect2()
	for p in _ground.platforms:
		if p.rect.intersects(pad):
			return Rect2()
	for r in _ground.ramps:
		if r.rect.intersects(pad):
			return Rect2()
	return pad


func test_in_the_sample_map_buildings_and_boulders_block_the_car_at_every_height() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
	var scene: Node2D = SampleScene.instantiate()
	add_child_autofree(scene)
	var car: CharacterBody2D = scene.car
	car.set_physics_process(false)
	car.use_keyboard = false
	car.detect_tricks = false
	var hits := []
	car.hit_obstacle.connect(func(c, i, n, sp): hits.append(c))
	await wait_physics_frames(2)

	var map_rect := MvpMapScript.rect_of(data.map.rect)
	var all := _obstacles(data)
	var tested := {"building": 0, "boulder": 0}
	var by_height := {"street": 0, "height 3": 0, "height 6": 0, "air": 0}
	for o in all:
		var s := Vector2.ZERO
		var pad := Rect2()
		for d in [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT]:
			pad = _approach(o, d, all, map_rect)
			if pad.has_area():
				s = d
				break
		if s == Vector2.ZERO:
			continue
		tested[o.kind] += 1
		var start: Vector2 = _surface(o, s) + s * 4.0
		for level in by_height.keys():
			var ground = scene.ground_height
			var h := 0.0
			if level == "height 3" or level == "height 6":
				# The layout keeps rooftops away from buildings and boulders, so a
				# temporary rooftop is raised under the approach and the obstacle.
				h = 3.0 if level == "height 3" else 6.0
				ground = GroundHeightScript.from_file(LAYOUT)
				ground.platforms.append({"id": "test-pad", "rect": pad, "height": h, "on": ""})
			scene.place_car(start, (-s).angle())
			car.ground = ground
			if level == "air":
				h = 8.0
				car.height_model.airborne = true
				car.height_model.height = h
				car.height_model.vertical_speed = 6.0
			assert_almost_eq(car.height, h, EPS, "%s %s: starts at its height" % [o.kind, level])
			hits.clear()
			car.scripted_input = [true, false, 0.0]
			var blocked := false
			for i in 40:
				car.physics_step()
				var pos: Vector2 = car.model.get_position()
				if _inside_obstacle(o, pos):
					fail_test("%s at %s, %s: the car drove into it (%s)" % [o.kind, o.centre, level, pos])
					break
				var body_hits := hits.filter(func(c) -> bool: return c != ground)
				if not body_hits.is_empty():
					var c = body_hits[0]
					var expected_body: bool = c == scene.map.walls if o.kind == "building" \
						else scene.map.boulder_bodies.has(c)
					assert_true(expected_body, "%s at %s, %s: hit the map's %s" % [o.kind, o.centre, level, o.kind])
					assert_lt((pos - _surface(o, s)).dot(s), 1.0, "%s %s: stopped at it" % [o.kind, level])
					if level == "air":
						assert_true(car.airborne, "%s: hit in the air" % o.kind)
						assert_gt(car.height, 6.0, "%s: well above the street" % o.kind)
					else:
						assert_false(car.airborne)
						assert_almost_eq(car.height, h, EPS, "%s: on the ground at %s" % [o.kind, h])
					blocked = true
					break
			assert_true(blocked, "%s at %s, %s: blocked" % [o.kind, o.centre, level])
			if blocked:
				by_height[level] += 1
	gut.p("Obstacles tested: %s; blocks per height: %s" % [tested, by_height])
	assert_eq(tested.building, data.buildings.size(), "every tall building")
	assert_gt(tested.boulder, 10, "many boulders")
	for level in by_height:
		assert_eq(by_height[level], tested.building + tested.boulder, "every obstacle blocks at %s" % level)
