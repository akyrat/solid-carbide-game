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
## never pushes or blocks the car (game/docs/driving/collisions.md, "Collision layers").
## It draws nothing itself: `sprite` (minion_sprite.gd) draws it in the
## isometric view. The spawner (minion_spawner.gd) moves it once per physics
## step through step(), so pausing the tree stops it.
##
## Weapons damage it through take_damage() and push it through
## apply_knockback() (game/docs/enemies/minions.md, "Minions").
##
## Heights (task T-207, enemy_height.gd): with `ground` set (the map's
## GroundHeight, on the elevation map) it stands on the ground under its
## centre (ground_height()), a rooftop's edge stops its walking and its
## knockback like a wall (from below and from above), and its contact damage
## only hits the car at its level. Which way to walk (the ramps) is the
## spawner's, through `follower` (enemy_path_follower.gd).
##
## Drops (task T-226): when its path drops off a rooftop's edge the spawner
## sets `may_drop`, it walks out over the edge and falls (`fall`,
## enemy_fall.gd) while it keeps walking; body_height() is then its height in
## the air, which its drawing, its depth order, pushing apart and its contact
## damage use (a falling minion hits a car at its height in the air). A
## knockback never takes it over an edge.

const PX_PER_UNIT := 16.0
const LAYER_OBSTACLES := 1 << 0
const LAYER_ENEMIES := 1 << 2
const EnemyHeightScript := preload("res://scripts/enemies/enemy_height.gd")
const EnemyFallScript := preload("res://scripts/enemies/enemy_fall.gd")

## The placeholder's body radius on the ground, in units (the collision
## circle, and the reach for touching the car). A size, not a balancing number.
const BASE_RADIUS_UNITS := 0.5
## T-379: the body keeps BASE_RADIUS_UNITS (the old radius, not the grown one)
## off a rooftop's or ramp's edge. The edges are not walls in the physics world,
## and the navigation's cells (2 units wide) put path corners 1 unit from an
## edge, where a body of 1 unit is held and jams at a rooftop's corner.
## Buildings and boulders (real colliders) use the grown radius.
## How tall the drawn minion is at size_scale 1, in units (for the depth order).
const BASE_HEIGHT_UNITS := 0.8
## Minions closer than this (units, centre to centre) push apart a little, so
## a crowd spreads around the car instead of stacking on one point.
const SEPARATION_UNITS := 1.2
## How long a knockback (apply_knockback) takes to move the minion its whole
## distance, in seconds, at an even speed (T-167). A feel number of the push,
## not a balancing number: the distance comes from the weapon.
const KNOCKBACK_SECONDS := 0.15

## The recap's key for this enemy (T-319).
const ENEMY_TYPE := "minion"

## The id of the weapon that hit it last (take_damage's `source`), "" if none told.
var last_hit_by := ""

## Emitted once, when health reaches 0. `minion` is this node (freed at the
## end of the frame), `position_units` where it died (flat world, units).
signal died(minion: Node, position_units: Vector2)

## T-379: how many times its old size it is (enemies.json minion.size_scale);
## its drawing, body, hits and navigation margin all follow it.
var size_scale := 1.0
var max_health := 1.0
var health := 1.0
var move_speed := 0.0
var contact_damage := 0.0
var contact_damage_interval := 0.0
var knockback := 0.0
## The isometric drawing, owned by this minion (freed with it).
var sprite: Node2D = null
## The brief red tint when hit (hit_tint.gd, T-072).
var hit_tint: Node = null
## Seconds until this minion can damage the car again.
var contact_cooldown := 0.0
## T-463: seconds until the car's Rusty Overcoat can damage this minion again.
var overcoat_cooldown := 0.0
## Which way it walks round an obstacle it meets head-on: 1 or -1.
var detour_side := 1.0
## The direction it last walked (flat world, normalized), for the drawing.
var heading := Vector2.RIGHT
## The ground's heights (a GroundHeight, ground_height.gd), or null (flat map).
var ground = null
## Its way to the car over the ramps (enemy_path_follower.gd); set by the spawner.
var follower: RefCounted = null
## T-226: true for this step when its path drops off an edge here (set by its
## controller from follower.dropping()): it may then walk out over the edge.
var may_drop := false
## Its fall off an edge (enemy_fall.gd, T-226).
var fall = EnemyFallScript.new()

var _dead := false
## T-531: true once the spawner's corpse keeper (minion_corpses.gd) has taken the dead body
## over: it then stays, in the group "minion_corpses", instead of being freed at its death.
var _corpse := false
## The corpse's numbers (the keeper hands them over; seconds, units) and its clocks.
var corpse_stats := {}
## Seconds until the corpse starts to fade (every hit restarts it), the fade's seconds left
## (-1 while it has not started), and the seconds since it was last hit by the car.
var corpse_timer := 0.0
var corpse_fade_left := -1.0
var _corpse_car_gap := 0.0
## A corpse's slide after a knock: the start velocity (units/s), the seconds it lasts and has left.
var _slide_v0 := Vector2.ZERO
var _slide_total := 0.0
var _slide_left := 0.0
## True when the corpse moved since the keeper last placed its drawing.
var corpse_moved := false
## The normal of the obstacle it touched last step (ZERO for none).
var _wall_normal := Vector2.ZERO
## A knockback still to travel (units, flat world) and the seconds left for it.
var _knockback_left := Vector2.ZERO
var _knockback_time := 0.0
## The normal of a ground edge that stopped the last move (ZERO for none).
var _edge_normal := Vector2.ZERO
## True while the current move may go over an edge (walking with may_drop).
var _drop_now := false


## Sets the numbers from EnemyData.minion().
func setup(stats: Dictionary) -> void:
	size_scale = float(stats.get("size_scale", 1.0))
	max_health = float(stats.get("health", 1.0))
	health = max_health
	move_speed = float(stats.get("move_speed", 0.0))
	contact_damage = float(stats.get("contact_damage", 0.0))
	contact_damage_interval = float(stats.get("contact_damage_interval", 0.0))
	knockback = float(stats.get("knockback", 0.0))


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("minions")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = LAYER_ENEMIES
	collision_mask = LAYER_OBSTACLES
	var shape := CircleShape2D.new()
	shape.radius = radius_units() * PX_PER_UNIT
	var col := CollisionShape2D.new()
	col.name = "Body"
	col.shape = shape
	add_child(col)
	hit_tint = preload("res://scripts/enemies/hit_tint.gd").attach(self)


func _exit_tree() -> void:
	if sprite != null and is_instance_valid(sprite):
		sprite.queue_free()
	sprite = null


## The body radius in units (T-379: BASE_RADIUS_UNITS times size_scale).
func radius_units() -> float:
	return BASE_RADIUS_UNITS * size_scale


## The same, for the weapons' hit checks (they ask any enemy with this).
func hit_radius_units() -> float:
	return radius_units()


## How tall the drawn minion is, in units.
func height_units() -> float:
	return BASE_HEIGHT_UNITS * size_scale


## The minion's centre in units (flat world).
func position_units() -> Vector2:
	return position / PX_PER_UNIT


func set_position_units(p: Vector2) -> void:
	position = p * PX_PER_UNIT
	fall.reset()


## The height of the ground it stands on, units (0 with no ground).
func ground_height() -> float:
	return EnemyHeightScript.height_at(ground, position_units())


## The height of its body, units (T-226): in the air while it falls off an
## edge, otherwise the ground's.
func body_height() -> float:
	return fall.body_height(ground_height())


## True while it falls off an edge (T-226).
func is_falling() -> bool:
	return fall.falling


## After a move from a body height of `h0` (T-226): starts a fall when it has
## walked out over ground more than MAX_STEP lower, and steps a fall `dt`.
func _fall_step(dt: float, h0: float) -> void:
	if ground == null:
		return
	var g := ground_height()
	if not fall.falling and h0 - g > EnemyHeightScript.MAX_STEP:
		fall.start(h0)
	fall.step(dt, g)


## Moves by `motion` (pixels), limited first by the ground's edges (T-207),
## then by the obstacles. Returns the obstacle hit, or null; an edge that
## stopped it is in _edge_normal.
func _move(motion: Vector2) -> KinematicCollision2D:
	_edge_normal = Vector2.ZERO
	if ground == null:
		return move_and_collide(motion)
	var lim: Dictionary = EnemyHeightScript.limit_motion(ground, position_units(), motion / PX_PER_UNIT, BASE_RADIUS_UNITS,
		body_height(), _drop_now or fall.falling)
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
func take_damage(amount: float, source := "") -> void:
	if Perf.on: Perf.each_begin(&"enemy.damage")
	if _dead or amount <= 0.0:
		if Perf.on: Perf.each_end(&"enemy.damage")
		return
	if source != "":
		last_hit_by = source
	health = maxf(health - amount, 0.0)
	if health <= 0.0:
		_die()
	elif hit_tint != null:
		hit_tint.flash()  # T-072: a brief red tint
	if Perf.on: Perf.each_end(&"enemy.damage")


func is_dead() -> bool:
	return _dead


# --- Corpse (task T-531; Enemies, Decisions, "Minion deaths") -----------------------

## True while this body is a corpse: dead, kept, knockable, fading in time.
func is_corpse() -> bool:
	return _corpse


## Called by the corpse keeper from its `died` listener: the body stays as a corpse for
## `stats.corpse_seconds` after its last hit, then fades out over `stats.fade_seconds`.
## It leaves every collision layer (nothing hits it, nothing is blocked by it); its
## mask stays on the obstacles, so a knocked corpse stops at walls.
func keep_as_corpse(stats: Dictionary) -> void:
	_corpse = true
	corpse_stats = stats
	corpse_timer = float(stats.get("corpse_seconds", 2.0))
	corpse_fade_left = -1.0
	add_to_group("minion_corpses")
	collision_layer = 0
	_knockback_left = Vector2.ZERO
	_knockback_time = 0.0


## A hit on the corpse (the car or a knockback weapon): it slides `distance` units along
## `direction` (any length), slowing evenly to rest over corpse_stats.slide_seconds, and the
## fade timer starts again (a fading corpse comes back whole). Ignored for a zero distance
## or direction, or when this is not a corpse.
func knock_corpse(direction: Vector2, distance: float) -> void:
	if not _corpse or direction.length() < 0.000001:
		return
	corpse_timer = float(corpse_stats.get("corpse_seconds", 2.0))
	corpse_fade_left = -1.0
	if distance <= 0.0:
		return
	var t := maxf(float(corpse_stats.get("slide_seconds", 0.4)), 0.05)
	# An even slowing down covers v0 * t / 2, so v0 = 2 * distance / t.
	_slide_v0 = direction.normalized() * (2.0 * distance / t) + _slide_v0 * (_slide_left / maxf(_slide_total, 0.001))
	_slide_total = t
	_slide_left = t


## A knockback weapon's hit on the corpse (T-531): `weapon_id` is the weapon ("bricks", "wiper",
## "polarized_steering_wheel"; any other pushes nothing), `distance` the weapon's knockback
## distance for a living minion (units); the data's knock_scale_* is the corpse's share of it.
## Returns true when it was hit (the timer restarts).
func knock_by_weapon(direction: Vector2, distance: float, weapon_id: String) -> bool:
	var key := ""
	match weapon_id:
		"bricks": key = "knock_scale_bricks"
		"wiper": key = "knock_scale_wiper"
		"polarized_steering_wheel": key = "knock_scale_shock"
	if not _corpse or key == "" or not corpse_stats.has(key):
		return false
	knock_corpse(direction, distance * float(corpse_stats[key]))
	return true


## True while a knocked corpse still slides.
func is_sliding() -> bool:
	return _slide_left > 0.0


## One physics step of a corpse: slides, counts the timer, fades. Returns true when it has
## faded away completely (the keeper then frees it).
func corpse_step(dt: float) -> bool:
	_corpse_car_gap = maxf(_corpse_car_gap - dt, 0.0)
	if _slide_left > 0.0:
		var h0 := body_height()
		var k := _slide_left / _slide_total
		var v := _slide_v0 * k
		_slide_left = maxf(_slide_left - dt, 0.0)
		var hit := _move(v * dt * PX_PER_UNIT)
		if hit != null:
			var n := hit.get_normal()
			_slide_v0 -= n * minf(_slide_v0.dot(n), 0.0)
			var rest := hit.get_remainder()
			rest -= n * rest.dot(n)
			if rest.length() > 0.0:
				_move(rest)
		elif _edge_normal != Vector2.ZERO:
			_slide_v0 -= _edge_normal * minf(_slide_v0.dot(_edge_normal), 0.0)
		_fall_step(dt, h0)
		corpse_moved = true
	if corpse_fade_left < 0.0:
		corpse_timer -= dt
		if corpse_timer <= 0.0:
			corpse_fade_left = maxf(float(corpse_stats.get("fade_seconds", 0.4)), 0.01)
	else:
		corpse_fade_left -= dt
		if corpse_fade_left <= 0.0:
			return true
	return false


## Starts the fade now (the keeper's cap on corpses, oldest first).
func start_fade_now() -> void:
	if corpse_fade_left < 0.0:
		corpse_timer = 0.0
		corpse_fade_left = maxf(float(corpse_stats.get("fade_seconds", 0.4)), 0.01)


## 1 while the corpse is whole, falling to 0 as it fades.
func corpse_alpha() -> float:
	if corpse_fade_left < 0.0:
		return 1.0
	return clampf(corpse_fade_left / maxf(float(corpse_stats.get("fade_seconds", 0.4)), 0.01), 0.0, 1.0)


## The car drove into the corpse (the keeper checks): knocks it away from the car by a
## distance that grows with the car's speed. Returns true when it was hit.
func car_knock(car_units: Vector2, car_speed: float) -> bool:
	if not _corpse or _corpse_car_gap > 0.0:
		return false
	if car_speed < float(corpse_stats.get("knock_car_min_speed", 2.0)):
		return false
	_corpse_car_gap = float(corpse_stats.get("knock_car_gap_seconds", 0.2))
	var away := position_units() - car_units
	if away.length() < 0.001:
		away = heading
	var d := clampf(car_speed * float(corpse_stats.get("knock_car_per_speed", 0.25)),
		float(corpse_stats.get("knock_car_min", 1.5)), float(corpse_stats.get("knock_car_max", 8.0)))
	knock_corpse(away, d)
	return true


func _die() -> void:
	_dead = true
	remove_from_group("enemies")
	remove_from_group("minions")
	died.emit(self, position_units())
	# T-531: the corpse keeper (a `died` listener) may keep the body, with its drawing, as a corpse.
	if _corpse:
		return
	if sprite != null and is_instance_valid(sprite):
		sprite.queue_free()
	sprite = null
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
	var h0 := body_height()
	var to_target := target_units - position_units()
	var dir := to_target.normalized() if to_target.length() > 0.001 else Vector2.ZERO
	dir += push
	if dir.length() < 0.001:
		_fall_step(dt, h0)
		return
	dir = dir.normalized()
	if _wall_normal != Vector2.ZERO and dir.dot(_wall_normal) < 0.0:
		var along := dir - _wall_normal * dir.dot(_wall_normal)
		if along.length() < 0.5:
			along = _wall_normal.orthogonal() * detour_side
		dir = along.normalized()
	heading = dir
	velocity = dir * move_speed * PX_PER_UNIT
	_drop_now = may_drop
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
	_drop_now = false
	_fall_step(dt, h0)


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
	var h0 := body_height()
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
	_fall_step(dt, h0)


## True when the minion's body touches the car's 1 x 1 unit body
## (`car_centre_units`, rotated `car_rotation`).
func touches_car(car_centre_units: Vector2, car_rotation: float) -> bool:
	var local := (position_units() - car_centre_units).rotated(-car_rotation)
	var nearest := Vector2(clampf(local.x, -0.5, 0.5), clampf(local.y, -0.5, 0.5))
	return local.distance_to(nearest) <= radius_units()


## One physics step of contact damage: while touching the car, it hits it
## (the first hit as soon as it touches) unless the car is still invulnerable
## from a hit (T-334: RunState.is_invulnerable(), 1 s; then no hit and no
## knockback). contact_damage_interval is an optional own repeat on top
## (0, none: enemies.json no longer has it, T-333): the car loses contact_damage through `state.damage_car()` and is
## knocked back away from the minion through `car.apply_knockback()`.
## On a map with heights (T-207) only when the car is at its level
## (EnemyHeight.minion_can_hit, T-515: a car on a rooftop above it, or more than 0.5 units
## up in the air, is not hit). Returns true when it hit this step.
func contact_step(dt: float, car: Node2D, state: Node) -> bool:
	contact_cooldown = maxf(contact_cooldown - dt, 0.0)
	overcoat_cooldown = maxf(overcoat_cooldown - dt, 0.0)
	if _dead or car == null:
		return false
	var car_units: Vector2 = car.position / PX_PER_UNIT
	if not touches_car(car_units, car.rotation):
		return false
	if ground != null and not EnemyHeightScript.minion_can_hit(body_height(), EnemyHeightScript.car_height(car)):
		return false
	# T-463 Rusty Overcoat: the car damages the minion it touches (before the car's own
	# invulnerability, which only protects the car).
	overcoat_cooldown = OvercoatContact.hit(self, state, overcoat_cooldown, false)
	# The overcoat never stops the enemy's own hit on the car (T-477): it hits even when the
	# overcoat's damage just killed it.
	# The car's invulnerability after a hit (T-334): no hit and no knockback, so the
	# car can drive out of a swarm. It is what spaces the hits now.
	if state != null and state.has_method("is_invulnerable") and state.is_invulnerable():
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
