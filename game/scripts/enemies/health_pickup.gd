extends Area2D
## A health pickup a minion dropped (task T-220). Driving over it restores
## `restore_fraction` of the car's maximum health through RunState.heal_car(),
## never above the maximum, and the pickup is gone (also at full health: a
## proposal for the playtest).
##
## Built like the coin (coin.gd): an Area2D on collision layer 4 (pickups) with
## mask 2 (the car), in the group "health_pickups" so a magnet can find it the
## way it finds "coins". `sprite` (health_pickup_sprite.gd) draws it and is
## freed with it.

const PX_PER_UNIT := 16.0
const LAYER_CAR := 1 << 1
const LAYER_PICKUPS := 1 << 3
## The pickup circle's radius, in units (a size, not a balancing number).
const RADIUS_UNITS := 0.5

## Emitted once when the car collects it, with the health points restored.
signal collected(pickup: Node, restored: float)

## The share of the car's maximum health it restores (enemies.json, health_drops).
var restore_fraction := 0.3
var state: Node = null
var sprite: Node2D = null
var _taken := false


func _ready() -> void:
	add_to_group("health_pickups")
	collision_layer = LAYER_PICKUPS
	collision_mask = LAYER_CAR
	monitorable = false
	var shape := CircleShape2D.new()
	shape.radius = RADIUS_UNITS * PX_PER_UNIT
	var col := CollisionShape2D.new()
	col.name = "Pickup"
	col.shape = shape
	add_child(col)
	body_entered.connect(_on_body_entered)


func _exit_tree() -> void:
	if sprite != null and is_instance_valid(sprite):
		sprite.queue_free()
	sprite = null


func position_units() -> Vector2:
	return position / PX_PER_UNIT


func _on_body_entered(body: Node) -> void:
	if body.collision_layer & LAYER_CAR:
		collect()


## Collects it: restores the health and removes it. Once only.
func collect() -> void:
	if _taken:
		return
	_taken = true
	var restored := 0.0
	if state != null:
		restored = state.heal_car(restore_fraction * state.max_health)
	remove_from_group("health_pickups")
	if sprite != null and is_instance_valid(sprite):
		sprite.queue_free()
	sprite = null
	collected.emit(self, restored)
	queue_free()


func is_taken() -> bool:
	return _taken
