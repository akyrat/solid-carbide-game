extends Node2D
## The elevation on a map built by mvp_map.gd (task T-206, taken out of the
## elevation sample map's scene, T-196 and T-197, so the drive-only scene and
## the run share it): the map file's raised areas (rooftops) and ramps, their
## drawings, the ground height under them (ground_height.gd), the depth order
## of the areas together with the map's buildings and boulders, and their
## see-through.
##
## Use: add it as a child of the map (after the map is ready) and call
## setup(map, layout_path). It builds one drawing per area
## (elevation_platform_drawing.gd) as its own children, sorts the depth order
## (restack) and hooks itself into the map (`map.elevation`), so the map's own
## depth queries (top_z_index, car_z_index, boulders, is_open_spot) and the
## enemies' (enemy_depth.gd) take the areas into account at street level.
##
## Depth order (Level design, Decisions, "Elevation sample map: depth
## order"): the buildings' slots and the raised areas are sorted together,
## back to front (restack, drawn_before), and each gets its own z_index,
## BUILDING_Z_STEP apart from DEPTH_Z_BASE. A stacked rooftop and a ramp
## standing on a rooftop come after the rooftop under them; an item wholly on
## another's far side (west or north) comes before it. Something drawn at a
## height goes just under the lowest item that covers it (z_for).
##
## See-through: update_see_through() fades every raised area, ramp and
## building covering the car's shape at its height (the map's own fade is off
## while the map has an elevation layer, mvp_map.gd _process).

const MvpMapScript := preload("res://scripts/level/mvp_map.gd")
const GroundHeightScript := preload("res://scripts/level/ground_height.gd")
const PlatformDrawingScript := preload("res://scripts/level/elevation_platform_drawing.gd")

const ISO_TRANSFORM := MvpMapScript.ISO_TRANSFORM
const PX_PER_UNIT := MvpMapScript.PX_PER_UNIT

## The car's footprint around its centre for the depth order, units.
const DEPTH_RADIUS := 0.5

## z_index of the first item (building slot or area) in depth order: one step
## over the map's own base, so a car under a boulder under the first item, and
## its shadow under it, still stay over the ground (z 0).
const DEPTH_Z_BASE := MvpMapScript.BUILDING_Z_BASE + MvpMapScript.BUILDING_Z_STEP

var map: Node2D
## The map's ground height (ground_height.gd, a GroundHeight; untyped so the
## scene loads before the class cache is built).
var ground_height
## The raised areas' drawings, in the file's order: the platforms, then the ramps.
var areas: Array = []
## Every item in the depth order (building slots and areas), back to front.
var depth_items: Array = []


## Reads the heights from `layout_path` (the map's own layout file), builds
## the areas' drawings, sorts the depth order and hooks into the map.
func setup(the_map: Node2D, layout_path: String) -> void:
	map = the_map
	ground_height = GroundHeightScript.from_file(layout_path)
	for p in ground_height.platforms:
		_add_area("platform", p)
	for r in ground_height.ramps:
		_add_area("ramp", r)
	restack()
	map.elevation = self


func _add_area(kind: String, block: Dictionary) -> void:
	var d = PlatformDrawingScript.new()
	d.name = "%s_%s" % [kind, str(block.id).replace("-", "_")]
	# The area's own art (task T-198): art/elevation_sample/<id>.png with its
	# record. With the art missing the script drawing is drawn instead.
	d.setup(kind, block, ISO_TRANSFORM, PlatformDrawingScript.SAMPLE_ART_DIR, str(block.id))
	add_child(d)
	areas.append(d)


# ---- Depth order -------------------------------------------------------------

## An item's footprint in units: a building slot's or an area's rectangle.
static func item_rect(item) -> Rect2:
	if item.get("footprint") != null:
		return item.footprint
	return item.rect()


## The height an item stands on: 0 for buildings and street areas, the area
## under it for a stacked rooftop or a ramp standing on a rooftop.
func item_base(item) -> float:
	if item.get("footprint") != null:
		return 0.0
	if item.kind == "ramp":
		return float(item.block.bottom_height)
	var on := str(item.block.get("on", ""))
	if on == "":
		return 0.0
	for p in ground_height.platforms:
		if p.id == on:
			return float(p.height)
	return 0.0


## True when item a must be drawn before (under) item b: a stands lower inside
## b's rectangle (a rooftop under a rooftop or a ramp standing on it), or a is
## wholly on b's far side (west or north of it) and b is not on a's.
func drawn_before(a, b) -> bool:
	var ra := item_rect(a)
	var rb := item_rect(b)
	var overlap := ra.position.x < rb.end.x and rb.position.x < ra.end.x \
		and ra.position.y < rb.end.y and rb.position.y < ra.end.y
	if overlap:
		return item_base(a) < item_base(b)
	var a_far := ra.end.x <= rb.position.x or ra.end.y <= rb.position.y
	var b_far := rb.end.x <= ra.position.x or rb.end.y <= ra.position.y
	return a_far and not b_far


## Sorts the map's building slots and the raised areas together, back to front
## (drawn_before, ties by the centre's x + y), and gives each its z_index; then
## puts the boulders and the pavement signs back in their places in that order.
func restack() -> void:
	var signs := {}
	if map.alert_signs_root != null:
		for sp in map.alert_signs_root.get_children():
			for s in map.fade_items():
				if s.z_index + 1 == sp.z_index:
					signs[sp] = s
	var items: Array = map.fade_items().duplicate()
	items.append_array(areas)
	var n := items.size()
	var before_count := []
	before_count.resize(n)
	before_count.fill(0)
	var edges := []
	for i in n:
		edges.append([])
	for i in n:
		for j in n:
			if i != j and drawn_before(items[i], items[j]):
				edges[i].append(j)
				before_count[j] += 1
	var done := []
	done.resize(n)
	done.fill(false)
	depth_items = []
	for _k in n:
		var best := -1
		for i in n:
			if done[i] or before_count[i] > 0:
				continue
			if best < 0 or _centre_sum(items[i]) < _centre_sum(items[best]):
				best = i
		if best < 0:
			# A cycle (should not happen): take the nearest-to-the-back left.
			for i in n:
				if not done[i] and (best < 0 or _centre_sum(items[i]) < _centre_sum(items[best])):
					best = i
		done[best] = true
		depth_items.append(items[best])
		for j in edges[best]:
			before_count[j] -= 1
	for k in depth_items.size():
		depth_items[k].z_index = DEPTH_Z_BASE + MvpMapScript.BUILDING_Z_STEP * k
	for sp in map.boulder_sprites:
		sp.z_index = boulder_z(sp)
	for sp in signs:
		sp.z_index = signs[sp].z_index + 1


static func _centre_sum(item) -> float:
	var c := item_rect(item).get_center()
	return c.x + c.y


## A z_index over every building and area.
func top_z_index() -> int:
	return DEPTH_Z_BASE + MvpMapScript.BUILDING_Z_STEP * depth_items.size()


## A boulder sprite's z_index: the map's (under the buildings that cover it),
## and under every raised area it is behind and overlaps on screen. A boulder
## nothing covers goes over every item, areas included.
func boulder_z(sp) -> int:
	var z: int = map._boulder_z_buildings(sp.centre_units, sp.outline)
	if z >= map.own_top_z_index():
		z = top_z_index()
	return boulder_z_under_areas(z, sp.centre_units, sp.outline)


## Lowers a boulder's z_index `z` under every raised area it is behind and
## overlaps on screen (outline in the map's screen pixels).
func boulder_z_under_areas(z: int, centre_units: Vector2, outline: PackedVector2Array) -> int:
	for a in areas:
		if a.is_behind(centre_units, 0.0, 0.0) \
				and not Geometry2D.intersect_polygons(a.silhouette(), outline).is_empty():
			z = mini(z, a.z_index - 1)
	return z


## Lowers `z` under every raised area that covers something at `centre_units`
## (radius units around it, at height units) with that shape on screen: the
## areas' part of the map's and the enemies' depth order.
func z_under_areas(z: int, centre_units: Vector2, radius: float, height: float, shape: PackedVector2Array) -> int:
	for a in areas:
		if a.z_index - 1 < z and a.covers(centre_units, radius, height, shape):
			z = a.z_index - 1
	return z


## The car's drawn shape on screen at a height (units): the map's 1 by 3 unit
## car shape at `units` with `rot`, lifted by that height.
static func car_shape_at(units: Vector2, rot: float, height: float) -> PackedVector2Array:
	return MvpMapScript.car_screen_shape_at(units, rot, height * PX_PER_UNIT)


## The z_index for the car drawn at `height` (units): just under the lowest
## building, boulder or raised area that covers it, otherwise over them all.
func z_for(units: Vector2, rot: float, height: float) -> int:
	var shape := car_shape_at(units, rot, height)
	var z := top_z_index()
	for b in map.fade_items():
		if b.covers(units, shape):
			z = mini(z, b.z_index - 1)
	var box := MvpMapScript._bounds(shape)
	for s in map.boulder_sprites:
		if s.covers(units, shape, box):
			z = mini(z, s.z_index - 1)
	for a in areas:
		if a.covers(units, DEPTH_RADIUS, height, shape):
			z = mini(z, a.z_index - 1)
	return z


## See-through: each raised area, ramp and building covering the car (at
## `units`, `rot`, `height`) fades, the others fade back, by `delta` seconds.
func update_see_through(units: Vector2, rot: float, height: float, delta: float) -> void:
	var shape := car_shape_at(units, rot, height)
	for a in areas:
		a.update_fade(units, DEPTH_RADIUS, height, shape, delta)
	for b in map.fade_items():
		b.update_fade(units, shape, delta)


## True when a circle of `radius` units at `centre` touches no raised area or
## ramp: street level all round (the map's is_open_spot adds it).
func is_street(centre: Vector2, radius: float) -> bool:
	for a in areas:
		if MvpMapScript._rect_distance(centre, a.rect()) < radius:
			return false
	return true


## The raised areas and ramps that covered the car at the last update_see_through().
func covering_areas() -> Array:
	return areas.filter(func(a) -> bool: return a.covering)


## The map's buildings (slots or blocks) that covered the car at the last update_see_through().
func covering_buildings() -> Array:
	return map.fade_items().filter(func(b) -> bool: return b.covering)
