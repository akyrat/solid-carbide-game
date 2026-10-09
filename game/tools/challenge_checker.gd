extends RefCounted
## Drivability check for a challenge drawing (task T-021, Driving & Drift Agent).
##
## Drives the real car (scripts/driving/car_model.gd, with the handling values in
## scripts/driving/car_tuning.gd) along a challenge's arrow, steering
## automatically, and decides whether the challenge can be driven:
##
## - the drawn car (1 x 3 units, centred on the car) keeps touching the arrow's
##   corridor (3 units wide) from the arrow's start to its end, in the arrow's
##   direction (Level design, Decisions);
## - the car's physics body (1 x 1 unit) never touches a boulder or a building
##   cell ("B") of the drawing.
##
## The driver is a simple path follower that picks W, S, A and D each physics
## step. One driver setting may fail where another passes, so the check tries a
## fixed list of settings (target speed, look-ahead, counter-steer) and the
## challenge passes when any of them drives it. Everything is plain maths on
## 64-bit floats with a fixed order, so every run gives the same result.
##
## Coordinates are those of the drawing: units from the sheet's centre, x right,
## y down, which are the car model's axes too.

const CarModel := preload("res://scripts/driving/car_model.gd")

## Half the corridor's width (corridor_width in the drawing, 3 units).
const DEFAULT_CORRIDOR_WIDTH := 3.0
## The drawn car: 3 units long, 1 unit wide (Drifting, Decisions).
const DRAWN_HALF_LENGTH := 1.5
const DRAWN_HALF_WIDTH := 0.5
## The physics body: a 1 x 1 unit square.
const BODY_HALF := 0.5
## Samples per curve piece when turning the drawing's points into the arrow's
## centre line (the same rounded curve the drawing's picture shows).
const SAMPLES_PER_PIECE := 12
## Part of the arrow the car counts as being on, around its progress (units of
## arc length behind and ahead). The car must touch the corridor within it.
const TOUCH_BEHIND := 3.0
const TOUCH_AHEAD := 6.0
## Part of the arrow searched each step to update the progress.
const PROGRESS_BEHIND := 1.0
const PROGRESS_AHEAD := 4.0
## A drive fails when it lasts longer than this, or makes less than
## STALL_PROGRESS units of progress in STALL_SECONDS.
const MAX_SECONDS := 60.0
const STALL_SECONDS := 5.0
const STALL_PROGRESS := 0.5

## Driver settings tried, in this order. Speeds in units/s; 0 = top speed.
const TARGET_SPEEDS := [0.0, 22.0, 18.0, 15.0, 13.0, 11.0, 9.0, 7.0, 5.0, 3.0]
const LOOKAHEADS := [1.5, 2.5, 3.5, 5.0]
const COUNTER_STEERS := [0.0, 0.6, 1.2]

## Optional handling overrides, {setting key: value} (see car_tuning.gd).
var tuning_overrides := {}

# The drawing.
var drawing := {}
var boulders: Array = []        # [{x, y, r}]
var building_cells: Array = []  # [Rect2-like dicts {x0, y0, x1, y1}]
var corridor_half := DEFAULT_CORRIDOR_WIDTH / 2.0

## Distance from the car's centre to the arrow's centre line, after the last
## progress update.
var last_offset := 0.0

# The arrow's centre line, sampled: points, arc length at each point, and the
# drawing point each sample belongs to (0-based).
var cx := PackedFloat64Array()
var cy := PackedFloat64Array()
var cs := PackedFloat64Array()
var c_point := PackedInt32Array()
var length := 0.0


## Loads a drawing (the parsed JSON of a docs/level-design/*/arrow-*.json file).
## Returns an empty string, or what is wrong with it.
func load_drawing(data: Dictionary) -> String:
	drawing = data
	if not data.has("arrow") or not (data.arrow is Dictionary) or not data.arrow.has("points"):
		return "the drawing has no arrow"
	var pts: Array = data.arrow.points
	if pts.size() < 2:
		return "the arrow needs at least 2 points"
	corridor_half = float(data.arrow.get("corridor_width", DEFAULT_CORRIDOR_WIDTH)) / 2.0
	boulders.clear()
	for b in data.get("boulders", []):
		boulders.append({"x": float(b.x), "y": float(b.y), "r": float(b.diameter) / 2.0})
	building_cells.clear()
	var rows: Array = data.get("rows", [])
	var w := float(data.get("width", 0))
	var h := float(data.get("height", 0))
	for row_i in rows.size():
		var row: String = rows[row_i]
		for col in row.length():
			if row[col] == "B":
				var x0 := col - w / 2.0
				var y0 := row_i - h / 2.0
				building_cells.append({"x0": x0, "y0": y0, "x1": x0 + 1.0, "y1": y0 + 1.0})
	_build_centre_line(pts)
	return ""


## The arrow's centre line as the drawing's picture draws it
## (tools/export_challenge_drawings.py, path_d): from the first point, one
## quadratic curve per inner point (that point is the control point, the curve
## runs between the midpoints of its neighbouring segments), then a straight
## line to the last point.
func _build_centre_line(pts: Array) -> void:
	cx.clear()
	cy.clear()
	c_point.clear()
	_add_sample(float(pts[0][0]), float(pts[0][1]), 0)
	if pts.size() > 2:
		var sx := float(pts[0][0])
		var sy := float(pts[0][1])
		for i in range(1, pts.size() - 1):
			var qx := float(pts[i][0])
			var qy := float(pts[i][1])
			var ex := (qx + float(pts[i + 1][0])) / 2.0
			var ey := (qy + float(pts[i + 1][1])) / 2.0
			for k in range(1, SAMPLES_PER_PIECE + 1):
				var t := float(k) / SAMPLES_PER_PIECE
				var a := (1.0 - t) * (1.0 - t)
				var b := 2.0 * (1.0 - t) * t
				var c := t * t
				_add_sample(a * sx + b * qx + c * ex, a * sy + b * qy + c * ey, i if t < 0.5 else i + 1)
			sx = ex
			sy = ey
	var last := pts.size() - 1
	_add_sample(float(pts[last][0]), float(pts[last][1]), last)
	cs.clear()
	cs.append(0.0)
	for i in range(1, cx.size()):
		cs.append(cs[i - 1] + sqrt(pow(cx[i] - cx[i - 1], 2) + pow(cy[i] - cy[i - 1], 2)))
	length = cs[cs.size() - 1]


func _add_sample(x: float, y: float, point_index: int) -> void:
	if cx.size() > 0 and absf(cx[cx.size() - 1] - x) < 1e-9 and absf(cy[cy.size() - 1] - y) < 1e-9:
		return
	cx.append(x)
	cy.append(y)
	c_point.append(point_index)


## Point on the centre line at arc length s (clamped; past the end it carries on
## along the last segment's direction).
func point_at(s: float) -> Vector2:
	var n := cx.size()
	if s <= 0.0:
		return Vector2(cx[0], cy[0])
	if s >= length:
		var dx := cx[n - 1] - cx[n - 2]
		var dy := cy[n - 1] - cy[n - 2]
		var d := sqrt(dx * dx + dy * dy)
		var extra := s - length
		return Vector2(cx[n - 1] + dx / d * extra, cy[n - 1] + dy / d * extra)
	var i := _segment_at(s)
	var seg := cs[i + 1] - cs[i]
	var t := (s - cs[i]) / seg if seg > 0.0 else 0.0
	return Vector2(cx[i] + (cx[i + 1] - cx[i]) * t, cy[i] + (cy[i + 1] - cy[i]) * t)


## Index of the segment (i to i + 1) that holds arc length s.
func _segment_at(s: float) -> int:
	var lo := 0
	var hi := cs.size() - 1
	while hi - lo > 1:
		var mid := (lo + hi) / 2
		if cs[mid] <= s:
			lo = mid
		else:
			hi = mid
	return lo


## Radius of the drawn curve around arc length s (units), from three points
## 1 unit apart. INF on a straight stretch.
func curve_radius_at(s: float) -> float:
	var a := point_at(maxf(0.0, s - 1.0))
	var b := point_at(s)
	var c := point_at(minf(length, s + 1.0))
	var ab := a.distance_to(b)
	var bc := b.distance_to(c)
	var ca := c.distance_to(a)
	var cross := absf((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x))
	if cross < 1e-9:
		return INF
	return ab * bc * ca / (2.0 * cross)


# --- Geometry ---------------------------------------------------------------

## Distance from point (px, py) to segment (ax, ay)-(bx, by), and the segment's
## parameter t (0..1) of the closest point.
static func _point_segment(px: float, py: float, ax: float, ay: float, bx: float, by: float) -> Vector2:
	var dx := bx - ax
	var dy := by - ay
	var len2 := dx * dx + dy * dy
	var t := 0.0
	if len2 > 0.0:
		t = clampf(((px - ax) * dx + (py - ay) * dy) / len2, 0.0, 1.0)
	var qx := ax + dx * t - px
	var qy := ay + dy * t - py
	return Vector2(sqrt(qx * qx + qy * qy), t)


## Distance from a point (in the box's own frame) to the box [-hx, hx] x [-hy, hy].
static func _point_box(lx: float, ly: float, hx: float, hy: float) -> float:
	var dx := maxf(0.0, absf(lx) - hx)
	var dy := maxf(0.0, absf(ly) - hy)
	return sqrt(dx * dx + dy * dy)


## Distance between a segment and the box [-hx, hx] x [-hy, hy], both in the
## box's frame. 0 when they overlap.
static func _segment_box(ax: float, ay: float, bx: float, by: float, hx: float, hy: float) -> float:
	# Overlap: clip the segment against the box (Liang-Barsky).
	var t0 := 0.0
	var t1 := 1.0
	var dx := bx - ax
	var dy := by - ay
	var p := [-dx, dx, -dy, dy]
	var q := [ax + hx, hx - ax, ay + hy, hy - ay]
	var inside := true
	for k in 4:
		if absf(p[k]) < 1e-12:
			if q[k] < 0.0:
				inside = false
				break
		else:
			var r: float = q[k] / p[k]
			if p[k] < 0.0:
				t0 = maxf(t0, r)
			else:
				t1 = minf(t1, r)
			if t0 > t1:
				inside = false
				break
	if inside:
		return 0.0
	var best := minf(_point_box(ax, ay, hx, hy), _point_box(bx, by, hx, hy))
	for corner in [Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)]:
		best = minf(best, _point_segment(corner.x, corner.y, ax, ay, bx, by).x)
	return best


## True when the drawn car (centre x, y, heading rot) touches the corridor on
## the stretch of the arrow between arc lengths s0 and s1.
func drawn_car_touches(x: float, y: float, rot: float, s0: float, s1: float) -> bool:
	var c := cos(rot)
	var sn := sin(rot)
	var reach := corridor_half + sqrt(DRAWN_HALF_LENGTH * DRAWN_HALF_LENGTH + DRAWN_HALF_WIDTH * DRAWN_HALF_WIDTH)
	var i0 := _segment_at(maxf(0.0, s0))
	var i1 := _segment_at(minf(length, s1))
	for i in range(i0, i1 + 1):
		var d := _point_segment(x, y, cx[i], cy[i], cx[i + 1], cy[i + 1]).x
		if d <= corridor_half:
			return true
		if d > reach:
			continue
		# Segment in the car's frame (x along the nose).
		var ax := (cx[i] - x) * c + (cy[i] - y) * sn
		var ay := -(cx[i] - x) * sn + (cy[i] - y) * c
		var bx := (cx[i + 1] - x) * c + (cy[i + 1] - y) * sn
		var by := -(cx[i + 1] - x) * sn + (cy[i + 1] - y) * c
		if _segment_box(ax, ay, bx, by, DRAWN_HALF_LENGTH, DRAWN_HALF_WIDTH) <= corridor_half:
			return true
	return false


## Index of the boulder the physics body touches, or -1.
func body_hits_boulder(x: float, y: float, rot: float) -> int:
	var c := cos(rot)
	var sn := sin(rot)
	for i in boulders.size():
		var b: Dictionary = boulders[i]
		var lx: float = (b.x - x) * c + (b.y - y) * sn
		var ly: float = -(b.x - x) * sn + (b.y - y) * c
		if _point_box(lx, ly, BODY_HALF, BODY_HALF) < b.r:
			return i
	return -1


## True when the physics body overlaps a building cell (separating axes).
func body_hits_building(x: float, y: float, rot: float) -> bool:
	if building_cells.is_empty():
		return false
	var c := cos(rot)
	var sn := sin(rot)
	var ext := BODY_HALF * (absf(c) + absf(sn))  # half-size of the body along x and y
	for cell in building_cells:
		if x + ext <= cell.x0 or x - ext >= cell.x1 or y + ext <= cell.y0 or y - ext >= cell.y1:
			continue
		# Body axes: project the cell onto them.
		var ccx: float = (cell.x0 + cell.x1) / 2.0 - x
		var ccy: float = (cell.y0 + cell.y1) / 2.0 - y
		var sep := false
		for axis in [Vector2(c, sn), Vector2(-sn, c)]:
			var centre := absf(ccx * axis.x + ccy * axis.y)
			var cell_ext := 0.5 * (absf(axis.x) + absf(axis.y))
			if centre >= BODY_HALF + cell_ext:
				sep = true
				break
		if not sep:
			return true
	return false


# --- Driving ----------------------------------------------------------------

## A fresh car with the game's handling values (plus any overrides).
func _new_car():
	var car = CarModel.new()
	for key in tuning_overrides:
		car.tuning.set(key, tuning_overrides[key])
	return car


## A fresh car placed at the arrow's start, nose along the arrow, moving at speed.
func make_car(speed: float):
	var car = _new_car()
	var start := point_at(0.0)
	var ahead := point_at(minf(length, 0.5))
	# Set the fields directly: the model keeps 64-bit floats, Vector2 is 32-bit.
	car.x = start.x
	car.y = start.y
	car.rotation = atan2(ahead.y - start.y, ahead.x - start.x)
	car.vx = cos(car.rotation) * speed
	car.vy = sin(car.rotation) * speed
	return car


## A copy of a car's whole driving state (the search tries several keys from
## the same moment). Shares the handling values, which never change mid-drive.
static func _clone_car(car):
	var c = CarModel.new()
	c.tuning = car.tuning
	c.dt = car.dt
	c.x = car.x
	c.y = car.y
	c.vx = car.vx
	c.vy = car.vy
	c.rotation = car.rotation
	c.drift_amount = car.drift_amount
	c.is_drifting = car.is_drifting
	c.set("_w_was_held", car.get("_w_was_held"))
	return c


static func _wrap(a: float) -> float:
	return fposmod(a + PI, TAU) - PI


## Keys, packed in one number: W, S, A, D.
const KEY_W := 1
const KEY_S := 2
const KEY_A := 4
const KEY_D := 8
## Every distinct set of keys a player can hold (S does nothing with W held).
const KEY_SETS := [KEY_W, KEY_W | KEY_A, KEY_W | KEY_D, 0, KEY_A, KEY_D, KEY_S, KEY_S | KEY_A, KEY_S | KEY_D]


static func _press(car, keys: int) -> void:
	var steer := 0.0
	if keys & KEY_A:
		steer += 1.0
	if keys & KEY_D:
		steer -= 1.0
	car.step(bool(keys & KEY_W), bool(keys & KEY_S), steer)


## Judges the car after a step. Returns [new progress, outcome, boulder]:
## outcome is "" (still going), "end" (reached the arrow's end), "boulder",
## "building" or "corridor".
func _judge(car, s: float) -> Array:
	var p: Vector2 = car.get_position()
	s = _update_progress(p, s)
	var hit := body_hits_boulder(p.x, p.y, car.rotation)
	if hit >= 0:
		return [s, "boulder", hit]
	if body_hits_building(p.x, p.y, car.rotation):
		return [s, "building", -1]
	if not drawn_car_touches(p.x, p.y, car.rotation, s - TOUCH_BEHIND, s + TOUCH_AHEAD):
		return [s, "corridor", -1]
	# The end: the car's centre has reached (or passed) the arrow's last point.
	if s >= length - 1e-6:
		return [s, "end", -1]
	return [s, "", -1]


static func _reason(kind: String, boulder: int) -> String:
	match kind:
		"boulder":
			return "the car hit boulder %d" % (boulder + 1)
		"building":
			return "the car hit a building"
		"corridor":
			return "the drawn car left the corridor"
		"stalled":
			return "the car stopped making progress"
		"timeout":
			return "the drive took longer than %d s" % int(MAX_SECONDS)
	return ""


## The path follower's keys for this step.
func _follower_keys(car, s: float, v_target: float, lookahead: float, counter_steer: float) -> int:
	var turn_step := deg_to_rad(car.tuning.turn_rate() * car.dt)
	var cruise: float = car.tuning.forward_speed
	var pos: Vector2 = car.get_position()
	var target := point_at(s + lookahead)
	var want := atan2(target.y - pos.y, target.x - pos.x)
	var speed: float = car.total_speed()
	var moving: float = atan2(car.vy, car.vx) if speed > 0.5 else car.rotation
	var correction := clampf(_wrap(want - moving) * counter_steer, -PI / 3.0, PI / 3.0)
	var err := _wrap(want + correction - car.rotation)
	var keys := 0
	if err > turn_step / 2.0:
		keys |= KEY_D  # rotation grows (clockwise on screen)
	elif err < -turn_step / 2.0:
		keys |= KEY_A
	var fwd: float = car.forward_speed()
	if fwd < v_target:
		# W snaps to cruise speed: below it, only press W when well under target.
		if v_target >= cruise or speed < 0.6 * v_target:
			keys |= KEY_W
	elif fwd > v_target + 1.0:
		keys |= KEY_S
	return keys


## Drives the arrow once with one path-follower setting. target_speed 0 = top
## speed. Returns {passed, reason, kind, boulder, progress, steps, settings,
## inputs} plus {line, speeds, headings} when record is true.
func drive(target_speed: float, lookahead: float, counter_steer: float, record := false) -> Dictionary:
	var probe = _new_car()
	var top: float = probe.tuning.top_speed()
	var v_target := top if target_speed <= 0.0 else minf(target_speed, top)
	var start_speed := minf(v_target, float(probe.tuning.forward_speed))
	return _run(start_speed, {"target_speed": v_target, "lookahead": lookahead, "counter_steer": counter_steer},
		PackedByteArray(), record)


## Drives the arrow again with recorded keys (one entry per physics step).
func replay(start_speed: float, inputs: PackedByteArray, settings: Dictionary, record := false) -> Dictionary:
	return _run(start_speed, settings, inputs, record)


func _run(start_speed: float, settings: Dictionary, inputs: PackedByteArray, record: bool) -> Dictionary:
	var follow := inputs.is_empty()
	var car = make_car(start_speed)
	var dt: float = car.dt
	var s := 0.0
	var line := PackedVector2Array()
	var speeds := PackedFloat64Array()
	var headings := PackedFloat64Array()
	var keys_used := PackedByteArray()
	var max_steps := int(MAX_SECONDS / dt) if follow else inputs.size()
	var stall_steps := int(STALL_SECONDS / dt)
	var stall_s := 0.0
	var stall_at := 0
	var result := {"passed": false, "reason": "", "kind": "", "boulder": -1,
		"progress": 0.0, "steps": 0, "start_speed": start_speed, "settings": settings}
	if record:
		line.append(car.get_position())
		speeds.append(car.total_speed())
		headings.append(car.rotation)
	for step_i in range(1, max_steps + 1):
		var keys: int
		if follow:
			keys = _follower_keys(car, s, settings.target_speed, settings.lookahead, settings.counter_steer)
		else:
			keys = inputs[step_i - 1]
		keys_used.append(keys)
		_press(car, keys)
		var j := _judge(car, s)
		s = j[0]
		result.progress = s
		result.steps = step_i
		if record:
			line.append(car.get_position())
			speeds.append(car.total_speed())
			headings.append(car.rotation)
		if j[1] == "end":
			result.passed = true
			break
		if j[1] != "":
			result.kind = j[1]
			result.boulder = j[2]
			break
		if s - stall_s >= STALL_PROGRESS:
			stall_s = s
			stall_at = step_i
		elif follow and step_i - stall_at > stall_steps:
			result.kind = "stalled"
			break
	if not result.passed and result.kind == "":
		result.kind = "stalled" if not follow else "timeout"
	result.reason = _reason(result.kind, result.boulder)
	result.inputs = keys_used
	if record:
		result.line = line
		result.speeds = speeds
		result.headings = headings
	return result


## New progress: the arc length of the closest centre-line point to p, searched
## only a little behind and ahead of the old progress, so a path that crosses
## itself is followed in order.
func _update_progress(p: Vector2, s: float) -> float:
	var i0 := _segment_at(maxf(0.0, s - PROGRESS_BEHIND))
	var i1 := _segment_at(minf(length, s + PROGRESS_AHEAD))
	var best_d := INF
	var best_s := s
	for i in range(i0, mini(i1 + 1, cx.size() - 1)):
		var r := _point_segment(p.x, p.y, cx[i], cy[i], cx[i + 1], cy[i + 1])
		if r.x < best_d - 1e-12:
			best_d = r.x
			best_s = cs[i] + (cs[i + 1] - cs[i]) * r.y
	last_offset = best_d
	return best_s


## The search, used when no path-follower setting drives the arrow. From a
## standstill on the arrow's start, it tries every set of keys, held for
## SEARCH_HOLD_STEPS physics steps, from each of the SEARCH_WIDTH most promising
## drives so far (furthest along the arrow and nearest its centre line, kept
## across a spread of positions, headings and speeds), until one reaches the end or none is left.
const SEARCH_HOLD_STEPS := 5
const SEARCH_WIDTH := 48
const SEARCH_SPEED_BANDS := [5.0, 10.0, 15.0]
## How much the search prefers drives that stay near the arrow's centre line:
## a drive's score is its progress minus this times its distance from the line.
const SEARCH_OFFSET_WEIGHT := 1.0


## Returns {passed, inputs, progress, kind, boulder}.
func search() -> Dictionary:
	var root := {"car": make_car(0.0), "s": 0.0, "inputs": PackedByteArray(), "order": 0, "score": 0.0}
	var beam: Array = [root]
	var furthest := {"progress": -1.0, "kind": "stalled", "boulder": -1, "inputs": PackedByteArray()}
	var round_seconds: float = root.car.dt * SEARCH_HOLD_STEPS
	var max_rounds := int(MAX_SECONDS / round_seconds)
	var stall_rounds := int(STALL_SECONDS / round_seconds)
	var best_s := 0.0
	var best_round := 0
	for round_i in max_rounds:
		var children: Array = []
		for node in beam:
			for keys in KEY_SETS:
				var c = _clone_car(node.car)
				var s: float = node.s
				var inputs: PackedByteArray = node.inputs.duplicate()
				var outcome := ""
				var boulder := -1
				for k in SEARCH_HOLD_STEPS:
					_press(c, keys)
					inputs.append(keys)
					var j := _judge(c, s)
					s = j[0]
					outcome = j[1]
					boulder = j[2]
					if outcome != "":
						break
				if outcome == "end":
					return {"passed": true, "inputs": inputs, "progress": s, "kind": "", "boulder": -1}
				if outcome != "":
					if s > furthest.progress + 1e-9:
						furthest = {"progress": s, "kind": outcome, "boulder": boulder, "inputs": inputs}
					continue
				children.append({"car": c, "s": s, "inputs": inputs, "order": children.size(),
					"score": s - SEARCH_OFFSET_WEIGHT * last_offset})
		if children.is_empty():
			break
		beam = _prune(children)
		var top_s := 0.0
		for n in beam:
			top_s = maxf(top_s, n.s)
		if top_s > best_s + STALL_PROGRESS:
			best_s = top_s
			best_round = round_i
		elif round_i - best_round > stall_rounds:
			break
	if not beam.is_empty() and beam[0].s > furthest.progress + 1e-9:
		furthest = {"progress": beam[0].s, "kind": "stalled", "boulder": -1, "inputs": beam[0].inputs}
	furthest.passed = false
	return furthest


static func _before(a: Dictionary, b: Dictionary) -> bool:
	if absf(a.score - b.score) > 1e-12:
		return a.score > b.score
	return a.order < b.order


## Keeps the most promising drives: the furthest one per small area, heading
## and speed; then the furthest few in each speed band; then the furthest
## overall, up to SEARCH_WIDTH. Ties go to the order the drives were made in,
## so the search is the same on every run.
func _prune(children: Array) -> Array:
	var by_cell := {}
	for n in children:
		var c = n.car
		var key := "%d,%d,%d,%d" % [floori(c.x / 0.3), floori(c.y / 0.3),
			floori(fposmod(c.rotation, TAU) / (PI / 12.0)), floori(c.total_speed() / 1.5)]
		if not by_cell.has(key) or _before(n, by_cell[key]):
			by_cell[key] = n
	var unique: Array = by_cell.values()
	unique.sort_custom(_before)
	var bands: Array = []
	for i in SEARCH_SPEED_BANDS.size() + 1:
		bands.append([])
	for n in unique:
		var v: float = n.car.total_speed()
		var band := 0
		while band < SEARCH_SPEED_BANDS.size() and v >= SEARCH_SPEED_BANDS[band]:
			band += 1
		bands[band].append(n)
	var per_band := SEARCH_WIDTH / bands.size()
	var kept: Array = []
	var taken := {}
	for band_nodes in bands:
		for i in mini(per_band, band_nodes.size()):
			kept.append(band_nodes[i])
			taken[band_nodes[i].order] = true
	for n in unique:
		if kept.size() >= SEARCH_WIDTH:
			break
		if not taken.has(n.order):
			kept.append(n)
	kept.sort_custom(_before)
	return kept


## Runs every path-follower setting and the search. Returns {passed, best,
## tried, w_held, length, where (on a fail)}: best is the quickest passing drive
## (fewest steps), or, when nothing passes, the drive that got furthest along
## the arrow, and carries the driven line. w_held is true when a path-follower
## setting at or above cruise speed passed, which means holding W the whole way.
func check() -> Dictionary:
	var best := {}
	var tried := 0
	var w_held := false
	var cruise: float = _new_car().tuning.forward_speed
	for v in TARGET_SPEEDS:
		for la in LOOKAHEADS:
			for k in COUNTER_STEERS:
				tried += 1
				var r := drive(v, la, k)
				if r.passed and r.settings.target_speed >= cruise:
					w_held = true
				if _better(r, best):
					best = r
	var found := search()
	var from_search := {"passed": found.passed, "progress": found.progress, "steps": found.inputs.size(),
		"start_speed": 0.0, "inputs": found.inputs, "settings": {"search": true}}
	if _better(from_search, best):
		best = from_search
	var full := replay(best.start_speed, best.inputs, best.settings, true)
	var out := {"passed": full.passed, "best": full, "tried": tried, "w_held": w_held, "length": length}
	if not full.passed:
		out.where = describe_place(full.progress)
	return out


## True when drive a is better than drive b: it passes and b does not, both
## pass and a is quicker, or neither passes and a got further.
static func _better(a: Dictionary, b: Dictionary) -> bool:
	if b.is_empty():
		return true
	if a.passed != b.passed:
		return a.passed
	if a.passed:
		return a.steps < b.steps
	return a.progress > b.progress + 1e-9


## Where along the arrow arc length s is, in words, plus the drawn curve's
## radius there.
func describe_place(s: float) -> Dictionary:
	var i := _segment_at(clampf(s, 0.0, length))
	var pi_ := c_point[i]
	var pts: Array = drawing.arrow.points
	var radius := INF
	for d in [-1.5, -0.75, 0.0, 0.75, 1.5]:
		radius = minf(radius, curve_radius_at(clampf(s + d, 0.0, length)))
	var pos := point_at(s)
	return {"progress": s, "point": pi_ + 1, "points": pts.size(),
		"point_x": float(pts[pi_][0]), "point_y": float(pts[pi_][1]),
		"x": pos.x, "y": pos.y, "radius": radius}


## One-line verdict for printing.
func summary(result: Dictionary, label: String) -> String:
	var b: Dictionary = result.best
	if result.passed:
		var speeds: PackedFloat64Array = b.speeds
		var total := 0.0
		var top := 0.0
		for v in speeds:
			total += v
			top = maxf(top, v)
		var secs := float(b.steps) * CarModel.new().dt
		return "PASS  %s: driven in %.2f s (%d physics steps), average speed %.1f, highest %.1f units/s (%s). With W held the whole way (path follower at cruise speed or faster): %s." % [
			label, secs, b.steps, total / speeds.size(), top, describe_driver(result), "passed" if result.w_held else "did not pass"]
	var w: Dictionary = result.where
	var radius_text := "a straight stretch" if w.radius == INF else "a drawn curve of radius %.1f units" % w.radius
	return "FAIL  %s: %s at %.1f of %.1f units along the arrow, near drawing point %d of %d (x %.1f, y %.1f), on %s. Neither the %d path-follower settings (target speeds 3 units/s to top speed) nor the search over key combinations got further (furthest drive: %s)." % [
		label, b.reason, w.progress, result.length, w.point, w.points, w.point_x, w.point_y, radius_text, result.tried, describe_driver(result)]


## Which driver made the saved drive, in words.
func describe_driver(result: Dictionary) -> String:
	var st: Dictionary = result.best.settings
	if st.has("search") and not result.passed:
		return "the search over key combinations"
	if st.has("search"):
		return "found by the search over key combinations, quicker than any of the %d path-follower settings" % result.tried
	return "path follower: target speed %.1f, look-ahead %.1f, counter-steer %.1f; %d settings tried" % [
		st.target_speed, st.lookahead, st.counter_steer, result.tried]


# --- Driven line output -------------------------------------------------------

## The driven line as JSON-ready data.
func driven_data(result: Dictionary, label: String) -> Dictionary:
	var b: Dictionary = result.best
	var pts := []
	var line: PackedVector2Array = b.line
	var speeds: PackedFloat64Array = b.speeds
	var headings: PackedFloat64Array = b.headings
	for i in line.size():
		pts.append([snappedf(line[i].x, 0.0001), snappedf(line[i].y, 0.0001),
			snappedf(speeds[i], 0.0001), snappedf(rad_to_deg(headings[i]), 0.01)])
	var probe = CarModel.new()
	var tuning := {}
	for entry in probe.tuning.SETTINGS:
		tuning[entry.key] = tuning_overrides.get(entry.key, probe.tuning.get(entry.key))
	return {
		"drawing": label,
		"made_by": "game/tools/check_challenge.gd (task T-021)",
		"passed": result.passed,
		"steps_per_second": roundi(1.0 / probe.dt),
		"steps": b.steps,
		"seconds": float(b.steps) * probe.dt,
		"driver": b.settings,
		"tuning": tuning,
		"columns": ["x", "y", "speed (units/s)", "heading (degrees, 0 = +x, clockwise)"],
		"line": pts,
	}


## SVG picture: the drawing (ground, boulders, corridor, arrow) at the same
## scale as its own picture, with the driven line and the drawn car every
## half second on top.
func driven_svg(result: Dictionary) -> String:
	const PX := 20.0
	var w := float(drawing.get("width", 24))
	var h := float(drawing.get("height", 24))
	var ox := w / 2.0
	var oy := h / 2.0
	var colours := {"R": "#5b5f68", "G": "#c9b48a", "B": "#4b3a8f", ".": "#f8f9fb"}
	var out := PackedStringArray()
	out.append('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">' % [w * PX, h * PX, w * PX, h * PX])
	var rows: Array = drawing.get("rows", [])
	for y in rows.size():
		var row: String = rows[y]
		var x := 0
		while x < row.length():
			var run := x
			while run < row.length() and row[run] == row[x]:
				run += 1
			out.append('<rect x="%d" y="%d" width="%d" height="%d" fill="%s"/>' % [x * PX, y * PX, (run - x) * PX, PX, colours.get(row[x], colours["."])])
			x = run
	for b in boulders:
		out.append('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#b4552c" stroke="#1b1d26"/>' % [(b.x + ox) * PX, (b.y + oy) * PX, b.r * PX])
	var d := PackedStringArray()
	for i in cx.size():
		d.append("%s%.1f,%.1f" % ["M" if i == 0 else "L", (cx[i] + ox) * PX, (cy[i] + oy) * PX])
	var path := " ".join(d)
	out.append('<path d="%s" fill="none" stroke="#c2186b" stroke-opacity="0.25" stroke-width="%.1f" stroke-linecap="round" stroke-linejoin="round"/>' % [path, corridor_half * 2.0 * PX])
	out.append('<path d="%s" fill="none" stroke="#c2186b" stroke-width="3.0" stroke-dasharray="6 6" stroke-linecap="round" stroke-linejoin="round"/>' % path)
	var b: Dictionary = result.best
	var line: PackedVector2Array = b.line
	var headings: PackedFloat64Array = b.headings
	# The drawn car every half second (25 physics steps), and at the end.
	var marks := range(0, line.size(), 25)
	if marks.is_empty() or marks[marks.size() - 1] != line.size() - 1:
		marks.append(line.size() - 1)
	for i in marks:
		out.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#ffd23f" fill-opacity="0.35" stroke="#1b1d26" stroke-width="1" transform="rotate(%.2f %.1f %.1f)"/>' % [
			(line[i].x + ox - DRAWN_HALF_LENGTH) * PX, (line[i].y + oy - DRAWN_HALF_WIDTH) * PX,
			DRAWN_HALF_LENGTH * 2.0 * PX, DRAWN_HALF_WIDTH * 2.0 * PX,
			rad_to_deg(headings[i]), (line[i].x + ox) * PX, (line[i].y + oy) * PX])
	var ld := PackedStringArray()
	for i in line.size():
		ld.append("%s%.1f,%.1f" % ["M" if i == 0 else "L", (line[i].x + ox) * PX, (line[i].y + oy) * PX])
	out.append('<path d="%s" fill="none" stroke="#2ee6d6" stroke-width="3.0" stroke-linecap="round" stroke-linejoin="round"/>' % " ".join(ld))
	out.append('<circle cx="%.1f" cy="%.1f" r="8.0" fill="#ffffff" stroke="#c2186b" stroke-width="2"/>' % [(cx[0] + ox) * PX, (cy[0] + oy) * PX])
	var n := cx.size()
	out.append('<circle cx="%.1f" cy="%.1f" r="6.0" fill="#c2186b"/>' % [(cx[n - 1] + ox) * PX, (cy[n - 1] + oy) * PX])
	out.append("</svg>")
	return "\n".join(out) + "\n"
