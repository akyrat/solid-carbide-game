class_name LevelSnapping
extends RefCounted
## Where a piece goes in the level creator (task T-237; Level design, Decisions, "Level creator":
## pieces snap to the map's tile grid and to close neighbours, so they align with little effort).
##
## 1. The tile grid: the piece's top-left corner goes on the corner of the 2 x 2 unit cell under the
##    cursor (LevelDocument.CELL, enemy_navigation.gd's CELL = 2; check_level.py checks the same),
##    so every edge of a piece whose size is even lies on even units.
## 2. Close neighbours (rooftops, ramps and buildings, and for a building the road tiles too): when
##    an edge of the piece is within SNAP_DISTANCE of a neighbour's edge, on the same axis, and the
##    two are side by side (their gap on the other axis is within SNAP_DISTANCE too), the piece
##    moves so that edge lies on the neighbour's: flush against it (a building against a road), or
##    lined up with it (a 6 on a 3, along the 3's edges). Each axis moves by its closest such edge.
## 3. A ramp: when its top end is within SNAP_DISTANCE of the side it climbs (its view's side) of a
##    rooftop at its top height, it goes onto that side, and within it (check_height_data.py's rule);
##    that wins over 2.
## Every neighbour edge is on even units already, so a snapped piece stays on the grid. A move that
## would take the piece out of the map is not made.
##
## Overlaps (overlap_problem): a rooftop or ramp that would overlap in a way check_height_data.py
## (run by check_level.py) refuses is not placed; the editor shows creator_texts.json's
## "overlap_message".

## Proposal (game/README.md, "Level creator"): how close, in units, an edge must be to a neighbour's
## edge to snap onto it. Two cells: a near miss of one or two tiles lines up, a gap of three stays.
const SNAP_DISTANCE := 4.0
const CELL := LevelDocument.CELL
const E := 0.001
## The kinds that snap to neighbours, and the kinds they snap to. Ground, road tiles and boulders
## only snap to the grid.
const SNAPPING_KINDS := ["building", "rooftop", "ramp"]


## The top-left corner (units) for placing `asset_id` with the cursor at `units`, in `view` and
## `mirror`: {corner: Vector2, rect: Rect2, snapped: "" | "neighbour" | "ramp"}; {} for an unknown
## asset or a cursor outside the map.
static func placement(doc: LevelDocument, asset_id: String, units: Vector2, view: String = "", mirror: bool = false) -> Dictionary:
	var e := LevelDocument.entry(asset_id)
	var c := doc.cell_at(units)
	if e.is_empty() or c.x < 0:
		return {}
	var kind := str(e.kind)
	var corner := doc.cell_corner(c)
	var foot := Vector2(float(e.footprint_units[0]), float(e.footprint_units[1]))
	if kind in ["ground", "road"] and not e.has("parts"):
		foot = Vector2(CELL, CELL)
	elif e.has("parts"):
		# A road piece (T-252): 2 x 2 tiles, moved in so all four tiles are on the map.
		var m := doc.map_rect()
		corner = corner.clamp(m.position, m.end - foot)
	var rect := Rect2(corner, foot)
	var out := {"corner": corner, "rect": rect, "snapped": ""}
	if not (kind in SNAPPING_KINDS):
		return out
	var map := doc.map_rect()
	if kind == "ramp":
		var t := LevelDocument.texture_of(asset_id, LevelDocument.valid_view(asset_id, view),
			LevelDocument.valid_mirror(asset_id, mirror))
		var onto := ramp_snap(doc, rect, str(t.get("side", "east")), float(e.heights[1]))
		if not onto.is_empty() and _holds(map, onto.rect):
			return {"corner": onto.rect.position, "rect": onto.rect, "snapped": "ramp"}
	var shift := neighbour_shift(rect, neighbours(doc, kind, rect))
	if shift != Vector2.ZERO:
		var moved := Rect2(rect.position + shift, rect.size)
		if _holds(map, moved):
			return {"corner": moved.position, "rect": moved, "snapped": "neighbour"}
		# One axis may still fit.
		for s in [Vector2(shift.x, 0), Vector2(0, shift.y)]:
			moved = Rect2(rect.position + s, rect.size)
			if s != Vector2.ZERO and _holds(map, moved):
				return {"corner": moved.position, "rect": moved, "snapped": "neighbour"}
	return out


## The neighbour rects (units) a piece of `kind` at `rect` can snap to: the placed buildings,
## rooftops and ramps near it, and for a building also the road tiles near it.
## [{rect: Rect2, flush_only: bool}] (a road tile is only stood against, never lined up with).
static func neighbours(doc: LevelDocument, kind: String, rect: Rect2) -> Array:
	var near := rect.grow(SNAP_DISTANCE + E)
	var out: Array = []
	for key in ["buildings", "platforms", "ramps"]:
		for it in doc.data.get(key, []):
			var r := Rect2(float(it.x), float(it.y), float(it.w), float(it.h))
			if near.intersects(r, true):
				out.append({"rect": r, "flush_only": false})
	if kind == "building":
		var m := doc.map_rect()
		var c0 := doc.cell_at(near.position.clamp(m.position, m.end - Vector2(E, E)))
		var c1 := doc.cell_at(near.end.clamp(m.position, m.end - Vector2(E, E)))
		for j in range(c0.y, c1.y + 1):
			for i in range(c0.x, c1.x + 1):
				if LevelDocument._kind_of_tile(doc.tile_at(Vector2i(i, j))) == "road":
					out.append({"rect": Rect2(doc.cell_corner(Vector2i(i, j)), Vector2(CELL, CELL)), "flush_only": true})
	return out


## How far to move `rect` so its edges land on the closest neighbour edges within SNAP_DISTANCE
## (each axis on its own; 0 on an axis with none, or when an edge is already on one).
static func neighbour_shift(rect: Rect2, near: Array) -> Vector2:
	var best := [INF, INF]
	for n in near:
		var r: Rect2 = n.rect
		var flush_only: bool = n.flush_only
		for axis in 2:
			var other := 1 - axis
			# Side by side: the gap between them on the other axis is within the snap distance.
			var gap := maxf(r.position[other] - rect.end[other], rect.position[other] - r.end[other])
			if gap > SNAP_DISTANCE + E:
				continue
			var ds: Array = [r.position[axis] - rect.end[axis], r.end[axis] - rect.position[axis]]
			if not flush_only:
				ds.append(r.position[axis] - rect.position[axis])
				ds.append(r.end[axis] - rect.end[axis])
			for d in ds:
				if absf(d) <= SNAP_DISTANCE + E and absf(d) < absf(best[axis]):
					best[axis] = d
	return Vector2(0.0 if best[0] == INF else best[0], 0.0 if best[1] == INF else best[1])


## A ramp at `rect` climbing `side` to `top_height`: the closest rooftop at that height whose `side`
## its top end is within SNAP_DISTANCE of, and where the ramp goes on it: its top end on that side,
## moved along it (by at most SNAP_DISTANCE) to lie within it. {rect, platform} or {}.
static func ramp_snap(doc: LevelDocument, rect: Rect2, side: String, top_height: float) -> Dictionary:
	var best: Dictionary = {}
	var best_d := INF
	for p in doc.data.get("platforms", []):
		if absf(float(p.height) - top_height) > E:
			continue
		var a := Rect2(float(p.x), float(p.y), float(p.w), float(p.h))
		var pos := rect.position
		var along := 0  # the axis along the side
		match side:
			"east":
				pos.x = a.end.x
				along = 1
			"west":
				pos.x = a.position.x - rect.size.x
				along = 1
			"north":
				pos.y = a.position.y - rect.size.y
				along = 0
			"south":
				pos.y = a.end.y
				along = 0
			_:
				continue
		var lo: float = a.position[along]
		var hi: float = a.end[along] - rect.size[along]
		if hi < lo - E:
			continue  # the side is shorter than the ramp
		pos[along] = clampf(pos[along], lo, hi)
		var d := (pos - rect.position).abs()
		if d.x > SNAP_DISTANCE + E or d.y > SNAP_DISTANCE + E:
			continue
		if d.x + d.y < best_d:
			best_d = d.x + d.y
			best = {"rect": Rect2(pos, rect.size), "platform": p}
	return best


static func _holds(outer: Rect2, inner: Rect2) -> bool:
	return inner.position.x >= outer.position.x - E and inner.position.y >= outer.position.y - E \
		and inner.end.x <= outer.end.x + E and inner.end.y <= outer.end.y + E


# ---- Overlaps check_height_data.py refuses ------------------------------------------------------

static func _overlap(a: Rect2, b: Rect2) -> bool:
	return a.position.x < b.end.x - E and b.position.x < a.end.x - E \
		and a.position.y < b.end.y - E and b.position.y < a.end.y - E


static func _rect(d: Dictionary) -> Rect2:
	return Rect2(float(d.x), float(d.y), float(d.w), float(d.h))


## The rooftops `id` stands on, directly or through others (cycle-safe).
static func _ancestors(id: String, by_id: Dictionary) -> Array:
	var seen: Array = []
	var cur := str(by_id[id].get("on", "")) if by_id.has(id) else ""
	while cur != "" and not (cur in seen) and by_id.has(cur):
		seen.append(cur)
		cur = str(by_id[cur].get("on", ""))
	return seen


## The overlap check_height_data.py refuses that involves `item` (a rooftop in data.platforms or a
## ramp in data.ramps, already placed and linked): "" when none, else a short description.
## - Two rooftops may overlap only when one stands on the other ("on", directly or through others).
## - A ramp may overlap only the rooftop at its foot (the highest holding its whole footprint) and
##   what that stands on.
static func overlap_problem(doc: LevelDocument, kind: String, item: Dictionary) -> String:
	var platforms: Array = doc.data.get("platforms", [])
	var by_id := {}
	for p in platforms:
		by_id[str(p.get("id", ""))] = p
	if kind == "rooftop":
		var id := str(item.id)
		for p in platforms:
			if is_same(p, item) or not _overlap(_rect(p), _rect(item)):
				continue
			var pid := str(p.get("id", ""))
			if pid in _ancestors(id, by_id) or id in _ancestors(pid, by_id):
				continue
			return "rooftop %s overlaps rooftop %s" % [id, pid]
		for r in doc.data.get("ramps", []):
			var why := _ramp_problem(r, platforms, by_id, id)
			if why != "":
				return why
	elif kind == "ramp":
		return _ramp_problem(item, platforms, by_id)
	return ""


## The rooftop a ramp overlaps in a way the check refuses (only `only` when given), as text; "".
static func _ramp_problem(ramp: Dictionary, platforms: Array, by_id: Dictionary, only: String = "") -> String:
	var rr := _rect(ramp)
	var target := str(ramp.get("platform", ""))
	var foot_id := ""
	var foot_h := 0.0
	for p in platforms:
		var pid := str(p.get("id", ""))
		if pid == target:
			continue
		if _holds(_rect(p), rr) and float(p.height) > foot_h:
			foot_id = pid
			foot_h = float(p.height)
	var allowed: Array = []
	if foot_id != "":
		allowed = [foot_id] + _ancestors(foot_id, by_id)
	for p in platforms:
		var pid := str(p.get("id", ""))
		if pid == target or pid in allowed or (only != "" and pid != only):
			continue
		if _overlap(rr, _rect(p)):
			return "ramp %s overlaps %s" % [str(ramp.get("id", "")), pid]
	return ""
