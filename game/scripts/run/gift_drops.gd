class_name GiftDrops
extends Node2D
## The gift pack drop (task T-144; Game loop architecture, Decisions, "Gift
## pack drop", with the board's answers of 2026-10-16). A level-up no longer
## opens the level-up screen by itself. Instead, on every level-up
## (RunState.level_up) a helicopter (GiftHelicopter) flies across the screen
## and drops a package (GiftPackage) that falls and lands a short way ahead of
## the car, on open road. When the car drives over a landed package, the
## package is removed and RunState.open_choice() opens the level-up screen for
## that package's level (T-052, offers from T-043), pausing the run as before.
##
## - The run keeps going (clock, enemies, likes, the drain) while the
##   helicopter comes and the package waits. This node is pausable: while the
##   run is paused (pause screen, level-up screen) helicopters and falling
##   packages stand still and nothing is picked up.
## - One package per level-up; several level-ups mean several packages, each
##   opening its own screen. Packages stay until picked up; a new run clears them.
## - Off-screen landed packages get an arrow at the screen's edge (gift_arrows.gd).
## - With RunState.pause_on_level_up on (tests and tools only) the old direct
##   flow runs and no helicopter comes.
##
## Numbers: res://data/gift_pack.json through GiftPackData. Coordinates: the
## landing spot is in the car's flat world pixels (ground_px); helicopters and
## packages are drawn in the isometric view's pixels (this node's space, the
## same as the run's View). Helicopters, carried and falling packages are
## drawn over the whole world (SKY_Z); a landed package takes the depth order
## a car would have on that spot (map.car_z_index), under the car's drawing.

const HelicopterScene := preload("res://scenes/run/gift_helicopter.tscn")
const PackageScene := preload("res://scenes/run/gift_package.tscn")
const ArrowsScript := preload("res://scripts/run/gift_arrows.gd")

const PX_PER_UNIT := 16.0
## Same 2:1 isometric projection as the run and the map.
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
## Over everything in the world (buildings top out far below), under the HUD's layers.
const SKY_Z := 4000
## Below this speed (world pixels per second) "ahead" is the car's nose, not its motion.
const STILL_SPEED := 1.0
## The ways tried around "straight ahead" (degrees) and the share of the
## landing distance tried for each, nearest to straight ahead first, until a
## spot of open road is found.
const SEARCH_ANGLES := [0.0, 20.0, -20.0, 40.0, -40.0, 60.0, -60.0, 90.0, -90.0, 120.0, -120.0, 150.0, -150.0, 180.0]
const SEARCH_SHARES := [1.0, 0.75, 1.25, 0.5, 1.5, 0.25]

## A helicopter set off for the level-up of `level`.
signal helicopter_sent(helicopter: Node2D)
## The helicopter dropped its package: it starts falling.
signal package_dropped(package: Node2D)
## A package landed on the map and waits to be driven over.
signal package_landed(package: Node2D)
## The car drove over a package: it is gone, and its level-up screen opens.
signal package_picked_up(package: Node2D)

var run: Node2D
var state: RunState
var data: GiftPackData
## Helicopters in the air.
var helicopters: Array = []
## Every package not picked up yet: carried, falling or landed.
var packages: Array = []
## The off-screen arrows (gift_arrows.gd), a CanvasLayer child of the run.
var arrows: CanvasLayer


## Hooks the gift pack into `the_run` (run.gd calls it once).
func bind(the_run: Node2D, the_data: GiftPackData = null) -> void:
	run = the_run
	state = run.state
	data = the_data if the_data != null else GiftPackData.new()
	state.level_up.connect(_on_level_up)
	state.run_started.connect(clear)
	arrows = ArrowsScript.new()
	arrows.name = "GiftArrows"
	run.add_child(arrows)
	arrows.bind(self, run.hud)


func _process(delta: float) -> void:
	advance(delta)


func _on_level_up(new_level: int) -> void:
	if state.pause_on_level_up:
		return  # the old direct flow: the level-up opens its screen at once
	send_helicopter(new_level)


## Removes every helicopter and package (a new run).
func clear() -> void:
	for n in helicopters + packages:
		if is_instance_valid(n):
			n.queue_free()
	helicopters.clear()
	packages.clear()


## Packages lying on the map, waiting to be driven over.
func landed_packages() -> Array:
	return packages.filter(func(p): return p.is_landed())


## Sends a helicopter with the package for the level-up of `level`: picks the
## landing spot now (landing_spot()) and a path across the screen that passes
## over it, starting and ending beyond the screen's edges.
func send_helicopter(level: int) -> GiftHelicopter:
	var spot_units := landing_spot()
	var pkg: GiftPackage = PackageScene.instantiate()
	pkg.name = "GiftPackage%d" % level
	pkg.level = level
	pkg.ground_px = spot_units * PX_PER_UNIT
	pkg.drawn_ground = ISO_TRANSFORM * pkg.ground_px
	pkg.fall_seconds = data.fall_seconds()
	pkg.z_index = SKY_Z
	var heli: GiftHelicopter = HelicopterScene.instantiate()
	heli.name = "GiftHelicopter%d" % level
	heli.speed = data.helicopter_speed()
	heli.drop_x = pkg.drawn_ground.x
	var view := visible_rect()
	var half := view.size.x / 2.0 + data.offscreen_margin()
	var mid := view.get_center().x
	heli.from_x = minf(pkg.drawn_ground.x, mid) - half
	heli.to_x = maxf(pkg.drawn_ground.x, mid) + half
	heli.z_index = SKY_Z + 1
	heli.package = pkg
	add_child(pkg)
	add_child(heli)
	heli.position = Vector2(heli.from_x, fly_y(heli, pkg))
	pkg.position = heli.position + carry_offset()
	helicopters.append(heli)
	packages.append(pkg)
	helicopter_sent.emit(heli)
	return heli


## Where the package hangs under the helicopter: hang_below_px under the
## helicopter's centre (the package's bottom), clear of its belly.
func carry_offset() -> Vector2:
	return Vector2(0, data.hang_below_px())


## How far the helicopter's frame reaches above its centre, in drawn pixels
## (from its sprite, so it follows the art).
func helicopter_top(heli: GiftHelicopter) -> float:
	var s := heli.sprite()
	if s == null or s.texture == null:
		return 0.0
	return -(s.get_rect().position.y * s.scale.y + s.position.y)


## How far a sprite's drawing (its opaque pixels) reaches above its node's
## origin, in drawn pixels; for the package's parachute look, the canopy's top.
func art_height(s: Sprite2D) -> float:
	if s == null or s.texture == null:
		return 0.0
	var img := s.texture.get_image()
	var used := img.get_used_rect()
	var top := s.get_rect().position.y + used.position.y
	return -(top * s.scale.y + s.position.y)


## The height the helicopter flies at (drawn y) while it carries `pkg`:
## drop_height_px above the landing spot, but never so high that its frame
## comes closer than screen_margin_px to the screen's top edge, so it is
## always fully seen. Worked out again every frame while it carries the
## package, because the camera follows the car.
func fly_y(heli: GiftHelicopter, pkg: GiftPackage) -> float:
	var top_line := visible_rect().position.y + data.screen_margin() + helicopter_top(heli)
	return maxf(pkg.drawn_ground.y - data.drop_height(), top_line)


## The part of the world on screen now, in drawn pixels (the camera's view).
func visible_rect() -> Rect2:
	var size := get_viewport().get_visible_rect().size
	var cam: Camera2D = run.camera if run != null else null
	if cam == null:
		return Rect2(-size / 2.0, size)
	var world := size / cam.zoom
	return Rect2(cam.get_screen_center_position() - world / 2.0, world)


## Where the next package lands, in units from the map's centre: a short way
## ahead of the car (gift_pack.json's land_ahead_units, along the way it is
## moving, or its nose when standing still), on open road (map.is_open_spot
## with clearance_units). When straight ahead is blocked it tries other ways
## and distances, nearest to straight ahead first; if none is open it uses the
## car's own spot.
func landing_spot() -> Vector2:
	var car: Node2D = run.car
	var centre: Vector2 = car.position / PX_PER_UNIT
	var dir := Vector2.RIGHT.rotated(car.rotation)
	if car is CharacterBody2D and car.velocity.length() > STILL_SPEED:
		dir = car.velocity.normalized()
	var ahead := data.land_ahead_units()
	for a in SEARCH_ANGLES:
		for share in SEARCH_SHARES:
			var p: Vector2 = centre + dir.rotated(deg_to_rad(a)) * ahead * share
			if is_open_road(p):
				return p
	return centre


## True when the package can land at `units`: open road with the clearance
## around it (no building, boulder or map edge within clearance_units).
func is_open_road(units: Vector2) -> bool:
	var map: Node = run.map
	if map == null or not map.has_method("is_open_spot"):
		return true
	return map.is_open_spot(units, data.clearance_units())


## Moves helicopters and falling packages on by `delta` seconds, then picks up
## any landed package the car is on. Called every frame (_process); tests call
## it by hand. Nothing moves once the run has ended.
func advance(delta: float) -> void:
	if state == null or not state.is_running():
		return
	for heli in helicopters.duplicate():
		heli.position.x += heli.speed * delta
		var pkg: GiftPackage = heli.package
		if pkg != null:
			heli.position.y = fly_y(heli, pkg)
			if heli.position.x >= heli.drop_x:
				_drop(heli)
			else:
				pkg.position = heli.position + carry_offset()
		if heli.position.x >= heli.to_x:
			helicopters.erase(heli)
			heli.queue_free()
	for pkg in packages.duplicate():
		if pkg.is_falling():
			_fall(pkg, delta)
	check_pickups()


func _drop(heli: GiftHelicopter) -> void:
	var pkg: GiftPackage = heli.package
	heli.package = null
	heli.dropped = true
	pkg.phase = GiftPackage.FALLING
	pkg.fall_t = 0.0
	pkg.refresh_look()
	# It falls from where it hangs, and at least min_fall_px, so the parachute
	# is seen coming down (when the screen leaves little room above the
	# landing spot it starts a little higher, behind the helicopter's body).
	# But it never starts so high that the parachute's top is above the
	# screen's top edge (less screen_margin_px): when the camera is zoomed in
	# close and the landing spot is high on the screen, the fall is shorter,
	# down to none, and the parachute stays in sight for fall_seconds anyway.
	var hang_y := heli.position.y + carry_offset().y
	var wanted := maxf(pkg.drawn_ground.y - hang_y, data.min_fall())
	var room := pkg.drawn_ground.y - (visible_rect().position.y + data.screen_margin() + art_height(pkg.sprite()))
	pkg.drop_height = clampf(wanted, 0.0, maxf(room, 0.0))
	pkg.position = pkg.drawn_ground + Vector2(0, -pkg.drop_height)
	package_dropped.emit(pkg)


## Floats down under its parachute at a steady speed and lands after
## fall_seconds.
func _fall(pkg: GiftPackage, delta: float) -> void:
	pkg.fall_t += delta
	var k := 1.0 if pkg.fall_seconds <= 0.0 else clampf(pkg.fall_t / pkg.fall_seconds, 0.0, 1.0)
	pkg.position = pkg.drawn_ground + Vector2(0, -pkg.drop_height * (1.0 - k))
	if k >= 1.0:
		_land(pkg)


func _land(pkg: GiftPackage) -> void:
	pkg.phase = GiftPackage.LANDED
	pkg.position = pkg.drawn_ground
	pkg.refresh_look()
	var map: Node = run.map
	pkg.z_index = map.car_z_index(pkg.ground_units(), 0.0) if map != null and map.has_method("car_z_index") else 0
	package_landed.emit(pkg)


## Picks up every landed package whose centre is within pickup_radius_units of
## the car's centre.
func check_pickups() -> void:
	var car: Node2D = run.car
	if car == null or not state.is_running():
		return
	var at: Vector2 = car.position / PX_PER_UNIT
	var reach := data.pickup_radius_units()
	for pkg in landed_packages():
		if at.distance_to(pkg.ground_units()) <= reach + RunState.EPSILON:
			pick_up(pkg)


## The car drove over `pkg`: it is removed and the level-up screen opens for
## its level (RunState.open_choice, which pauses the run; with another screen
## already open it waits its turn).
func pick_up(pkg: GiftPackage) -> void:
	if not packages.has(pkg):
		return
	packages.erase(pkg)
	pkg.queue_free()
	package_picked_up.emit(pkg)
	state.open_choice(pkg.level)


## Tests and screenshot fixtures: every helicopter drops at once and every
## package lands at once (helicopters fly on and leave as usual).
func land_all() -> void:
	for heli in helicopters:
		if heli.package != null:
			_drop(heli)
	for pkg in packages:
		if pkg.is_falling():
			_land(pkg)


## Tests and screenshot fixtures: lands everything, then picks up every landed
## package, oldest first, as if the car drove over each.
func pick_up_all() -> void:
	land_all()
	for pkg in landed_packages():
		pick_up(pkg)
