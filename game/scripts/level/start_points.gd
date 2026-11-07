class_name LevelStartPoints
extends RefCounted
## The named start points of a level (task T-560; Level design, Decisions, "The practice
## playground"). A level file's "start_points" is a list of {id, x, y, heading}, each as its
## "spawn" ({x, y, heading}: the cell's middle the car starts on, units, and its heading in degrees,
## LevelSpawn): the practice playground has one per trick slide (drift, alt_drift, air_spin, grind).
## A run given a start point id (run.gd start_point_id) starts the car there instead of on the spawn.

## The ids, in the file's order.
static func ids(level: Dictionary) -> Array:
	var out: Array = []
	var l = level.get("start_points", [])
	if l is Array:
		for p in l:
			if p is Dictionary and p.has("id"):
				out.append(str(p.id))
	return out


## The start point `id` as {x, y, heading} (heading in 0 to 359), or {} when the level has none.
static func of(level: Dictionary, id: String) -> Dictionary:
	var l = level.get("start_points", [])
	if l is Array:
		for p in l:
			if p is Dictionary and str(p.get("id", "")) == id and (p.get("x") is float or p.get("x") is int) \
					and (p.get("y") is float or p.get("y") is int):
				return {"x": float(p.x), "y": float(p.y), "heading": posmod(int(p.get("heading", LevelSpawn.DEFAULT_HEADING)), 360)}
	return {}


## The level with its spawn moved to start point `id` (a copy); the level itself when it has no such point.
static func with_spawn(level: Dictionary, id: String) -> Dictionary:
	var p := of(level, id)
	if p.is_empty():
		return level
	var out := level.duplicate()
	out["spawn"] = p
	return out
