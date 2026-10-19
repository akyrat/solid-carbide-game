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


func setup(the_kind: String, the_block: Dictionary, basis: Transform2D) -> void:
	kind = the_kind
	block = the_block
	view_basis = basis
	queue_redraw()


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
## at height (units) is behind this area and must be drawn under it: its
## footprint lies wholly west or north of the area's rectangle (the far sides
## in the isometric view) and not wholly east or south of it, and it is lower
## than the area's top next to it. Anything on the area, above it, or in front
## of it is drawn over it.
func is_behind(centre: Vector2, radius: float, height: float) -> bool:
	var r := rect()
	var behind := centre.x + radius <= r.position.x or centre.y + radius <= r.position.y
	var in_front := centre.x - radius >= r.end.x or centre.y - radius >= r.end.y
	if not behind or in_front:
		return false
	return height < top_height_at(centre) - 0.001


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
	if block.is_empty():
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
