extends Sprite2D
## Draws the car from a 16-direction sprite sheet, picking the frame closest to
## the car's heading. The layout (frame size, frame count, step, centre pixel,
## pixels per unit) is read from the JSON file next to each sheet, so the full
## pixel-art sheets drop in with no code change.
##
## The isometric view uses the final pixel-art car (task T-101, 128 x 128
## frames, scaled to the world from its px_per_unit); the flat view keeps the
## placeholder (Visual style, Decisions: the final car is drawn for the
## isometric view only).

const SHEETS := {
	"flat": "res://art/placeholders/car/car_flat",
	"iso": "res://art/car/car_iso",
}

var layout := {}
var sheet := ""
## World pixels per unit of the drawing (the flat world's scale).
var world_px_per_unit := 16.0

## The damage shake (T-072; board: "a short shake or wobble of the car"): it only moves
## the drawing, through `offset`, never the node's position, the car's physics or the camera.
const SHAKE_SECONDS := 0.2
const SHAKE_PIXELS := 3.0  ## screen pixels at the start; it dies down to 0
const SHAKE_HZ := 20.0
var _base_offset := Vector2.ZERO
var _shake_left := 0.0

var _base_scale := Vector2.ONE


func _init() -> void:
	centered = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## Switches to the "flat" or "iso" sheet.
func use_sheet(view: String) -> void:
	if view == sheet:
		return
	var base: String = SHEETS[view]
	var text := FileAccess.get_file_as_string(base + ".json")
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("car_sprite.gd: could not read %s.json" % base)
		return
	layout = parsed
	sheet = view
	texture = load(base + ".png")
	hframes = int(layout.get("columns", layout.frame_count))
	vframes = int(layout.get("rows", 1))
	var frame_size := Vector2(float(layout.frame_width), float(layout.frame_height))
	var center := Vector2(float(layout.center_px.x), float(layout.center_px.y))
	# Put the car's centre pixel on the node's origin.
	_base_offset = frame_size / 2.0 - center
	offset = _base_offset
	var s := world_px_per_unit / float(layout.get("px_per_unit", world_px_per_unit))
	_base_scale = Vector2(s, s)
	scale = _base_scale


## Starts the damage shake (restarts it if one is running). Runs in _process, so pausing stops it.
func shake() -> void:
	_shake_left = SHAKE_SECONDS


func is_shaking() -> bool:
	return _shake_left > 0.0


func _process(delta: float) -> void:
	if _shake_left <= 0.0:
		return
	_shake_left = maxf(_shake_left - delta, 0.0)
	var k := _shake_left / SHAKE_SECONDS
	var t := SHAKE_SECONDS - _shake_left
	var px := Vector2(sin(t * TAU * SHAKE_HZ), cos(t * TAU * SHAKE_HZ * 0.5) * 0.5) * SHAKE_PIXELS * k
	offset = _base_offset + (px / scale.x if scale.x != 0.0 else px)


## The lift of the drawing for a height above the ground (task T-185;
## Drifting, Decisions, "Elevation"): straight up the screen, px_per_unit
## pixels per unit of height (16, the rest of the drawing's scale). The same in
## the flat and the isometric view: height is always drawn up the screen.
static func lift_for_height(height_units: float, px_per_unit: float = 16.0) -> Vector2:
	return Vector2(0.0, -height_units * px_per_unit)


## Places the drawing at the car's drawn map position (on the ground, height
## 0), lifted up the screen by the car's height (lift_for_height). The lift is
## part of the node's position, so physics interpolation smooths it too. The
## drawing's scale is the sheet's own at every height (task T-192).
func place(drawn_ground_px: Vector2, height_units: float) -> void:
	position = drawn_ground_px + lift_for_height(height_units, world_px_per_unit)
	scale = _base_scale


## Frame index for a car rotation (radians, nose along +x at 0, clockwise).
func frame_for_rotation(rot: float) -> int:
	var step := deg_to_rad(float(layout.get("step_deg", 22.5)))
	var count := int(layout.get("frame_count", 16))
	var start := deg_to_rad(float(layout.get("frame0_heading_deg", 0.0)))
	return posmod(roundi((rot - start) / step), count)


func set_heading(rot: float) -> void:
	frame = frame_for_rotation(rot)
