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

## T-444: what covers something is looked up in a grid of SCREEN_CELL pixel cells on screen,
## not by testing every building, boulder, prop and raised area of the map for each enemy each
## step: each item is listed in the cells its outline's bounding box touches (grown by a pixel),
## once per map, and a thing's shape is only tested against the items listed in the cells its
## own box touches. An item whose box does not reach the thing's box cannot overlap it on screen,
## so the result is the same: the lowest z_index of the items that cover it, tested with the
## same rules (is_behind, overlaps_on_screen, covers). The grid is rebuilt when the map's
## buildings, boulder or prop sprites, or raised areas are added or removed (_signature).
const SCREEN_CELL := 64.0

var map: Node2D = null
var _items: Array = []
var _boxes: Array = []
var _sprites: Array = []
var _areas: Array = []
## Each area's outline's bounding box on screen (an area does not move).
var _area_boxes: Array = []
## Screen cell (Vector2i) -> indices into _items / _sprites / _areas.
var _item_cells: Dictionary = {}
var _sprite_cells: Dictionary = {}
var _area_cells: Dictionary = {}
## What the grid was built from (_is_current): the lists, and each one's size, first and last entry.
var _sig: Array = []
var _sig_refs: Array = []
## How many times the grid was built (tests).
var builds := 0
const _NONE := []


func _init(the_map: Node2D = null) -> void:
	set_map(the_map)


## Use another map (a new run's). Forgets the cached outlines.
func set_map(the_map: Node2D) -> void:
	map = the_map
	_items = []
	_boxes = []
	_sprites = []
	_areas = []
	_item_cells = {}
	_sprite_cells = {}
	_area_cells = {}
	_sig = []
	_sig_refs = []


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
	var c0 := _cell_of(box.position - Vector2.ONE)
	var c1 := _cell_of(box.end + Vector2.ONE)
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var key := Vector2i(cx, cy)
			for i in _item_cells.get(key, _NONE):
				var b = _items[i]
				if b.z_index - 1 >= z:
					continue
				if not b.is_behind(centre_units):
					continue
				if not (_boxes[i] as Rect2).intersects(box):
					continue
				if b.overlaps_on_screen(shape):
					z = b.z_index - 1
			for i in _sprite_cells.get(key, _NONE):
				var s = _sprites[i]
				if is_instance_valid(s) and s.z_index - 1 < z and s.covers(centre_units, shape, box):
					z = s.z_index - 1
			# T-206, T-207: on a map with elevation, also under the raised areas and
			# ramps that cover it at the height it stands on (elevation.z_under_areas's rule).
			for i in _area_cells.get(key, _NONE):
				var a = _areas[i]
				if a.z_index - 1 >= z or not (_area_boxes[i] as Rect2).intersects(box, true):
					continue
				if a.covers(centre_units, radius_units, ground_h, shape):
					z = a.z_index - 1
	return z


static func _cell_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / SCREEN_CELL), floori(p.y / SCREEN_CELL))


## True when the grid was built from the map's current lists: the same lists (by identity)
## with the same sizes and the same first and last entries.
func _is_current() -> bool:
	var elevation = map.get("elevation")
	var lists := [map.get("slots"), map.get("buildings"), map.get("boulder_sprites"), map.get("prop_sprites"),
		elevation.get("areas") if elevation != null else null]
	if _sig.is_empty() or _sig_refs.size() != lists.size():
		_sig_refs = lists
		return false
	var current := true
	for i in lists.size():
		var l = lists[i]
		if not is_same(l, _sig_refs[i]):
			current = false
		var size: int = l.size() if l != null else -1
		var first = l[0] if size > 0 else null
		var last = l[-1] if size > 0 else null
		if size != _sig[3 * i] or not is_same(first, _sig[3 * i + 1]) or not is_same(last, _sig[3 * i + 2]):
			current = false
	_sig_refs = lists
	return current


func _remember_lists() -> void:
	_sig = []
	for l in _sig_refs:
		var size: int = l.size() if l != null else -1
		_sig.append(size)
		_sig.append(l[0] if size > 0 else null)
		_sig.append(l[-1] if size > 0 else null)


func _cache_items() -> void:
	if _is_current():
		return
	_remember_lists()
	builds += 1
	_items = map.fade_items().duplicate()
	_boxes = []
	_item_cells = {}
	for i in _items.size():
		var bx := _bounds(_items[i].iso_silhouette())
		_boxes.append(bx)
		_file(_item_cells, bx, i)
	_sprites = map.depth_sprites().duplicate()
	_sprite_cells = {}
	for i in _sprites.size():
		_file(_sprite_cells, _sprites[i].box, i)
	_areas = []
	_area_cells = {}
	_area_boxes = []
	var elevation = map.get("elevation")
	if elevation != null:
		_areas = elevation.areas.duplicate()
		for i in _areas.size():
			_area_boxes.append(_bounds(_areas[i].silhouette()))
			_file(_area_cells, _area_boxes[i], i)


## Lists index `i` in every cell the box (grown by a pixel) touches.
static func _file(cells: Dictionary, box: Rect2, i: int) -> void:
	if box.size == Vector2.ZERO and box.position == Vector2.ZERO:
		return
	var c0 := _cell_of(box.position - Vector2.ONE)
	var c1 := _cell_of(box.end + Vector2.ONE)
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var key := Vector2i(cx, cy)
			if not cells.has(key):
				cells[key] = []
			cells[key].append(i)


static func _bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var r := Rect2(points[0], Vector2.ZERO)
	for p in points:
		r = r.expand(p)
	return r
