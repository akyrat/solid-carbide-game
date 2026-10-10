extends RefCounted
## Tracks one driving challenge's completion rule (Level design, Decisions): the
## drawn car must touch the challenge's corridor continuously from the arrow's
## start to its end, in the arrow's direction. Leaving the corridor midway means
## starting again from the start.
##
## Everything is in map units (1 unit = the car's width). No nodes, so tests can
## run it directly. The map (mvp_map.gd) feeds it the drawn car once per physics
## step through update().
##
## How "touching" is measured: the corridor is every point within half its
## width of the arrow's centre line. The drawn car is a 3 x 1 unit rectangle
## (its length along its heading, rotation 0 = nose along +x), centred on the
## car's position. The car touches the corridor at a centre-line sample when the
## sample is within half the corridor's width of that rectangle. The centre line
## is resampled every SAMPLE_STEP units, so the corridor's edge is exact to
## within SAMPLE_STEP / 2.

## The drawn car's size in units (Drifting, Decisions).
const CAR_LENGTH := 3.0
const CAR_WIDTH := 1.0
## Spacing of the centre-line samples, in units.
const SAMPLE_STEP := 0.1
## How far along the arrow (in units) progress may move in one step, ahead of or
## behind the furthest point reached. It keeps progress on the stretch of the
## arrow the car is on where the path crosses or passes close to itself (a
## figure-eight's crossing, a loop's start and end). It is wider than the stretch
## of corridor the car can touch at once (car length + corridor width = 6 units).
const PROGRESS_WINDOW := 8.0

## Emitted once, the step the challenge is completed.
signal completed

var id := ""
var corridor_width := 3.0
## Centre-line samples, from the arrow's start to its end.
var samples := PackedVector2Array()
## Arc length (units) of each sample from the start.
var arc := PackedFloat32Array()

## True while the car is on a valid run from the start.
var active := false
## Index of the furthest sample reached on the current run.
var progress := 0
var is_completed := false

var _window_samples := 1
var _bounds := Rect2()


## centre_line: the arrow's centre line, in units (the layout data's centre_line).
func setup(challenge_id: String, centre_line: PackedVector2Array, width: float) -> void:
	id = challenge_id
	corridor_width = width
	samples = PackedVector2Array()
	arc = PackedFloat32Array()
	var length := 0.0
	samples.append(centre_line[0])
	arc.append(0.0)
	for i in range(1, centre_line.size()):
		var a := centre_line[i - 1]
		var b := centre_line[i]
		var seg := a.distance_to(b)
		if seg <= 0.0:
			continue
		var n := maxi(1, ceili(seg / SAMPLE_STEP))
		for k in range(1, n + 1):
			var t := float(k) / float(n)
			samples.append(a.lerp(b, t))
			arc.append(length + seg * t)
		length += seg
	_window_samples = maxi(1, ceili(PROGRESS_WINDOW / SAMPLE_STEP))
	_bounds = Rect2(samples[0], Vector2.ZERO)
	for p in samples:
		_bounds = _bounds.expand(p)
	_bounds = _bounds.grow(width / 2.0)
	reset()


func length() -> float:
	return arc[arc.size() - 1]


## Progress along the arrow on the current run, 0 to 1.
func progress_ratio() -> float:
	return arc[progress] / length() if active else 0.0


func reset() -> void:
	active = false
	progress = 0


## Distance from a point to the drawn car's rectangle (0 inside it).
static func distance_to_car(p: Vector2, car_centre: Vector2, car_rotation: float) -> float:
	var local := (p - car_centre).rotated(-car_rotation)
	var dx := maxf(absf(local.x) - CAR_LENGTH / 2.0, 0.0)
	var dy := maxf(absf(local.y) - CAR_WIDTH / 2.0, 0.0)
	return Vector2(dx, dy).length()


## True when the drawn car touches the corridor anywhere.
func car_touches(car_centre: Vector2, car_rotation: float) -> bool:
	return not touched_samples(car_centre, car_rotation).is_empty()


## Indices of the centre-line samples the drawn car touches.
func touched_samples(car_centre: Vector2, car_rotation: float) -> PackedInt32Array:
	var out := PackedInt32Array()
	# The car reaches at most half its diagonal from its centre.
	var reach := Vector2(CAR_LENGTH, CAR_WIDTH).length() / 2.0
	if not _bounds.grow(reach).has_point(car_centre):
		return out
	var r := corridor_width / 2.0
	var near := reach + r
	for i in samples.size():
		var p := samples[i]
		if absf(p.x - car_centre.x) > near or absf(p.y - car_centre.y) > near:
			continue
		if distance_to_car(p, car_centre, car_rotation) <= r:
			out.append(i)
	return out


## Feeds the drawn car's position (units) and rotation (radians) for one physics
## step. Returns true on the step the challenge is completed.
func update(car_centre: Vector2, car_rotation: float) -> bool:
	if is_completed:
		return false
	var touched := touched_samples(car_centre, car_rotation)
	if touched.is_empty():
		reset()
		return false
	if active:
		var best := -1
		for i in touched:
			if i >= progress - _window_samples and i <= progress + _window_samples:
				best = maxi(best, i)
		if best < 0:
			# Touching another stretch of the arrow only: the run was broken.
			reset()
		else:
			progress = maxi(progress, best)
	if not active:
		# A run starts when the car touches the arrow's start.
		if touched[0] == 0:
			active = true
			progress = 0
			for i in touched:
				if i <= _window_samples:
					progress = maxi(progress, i)
	if active and progress == samples.size() - 1:
		is_completed = true
		active = false
		completed.emit()
		return true
	return false
