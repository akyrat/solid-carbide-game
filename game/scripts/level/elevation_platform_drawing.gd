extends Node2D
## Placeholder drawing of one raised area of the elevation test scene (task
## T-185): a platform or a ramp from GroundHeight (ground_height.gd), drawn by
## script in the view's projection. Flat-coloured top face with a unit grid on
## it, the two side faces the isometric view shows (east, x = the rectangle's
## end, and south, y = its end), and light edges. No PixelLab art, no
## semi-transparent pixels, no Redgull red. Every colour is a proposal.
##
## Positions: the node sits at the drawn origin; it draws in drawn pixels,
## PX_PER_UNIT per unit, with heights lifted straight up the screen (as the
## car's drawing, car_sprite.gd, lift_for_height).
##
## Depth order (is_behind): the scene gives each area its own z_index and puts
## the car and its shadow just under the first area they are behind.
##
## See-through (task T-191; Level design, Decisions, "Raised areas turn
## see-through like buildings"): while the area covers the car on screen (the
## car is behind it, is_behind, and the car's drawn shape overlaps the area's
## silhouette), the whole area fades to the map buildings' SEE_THROUGH_ALPHA
## (15%) over their SEE_THROUGH_FADE_TIME (0.15 s), and back when it no longer
## covers it. The numbers are mvp_map.gd's, the fade step is map_building.gd's
## (faded_alpha) and the car's shape is mvp_map.gd's (car_screen_shape_at):
## shared, not copied. Only modulate.a changes, so the art sprite fades with it.

const MapBuildingScript := preload("res://scripts/level/map_building.gd")
const MvpMapScript := preload("res://scripts/level/mvp_map.gd")

const PX_PER_UNIT := 16.0

const TOP_COLOR := Color(0.40, 0.42, 0.50)
const TOP_GRID_COLOR := Color(0.34, 0.36, 0.44)
const RAMP_TOP_COLOR := Color(0.48, 0.45, 0.34)
const RAMP_GRID_COLOR := Color(0.41, 0.38, 0.28)
const EAST_COLOR := Color(0.27, 0.28, 0.35)
const SOUTH_COLOR := Color(0.19, 0.20, 0.26)
const EDGE_COLOR := Color(0.62, 0.64, 0.74)

## "platform" or "ramp".
var kind := "platform"
## The area's Dictionary from GroundHeight.platforms or GroundHeight.ramps.
var block := {}
## Flat world pixels -> drawn pixels (the scene's view transform, origin 0).
var view_basis := Transform2D.IDENTITY

## How visible the area is while it covers the car (1 = solid): the buildings'.
var see_through_alpha: float = MvpMapScript.SEE_THROUGH_ALPHA
## Seconds for the whole fade, either way (0 = instant): the buildings'.
var fade_time: float = MvpMapScript.SEE_THROUGH_FADE_TIME
## True while the area covers the car (set by update_fade).
var covering := false


## The PixelLab art (task T-186, game/art/elevation/): a sprite per kind, drawn
## at scale 0.5 (32 art px per unit in the 16 px per unit world). Its record
## gives where its top-left sits from the drawn origin, in art px. When the art
## exists, it replaces the script drawing below (kept as the fallback).
const ART_DIR := "res://art/elevation/"
const ART_SCALE := 0.5

var art_sprite: Sprite2D
## Where this drawing looks for its art: a folder and the file name without its
## extension. The test scene's default is ART_DIR and the kind; the elevation
## sample map (task T-198) uses art/elevation_sample/ and the area's id, one
## sprite and record per area (SAMPLE_ART_DIR). With no art there, the script
## drawing below is drawn (the fallback).
var art_dir := ART_DIR
var art_name := ""

const SAMPLE_ART_DIR := "res://art/elevation_sample/"


func setup(the_kind: String, the_block: Dictionary, basis: Transform2D, the_art_dir: String = ART_DIR, the_art_name: String = "") -> void:
	kind = the_kind
	block = the_block
	view_basis = basis
	art_dir = the_art_dir
	art_name = the_art_name
	_load_art()
	queue_redraw()


func _load_art() -> void:
	if art_sprite != null:
		art_sprite.queue_free()
		art_sprite = null
	var stem := art_name if art_name != "" else kind
	var png := art_dir + stem + ".png"
	var record := art_dir + stem + ".json"
	if not ResourceLoader.exists(png) or not FileAccess.file_exists(record):
		return
	var info = JSON.parse_string(FileAccess.get_file_as_string(record))
	if not (info is Dictionary) or not info.has("top_left_art_px"):
		return
	art_sprite = Sprite2D.new()
	art_sprite.name = "Art"
	art_sprite.texture = load(png)
	art_sprite.centered = false
	art_sprite.scale = Vector2(ART_SCALE, ART_SCALE)
	art_sprite.position = Vector2(info.top_left_art_px[0], info.top_left_art_px[1]) * ART_SCALE
	art_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(art_sprite)


## Moves the art by `offset_units` (flat units) from where its record puts it: the level creator's
## pieces (T-236) reuse the sample map's art away from where it was made.
func shift_art(offset_units: Vector2) -> void:
	if art_sprite != null:
		art_sprite.position += view_basis * (offset_units * PX_PER_UNIT)


## Textured mode (task T-251): the level creator's rooftops and ramps of any size have no art
## piece; with a style (piece_style.gd, art/creator_pieces/piece_style.tres) they are drawn from
## its tileable textures projected onto the top and the east and south walls, in the art's
## projection (32 art px per unit, drawn at 0.5), mirror-tiled, nearest filtering, with a dark
## outline on the edges and a parapet on a rooftop's back edges. Null: the flat placeholder.
var style: Resource
## The height the area stands on (its walls start there): the rooftop under a stacked rooftop,
## a ramp's bottom height; 0 on the street.
var base := 0.0
## Where an edge has no outline (and, on the back edges, no parapet): a ramp meeting it or a
## higher rooftop standing on it. {"north": [[from, to], ...], "east", "south", "west"}, units
## along the edge (x for north and south, y for east and west).
var edge_gaps: Dictionary = {}


## Switches to the textured mode with `the_style` (when the area has no art sprite).
func use_style(the_style: Resource, the_base: float, gaps: Dictionary = {}) -> void:
	style = the_style
	base = the_base
	edge_gaps = gaps
	# A ramp whose textures are seamless when tiled plainly (T-255) keeps its chevrons pointing
	# one way; mirrored tiles would turn every other row's the other way.
	var plain: bool = kind == "ramp" and bool(style.get("ramp_plain_repeat"))
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED if plain else CanvasItem.TEXTURE_REPEAT_MIRROR
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()


## True when the area is drawn from the style's textures.
func is_textured() -> bool:
	return style != null and art_sprite == null and not block.is_empty()


## A ramp's top end, the edge where it meets the rooftop it climbs (the opposite of `side`, the
## rooftop's side): "west" for a ramp up an east side, ... "" for a rooftop.
func join_edge() -> String:
	if kind != "ramp":
		return ""
	return {"east": "west", "west": "east", "north": "south", "south": "north"}.get(str(block.side), "")


## Which way a ramp's arrows point (T-264): "up" the slope (the default) or "down" it.
func arrows() -> String:
	return "down" if str(block.get("arrows", "up")) == "down" else "up"


## The flat direction (a unit vector on x or y) a ramp's arrows point in: towards its top end for
## "up", away from it for "down". ZERO for a rooftop.
func arrow_direction() -> Vector2:
	var up: Vector2 = {"east": Vector2(-1, 0), "west": Vector2(1, 0), "south": Vector2(0, -1),
		"north": Vector2(0, 1)}.get(str(block.get("side", "")), Vector2.ZERO)
	return up if arrows() == "up" else -up


## The textured mode's faces, back to front, each {name, points, uvs, texture, color}: the east
## and south walls, a ramp's wall at its tall end too (T-264), the top, and
## a rooftop's parapet runs (north, west). For the drawing and the tests.
func textured_faces() -> Array:
	var out: Array = []
	if style == null or block.is_empty():
		return out
	var r := rect()
	var h := corner_heights()
	var is_ramp := kind == "ramp"
	var join := join_edge()
	var px: float = style.TEXTURE_PX_PER_UNIT
	var side_tex: Texture2D = style.ramp_side if is_ramp else style.wall
	var ne := Vector2(r.end.x, r.position.y)
	var sw := Vector2(r.position.x, r.end.y)
	# T-264: a ramp is a closed block, so its tall end has its wall too, down to what it stands on,
	# in the ramp side's texture, even where it meets a rooftop. On the west and north ends the
	# wall faces away from the view and is drawn first, behind the top.
	if is_ramp and join == "west":
		_add_wall(out, "west", r.position, sw, h[0], h[3], 1, side_tex, style.ramp_east_shade, px)
	if is_ramp and join == "north":
		_add_wall(out, "north", r.position, ne, h[0], h[1], 0, side_tex, style.ramp_south_shade, px)
	var east_shade: float = style.ramp_east_shade if is_ramp else style.roof_east_shade
	_add_wall(out, "east", ne, r.end, h[1], h[2], 1, side_tex, east_shade, px)
	var south_shade: float = style.ramp_south_shade if is_ramp else style.roof_south_shade
	_add_wall(out, "south", sw, r.end, h[3], h[2], 0, side_tex, south_shade, px)
	var top_tex: Texture2D = style.ramp_top if is_ramp else style.roof_top
	var swap := is_ramp and str(block.side) in ["east", "west"]  # the lane lines run along the ramp
	# T-264: the texture's arrows point towards smaller v; v runs along the ramp with the sign that
	# makes them point up or down the slope (arrow_direction).
	var v_sign := 1.0
	if is_ramp:
		var along: Vector2 = arrow_direction()
		v_sign = -(along.x if swap else along.y)
	var corners := [r.position, ne, r.end, sw]
	var pts := top_face()
	var uvs := PackedVector2Array()
	for c in corners:
		var p: Vector2 = c
		var q := Vector2(p.y, p.x) if swap else p
		if is_ramp:
			q.y *= v_sign
		uvs.append(_uv(q, px, top_tex))
	out.append({"name": "top", "points": pts, "uvs": uvs, "texture": top_tex, "color": Color.WHITE})
	if not is_ramp and style.parapet != null:
		var top := float(block.height)
		var ph: float = style.parapet_height_units
		for seg in _open_runs("north", r.position.x, r.end.x):
			var a := Vector2(seg[0], r.position.y)
			var b := Vector2(seg[1], r.position.y)
			out.append(_parapet_face("parapet_north", a, b, seg[0], seg[1], top, ph, px, Color.WHITE))
		var west_c := Color(style.parapet_west_shade, style.parapet_west_shade, style.parapet_west_shade)
		for seg in _open_runs("west", r.position.y, r.end.y):
			var a := Vector2(r.position.x, seg[0])
			var b := Vector2(r.position.x, seg[1])
			out.append(_parapet_face("parapet_west", a, b, seg[0], seg[1], top, ph, px, west_c))
	return out


## A wall from flat corner a to b (`axis` 1: along y, the east wall; 0: along x, the south wall),
## its top at heights ha and hb, from `base` up. Left out when it has no height.
func _add_wall(out: Array, wall_name: String, a: Vector2, b: Vector2, ha: float, hb: float, axis: int,
		tex: Texture2D, shade: float, px: float) -> void:
	if ha - base <= 0.001 and hb - base <= 0.001:
		return
	var off: float = style.wall_row_offset_px
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	for c in [[a, ha, ha], [b, hb, hb], [b, hb, base], [a, ha, base]]:
		var p: Vector2 = c[0]
		var top: float = c[1]
		var at: float = c[2]
		var q := drawn(p, at)
		var repeated := false
		for o in pts:
			if o.is_equal_approx(q):
				repeated = true
		if repeated:
			continue
		pts.append(q)
		uvs.append(Vector2(p[axis] * px / tex.get_width(), ((top - at) * px + off) / tex.get_height()))
	if pts.size() >= 3:
		out.append({"name": wall_name, "points": pts, "uvs": uvs, "texture": tex, "color": Color(shade, shade, shade)})


func _parapet_face(face_name: String, a: Vector2, b: Vector2, ta: float, tb: float, top: float, ph: float,
		px: float, color: Color) -> Dictionary:
	var tex: Texture2D = style.parapet
	var w := float(tex.get_width())
	return {"name": face_name, "texture": tex, "color": color,
		"points": PackedVector2Array([drawn(a, top), drawn(b, top), drawn(b, top + ph), drawn(a, top + ph)]),
		"uvs": PackedVector2Array([Vector2(ta * px / w, 1.0), Vector2(tb * px / w, 1.0),
			Vector2(tb * px / w, 0.0), Vector2(ta * px / w, 0.0)])}


static func _uv(p: Vector2, px: float, tex: Texture2D) -> Vector2:
	return Vector2(p.x * px / tex.get_width(), p.y * px / tex.get_height())


## The runs [from, to] of `edge` between lo and hi that no gap (edge_gaps) covers.
func _open_runs(edge: String, lo: float, hi: float) -> Array:
	var runs: Array = [[lo, hi]]
	for g in edge_gaps.get(edge, []):
		var next: Array = []
		for run in runs:
			var a: float = run[0]
			var b: float = run[1]
			var ga := maxf(a, float(g[0]))
			var gb := minf(b, float(g[1]))
			if ga >= gb:
				next.append(run)
				continue
			if ga > a:
				next.append([a, ga])
			if gb < b:
				next.append([gb, b])
		runs = next
	return runs.filter(func(run) -> bool: return float(run[1]) - float(run[0]) > 0.001)


## The textured mode's outline: [[from, to], ...] drawn segments. The top's four edges (not at a
## ramp's top end, not in the edge gaps), the visible vertical corners (NE, SE, SW; not at a ramp's
## top end) and the walls' bottom edges.
func outline_segments() -> Array:
	var out: Array = []
	if block.is_empty():
		return out
	var r := rect()
	var h := corner_heights()
	var join := join_edge()
	var nw := r.position
	var ne := Vector2(r.end.x, r.position.y)
	var se := r.end
	var sw := Vector2(r.position.x, r.end.y)
	# The top's edges: name, from, to, the axis along it.
	for e in [["north", nw, ne, 0], ["east", ne, se, 1], ["south", sw, se, 0], ["west", nw, sw, 1]]:
		if e[0] == join:
			continue
		var a: Vector2 = e[1]
		var axis: int = e[3]
		for run in _open_runs(e[0], a[axis], (e[2] as Vector2)[axis]):
			var pa := a
			var pb := a
			pa[axis] = run[0]
			pb[axis] = run[1]
			out.append([drawn(pa, top_height_at(pa)), drawn(pb, top_height_at(pb))])
	# Vertical corners, with the two edges each belongs to, and its height.
	for c in [[ne, ["north", "east"], h[1]], [se, ["east", "south"], h[2]], [sw, ["south", "west"], h[3]]]:
		var p: Vector2 = c[0]
		if float(c[2]) - base <= 0.001:
			continue
		out.append([drawn(p, base), drawn(p, float(c[2]))])
	if maxf(h[1], h[2]) - base > 0.001:
		out.append([drawn(ne, base), drawn(se, base)])
	if maxf(h[3], h[2]) - base > 0.001:
		out.append([drawn(sw, base), drawn(se, base)])
	return out


func _draw_textured() -> void:
	for f in textured_faces():
		draw_polygon(f.points, PackedColorArray([f.color]), f.uvs, f.texture)
	for s in outline_segments():
		draw_line(s[0], s[1], style.outline_color, style.outline_width)


## Every colour this drawing can use (for the colour check in the tests).
static func colors_used() -> Array:
	return [TOP_COLOR, TOP_GRID_COLOR, RAMP_TOP_COLOR, RAMP_GRID_COLOR, EAST_COLOR, SOUTH_COLOR, EDGE_COLOR]


func rect() -> Rect2:
	return block.rect


## Heights of the corners, units, in the order NW, NE, SE, SW (north = -y).
func corner_heights() -> Array:
	if kind != "ramp":
		var h := float(block.height)
		return [h, h, h, h]
	var top := float(block.top_height)
	var bottom := float(block.get("bottom_height", 0.0))
	match str(block.side):
		"east":   # the top is at the ramp's west end
			return [top, bottom, bottom, top]
		"west":
			return [bottom, top, top, bottom]
		"south":  # the top is at the ramp's north end
			return [top, top, bottom, bottom]
		"north":
			return [bottom, bottom, top, top]
	return [top, top, top, top]


## The height of the area's top at a flat point (units), clamped into its
## rectangle: the plane through its corners.
func top_height_at(point: Vector2) -> float:
	var r := rect()
	var u := clampf((point.x - r.position.x) / maxf(0.0001, r.size.x), 0.0, 1.0)
	var v := clampf((point.y - r.position.y) / maxf(0.0001, r.size.y), 0.0, 1.0)
	var h := corner_heights()
	var north := lerpf(h[0], h[1], u)
	var south := lerpf(h[3], h[2], u)
	return lerpf(north, south, v)


## The drawn pixel of a flat point (units) at a height (units).
func drawn(point: Vector2, height: float) -> Vector2:
	return view_basis * (point * PX_PER_UNIT) + Vector2(0.0, -height * PX_PER_UNIT)


## True when something centred at centre (flat units), radius units around it,
## at height (units) is behind this area and must be drawn under it: its centre
## is west or north of the area's rectangle (the far sides in the isometric
## view), its footprint is not wholly east or south of it, and it is lower than
## the area's top next to it. Anything on the area, above it, or in front of it
## is drawn over it.
##
## The far side is judged by the centre, not the whole footprint (task T-191):
## the ground's sides stop the car's centre (car_height.gd, _walk), so at a
## wall hit from behind the car's 1 by 1 footprint reaches into the rectangle
## while its centre stays just outside. Judged by the footprint, the car was
## "not behind" there and popped over the area for the hit.
func is_behind(centre: Vector2, radius: float, height: float) -> bool:
	var r := rect()
	var behind := centre.x <= r.position.x or centre.y <= r.position.y
	var in_front := centre.x - radius >= r.end.x or centre.y - radius >= r.end.y
	if not behind or in_front:
		return false
	return height < top_height_at(centre) - 0.001


## The area's outline on screen, in drawn pixels: the convex hull of its top
## face and its ground corners (the area is a box or a wedge, so convex).
func silhouette() -> PackedVector2Array:
	var r := rect()
	var pts := top_face()
	for p in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		pts.append(drawn(p, 0.0))
	return Geometry2D.convex_hull(pts)


## True when the area covers the car: the car (centre in flat units, radius
## units around it, at height units) is behind it and the car's drawn shape
## (drawn pixels, car_shape) overlaps the area's silhouette.
func covers(centre: Vector2, radius: float, height: float, car_shape: PackedVector2Array) -> bool:
	if block.is_empty() or not is_behind(centre, radius, height):
		return false
	return not Geometry2D.intersect_polygons(silhouette(), car_shape).is_empty()


## Decides whether the area covers the car and moves the fade by `delta`
## seconds, as the map's buildings do (map_building.gd, faded_alpha). Returns
## `covering`.
func update_fade(centre: Vector2, radius: float, height: float, car_shape: PackedVector2Array, delta: float) -> bool:
	covering = covers(centre, radius, height, car_shape)
	modulate.a = MapBuildingScript.faded_alpha(modulate.a, covering, delta, see_through_alpha, fade_time)
	return covering


## The area's alpha now (1 = solid). The same as modulate.a.
func alpha() -> float:
	return modulate.a


## The four corners' drawn points of the top face (NW, NE, SE, SW).
func top_face() -> PackedVector2Array:
	var r := rect()
	var h := corner_heights()
	return PackedVector2Array([
		drawn(r.position, h[0]),
		drawn(Vector2(r.end.x, r.position.y), h[1]),
		drawn(r.end, h[2]),
		drawn(Vector2(r.position.x, r.end.y), h[3]),
	])


## A side face from flat corner a to b, with heights ha and hb at the top:
## the drawn polygon, without repeated points (an empty array when it has no
## area, for a side of height 0).
func side_face(a: Vector2, b: Vector2, ha: float, hb: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for p in [drawn(a, 0.0), drawn(b, 0.0), drawn(b, hb), drawn(a, ha)]:
		var repeated := false
		for q in pts:
			if (p as Vector2).is_equal_approx(q):
				repeated = true
		if not repeated:
			pts.append(p)
	return pts if pts.size() >= 3 else PackedVector2Array()


func east_face() -> PackedVector2Array:
	var r := rect()
	var h := corner_heights()
	return side_face(Vector2(r.end.x, r.position.y), r.end, h[1], h[2])


func south_face() -> PackedVector2Array:
	var r := rect()
	var h := corner_heights()
	return side_face(Vector2(r.position.x, r.end.y), r.end, h[3], h[2])


func _draw() -> void:
	if block.is_empty() or art_sprite != null:
		return
	if style != null:
		_draw_textured()
		return
	var r := rect()
	var h := corner_heights()
	var east := east_face()
	if not east.is_empty():
		draw_colored_polygon(east, EAST_COLOR)
	var south := south_face()
	if not south.is_empty():
		draw_colored_polygon(south, SOUTH_COLOR)
	var top := top_face()
	var is_ramp := kind == "ramp"
	draw_colored_polygon(top, RAMP_TOP_COLOR if is_ramp else TOP_COLOR)
	# A unit grid on the top, so movement shows on it as on the street.
	var grid := PackedVector2Array()
	for gx in range(ceili(r.position.x + 0.001), floori(r.end.x - 0.001) + 1):
		var a := Vector2(gx, r.position.y)
		var b := Vector2(gx, r.end.y)
		grid.append(drawn(a, top_height_at(a)))
		grid.append(drawn(b, top_height_at(b)))
	for gy in range(ceili(r.position.y + 0.001), floori(r.end.y - 0.001) + 1):
		var a := Vector2(r.position.x, gy)
		var b := Vector2(r.end.x, gy)
		grid.append(drawn(a, top_height_at(a)))
		grid.append(drawn(b, top_height_at(b)))
	if not grid.is_empty():
		draw_multiline(grid, RAMP_GRID_COLOR if is_ramp else TOP_GRID_COLOR, 1.0)
	# Light edges: the top's outline and the visible vertical corners.
	var outline := top.duplicate()
	outline.append(top[0])
	draw_polyline(outline, EDGE_COLOR, 1.0)
	var ne := Vector2(r.end.x, r.position.y)
	var sw := Vector2(r.position.x, r.end.y)
	for c in [[ne, h[1]], [r.end, h[2]], [sw, h[3]]]:
		if float(c[1]) > 0.001:
			draw_line(drawn(c[0], 0.0), drawn(c[0], c[1]), EDGE_COLOR, 1.0)
