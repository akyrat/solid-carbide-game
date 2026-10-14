extends CharacterBody2D
## The kaiju, Crash City's final boss (task T-045; Enemies, Decisions): a body
## several times the car's size that walks slowly towards the car, damages and
## knocks back the car while touching it, and can be damaged at any time (no
## shield, no vulnerability windows). At 0 health it dies; the boss controller
## (kaiju_boss.gd) then adds its coins and ends the run as a win. Its numbers
## come from res://data/enemies.json's "kaiju" (EnemyData.kaiju()) and never
## change over a run.
##
## Built like a minion (minion.gd) so weapons treat both the same: a
## CharacterBody2D in the run's flat PhysicsWorld (pixels, PX_PER_UNIT per
## unit) on collision layer 3 (enemies), mask layer 1 only (walls, buildings,
## the map's edge, boulders), so it slides along obstacles and never pushes or
## blocks the car. In the group "enemies" (not "minions"), and also "kaiju".
## The same take_damage(amount), position_units(), health, max_health and
## is_dead() as a minion (game/README.md, "Minions" and "The kaiju").
##
## It draws nothing itself: `sprite` (kaiju_sprite.gd) draws it in the
## isometric view. The controller moves it once per physics step through
## walk() and contact_step(), so pausing the tree stops it.

const PX_PER_UNIT := 16.0
const LAYER_OBSTACLES := 1 << 0
const LAYER_ENEMIES := 1 << 2

## The placeholder's body radius on the ground, in units (the collision circle
## and the reach for touching the car): 4 units across, the car being 1 wide
## and 3 long. A size of the placeholder, not a balancing number.
const RADIUS_UNITS := 2.0
## How tall the drawn kaiju is, in units (for the depth order and spawning
## fully off-screen).
const HEIGHT_UNITS := 7.0

## Emitted on every change of health (damage), with the new values. For the HUD.
signal health_changed(health: float, max_health: float)
## Emitted once, when health reaches 0. `kaiju` is this node (freed at the end
## of the frame), `position_units` where it died (flat world, units).
signal died(kaiju: Node, position_units: Vector2)

var max_health := 1.0
var health := 1.0
var move_speed := 0.0
var contact_damage := 0.0
var contact_damage_interval := 1.0
var knockback := 0.0
## The isometric drawing, owned by this kaiju (freed with it).
var sprite: Node2D = null
## Seconds until it can damage the car again.
var contact_cooldown := 0.0
## Which way it walks round an obstacle it meets head-on: 1 or -1.
var detour_side := 1.0
## The direction it last walked (flat world, normalized), for the drawing.
var heading := Vector2.LEFT

var _dead := false
## The normal of the obstacle it touched last step (ZERO for none).
var _wall_normal := Vector2.ZERO


## Sets the numbers from EnemyData.kaiju().
func setup(stats: Dictionary) -> void:
	max_health = float(stats.get("health", 1.0))
	health = max_health
	move_speed = float(stats.get("move_speed", 0.0))
	contact_damage = float(stats.get("contact_damage", 0.0))
	contact_damage_interval = float(stats.get("contact_damage_interval", 1.0))
	knockback = float(stats.get("knockback", 0.0))


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("kaiju")
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


## The kaiju's centre in units (flat world).
func position_units() -> Vector2:
	return position / PX_PER_UNIT


func set_position_units(p: Vector2) -> void:
	position = p * PX_PER_UNIT


## The kaiju's body on the ground, as a radius in units (its collision
## circle). Weapons read it for their hits: the flamethrower counts any
## overlap with this circle as a hit (board, 2026-10-14; minions keep the
## centre rule).
func hit_radius_units() -> float:
	return RADIUS_UNITS


## Damages the kaiju by `amount` (weapons call this, as on a minion). It can be
## damaged at any time. `health_changed` fires; at 0 health it dies: `died`
## fires once and the node is freed at the end of the frame. Ignored when
## `amount` is not positive or the kaiju is already dead.
func take_damage(amount: float) -> void:
	if _dead or amount <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		_die()


func is_dead() -> bool:
	return _dead


func _die() -> void:
	_dead = true
	remove_from_group("enemies")
	remove_from_group("kaiju")
	if sprite != null and is_instance_valid(sprite):
		sprite.queue_free()
	sprite = null
	died.emit(self, position_units())
	# Freed at the end of the frame, so a weapon's physics callback can kill it.
	queue_free()


## One physics step of walking towards `target_units` (the car's centre), `dt`
## seconds. Obstacles stop it and it slides along them; meeting one head-on,
## it walks round it on its detour side (the minion's rule).
func walk(dt: float, target_units: Vector2) -> void:
	if _dead:
		return
	var to_target := target_units - position_units()
	if to_target.length() < 0.001:
		return
	var dir := to_target.normalized()
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
		var rest := hit.get_remainder()
		rest -= _wall_normal * rest.dot(_wall_normal)
		if rest.length() > 0.0:
			var hit2 := move_and_collide(rest)
			if hit2 != null:
				_wall_normal = hit2.get_normal()


## True when the kaiju's body touches the car's 1 x 1 unit body
## (`car_centre_units`, rotated `car_rotation`).
func touches_car(car_centre_units: Vector2, car_rotation: float) -> bool:
	var local := (position_units() - car_centre_units).rotated(-car_rotation)
	var nearest := Vector2(clampf(local.x, -0.5, 0.5), clampf(local.y, -0.5, 0.5))
	return local.distance_to(nearest) <= RADIUS_UNITS


## One physics step of contact damage, as a minion's: while touching the car
## it hits once every contact_damage_interval seconds (the first hit as soon
## as it touches): `state.damage_car(contact_damage)` and
## `car.apply_knockback(away from the kaiju, knockback)`. True when it hit.
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
