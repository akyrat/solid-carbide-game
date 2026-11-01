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
## - Every package on the map (falling or landed) that is off screen gets an arrow at the screen's edge (gift_arrows.gd).
## - With RunState.pause_on_level_up on (tests and tools only) the old direct
##   flow runs and no helicopter comes.
##
## Numbers: res://data/gift_pack.json through GiftPackData. Coordinates: the
## landing spot is in the car's flat world pixels (ground_px); helicopters and
## packages are drawn in the isometric view's pixels (this node's space, the
## same as the run's View). Helicopters, carried and falling packages are
## drawn over the whole world (SKY_Z); a landed package takes the depth order
## a car would have on that spot (map.car_z_index), under the car's drawing.
##
## Heights (T-402; Level design, Content, "Elevation sample map"): on a map
## with rooftops the package lands on street level when it can. Only when no
## street spot is open within the search (the car well inside a large rooftop)
## does it land on open ground of the rooftop the car is on. Either way it is
## drawn at the height of the ground it lands on (GiftPackage.ground_height),
## in the depth order the car has at that height (elevation_layer.gd z_for),
## and the car picks it up only from that height or above.

const HelicopterScene := preload("res://scenes/run/gift_helicopter.tscn")
const PackageScene := preload("res://scenes/run/gift_package.tscn")
const ArrowsScript := preload("res://scripts/run/gift_arrows.gd")
## T-407: the car's air shadow (car_shadow.gd), reused for a falling package's landing spot.
const ShadowScript := preload("res://scripts/driving/car_shadow.gd")
const ShadowSizeScript := preload("res://scripts/driving/shadow_size.gd")
## T-454: the package's own width on screen (package.png's box, 40 of its 64
## pixels, drawn at scale 1): its falling shadow's full size, reached as it lands.
const PACKAGE_WIDTH_PX := 40.0

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
## T-402: the car picks a package up when its height (units) is at least the
## package's ground height less this, so a car on the street beside a rooftop
## does not pick up a package lying on it, and a car jumping over one still does.
const PickupHeightScript := preload("res://scripts/run/pickup_height.gd")
const PICKUP_HEIGHT_TOLERANCE := PickupHeightScript.TOLERANCE
## Tolerance (units) for "the same height" when checking a rooftop spot.
const SAME_HEIGHT := 0.01

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
	Perf.begin(&"gifts.drops")
	advance(delta)
	Perf.end(&"gifts.drops")


func _on_level_up(new_level: int) -> void:
	if state.pause_on_level_up:
		return  # the old direct flow: the level-up opens its screen at once
	send_helicopter(new_level)


## Removes every helicopter and package (a new run).
func clear() -> void:
	for pkg in packages:
		if is_instance_valid(pkg):
			_remove_shadow(pkg)
	for n in helicopters + packages:
		if is_instance_valid(n):
			n.queue_free()
	helicopters.clear()
	packages.clear()


## Packages lying on the map, waiting to be driven over.
func landed_packages() -> Array:
	return packages.filter(func(p): return p.is_landed())


## Packages on the map, which get an arrow when off screen: falling (from the
## moment it is dropped) and landed; not the one still carried by the helicopter.
func mapped_packages() -> Array:
	return packages.filter(func(p): return p.phase != GiftPackage.CARRIED)


## Sends a helicopter with the package for the level-up of `level`: picks the
## landing spot now (landing_spot()) and a path across the screen that passes
## over it, starting and ending beyond the screen's edges.
func send_helicopter(level: int) -> GiftHelicopter:
	var spot_units := landing_spot()
	var pkg: GiftPackage = PackageScene.instantiate()
	pkg.name = "GiftPackage%d" % level
	pkg.level = level
	pkg.set_ground(spot_units * PX_PER_UNIT, ground_height_at(spot_units))
	pkg.fall_seconds = data.fall_seconds()
	pkg.z_index = SKY_Z
	var heli: GiftHelicopter = HelicopterScene.instantiate()
	heli.name = "GiftHelicopter%d" % level
	heli.draw_scale = data.helicopter_scale()
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
##
## T-402: on a map with rooftops, open road is street level only. When the
## search finds none and the car is on a flat rooftop, it searches the same
## ways again for open ground on that rooftop (is_open_rooftop). Only then the
## car's own spot. The package is drawn at the ground's height there.
func landing_spot() -> Vector2:
	var car: Node2D = run.car
	var centre: Vector2 = car.position / PX_PER_UNIT
	var dir := Vector2.RIGHT.rotated(car.rotation)
	if car is CharacterBody2D and car.velocity.length() > STILL_SPEED:
		dir = car.velocity.normalized()
	var ahead := data.land_ahead_units()
	var tries: Array = []
	for a in SEARCH_ANGLES:
		for share in SEARCH_SHARES:
			tries.append(centre + dir.rotated(deg_to_rad(a)) * ahead * share)
	for p in tries:
		if is_open_road(p):
			return p
	var roof := ground_height_at(centre)
	if roof > SAME_HEIGHT:
		for p in tries:
			if is_open_rooftop(p, roof):
				return p
	return centre


## The ground's height at `units` (units): a rooftop's or ramp's, 0 on the
## street and on maps without rooftops (T-402).
func ground_height_at(units: Vector2) -> float:
	var gh = _ground()
	return gh.height_at(units) if gh != null else 0.0


## The map's ground heights (ground_height.gd), or null without rooftops.
func _ground():
	var map: Node = run.map if run != null else null
	if map == null:
		return null
	var elev = map.get("elevation")
	return elev.ground_height if elev != null else null


## True when the package can land at `units` on a rooftop of `height` (T-402):
## no building, boulder, prop or map edge within clearance_units (the map's
## is_open_spot without its street-only check), and the whole clearance square
## around it lies on flat rooftop of that same height (no ramp, no edge, no
## higher rooftop standing on it).
func is_open_rooftop(units: Vector2, height: float) -> bool:
	var gh = _ground()
	var map: Node = run.map
	if gh == null or map == null or not map.has_method("is_open_spot") or height <= SAME_HEIGHT:
		return false
	var r := data.clearance_units()
	if not map.is_open_spot(units, r, false):
		return false
	for ox in [-r, 0.0, r]:
		for oy in [-r, 0.0, r]:
			var q: Vector2 = units + Vector2(ox, oy)
			if gh.is_ramp(q) or absf(gh.height_at(q) - height) > SAME_HEIGHT:
				return false
	return true


## Moves a landed package's spot to `px` (flat world pixels; the pickup magnet
## pulls it, T-222): its height follows the ground there and its depth order
## is worked out again (T-402).
func move_package(pkg: GiftPackage, px: Vector2) -> void:
	pkg.set_ground(px, ground_height_at(px / PX_PER_UNIT))
	pkg.position = pkg.drawn_ground
	pkg.z_index = landed_z(pkg)


## The depth order of a landed package: the car's at that spot and height,
## under every building, boulder, prop and raised area that covers it there
## (T-402: elevation_layer.gd z_for at the package's ground height; on a map
## without rooftops the map's car_z_index, as before).
func landed_z(pkg: GiftPackage) -> int:
	var map: Node = run.map
	if map == null:
		return 0
	var elev = map.get("elevation")
	if elev != null:
		return elev.z_for(pkg.ground_units(), 0.0, pkg.ground_height)
	return map.car_z_index(pkg.ground_units(), 0.0) if map.has_method("car_z_index") else 0


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
	_add_shadow(pkg)
	package_dropped.emit(pkg)


## T-407 (Game loop architecture, Decisions, "A falling gift pack shows its
## shadow"): while `pkg` falls, the car's shadow (car_shadow.gd, no new art)
## lies at its landing spot, at the height of the ground it lands on, in the
## depth order the car's shadow has there. Removed when it lands.
func _add_shadow(pkg: GiftPackage) -> void:
	_remove_shadow(pkg)
	var sh: Node2D = ShadowScript.new()
	sh.name = "Shadow" + pkg.name
	sh.view_basis = ISO_TRANSFORM
	sh.full_diameter_units = shadow_full_diameter_units()
	add_child(sh)
	sh.place(pkg.ground_units(), pkg.ground_height)
	sh.z_index = shadow_z(pkg)
	pkg.shadow = sh
	update_shadow(pkg)


## T-454: the falling shadow's full size (units across on the ground), the
## package's own width on screen, so it ends at the package's size as it lands.
static func shadow_full_diameter_units() -> float:
	return ShadowSizeScript.diameter_for_screen_width(PACKAGE_WIDTH_PX, PX_PER_UNIT)


## T-454 (Visual style, Decisions, "Shadows shrink with height"): sizes `pkg`'s
## falling shadow by its height above the ground it lands on (shadow_size.gd):
## small high up, growing as it comes down.
func update_shadow(pkg: GiftPackage) -> void:
	if pkg.shadow != null and is_instance_valid(pkg.shadow):
		pkg.shadow.set_height_above(pkg.height() / PX_PER_UNIT)


func _remove_shadow(pkg: GiftPackage) -> void:
	if pkg.shadow != null and is_instance_valid(pkg.shadow):
		pkg.shadow.queue_free()
	pkg.shadow = null


## The depth order of a falling package's shadow: the car's shadow rule at the
## landing spot (on a map without rooftops, just under the car's order).
func shadow_z(pkg: GiftPackage) -> int:
	var map: Node = run.map
	if map == null:
		return 0
	var elev = map.get("elevation")
	if elev != null:
		return elev.shadow_z_for(pkg.ground_units(), 0.0, pkg.ground_height, pkg.ground_height)
	return (map.car_z_index(pkg.ground_units(), 0.0) - 1) if map.has_method("car_z_index") else 0


## Floats down under its parachute at a steady speed and lands after
## fall_seconds.
func _fall(pkg: GiftPackage, delta: float) -> void:
	pkg.fall_t += delta
	var k := 1.0 if pkg.fall_seconds <= 0.0 else clampf(pkg.fall_t / pkg.fall_seconds, 0.0, 1.0)
	pkg.position = pkg.drawn_ground + Vector2(0, -pkg.drop_height * (1.0 - k))
	update_shadow(pkg)
	if k >= 1.0:
		_land(pkg)


func _land(pkg: GiftPackage) -> void:
	pkg.phase = GiftPackage.LANDED
	_remove_shadow(pkg)
	pkg.position = pkg.drawn_ground
	pkg.refresh_look()
	pkg.z_index = landed_z(pkg)
	package_landed.emit(pkg)


## Picks up every landed package whose centre is within pickup_radius_units of
## the car's centre, with the car at the package's height or above (T-402).
func check_pickups() -> void:
	var car: Node2D = run.car
	if car == null or not state.is_running():
		return
	var at: Vector2 = car.position / PX_PER_UNIT
	var reach := data.pickup_radius_units()
	var h := PickupHeightScript.height_of(car)
	for pkg in landed_packages():
		if at.distance_to(pkg.ground_units()) <= reach + RunState.EPSILON \
				and PickupHeightScript.car_reaches(h, pkg.ground_height):
			pick_up(pkg)


## The car drove over `pkg`: it is removed and the level-up screen opens for
## its level (RunState.open_choice, which pauses the run; with another screen
## already open it waits its turn).
func pick_up(pkg: GiftPackage) -> void:
	if not packages.has(pkg):
		return
	packages.erase(pkg)
	_remove_shadow(pkg)
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
