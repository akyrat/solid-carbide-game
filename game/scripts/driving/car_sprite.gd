extends Sprite2D
## Draws the car from a 16-direction sprite sheet, picking the frame closest to
## the car's heading. The layout (frame size, frame count, step, centre pixel,
## pixels per unit) is read from the JSON file next to each sheet, so the full
## pixel-art sheets (task T-014) drop in with no code change.

const SHEETS := {
	"flat": "res://art/placeholders/car/car_flat",
	"iso": "res://art/placeholders/car/car_iso",
}

var layout := {}
var sheet := ""
## World pixels per unit of the drawing (the flat world's scale).
var world_px_per_unit := 16.0


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
	offset = frame_size / 2.0 - center
	var s := world_px_per_unit / float(layout.get("px_per_unit", world_px_per_unit))
	scale = Vector2(s, s)


## Frame index for a car rotation (radians, nose along +x at 0, clockwise).
func frame_for_rotation(rot: float) -> int:
	var step := deg_to_rad(float(layout.get("step_deg", 22.5)))
	var count := int(layout.get("frame_count", 16))
	var start := deg_to_rad(float(layout.get("frame0_heading_deg", 0.0)))
	return posmod(roundi((rot - start) / step), count)


func set_heading(rot: float) -> void:
	frame = frame_for_rotation(rot)
