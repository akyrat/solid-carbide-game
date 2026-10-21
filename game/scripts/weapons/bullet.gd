extends Node2D
## One bullet of the starting gun (task T-041; Unity weapons report, section 2,
## "The bullets", with the board's fix that a bullet that misses is removed).
##
## It flies in a straight line from where it was fired at the gun's
## bullet_speed, in the flat world (units), and is drawn in the isometric view
## (this node sits in the rack's draw root). After each move it hits every
## living enemy whose body comes within bullet_hit_radius of its centre (one
## hit per enemy per bullet, closest first): take_damage(damage). It is done
## after 1 + pierce_hits hits, or once it has flown missed_bullet_max_travel
## (the gun's range). It never pushes enemies and passes through walls.
##
## The drawing is the final art (task T-071): a cyan neon ball with a white-hot
## core and a dark outline, game/art/effects/bullet.png (two pulse frames of
## 12 x 12 art pixels, drawn at scale 0.5 like the rest of the world). The hit
## circle is unchanged. No Redgull red.

const PX_PER_UNIT := 16.0
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
## How high above the ground the bullet is drawn, in units (about the car's
## body height), so it looks fired from the car rather than skimming the road.
const DRAW_HEIGHT_UNITS := 0.5

const ART := preload("res://art/effects/bullet.png")
const ART_FRAME := 12
const ART_FRAMES := 2
const ART_SCALE := 0.5
## The bullet pulses between its two frames every this many units flown.
const PULSE_UNITS := 0.4

## Emitted for every hit, with the enemy and the damage dealt.
signal hit(enemy: Node, damage: float)

## Flat world, units.
var units := Vector2.ZERO
var direction := Vector2.RIGHT
var speed := 0.0
var damage := 0.0
var hit_radius := 1.0
var max_hits := 1
var max_travel := 0.0
var travelled := 0.0
var drawn_size := 0.32
var hits := 0
var rack: Node = null
## Enemies this bullet has hit already (instance ids).
var _hit_ids := {}
var _done := false
## Which pulse frame is drawn (0 or 1).
var frame := 0


## Sets the bullet up from the gun's stats (WeaponData.gun_at).
func setup(the_rack: Node, from_units: Vector2, dir: Vector2, stats: Dictionary) -> void:
	rack = the_rack
	units = from_units
	direction = dir.normalized()
	speed = float(stats["bullet_speed"])
	damage = float(stats["damage"])
	hit_radius = float(stats["bullet_hit_radius"])
	max_hits = 1 + int(stats["pierce_hits"])
	max_travel = float(stats["missed_bullet_max_travel"])
	drawn_size = float(stats.get("bullet_drawn_size", drawn_size))
	_place()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	reset_physics_interpolation()


func is_done() -> bool:
	return _done


## One physics step: move, then hit.
func step(dt: float) -> void:
	if _done:
		return
	var move := speed * dt
	units += direction * move
	travelled += move
	_check_hits()
	if not _done and travelled > max_travel:
		_done = true
	var f := int(travelled / PULSE_UNITS) % ART_FRAMES
	if f != frame:
		frame = f
		queue_redraw()
	_place()


func _check_hits() -> void:
	if rack == null:
		return
	var touching := []
	for e in rack.living_enemies():
		if _hit_ids.has(e.get_instance_id()):
			continue
		var d: float = units.distance_to(e.position_units())
		if d <= hit_radius + rack.radius_of(e):
			touching.append([d, e])
	touching.sort_custom(func(a, b) -> bool: return a[0] < b[0])
	for pair in touching:
		var e: Node = pair[1]
		_hit_ids[e.get_instance_id()] = true
		hits += 1
		e.take_damage(damage)
		hit.emit(e, damage)
		if hits >= max_hits:
			_done = true
			return


func _place() -> void:
	position = ISO_TRANSFORM * (units * PX_PER_UNIT) + Vector2(0.0, -DRAW_HEIGHT_UNITS * PX_PER_UNIT)
	if rack != null and rack.depth != null:
		z_index = rack.depth.z_index_for(units, drawn_size / 2.0, DRAW_HEIGHT_UNITS)


func _draw() -> void:
	var size := ART_FRAME * ART_SCALE
	draw_texture_rect_region(ART, Rect2(Vector2(-size / 2.0, -size / 2.0), Vector2(size, size)),
		Rect2(Vector2(frame * ART_FRAME, 0), Vector2(ART_FRAME, ART_FRAME)))
