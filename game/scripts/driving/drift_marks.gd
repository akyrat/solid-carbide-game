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
## Hype (task T-249; Visual style, Decisions, "Hype drift trail"): the marks
## heat up with the combo, on the HUD's combo heat steps (ComboHeat.THRESHOLDS,
## read from there). heat_step is 0 (the plain marks) below x2, then 1, 2, 3 from
## x2, x3, x4. Each piece takes the step current when it is started and keeps it
## for life, so the trail shows how hot the drift was. A piece of step 1 or more
## gets a solid glow line behind it and a hot core line on it (heat_looks), the
## tyres throw sparks, and at the top step flames (drift_heat_sparks.gd).
## Nothing calls set_multiplier in the drift prototype, so it keeps the plain marks.
##
## Every look and tuning value lives in scenes/driving/drift_marks.tscn (the
## exported variables below), so the art task (T-118) swaps the texture and
## retunes without touching this code.
##
## Raised ground (task T-259; Drifting, Decisions, "Drift marks on raised ground"):
## on a map with rooftops and ramps the run sets height_at, depth_for and
## view_basis. Each point of a mark is then lifted up the screen by the ground's
## height under that tyre (view_basis turns the screen lift into this node's own
## flat pixels), and a piece takes the depth (z_index) depth_for gives where it
## is laid: over the rooftop or ramp it lies on, under the buildings, boulders and
## areas that cover the car there, as the car's shadow is. Street marks keep z 0,
## under everything. A piece closes when its depth changes. Without the three
## (the drift prototype) nothing is lifted and every piece stays at z 0.
##
## Use: instantiate the scene, add it under the view, call bind(car). Or call
## lay(drifting, position_units, rotation) yourself after each physics step.
## It ages in _process (the default, pausable process mode), so marks do not
## fade while the game is paused.

## Pixels per unit in the flat world (Car.PX_PER_UNIT).
const PX_PER_UNIT := 16.0
const HeatSparks := preload("res://scripts/driving/drift_heat_sparks.gd")

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

## The look of each heat step, index 0 = step 1 (x2), 1 = step 2 (x3), 2 = step 3
## (x4 and up). Keys: glow_color, glow_width_units (behind the mark, wider than
## it), core_color, core_width_units (on the mark; 0 = none), flicker_colors
## (glow colours picked each flicker frame; empty = steady), spark_rate (per
## second per tyre), spark_speed (world px/s), spark_life, spark_size_px,
## spark_colors, flame_rate (per second per tyre), flame_size_px, flame_life.
## All colours opaque, in the combo heat's yellows, oranges and white-hot.
@export var heat_looks: Array = []
## Length of a flicker frame in seconds (the combo heat's, 1/12).
@export var flicker_frame: float = 1.0 / 12.0

## Raised ground (T-259), set by the run; unset = flat ground. height_at:
## Callable(units: Vector2) -> float, the ground's height there in units.
## depth_for: Callable(units: Vector2, rotation: float, height: float) -> int,
## the z_index for a mark laid at that height. view_basis: the view's transform
## (flat world pixels -> screen), only its basis is used.
var height_at := Callable()
var depth_for := Callable()
var view_basis := Transform2D.IDENTITY

## The current heat step, 0 to 3; marks started now take it.
var heat_step := 0

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
var _sparks: Node2D
var _spark_carry := [0.0, 0.0]
var _flame_carry := [0.0, 0.0]
var _flicker_seed := -1


func _ready() -> void:
	_sparks = HeatSparks.new()
	_sparks.name = "HeatSparks"
	add_child(_sparks)


func _process(delta: float) -> void:
	advance(delta)


## The combo multiplier now (from RunState.combo_changed): picks the heat step
## for marks started from now on, with the combo heat's own thresholds.
func set_multiplier(multiplier: float) -> void:
	heat_step = ComboHeat.step_for(multiplier)


## The look of heat step `step` (1 to 3), or {} for the plain marks.
func look_for(step: int) -> Dictionary:
	if step < 1 or step > heat_looks.size():
		return {}
	return heat_looks[step - 1]


## The heat step a mark number's pieces were laid at (0 when it is gone).
func step_of_mark(mark: int) -> int:
	for p in _pieces:
		if p.mark == mark:
			return p.step
	return 0


## Lays marks after the car's every physics step. None while the car is
## airborne, even with the drift keys held: the marks end on takeoff and new
## ones start on landing (Drifting, Decisions, "No drift smoke or tyre marks in
## the air", task T-206).
func bind(car: Node) -> void:
	car.stepped.connect(func() -> void:
		lay(lays(car), car.model.get_position(), car.model.rotation))


## Whether `car` lays marks this step: drifting and not airborne (a car
## without a height, `airborne` missing, is always on the ground).
static func lays(car: Node) -> bool:
	return car.model.is_drifting and car.get("airborne") != true


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
	var z := depth_at(position_units, rotation_rad)
	if _sparks != null:
		_sparks.z_index = z
	if not _was_drifting:
		_close_open()
		for t in 2:
			marks_started += 1
			_open[t] = _new_piece(marks_started, t, point_px(tyres[t]), z)
	else:
		for t in 2:
			_extend(t, point_px(tyres[t]), z)
	_was_drifting = true
	_enforce_cap()


## A tyre's place in this node's pixels: the flat place, lifted by the ground's
## height under it on raised ground.
func point_px(tyre_units: Vector2) -> Vector2:
	var p := tyre_units * PX_PER_UNIT
	if not height_at.is_valid():
		return p
	var h: float = height_at.call(tyre_units)
	if h <= 0.0:
		return p
	return p + view_basis.affine_inverse().basis_xform(Vector2(0.0, -h * PX_PER_UNIT))


## The depth a mark laid with the car at `position_units` takes: 0 on the street
## (and everywhere without raised ground), on raised ground depth_for's.
func depth_at(position_units: Vector2, rotation_rad: float) -> int:
	if not height_at.is_valid() or not depth_for.is_valid():
		return 0
	var h: float = height_at.call(position_units)
	if h <= 0.0:
		return 0
	return depth_for.call(position_units, rotation_rad, h)


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
	_flicker()
	_throw_sparks(delta)


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
	if _sparks != null:
		_sparks.clear()


func _new_piece(mark: int, tyre: int, start_px: Vector2, z: int = 0) -> Dictionary:
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
	line.z_index = z
	add_child(line)
	var p := {"line": line, "mark": mark, "tyre": tyre, "closed_at": -1.0, "segments": 0,
		"step": heat_step, "glow": null, "core": null, "z": z}
	var look := look_for(heat_step)
	if not look.is_empty():
		p.glow = _heat_line("Glow", look.glow_width_units, look.glow_color, start_px, line)
		p.glow.show_behind_parent = true
		if look.core_width_units > 0.0:
			p.core = _heat_line("Core", look.core_width_units, look.core_color, start_px, line)
	_pieces.append(p)
	return p


func _heat_line(node_name: String, width_units: float, color: Color, start_px: Vector2, parent: Line2D) -> Line2D:
	var l := Line2D.new()
	l.name = node_name
	l.width = width_units * PX_PER_UNIT
	l.default_color = color
	l.antialiased = false
	l.joint_mode = Line2D.LINE_JOINT_SHARP
	l.add_point(start_px)
	parent.add_child(l)
	return l


## Glow colours jump each flicker frame on steps that flicker (steady ones keep theirs).
func _flicker() -> void:
	var frame := int(floorf(time / flicker_frame))
	if frame == _flicker_seed:
		return
	_flicker_seed = frame
	for p in _pieces:
		var look := look_for(p.step)
		if look.is_empty() or look.flicker_colors.is_empty():
			continue
		var colors: Array = look.flicker_colors
		var pick := int(abs(sin((frame + p.mark * 7 + p.tyre) * 12.9898) * 43758.5453)) % colors.size()
		p.glow.default_color = colors[pick]


## Sparks (and, at the top step, flames) off each tyre being laid at a hot step.
func _throw_sparks(delta: float) -> void:
	if _sparks == null:
		return
	_sparks.age(delta)
	for t in 2:
		var p = _open[t]
		if p == null or p.step < 1:
			_spark_carry[t] = 0.0
			_flame_carry[t] = 0.0
			continue
		var look := look_for(p.step)
		var at: Vector2 = p.line.get_point_position(p.line.get_point_count() - 1)
		_spark_carry[t] += look.spark_rate * delta
		while _spark_carry[t] >= 1.0:
			_spark_carry[t] -= 1.0
			_sparks.emit(at, look, false)
		_flame_carry[t] += look.flame_rate * delta
		while _flame_carry[t] >= 1.0:
			_flame_carry[t] -= 1.0
			_sparks.emit(at, look, true)


func _extend(tyre: int, new_px: Vector2, z: int = 0) -> void:
	var p = _open[tyre]
	if p == null:
		return
	var line: Line2D = p.line
	var last := line.get_point_position(line.get_point_count() - 1)
	if last.distance_to(new_px) < min_segment_units * PX_PER_UNIT:
		return
	line.add_point(new_px)
	for extra in [p.glow, p.core]:
		if extra != null:
			extra.add_point(new_px)
	p.segments += 1
	_segments += 1
	if p.segments >= piece_segments or p.z != z:
		# Close this piece (full, or the depth changed) and carry on from its last
		# point, so the mark stays joined.
		p.closed_at = time
		_open[tyre] = _new_piece(p.mark, tyre, new_px, z)


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
		for extra in [p.glow, p.core]:
			if extra != null:
				extra.remove_point(0)
		p.segments -= 1
		_segments -= 1


func _free_piece(p: Dictionary) -> void:
	_segments -= int(p.segments)
	p.line.queue_free()
