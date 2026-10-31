extends Node2D
## The Rev Charge placeholder effect (task T-460), drawn in code until the art
## ticket replaces it. The run draws it over the car. Two parts, at the car's rear:
## - while charging: a glow at the car's rear that grows with the charge
##   (heat yellows and oranges, Visual style, HUD palette "for heat and fire")
##   and pulses once the charge is full;
## - while boosting: speed lines streaming back from the rear (light
##   blue-grey), fading out as the boost runs down.
## Nothing shows when the power-up is not owned, or after the boost ends.
## Set `view_transform` to the view's projection and call bind(car). Reads the
## car's rev_charge each frame; it changes no driving.

const PX_PER_UNIT := 16.0
## Glow colours, from the outside in (Visual style, the burning likes bar's yellows and oranges).
const GLOW_OUTER := Color8(255, 153, 20, 90)
const GLOW_MID := Color8(255, 184, 41, 150)
const GLOW_CORE := Color8(255, 224, 77, 220)
const GLOW_HOT := Color8(255, 250, 209, 255)
## Speed lines (Visual style, the light blue-grey for labels).
const LINE_COLOUR := Color8(235, 242, 255, 230)

## How far behind the car's centre the rear is, in units (the car is 3 long).
@export var behind_units := 1.6
## Glow radius at a full charge, in view pixels.
@export var glow_radius_px := 18.0
## Speed lines: count, length (px) and how far back they reach (units).
@export var line_count := 5
@export var line_length_px := 22.0
@export var line_reach_units := 3.0

var view_transform := Transform2D.IDENTITY:
	set(value):
		view_transform = value
		queue_redraw()
## Seconds since this node started (for the pulse and the lines' motion).
var time := 0.0

var _car: Node = null


func _process(delta: float) -> void:
	advance(delta)


func bind(car: Node) -> void:
	_car = car
	queue_redraw()


func advance(delta: float) -> void:
	time += delta
	queue_redraw()


func _rc():
	if _car == null or not is_instance_valid(_car):
		return null
	return _car.rev_charge


## True while the charge glow shows.
func charge_visible() -> bool:
	var rc = _rc()
	return rc != null and rc.is_owned() and rc.charging and rc.charge_fraction() > 0.0


## True while the boost's speed lines show.
func boost_visible() -> bool:
	var rc = _rc()
	return rc != null and rc.is_owned() and rc.is_boosting()


func is_showing() -> bool:
	return charge_visible() or boost_visible()


## The glow's radius now, view px (0 when not charging).
func glow_radius() -> float:
	if not charge_visible():
		return 0.0
	var rc = _rc()
	var f: float = rc.charge_fraction()
	var r := glow_radius_px * (0.35 + 0.65 * f)
	if f >= 1.0:
		r *= 1.0 + 0.12 * sin(time * TAU * 4.0)  # full: pulses
	return r


## Where the rear of the car is drawn, view px.
func rear_point() -> Vector2:
	var m = _car.model
	var heading: float = m.rotation
	var rear: Vector2 = m.get_position() - Vector2.from_angle(heading) * behind_units
	return view_transform * (rear * PX_PER_UNIT)


## The speed lines now, for tests and drawing: [[from, to], ...] in view px.
func speed_lines() -> Array:
	var out: Array = []
	if not boost_visible():
		return out
	var m = _car.model
	var back := view_transform.basis_xform(-Vector2.from_angle(m.rotation)).normalized()
	var across := Vector2(-back.y, back.x)
	var rear := rear_point()
	var reach := line_reach_units * PX_PER_UNIT
	for i in line_count:
		var lane := (float(i) - (line_count - 1) * 0.5) * 4.0
		var phase := fposmod(time * 3.0 + float(i) * 0.37, 1.0)
		var start := rear + across * lane + back * (phase * reach)
		out.append([start, start + back * line_length_px * (0.6 + 0.4 * (1.0 - phase))])
	return out


func _draw() -> void:
	if _car == null or not is_instance_valid(_car):
		return
	if charge_visible():
		var at := rear_point()
		var r := glow_radius()
		draw_circle(at, r, GLOW_OUTER)
		draw_circle(at, r * 0.72, GLOW_MID)
		draw_circle(at, r * 0.45, GLOW_CORE)
		if _rc().charge_fraction() >= 1.0:
			draw_circle(at, r * 0.25, GLOW_HOT)
	if boost_visible():
		var fade: float = 0.35 + 0.65 * _rc().boost_fraction_left()
		var c := LINE_COLOUR
		c.a *= fade
		for seg in speed_lines():
			draw_line(seg[0], seg[1], c, 2.0)
