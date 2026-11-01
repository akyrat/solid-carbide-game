class_name PickupMagnet
extends Node
## The pickup magnet (task T-222; Game loop architecture, Decisions, "Pickup
## magnet"). Coins, landed gift packs and health drops within
## RunState.pickup_magnet_radius_units of the car's centre are pulled straight
## to the car, at RunState.pickup_pull_speed units per second (numbers: run.json's
## pickup_magnet). Picking up is unchanged: the pickup's own rule fires when the
## car touches it (the coin's Area2D, the package's pickup radius, the health
## drop's own). The magnet only moves them. The reach is measured on the flat
## map, and (T-402, proposal) it pulls only pickups on the level the car is on
## (the ground under the car, pickup_height.gd); a pulled pickup is drawn at the
## height of the ground it is pulled over.
##
## It is a pausable node: while the run is paused or over, nothing is pulled.

const PX_PER_UNIT := 16.0
## Same 2:1 isometric projection as the run and the map.
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
## A pulled coin or drop is picked up once this close to the car's centre, in
## units (the car's body is 1 x 1 unit): the same as touching it.
const TOUCH_UNITS := 0.5
## Groups of pickups that take part. Coins join "coins" themselves (coin.gd);
## health drops join "health_pickups". Each is a flat-world node with `position`
## in pixels, an optional `sprite` drawn in the isometric view, and collect().
const GROUPS := ["coins", "health_pickups"]
const PickupHeightScript := preload("res://scripts/run/pickup_height.gd")
## How high a coin's or health drop's sprite is drawn for the depth order (units), as at spawn.
const SPRITE_HEIGHT_UNITS := 0.6

var run: Node2D
var state: RunState


func bind(the_run: Node2D) -> void:
	run = the_run
	state = run.state


func _physics_process(delta: float) -> void:
	Perf.begin(&"pickups.magnet")
	step(delta)
	Perf.end(&"pickups.magnet")


## Pulls every pickup inside the reach `delta` seconds closer to the car. Tests call it by hand.
func step(delta: float) -> void:
	# T-413 (replaces T-406's coins standing still): during the wreck coins and
	# health pickups are pulled and picked up as usual (coins count, a health
	# pickup revives the car); the gift packs stand still.
	var wrecked: bool = state != null and state.is_wrecked()
	if state == null or not (state.is_running() or wrecked) or run == null:
		return
	var car: Node2D = run.car
	if car == null or not is_instance_valid(car):
		return
	var at: Vector2 = car.position / PX_PER_UNIT
	var ground = _ground()
	var car_level := PickupHeightScript.ground_at(ground, at)
	for group in GROUPS:
		for p in get_tree().get_nodes_in_group(group):
			if not is_instance_valid(p) or (p.has_method("is_taken") and p.is_taken()):
				continue
			if not PickupHeightScript.same_level(_height_of(p), car_level):
				continue  # T-402: only pickups on the car's level
			if p.has_method("wants_health") and not p.wants_health():
				continue  # T-415: a health pickup at full hearts stays where it is
			var d := _pull(p, p.position / PX_PER_UNIT, at, delta)
			if d != Vector2.ZERO:
				p.position += d * PX_PER_UNIT
				_follow_ground(p, ground)
				if (at - p.position / PX_PER_UNIT).length() <= TOUCH_UNITS and p.has_method("collect"):
					if not p.has_method("can_be_picked_up_by") or p.can_be_picked_up_by(car):
						p.collect()
	var drops: GiftDrops = run.gift_drops
	if drops != null and not wrecked:
		for pkg in drops.landed_packages():
			if not PickupHeightScript.same_level(pkg.ground_height, car_level):
				continue  # T-402: only packages on the car's level
			var d := _pull(pkg, pkg.ground_units(), at, delta)
			if d != Vector2.ZERO:
				# T-402: its height and depth follow the ground it is pulled over.
				drops.move_package(pkg, pkg.ground_px + d * PX_PER_UNIT)


## The map's ground heights (ground_height.gd), or null on a map without rooftops.
func _ground():
	var elev = run.get("elevation") if run != null else null
	return elev.ground_height if elev != null else null


func _height_of(p: Node) -> float:
	var h = p.get("ground_height")
	return float(h) if h != null else 0.0


## After a pull (T-402): the pickup lies at the height of the ground under it now, and its
## sprite is drawn there, in the depth order the minions' spawner gives pickups at that height.
func _follow_ground(p: Node, ground) -> void:
	var units: Vector2 = p.position / PX_PER_UNIT
	var h := PickupHeightScript.ground_at(ground, units)
	if p.get("ground_height") != null:
		p.ground_height = h
	var s = p.get("sprite")
	if s == null or not is_instance_valid(s):
		return
	s.position = ISO_TRANSFORM * p.position + Vector2(0.0, -h * PX_PER_UNIT)
	var spawner = run.get("minions")
	if spawner != null and spawner.get("depth") != null:
		var r = p.get("RADIUS_UNITS")
		s.z_index = spawner.depth.z_index_for(units, float(r) if r != null else 0.5, SPRITE_HEIGHT_UNITS, h)
	s.reset_physics_interpolation()


## How far `pickup` (at `pos` units) moves towards `car` this step, in units: nothing
## outside the reach, otherwise pull_speed x delta, never past the car.
func _pull(_pickup: Node, pos: Vector2, car: Vector2, delta: float) -> Vector2:
	var to_car := car - pos
	var dist := to_car.length()
	if dist > state.pickup_magnet_radius_units or dist <= 0.0001:
		return Vector2.ZERO
	return to_car / dist * minf(state.pickup_pull_speed * delta, dist)
