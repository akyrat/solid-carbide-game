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
## Weapons damage it through take_damage() (game/README.md, "Minions").

const PX_PER_UNIT := 16.0
const LAYER_OBSTACLES := 1 << 0
const LAYER_ENEMIES := 1 << 2

## The placeholder's body radius on the ground, in units (the collision
## circle, and the reach for touching the car). A size, not a balancing number.
const RADIUS_UNITS := 0.5
## How tall the drawn minion is, in units (for the depth order).
const HEIGHT_UNITS := 0.8
## Minions closer than this (units, centre to centre) push apart a little, so
## a crowd spreads around the car instead of stacking on one point.
const SEPARATION_UNITS := 1.2

## Emitted once, when health reaches 0. `minion` is this node (freed at the
## end of the frame), `position_units` where it died (flat world, units).
signal died(minion: Node, position_units: Vector2)
## Emitted when a hit leaves it alive (T-072's hit effect plays at it).
signal hurt(minion: Node, position_units: Vector2)

var max_health := 1.0
var health := 1.0
var move_speed := 0.0
var contact_damage := 0.0
var contact_damage_interval := 1.0
var knockback := 0.0
## The isometric drawing, owned by this minion (freed with it).
var sprite: Node2D = null
## Seconds until this minion can damage the car again.
var contact_cooldown := 0.0
## Which way it walks round an obstacle it meets head-on: 1 or -1.
var detour_side := 1.0
## The direction it last walked (flat world, normalized), for the drawing.
var heading := Vector2.RIGHT

var _dead := false
## The normal of the obstacle it touched last step (ZERO for none).
var _wall_normal := Vector2.ZERO


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


func _exit_tree() -> void:
	if sprite != null and is_instance_valid(sprite):
		sprite.queue_free()
	sprite = null


## The minion's centre in units (flat world).
func position_units() -> Vector2:
	return position / PX_PER_UNIT


func set_position_units(p: Vector2) -> void:
	position = p * PX_PER_UNIT


## Damages the minion by `amount` (weapons call this). At 0 health it dies:
## `died` fires once and the node is freed. Ignored when `amount` is not
## positive or the minion is already dead.
func take_damage(amount: float) -> void:
	if _dead or amount <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	if health <= 0.0:
		_die()
	else:
		hurt.emit(self, position_units())


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
	var hit := move_and_collide(velocity * dt)
	_wall_normal = Vector2.ZERO
	if hit != null:
		_wall_normal = hit.get_normal()
		# Slide the rest of the step along the obstacle.
		var rest := hit.get_remainder()
		rest -= _wall_normal * rest.dot(_wall_normal)
		if rest.length() > 0.0:
			var hit2 := move_and_collide(rest)
			if hit2 != null:
				_wall_normal = hit2.get_normal()


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
## Returns true when it hit this step.
func contact_step(dt: float, car: Node2D, state: Node) -> bool:
	contact_cooldown = maxf(contact_cooldown - dt, 0.0)
	if _dead or car == null:
		return false
	var car_units: Vector2 = car.position / PX_PER_UNIT
	if not touches_car(car_units, car.rotation):
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
