extends Node2D
class_name BurnFlames
## The flames on a burning enemy (task T-071, the final art; Visual style, Effects: burning).
##
## A weapon that burns an enemy adds itself as a source (`BurnFlames.add_source(enemy, source_id)`) and removes
## itself when the enemy stops burning (`remove_source`): the flamethrower's burn flash and each molotov fire the
## enemy stands in. The flames show while any source is left and go when the last one is removed; two sources
## never draw two flames. It only draws: it does not change damage, tint or movement.
##
## The node is a child of the enemy's `sprite` (the drawing node, so it moves with the enemy, sorts with it and
## is freed with it), drawn over the sprite with its base on the enemy's ground point. The art is
## game/art/effects/burning_flames.png (two mirrored frames of 48 x 54 art pixels, built by
## game/tools/build_weapon_effects.py), drawn at 0.5 like the rest of the world; a bigger enemy (the kaiju) gets
## bigger flames in whole steps, by its body radius.

const NODE_NAME := "BurnFlames"
const ART := preload("res://art/effects/burning_flames.png")
const FRAME_SIZE := Vector2(48, 54)
const FRAMES := 2
const ART_SCALE := 0.5
## How often the flicker changes, in seconds.
const FLICKER_SECONDS := 0.12
## The body radius (units) one step of flame size covers: a minion's.
const MINION_RADIUS_UNITS := 0.5
const MAX_STEPS := 4
## The flames' base sits this many screen pixels above the enemy's ground point.
const BASE_LIFT := 1.0

## Source ids now burning this enemy.
var sources := {}
var frame := 0
var steps := 1
var _clock := 0.0


## Adds a burning source to an enemy that has a `sprite`; makes the flames if there are none yet.
static func add_source(enemy: Node, source_id: Variant) -> void:
	var node := _find(enemy)
	if node == null:
		var sprite = enemy.get("sprite") if enemy != null else null
		if sprite == null or not is_instance_valid(sprite) or not (sprite is Node2D):
			return
		node = load("res://scripts/enemies/burn_flames.gd").new()
		node.name = NODE_NAME
		node.steps = clampi(roundi(_radius_of(enemy) / MINION_RADIUS_UNITS), 1, MAX_STEPS)
		sprite.add_child(node)
	node.sources[source_id] = true


## Takes a source away; the flames go with the last one.
static func remove_source(enemy: Node, source_id: Variant) -> void:
	var node := _find(enemy)
	if node == null:
		return
	node.sources.erase(source_id)
	if node.sources.is_empty():
		node.queue_free()


## Whether an enemy has flames on now.
static func is_burning(enemy: Node) -> bool:
	var node := _find(enemy)
	return node != null and not node.sources.is_empty()


static func _find(enemy: Node) -> BurnFlames:
	if enemy == null or not is_instance_valid(enemy):
		return null
	var sprite = enemy.get("sprite")
	if sprite == null or not is_instance_valid(sprite):
		return null
	return sprite.get_node_or_null(NODE_NAME) as BurnFlames


static func _radius_of(enemy: Node) -> float:
	if enemy.has_method("hit_radius_units"):
		return float(enemy.hit_radius_units())
	return MINION_RADIUS_UNITS


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame = randi() % FRAMES  # a crowd does not flicker in unison


func _process(delta: float) -> void:
	_clock += delta
	if _clock >= FLICKER_SECONDS:
		_clock = 0.0
		frame = (frame + 1) % FRAMES
		queue_redraw()


func _draw() -> void:
	var k := ART_SCALE * steps
	var size := FRAME_SIZE * k
	draw_texture_rect_region(ART, Rect2(Vector2(-size.x / 2.0, -size.y - BASE_LIFT), size),
		Rect2(Vector2(frame * FRAME_SIZE.x, 0), FRAME_SIZE))
