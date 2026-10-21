extends RefCounted
## Puts an enemy or a coin into the buildings' depth order (task T-044), the
## same rule the map uses for the car (map.car_z_index(), task T-034): just
## under the lowest building or boulder sprite that covers it, otherwise over
## every building (map.top_z_index()). Unlike the car, nothing fades for an
## enemy: the fade stays car-only.
##
## "Covers" is the map's own test: the thing stands behind the building
## (building.is_behind(centre)) or the boulder (smaller x + y), and its
## shape on screen overlaps the building's or boulder's outline. The screen
## shape here is a small box on the ground, `radius_units` around the centre,
## raised `height_units`, in the map's screen pixels (the isometric view).
##
## Silhouettes do not move, so their bounding boxes are cached per map: a cheap
## box test rules out most buildings before the polygon test.
##
## On a map with elevation (task T-206, map.elevation, elevation_layer.gd) the
## raised areas and ramps join the order: the thing is drawn under every area
## that covers it. Since task T-207 the thing stands on the ground under it:
## `ground_h` (units; 0 on the street) lifts its screen shape up the screen,
## as its sprite is lifted, and an area covers it only where it stands lower
## than the area's top there (elevation_platform_drawing.gd, is_behind).

const PX_PER_UNIT := 16.0
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)

var map: Node2D = null
var _items: Array = []
var _boxes: Array = []


func _init(the_map: Node2D = null) -> void:
	set_map(the_map)


## Use another map (a new run's). Forgets the cached outlines.
func set_map(the_map: Node2D) -> void:
	map = the_map
	_items = []
	_boxes = []


## The screen shape (map screen pixels) of something `radius_units` around
## `centre_units` on the ground and `height_units` tall.
static func screen_shape(centre_units: Vector2, radius_units: float, height_units: float) -> PackedVector2Array:
	var up := Vector2(0.0, -height_units * PX_PER_UNIT)
	var pts := PackedVector2Array()
	for s in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var p: Vector2 = ISO_TRANSFORM * ((centre_units + s * radius_units) * PX_PER_UNIT)
		pts.append(p)
		pts.append(p + up)
	return Geometry2D.convex_hull(pts)


## The z_index for something at `centre_units` with that size, standing on
## ground `ground_h` units high (T-207; 0 on the street).
func z_index_for(centre_units: Vector2, radius_units: float, height_units: float, ground_h: float = 0.0) -> int:
	if map == null:
		return 0
	var z: int = map.top_z_index()
	if map.view != "iso":
		return z
	_cache_items()
	var shape := screen_shape(centre_units, radius_units, height_units)
	if ground_h != 0.0:
		shape = Transform2D(0.0, Vector2(0.0, -ground_h * PX_PER_UNIT)) * shape
	var box := _bounds(shape)
	for i in _items.size():
		var b = _items[i]
		if b.z_index - 1 >= z:
			continue
		if not b.is_behind(centre_units):
			continue
		if not (_boxes[i] as Rect2).intersects(box):
			continue
		if b.overlaps_on_screen(shape):
			z = b.z_index - 1
	for s in map.boulder_sprites:
		if s.z_index - 1 < z and s.covers(centre_units, shape, box):
			z = s.z_index - 1
	# T-206, T-207: on a map with elevation, also under the raised areas and
	# ramps that cover it at the height it stands on.
	var elevation = map.get("elevation")
	if elevation != null:
		z = elevation.z_under_areas(z, centre_units, radius_units, ground_h, shape)
	return z


func _cache_items() -> void:
	var items: Array = map.fade_items()
	if items.size() == _items.size() and (items.is_empty() or items[0] == _items[0]):
		return
	_items = items.duplicate()
	_boxes = []
	for b in _items:
		_boxes.append(_bounds(b.iso_silhouette()))


static func _bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var r := Rect2(points[0], Vector2.ZERO)
	for p in points:
		r = r.expand(p)
	return r
