class_name RailPiece
extends RefCounted
## The rail piece of the level creator (task T-542; Level design, Content, "Rails in the level
## creator (task T-542)"; the file format is Rails, game/scripts/level/rails.gd). Plain helpers, no
## scene tree: an item is the level file's own entry {id, x1, y1, z1, x2, y2, z2} (map units).
## Every number here is a proposal for the board's playtest.

const Rails := preload("res://scripts/level/rails.gd")
const MvpMapScript := preload("res://scripts/level/mvp_map.gd")

## The ends of a rail snap to this grid, units.
const SNAP := 0.5
## A click without a drag lays a rail this long, units, in the picked direction.
const DEFAULT_LENGTH := 12.0
## The direction steps of R, degrees (0 east, then clockwise on the map: x east, y south).
const TURN_STEP_DEG := 45.0
## "[" and "]" shorten and lengthen the selected rail by this, units.
const LENGTH_STEP := 1.0
## Auto height: a rail over the street is at this height (the jump pair's, Rails format); over a
## rooftop or ramp it is the surface's height plus RAIL_LIFT (a car leaving that edge is caught).
const STREET_HEIGHT := 1.0
const RAIL_LIFT := 0.1
## The picked heights besides auto, the family members' "height" (units).
const AUTO := "auto"
## Mouse: an end's handle is grabbed within this many screen pixels, the bar within BODY_PX.
const HANDLE_PX := 12.0
const BODY_PX := 8.0


## A level file entry.
static func make_item(id: String, a: Vector2, b: Vector2, za: float, zb: float) -> Dictionary:
	return {"id": id, "x1": a.x, "y1": a.y, "z1": za, "x2": b.x, "y2": b.y, "z2": zb}


static func end_a(item: Dictionary) -> Vector2:
	return Vector2(float(item.x1), float(item.y1))


static func end_b(item: Dictionary) -> Vector2:
	return Vector2(float(item.x2), float(item.y2))


static func height_a(item: Dictionary) -> float:
	return float(item.z1)


## z2 may be left out of a file entry: then it is z1.
static func height_b(item: Dictionary) -> float:
	return float(item.get("z2", item.z1))


static func length_of(item: Dictionary) -> float:
	return end_a(item).distance_to(end_b(item))


static func snap(v: Vector2) -> Vector2:
	return Vector2(snappedf(v.x, SNAP), snappedf(v.y, SNAP))


## The direction of step `turn` (0..7), a unit vector.
static func direction_of(turn: int) -> Vector2:
	var t := deg_to_rad(TURN_STEP_DEG * float(turn))
	return Vector2(cos(t), sin(t))


## The direction of the rail in degrees from east, 0 up to 360.
static func angle_deg(item: Dictionary) -> float:
	var d := end_b(item) - end_a(item)
	return fposmod(rad_to_deg(atan2(d.y, d.x)), 360.0)


## The auto height over a surface of height `ground`.
static func auto_height(ground: float) -> float:
	return STREET_HEIGHT if ground <= 0.0 else ground + RAIL_LIFT


## The screen pixel (map pixels) of a point of the map at a height.
static func px_of(u: Vector2, h: float) -> Vector2:
	return MvpMapScript.ISO_TRANSFORM * (u * MvpMapScript.PX_PER_UNIT) - Vector2(0.0, h * MvpMapScript.PX_PER_UNIT)


## The map point (units) under map pixel `px` when the point is at height `h`.
static func ground_for(px: Vector2, h: float) -> Vector2:
	return MvpMapScript.ISO_TRANSFORM.affine_inverse() * (px + Vector2(0.0, h * MvpMapScript.PX_PER_UNIT)) / MvpMapScript.PX_PER_UNIT


## The distance in map pixels from `px` to the drawn bar of `item`.
static func distance_px(item: Dictionary, px: Vector2) -> float:
	var a := px_of(end_a(item), height_a(item))
	var b := px_of(end_b(item), height_b(item))
	var closest := Geometry2D.get_closest_point_to_segment(px, a, b)
	return px.distance_to(closest)


## Which part of `item` is under `px`: "a" or "b" (an end, within `handle_px`), "body" (within
## `body_px` of the bar), "" for none. Ends are tested first.
static func part_at(item: Dictionary, px: Vector2, handle_px: float, body_px: float) -> String:
	if px.distance_to(px_of(end_a(item), height_a(item))) <= handle_px:
		return "a"
	if px.distance_to(px_of(end_b(item), height_b(item))) <= handle_px:
		return "b"
	return "body" if distance_px(item, px) <= body_px else ""


## `item`'s new ends after turning it by `steps` of TURN_STEP_DEG round its middle, snapped.
static func turned_ends(item: Dictionary, steps: int) -> Array:
	var a := end_a(item)
	var b := end_b(item)
	var mid := (a + b) / 2.0
	var t := deg_to_rad(TURN_STEP_DEG * float(steps))
	return [snap(mid + (a - mid).rotated(t)), snap(mid + (b - mid).rotated(t))]


## The end b after lengthening by `delta` units along the rail (shortening when negative), snapped.
## The rail is never made shorter than the game takes (Rails.MIN_LENGTH).
static func resized_b(item: Dictionary, delta: float) -> Vector2:
	var a := end_a(item)
	var d := end_b(item) - a
	var len := maxf(d.length() + delta, Rails.MIN_LENGTH)
	return snap(a + d.normalized() * len)
