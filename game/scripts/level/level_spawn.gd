class_name LevelSpawn
extends RefCounted

## T-405: the short buildings are platforms (short_platforms.gd).
const ShortPlatformsScript := preload("res://scripts/level/short_platforms.gd")
## The car's spawn point of a level (task T-280; Level design, Decisions, "The car's spawn point").
## A level file's "spawn" is {x, y, heading}: the cell's middle the car starts on (units) and its
## heading in degrees, the car model's rotation (0 faces +x, 270 faces -y, the run's own start).
## The height is not stored: the car stands on whatever ground is there (GroundHeight). One place
## for the rules; game/tools/check_level.py checks the same ones.
##
## Proposals: eight headings (every 45 degrees), a clearance of 1 unit round a building, an
## obstacle (prop) or a boulder's edge (the cell next to one is allowed), the map's centre and the
## run's own heading for a level without a spawn point.

const CELL := 2.0
## Degrees between two headings (R turns the start by this much): eight headings.
const HEADING_STEP := 45
## The run's own start heading (run.gd START_ROTATION = -PI / 2), in degrees.
const DEFAULT_HEADING := 270
## How close to a building, a prop or a boulder's edge the car may start (units).
const CLEARANCE := 1.0

const OFF_MAP := "off_map"
const BLOCKED := "blocked"


## The level's spawn point {x, y, heading}: its "spawn" when it is valid in form, else the map's
## centre and the default heading (a level saved before T-280).
static func of(data: Dictionary) -> Dictionary:
	var s = data.get("spawn")
	if s is Dictionary and s.has("x") and s.has("y") and (s.x is float or s.x is int) \
			and (s.y is float or s.y is int):
		var h := int(s.get("heading", DEFAULT_HEADING))
		return {"x": float(s.x), "y": float(s.y), "heading": posmod(h, 360)}
	var c := centre_of(data)
	return {"x": c.x, "y": c.y, "heading": DEFAULT_HEADING}


static func has_spawn(data: Dictionary) -> bool:
	var s = data.get("spawn")
	return s is Dictionary and s.has("x") and s.has("y")


static func position_of(data: Dictionary) -> Vector2:
	var s := of(data)
	return Vector2(s.x, s.y)


## The heading as the car model's rotation (radians).
static func rotation_of(data: Dictionary) -> float:
	return deg_to_rad(float(of(data).heading))


## The map's centre, snapped to the middle of the cell it falls in.
static func centre_of(data: Dictionary) -> Vector2:
	return snap(data, _map_rect(data).get_center())


## The middle of the cell (CELL units wide, from the map's corner) that holds `units`.
static func snap(data: Dictionary, units: Vector2) -> Vector2:
	var r := _map_rect(data)
	return r.position + ((units - r.position) / CELL).floor() * CELL + Vector2(CELL, CELL) / 2.0


## The next heading when the start is turned (R).
static func turned(heading: int) -> int:
	return posmod(heading + HEADING_STEP, 360)


## "" when a car can stand at `units` (inside the map, clear of every building, prop and boulder),
## else OFF_MAP or BLOCKED. Rooftops and ramps are fine: the car stands at their height (and since
## T-405 the short buildings, which are platforms).
static func problem(data: Dictionary, units: Vector2) -> String:
	if not _map_rect(data).has_point(units):
		return OFF_MAP
	for key in ["buildings", "props"]:
		var items = data.get(key, [])
		if items is Array:
			for b in items:
				# T-405: a short building is a platform the car can stand on, like a rooftop.
				if key == "buildings" and b is Dictionary and ShortPlatformsScript.is_platform_entry(b):
					continue
				if b is Dictionary and _rect(b).grow(CLEARANCE).has_point(units) \
						and not _on_edge(_rect(b).grow(CLEARANCE), units):
					return BLOCKED
	var copies = data.get("pattern_copies", [])
	if copies is Array:
		for copy in copies:
			if not (copy is Dictionary):
				continue
			for b in copy.get("boulders", []):
				var reach := float(b.diameter) / 2.0 + CLEARANCE
				if units.distance_to(Vector2(float(b.x), float(b.y))) < reach - 0.0001:
					return BLOCKED
	return ""


## A point on the very edge of the grown rectangle does not count as inside it (a cell next to a
## building is allowed).
static func _on_edge(r: Rect2, p: Vector2) -> bool:
	return is_equal_approx(p.x, r.position.x) or is_equal_approx(p.x, r.end.x) \
		or is_equal_approx(p.y, r.position.y) or is_equal_approx(p.y, r.end.y)


static func _rect(d: Dictionary) -> Rect2:
	return Rect2(float(d.x), float(d.y), float(d.w), float(d.h))


static func _map_rect(data: Dictionary) -> Rect2:
	var m = data.get("map", {})
	if m is Dictionary and m.get("rect") is Dictionary:
		var r: Dictionary = m.rect
		return Rect2(float(r.x), float(r.y), float(r.w), float(r.h))
	return Rect2(-120.0, -120.0, 240.0, 240.0)
