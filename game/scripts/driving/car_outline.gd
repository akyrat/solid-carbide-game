extends RefCounted
## The car's drawing on screen, for the rail snap (task T-566; Drifting, Decisions, "A grind starts
## when the car's drawing crosses the rail's"; how it is measured: Drifting, Content, "The rail snap
## on the drawing (task T-566)").
##
## The shape is the car's own pixels as drawn: for each frame of the sheets the car is drawn from in
## the air (the shadowless sheet at tilt step 0, the tilt sheet's rows at steps 1 to 3), each pixel
## row from its leftmost to its rightmost opaque pixel (art/car/car_iso_outline.json, built from the
## PNGs by tools/build_car_outline.py). The empty corners of the frame never count, so a rail the
## car only seems near is not caught.
##
## Screen pixels are the map view's, as the rails' drawing (rail_drawing.gd screen_of): a point at
## map units u and height h is ISO * (u * 16) lifted 16 px per unit of height. The car's frame is
## drawn with its centre pixel on the car's point, at 16 / px_per_unit (0.5) screen px per frame px
## (car_sprite.gd). Node-free and static: the file is read once.

const OUTLINE_FILE := "res://art/car/car_iso_outline.json"
## The map view's projection and scale (mvp_map.gd ISO_TRANSFORM and PX_PER_UNIT; a test checks
## they match rail_drawing.gd's screen_of).
const ISO := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
const PX_PER_UNIT := 16.0
const KEYS := ["air", "tilt1", "tilt2", "tilt3"]

static var _data := {}


## The screen pixel of map point `u` (units) at height `h` (units).
static func screen_of(u: Vector2, h: float) -> Vector2:
	return ISO * (u * PX_PER_UNIT) + Vector2(0.0, -h * PX_PER_UNIT)


## The outline's data (read on first use; {} when the file is missing).
static func data() -> Dictionary:
	if _data.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(OUTLINE_FILE))
		if typeof(parsed) == TYPE_DICTIONARY:
			_data = parsed
	return _data


## The direction frame for a car heading (radians), as car_sprite.gd frame_for_rotation.
static func frame_for(rotation: float) -> int:
	var d := data()
	var count := int(d.get("frame_count", 32))
	var start := deg_to_rad(float(d.get("frame0_heading_deg", 0.0)))
	return posmod(roundi((rotation - start) / (TAU / float(count))), count)


## The frame's spans [row, left, right, ...] (frame pixels) at tilt step 0 to 3.
static func spans(rotation: float, tilt_step: int) -> Array:
	var d := data()
	if d.is_empty():
		return []
	var frames: Array = d.sheets[KEYS[clampi(tilt_step, 0, 3)]]
	return frames[frame_for(rotation)]


## Screen px per frame px (0.5 for the 32 px-per-unit art).
static func scale() -> float:
	return PX_PER_UNIT / float(data().get("px_per_unit", PX_PER_UNIT))


## The screen rectangles of the car's drawing at screen point `at` (one per pixel row).
static func rects(at: Vector2, rotation: float, tilt_step: int) -> Array:
	var d := data()
	var out: Array = []
	if d.is_empty():
		return out
	var k := scale()
	var c := Vector2(float(d.center_px.x), float(d.center_px.y))
	var sp := spans(rotation, tilt_step)
	for i in range(0, sp.size(), 3):
		var top_left := at + (Vector2(float(sp[i + 1]), float(sp[i])) - c) * k
		out.append(Rect2(top_left, Vector2(float(sp[i + 2]) - float(sp[i + 1]) + 1.0, 1.0) * k))
	return out


## The bounding box of the car's drawing at screen point `at`.
static func bounds(at: Vector2, rotation: float, tilt_step: int) -> Rect2:
	var rs := rects(at, rotation, tilt_step)
	if rs.is_empty():
		return Rect2(at, Vector2.ZERO)
	var box: Rect2 = rs[0]
	for r in rs:
		box = box.merge(r)
	return box


## True when the segment a-b (screen px), `half_width` px thick on either side, crosses the car's
## drawing at screen point `at`.
static func touches_segment(at: Vector2, rotation: float, tilt_step: int, a: Vector2, b: Vector2,
		half_width: float) -> bool:
	var rs := rects(at, rotation, tilt_step)
	if rs.is_empty():
		return false
	var box: Rect2 = rs[0]
	for r in rs:
		box = box.merge(r)
	if not segment_hits_rect(a, b, box.grow(half_width)):
		return false
	for r in rs:
		if segment_hits_rect(a, b, (r as Rect2).grow(half_width)):
			return true
	return false


## True when the segment a-b meets the rectangle (Liang-Barsky clipping).
static func segment_hits_rect(a: Vector2, b: Vector2, r: Rect2) -> bool:
	var d := b - a
	var t0 := 0.0
	var t1 := 1.0
	var p := [-d.x, d.x, -d.y, d.y]
	var q := [a.x - r.position.x, r.end.x - a.x, a.y - r.position.y, r.end.y - a.y]
	for i in 4:
		if absf(p[i]) < 1e-12:
			if q[i] < 0.0:
				return false
			continue
		var t: float = q[i] / p[i]
		if p[i] < 0.0:
			t0 = maxf(t0, t)
		else:
			t1 = minf(t1, t)
		if t0 > t1:
			return false
	return true
