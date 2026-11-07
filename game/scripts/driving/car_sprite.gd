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

## While the car is in the air (task T-205; Drifting, Decisions, "No sprite
## shadow in the air") the isometric view draws it from the shadowless sheet
## (T-204), so only the round shadow on the ground shows. Same layout, same
## frames; the flat view has none. Only scenes with a ground-height source ever
## call set_in_air(true): the run and the drift prototype never do.
const AIR_SHEETS := {
	"iso": "res://art/car/car_iso_noshadow",
}

## The tilt (task T-551; Drifting, Decisions, "The grind overhaul"): Space held in the air tilts
## the car through 3 frames (car_tilt.gd). The hook: set_tilt_step(step) with step 0 (normal) to 3
## (the held pose). When the tilt sheet below exists for the view (T-555's art), steps 1 to 3 draw
## from it: same frame size, centre pixel and px_per_unit as the normal sheet, `columns` = the
## normal sheet's direction count (frame_count), one row per step (row 0 = step 1, row 2 = the held
## pose), drawn without the sprite's drop shadow (the tilt happens in the air and on a rail), and
## its own JSON beside it (the same fields; "rows": 3). Until it exists, the placeholder: the normal
## frame sheared and squashed in code (TILT_PLACEHOLDER_*), more with each step.
const TILT_SHEETS := {
	"iso": "res://art/car/car_iso_tilt",
}
## The placeholder's shear (radians) and vertical squash at the held pose; steps 1 and 2 a third and
## two thirds of it. Only a stand-in for T-555's art: the drawing looks rolled, its top side
## slid right and down a little.
const TILT_PLACEHOLDER_SKEW := 0.5
const TILT_PLACEHOLDER_SQUASH := 0.12

var layout := {}
var sheet := ""
var in_air := false
## The tilt frame shown (0 normal, 1 to 3; set_tilt_step).
var tilt_step := 0
## True when the tilt art (TILT_SHEETS) is in use for this view; false: the placeholder.
var has_tilt_art := false
var _ground_texture: Texture2D
var _air_texture: Texture2D
var _tilt_texture: Texture2D
var _tilt_columns := 0
var _normal_hframes := 1
var _normal_vframes := 1
## The direction frame for the heading (frame_for_rotation), kept for the tilt sheet.
var _dir_frame := 0
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
	_ground_texture = load(base + ".png")
	_air_texture = load(AIR_SHEETS[view] + ".png") if AIR_SHEETS.has(view) else null
	_load_tilt_sheet(view)
	in_air = false
	texture = _ground_texture
	hframes = int(layout.get("columns", layout.frame_count))
	vframes = int(layout.get("rows", 1))
	_normal_hframes = hframes
	_normal_vframes = vframes
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
	Perf.begin(&"car.sprite")
	if _shake_left <= 0.0:
		Perf.end(&"car.sprite")
		return
	_shake_left = maxf(_shake_left - delta, 0.0)
	var k := _shake_left / SHAKE_SECONDS
	var t := SHAKE_SECONDS - _shake_left
	var px := Vector2(sin(t * TAU * SHAKE_HZ), cos(t * TAU * SHAKE_HZ * 0.5) * 0.5) * SHAKE_PIXELS * k
	offset = _base_offset + (px / scale.x if scale.x != 0.0 else px)
	Perf.end(&"car.sprite")


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
	_apply_tilt_look()


## True when the car's height is above the ground under it.
static func is_in_air(height_units: float, ground_under_units: float) -> bool:
	return height_units > ground_under_units + 0.0001


## Switches between the normal sheet (on the ground) and the shadowless one (in
## the air). The frame stays the same: both sheets share one layout.
func set_in_air(value: bool) -> void:
	in_air = value
	_refresh_texture()


## The texture and frame for the air state, the tilt step and the direction.
func _refresh_texture() -> void:
	if _ground_texture == null:
		return
	if tilt_step > 0 and has_tilt_art:
		texture = _tilt_texture
		hframes = _tilt_columns
		vframes = 3
		frame = tilt_frame_index(_dir_frame, tilt_step, _tilt_columns)
		return
	texture = _air_texture if (in_air and _air_texture != null) else _ground_texture
	hframes = _normal_hframes
	vframes = _normal_vframes
	frame = _dir_frame


## T-551: the tilt sheet's frame for direction frame `dir_frame` at tilt step 1 to 3 (row step - 1).
static func tilt_frame_index(dir_frame: int, step: int, columns: int) -> int:
	return (clampi(step, 1, 3) - 1) * columns + dir_frame


## T-551, the tilt's hook (T-555 swaps its art in through TILT_SHEETS): shows tilt step 0 (normal)
## to 3 (the held pose) for the current direction.
func set_tilt_step(step: int) -> void:
	step = clampi(step, 0, 3)
	if step == tilt_step:
		return
	tilt_step = step
	_refresh_texture()
	_apply_tilt_look()


## The placeholder's shear and squash for tilt_step (none with the tilt art, or at step 0).
func _apply_tilt_look() -> void:
	var k := 0.0 if has_tilt_art else float(tilt_step) / 3.0
	skew = TILT_PLACEHOLDER_SKEW * k
	scale = Vector2(_base_scale.x, _base_scale.y * (1.0 - TILT_PLACEHOLDER_SQUASH * k))


func _load_tilt_sheet(view: String) -> void:
	has_tilt_art = false
	_tilt_texture = null
	if not TILT_SHEETS.has(view):
		return
	var base: String = TILT_SHEETS[view]
	if not ResourceLoader.exists(base + ".png") or not FileAccess.file_exists(base + ".json"):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(base + ".json"))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_tilt_texture = load(base + ".png")
	_tilt_columns = int(parsed.get("columns", layout.get("frame_count", 16)))
	has_tilt_art = _tilt_texture != null


## Frame index for a car rotation (radians, nose along +x at 0, clockwise).
func frame_for_rotation(rot: float) -> int:
	var step := deg_to_rad(float(layout.get("step_deg", 22.5)))
	var count := int(layout.get("frame_count", 16))
	var start := deg_to_rad(float(layout.get("frame0_heading_deg", 0.0)))
	return posmod(roundi((rot - start) / step), count)


func set_heading(rot: float) -> void:
	_dir_frame = frame_for_rotation(rot)
	if tilt_step > 0 and has_tilt_art:
		frame = tilt_frame_index(_dir_frame, tilt_step, _tilt_columns)
	else:
		frame = _dir_frame
