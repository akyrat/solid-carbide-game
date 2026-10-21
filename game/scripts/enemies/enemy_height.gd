extends RefCounted
## Enemies on the ground's heights (task T-207; Enemies, Decisions, "Enemies
## follow the car up the ramps"): the rules every enemy that chases the car
## shares on a map with rooftops and ramps (ground_height.gd, a GroundHeight).
##
## - An enemy stands on the ground under its centre: its height is
##   ground.height_at(centre). It has no jump and no fall.
## - A rooftop's edge is a wall, from below and from above: a move whose
##   ground height changes by more than MAX_STEP units is refused, so an enemy
##   only changes level along a ramp (the ground there rises gradually). The
##   sides of a ramp are walls too, except near its foot where it is still low.
## - The body must fit where it goes: the ground under the edge of its circle
##   (four points `radius` from the centre) may differ from the ground under
##   its centre by MAX_STEP at most, so the body keeps off an edge instead of
##   hanging over it.
## - Contact damage only reaches the car at its level: the car's height
##   (in the air included) within LEVEL_TOLERANCE units of the enemy's ground.
##
## With no ground (the MVP map, ground null) every move is allowed and the
## height is 0, so nothing changes there.

## The largest change of ground height a move may make, units. A ramp rises
## 3 units over 12 (0.25 a unit), far under it; every edge is 3 units or more.
const MAX_STEP := 0.6
## A move is checked in pieces this long at most (units), so a big push
## (a weapon's knockback) cannot jump over an edge.
const SUB_STEP := 0.25
## How far (units) the car's height may be from the enemy's ground for its
## contact damage to hit (a proposal for the playtest).
const LEVEL_TOLERANCE := 1.0

const _PROBES := [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]


## The ground height under `units` (0 with no ground).
static func height_at(ground, units: Vector2) -> float:
	if ground == null:
		return 0.0
	return ground.height_at(units)


## True when a body of `radius` units fits at `units`: the ground under its
## circle's edge (four points) is within MAX_STEP of the ground under its centre.
static func fits(ground, units: Vector2, radius: float) -> bool:
	if ground == null:
		return true
	var h: float = ground.height_at(units)
	for o in _PROBES:
		if absf(ground.height_at(units + o * radius) - h) > MAX_STEP:
			return false
	return true


## True when a body of `radius` may move straight from `a` to `b` (a short
## move, SUB_STEP or less): the ground under its centre changes by MAX_STEP at
## most and it fits at `b`. A body that does not fit where it is (pushed half
## over an edge before T-207's rules, or placed there by a test) is held to
## the centre's rule only, so it can still walk away.
static func can_step(ground, a: Vector2, b: Vector2, radius: float) -> bool:
	if ground == null:
		return true
	if absf(ground.height_at(b) - ground.height_at(a)) > MAX_STEP:
		return false
	if fits(ground, b, radius):
		return true
	return not fits(ground, a, radius)


## Limits a move of `motion` units from `from` for a body of `radius` by the
## ground's edges. Returns {"segments": Array of Vector2 moves to make one
## after the other (at most two: straight up to the edge, then sliding along
## it), "normal": the edge's normal against the move (Vector2.ZERO when
## nothing stopped it)}. Every edge on the map runs north-south or east-west,
## so sliding keeps the free axis of the move.
static func limit_motion(ground, from: Vector2, motion: Vector2, radius: float) -> Dictionary:
	if ground == null or motion.length() < 0.000001:
		return {"segments": [motion], "normal": Vector2.ZERO}
	var n := maxi(1, ceili(motion.length() / SUB_STEP))
	var piece := motion / float(n)
	var at := from
	var done := 0
	while done < n and can_step(ground, at, at + piece, radius):
		at += piece
		done += 1
	if done == n:
		return {"segments": [motion], "normal": Vector2.ZERO}
	var straight := at - from
	var rest := piece * float(n - done)
	var slide := Vector2.ZERO
	var normal := Vector2.ZERO
	var x_only := Vector2(piece.x, 0.0)
	var y_only := Vector2(0.0, piece.y)
	if absf(piece.x) > 0.000001 and can_step(ground, at, at + x_only, radius):
		normal = Vector2(0.0, -signf(piece.y))
		slide = _slide(ground, at, Vector2(rest.x, 0.0), radius)
	elif absf(piece.y) > 0.000001 and can_step(ground, at, at + y_only, radius):
		normal = Vector2(-signf(piece.x), 0.0)
		slide = _slide(ground, at, Vector2(0.0, rest.y), radius)
	else:
		normal = -motion.normalized()
	return {"segments": [straight, slide], "normal": normal}


## How far a body can slide from `from` along `motion` (one axis) before an edge stops it.
static func _slide(ground, from: Vector2, motion: Vector2, radius: float) -> Vector2:
	var n := maxi(1, ceili(motion.length() / SUB_STEP))
	var piece := motion / float(n)
	var at := from
	for _i in n:
		if not can_step(ground, at, at + piece, radius):
			break
		at += piece
	return at - from


## True when a car at `car_height` (units, its own height, in the air
## included) is at the level of an enemy standing on ground `enemy_ground`.
static func at_car_level(enemy_ground: float, car_height: float) -> bool:
	return absf(car_height - enemy_ground) <= LEVEL_TOLERANCE


## The car's height (units): car.height on a map with heights, else 0.
static func car_height(car: Node) -> float:
	if car == null:
		return 0.0
	var h = car.get("height")
	return float(h) if h != null else 0.0
