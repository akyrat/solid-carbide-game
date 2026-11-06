extends RefCounted
## Rail grinding (task T-541, a prototype; Drifting, Decisions, "Rail grinding, a prototype";
## how it behaves and every proposed number: Drifting, Content, "Rail grinding (task T-541)").
## Built from the trick prototype's wall grind (hold/trick-prototype, trick_grind.gd), on the
## car's real height (car_height.gd) and the map's rails (scripts/level/rails.gd).
##
## The car (car.gd) owns one, `car.grind`, and the run gives it the map's rails (`rails`).
##  - find(pos, vel, height, vz, exclude): after each step in the air, the rail the car catches:
##    its centre within REACH of the rail's line (square to it) and no more than END_MARGIN past
##    an end, falling or level (vz <= 0) with its height within CATCH_BELOW under to CATCH_ABOVE
##    over the bar, and moving roughly along it: its flat speed along the rail at least
##    MIN_START_SPEED and its direction within MAX_ANGLE_DEG of the rail's line (either way).
##    A landing across a rail doesn't catch it. The nearest rail wins.
##  - start(info, heading): locks on. The car sits on the bar, across it at ANGLE_DEG, the nose
##    leaning the way it travels, on the side its nose pointed (A or D held swing it to that side,
##    set_steer()). Only the speed along the rail is kept.
##  - step(dt): slides on along the rail, losing DECEL units/s every second, and returns "end"
##    past the rail's end or "slow" below END_SPEED ("" while it goes on).
##  - stop(reason): ends it ("end", "slow", "jump"), sending grind_ended with its seconds and
##    length, which the run pays as the GRIND! trick. leave_velocity(reason) is the car's flat
##    velocity as it leaves: along the rail, plus a sideways push for a jump (JUMP_SIDE_SPEED)
##    or a slow drop (DROP_SIDE_SPEED), toward the side the nose points.
## The rail it left can't be caught again until the car touches the ground or another rail
## (`exclude`, cleared by touched_ground()), so a jump off a rail never lands back on it.
## Node-free: tests drive it directly.

const Rails := preload("res://scripts/level/rails.gd")

## All numbers are proposals for the board's playtest (Drifting, Content, "Rail grinding (task
## T-541)").
## How far the car's centre may be from the rail's line, units (the car is 1 wide: its side
## within half a unit of the bar). The old wall grind's reach was 2 (loosened by the board).
const REACH := 1.0
## How far past a rail's end a landing still catches it, units (the grind starts at that end).
const END_MARGIN := 0.5
## The car's height may be this far over the bar (units) when it catches it...
const CATCH_ABOVE := 0.25
## ...or this far under it: a step of a fall moves up to about 0.3 units, so the bar is never
## stepped through.
const CATCH_BELOW := 0.5
## The least flat speed along the rail that catches it, units/s.
const MIN_START_SPEED := 2.0
## The widest angle between the car's flat direction and the rail that still catches it, degrees.
const MAX_ANGLE_DEG := 45.0
## How fast the grind burns the speed, units/s every second (the wall grind's was 4: rails are
## for travelling, so they keep the speed longer).
const DECEL := 1.0
## Below this speed along the rail the car drops off, units/s.
const END_SPEED := 2.0
## The car's angle to the rail while it grinds, degrees (as the wall grind).
const ANGLE_DEG := 70.0
## Jump off a rail: the sideways speed the hop adds, units/s, toward the side the nose points
## (A or D held: that side). With Jump tier 1 (takeoff 5 units/s, about 0.83 s in the air) it
## carries the car about 3.3 units sideways: rails up to 3.5 units apart, at the same height.
const JUMP_SIDE_SPEED := 4.0
## A grind that ends too slow drops the car off beside the rail at this sideways speed, units/s.
const DROP_SIDE_SPEED := 2.0

## Sent when a grind starts, with the rail's index in `rails`.
signal grind_started(rail_index: int)
## Sent when a grind ends: why ("end", "slow" or "jump"), its seconds and its length (units).
signal grind_ended(reason: String, seconds: float, length: float)

## The map's rails (Rails.from_layout).
var rails: Array = []
## True while grinding.
var active := false
## The rail of the current (or last) grind, and its index in `rails`.
var rail := {}
var rail_index := -1
## The car's distance along the rail from its end a (units), its speed (>= 0, units/s) and its
## direction along the rail (+1 toward end b, -1 toward end a).
var s := 0.0
var speed := 0.0
var direction := 1.0
## The side the nose points across the rail (unit vector, flat world).
var across := Vector2.UP
## The current grind's seconds and length so far.
var seconds := 0.0
var length := 0.0
## The rail that can't be caught (the one just left), -1 for none.
var exclude := -1
## Grinds started so far (tests, readouts).
var grinds := 0


## The rail the car catches at `pos` (units) with flat velocity `vel` (units/s), at `height`
## falling at `vz` (units/s, up positive), or {}: {"index", "s", "speed_along"}.
func find(pos: Vector2, vel: Vector2, height: float, vz: float) -> Dictionary:
	if vz > 0.0:
		return {}
	var flat := vel.length()
	if flat < MIN_START_SPEED:
		return {}
	var cos_max := cos(deg_to_rad(MAX_ANGLE_DEG))
	var best := {}
	var best_gap := INF
	for i in rails.size():
		if i == exclude:
			continue
		var r: Dictionary = rails[i]
		var at := Rails.along(r, pos)
		if at < -END_MARGIN or at > float(r.length) + END_MARGIN:
			continue
		var gap := Rails.side_distance(r, pos)
		if gap > REACH or gap >= best_gap:
			continue
		at = clampf(at, 0.0, float(r.length))
		var bar := Rails.height_at(r, at)
		if height > bar + CATCH_ABOVE or height < bar - CATCH_BELOW:
			continue
		var v: float = vel.dot(r.dir)
		if absf(v) < MIN_START_SPEED or absf(v) < flat * cos_max - 1e-9:
			continue
		best = {"index": i, "s": at, "speed_along": v}
		best_gap = gap
	return best


## Locks onto info's rail (from find()); heading is the car's heading (radians) as it lands.
func start(info: Dictionary, heading: float) -> void:
	rail_index = int(info.index)
	rail = rails[rail_index]
	s = float(info.s)
	direction = signf(float(info.speed_along))
	speed = absf(float(info.speed_along))
	var left := travel().rotated(-PI / 2.0)
	across = left if Vector2(cos(heading), sin(heading)).dot(left) >= 0.0 else -left
	seconds = 0.0
	length = 0.0
	exclude = -1
	active = true
	grinds += 1
	grind_started.emit(rail_index)


## A or D while grinding (steer > 0: A, left; < 0: D, right): the nose swings to that side of
## the rail, and a jump goes that way. 0 changes nothing. The car never leaves the rail.
func set_steer(steer: float) -> void:
	if not active or steer == 0.0:
		return
	var left := travel().rotated(-PI / 2.0)
	across = left if steer > 0.0 else -left


## Slides on by dt: "" while it goes on, "end" once past the rail's end, "slow" below END_SPEED.
func step(dt: float) -> String:
	if not active:
		return ""
	speed = maxf(0.0, speed - DECEL * dt)
	var moved := speed * dt
	s += direction * moved
	seconds += dt
	length += moved
	if (direction > 0.0 and s > float(rail.length)) or (direction < 0.0 and s < 0.0):
		return "end"
	if speed < END_SPEED:
		return "slow"
	return ""


## Ends the grind: the rail can't be caught again until the ground (or another rail).
func stop(reason: String) -> void:
	if not active:
		return
	active = false
	exclude = rail_index
	grind_ended.emit(reason, seconds, length)


## The car touched the ground: every rail can be caught again.
func touched_ground() -> void:
	if not active:
		exclude = -1


## The way the car travels along the rail (unit vector, flat).
func travel() -> Vector2:
	if rail.is_empty():
		return Vector2.RIGHT
	return rail.dir * direction


## The car's centre now: on the bar (units, flat; held at the rail's ends).
func position_units() -> Vector2:
	return Rails.point_at(rail, clampf(s, 0.0, float(rail.length)))


## The bar's height under the car (units).
func height() -> float:
	return Rails.height_at(rail, s)


## The car's flat velocity while grinding (units/s).
func velocity() -> Vector2:
	return travel() * speed


## The car's heading while grinding: across the rail, ANGLE_DEG to it, the nose leaning the way
## it travels, on the `across` side.
func heading() -> float:
	var a := deg_to_rad(ANGLE_DEG)
	var d := travel() * cos(a) + across * sin(a)
	return atan2(d.y, d.x)


## The heading as the car leaves: along the rail, the way it travelled.
func exit_heading() -> float:
	var t := travel()
	return atan2(t.y, t.x)


## The car's flat velocity as it leaves for `reason` (units/s): along the rail at its speed, plus
## JUMP_SIDE_SPEED ("jump") or DROP_SIDE_SPEED ("slow") toward the nose's side.
func leave_velocity(reason: String) -> Vector2:
	var v := velocity()
	match reason:
		"jump":
			v += across * JUMP_SIDE_SPEED
		"slow":
			v += across * DROP_SIDE_SPEED
	return v
