extends "res://scripts/weapons/weapon.gd"
## The molotovs (task T-169; Weapons, Decisions, 2026-10-18): thrown from the
## car at random, each one makes a circular area on fire where it lands, and
## enemies in a fire area burn and take damage, only while they are inside it
## (board, 2026-10-18). Every number comes from res://data/weapons.json
## ("molotov") through WeaponData.molotov_at(); the garage damage bonus
## multiplies the damage (weapon.gd, boosted_damage()).
##
## One of the run's weapons (listed in weapons.gd's WEAPON_SCRIPTS, id
## "molotov"): a run starts without it (tier 0); `run.weapons.upgrade("molotov")`
## gives it (0 to 1) and applies tiers 2 to 8. The rack steps it once per
## physics step while it is owned and the run is going.
##
## Throwing (the agent's proposal, T-169 result notes): a clock counts physics
## time from when the car gets the molotovs. Each time it reaches
## `throw_interval` it goes back to 0 and `molotovs_per_throw` bottles are
## thrown at once. Each bottle picks its own landing spot with `rng`: a
## direction anywhere around the car (uniform angle) and a distance from the
## car's centre uniform between `throw_distance_min` and `throw_distance_max`.
## Enemies play no part in where a bottle lands. The spot is fixed when the
## bottle leaves; it flies there in FLIGHT_SECONDS along a small arc and makes a
## fire area there (molotov_fire.gd) with the tier's radius, duration, damage
## and tick interval at the moment it lands.
##
## Bottles and fire areas are projectiles of the rack (rack.add_projectile), so
## they stop while the run is paused or over and are removed at a new run. The
## bottles are drawn in the rack's draw root (in the air, the bullets' depth
## rule); the fire areas on the ground, in the map's drawing just after the
## drift marks (FIRE_ROOT_NAME), so the buildings, enemies and car are drawn
## over them.
##
## Look: placeholders drawn in code (MolotovBottle below, molotov_fire.gd). No
## Redgull red. The art task swaps the final art in.

const FireScript := preload("res://scripts/weapons/molotov_fire.gd")

## Flat world pixels per unit (Car.PX_PER_UNIT).
const PX_PER_UNIT := 16.0
## The run's isometric projection (run.gd ISO_TRANSFORM).
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
const EPS := 1e-6
## How long a bottle is in the air, in seconds (a look and feel value of the
## placeholder, not in the data: the agent's proposal, judged in the playtest).
const FLIGHT_SECONDS := 0.5
## How high the bottle's arc goes at its middle, in units, over the throw
## height (the car's roof).
const ARC_PEAK_UNITS := 1.5
const THROW_HEIGHT_UNITS := 0.5
## Name of the node holding the fire areas in the map's drawing.
const FIRE_ROOT_NAME := "MolotovFires"
## The playtest switch file (res://data/playtest.json), one key of several.
const PLAYTEST_FILE := "playtest"
const PLAYTEST_KEY := "molotov_at_start"

## Placeholder bottle colours: green glass, a pale rag, an orange-yellow
## flame on the rag, a dark outline. Opaque; never Redgull red.
const BOTTLE_GLASS := Color(0.3, 0.72, 0.38, 1.0)
const BOTTLE_GLASS_DARK := Color(0.16, 0.45, 0.24, 1.0)
const BOTTLE_RAG := Color(0.92, 0.86, 0.7, 1.0)
const BOTTLE_FLAME := Color(1.0, 0.78, 0.2, 1.0)
const BOTTLE_OUTLINE := Color(0.05, 0.07, 0.12, 1.0)

## Tests set this to 0 (off) or 1 (on) to override data/playtest.json; -1 reads the file.
static var playtest_override := -1

## A bottle left the car, towards `landing` (flat world, units).
signal thrown(bottle: Node, landing: Vector2)
## A bottle landed and made a fire area.
signal fire_started(fire: Node)

## WeaponData.molotov_at(tier) (tier 1's values while not owned), damage boosted.
var stats: Dictionary = {}
## Seconds since the last throw (or since the car got the molotovs).
var throw_clock := 0.0
## Throws, bottles and fire areas this run (for tests and notes).
var throws := 0
var bottles := 0
var fires := 0
## The weapon's random generator: tests set rng.seed to get the same spots.
## A new run does not re-seed it, so a seeded test stays seeded.
var rng := RandomNumberGenerator.new()


func _init() -> void:
	weapon_id = "molotov"
	starts_owned = false
	stats = data.molotov_at(1)
	rng.randomize()


## The playtest switch: data/playtest.json "molotov_at_start" (or playtest_override).
static func playtest_switch_on() -> bool:
	if playtest_override >= 0:
		return playtest_override == 1
	var r := GameData.load_file(PLAYTEST_FILE)
	if not r.ok:
		return false
	var v := GameData.get_value(r.data, PLAYTEST_KEY)
	return v.ok and bool(v.data)


func _car() -> Node2D:
	if rack == null or rack.car == null or not is_instance_valid(rack.car):
		return null
	return rack.car


# --- Tiers and runs --------------------------------------------------------

func apply_tier() -> void:
	stats = data.molotov_at(maxi(tier, 1))
	stats["damage"] = boosted_damage(float(stats["damage"]))
	if not is_owned():
		throw_clock = 0.0


func reset_for_run() -> void:
	throw_clock = 0.0
	throws = 0
	bottles = 0
	fires = 0
	super.reset_for_run()


## Seconds between throws at the current tier.
func throw_interval() -> float:
	return float(stats["throw_interval"])


# --- Each step -------------------------------------------------------------

func step(dt: float) -> void:
	if _car() == null:
		return
	throw_clock += dt
	if throw_clock < throw_interval() - EPS:
		return
	throw_clock = 0.0
	throw_volley()


## Throws `molotovs_per_throw` bottles now, each to its own random spot.
func throw_volley() -> Array:
	throws += 1
	var out := []
	for i in int(stats["molotovs_per_throw"]):
		out.append(throw_to(random_landing()))
	return out


## A random landing spot (flat world, units) around the car's centre now.
func random_landing() -> Vector2:
	var angle := rng.randf() * TAU
	var d := rng.randf_range(float(stats["throw_distance_min"]), float(stats["throw_distance_max"]))
	return car_units() + Vector2.from_angle(angle) * d


## Throws one bottle from the car's centre to `landing` (flat world, units).
func throw_to(landing: Vector2) -> Node:
	var b := MolotovBottle.new()
	b.name = "MolotovBottle"
	b.setup(self, car_units(), landing)
	rack.add_projectile(b)
	bottles += 1
	thrown.emit(b, landing)
	return b


## Called by a bottle when it lands: a fire area at `centre` with the tier's
## values now. Returns the fire.
func land(centre: Vector2) -> Node:
	var f: Node2D = FireScript.new()
	f.name = "MolotovFire"
	f.setup(rack, centre, stats)
	rack.add_projectile(f, fire_root())
	fires += 1
	fire_started.emit(f)
	return f


## The car's centre in units (flat world), from its driving model.
func car_units() -> Vector2:
	var car := _car()
	return Vector2(car.model.x, car.model.y) if car != null else Vector2.ZERO


## Where fire areas are drawn: a node in the current map's drawing just after
## the drift marks (the map's view applies the isometric transform), made once
## per map. Without a map (never in a run), a node in the rack's draw root with
## the isometric transform.
func fire_root() -> Node2D:
	var map = rack.run.get("map") if rack.run != null else null
	var parent: Node = null
	var after: Node = null
	if map != null and is_instance_valid(map) and map.get("view_root") != null:
		parent = map.view_root
		after = rack.run.get("drift_marks")
	var existing: Node = null
	if parent != null:
		existing = parent.get_node_or_null(FIRE_ROOT_NAME)
	elif rack.draw_root != null:
		existing = rack.draw_root.get_node_or_null(FIRE_ROOT_NAME)
	if existing != null:
		return existing
	var root := Node2D.new()
	root.name = FIRE_ROOT_NAME
	if parent != null:
		parent.add_child(root)
		if after != null and is_instance_valid(after) and after.get_parent() == parent:
			parent.move_child(root, after.get_index() + 1)
	else:
		root.transform = ISO_TRANSFORM
		rack.draw_root.add_child(root)
		rack.draw_root.move_child(root, 0)
	return root


## One bottle in the air (a projectile of the rack): flies from `from` to
## `landing` (flat world, units) in FLIGHT_SECONDS, along an arc, then calls
## the weapon's land() and is done. Drawn as a small placeholder bottle with a
## burning rag, spinning, in the rack's draw root.
class MolotovBottle:
	extends Node2D

	var weapon = null
	var from := Vector2.ZERO
	var landing := Vector2.ZERO
	var units := Vector2.ZERO
	var age := 0.0
	var fire: Node = null
	var _done := false

	func setup(the_weapon, from_units: Vector2, landing_units: Vector2) -> void:
		weapon = the_weapon
		from = from_units
		landing = landing_units
		units = from
		_place()

	func _ready() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		reset_physics_interpolation()

	func is_done() -> bool:
		return _done

	## 0 when thrown, 1 when it lands.
	func progress() -> float:
		return clampf(age / FLIGHT_SECONDS, 0.0, 1.0)

	## Height over the ground, in units: the throw height easing down to 0,
	## plus the arc.
	func height_units() -> float:
		var f := progress()
		return THROW_HEIGHT_UNITS * (1.0 - f) + 4.0 * ARC_PEAK_UNITS * f * (1.0 - f)

	func step(dt: float) -> void:
		if _done:
			return
		age += dt
		units = from.lerp(landing, progress())
		if age >= FLIGHT_SECONDS - EPS:
			units = landing
			_done = true
			if weapon != null:
				fire = weapon.land(landing)
		rotation = age * TAU * 2.0  # two turns a second
		_place()

	func _place() -> void:
		position = ISO_TRANSFORM * (units * PX_PER_UNIT) + Vector2(0.0, -height_units() * PX_PER_UNIT)
		if weapon != null and weapon.rack != null and weapon.rack.depth != null:
			z_index = weapon.rack.depth.z_index_for(units, 0.2, height_units() + 0.3)

	## Every colour the bottle draws with (tests check none is Redgull red).
	func colours() -> Array:
		return [BOTTLE_OUTLINE, BOTTLE_GLASS, BOTTLE_GLASS_DARK, BOTTLE_RAG, BOTTLE_FLAME]

	func _draw() -> void:
		# A bottle about 0.3 by 0.6 units, its neck up, in screen pixels.
		draw_rect(Rect2(-3, -3, 6, 9), BOTTLE_OUTLINE)
		draw_rect(Rect2(-2, -2, 4, 7), BOTTLE_GLASS)
		draw_rect(Rect2(-2, 3, 4, 2), BOTTLE_GLASS_DARK)
		draw_rect(Rect2(-2, -7, 4, 5), BOTTLE_OUTLINE)
		draw_rect(Rect2(-1, -6, 2, 4), BOTTLE_RAG)
		draw_rect(Rect2(-2, -10, 4, 3), BOTTLE_FLAME)
