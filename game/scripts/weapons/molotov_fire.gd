extends Node2D
## One molotov's fire area (task T-169; Weapons, Decisions, 2026-10-18): a
## circle on the ground where a bottle landed (molotovs.gd), burning for
## `fire_duration` seconds. A projectile of the rack (step(dt), is_done()), so
## it stops while the run is paused or over and is removed at a new run.
##
## Damage: enemies burn only while they are inside (board, 2026-10-18). Each
## enemy has its own clock, as the neon underglow's: an enemy inside is hit
## (take_damage(damage), signal enemy_hit) when this fire has not hit it in the
## last `tick_interval` seconds, so it is hit on the step it enters (with
## damage_on_enter) and every interval while it stays; one that leaves takes
## nothing more. Two fire areas are separate: an enemy inside both is hit by
## each (the agent's proposal, judged in the playtest). The values are the
## molotovs' tier when the bottle landed, damage already times the garage bonus.
##
## Who is inside: the rack's target rule, as the flamethrower's and the
## underglow's. A minion is inside when its centre is within `radius` of the
## fire's centre; an enemy that reports its body size with hit_radius_units()
## (the kaiju) when its body overlaps the circle at all.
##
## Look: a placeholder drawn in code, a flat circle on the ground. This node
## sits in a node of the map's drawing whose view applies the isometric
## transform, so it draws in flat world pixels and the circle shows as the
## ground ellipse. Opaque hard-edged orange and yellow with a dark rim, a few
## flickering yellow tongues; never Redgull red.

const PX_PER_UNIT := 16.0
const EPS := 1e-6
## Placeholder colours (opaque, Visual style). Orange and yellow, never Redgull red.
const FIRE_OUTLINE := Color(0.05, 0.07, 0.12, 1.0)
const FIRE_OUTER := Color(1.0, 0.55, 0.1, 1.0)
const FIRE_INNER := Color(1.0, 0.82, 0.25, 1.0)
const FIRE_CORE := Color(1.0, 0.96, 0.7, 1.0)
## The final art (T-175): the fire and its mirrored copy, the flicker's two frames.
const ART_PATH := "res://art/weapons/molotov_fire.png"
const ART_FLIP_PATH := "res://art/weapons/molotov_fire_flip.png"
const ART_TEXTURE := preload("res://art/weapons/molotov_fire.png")
const ART_FLIP_TEXTURE := preload("res://art/weapons/molotov_fire_flip.png")
const ART_SCALE := 0.5
const ART_RADIUS_UNITS := 1.5
## The run's isometric projection (run.gd ISO_TRANSFORM).
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
## How often the flicker changes, in seconds.
const FLICKER_SECONDS := 0.1

## Every hit, with the damage dealt.
signal enemy_hit(enemy: Node, amount: float)

var rack: Node = null
## Flat world, units.
var centre := Vector2.ZERO
var radius := 1.5
var duration := 3.0
var damage := 2.0
var tick_interval := 0.5
var damage_on_enter := true
## Seconds since the fire started.
var age := 0.0
var hits := 0
## Enemies inside on the last step: instance id -> node.
var inside: Dictionary = {}
## Seconds since each recently hit enemy's last hit: instance id -> seconds.
var since_hit: Dictionary = {}
var _done := false
var _flicker := 0


## Sets the fire up at `at` (flat world, units) from the molotovs' stats
## (WeaponData.molotov_at, damage boosted).
func setup(the_rack: Node, at: Vector2, stats: Dictionary) -> void:
	rack = the_rack
	centre = at
	radius = float(stats["fire_radius"])
	duration = float(stats["fire_duration"])
	damage = float(stats["damage"])
	tick_interval = float(stats["tick_interval"])
	damage_on_enter = bool(stats.get("damage_on_enter", true))
	position = centre * PX_PER_UNIT


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	reset_physics_interpolation()


func is_done() -> bool:
	return _done


## Seconds left before it goes out.
func time_left() -> float:
	return maxf(duration - age, 0.0)


func step(dt: float) -> void:
	if _done:
		return
	age += dt
	if age > duration + EPS:
		_done = true
		inside.clear()
		since_hit.clear()
		return
	for id in since_hit.keys():
		since_hit[id] += dt
	var now_inside := {}
	if rack != null:
		for e in rack.living_enemies():
			if is_inside(e):
				now_inside[e.get_instance_id()] = e
	for id in now_inside:
		var e: Node = now_inside[id]
		if not inside.has(id) and not damage_on_enter and not since_hit.has(id):
			since_hit[id] = 0.0  # without damage on entering, the first hit waits one interval
			continue
		if not since_hit.has(id) or since_hit[id] >= tick_interval - EPS:
			since_hit[id] = 0.0
			_hit(e)
	for id in since_hit.keys():
		if not now_inside.has(id) and since_hit[id] >= tick_interval - EPS:
			since_hit.erase(id)
	inside = now_inside
	var f := int(age / FLICKER_SECONDS)
	if f != _flicker:
		_flicker = f
		queue_redraw()


## Whether a point (flat world, units) is inside the circle.
func contains_point(p: Vector2) -> bool:
	return p.distance_to(centre) <= radius + EPS


## Whether an enemy is inside: its body overlapping the circle when it reports
## its size (hit_radius_units(), the kaiju), its centre otherwise (the minions).
func is_inside(e: Node) -> bool:
	var c: Vector2 = e.position_units() if e.has_method("position_units") else (e as Node2D).position / PX_PER_UNIT
	if e.has_method("hit_radius_units"):
		return c.distance_to(centre) <= radius + maxf(float(e.hit_radius_units()), 0.0) + EPS
	return contains_point(c)


func _hit(e: Node) -> void:
	hits += 1
	enemy_hit.emit(e, damage)
	e.take_damage(damage)


## Every colour the fire draws with (tests check none is Redgull red).
func colours() -> Array:
	return [FIRE_OUTLINE, FIRE_OUTER, FIRE_INNER, FIRE_CORE]


func _draw() -> void:
	var tex: Texture2D = ART_FLIP_TEXTURE if _flicker % 2 == 1 else ART_TEXTURE
	if tex != null:
		# The final art (T-175): the fire ellipse as the iso view shows the circle
		# it was made for (1.5 units), at scale 0.5 in screen pixels. This node is
		# drawn in flat world pixels under the map's iso transform, so the sprite is
		# undone through the inverse transform to keep its pixels square on screen.
		var k := ART_SCALE * radius / ART_RADIUS_UNITS
		var size := tex.get_size() * k
		draw_set_transform_matrix(ISO_TRANSFORM.affine_inverse())
		draw_texture_rect(tex, Rect2(-size / 2.0, size), false)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		return
	var r := radius * PX_PER_UNIT
	draw_circle(Vector2.ZERO, r + 1.0, FIRE_OUTLINE, true, -1.0, false)
	draw_circle(Vector2.ZERO, r, FIRE_OUTER, true, -1.0, false)
	draw_circle(Vector2.ZERO, r * 0.62, FIRE_INNER, true, -1.0, false)
	# A few yellow tongues that move every FLICKER_SECONDS, so it reads as burning.
	var n := 6
	for i in n:
		var a := TAU * (float(i) + 0.5 * float((_flicker + i) % 2)) / float(n)
		var p := Vector2.from_angle(a) * r * 0.75
		draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), FIRE_INNER)
	draw_circle(Vector2.ZERO, r * 0.25, FIRE_CORE, true, -1.0, false)
