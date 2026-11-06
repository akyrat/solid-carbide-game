extends RefCounted
## Rails (task T-541; Level design, Decisions, "Rails"; the format: Level design, Content,
## "Rails (task T-541)"). A rail is a map piece: a straight bar at a height that the car can
## grind along (Drifting, Content, "Rail grinding (task T-541)"; rail_grind.gd).
##
## A level file holds them in its "rails" list, one dictionary per rail:
##   {"id": "rail-1", "x1": 6.0, "y1": -6.0, "z1": 1.0, "x2": 6.0, "y2": -60.0, "z2": 1.0}
## - id: unique in the level ("rail-N", as the creator names its pieces);
## - x1, y1 and x2, y2: its two ends on the map, units (x east, y south, the map's own units);
## - z1 and z2: the bar's height above the street at each end, units (z2 may be left out: then
##   it is z1, a level rail). Between the ends the height changes in a straight line, so a rail
##   can climb from one rooftop to a higher one.
## A rail is a straight segment: corners are two rails whose ends meet. The order of the ends
## does not matter: the car grinds either way.
##
## This script reads and checks the list (from_layout, problem) and gives the geometry the grind
## and the drawing use (closest, height_at). It needs no scene tree.

## The shortest rail the game takes, units: a shorter one is skipped (problem()).
const MIN_LENGTH := 1.0


## The level's rails, checked: an array of dictionaries {"id", "a": Vector2, "b": Vector2,
## "za": float, "zb": float, "length": float, "dir": Vector2 (unit, a to b)}. A rail that
## fails problem() is skipped with a warning.
static func from_layout(layout: Dictionary) -> Array:
	var out: Array = []
	var l = layout.get("rails", [])
	if not (l is Array):
		return out
	for r in l:
		if not (r is Dictionary):
			continue
		var why := problem(r)
		if why != "":
			push_warning("Rail %s skipped: %s" % [str(r.get("id", "?")), why])
			continue
		out.append(make(str(r.get("id", "rail-%d" % out.size())),
			Vector2(float(r.x1), float(r.y1)), Vector2(float(r.x2), float(r.y2)),
			float(r.z1), float(r.get("z2", r.z1))))
	return out


## A rail from its ends (units) and their heights (units).
static func make(id: String, a: Vector2, b: Vector2, za: float, zb: float) -> Dictionary:
	var length := a.distance_to(b)
	return {
		"id": id,
		"a": a,
		"b": b,
		"za": za,
		"zb": zb,
		"length": length,
		"dir": (b - a) / length if length > 0.0 else Vector2.RIGHT,
	}


## Why a rail entry of a level file is not usable ("" when it is): a missing or non-number end,
## a height at or below the street (z 0), or shorter than MIN_LENGTH.
static func problem(r: Dictionary) -> String:
	for k in ["x1", "y1", "z1", "x2", "y2"]:
		if not r.has(k):
			return "no %s" % k
		if not (r[k] is float or r[k] is int):
			return "%s is not a number" % k
	if r.has("z2") and not (r.z2 is float or r.z2 is int):
		return "z2 is not a number"
	if float(r.z1) <= 0.0 or float(r.get("z2", r.z1)) <= 0.0:
		return "a height at or below the street"
	if Vector2(float(r.x1), float(r.y1)).distance_to(Vector2(float(r.x2), float(r.y2))) < MIN_LENGTH:
		return "shorter than %s units" % MIN_LENGTH
	return ""


## The distance along the rail (units from end a, not clamped) of `point`'s projection.
static func along(rail: Dictionary, point: Vector2) -> float:
	return (point - rail.a).dot(rail.dir)


## The point on the rail's line at `s` units from end a (not clamped).
static func point_at(rail: Dictionary, s: float) -> Vector2:
	return rail.a + rail.dir * s


## The bar's height at `s` units from end a (held at the ends' heights past them).
static func height_at(rail: Dictionary, s: float) -> float:
	if rail.length <= 0.0:
		return float(rail.za)
	return lerpf(float(rail.za), float(rail.zb), clampf(s / float(rail.length), 0.0, 1.0))


## The flat distance (units) from `point` to the rail's line, measured square to it.
static func side_distance(rail: Dictionary, point: Vector2) -> float:
	var d: Vector2 = point - rail.a
	return absf(d.cross(rail.dir))
