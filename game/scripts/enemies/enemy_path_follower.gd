extends RefCounted
## Where one enemy walks next (task T-207): straight at the car when both are
## on the same surface (the street, one rooftop, one ramp; as before T-207),
## otherwise along a path from the map's navigation (enemy_navigation.gd) to
## the car, which goes by the ramps. Each enemy (minion or kaiju) owns one.
##
## A path is asked for when the enemy leaves the car's surface, when the car
## changes surface, and then every REPATH_SECONDS while they stay apart (each
## enemy's clock starts at a random point, so the asks spread over the steps).
## The enemy walks to each point of the path in turn, the next once it is
## within REACH units, and after the last one straight at the car.
##
## Drops (T-226): when the path drops off a rooftop's edge (two points in a
## row, the second more than MAX_STEP lower; enemy_navigation.gd, is_drop),
## dropping() is true from DROP_NEAR units before the edge's point until the
## point below it is the target, and the enemy may then walk out over the edge.

## Seconds between two paths for one enemy while it is not on the car's surface.
const REPATH_SECONDS := 1.0
## A path point counts as reached this close, units.
const REACH := 1.0
## How near (units) the point on an edge the enemy may come before it may drop
## off: farther than a cell plus REACH, so a body that keeps its radius off the
## edge (the kaiju's 2 units) still reaches that point.
const DROP_NEAR := 3.0
const EnemyHeightScript := preload("res://scripts/enemies/enemy_height.gd")

## T-380 (Enemies, Decisions, "Minions don't get stuck on ramps"): with
## `by_sight` (the minions; the kaiju keeps the surface rule) the enemy walks
## straight at the car only while the line to it is clear on the navigation's
## grid (enemy_navigation.gd, line_clear), on any surface, and otherwise by a
## path. Before, "the car's surface" decided: on the street a ramp's high side,
## a rooftop's edge or a building between them was walked into head-on (stuck
## in the pocket where a ramp's side meets its rooftop), and at a ramp's foot
## a minion went back and forth between the street (straight) and the ramp (a
## path back to the foot's point).
var by_sight := false
## Seconds between two sight checks, and the half width (units) of the line
## checked: the body's distance off an edge (minion.gd, BASE_RADIUS_UNITS).
const SIGHT_SECONDS := 0.1
const SIGHT_HALF_WIDTH := 0.5
## With `by_sight`, a path point counts as reached this close (units) instead
## of REACH: a minion of 1 unit (T-379) that turned for the next point 1 unit
## early cut a building's corner and jammed on it.
const SIGHT_REACH := 0.5
var sight := true
var sight_clock := 0.0
## How many sight checks it made (tests).
var sight_checks := 0

var path := PackedVector2Array()
var index := 0
## Seconds until the next path.
var clock := 0.0
## The car's surface the path was made for (-2 = no path yet).
var car_surface := -2
## How many paths it asked for (for tests and the soak).
var paths_found := 0


## `start_clock`: seconds until the first repath once a path is in use (the
## spawner gives each enemy its own, 0 to REPATH_SECONDS).
func _init(start_clock: float = 0.0) -> void:
	clock = start_clock


## The point (flat units) to walk towards this step, `dt` seconds, from
## `from` to the car at `car_units`. `nav` null (no heights): the car.
## `budgeted` (the minions): a new path only while the navigation's budget
## for the step lasts (enemy_navigation.gd, PATHS_PER_STEP); otherwise it
## keeps its old path (or walks at the car) and asks again next step. The
## kaiju, one enemy, passes false.
func target(nav, from: Vector2, car_units: Vector2, dt: float, budgeted: bool = true) -> Vector2:
	if nav == null:
		return car_units
	var car_s: int = nav.surface_at(car_units)
	if by_sight:
		# T-380: straight only while nothing stands between it and the car.
		sight_clock -= dt
		if sight_clock <= 0.0:
			sight = nav.line_clear(from, car_units, SIGHT_HALF_WIDTH)
			sight_clock = SIGHT_SECONDS
			sight_checks += 1
		if sight:
			_forget()
			return car_units
	elif nav.surface_at(from) == car_s:
		_forget()
		return car_units
	clock -= dt
	if (car_s != car_surface or clock <= 0.0) and (not budgeted or nav.can_find_path()):
		path = nav.find_path(from, car_units)
		index = 0
		clock = REPATH_SECONDS
		car_surface = car_s
		paths_found += 1
	var reach := SIGHT_REACH if by_sight else REACH
	while index < path.size() and from.distance_to(path[index]) <= reach:
		index += 1
	if index >= path.size():
		return car_units
	return path[index]


## True when the enemy at `from`, its body at `body_h` units, is on its way
## off an edge this step (see the top): its target is the point below an edge
## and more than MAX_STEP below it, or its target is the point on an edge,
## DROP_NEAR units away or less, and the path drops from there. Never on the
## way down a ramp (its foot is not a drop from its top's point).
func dropping(nav, from: Vector2, body_h: float) -> bool:
	if nav == null or index >= path.size():
		return false
	var p := path[index]
	if index > 0 and nav.is_drop(path[index - 1], p):
		return body_h - nav.ground.height_at(p) > EnemyHeightScript.MAX_STEP
	return index + 1 < path.size() and from.distance_to(p) <= DROP_NEAR and nav.is_drop(p, path[index + 1])


func has_path() -> bool:
	return index < path.size()


func _forget() -> void:
	path = PackedVector2Array()
	index = 0
	car_surface = -2
