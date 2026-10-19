extends CharacterBody2D
## The player's car in the flat top-down physics world. Runs CarModel once per
## physics step (50 per second) and moves this body with the result.
##
## The body is a 1 x 1 unit square, as in the Unity prototype (Drifting,
## Decisions). It draws nothing itself: the drift prototype scene draws the car
## in the flat or isometric view.
##
## Position here is in pixels, PX_PER_UNIT pixels per unit; the model works in
## units.
##
## Collisions (task T-033; layers in game/README.md, "Collision layers"): the
## body is on layer 2 (the car) and collides only with layer 1 (walls,
## buildings, the map's edge and boulders). It bounces off them slightly
## (tuning.wall_bounce) and emits hit_obstacle once per hit. Enemies (layer 3)
## are not in its mask, so they never block it or make it bounce.
## apply_knockback() is how other code (minion hits, meteor impacts) pushes it.

const CarModel := preload("res://scripts/driving/car_model.gd")
const TrickDetector := preload("res://scripts/driving/trick_detector.gd")
const CarHeight := preload("res://scripts/driving/car_height.gd")

## Pixels per unit in the flat world. Matches the placeholder car sheets
## (game/art/placeholders/car/*.json, px_per_unit), so a 1-unit-wide car is
## 16 pixels wide at zoom 1.
const PX_PER_UNIT := 16.0

## Input actions (game/project.godot, input map).
const ACTION_ACCELERATE := "car_accelerate"
const ACTION_REVERSE := "car_reverse"
const ACTION_STEER_LEFT := "car_steer_left"
const ACTION_STEER_RIGHT := "car_steer_right"

## Collision layer bits (game/README.md, "Collision layers").
const LAYER_OBSTACLES := 1 << 0  # layer 1: walls, buildings, the map's edge, boulders
const LAYER_CAR := 1 << 1        # layer 2: the player's car
const LAYER_ENEMIES := 1 << 2    # layer 3: enemies (minions, the kaiju, meteors)
const LAYER_PICKUPS := 1 << 3    # layer 4: pickups (coins)

## A hit re-arms (counts as a new hit next time) once the car is this far from
## the obstacle it touched, in units. Holding the car against a wall is one hit.
const REARM_GAP_UNITS := 0.25

## Emitted after every physics step, once the body has moved.
signal stepped
## Emitted once each time the car hits a wall, building, map edge or boulder
## (anything on collision layer 1), for the combo (task T-081). collider is the
## StaticBody2D hit, shape_index the index of its shape that was hit (which
## building or boulder), normal the obstacle's surface normal (pointing out of
## the obstacle, towards the car) and impact_speed the car's speed into the
## surface in units/s, before the bounce. Staying pressed against the same
## obstacle does not emit it again; it re-arms once the car is
## REARM_GAP_UNITS away.
signal hit_obstacle(collider: Object, shape_index: int, normal: Vector2, impact_speed: float)
## Emitted when W makes the car jump up to cruise speed (for the boost effect,
## task T-008). See CarModel.cruise_jump for the arguments.
signal cruise_jump(from_speed: float, w_just_pressed: bool)
## Emitted once per press of W that snaps the car up to cruise speed (task
## T-008): the "boost". Not while W stays held (so not on the jumps back to
## cruise during a held drift), and not when W is pressed at or above cruise
## speed. from_speed is the forward speed just before the jump, in units/s
## (negative when reversing). The boost effect, and later the art, the sound
## and the UI, hook into this. It changes no driving.
signal boost(from_speed: float)
## Emitted once per trick the car does (task T-079), with the trick's id:
## "extended_drift", "three_sixty" or "alternate_drift" (TrickDetector.TRICK_IDS).
## For the combo (task T-081) and the trick popups. See trick_detector.gd.
signal trick(trick_id: String)

var model = CarModel.new()
## Watches the driving for tricks (task T-079). It only reads the model.
var tricks = TrickDetector.new()
## When false, no tricks are detected (tests compare the movement both ways).
var detect_tricks := true
## The handling values (shared with the tuning panel).
var tuning:
	get:
		return model.tuning

## The car's real height above the ground (task T-183, car_height.gd), stepped
## after the flat step. It never changes the flat driving.
var height_model = CarHeight.new()
## The ground-height source (a GroundHeight, ground_height.gd), or null. Null
## (the drift prototype, the run): the height stays 0.
var ground = null:
	get:
		return height_model.ground
	set(value):
		height_model.ground = value
		height_model.reset(model.get_position())
## Height above the ground's zero, units (0 with no ground source).
var height: float:
	get:
		return height_model.height
## Vertical speed, units/s, up positive.
var vertical_speed: float:
	get:
		return height_model.vertical_speed
## True while the car is in the air.
var airborne: bool:
	get:
		return height_model.airborne

## When false, physics_step uses scripted_input instead of the keyboard (tests).
var use_keyboard := true
## [W held, S held, steer] used when use_keyboard is false.
var scripted_input := [false, false, 0.0]

## Knockback waiting for the next physics step, in units/s (apply_knockback).
var _pending_knockback := Vector2.ZERO
## Obstacles the car is touching: "collider id:shape index" -> surface normal.
var _contacts := {}
## Sides of the ground the car is touching (task T-184): key -> {point, normal}.
var _side_contacts := {}


func _init() -> void:
	tricks.trick.connect(func(trick_id: String) -> void: trick.emit(trick_id))


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = LAYER_CAR
	collision_mask = LAYER_OBSTACLES
	var shape := RectangleShape2D.new()
	shape.size = Vector2(PX_PER_UNIT, PX_PER_UNIT)
	var collision := CollisionShape2D.new()
	collision.name = "Body1x1"
	collision.shape = shape
	add_child(collision)
	model.dt = 1.0 / float(Engine.physics_ticks_per_second)
	model.cruise_jump.connect(func(from_speed: float, just: bool) -> void:
		cruise_jump.emit(from_speed, just)
		if just:
			boost.emit(from_speed))
	_sync_from_model()


func _physics_process(_delta: float) -> void:
	physics_step()


## One physics step: read the controls, run the model, move the body.
func physics_step() -> void:
	var w: bool
	var s: bool
	var steer: float
	if use_keyboard:
		w = Input.is_action_pressed(ACTION_ACCELERATE)
		s = Input.is_action_pressed(ACTION_REVERSE)
		steer = Input.get_action_strength(ACTION_STEER_LEFT) - Input.get_action_strength(ACTION_STEER_RIGHT)
	else:
		w = scripted_input[0]
		s = scripted_input[1]
		steer = scripted_input[2]
	var rotation_before: float = model.rotation
	model.update_velocity(w, s, steer)
	if detect_tricks:
		tricks.observe(model, w, s, steer, rotation_before)
	if _pending_knockback != Vector2.ZERO:
		model.vx += _pending_knockback.x
		model.vy += _pending_knockback.y
		_pending_knockback = Vector2.ZERO
	rotation = model.rotation
	velocity = model.get_velocity() * PX_PER_UNIT
	var flat_before: Vector2 = model.get_position()
	var hit := move_and_collide(velocity * model.dt)
	# Moving sets the body's transform, which wraps rotation into -PI..PI; keep
	# the model's own angle, as before collisions existed.
	rotation = model.rotation
	if hit == null:
		# Nothing in the way: move by the model's own (64-bit) step, so the
		# position matches the Unity maths exactly.
		model.x += model.vx * model.dt
		model.y += model.vy * model.dt
		position = model.get_position() * PX_PER_UNIT
	else:
		# The body stopped against an obstacle: take its position, and bounce.
		model.set_position(position / PX_PER_UNIT)
		_bounce(hit)
	_update_contacts(hit)
	var side: Dictionary = height_model.step(flat_before, model.get_position(), model.get_velocity(), model.dt)
	if side.wall:
		# A side of the ground higher than the car (task T-184): stop at it and
		# bounce like off any wall.
		model.set_position(side.point)
		position = model.get_position() * PX_PER_UNIT
		_bounce_off_side(side)
	_update_side_contacts()
	stepped.emit()


## Knocks the car back: adds direction (normalized here) x strength, in units
## per second, to the car's velocity on the next physics step, after the driving
## model's own update for that step. Several calls before one step add up. The
## Enemy Behavior Agent calls it for minion hits and meteor impacts (strength
## from the game data). The push is then treated like any other speed: the
## sideways part fades with the sideways grip, the part along the nose changes
## the forward speed (so W held with the nose against the push snaps the car
## back to cruise speed on the step after), and a push into a wall bounces.
func apply_knockback(direction: Vector2, strength: float) -> void:
	if direction == Vector2.ZERO:
		return
	_pending_knockback += direction.normalized() * strength


## Knockback that will be added on the next physics step (units/s).
func pending_knockback() -> Vector2:
	return _pending_knockback


## Reflects the part of the velocity going into the obstacle, scaled by
## tuning.wall_bounce (0 = slide along it, 1 = full bounce). The part along the
## surface is kept. Emits hit_obstacle for a new hit.
func _bounce(hit: KinematicCollision2D) -> void:
	var n := hit.get_normal()
	var impact := _reflect(n)
	var key := _contact_key(hit.get_collider(), hit.get_collider_shape_index())
	if not _contacts.has(key):
		hit_obstacle.emit(hit.get_collider(), hit.get_collider_shape_index(), n, impact)
	_contacts[key] = n


## Reflects the velocity off a surface with outward normal n (see _bounce) and
## returns the speed into it before the bounce, units/s.
func _reflect(n: Vector2) -> float:
	var v := model.get_velocity()
	var into := v.dot(n)
	var impact := maxf(0.0, -into)
	if into < 0.0:
		var e := clampf(float(tuning.wall_bounce), 0.0, 1.0)
		model.set_velocity(v - (1.0 + e) * into * n)
	velocity = model.get_velocity() * PX_PER_UNIT
	return impact


## The same bounce off a side of the ground (task T-184; a drop-off edge from
## below, a ramp's side). hit_obstacle gets the GroundHeight as the collider
## and the area's index (GroundHeight.area_index_at) as the shape index. It
## counts once per side until the car is REARM_GAP_UNITS away from it.
func _bounce_off_side(side: Dictionary) -> void:
	var n: Vector2 = side.normal
	var impact := _reflect(n)
	var key := "side:%d:%d,%d" % [side.area, roundi(n.x), roundi(n.y)]
	if not _side_contacts.has(key):
		hit_obstacle.emit(ground, side.area, n, impact)
	_side_contacts[key] = {"point": side.point, "normal": n}


## Forgets the ground's sides the car has moved away from (_bounce_off_side).
func _update_side_contacts() -> void:
	if _side_contacts.is_empty():
		return
	var pos: Vector2 = model.get_position()
	for key in _side_contacts.keys():
		var c: Dictionary = _side_contacts[key]
		if (pos - c.point).dot(c.normal) > REARM_GAP_UNITS:
			_side_contacts.erase(key)


## Forgets the contacts the car has moved away from, so hitting them again
## counts as a new hit.
func _update_contacts(hit: KinematicCollision2D) -> void:
	if _contacts.is_empty():
		return
	var current := ""
	if hit != null:
		current = _contact_key(hit.get_collider(), hit.get_collider_shape_index())
	for key in _contacts.keys():
		if key == current:
			continue
		var probe := move_and_collide(-_contacts[key] * REARM_GAP_UNITS * PX_PER_UNIT, true)
		if probe == null or _contact_key(probe.get_collider(), probe.get_collider_shape_index()) != key:
			_contacts.erase(key)


static func _contact_key(collider: Object, shape_index: int) -> String:
	return "%d:%d" % [collider.get_instance_id() if collider != null else 0, shape_index]


func _sync_from_model() -> void:
	rotation = model.rotation
	position = model.get_position() * PX_PER_UNIT
	velocity = model.get_velocity() * PX_PER_UNIT
