extends Node2D
## Drift marks (task T-117; Visual style, Decisions, "Drift marks"): while the
## car drifts, its two rear tyres leave marks on the ground.
##
## - When: only while the car's own drift state is on (CarModel.is_drifting,
##   the same one that gives likes for drifting). Each drift starts a new mark
##   per rear tyre, so separate drifts leave separate marks.
## - Where: one mark per rear tyre, at the tyre's real place on the ground,
##   worked out from the car's position, heading and size (rear_axle_units
##   behind the centre, half_track_units to each side). Points are in the flat
##   world's pixels (Car.PX_PER_UNIT per unit), so this node goes under a node
##   with the view's transform (flat or isometric), drawn over the ground and
##   under the car, buildings and everything else.
## - How long: a mark is a chain of pieces (Line2D children). A piece closes
##   after piece_segments segments, or when the drift ends. Each closed piece
##   stays fully visible for `lifetime` seconds, then fades as a whole
##   (modulate alpha, never per pixel: Visual style, "See-through rule") over
##   `fade_time` seconds and is removed. At most max_segments segments are
##   kept; past it the oldest pieces go first.
##
## Every look and tuning value lives in scenes/driving/drift_marks.tscn (the
## exported variables below), so the art task (T-118) swaps the texture and
## retunes without touching this code.
##
## Use: instantiate the scene, add it under the view, call bind(car). Or call
## lay(drifting, position_units, rotation) yourself after each physics step.
## It ages in _process (the default, pausable process mode), so marks do not
## fade while the game is paused.

## Pixels per unit in the flat world (Car.PX_PER_UNIT).
const PX_PER_UNIT := 16.0

## The mark's texture, drawn along each line (Line2D texture). Opaque pixels
## only; the whole piece fades through modulate.
@export var mark_texture: Texture2D
## How the texture runs along the line (Line2D.texture_mode): tile or stretch.
@export var texture_mode: Line2D.LineTextureMode = Line2D.LINE_TEXTURE_TILE
## Tint multiplied with the texture (Line2D.default_color). Keep alpha at 1.
@export var mark_color: Color = Color(1, 1, 1, 1)
## The mark's width, in units (1 unit = the car's width).
@export var width_units: float = 0.25
## Seconds a piece stays fully visible after it was laid.
@export var lifetime: float = 6.0
## Seconds a piece then takes to fade out as a whole before it is removed.
@export var fade_time: float = 1.0
## The most segments kept at once, both tyres together.
@export var max_segments: int = 800
## A piece of a mark closes (starts its lifetime) after this many segments.
@export var piece_segments: int = 16
## A new point is laid once the tyre has moved this far from the last one, in units.
@export var min_segment_units: float = 0.1
## How far behind the car's centre the rear tyres are, in units (the car is 3 long).
@export var rear_axle_units: float = 0.9
## How far each rear tyre is from the car's centre line, in units (the car is 1 wide).
@export var half_track_units: float = 0.375

## Seconds since this node started (only advances while not paused).
var time := 0.0
## How many marks have been started (each drift starts two: one per tyre).
var marks_started := 0

## Pieces, oldest first: {line: Line2D, mark: int, tyre: int, closed_at: float
## (-1 while still being laid), segments: int}.
var _pieces: Array = []
## The piece each tyre is laying now (0 = left, 1 = right), or null.
var _open: Array = [null, null]
var _segments := 0
var _was_drifting := false


func _process(delta: float) -> void:
	advance(delta)


## Lays marks after the car's every physics step.
func bind(car: Node) -> void:
	car.stepped.connect(func() -> void:
		lay(car.model.is_drifting, car.model.get_position(), car.model.rotation))


## The two rear tyres' places on the ground, in units: [left, right].
## rotation 0 points the nose along +x (the car's convention).
func rear_tyres(position_units: Vector2, rotation_rad: float) -> Array:
	var forward := Vector2(cos(rotation_rad), sin(rotation_rad))
	var side := Vector2(-forward.y, forward.x)  # the car's right, y down
	var axle := position_units - forward * rear_axle_units
	return [axle - side * half_track_units, axle + side * half_track_units]


## One physics step of the car: lays marks while drifting, ends them when not.
func lay(drifting: bool, position_units: Vector2, rotation_rad: float) -> void:
	if not drifting:
		if _was_drifting:
			_close_open()
		_was_drifting = false
		return
	var tyres := rear_tyres(position_units, rotation_rad)
	if not _was_drifting:
		_close_open()
		for t in 2:
			marks_started += 1
			_open[t] = _new_piece(marks_started, t, tyres[t] * PX_PER_UNIT)
	else:
		for t in 2:
			_extend(t, tyres[t] * PX_PER_UNIT)
	_was_drifting = true
	_enforce_cap()


## Moves time on: closed pieces past their lifetime fade, then go.
func advance(delta: float) -> void:
	time += delta
	var keep: Array = []
	for p in _pieces:
		if p.closed_at < 0.0:
			keep.append(p)
			continue
		var age: float = time - p.closed_at
		if age >= lifetime + fade_time:
			_free_piece(p)
			continue
		var line: Line2D = p.line
		if age > lifetime:
			line.modulate.a = clampf(1.0 - (age - lifetime) / maxf(fade_time, 0.0001), 0.0, 1.0)
		else:
			line.modulate.a = 1.0
		keep.append(p)
	_pieces = keep


## Segments kept now, both tyres together.
func segment_count() -> int:
	return _segments


## The Line2D pieces kept now, oldest first.
func pieces() -> Array:
	var out: Array = []
	for p in _pieces:
		out.append(p.line)
	return out


## The marks kept now: mark number -> {tyre: 0 left / 1 right, lines: [Line2D]}.
func marks() -> Dictionary:
	var out := {}
	for p in _pieces:
		if not out.has(p.mark):
			out[p.mark] = {"tyre": p.tyre, "lines": []}
		out[p.mark].lines.append(p.line)
	return out


## True while a drift is laying marks.
func is_laying() -> bool:
	return _open[0] != null or _open[1] != null


## Removes every mark (not needed by the run, which builds a new map per run).
func clear() -> void:
	for p in _pieces:
		p.line.queue_free()
	_pieces.clear()
	_open = [null, null]
	_segments = 0
	_was_drifting = false


func _new_piece(mark: int, tyre: int, start_px: Vector2) -> Dictionary:
	var line := Line2D.new()
	line.name = "Mark%d_%s" % [mark, "L" if tyre == 0 else "R"]
	line.width = width_units * PX_PER_UNIT
	line.texture = mark_texture
	line.texture_mode = texture_mode
	line.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	line.default_color = mark_color
	line.antialiased = false
	line.joint_mode = Line2D.LINE_JOINT_SHARP
	line.add_point(start_px)
	add_child(line)
	var p := {"line": line, "mark": mark, "tyre": tyre, "closed_at": -1.0, "segments": 0}
	_pieces.append(p)
	return p


func _extend(tyre: int, point_px: Vector2) -> void:
	var p = _open[tyre]
	if p == null:
		return
	var line: Line2D = p.line
	var last := line.get_point_position(line.get_point_count() - 1)
	if last.distance_to(point_px) < min_segment_units * PX_PER_UNIT:
		return
	line.add_point(point_px)
	p.segments += 1
	_segments += 1
	if p.segments >= piece_segments:
		# Close this piece and carry on from its last point, so the mark stays joined.
		p.closed_at = time
		_open[tyre] = _new_piece(p.mark, tyre, point_px)


func _close_open() -> void:
	for t in 2:
		var p = _open[t]
		_open[t] = null
		if p == null:
			continue
		if p.segments == 0:
			_pieces.erase(p)
			p.line.queue_free()
		else:
			p.closed_at = time


func _enforce_cap() -> void:
	while _segments > max_segments:
		var oldest_closed = null
		for p in _pieces:
			if p.closed_at >= 0.0:
				oldest_closed = p
				break
		if oldest_closed != null:
			_free_piece(oldest_closed)
			_pieces.erase(oldest_closed)
			continue
		# Only pieces still being laid: trim the longest one's first point.
		var p = null
		for q in _pieces:
			if p == null or q.segments > p.segments:
				p = q
		if p == null or p.segments <= 0:
			break
		var line: Line2D = p.line
		line.remove_point(0)
		p.segments -= 1
		_segments -= 1


func _free_piece(p: Dictionary) -> void:
	_segments -= int(p.segments)
	p.line.queue_free()
