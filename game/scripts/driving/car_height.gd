extends RefCounted
## The car's real height above the ground (task T-183; Drifting, Decisions,
## "Elevation"): a node-free model, separate from the flat top-down driving.
## car.gd steps it once per physics step, after its flat step, with where the
## car was, where it is now and its flat velocity. It never changes the flat
## position or speed.
##
## Units are the flat world's (x east, y south); height is in the same units,
## up is positive. The ground comes from a GroundHeight query (ground_height.gd).
## With no ground the height stays 0.
##
## Every number below is a proposal for the board's playtest (game/README.md,
## "Elevation test scene", "The car's height").

## Gravity in the air, units/s^2 (proposal).
const GRAVITY := 12.0
## The slowest flat speed, units/s, at which the car leaves the ground at the
## ramp's top (proposal). Slower, it just follows the ground onto the platform.
## Going off a drop-off edge the car always falls: nothing holds it up there.
const RAMP_TAKEOFF_MIN_SPEED := 4.0
## Share of the ramp's vertical speed the car keeps when it takes off (proposal;
## 1 = it carries on exactly along the ramp's slope).
const RAMP_TAKEOFF_FACTOR := 1.0
## The biggest step of the ground, units, the car drives over like a curb
## (proposal, task T-184). A step up higher than this, to more than this above
## the car, is a wall: a drop-off edge met from below, a ramp's side, or a
## platform's side met in the air below its top. A step down higher than this
## is a drop: the car leaves the ground and falls. A ramp's slope is never a
## step (it rises SAMPLE_STEP x slope per piece).
const STEP_CLIMB_MAX := 0.1
## Length of the pieces a move is walked in, units (as GroundHeight.SAMPLE_STEP).
const SAMPLE_STEP := 0.05

## Height above y = 0 ground, units.
var height := 0.0
## Vertical speed, units/s, up positive. 0 on the ground.
var vertical_speed := 0.0
## True from takeoff (or falling off an edge) until landing.
var airborne := false
## The GroundHeight query, or null (no elevation: height stays 0).
var ground = null

## Emitted when the car leaves the ground. from_ramp is true at the ramp's top,
## false when it falls off a drop-off edge.
signal took_off(from_ramp: bool, vertical_speed: float)
## Emitted when the car lands, with its vertical speed just before landing.
signal landed(impact_vertical_speed: float)


## Puts the car on the ground at point (for a reset or a teleport).
func reset(point: Vector2) -> void:
	airborne = false
	vertical_speed = 0.0
	height = ground.height_at(point) if ground != null else 0.0


## The ramp's vertical speed for a car moving with flat velocity on ramp r:
## velocity . climb direction x (top_height - bottom_height) / ramp length.
## Positive climbing, negative going down.
static func ramp_vertical_speed(r: Dictionary, velocity: Vector2) -> float:
	var rect: Rect2 = r.rect
	var rise: float = float(r.top_height) - float(r.bottom_height)
	var dir := Vector2.ZERO
	var length := 1.0
	match str(r.side):
		"east":   # the top is at the ramp's west end
			dir = Vector2.LEFT
			length = rect.size.x
		"west":
			dir = Vector2.RIGHT
			length = rect.size.x
		"south":  # the top is at the ramp's north end
			dir = Vector2.UP
			length = rect.size.y
		"north":
			dir = Vector2.DOWN
			length = rect.size.y
	return velocity.dot(dir) * rise / maxf(0.0001, length)


## One physics step of dt seconds: the car moved from prev to pos (flat units)
## with flat velocity (units/s).
##
## Returns what the ground's sides did to the move (task T-184), see _walk:
## when "wall" is true the car met the side of a higher area (a drop-off edge
## from below, a ramp's side, or a platform's side while in the air below its
## top) and stopped at "point", the last place along the move outside it; the
## caller moves the flat car there and bounces it off "normal". The height is
## stepped as if the car had moved from prev to that point.
func step(prev: Vector2, pos: Vector2, velocity: Vector2, dt: float) -> Dictionary:
	if ground == null:
		height = 0.0
		vertical_speed = 0.0
		airborne = false
		return {"wall": false}
	var walk := _walk(prev, pos, dt)
	if walk.wall:
		pos = walk.point
	if airborne:
		_step_air(pos, dt)
		return walk
	# On the ground. Falling off a step down: a drop-off edge, or a ramp's side.
	if walk.drop:
		_take_off(false, 0.0, walk.drop_height)
		return walk
	# Leaving the ramp at its top, climbing, fast enough.
	var r: Dictionary = ground.ramp_at(prev)
	if not r.is_empty() and not ground.is_ramp(pos) and velocity.length() >= RAMP_TAKEOFF_MIN_SPEED:
		var vz := ramp_vertical_speed(r, velocity) * RAMP_TAKEOFF_FACTOR
		var at_ground: float = ground.height_at(pos)
		if vz > 0.0 and height + vz * dt > at_ground:
			# Carry on along the slope's line for this step.
			_take_off(true, vz, height + vz * dt)
			return walk
	# Otherwise the height follows the ground under the car (a step up higher
	# than STEP_CLIMB_MAX was a wall, so this is a slope or a curb).
	height = ground.height_at(pos)
	vertical_speed = 0.0
	return walk


## Walks the move from prev to pos in SAMPLE_STEP pieces, with the car's height
## along it: in the air, the straight line from this step's start height to its
## end height under gravity; on the ground, the ground's height, held where it
## steps down (the car leaves the ground there).
##
## A wall: a piece that steps the ground up by more than STEP_CLIMB_MAX (a side,
## not a slope) to a height more than STEP_CLIMB_MAX above the car. The walk
## stops there. A drop (on the ground only): the first piece that steps the
## ground down by more than STEP_CLIMB_MAX; drop_height is the car's height
## just before it.
##
## Returns {"wall": bool, "point": Vector2 (where the car stops; pos with no
## wall), "normal": Vector2 (the side's outward normal), "area": int (the higher
## area's index, GroundHeight.area_index_at), "wall_height": float (the ground's
## height past the side), "drop": bool, "drop_height": float}.
func _walk(prev: Vector2, pos: Vector2, dt: float) -> Dictionary:
	var out := {"wall": false, "point": pos, "normal": Vector2.ZERO, "area": -1,
		"wall_height": 0.0, "drop": false, "drop_height": 0.0}
	var n := maxi(1, ceili(prev.distance_to(pos) / SAMPLE_STEP))
	var h0 := height
	var h1 := height + (vertical_speed - GRAVITY * dt) * dt
	var h := height
	var a := prev
	var g_a: float = ground.height_at(prev)
	for i in range(1, n + 1):
		var t := float(i) / float(n)
		var b := prev.lerp(pos, t)
		var g_b: float = ground.height_at(b)
		var h_b := lerpf(h0, h1, t) if airborne else h
		if g_b - g_a > STEP_CLIMB_MAX and g_b > h_b + STEP_CLIMB_MAX:
			var area: int = ground.area_index_at(b)
			out.wall = true
			out.point = a
			out.area = area
			out.normal = ground.side_normal(area, a, b)
			out.wall_height = g_b
			return out
		if not airborne and not out.drop:
			if g_b < h - STEP_CLIMB_MAX:
				out.drop = true
				out.drop_height = h
			else:
				h = g_b
		a = b
		g_a = g_b
	return out


func _take_off(from_ramp: bool, vz: float, new_height: float) -> void:
	airborne = true
	vertical_speed = vz
	height = new_height
	took_off.emit(from_ramp, vz)


## Gravity, then the height follows the vertical speed (semi-implicit Euler);
## lands when the height reaches the ground under the car.
func _step_air(pos: Vector2, dt: float) -> void:
	vertical_speed -= GRAVITY * dt
	height += vertical_speed * dt
	var at_ground: float = ground.height_at(pos)
	if height <= at_ground:
		var impact := vertical_speed
		height = at_ground
		vertical_speed = 0.0
		airborne = false
		landed.emit(impact)
