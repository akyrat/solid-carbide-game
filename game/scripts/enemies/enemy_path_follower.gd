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

## Seconds between two paths for one enemy while it is not on the car's surface.
const REPATH_SECONDS := 1.0
## A path point counts as reached this close, units.
const REACH := 1.0

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
	if nav.surface_at(from) == car_s:
		_forget()
		return car_units
	clock -= dt
	if (car_s != car_surface or clock <= 0.0) and (not budgeted or nav.can_find_path()):
		path = nav.find_path(from, car_units)
		index = 0
		clock = REPATH_SECONDS
		car_surface = car_s
		paths_found += 1
	while index < path.size() and from.distance_to(path[index]) <= REACH:
		index += 1
	if index >= path.size():
		return car_units
	return path[index]


func has_path() -> bool:
	return index < path.size()


func _forget() -> void:
	path = PackedVector2Array()
	index = 0
	car_surface = -2
