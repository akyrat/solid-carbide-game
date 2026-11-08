extends RefCounted
## The car points where it goes (task T-583; Drifting, Decisions, "The car points where it goes";
## game/docs/driving/facing.md). Node-free and static.
##
## Fix A, the frame remap: the car's sheets were drawn so frame i shows world heading i * step_deg,
## but some drawings point elsewhere on screen (T-580: frames 21 to 23 all point straight up). With
## data/car_facing.json frame_remap on, a heading is drawn with the frame whose drawing points
## closest, on screen, to where that heading points in the run's 2:1 projection; each frame's
## drawn angle is its sheet JSON's `seen_nose_screen_angle_deg_approx` (measured; refresh it with
## game/tools/measure_car_facing.py after a redraw). A sheet without those angles (the flat
## placeholder) keeps frame = heading / step_deg. The shadowless and tilt sheets share the normal
## sheet's direction columns, so they follow the same frame.
##
## Fix C (the straight grip: more grip with W held outside a drift) is read here too; car_tuning.gd
## holds it and car_model.gd sideways_grip applies it.

const DATA_PATH := "res://data/car_facing.json"
const DEFAULTS := {"frame_remap": true, "straight_grip_on": true, "straight_grip": 0.9}
## The run's projection (run.gd ISO_TRANSFORM): screen = (x - y, (x + y) / 2).
const ISO := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)

static var _config := {}
## Set by tests and the T-580 probe to compare combinations; null = the data file's value.
static var remap_override = null


## The data file's values over DEFAULTS (read once).
static func config() -> Dictionary:
	if _config.is_empty():
		_config = DEFAULTS.duplicate()
		if FileAccess.file_exists(DATA_PATH):
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
			if typeof(parsed) == TYPE_DICTIONARY:
				for k in DEFAULTS:
					if parsed.has(k):
						_config[k] = parsed[k]
	return _config


static func remap_on() -> bool:
	if remap_override != null:
		return bool(remap_override)
	return bool(config().frame_remap)


## Screen angle (degrees, 0 = screen right, clockwise) of world heading `rot` (radians).
static func screen_angle(rot: float) -> float:
	var s := ISO.basis_xform(Vector2(cos(rot), sin(rot)))
	return fposmod(rad_to_deg(atan2(s.y, s.x)), 360.0)


static func wrap180(a: float) -> float:
	return fposmod(a + 180.0, 360.0) - 180.0


## The frame by index alone: round(heading / step) (the sheets' own convention).
static func index_frame(rot: float, layout: Dictionary) -> int:
	var step := deg_to_rad(float(layout.get("step_deg", 22.5)))
	var count := int(layout.get("frame_count", 16))
	var start := deg_to_rad(float(layout.get("frame0_heading_deg", 0.0)))
	return posmod(roundi((rot - start) / step), count)


## The drawn screen angle of each frame of `layout`, or [] when the sheet has none recorded.
static func drawn_angles(layout: Dictionary) -> Array:
	var frames = layout.get("frames", [])
	if typeof(frames) != TYPE_ARRAY or frames.is_empty():
		return []
	var out := []
	for f in frames:
		if typeof(f) != TYPE_DICTIONARY or not f.has("seen_nose_screen_angle_deg_approx"):
			return []
		out.append(float(f.seen_nose_screen_angle_deg_approx))
	return out


## The frame whose drawing points closest on screen to heading `rot` (radians). Ties go to the
## frame nearest by index.
static func remapped_frame(rot: float, angles: Array, layout: Dictionary) -> int:
	var target := screen_angle(rot)
	var by_index := index_frame(rot, layout)
	var count := angles.size()
	var best := by_index
	var best_cost := INF
	for i in count:
		var cost := absf(wrap180(float(angles[i]) - target))
		var d := absi(i - by_index)
		cost += 1e-4 * float(mini(d, count - d))
		if cost < best_cost:
			best_cost = cost
			best = i
	return best


## The frame car_sprite.gd (and the rail snap's outline) draws for heading `rot`.
static func frame_for(rot: float, layout: Dictionary, angles: Array = []) -> int:
	if remap_on():
		if angles.is_empty():
			angles = drawn_angles(layout)
		if angles.size() == int(layout.get("frame_count", angles.size())) and not angles.is_empty():
			return remapped_frame(rot, angles, layout)
	return index_frame(rot, layout)
