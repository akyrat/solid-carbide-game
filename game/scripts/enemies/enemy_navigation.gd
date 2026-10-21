extends RefCounted
## Pathfinding for the enemies over the streets, ramps and rooftops (task
## T-207; Enemies, Decisions, "Enemies follow the car up the ramps").
##
## A grid of CELL by CELL unit cells over the whole map, in Godot's AStar2D:
## one point per open cell (not in a building), and a link between two
## neighbouring cells (the four sides and the four corners) only when the
## ground between them changes by EnemyHeight.MAX_STEP or less. Rooftop edges
## (3 or 6 units) and the high part of a ramp's sides are never linked, so the
## only ways between the street and a rooftop are the ramps. Why AStar2D on a
## grid: the map's heights are rectangles in the map file (ground_height.gd),
## so a grid built from them is exact at CELL = 2 (every edge on the map lies
## on even units), it needs no baking or navigation regions, and a link that
## exists only where the height allows is what an edge that blocks "like a
## wall" means. AStarGrid2D cannot leave out a link between two open cells,
## which is why it is AStar2D.
##
## One per map, built on first use and kept on the map (for_map), so the
## minions and the kaiju share it. The build is about 14 400 points; the
## enemies only ask it for a path when they are not on the car's surface
## (surface_at), about once a second each (enemy_path_follower.gd).
##
## Paths through a ramp: the cells on the ramp are replaced by two points on
## the ramp's centre line, RAMP_OUT units beyond its foot and beyond its top,
## so every enemy (the kaiju is 4 units wide, a ramp 10) goes up and down a
## ramp along its middle and not along its sides.

const EnemyHeightScript := preload("res://scripts/enemies/enemy_height.gd")

## Cell size, units. Every edge in the map file lies on even units.
const CELL := 2.0
## A building blocks the cells within this many units of it (the minion's radius).
const BUILDING_MARGIN := 0.5
## How far beyond a ramp's ends its two path points are, units.
const RAMP_OUT := 1.5
## A run of ramp cells changing the path's height by less than this (units)
## only skims the ramp's low end: its cells are kept as they are.
const CLIMB_MIN := 1.0
const META_KEY := "enemy_navigation"

var ground
var astar := AStar2D.new()
var origin := Vector2.ZERO
var cols := 0
var rows := 0
## Per cell: the ground height at its centre, open (1) or in a building (0),
## and the index of the ramp it is on (-1 for none).
var heights := PackedFloat32Array()
var open := PackedByteArray()
var ramp_of := PackedInt32Array()
## Microseconds the last build took (for the result notes and the soak).
var build_usec := 0


## The navigation of `map` (built by mvp_map.gd) on a map with elevation
## (map.elevation, elevation_layer.gd), built once and kept on the map; null
## on a map without heights (the MVP map: enemies walk straight at the car).
static func for_map(map: Node) -> RefCounted:
	if map == null or not is_instance_valid(map):
		return null
	var elevation = map.get("elevation")
	if elevation == null:
		return null
	if map.has_meta(META_KEY):
		return map.get_meta(META_KEY)
	var blocks: Array = []
	for b in map.layout.buildings:
		blocks.append(map.rect_of(b))
	var nav = load("res://scripts/enemies/enemy_navigation.gd").new()
	nav.build(map.rect_of(map.layout.map.rect), blocks, elevation.ground_height)
	map.set_meta(META_KEY, nav)
	return nav


## Builds the grid over `map_rect` (units) with `blocks` (building rectangles)
## closed, and the heights of `the_ground` (a GroundHeight).
func build(map_rect: Rect2, blocks: Array, the_ground) -> void:
	var t0 := Time.get_ticks_usec()
	ground = the_ground
	origin = map_rect.position
	cols = int(floor(map_rect.size.x / CELL))
	rows = int(floor(map_rect.size.y / CELL))
	var n := cols * rows
	heights.resize(n)
	heights.fill(0.0)
	open.resize(n)
	open.fill(1)
	ramp_of.resize(n)
	ramp_of.fill(-1)
	# Heights: only cells inside an area can be above 0.
	var areas: Array = []
	for p in ground.platforms:
		areas.append(p.rect)
	for r in ground.ramps:
		areas.append(r.rect)
	for rect in areas:
		_for_cells_in(rect, func(k: int, c: Vector2) -> void: heights[k] = ground.height_at(c))
	for i in ground.ramps.size():
		var ri: int = i
		_for_cells_in(ground.ramps[i].rect, func(k: int, _c: Vector2) -> void: ramp_of[k] = ri)
	for b in blocks:
		_for_cells_in((b as Rect2).grow(BUILDING_MARGIN), func(k: int, _c: Vector2) -> void: open[k] = 0)
	astar.clear()
	astar.reserve_space(n)
	for k in n:
		if open[k] == 1:
			astar.add_point(k, cell_centre(k))
	var step := EnemyHeightScript.MAX_STEP
	for j in rows:
		for i in cols:
			var k := j * cols + i
			if open[k] == 0:
				continue
			var h := heights[k]
			if i + 1 < cols:
				var e := k + 1
				if open[e] == 1 and absf(heights[e] - h) <= step:
					astar.connect_points(k, e)
			if j + 1 < rows:
				var s := k + cols
				if open[s] == 1 and absf(heights[s] - h) <= step:
					astar.connect_points(k, s)
				if i + 1 < cols and _square_level(k, k + 1, s, s + 1):
					astar.connect_points(k, s + 1)
				if i > 0 and _square_level(k, k - 1, s, s - 1):
					astar.connect_points(k, s - 1)
	build_usec = Time.get_ticks_usec() - t0


## True when the four cells are open and their heights within MAX_STEP of each
## other: a corner link that cuts past no edge.
func _square_level(a: int, b: int, c: int, d: int) -> bool:
	if open[a] == 0 or open[b] == 0 or open[c] == 0 or open[d] == 0:
		return false
	var lo := minf(minf(heights[a], heights[b]), minf(heights[c], heights[d]))
	var hi := maxf(maxf(heights[a], heights[b]), maxf(heights[c], heights[d]))
	return hi - lo <= EnemyHeightScript.MAX_STEP


## Calls f(cell index, cell centre) for every cell whose centre is inside `rect`.
func _for_cells_in(rect: Rect2, f: Callable) -> void:
	var i0 := maxi(0, int(ceil((rect.position.x - origin.x) / CELL - 0.5)))
	var i1 := mini(cols - 1, int(floor((rect.end.x - origin.x) / CELL - 0.5)))
	var j0 := maxi(0, int(ceil((rect.position.y - origin.y) / CELL - 0.5)))
	var j1 := mini(rows - 1, int(floor((rect.end.y - origin.y) / CELL - 0.5)))
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			var k := j * cols + i
			var c := cell_centre(k)
			if rect.has_point(c):
				f.call(k, c)


func cell_centre(k: int) -> Vector2:
	return origin + Vector2((k % cols) + 0.5, (k / cols) + 0.5) * CELL


## The cell under `units`, or -1 off the grid.
func cell_at(units: Vector2) -> int:
	var i := int(floor((units.x - origin.x) / CELL))
	var j := int(floor((units.y - origin.y) / CELL))
	if i < 0 or j < 0 or i >= cols or j >= rows:
		return -1
	return j * cols + i


## Which surface `units` is on: the ground's area index (ground_height.gd,
## area_index_at: a rooftop or a ramp), -1 for the street. Two places on the
## same surface are joined without a ramp.
func surface_at(units: Vector2) -> int:
	return ground.area_index_at(units)


## An open cell near `units` whose ground is at height `h` (within MAX_STEP):
## the cell under it, or the nearest such cell up to two cells away; -1 if none.
func _cell_near(units: Vector2, h: float) -> int:
	var k := cell_at(units)
	if k >= 0 and open[k] == 1 and absf(heights[k] - h) <= EnemyHeightScript.MAX_STEP:
		return k
	var best := -1
	var best_d := INF
	var ci := int(floor((units.x - origin.x) / CELL))
	var cj := int(floor((units.y - origin.y) / CELL))
	for dj in range(-2, 3):
		for di in range(-2, 3):
			var i := ci + di
			var j := cj + dj
			if i < 0 or j < 0 or i >= cols or j >= rows:
				continue
			var kk := j * cols + i
			if open[kk] == 0 or absf(heights[kk] - h) > EnemyHeightScript.MAX_STEP:
				continue
			var d := cell_centre(kk).distance_squared_to(units)
			if d < best_d:
				best_d = d
				best = kk
	return best


## A path (units) from `from` to `to` over the streets, ramps and rooftops,
## each on the ground under it. The first point is near `from`, the last at
## `to`'s cell. Empty when there is no way (or either end is off the grid).
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var a := _cell_near(from, ground.height_at(from))
	var b := _cell_near(to, ground.height_at(to))
	if a < 0 or b < 0:
		return PackedVector2Array()
	var ids := astar.get_id_path(a, b)
	if ids.is_empty():
		return PackedVector2Array()
	return through_ramps(ids)


## The path's points for the cell ids, with every climb along a ramp replaced
## by the ramp's two end points on its centre line (see the top).
func through_ramps(ids: PackedInt64Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	var i := 0
	var n := ids.size()
	while i < n:
		var r := ramp_of[ids[i]]
		if r < 0:
			out.append(cell_centre(ids[i]))
			i += 1
			continue
		var j := i
		while j + 1 < n and ramp_of[ids[j + 1]] == r:
			j += 1
		var h_in := heights[ids[i - 1]] if i > 0 else heights[ids[i]]
		var h_out := heights[ids[j + 1]] if j + 1 < n else heights[ids[j]]
		var ramp: Dictionary = ground.ramps[r]
		var mid := (float(ramp.bottom_height) + float(ramp.top_height)) / 2.0
		if i > 0 and j + 1 < n and absf(h_out - h_in) < CLIMB_MIN:
			for k in range(i, j + 1):
				out.append(cell_centre(ids[k]))
		else:
			if i > 0:
				out.append(ramp_end(r, h_in >= mid))
			if j + 1 < n:
				out.append(ramp_end(r, h_out >= mid))
			else:
				out.append(cell_centre(ids[j]))
		i = j + 1
	return out


## A ramp's path point: on its centre line, RAMP_OUT units beyond its top
## (top true) or its foot.
func ramp_end(index: int, top: bool) -> Vector2:
	var r: Dictionary = ground.ramps[index]
	var rect: Rect2 = r.rect
	var c := rect.get_center()
	# The top's side of the rectangle, by the side the ramp climbs from (ground_height.gd, _ramp_t).
	var top_dir := Vector2.ZERO
	match str(r.side):
		"east":
			top_dir = Vector2.LEFT
		"west":
			top_dir = Vector2.RIGHT
		"south":
			top_dir = Vector2.UP
		"north":
			top_dir = Vector2.DOWN
	var dir := top_dir if top else -top_dir
	var half := absf(dir.x) * rect.size.x / 2.0 + absf(dir.y) * rect.size.y / 2.0
	return c + dir * (half + RAMP_OUT)
