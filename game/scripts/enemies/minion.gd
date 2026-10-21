extends CharacterBody2D
## One minion (task T-044; Enemies, Decisions): it walks towards the car,
## damages and knocks back the car while touching it, and dies at 0 health.
## Its numbers come from res://data/enemies.json's "minion" (EnemyData.minion())
## and never change over a run.
##
## The body lives in the flat top-down physics world (the run's PhysicsWorld,
## position in pixels, PX_PER_UNIT per unit), like the car. It is on collision
## layer 3 (enemies) so weapons can find it, and its mask is layer 1 only
## (walls, buildings, the map's edge, boulders): it slides along obstacles and
## never pushes or blocks the car (game/README.md, "Collision layers").
## It draws nothing itself: `sprite` (minion_sprite.gd) draws it in the
## isometric view. The spawner (minion_spawner.gd) moves it once per physics
## step through step(), so pausing the tree stops it.
##
## Weapons damage it through take_damage() and push it through
## apply_knockback() (game/README.md, "Minions").
##
## Heights (task T-207, enemy_height.gd): with `ground` set (the map's
## GroundHeight, on the elevation map) it stands on the ground under its
## centre (ground_height()), a rooftop's edge stops its walking and its
## knockback like a wall (from below and from above), and its contact damage
## only hits the car at its level. Which way to walk (the ramps) is the
## spawner's, through `follower` (enemy_path_follower.gd).

const PX_PER_UNIT := 16.0
const LAYER_OBSTACLES := 1 << 0
const LAYER_ENEMIES := 1 << 2
const EnemyHeightScript := preload("res://scripts/enemies/enemy_height.gd")

## The placeholder's body radius on the ground, in units (the collision
## circle, and the reach for touching the car). A size, not a balancing number.
const RADIUS_UNITS := 0.5
## How tall the drawn minion is, in units (for the depth order).
const HEIGHT_UNITS := 0.8
## Minions closer than this (units, centre to centre) push apart a little, so
## a crowd spreads around the car instead of stacking on one point.
const SEPARATION_UNITS := 1.2
## How long a knockback (apply_knockback) takes to move the minion its whole
## distance, in seconds, at an even speed (T-167). A feel number of the push,
## not a balancing number: the distance comes from the weapon.
const KNOCKBACK_SECONDS := 0.15

## Emitted once, when health reaches 0. `minion` is this node (freed at the
## end of the frame), `position_units` where it died (flat world, units).
signal died(minion: Node, position_units: Vector2)

var max_health := 1.0
var health := 1.0
var move_speed := 0.0
var contact_damage := 0.0
var contact_damage_interval := 1.0
var knockback := 0.0
## The isometric drawing, owned by this minion (freed with it).
var sprite: Node2D = null
## The brief red tint when hit (hit_tint.gd, T-072).
var hit_tint: Node = null
## Seconds until this minion can damage the car again.
var contact_cooldown := 0.0
## Which way it walks round an obstacle it meets head-on: 1 or -1.
var detour_side := 1.0
## The direction it last walked (flat world, normalized), for the drawing.
var heading := Vector2.RIGHT
## The ground's heights (a GroundHeight, ground_height.gd), or null (flat map).
var ground = null
## Its way to the car over the ramps (enemy_path_follower.gd); set by the spawner.
var follower: RefCounted = null

var _dead := false
## The normal of the obstacle it touched last step (ZERO for none).
var _wall_normal := Vector2.ZERO
## A knockback still to travel (units, flat world) and the seconds left for it.
var _knockback_left := Vector2.ZERO
var _knockback_time := 0.0
## The normal of a ground edge that stopped the last move (ZERO for none).
var _edge_normal := Vector2.ZERO


## Sets the numbers from EnemyData.minion().
func setup(stats: Dictionary) -> void:
	max_health = float(stats.get("health", 1.0))
	health = max_health
	move_speed = float(stats.get("move_speed", 0.0))
	contact_damage = float(stats.get("contact_damage", 0.0))
	contact_damage_interval = float(stats.get("contact_damage_interval", 1.0))
	knockback = float(stats.get("knockback", 0.0))


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("minions")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = LAYER_ENEMIES
	collision_mask = LAYER_OBSTACLES
	var shape := CircleShape2D.new()
	shape.radius = RADIUS_UNITS * PX_PER_UNIT
	var col := CollisionShape2D.new()
	col.name = "Body"
	col.shape = shape
	add_child(col)
	hit_tint = preload("res://scripts/enemies/hit_tint.gd").attach(self)


func _exit_tree() -> void:
	if sprite != null and is_instance_valid(sprite):
		sprite.queue_free()
	sprite = null


## The minion's centre in units (flat world).
func position_units() -> Vector2:
	return position / PX_PER_UNIT


func set_position_units(p: Vector2) -> void:
	position = p * PX_PER_UNIT


## The height of the ground it stands on, units (0 with no ground).
func ground_height() -> float:
	return EnemyHeightScript.height_at(ground, position_units())


## Moves by `motion` (pixels), limited first by the ground's edges (T-207),
## then by the obstacles. Returns the obstacle hit, or null; an edge that
## stopped it is in _edge_normal.
func _move(motion: Vector2) -> KinematicCollision2D:
	_edge_normal = Vector2.ZERO
	if ground == null:
		return move_and_collide(motion)
	var lim: Dictionary = EnemyHeightScript.limit_motion(ground, position_units(), motion / PX_PER_UNIT, RADIUS_UNITS)
	_edge_normal = lim.normal
	for seg in lim.segments:
		if (seg as Vector2).length() < 0.000001:
			continue
		var hit := move_and_collide(seg * PX_PER_UNIT)
		if hit != null:
			return hit
	return null


## Damages the minion by `amount` (weapons call this). At 0 health it dies:
## `died` fires once and the node is freed. Ignored when `amount` is not
## positive or the minion is already dead.
func take_damage(amount: float) -> void:
	if _dead or amount <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	if health <= 0.0:
		_die()
	elif hit_tint != null:
		hit_tint.flash()  # T-072: a brief red tint


func is_dead() -> bool:
	return _dead


func _die() -> void:
	_dead = true
	remove_from_group("enemies")
	remove_from_group("minions")
	if sprite != null and is_instance_valid(sprite):
		sprite.queue_free()
	sprite = null
	died.emit(self, position_units())
	# Freed at the end of the frame, so a weapon's physics callback can kill it.
	queue_free()


## One physics step of walking towards `target_units` (the car's centre),
## `dt` seconds. `push` is the separation from nearby minions (units, any
## length; the spawner works it out). Obstacles stop it and it slides along
## them; meeting one head-on, it walks round it on its detour side.
func walk(dt: float, target_units: Vector2, push: Vector2 = Vector2.ZERO) -> void:
	if _dead:
		return
	if _knockback_time > 0.0:
		_knockback_step(dt)
		return
	var to_target := target_units - position_units()
	var dir := to_target.normalized() if to_target.length() > 0.001 else Vector2.ZERO
	dir += push
	if dir.length() < 0.001:
		return
	dir = dir.normalized()
	if _wall_normal != Vector2.ZERO and dir.dot(_wall_normal) < 0.0:
		var along := dir - _wall_normal * dir.dot(_wall_normal)
		if along.length() < 0.5:
			along = _wall_normal.orthogonal() * detour_side
		dir = along.normalized()
	heading = dir
	velocity = dir * move_speed * PX_PER_UNIT
	var hit := _move(velocity * dt)
	_wall_normal = _edge_normal
	if hit != null:
		_wall_normal = hit.get_normal()
		# Slide the rest of the step along the obstacle.
		var rest := hit.get_remainder()
		rest -= _wall_normal * rest.dot(_wall_normal)
		if rest.length() > 0.0:
			var hit2 := _move(rest)
			if hit2 != null:
				_wall_normal = hit2.get_normal()
			elif _edge_normal != Vector2.ZERO:
				_wall_normal = _edge_normal


## Knocks the minion back (weapons call this; T-167): it is pushed `strength`
## units (flat world) along `direction` (any length; normalized here) over
## KNOCKBACK_SECONDS, instead of walking, then walks on. Obstacles stop it the
## same way they stop its walking (it slides along them, never through). A
## second push before the first ends adds to what is left and restarts the
## time. Ignored when `strength` is not positive, `direction` is zero, or the
## minion is dead. Only minions have it: the kaiju is never pushed.
func apply_knockback(direction: Vector2, strength: float) -> void:
	if _dead or strength <= 0.0 or direction.length() < 0.000001:
		return
	_knockback_left += direction.normalized() * strength
	_knockback_time = KNOCKBACK_SECONDS


## True while a knockback is still moving the minion.
func is_knocked_back() -> bool:
	return _knockback_time > 0.0


## One physics step of a knockback: an even share of what is left.
func _knockback_step(dt: float) -> void:
	var share := 1.0 if dt >= _knockback_time else dt / _knockback_time
	var move := _knockback_left * share
	_knockback_left -= move
	_knockback_time = maxf(_knockback_time - dt, 0.0)
	if _knockback_time <= 0.0:
		_knockback_left = Vector2.ZERO
	velocity = Vector2.ZERO
	var motion := move * PX_PER_UNIT
	var hit := _move(motion)
	_wall_normal = _edge_normal
	if _edge_normal != Vector2.ZERO:
		# An edge (T-207): stop pushing over it, keep the part along it.
		_knockback_left -= _edge_normal * minf(_knockback_left.dot(_edge_normal), 0.0)
	if hit != null:
		_wall_normal = hit.get_normal()
		# Stop pushing into the obstacle: keep only the part along it.
		_knockback_left -= _wall_normal * minf(_knockback_left.dot(_wall_normal), 0.0)
		var rest := hit.get_remainder()
		rest -= _wall_normal * rest.dot(_wall_normal)
		if rest.length() > 0.0:
			var hit2 := _move(rest)
			if hit2 != null:
				_wall_normal = hit2.get_normal()
				_knockback_left -= _wall_normal * minf(_knockback_left.dot(_wall_normal), 0.0)


## True when the minion's body touches the car's 1 x 1 unit body
## (`car_centre_units`, rotated `car_rotation`).
func touches_car(car_centre_units: Vector2, car_rotation: float) -> bool:
	var local := (position_units() - car_centre_units).rotated(-car_rotation)
	var nearest := Vector2(clampf(local.x, -0.5, 0.5), clampf(local.y, -0.5, 0.5))
	return local.distance_to(nearest) <= RADIUS_UNITS


## One physics step of contact damage: while touching the car, it hits once
## every contact_damage_interval seconds (the first hit as soon as it
## touches): the car loses contact_damage through `state.damage_car()` and is
## knocked back away from the minion through `car.apply_knockback()`.
## On a map with heights (T-207) only when the car is at its level
## (EnemyHeight.at_car_level: a car on a rooftop above it, or high in the air,
## is not hit). Returns true when it hit this step.
func contact_step(dt: float, car: Node2D, state: Node) -> bool:
	contact_cooldown = maxf(contact_cooldown - dt, 0.0)
	if _dead or car == null:
		return false
	var car_units: Vector2 = car.position / PX_PER_UNIT
	if not touches_car(car_units, car.rotation):
		return false
	if ground != null and not EnemyHeightScript.at_car_level(ground_height(), EnemyHeightScript.car_height(car)):
		return false
	if contact_cooldown > 0.0:
		return false
	contact_cooldown = contact_damage_interval
	if state != null:
		state.damage_car(contact_damage)
	var away := car_units - position_units()
	if away.length() < 0.001:
		away = heading
	car.apply_knockback(away, knockback)
	return true
