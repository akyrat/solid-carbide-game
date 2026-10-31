extends RefCounted
## The car's real height above the ground (task T-183; Drifting, Decisions,
## "Elevation"): a node-free model, separate from the flat top-down driving.
## car.gd steps it once per physics step, after its flat step, with where the
## car was, where it is now and its flat velocity. It never changes the flat
## position or speed itself; car.gd does, when step() reports a wall.
##
## Units are the flat world's (x east, y south); height is in the same units,
## up is positive. The ground comes from a GroundHeight query (ground_height.gd).
## With no ground the height stays 0. The ground's sides (task T-184) can stop
## the move: step() returns the wall for car.gd to bounce off (see _walk).
##
## Every number below is a proposal for the board's playtest (game/docs/level/elevation-test-scene.md,
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
## The car's drawn footprint (task T-411; Drifting, Decisions, 2026-10-07: drawn
## 1 wide and 3 long around its centre, car_flat.json): the points of its
## outline, in units around the centre with the nose along +x. Every point
## meets the sides of raised areas (rooftops, ramps, platforms) like the centre
## does, so the drawn bumper, corners and flanks stop at a side. Falling off an
## edge and landing stay with the centre (the board's choice is open: Drifting,
## Content, "The car's footprint (task T-411)").
const HALF_LENGTH := 1.5
const HALF_WIDTH := 0.5
const OUTLINE: Array[Vector2] = [
	Vector2(1.5, -0.5), Vector2(1.5, 0.0), Vector2(1.5, 0.5),  # the nose
	Vector2(0.5, 0.5), Vector2(-0.5, 0.5),                      # the right flank
	Vector2(-1.5, 0.5), Vector2(-1.5, 0.0), Vector2(-1.5, -0.5), # the tail
	Vector2(-0.5, -0.5), Vector2(0.5, -0.5),                    # the left flank
]

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
## Emitted when hop() lifts the car off the ground (task T-461, the Jump
## power-up), with its takeoff vertical speed. took_off(false, vz) is sent too.
signal hopped(vertical_speed: float)


## Task T-461 (Drifting, Content, "Jump (task T-461)"): lifts the car straight
## up from where it stands with vertical speed vz (units/s, up positive). From
## then on it is in the air like after any takeoff: gravity, landing, the
## ground's sides met at height, the aerial tricks. Only on the ground: in the
## air it does nothing and returns false (no double jump). With no ground
## source the ground is flat at 0 for the hop (see step()).
func hop(vz: float) -> bool:
	if airborne or vz <= 0.0:
		return false
	_take_off(false, vz, height)
	hopped.emit(vz)
	return true


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


## True when `point` lies beyond ramp r's top end (past the edge where it is tallest), T-400.
static func past_top(r: Dictionary, point: Vector2) -> bool:
	var rect: Rect2 = r.rect
	match str(r.side):
		"east":   # the top is at the ramp's west end
			return point.x < rect.position.x
		"west":
			return point.x > rect.end.x
		"south":  # the top is at the ramp's north end
			return point.y < rect.position.y
		"north":
			return point.y > rect.end.y
	return false


## One physics step of dt seconds: the car moved from prev to pos (flat units)
## with flat velocity (units/s).
##
## Returns what the ground's sides did to the move (task T-184), see _walk:
## when "wall" is true the car met the side of a higher area (a drop-off edge
## from below, a ramp's side, or a platform's side while in the air below its
## top) and stopped at "point", the last place along the move outside it; the
## caller moves the flat car there and bounces it off "normal". The height is
## stepped as if the car had moved from prev to that point.
##
## rot_prev and rot_new (radians, the car's heading before and after the step,
## task T-411): given, the whole drawn outline (OUTLINE) meets the sides, and a
## wall also gives "rotation", the heading the car stops at (a turn into a side
## is stopped too). Left out (NAN), only the centre does, as before T-411.
func step(prev: Vector2, pos: Vector2, velocity: Vector2, dt: float,
		rot_prev: float = NAN, rot_new: float = NAN) -> Dictionary:
	if ground == null:
		if airborne:
			# T-461: a hop with no ground source flies over flat ground at 0.
			_step_air(pos, dt)
			return {"wall": false, "rotation": rot_new}
		height = 0.0
		vertical_speed = 0.0
		airborne = false
		return {"wall": false, "rotation": rot_new}
	var walk := _walk(prev, pos, dt, rot_prev, rot_new)
	if walk.wall:
		pos = walk.point
	if airborne:
		_step_air(pos, dt)
		return walk
	# On the ground. Falling off a step down: a drop-off edge, or a ramp's side.
	if walk.drop:
		# T-400: off the open top of a ramp that climbs to no rooftop (the level creator's small
		# jump ramp), climbing fast enough, the car takes off along the slope as at a ramp's top.
		var top: Dictionary = ground.ramp_at(prev)
		if not top.is_empty() and past_top(top, pos) and velocity.length() >= RAMP_TAKEOFF_MIN_SPEED:
			var vz_top := ramp_vertical_speed(top, velocity) * RAMP_TAKEOFF_FACTOR
			if vz_top > 0.0:
				_take_off(true, vz_top, walk.drop_height)
				return walk
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
## The outline (task T-411, rot_prev and rot_new given): each OUTLINE point is
## walked too, the heading turning evenly from rot_prev to rot_new, and meets a
## side by the same rule against its own ground, compared with the car's body
## there: the car's height, along the ramp's slope when the centre is on a ramp
## (so the ramp the car is on is never a wall for its nose or tail). Pieces are
## short enough that no outline point moves more than SAMPLE_STEP in one.
##
## Returns {"wall": bool, "point": Vector2 (where the car stops; pos with no
## wall), "rotation": float (the heading it stops at; rot_new with no wall),
## "normal": Vector2 (the side's outward normal), "area": int (the higher
## area's index, GroundHeight.area_index_at), "wall_height": float (the ground's
## height past the side), "drop": bool, "drop_height": float}.
func _walk(prev: Vector2, pos: Vector2, dt: float, rot_prev: float = NAN, rot_new: float = NAN) -> Dictionary:
	var out := {"wall": false, "point": pos, "rotation": rot_new, "normal": Vector2.ZERO, "area": -1,
		"wall_height": 0.0, "drop": false, "drop_height": 0.0}
	var span := prev.distance_to(pos)
	# The outline, only where a raised area is near enough to touch it this step.
	var near := {}
	var turn := 0.0
	if not is_nan(rot_prev) and not is_nan(rot_new):
		var reach := Vector2(HALF_LENGTH, HALF_WIDTH).length()
		var box := Rect2(prev, Vector2.ZERO).expand(pos).grow(reach + SAMPLE_STEP)
		var found: Dictionary = ground.areas_near(box)
		if not found.ramps.is_empty() or not found.platforms.is_empty():
			near = found
			turn = rot_new - rot_prev
			span += absf(turn) * reach
	var n := maxi(1, ceili(span / SAMPLE_STEP))
	var h0 := height
	var h1 := height + (vertical_speed - GRAVITY * dt) * dt
	var h := height
	var a := prev
	var g_a: float = ground.height_at(prev)
	var rot_a := rot_prev
	var pts_a: Array[Vector2] = []
	var gs_a: Array[float] = []
	if not near.is_empty():
		for o in OUTLINE:
			var p := prev + o.rotated(rot_prev)
			pts_a.append(p)
			gs_a.append(ground.height_among(p, near))
	for i in range(1, n + 1):
		var t := float(i) / float(n)
		var b := prev.lerp(pos, t)
		var g_b: float = ground.height_at(b)
		var h_b := lerpf(h0, h1, t) if airborne else h
		if g_b - g_a > STEP_CLIMB_MAX and g_b > h_b + STEP_CLIMB_MAX:
			var area: int = ground.area_index_at(b)
			out.wall = true
			out.point = a
			out.rotation = rot_a
			out.area = area
			out.normal = ground.side_normal(area, a, b)
			out.wall_height = g_b
			return out
		if not near.is_empty():
			var rot_b := rot_prev + turn * t
			# On a ramp the body lies along its slope; in the air it is level.
			var on_ramp: Dictionary = {} if airborne else ground.ramp_at(b)
			for k in OUTLINE.size():
				var p := b + OUTLINE[k].rotated(rot_b)
				var g_p: float = ground.height_among(p, near)
				var body := h_b
				if not on_ramp.is_empty():
					body += ramp_vertical_speed(on_ramp, p - b)
				if g_p - gs_a[k] > STEP_CLIMB_MAX and g_p > body + STEP_CLIMB_MAX:
					var area: int = ground.area_among(p, near)
					out.wall = true
					out.point = a
					out.rotation = rot_a
					out.area = area
					out.normal = ground.side_normal(area, pts_a[k], p)
					out.wall_height = g_p
					return out
				pts_a[k] = p
				gs_a[k] = g_p
			rot_a = rot_b
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
	var at_ground: float = ground.height_at(pos) if ground != null else 0.0
	if height <= at_ground:
		var impact := vertical_speed
		height = at_ground
		vertical_speed = 0.0
		airborne = false
		landed.emit(impact)
