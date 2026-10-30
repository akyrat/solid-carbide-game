extends Area2D
## A coin a minion dropped (task T-044). Driving over it collects it: the run's
## coins go up by `value` through RunState.add_coins() and the coin is gone.
##
## It lives in the flat top-down physics world like the car, as an Area2D on
## collision layer 4 (pickups) with mask 2 (the car), so it notices the car
## driving over it (game/docs/driving/collisions.md, "Collision layers"). `sprite`
## (coin_sprite.gd) draws it in the isometric view; it is freed with the coin.

const PX_PER_UNIT := 16.0
const LAYER_CAR := 1 << 1
const LAYER_PICKUPS := 1 << 3
## The pickup circle's radius, in units (a size, not a balancing number).
const RADIUS_UNITS := 0.5
const PickupHeightScript := preload("res://scripts/run/pickup_height.gd")

## Emitted once when the car collects it.
signal collected(coin: Node, value: int)

var value := 1
## The run's state (RunState): add_coins() is called on it.
var state: Node = null
var sprite: Node2D = null
## The height of the ground it lies on, units (T-402): a rooftop's on a rooftop. The spawner sets
## it; the car picks it up only from that height or above (pickup_height.gd).
var ground_height := 0.0
var _taken := false


func _ready() -> void:
	add_to_group("coins")
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
	if body.collision_layer & LAYER_CAR and can_be_picked_up_by(body):
		collect()


## True when `car` is high enough to pick it up (T-402): not from the street below a rooftop.
func can_be_picked_up_by(car: Node) -> bool:
	return PickupHeightScript.car_reaches(PickupHeightScript.height_of(car), ground_height)


## Collects the coin: adds `value` to the run's coins and removes it. Once only.
func collect() -> void:
	if _taken:
		return
	_taken = true
	if state != null:
		state.add_coins(value)
	remove_from_group("coins")
	if sprite != null and is_instance_valid(sprite):
		sprite.queue_free()
	sprite = null
	collected.emit(self, value)
	# Freed at the end of the frame: removing an Area2D inside its own physics
	# callback is not allowed.
	queue_free()


func is_taken() -> bool:
	return _taken
