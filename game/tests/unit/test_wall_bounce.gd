extends GutTest
## Task T-435: the car really bounces off walls, even with W held (Drifting,
## Decisions, "The car bounces off walls", board 2026-10-30). The real car
## (car.gd) is driven into a building side, the map's edge, a boulder and a
## raised platform's side from the street, head-on, at about 45 degrees and
## while drifting, with W held the whole time; after the hit its distance from
## the wall must grow for a while instead of it staying pressed against it.
## Also: the bounce grows with the hit speed up to the cap, and W keeps working
## right after a hit (no throttle cut).
##
## The platform comes from the elevation test data (data/level/elevation_test.json,
## read only): 16 x 16 at (-8, -8), height 3. Headings: rotation 0 east,
## PI / 2 south (+y), PI west, -PI / 2 north.

const CarScript := preload("res://scripts/driving/car.gd")
const GroundHeightScript := preload("res://scripts/level/ground_height.gd")
const U := 16.0
## Steps watched after the hit (half a second).
const WATCH_STEPS := 25
## The car must get at least this far from where it hit (units).
const MIN_AWAY := 0.15

var _world: Node2D
var _hits: Array = []


func before_each() -> void:
	_world = Node2D.new()
	add_child_autofree(_world)
	_hits = []


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
	car.hit_obstacle.connect(func(c, i, n, s): _hits.append([c, i, n, s]))
	return car


func _rect(rect_units: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = CarScript.LAYER_OBSTACLES
	body.collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = rect_units.size * U
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = rect_units.get_center() * U
	body.add_child(cs)
	_world.add_child(body)


func _boulder(centre_units: Vector2, diameter_units: float) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = CarScript.LAYER_OBSTACLES
	body.collision_mask = 0
	var shape := CircleShape2D.new()
	shape.radius = diameter_units / 2.0 * U
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = centre_units * U
	body.add_child(cs)
	_world.add_child(body)


func _settle() -> void:
	await wait_physics_frames(2)


## Holds `input` until the first hit, then for WATCH_STEPS more steps. Returns
## {hit, impact, away}: away[i] = how far the car's centre is from where it hit,
## along the hit's normal, i + 1 steps after the hit (units).
func _run(car, input: Array, max_steps: int = 300) -> Dictionary:
	car.scripted_input = input
	for i in max_steps:
		car.physics_step()
		if not _hits.is_empty():
			break
	if _hits.is_empty():
		return {"hit": false, "impact": 0.0, "away": []}
	var n: Vector2 = _hits[0][2]
	var at: Vector2 = car.model.get_position()
	var away := []
	for i in WATCH_STEPS:
		car.physics_step()
		away.append((car.model.get_position() - at).dot(n))
	return {"hit": true, "impact": _hits[0][3], "away": away}


func _assert_bounces(r: Dictionary, what: String) -> void:
	assert_true(r.hit, "%s: the car hit it" % what)
	if not r.hit:
		return
	var away: Array = r.away
	assert_gt(float(away[0]), 0.0, "%s: one step after the hit the car has left the wall (%s)" % [what, away.slice(0, 5)])
	assert_gt(float(away[1]), float(away[0]), "%s: still moving away 2 steps after (%s)" % [what, away.slice(0, 5)])
	assert_gt(float(away[2]), float(away[1]), "%s: still moving away 3 steps after (%s)" % [what, away.slice(0, 5)])
	assert_gt(float(away.max()), MIN_AWAY, "%s: gets at least %.2f units away (max %.3f)" % [what, MIN_AWAY, float(away.max())])


const W := [true, false, 0.0]
const W_LEFT := [true, false, 1.0]


# --- A building's side (wall along y = -10, the car comes from the south) ----

func test_building_head_on() -> void:
	_rect(Rect2(-10, -12, 20, 2))
	var car = _car(Vector2(0, 0), -PI / 2.0)
	await _settle()
	_assert_bounces(_run(car, W), "building, head-on")


func test_building_at_45_degrees() -> void:
	_rect(Rect2(-10, -12, 20, 2))
	var car = _car(Vector2(-6, 0), -PI / 4.0)  # north-east
	await _settle()
	_assert_bounces(_run(car, W), "building, 45 degrees")


func test_building_while_drifting() -> void:
	_rect(Rect2(-10, -12, 20, 2))
	var car = _car(Vector2(0, -6.5), -PI / 2.0)
	await _settle()
	var r := _run(car, W_LEFT)
	assert_true(car.model.is_drifting, "drifting when it hit")
	_assert_bounces(r, "building, drifting")


# --- The map's edge (a long wall along x = 10, the car comes from the west) --

func test_map_edge_head_on() -> void:
	_rect(Rect2(10, -500, 2, 1000))
	var car = _car(Vector2(0, 0), 0.0)
	await _settle()
	_assert_bounces(_run(car, W), "map edge, head-on")


func test_map_edge_at_45_degrees() -> void:
	_rect(Rect2(10, -500, 2, 1000))
	var car = _car(Vector2(0, 0), -PI / 4.0)
	await _settle()
	_assert_bounces(_run(car, W), "map edge, 45 degrees")


func test_map_edge_while_drifting() -> void:
	_rect(Rect2(10, -500, 2, 1000))
	var car = _car(Vector2(6.5, 0), 0.0)
	await _settle()
	var r := _run(car, W_LEFT)
	assert_true(car.model.is_drifting, "drifting when it hit")
	_assert_bounces(r, "map edge, drifting")


# --- A boulder 3 units across ------------------------------------------------

func test_boulder_head_on() -> void:
	_boulder(Vector2(0, -11.5), 3.0)
	var car = _car(Vector2(0, 0), -PI / 2.0)
	await _settle()
	_assert_bounces(_run(car, W), "boulder, head-on")


func test_boulder_at_45_degrees() -> void:
	# Off-centre so the boulder's surface meets the car at about 45 degrees.
	_boulder(Vector2(0, -11.5), 3.0)
	var car = _car(Vector2(1.4, 0), -PI / 2.0)
	await _settle()
	var r := _run(car, W)
	if r.hit:
		var n: Vector2 = _hits[0][2]
		assert_almost_eq(absf(rad_to_deg(n.angle_to(Vector2.DOWN))), 45.0, 15.0, "hit at about 45 degrees (normal %s)" % n)
	_assert_bounces(r, "boulder, 45 degrees")


func test_boulder_while_drifting() -> void:
	_boulder(Vector2(0, -11.5), 3.0)
	var car = _car(Vector2(0.5, -6.5), -PI / 2.0)
	await _settle()
	var r := _run(car, W_LEFT)
	assert_true(car.model.is_drifting, "drifting when it hit")
	_assert_bounces(r, "boulder, drifting")


# --- A raised platform's side, from the street (north side y = -8) ----------

func test_platform_side_head_on() -> void:
	var car = _car(Vector2(0, -16), PI / 2.0, GroundHeightScript.from_file())
	_assert_bounces(_run(car, W), "platform side, head-on")


func test_platform_side_at_45_degrees() -> void:
	var car = _car(Vector2(-6, -16), PI / 4.0, GroundHeightScript.from_file())
	_assert_bounces(_run(car, W), "platform side, 45 degrees")


func test_platform_side_while_drifting() -> void:
	var car = _car(Vector2(0, -11.0), PI / 2.0, GroundHeightScript.from_file())
	var r := _run(car, W_LEFT)
	assert_true(car.model.is_drifting, "drifting when it hit")
	_assert_bounces(r, "platform side, drifting")


# --- The bounce grows with the hit, up to the cap ----------------------------

## Furthest the car gets from the wall after hitting it head-on at speed, W held.
func _bounce_distance(speed: float) -> float:
	_hits = []
	var car = _car(Vector2(0, -8.5), -PI / 2.0)  # 1 unit below the wall's side
	car.model.set_velocity(Vector2(0, -speed))
	var r := _run(car, W, 20)
	assert_true(r.hit, "hit at %.1f" % speed)
	car.queue_free()
	return float(r.away.max()) if r.hit else 0.0


func test_bounce_grows_with_the_hit_and_stops_at_the_cap() -> void:
	_rect(Rect2(-10, -12, 20, 2))
	await _settle()
	var cap: float = preload("res://scripts/driving/car_tuning.gd").new().wall_bounce_max_hit_speed
	assert_gt(cap, 11.0, "the cap is above cruise speed")
	var cruise := _bounce_distance(11.0)
	var harder := _bounce_distance(lerpf(11.0, cap, 0.5))
	var at_cap := _bounce_distance(cap + 1.0)
	var way_over := _bounce_distance(cap + 15.0)
	assert_gt(cruise, MIN_AWAY, "a cruise-speed hit bounces")
	assert_gt(harder, cruise + 0.05, "a harder hit bounces further (%.3f vs %.3f)" % [harder, cruise])
	assert_gt(at_cap, harder + 0.05, "harder still, further still (%.3f vs %.3f)" % [at_cap, harder])
	assert_almost_eq(way_over, at_cap, 1e-3, "above the cap every hit bounces the same distance")


# --- W keeps working after a hit (no throttle cut) ---------------------------

func test_w_still_acts_on_the_step_right_after_a_hit() -> void:
	_rect(Rect2(-10, -12, 20, 2))
	var a = _car(Vector2(-4, 0), -PI / 2.0)
	var b = _car(Vector2(4, 0), -PI / 2.0)
	await _settle()
	for car in [a, b]:
		_hits = []
		car.scripted_input = W
		for i in 300:
			car.physics_step()
			if not _hits.is_empty():
				break
		assert_eq(_hits.size(), 1, "hit")
	# Both have just hit and are in the same state (mirrored in x). One more
	# step: with W, without W.
	_hits = []
	var b_before: Vector2 = b.model.get_velocity()
	a.scripted_input = W
	a.physics_step()
	b.scripted_input = [false, false, 0.0]
	b.physics_step()
	assert_ne(a.model.get_velocity(), b.model.get_velocity(), "W changes the car's speed right after a hit")
	assert_lt(a.model.get_velocity().y, b_before.y, "W pulls the car back towards its nose (up)")
