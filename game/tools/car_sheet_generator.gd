extends RefCounted
## Draws the placeholder car sprite sheets (task T-013): a plain rectangle with a
## differently coloured nose, in 16 directions, for the flat top-down view and the
## isometric view. No PixelLab: every pixel is computed here, so the output is the
## same on every run.
##
## Used by tools/generate_car_sheets.gd (writes the files) and by the GUT tests.
##
## Layout convention (also written to the JSON file next to each sheet):
## - One row of 16 frames, each FRAME x FRAME pixels, frame i at x = i * FRAME.
## - Frames are indexed by the car's heading in the flat physics world (Godot axes,
##   y down). Frame 0: heading 0 degrees, nose pointing +x (screen right in the flat
##   view). Each next frame adds 22.5 degrees, turning clockwise on screen, the same
##   way Godot's `rotation` grows. So for a nose-right car body:
##   frame = posmod(roundi(rotation / deg_to_rad(22.5)), 16), in both views.
## - The isometric sheet shows the same world heading projected with the standard
##   2:1 isometric projection screen = (x - y, (x + y) / 2), so on screen its nose
##   angles are not evenly spaced, but its world headings are.
## - The car's centre is the point CENTER (frame pixel coordinates, top-left of the
##   frame = (0, 0)), which is the middle of the frame: a Sprite2D with
##   `centered = true` and no offset puts the car's centre on the node's origin.

const FRAME := 64
const DIRECTIONS := 16
const STEP_DEG := 22.5
const CENTER := Vector2(32.0, 32.0)

## Car footprint in world pixels (length along the nose x width across it).
const LENGTH := 32.0
const WIDTH := 16.0
## How far back from the front edge the nose patch reaches.
const NOSE_LENGTH := 8.0

const BODY_COLOR := Color8(46, 134, 255)  # 2e86ff
const NOSE_COLOR := Color8(255, 230, 0)  # ffe600

const VIEWS := ["flat", "iso"]


## World heading of a frame, in degrees.
static func heading_deg(frame: int) -> float:
	return frame * STEP_DEG


## Unit vector of the car's nose in the flat world for a frame.
static func nose_world(frame: int) -> Vector2:
	return Vector2.from_angle(deg_to_rad(heading_deg(frame)))


## World offset (from the car's centre) to screen offset, for a view.
static func project(view: String, world: Vector2) -> Vector2:
	if view == "iso":
		return Vector2(world.x - world.y, (world.x + world.y) * 0.5)
	return world


## Screen offset back to world offset, for a view.
static func unproject(view: String, screen: Vector2) -> Vector2:
	if view == "iso":
		return Vector2((screen.x + 2.0 * screen.y) * 0.5, (2.0 * screen.y - screen.x) * 0.5)
	return screen


## Screen angle of the nose for a frame, in degrees (0 = right, clockwise, 0..360).
static func nose_screen_angle_deg(view: String, frame: int) -> float:
	var screen := project(view, nose_world(frame))
	return fposmod(rad_to_deg(screen.angle()), 360.0)


## Draws one sheet: DIRECTIONS frames in one row, transparent background.
static func build_sheet(view: String) -> Image:
	assert(view in VIEWS, "unknown view %s" % view)
	var image := Image.create(FRAME * DIRECTIONS, FRAME, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for frame in DIRECTIONS:
		_draw_frame(image, view, frame)
	return image


static func _draw_frame(image: Image, view: String, frame: int) -> void:
	var forward := nose_world(frame)
	var right := forward.orthogonal() * -1.0  # forward rotated +90 degrees (clockwise on screen)
	var half_length := LENGTH * 0.5
	var half_width := WIDTH * 0.5
	var origin_x := frame * FRAME
	for y in FRAME:
		for x in FRAME:
			# Sample at the pixel's centre, relative to the car's centre.
			var screen := Vector2(x + 0.5, y + 0.5) - CENTER
			var world := unproject(view, screen)
			var along := world.dot(forward)
			var across := world.dot(right)
			if absf(along) > half_length or absf(across) > half_width:
				continue
			var color := NOSE_COLOR if along > half_length - NOSE_LENGTH else BODY_COLOR
			image.set_pixel(origin_x + x, y, color)


## The layout and record written as JSON next to a sheet.
static func describe(view: String, png_file: String, command: String) -> Dictionary:
	var frames: Array = []
	for frame in DIRECTIONS:
		frames.append({
			"index": frame,
			"heading_deg": heading_deg(frame),
			"nose_screen_angle_deg": snappedf(nose_screen_angle_deg(view, frame), 0.01),
		})
	var projection := "flat top-down: screen = world (1 world pixel = 1 sprite pixel)"
	if view == "iso":
		projection = "2:1 isometric: screen = (x - y, (x + y) / 2), world pixels, no box height"
	return {
		"file": png_file,
		"view": view,
		"placeholder": true,
		"frame_width": FRAME,
		"frame_height": FRAME,
		"frame_count": DIRECTIONS,
		"columns": DIRECTIONS,
		"rows": 1,
		"step_deg": STEP_DEG,
		"frame0_heading_deg": 0.0,
		"frame0_faces": "world heading 0 degrees, nose along world +x: %s" % (
			"drawn pointing down-right on screen (2:1 isometric, 26.57 degrees below the horizontal)"
			if view == "iso" else "drawn pointing right on screen"),
		"order": "clockwise on screen: frame i shows world heading i * 22.5 degrees, Godot axes (y down), the same direction Godot's rotation grows",
		"frame_from_rotation": "posmod(roundi(rotation / deg_to_rad(22.5)), 16) for a car body whose nose is +x at rotation 0; the same formula for both views",
		"center_px": {"x": CENTER.x, "y": CENTER.y},
		"center_note": "point in frame pixel coordinates (top-left of the frame = 0, 0) where the car's centre sits; it is the frame's middle, so a Sprite2D with centered = true and no offset lines it up",
		"projection": projection,
		"frames": frames,
		"record": {
			"made_by": "script (no PixelLab, no prompt)",
			"script": "game/tools/car_sheet_generator.gd (drawing), game/tools/generate_car_sheets.gd (writes the files)",
			"command": command,
			"task": "T-013",
			"settings": {
				"car_length_px": LENGTH,
				"car_width_px": WIDTH,
				"nose_length_px": NOSE_LENGTH,
				"body_color": "#" + BODY_COLOR.to_html(false),
				"nose_color": "#" + NOSE_COLOR.to_html(false),
				"sampling": "pixel centre inside the rectangle, no anti-aliasing, no outline, no shading",
			},
			"resources_consulted": [
				"tasks/T-013-placeholder-car-sprites.md",
				"docs/visual-style.md",
				"docs/drifting.md",
				"docs/drifting/unity-prototype-report.md",
				"C:/solid-carbide-prototype-drifting/tools/generate_car_sheet.gd (read-only, for the approach)",
			],
			"notes": "Placeholder until the full car art (T-014), which uses the same layout. Deterministic: running the generator again gives byte-identical files, so no generation time is stored.",
		},
	}


## JSON text for describe(), stable across runs (sorted keys, tab indent, trailing newline).
static func describe_json(view: String, png_file: String, command: String) -> String:
	return JSON.stringify(describe(view, png_file, command), "\t", true) + "\n"
