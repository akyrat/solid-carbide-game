class_name HudLayout
extends RefCounted
## The player's HUD layout (task T-453; HUD and menus, Decisions, "The player can move the HUD's
## pieces"): where each movable HUD piece goes, kept relative to the screen so it holds at any
## window size and HUD size (T-431). No nodes, so tests run it directly.
##
## A moved piece is stored as an entry {ax, ay, dx, dy} in the HUD's layout pixels (the scaled
## area, `Hud.root`): ax and ay are the piece's anchor across the area (0 the left or top edge,
## 0.5 the centre, 1 the right or bottom edge), picked from the third of the area its centre is
## in when it is dropped, and dx, dy its distance from that anchor. Its place in an area of
## `area` layout pixels is ax * (area - size) + d, clamped so the piece stays fully on screen.
## A piece at the bottom right keeps its margins to that corner at any window size, a piece at
## the centre stays centred. Pieces that were never moved keep their own default anchoring.
##
## Snapping (a proposal for the playtest): a dragged piece snaps to a GRID of 4 layout pixels,
## and to the HUD's usual 16 pixel margin from an edge when it comes within EDGE_SNAP of it.

## The movable pieces, in the order the editor lists them.
const PIECES: Array[String] = ["hearts", "weapon_icons", "coins", "clock", "sub_goal", "viewers"]
const GRID := 4.0
const EDGE_MARGIN := 16.0
const EDGE_SNAP := 12.0


## Whether `v` is a stored entry this version can use.
static func valid_entry(v: Variant) -> bool:
	if not (v is Dictionary):
		return false
	for k in ["ax", "ay", "dx", "dy"]:
		if not v.has(k) or not (v[k] is float or v[k] is int):
			return false
	return float(v.ax) >= 0.0 and float(v.ax) <= 1.0 and float(v.ay) >= 0.0 and float(v.ay) <= 1.0


## Only the valid entries of known pieces, as floats.
static func clean(layout: Variant) -> Dictionary:
	var out := {}
	if not (layout is Dictionary):
		return out
	for id in PIECES:
		var e = layout.get(id)
		if valid_entry(e):
			out[id] = {"ax": float(e.ax), "ay": float(e.ay), "dx": float(e.dx), "dy": float(e.dy)}
	return out


## The anchor (0, 0.5 or 1) for a piece spanning `from` to `from + length` along an area `area` long.
static func anchor_for(from: float, length: float, area: float) -> float:
	var centre := from + length / 2.0
	if centre < area / 3.0:
		return 0.0
	if centre > area * 2.0 / 3.0:
		return 1.0
	return 0.5


## The entry for a piece of `size` dropped at `pos` (its top left) in an area of `area`.
static func entry_for(pos: Vector2, size: Vector2, area: Vector2) -> Dictionary:
	var ax := anchor_for(pos.x, size.x, area.x)
	var ay := anchor_for(pos.y, size.y, area.y)
	return {"ax": ax, "ay": ay,
		"dx": pos.x - ax * (area.x - size.x), "dy": pos.y - ay * (area.y - size.y)}


## The top left of a piece of `size` placed by `entry` in an area of `area`, fully inside it.
static func position_for(entry: Dictionary, size: Vector2, area: Vector2) -> Vector2:
	var p := Vector2(
		float(entry.ax) * (area.x - size.x) + float(entry.dx),
		float(entry.ay) * (area.y - size.y) + float(entry.dy))
	return clamp_inside(p, size, area)


## `pos` moved just enough to keep a piece of `size` fully inside the area.
static func clamp_inside(pos: Vector2, size: Vector2, area: Vector2) -> Vector2:
	return Vector2(
		clampf(pos.x, 0.0, maxf(area.x - size.x, 0.0)),
		clampf(pos.y, 0.0, maxf(area.y - size.y, 0.0)))


## Where a piece of `size` dragged to `pos` lands: on the grid, at the edge margin when near an
## edge, and fully inside the area.
static func snap(pos: Vector2, size: Vector2, area: Vector2) -> Vector2:
	var p := (pos / GRID).round() * GRID
	p.x = _snap_axis(p.x, pos.x, size.x, area.x)
	p.y = _snap_axis(p.y, pos.y, size.y, area.y)
	return clamp_inside(p, size, area)


static func _snap_axis(gridded: float, raw: float, length: float, area: float) -> float:
	var near := EDGE_MARGIN
	var far := area - length - EDGE_MARGIN
	if absf(raw - near) <= EDGE_SNAP:
		return near
	if absf(raw - far) <= EDGE_SNAP:
		return far
	return gridded
