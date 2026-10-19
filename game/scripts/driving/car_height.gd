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
func step(prev: Vector2, pos: Vector2, velocity: Vector2, dt: float) -> void:
	if ground == null:
		height = 0.0
		vertical_speed = 0.0
		airborne = false
		return
	if airborne:
		_step_air(pos, dt)
		return
	# On the ground. Falling off a drop-off edge (not a ramp, a step down).
	var edge: Dictionary = ground.edge_between(prev, pos)
	if edge.drop and not edge.up:
		_take_off(false, 0.0, height)
		return
	# Leaving the ramp at its top, climbing, fast enough.
	var r: Dictionary = ground.ramp_at(prev)
	if not r.is_empty() and not ground.is_ramp(pos) and velocity.length() >= RAMP_TAKEOFF_MIN_SPEED:
		var vz := ramp_vertical_speed(r, velocity) * RAMP_TAKEOFF_FACTOR
		var at_ground: float = ground.height_at(pos)
		if vz > 0.0 and height + vz * dt > at_ground:
			# Carry on along the slope's line for this step.
			_take_off(true, vz, height + vz * dt)
			return
	# Otherwise the height follows the ground under the car. Driving into a
	# platform side from below is the next task's: here it just snaps.
	height = ground.height_at(pos)
	vertical_speed = 0.0


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
