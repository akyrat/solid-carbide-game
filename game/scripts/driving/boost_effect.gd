extends Node2D
## The cruise boost effect: a few animated motion lines behind the car when W
## snaps it up to cruise speed (Car.boost). Task T-008 made the signal and a
## placeholder (drawn streaks); task T-009 replaced the drawing with PixelLab
## art, `res://art/effects/boost_lines.png` (record: boost_lines.json, built by
## game/tools/build_boost_lines.py).
##
## The sheet has one row per screen direction (row 0 points right on screen,
## each next row turned clockwise by 360 / directions degrees) and one column
## per frame. The effect picks the row closest to the car's heading as seen in
## the view, so the art is never rotated by the engine, and draws it at the
## car's art density (scale 0.5). Each burst plays its frames once and ends by
## itself. A burst from bind(car) follows the car, staying right behind it (the
## T-008 streaks stayed where they were made, but the car outruns them at once);
## play() alone draws a burst that stays where it was made.
## Set `view_transform` to the view's projection and call bind(car).
##
## The Polarized Steering Wheel's burst (task T-502) plays a stronger burst of the
## same lines (play_strong()): three sets side by side across the car's width
## (`strong_offsets_units`), the side ones out of step with the middle one, looping
## their frames for as long as the burst lasts. The art is never scaled, so its
## pixels stay the car's size.

const PX_PER_UNIT := 16.0
const SHEET := preload("res://art/effects/boost_lines.png")
const RECORD_PATH := "res://art/effects/boost_lines.json"
## Texels per unit of the art, drawn at 0.5 (like the car).
const ART_SCALE := 0.5
## Where the lines' leading (bright) ends sit in the unturned frame, in texels
## from the cell's centre: the lines point right, so +x is towards the car.
const HEAD_OFFSET_TEXELS := Vector2(28.0, 0.0)

## Frames a second. 5 frames at 14 fps last about 0.36 s, close to T-008's 0.35 s.
@export var fps := 14.0
## How far behind the car's centre the lines start, in units (the car is 3 long).
@export var behind_units := 0.8
## The Polarized Steering Wheel's burst (T-502): the sideways offsets of its sets of
## lines, units from the car's centre line (proposal: the middle set and one at each
## side of the car, so the trail is three times as dense as the cruise boost's).
var strong_offsets_units: Array = [-0.45, 0.0, 0.45]

var view_transform := Transform2D.IDENTITY:
	set(value):
		view_transform = value
		queue_redraw()
## Seconds since this node started (only advances while not paused).
var time := 0.0
## How many bursts have been made.
var bursts_made := 0
## Frames in the sheet, size of one cell, screen directions (from the record).
var frame_count := 5
var cell_size := 80
var directions := 16
## Seconds one burst lasts (frame_count / fps).
var lifetime := 0.35
## Bursts now: {position: Vector2 (units, behind the car), heading: float, born: float,
## and for a strong burst (T-502) strong: true and life: float (seconds, looping)}.
var _bursts: Array = []


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var f := FileAccess.open(RECORD_PATH, FileAccess.READ)
	if f:
		var rec: Variant = JSON.parse_string(f.get_as_text())
		if rec is Dictionary:
			frame_count = int(rec.get("frames", frame_count))
			cell_size = int(rec.get("frame_size", cell_size))
			directions = int(rec.get("directions", directions))
	lifetime = frame_count / fps


func _process(delta: float) -> void:
	Perf.begin(&"effects.boost")
	advance(delta)
	Perf.end(&"effects.boost")


## Plays a burst each time the car's boost signal fires.
func bind(car: Node) -> void:
	car.boost.connect(func(_from_speed: float) -> void:
		play(car.model.get_position(), car.model.rotation)
		_bursts[-1]["car"] = car)
	# T-502: the Polarized Steering Wheel's burst, a stronger burst for its length.
	var wheel = car.get("polarized")
	if wheel != null:
		wheel.fired.connect(func(_speed: float, seconds: float, _angle: float) -> void:
			play_strong(car.model.get_position(), car.model.rotation, seconds)
			_bursts[-1]["car"] = car)


## The Polarized Steering Wheel's burst (T-502): the stronger lines, looping their
## frames for `seconds` (at least one full play).
func play_strong(position_units: Vector2, heading: float, seconds: float) -> void:
	play(position_units, heading)
	_bursts[-1]["strong"] = true
	_bursts[-1]["life"] = maxf(seconds, lifetime)


## Strong bursts playing now (T-502).
func strong_count() -> int:
	var n := 0
	for b in _bursts:
		if b.has("strong"):
			n += 1
	return n


## Starts a burst for a car at a place (units) pointing at heading (radians).
func play(position_units: Vector2, heading: float) -> void:
	_bursts.append({"position": position_units, "heading": heading, "born": time})
	bursts_made += 1
	queue_redraw()


func advance(delta: float) -> void:
	time += delta
	var keep: Array = []
	for b in _bursts:
		if time - b.born < float(b.get("life", lifetime)):
			keep.append(b)
	_bursts = keep
	queue_redraw()


## Bursts playing now.
func burst_count() -> int:
	return _bursts.size()


func clear() -> void:
	_bursts.clear()
	queue_redraw()


## The sheet row for a heading (radians, world): the closest screen direction.
func direction_row(heading: float) -> int:
	var screen := view_transform.basis_xform(Vector2.from_angle(heading))
	var step := TAU / float(directions)
	return posmod(roundi(screen.angle() / step), directions)


## The frame (column) a burst shows now, or -1 once it has ended.
func frame_of(burst: Dictionary) -> int:
	var age: float = time - burst.born
	var life := float(burst.get("life", lifetime))
	if age < 0.0 or age >= life:
		return -1
	if burst.has("life"):
		return int(age * fps) % frame_count  # a strong burst loops (T-502)
	return mini(int(age * fps), frame_count - 1)


## What is drawn now, for tests: [{row, frame, at (view px, cell centre)}]; a strong
## burst (T-502) gives one entry per set of lines.
func drawn() -> Array:
	var out: Array = []
	for b in _bursts:
		var frame := frame_of(b)
		if frame < 0:
			continue
		var place: Vector2 = b.position
		var heading: float = b.heading
		var car: Variant = b.get("car")
		if car != null and is_instance_valid(car):
			place = car.model.get_position()
			heading = car.model.rotation
		var row := direction_row(heading)
		var angle := float(row) * TAU / float(directions)
		var nose := Vector2.from_angle(heading)
		var offsets: Array = strong_offsets_units if b.has("strong") else [0.0]
		for i in offsets.size():
			var side := float(offsets[i])
			var rear: Vector2 = place - nose * behind_units + nose.orthogonal() * side
			var anchor := view_transform * (rear * PX_PER_UNIT)
			var centre := anchor - (HEAD_OFFSET_TEXELS * ART_SCALE).rotated(angle)
			var f := frame if side == 0.0 else (frame + 1 + i) % frame_count
			out.append({"row": row, "frame": f, "at": centre})
	return out


func _draw() -> void:
	if Perf.on: Perf.each_begin(&"draw.boost")
	var half := cell_size * ART_SCALE * 0.5
	for d in drawn():
		var src := Rect2(d.frame * cell_size, d.row * cell_size, cell_size, cell_size)
		var at: Vector2 = d.at
		var dest := Rect2(at - Vector2(half, half), Vector2(half, half) * 2.0)
		draw_texture_rect_region(SHEET, dest, src)
	if Perf.on: Perf.each_end(&"draw.boost")
