class_name PickupMagnet
extends Node
## The pickup magnet (task T-222; Game loop architecture, Decisions, "Pickup
## magnet"). Coins, landed gift packs and health drops within
## RunState.pickup_magnet_radius_units of the car's centre are pulled straight
## to the car, at RunState.pickup_pull_speed units per second (numbers: run.json's
## pickup_magnet). Picking up is unchanged: the pickup's own rule fires when the
## car touches it (the coin's Area2D, the package's pickup radius, the health
## drop's own). The magnet only moves them; it does not follow the car's height
## (proposal): the reach is measured on the flat map.
##
## It is a pausable node: while the run is paused or over, nothing is pulled.

const PX_PER_UNIT := 16.0
## Same 2:1 isometric projection as the run and the map.
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
## A pulled coin or drop is picked up once this close to the car's centre, in
## units (the car's body is 1 x 1 unit): the same as touching it.
const TOUCH_UNITS := 0.5
## Groups of pickups that take part. Coins join "coins" themselves (coin.gd);
## health drops join "health_drops". Each is a flat-world node with `position`
## in pixels, an optional `sprite` drawn in the isometric view, and collect().
const GROUPS := ["coins", "health_drops"]

var run: Node2D
var state: RunState


func bind(the_run: Node2D) -> void:
	run = the_run
	state = run.state


func _physics_process(delta: float) -> void:
	step(delta)


## Pulls every pickup inside the reach `delta` seconds closer to the car. Tests call it by hand.
func step(delta: float) -> void:
	if state == null or not state.is_running() or run == null:
		return
	var car: Node2D = run.car
	if car == null or not is_instance_valid(car):
		return
	var at: Vector2 = car.position / PX_PER_UNIT
	for group in GROUPS:
		for p in get_tree().get_nodes_in_group(group):
			if not is_instance_valid(p) or (p.has_method("is_taken") and p.is_taken()):
				continue
			var d := _pull(p, p.position / PX_PER_UNIT, at, delta)
			if d != Vector2.ZERO:
				p.position += d * PX_PER_UNIT
				var s = p.get("sprite")
				if s != null and is_instance_valid(s):
					s.position += ISO_TRANSFORM.basis_xform(d * PX_PER_UNIT)
					s.reset_physics_interpolation()
				if (at - p.position / PX_PER_UNIT).length() <= TOUCH_UNITS and p.has_method("collect"):
					p.collect()
	var drops: GiftDrops = run.gift_drops
	if drops != null:
		for pkg in drops.landed_packages():
			var d := _pull(pkg, pkg.ground_units(), at, delta)
			if d != Vector2.ZERO:
				pkg.ground_px += d * PX_PER_UNIT
				pkg.drawn_ground = ISO_TRANSFORM * pkg.ground_px
				pkg.position = pkg.drawn_ground


## How far `pickup` (at `pos` units) moves towards `car` this step, in units: nothing
## outside the reach, otherwise pull_speed x delta, never past the car.
func _pull(_pickup: Node, pos: Vector2, car: Vector2, delta: float) -> Vector2:
	var to_car := car - pos
	var dist := to_car.length()
	if dist > state.pickup_magnet_radius_units or dist <= 0.0001:
		return Vector2.ZERO
	return to_car / dist * minf(state.pickup_pull_speed * delta, dist)
