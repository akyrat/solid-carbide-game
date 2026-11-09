extends Node2D
## The Polarized Steering Wheel's ground arrows (task T-603; Drifting, Decisions, "The
## Polarized Steering Wheel bursts after an alternate drift"). When the wheel's burst
## fires (car.polarized.fired), two arrows are drawn on the ground, one on each side of
## the car, pointing along the direction of travel at the payout (the way the burst
## pushes), and fade out. Drawn in code (no PixelLab), flat on the ground through
## `view_transform` (the iso projection in a run), under the car: boost_effect.gd makes
## this node its child, so it sits where the boost lines sit (before the car's sprite,
## lifted with the ground on rooftops).
##
## The arrows follow the car (they stay at its sides while it moves on); their direction
## stays the one of the payout. Every number below is a proposal for the playtest.

const PX_PER_UNIT := 16.0
## The wheel's colours (the icon's hub: tools/draw_power_up_icon_polarized_steering_wheel.py).
const CYAN := Color8(42, 213, 239)
const CYAN_DARK := Color8(30, 140, 180)
const MAGENTA := Color8(220, 70, 200)
const MAGENTA_DARK := Color8(110, 34, 104)

## Seconds an arrow pair shows: the burst's hold (0.5 s).
@export var life_seconds := 0.5
## Seconds at full strength before the fade starts.
@export var full_seconds := 0.1
## Arrow length, tail to tip, in units (1 unit = the car's width; the car is drawn
## about 3 units long, so each arrow runs about two thirds of the car's side).
@export var length_units := 2.0
## The shaft's width and the head's length and width, units.
@export var shaft_units := 0.24
@export var head_length_units := 0.6
@export var head_width_units := 0.7
## How far each arrow's centre line is from the car's centre, units, across the travel.
@export var side_units := 1.2
## How far the arrows slide on along the travel over their life, units (reads as the push).
@export var slide_units := 0.5

var view_transform := Transform2D.IDENTITY:
	set(value):
		view_transform = value
		queue_redraw()
## Seconds since this node started (advances in advance()).
var time := 0.0
## Arrow pairs made so far (tests).
var pairs_made := 0
## Pairs now: {position: Vector2 (units), direction: Vector2 (unit), born: float, car}.
var _pairs: Array = []


## Shows a pair each time the car's Polarized Steering Wheel fires.
func bind(car: Node) -> void:
	var wheel = car.get("polarized")
	if wheel == null:
		return
	wheel.fired.connect(func(_speed: float, _seconds: float, direction: Vector2) -> void:
		play(car.model.get_position(), direction)
		_pairs[-1]["car"] = car)


## Starts a pair at a place (units) pointing along `direction` (flat world).
func play(position_units: Vector2, direction: Vector2) -> void:
	var d := direction.normalized() if direction.length() > 1e-6 else Vector2.RIGHT
	_pairs.append({"position": position_units, "direction": d, "born": time})
	pairs_made += 1
	queue_redraw()


func clear() -> void:
	_pairs.clear()
	queue_redraw()


func advance(delta: float) -> void:
	time += delta
	var keep: Array = []
	for p in _pairs:
		if time - float(p.born) < life_seconds:
			keep.append(p)
	_pairs = keep
	queue_redraw()


func _process(delta: float) -> void:
	if not _pairs.is_empty():
		advance(delta)
	else:
		time += delta


## Pairs showing now.
func pair_count() -> int:
	return _pairs.size()


## The strength (alpha) of a pair at `age` seconds: 1 for full_seconds, then a straight
## line to 0 at life_seconds.
func alpha_at(age: float) -> float:
	if age < 0.0 or age >= life_seconds:
		return 0.0
	if age <= full_seconds:
		return 1.0
	return clampf(1.0 - (age - full_seconds) / maxf(life_seconds - full_seconds, 1e-6), 0.0, 1.0)


## What is drawn now, for tests and _draw: one entry per arrow,
## {side: -1 left of the travel / +1 right, tail and tip (flat world, units),
## direction (flat world, unit), alpha, fill, edge, points (view px, the outline)}.
func drawn() -> Array:
	var out: Array = []
	for p in _pairs:
		var age: float = time - float(p.born)
		var a := alpha_at(age)
		if a <= 0.0:
			continue
		var centre: Vector2 = p.position
		var car: Variant = p.get("car")
		if car != null and is_instance_valid(car):
			centre = car.model.get_position()
		var d: Vector2 = p.direction
		var across := Vector2(-d.y, d.x)  # +1 side: to the right of the travel on a y-down screen
		var slide := d * slide_units * clampf(age / maxf(life_seconds, 1e-6), 0.0, 1.0)
		for side in [-1, 1]:
			var mid: Vector2 = centre + across * side_units * float(side) + slide
			var tail := mid - d * length_units * 0.5
			var tip := mid + d * length_units * 0.5
			var fill := CYAN if side < 0 else MAGENTA
			var edge := CYAN_DARK if side < 0 else MAGENTA_DARK
			out.append({"side": side, "tail": tail, "tip": tip, "direction": d, "alpha": a,
				"fill": Color(fill, a), "edge": Color(edge, a), "points": _outline(tail, tip, d, across)})
	return out


## The arrow's outline in view pixels: a shaft and a head, flat on the ground.
func _outline(tail: Vector2, tip: Vector2, d: Vector2, across: Vector2) -> PackedVector2Array:
	var neck := tip - d * head_length_units
	var hs := across * shaft_units * 0.5
	var hh := across * head_width_units * 0.5
	var world := [tail - hs, neck - hs, neck - hh, tip, neck + hh, neck + hs, tail + hs]
	var pts := PackedVector2Array()
	for w in world:
		pts.append(view_transform * (w * PX_PER_UNIT))
	return pts


func _draw() -> void:
	for a in drawn():
		var pts: PackedVector2Array = a.points
		draw_colored_polygon(pts, a.fill)
		var loop := pts.duplicate()
		loop.append(pts[0])
		draw_polyline(loop, a.edge, 1.0)
