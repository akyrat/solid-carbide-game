extends GutTest
## Task T-033: the car's collisions. Bouncing off walls and boulders, passing
## through enemies, the hit_obstacle signal, knockback, the bounce slider, the
## test room and the collision layers.
##
## The car runs one physics step per physics_step() call (its own
## _physics_process is off), against static bodies built here in units.

const CarScript := preload("res://scripts/driving/car.gd")
const PrototypeScene := preload("res://scenes/drift_prototype/drift_prototype.tscn")
const TestRoom := preload("res://scripts/driving/test_room.gd")
const U := 16.0

var _world: Node2D
var _hits: Array = []


func before_each() -> void:
	_world = Node2D.new()
	add_child_autofree(_world)
	_hits = []


## A car at the origin, nose up (-y), driven by scripted input.
func _car() -> CharacterBody2D:
	var car: CharacterBody2D = CarScript.new()
	_world.add_child(car)
	car.set_physics_process(false)
	car.use_keyboard = false
	car.hit_obstacle.connect(func(c, i, n, s): _hits.append([c, i, n, s]))
	return car


func _wall(rect_units: Rect2, layer: int = CarScript.LAYER_OBSTACLES) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = rect_units.size * U
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = rect_units.get_center() * U
	body.add_child(cs)
	_world.add_child(body)
	return body


func _boulder(centre_units: Vector2, diameter_units: float) -> StaticBody2D:
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
	return body


## New static bodies join the physics space's broadphase on the next physics frame.
func _settle() -> void:
	await wait_physics_frames(2)


func _drive(car, steps: int, w: bool, s: bool, steer: float) -> void:
	car.scripted_input = [w, s, steer]
	for i in steps:
		car.physics_step()


## Holds W until the first hit (at most max_steps). Returns the car's speed into
## the obstacle on the step it hit, or -1 if it never hit.
func _drive_until_hit(car, max_steps: int) -> float:
	car.scripted_input = [true, false, 0.0]
	for i in max_steps:
		var before := _hits.size()
		car.physics_step()
		if _hits.size() > before:
			return _hits[-1][3]
	return -1.0


# --- Bounce -------------------------------------------------------------------------------

## Drives straight up into an obstacle whose near side is at y = -near_y units,
## then checks the car stopped at it and bounced back with a small speed.
func _check_straight_bounce(car, near_y: float) -> void:
	var impact := _drive_until_hit(car, 200)
	assert_gt(impact, 0.0, "the car hit the obstacle")
	var v: Vector2 = car.model.get_velocity()
	assert_gt(v.y, 0.0, "after the hit the car moves away from the obstacle (down)")
	var bounce_speed := v.length()
	assert_gt(bounce_speed, 0.0, "bounce speed is not zero")
	assert_lt(bounce_speed, impact, "bounce speed is less than the speed it hit with")
	assert_almost_eq(bounce_speed, impact * car.tuning.wall_bounce, 1e-3, "bounce = impact x wall bounce")
	var top_edge: float = car.position.y / U - 0.5
	assert_gt(top_edge, -near_y - 0.01, "the car's body did not pass into the obstacle")
	# Let go of W: the car rolls away from the obstacle.
	var y_at_hit: float = car.position.y
	_drive(car, 5, false, false, 0.0)
	assert_gt(car.position.y, y_at_hit, "the car moves away after the hit")
	# Holding W into it for a long time never gets it through.
	_drive(car, 150, true, false, 0.0)
	assert_gt(car.position.y / U - 0.5, -near_y - 0.01, "W held: still not through")


func test_car_bounces_off_a_wall() -> void:
	_wall(Rect2(-10, -12, 20, 2))
	var car = _car()
	await _settle()
	_check_straight_bounce(car, 10.0)


func test_car_bounces_off_a_boulder_3_units_across() -> void:
	_boulder(Vector2(0, -11.5), 3.0)
	var car = _car()
	await _settle()
	_check_straight_bounce(car, 10.0)


func test_bounce_at_top_speed_is_still_small() -> void:
	_wall(Rect2(-10, -70, 20, 2))
	var car = _car()
	car.tuning.top_speed_multiplier = 3.0  # pinned at the pre-experiment top speed, 33
	await _settle()
	var impact := _drive_until_hit(car, 400)
	assert_gt(impact, 30.0, "hit near top speed (33)")
	assert_almost_eq(car.model.get_velocity().length(), impact * 0.25, 1e-3, "default bounce 0.25")


func test_glancing_hit_keeps_the_speed_along_the_wall() -> void:
	# A wall to the car's left; the car drives up and to the left into it.
	_wall(Rect2(-12, -40, 2, 80))
	var car = _car()
	car.tuning.top_speed_multiplier = 3.0  # pinned at the pre-experiment top speed, 33
	car.model.rotation = deg_to_rad(-120.0)  # nose up and to the left
	car.rotation = car.model.rotation
	await _settle()
	var impact := _drive_until_hit(car, 200)
	assert_gt(impact, 0.0, "hit the wall")
	var v: Vector2 = car.model.get_velocity()
	assert_gt(v.x, 0.0, "pushed away from the wall (to the right)")
	assert_almost_eq(v.x, impact * car.tuning.wall_bounce, 1e-3, "bounce across the wall")
	assert_lt(v.y, -1.0, "keeps moving up along the wall")


func test_driving_away_after_a_hit_works_as_before() -> void:
	_wall(Rect2(-10, -12, 20, 2))
	var car = _car()
	car.tuning.top_speed_multiplier = 3.0  # pinned at the pre-experiment top speed, 33
	await _settle()
	_drive_until_hit(car, 200)
	# Reverse away: S snaps to reverse cruise speed and climbs as on open ground.
	var y_at_hit: float = car.position.y
	_drive(car, 20, false, true, 0.0)
	assert_lt(car.model.forward_speed(), -10.99, "reversing at cruise speed or faster")
	assert_gt(car.position.y, y_at_hit + 2.0 * U, "backed away from the wall")
	assert_eq(_hits.size(), 1, "no further hits while reversing away")
	# Turn round on the spot (A for about 180 degrees), then drive away with W
	# and drift: no more hits.
	_drive(car, 47, false, false, 1.0)
	_drive(car, 40, true, false, 0.0)
	_drive(car, 20, true, false, -1.0)
	assert_eq(_hits.size(), 1, "no further hits")
	assert_gt(car.model.total_speed(), 20.0, "speeding up away from the wall")


func test_bounce_zero_slides_and_one_bounces_fully() -> void:
	_wall(Rect2(-10, -12, 20, 2))
	var car = _car()
	car.tuning.wall_bounce = 0.0
	await _settle()
	_drive_until_hit(car, 200)
	assert_almost_eq(car.model.get_velocity().length(), 0.0, 1e-6, "0 = no bounce")
	car.tuning.wall_bounce = 1.0
	_drive(car, 10, true, false, 0.0)
	# Still pressed against the wall with W: W snaps forward to cruise each step,
	# so the full bounce sends it back at cruise speed.
	assert_almost_eq(car.model.get_velocity().y, 11.0, 1e-3, "1 = bounces back at full speed")


# --- Enemies ------------------------------------------------------------------------------

func _route(car) -> void:
	_drive(car, 30, true, false, 0.0)
	_drive(car, 40, true, false, 1.0)
	_drive(car, 20, false, false, 0.0)


func test_car_passes_through_an_enemy_layer_body_unchanged() -> void:
	# Two cars on the same route; an enemy-layer body sits across the route of one.
	var free_car = _car()
	await _settle()
	_route(free_car)
	var free_model = free_car.model
	free_car.queue_free()
	await _settle()

	_wall(Rect2(-40, -12, 80, 6), CarScript.LAYER_ENEMIES).collision_mask = CarScript.LAYER_CAR | CarScript.LAYER_OBSTACLES
	var car = _car()
	await _settle()
	_route(car)
	assert_eq(_hits.size(), 0, "no hit signal")
	assert_eq(car.model.x, free_model.x, "x unchanged")
	assert_eq(car.model.y, free_model.y, "y unchanged")
	assert_eq(car.model.vx, free_model.vx, "vx unchanged")
	assert_eq(car.model.vy, free_model.vy, "vy unchanged")
	assert_lt(free_model.y, -12.0, "the route crosses the enemy body")


# --- Collision signal ---------------------------------------------------------------------

func test_hit_signal_fires_once_per_hit() -> void:
	var wall := _wall(Rect2(-10, -12, 20, 2))
	var car = _car()
	await _settle()
	_drive_until_hit(car, 200)
	assert_eq(_hits.size(), 1, "first hit")
	assert_eq(_hits[0][0], wall, "the wall's body")
	assert_almost_eq(_hits[0][2], Vector2(0, 1), Vector2(1e-4, 1e-4), "normal points out of the wall, to the car")
	_drive(car, 60, true, false, 0.0)
	assert_eq(_hits.size(), 1, "held against the wall: still one hit")
	_drive(car, 25, false, true, 0.0)
	assert_eq(_hits.size(), 1, "reversing away: no hit")
	_drive_until_hit(car, 200)
	assert_eq(_hits.size(), 2, "second hit after moving away")
	# A bounce off it without W: one more hit, no repeats while it rolls away.
	_drive(car, 25, false, true, 0.0)
	_drive_until_hit(car, 200)
	_drive(car, 30, false, false, 0.0)
	assert_eq(_hits.size(), 3, "third hit")


func test_hit_signal_for_a_boulder() -> void:
	var boulder := _boulder(Vector2(0, -11.5), 3.0)
	var car = _car()
	await _settle()
	_drive_until_hit(car, 200)
	_drive(car, 30, true, false, 0.0)
	assert_eq(_hits.size(), 1)
	assert_eq(_hits[0][0], boulder)
	assert_gt(_hits[0][3], 10.0, "impact speed in units/s")


# --- Knockback ----------------------------------------------------------------------------

func test_knockback_from_standstill() -> void:
	var car = _car()
	await _settle()
	var dir := Vector2(1, 1).normalized()
	car.apply_knockback(Vector2(3, 3), 5.0)
	assert_eq(car.model.get_velocity(), Vector2.ZERO, "nothing happens before the next step")
	var p0: Vector2 = car.position
	car.scripted_input = [false, false, 0.0]
	car.physics_step()
	var v: Vector2 = car.model.get_velocity()
	assert_almost_eq(v.length(), 5.0, 1e-6, "strength in units/s")
	assert_almost_eq(v.normalized(), dir, Vector2(1e-6, 1e-6), "in the knockback direction")
	assert_almost_eq((car.position - p0).normalized(), dir, Vector2(1e-4, 1e-4), "the car moved that way")
	assert_eq(car.pending_knockback(), Vector2.ZERO, "applied once")


func test_knockback_while_driving() -> void:
	var car = _car()
	var twin = _car()
	await _settle()
	_drive(car, 20, true, false, 0.0)
	_drive(twin, 20, true, false, 0.0)
	car.apply_knockback(Vector2.RIGHT, 8.0)
	_drive(car, 1, true, false, 0.0)
	_drive(twin, 1, true, false, 0.0)
	var dv: Vector2 = car.model.get_velocity() - twin.model.get_velocity()
	assert_almost_eq(dv, Vector2(8.0, 0.0), Vector2(1e-6, 1e-6), "velocity changed by 8 units/s to the right")


func test_knockback_calls_add_up_and_zero_direction_is_ignored() -> void:
	var car = _car()
	await _settle()
	car.apply_knockback(Vector2.LEFT, 2.0)
	car.apply_knockback(Vector2.UP, 3.0)
	car.apply_knockback(Vector2.ZERO, 50.0)
	_drive(car, 1, false, false, 0.0)
	assert_almost_eq(car.model.get_velocity(), Vector2(-2.0, -3.0), Vector2(1e-6, 1e-6))


func test_knockback_into_a_wall_bounces() -> void:
	_wall(Rect2(-10, -2.0, 20, 1))  # near side 1 unit above the car's centre
	var car = _car()
	await _settle()
	car.apply_knockback(Vector2.UP, 30.0)
	_drive(car, 1, false, false, 0.0)
	assert_eq(_hits.size(), 1, "knocked into the wall")
	assert_gt(car.model.get_velocity().y, 0.0, "bounced off it")
	assert_gt(car.position.y / U - 0.5, -1.01, "not through it")


# --- Layers -------------------------------------------------------------------------------

func test_collision_layers() -> void:
	var car = _car()
	assert_eq(CarScript.LAYER_OBSTACLES, 1, "layer 1")
	assert_eq(CarScript.LAYER_CAR, 2, "layer 2")
	assert_eq(CarScript.LAYER_ENEMIES, 4, "layer 3")
	assert_eq(CarScript.LAYER_PICKUPS, 8, "layer 4")
	assert_eq(car.collision_layer, CarScript.LAYER_CAR, "the car is on the car layer")
	assert_eq(car.collision_mask, CarScript.LAYER_OBSTACLES, "the car collides only with obstacles")
	for i in range(1, 5):
		assert_ne(ProjectSettings.get_setting("layer_names/2d_physics/layer_%d" % i, ""), "", "layer %d is named" % i)


func test_mvp_map_obstacles_are_on_the_obstacle_layer() -> void:
	var map = load("res://scenes/level/mvp_map.tscn").instantiate()
	add_child_autofree(map)
	assert_eq(map.walls.collision_layer, CarScript.LAYER_OBSTACLES, "walls, buildings, map edge")
	assert_gt(map.boulder_bodies.size(), 0)
	for b in map.boulder_bodies:
		assert_eq(b.collision_layer, CarScript.LAYER_OBSTACLES, "boulders")


# --- Drift prototype: test room and bounce slider -----------------------------------------

func _prototype() -> Node2D:
	var p: Node2D = PrototypeScene.instantiate()
	add_child_autofree(p)
	p.car.set_physics_process(false)
	p.car.use_keyboard = false
	return p


func test_prototype_has_test_walls_and_a_3_unit_boulder() -> void:
	var p := _prototype()
	var room = p.test_room
	assert_not_null(room)
	assert_eq(room.walls_body.get_parent(), p.physics_world)
	assert_eq(room.walls_body.collision_layer, CarScript.LAYER_OBSTACLES)
	assert_eq(room.boulder_body.collision_layer, CarScript.LAYER_OBSTACLES)
	assert_gte(room.walls_body.get_child_count(), 5, "outer walls plus inside walls")
	var circle: CircleShape2D = room.boulder_body.get_child(0).shape
	assert_eq(circle.radius * 2.0, 3.0 * U, "3 units across")
	p.set_view("flat")
	assert_eq(room.transform, Transform2D.IDENTITY)
	p.set_view("iso")
	assert_eq(room.transform, p.ISO_TRANSFORM, "drawn in the isometric view")


func test_prototype_car_bounces_off_the_test_boulder() -> void:
	var p := _prototype()
	p.car.hit_obstacle.connect(func(c, i, n, s): _hits.append([c, i, n, s]))
	# Put the car 6 units below the boulder, nose up.
	p.car.model.set_position(TestRoom.BOULDER_CENTRE + Vector2(0, 6))
	p.car.position = p.car.model.get_position() * U
	await _settle()
	_drive(p.car, 100, true, false, 0.0)
	assert_eq(_hits.size(), 1)
	assert_eq(_hits[0][0], p.test_room.boulder_body)


func test_bounce_slider_and_reset() -> void:
	var p := _prototype()
	var sl: HSlider = p.panel.collision_sliders["wall_bounce"]
	assert_eq(sl.min_value, 0.0)
	assert_eq(sl.max_value, 1.0)
	assert_almost_eq(sl.value, 0.25, 1e-9, "starts at the proposed default")
	assert_ne(sl.tooltip_text, "")
	sl.value = 0.8
	assert_almost_eq(p.car.tuning.wall_bounce, 0.8, 1e-9, "applies at once")
	p.panel.reset_button.pressed.emit()
	assert_almost_eq(p.car.tuning.wall_bounce, 0.25, 1e-12, "reset restores the default")
	assert_almost_eq(sl.value, 0.25, 1e-9, "slider follows")
