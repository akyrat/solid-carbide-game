class_name GridGround
extends RefCounted
## A level's grid ground (task T-560; Level design, Decisions, "The practice playground"): the
## drift prototype's dark purple ground with its grid (ground_grid.gd's colours) drawn over the whole
## map instead of the road and gravel tiles. A level file asks for it with a "ground_style":
##   {"kind": "grid", "ground_color": [r, g, b], "minor_color": [r, g, b],
##    "major_color": [r, g, b], "major_every": 5}
## (colours 0 to 1; any key left out takes the drift prototype's value). A file without it, or with
## another kind, keeps the usual ground (LevelGround). mvp_map.gd reads it once (grid_style) and its
## ground node calls draw(); the level creator keeps the key when it saves.

const KIND := "grid"
## The drift prototype's colours (ground_grid.gd).
const GROUND_COLOR := Color(0.07, 0.07, 0.14)
const MINOR_COLOR := Color(0.17, 0.17, 0.30)
const MAJOR_COLOR := Color(0.33, 0.30, 0.52)
const MAJOR_EVERY := 5


static func _colour(style: Dictionary, key: String, fallback: Color) -> Color:
	var c = style.get(key)
	if c is Array and c.size() >= 3:
		return Color(float(c[0]), float(c[1]), float(c[2]))
	return fallback


## The grid style of a level: {ground_color, minor_color, major_color, major_every} (Colors and an
## int), or {} when the level has no grid ground.
static func of(level: Dictionary) -> Dictionary:
	var s = level.get("ground_style")
	if not (s is Dictionary and str(s.get("kind", "")) == KIND):
		return {}
	return {
		"ground_color": _colour(s, "ground_color", GROUND_COLOR),
		"minor_color": _colour(s, "minor_color", MINOR_COLOR),
		"major_color": _colour(s, "major_color", MAJOR_COLOR),
		"major_every": maxi(1, int(s.get("major_every", MAJOR_EVERY))),
	}


## Draws the grid over `map_rect` (units) on `canvas`, in flat world pixels (`px_per_unit` each): the
## ground colour, a thin line every unit and a stronger one every major_every units counted from the
## map's centre, as ground_grid.gd does from the origin.
static func draw(canvas: CanvasItem, style: Dictionary, map_rect: Rect2, px_per_unit: float) -> void:
	var u := px_per_unit
	canvas.draw_rect(Rect2(map_rect.position * u, map_rect.size * u), style.ground_color)
	var every: int = style.major_every
	var minor := PackedVector2Array()
	var major := PackedVector2Array()
	var x0 := map_rect.position.x
	var y0 := map_rect.position.y
	var x1 := map_rect.end.x
	var y1 := map_rect.end.y
	for gx in range(int(ceilf(x0)), int(floorf(x1)) + 1):
		var line := PackedVector2Array([Vector2(gx, y0) * u, Vector2(gx, y1) * u])
		if posmod(gx, every) == 0:
			major.append_array(line)
		else:
			minor.append_array(line)
	for gy in range(int(ceilf(y0)), int(floorf(y1)) + 1):
		var line := PackedVector2Array([Vector2(x0, gy) * u, Vector2(x1, gy) * u])
		if posmod(gy, every) == 0:
			major.append_array(line)
		else:
			minor.append_array(line)
	canvas.draw_multiline(minor, style.minor_color, 1.0)
	canvas.draw_multiline(major, style.major_color, 2.0)
