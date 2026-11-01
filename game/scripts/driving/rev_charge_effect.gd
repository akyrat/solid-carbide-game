extends Node2D
## The Rev Charge effect (task T-460; its art is T-466's, replacing the code-drawn
## placeholder). The run draws it over the car. Two parts, at the car's rear:
## - while charging: a heat glow that grows with the charge in four steps and
##   pulses once the charge is full;
## - while boosting: speed lines streaming back from the rear (light
##   blue-grey), shorter as the boost runs down.
## glow_radius() and speed_lines() remain as the logic the tests read.
## Nothing shows when the power-up is not owned, or after the boost ends.
## Set `view_transform` to the view's projection and call bind(car). Reads the
## car's rev_charge each frame; it changes no driving.

const PX_PER_UNIT := 16.0
## The art (task T-466, game/tools/build_rev_charge.py): one row per screen direction
## (16, row 0 points right), columns: charge 25/50/75/100 %, two full-charge pulse
## frames, then the boost's five frames. Drawn at 0.5, like the car.
const SHEET := preload("res://art/driving/rev_charge/rev_charge.png")
const CELL := 80
const DIRECTIONS := 16
const CHARGE_FRAMES := 4
const PULSE_FRAMES := 2
const BOOST_FRAMES := 5
const ART_SCALE := 0.5
## Where the glow's centre and the lines' leading ends sit, texels right of the cell's centre.
const CHARGE_ANCHOR_TEXELS := Vector2(10.0, 0.0)
const BOOST_ANCHOR_TEXELS := Vector2(26.0, 0.0)

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


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


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


## The sheet column now (charge frames 0-3 by the charge, 4-5 pulsing when full,
## then the boost's frames as it runs down), or -1 when nothing shows.
func frame_now() -> int:
	if charge_visible():
		var f: float = _rc().charge_fraction()
		if f >= 1.0:
			return CHARGE_FRAMES + (int(time * 8.0) % PULSE_FRAMES)
		return clampi(ceili(f * CHARGE_FRAMES) - 1, 0, CHARGE_FRAMES - 1)
	if boost_visible():
		var used: float = 1.0 - _rc().boost_fraction_left()
		return CHARGE_FRAMES + PULSE_FRAMES + clampi(int(used * BOOST_FRAMES), 0, BOOST_FRAMES - 1)
	return -1


## The sheet row for the car's heading: the closest screen direction.
func direction_row() -> int:
	var screen := view_transform.basis_xform(Vector2.from_angle(_car.model.rotation))
	var step := TAU / float(DIRECTIONS)
	return posmod(roundi(screen.angle() / step), DIRECTIONS)


func _draw() -> void:
	if _car == null or not is_instance_valid(_car):
		return
	var frame := frame_now()
	if frame < 0:
		return
	# The art points right and trails left; its anchor (the glow's centre, or the
	# lines' leading ends) goes at the car's rear.
	var row := direction_row()
	var anchor_texels := CHARGE_ANCHOR_TEXELS if charge_visible() else BOOST_ANCHOR_TEXELS
	var angle := float(row) * TAU / float(DIRECTIONS)
	var centre := rear_point() - (anchor_texels * ART_SCALE).rotated(angle)
	var half := CELL * ART_SCALE * 0.5
	var src := Rect2(frame * CELL, row * CELL, CELL, CELL)
	draw_texture_rect_region(SHEET, Rect2(centre - Vector2(half, half), Vector2(half, half) * 2.0), src)
