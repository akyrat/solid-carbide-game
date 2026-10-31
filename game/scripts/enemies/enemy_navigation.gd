extends RefCounted
## Pathfinding for the enemies over the streets, ramps and rooftops (task
## T-207; Enemies, Decisions, "Enemies follow the car up the ramps").
##
## A grid of CELL by CELL unit cells over the whole map, in Godot's AStar2D:
## one point per open cell (not in a building or on a boulder), and a link between two
## neighbouring cells (the four sides and the four corners) only when the
## ground between them changes by EnemyHeight.MAX_STEP or less. Rooftop edges
## (3 or 6 units) and the high part of a ramp's sides are never linked, so the
## only ways between the street and a rooftop are the ramps. Why AStar2D on a
## grid: the map's heights are rectangles in the map file (ground_height.gd),
## so a grid built from them is exact at CELL = 2 (every edge in the map file
## lies on even units; T-405's short-building platforms do not, see rough), it needs no baking or navigation regions, and a link that
## exists only where the height allows is what an edge that blocks "like a
## wall" means. AStarGrid2D cannot leave out a link between two open cells,
## which is why it is AStar2D.
##
## One per map and body size, built on first use and kept on the map (for_map):
## the minions share one, the kaiju has its own (T-419, below). The build is about 14 400 points; the
## enemies only ask it for a path when they are not on the car's surface
## (surface_at), about once a second each (enemy_path_follower.gd).
##
## Paths through a ramp: the cells on the ramp are replaced by two points on
## the ramp's centre line, RAMP_OUT units beyond its foot and beyond its top,
## so every enemy (the kaiju is 4 units wide, a ramp 10) goes up and down a
## ramp along its middle and not along its sides.
##
## Body size (task T-419; Enemies, Decisions, "The kaiju only takes paths it
## fits through"): a navigation plans for one body radius, its
## building_margin. Buildings, boulders and props close every cell whose
## centre is nearer than that to them, so each path point is at least the
## body's radius off them and a gap narrower than the body is closed. Each
## enemy asks for_map() with its own radius: the minions with theirs
## (minion_radius(), T-379's size), the kaiju with its 2 units. Before, every
## enemy shared the minion's grid and the kaiju was sent through gaps it does
## not fit and to points 1 unit off a wall, which it never reached.
## A navigation can also keep the body off the ground's edges (edge_radius,
## the kaiju's: a rooftop's edge stops its whole 2-unit radius, enemy_height.gd
## fits): a cell where the body would hang over an edge is closed too, and a
## drop then links the last cell it fits on the rooftop to the first it fits
## on below, a few cells apart (drop_span). The minions keep edge_radius 0,
## their grid as before (their edges use the old 0.5-unit radius, T-379).
##
## Drops (task T-226; Enemies, Decisions, "Enemies jump down off ledges"):
## each open rooftop cell beside lower ground (more than MAX_STEP lower, on
## one of its four sides, neither cell on a ramp) also has a one-way link down
## to that cell, so a path down may drop off an edge; nothing links back up,
## so going up is still only by the ramps. A path's drop is two points in a
## row, the cell on the edge and the cell below it (is_drop); the enemy walks
## out over the edge between them and falls (enemy_fall.gd).

const EnemyHeightScript := preload("res://scripts/enemies/enemy_height.gd")
const GroundIndexScript := preload("res://scripts/enemies/enemy_ground_index.gd")

## Cell size, units. Every edge in the map file lies on even units.
const CELL := 2.0
## A building blocks the cells within this many units of it (the minion's radius).
const BASE_MARGIN := 0.5
## How far beyond a ramp's ends its two path points are, units.
const RAMP_OUT := 1.5
## A run of ramp cells changing the path's height by less than this (units)
## only skims the ramp's low end: its cells are kept as they are.
const CLIMB_MIN := 1.0
const META_KEY := "enemy_navigation"
## Paths found at most per step (the spawner calls new_step() each step), so
## a crowd that needs paths at the same moment (the car drives up a ramp) asks
## for them over a few steps instead of in one.
const PATHS_PER_STEP := 4
## line_clear's samples along a line, units (half a cell).
const SIGHT_SAMPLE := 1.0
## off_edges: how far round a path point higher ground is looked for, and how
## far the point is moved away from each direction it is found in (units).
const EDGE_PROBE := 0.9
const EDGE_PUSH := 0.5
const _EDGE_DIRS := [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1),
	Vector2(0.70710678, 0.70710678), Vector2(-0.70710678, 0.70710678),
	Vector2(0.70710678, -0.70710678), Vector2(-0.70710678, -0.70710678)]
## line_clear's samples of the true ground in a rough cell, units (a ramp
## climbs 0.25 units per unit, well under MAX_STEP over this step).
const SIGHT_FINE := 0.25

## The body radius this navigation plans for (units): how far every open
## cell's centre is from the buildings, boulders and props. T-379: the
## minions' grows with their size (minion_radius()); T-419: the kaiju's is its
## own radius. Set in build_for_map().
var building_margin := BASE_MARGIN
## T-419: what closes cells, kept for clearance(): the rectangles (buildings,
## props) and the circles ([centre, radius]: boulders, round props).
var block_rects: Array = []
var block_circles: Array = []
## T-419: the body's radius kept off the ground's edges (0: none, the
## minions); per cell, 1 where only that closed it (the body hangs over an
## edge there; not a building's); and how many cells a drop link may span.
var edge_radius := 0.0
var unfit := PackedByteArray()
var drop_span := 1
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
## T-380, after T-405: 1 for a rough cell, one that an area's edge (a rooftop's,
## a platform's or a ramp's) passes through or passes within BASE_MARGIN of.
## The short buildings' platforms (T-405, short_platforms.gd) lie on half units,
## so their edges cut through cells whose centre (and so whose height) is on the
## street: line_clear checks the true ground in these cells.
var rough := PackedByteArray()
## Microseconds the last build took (for the result notes and the soak).
var build_usec := 0
## T-444: surface_at's last question and answer (and the lookup, and its build, it came from).
var _surface_units := Vector2(INF, INF)
var _surface_index = null
var _surface_builds := -1
var _surface_value := -1
## Paths found since the last new_step(), and in all.
var paths_this_step := 0
var paths_total := 0
## T-226: whether the grid has the one-way drop links, and how many.
var drops_enabled := true
var drop_links := 0


## The navigation of `map` (built by mvp_map.gd) on a map with elevation
## (map.elevation, elevation_layer.gd) for a body of `radius` units (T-419;
## below 0: the minion's, minion_radius()), built once per radius and kept on
## the map; null on a map without heights (the MVP map: enemies walk straight
## at the car). `fit_edges`: the body also keeps `radius` off the ground's
## edges (edge_radius; the kaiju).
static func for_map(map: Node, radius: float = -1.0, fit_edges: bool = false) -> RefCounted:
	if map == null or not is_instance_valid(map):
		return null
	var elevation = map.get("elevation")
	if elevation == null:
		return null
	var margin := radius if radius > 0.0 else minion_radius()
	var key := meta_key(margin, fit_edges)
	if map.has_meta(key):
		return map.get_meta(key)
	var nav = build_for_map(map, true, margin, fit_edges)
	map.set_meta(key, nav)
	return nav


## The map's meta key for the navigation of a body of `radius` units (and
## `fit_edges`): the minions' keeps META_KEY, other bodies get their own.
static func meta_key(radius: float, fit_edges: bool = false) -> String:
	if is_equal_approx(radius, minion_radius()) and not fit_edges:
		return META_KEY
	return "%s_%d%s" % [META_KEY, int(round(radius * 1000.0)), "_fit" if fit_edges else ""]


## The minions' body radius, units (T-379: BASE_MARGIN, the old minion radius,
## times enemies.json minion.size_scale; minion.gd radius_units()).
static func minion_radius() -> float:
	return BASE_MARGIN * float(EnemyData.new().minion().get("size_scale", 1.0))


## A new navigation for `map` (which must have elevation), not kept on the
## map, for a body of `radius` units (below 0: the minion's), kept off the
## ground's edges too with `fit_edges` (edge_radius). `drops` false
## leaves out the drop links (T-226), for comparison with the paths before
## T-226 (tests, the soak).
static func build_for_map(map: Node, drops: bool = true, radius: float = -1.0, fit_edges: bool = false) -> RefCounted:
	var elevation = map.get("elevation")
	var blocks: Array = []
	# T-405: only what stays a building closes cells (short_platforms.gd wall_rects); the short
	# buildings are platforms, which the ground height gives their heights like rooftops.
	for w in load("res://scripts/level/short_platforms.gd").wall_rects(map.layout):
		blocks.append(w.rect)
	var boulders: Array = []
	for b in map.all_boulders():
		boulders.append([Vector2(float(b.x), float(b.y)), float(b.diameter) / 2.0])
	# T-253: the props close the cells they take (a rectangle like a building, a round one like a boulder).
	var prop_obstacles: Dictionary = LevelProps.obstacles(map.layout)
	blocks.append_array(prop_obstacles.rects)
	boulders.append_array(prop_obstacles.circles)
	var nav = load("res://scripts/enemies/enemy_navigation.gd").new()
	nav.building_margin = radius if radius > 0.0 else minion_radius()
	nav.edge_radius = nav.building_margin if fit_edges else 0.0
	nav.build(map.rect_of(map.layout.map.rect), blocks, elevation.ground_height, boulders, drops)
	return nav


## Builds the grid over `map_rect` (units) with `blocks` (building rectangles)
## and `boulders` ([centre, radius] in units, the map's at the run's start)
## closed, and the heights of `the_ground` (a GroundHeight); `drops`: the
## one-way drop links off the rooftops' edges (T-226).
func build(map_rect: Rect2, blocks: Array, the_ground, boulders: Array = [], drops: bool = true) -> void:
	var t0 := Time.get_ticks_usec()
	ground = the_ground
	block_rects = blocks.duplicate()
	block_circles = boulders.duplicate()
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
	rough.resize(n)
	rough.fill(0)
	unfit.resize(n)
	unfit.fill(0)
	# T-419: a drop from the last cell the body fits on above to the first below.
	drop_span = 1 + ceili(2.0 * edge_radius / CELL) if edge_radius > 0.0 else 1
	# Heights: only cells inside an area can be above 0.
	var areas: Array = []
	for p in ground.platforms:
		areas.append(p.rect)
	for r in ground.ramps:
		areas.append(r.rect)
	for rect in areas:
		_for_cells_in(rect, func(k: int, c: Vector2) -> void: heights[k] = _gi().height_at(c))
	for rect in areas:
		_mark_rough(rect)
	for i in ground.ramps.size():
		var ri: int = i
		_for_cells_in(ground.ramps[i].rect, func(k: int, _c: Vector2) -> void: ramp_of[k] = ri)
	for b in blocks:
		_for_cells_in((b as Rect2).grow(building_margin), func(k: int, _c: Vector2) -> void: open[k] = 0)
	for bo in boulders:
		var centre: Vector2 = bo[0]
		var reach: float = float(bo[1]) + building_margin
		_for_cells_in(Rect2(centre - Vector2(reach, reach), Vector2(reach, reach) * 2.0),
			func(k: int, c: Vector2) -> void: if c.distance_to(centre) < reach: open[k] = 0)
	# T-419: the map's edge stops a body like a wall; cells nearer to it than the
	# body's radius are closed (strictly nearer: the minions' cells, 1 unit off it, stay).
	for k in n:
		var c := cell_centre(k)
		if minf(minf(c.x - map_rect.position.x, map_rect.end.x - c.x),
				minf(c.y - map_rect.position.y, map_rect.end.y - c.y)) < building_margin - 0.0001:
			open[k] = 0
	if edge_radius > 0.0:
		_close_unfit(areas)
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
	drops_enabled = drops
	drop_links = 0
	if drops:
		_add_drops()
	build_usec = Time.get_ticks_usec() - t0


## T-419: closes (open 0, unfit 1) every open cell where a body of
## edge_radius hangs over an edge of the ground (enemy_height.gd, fits). Only
## the cells within edge_radius of an area's (a rooftop's, a platform's, a
## ramp's) boundary are checked: elsewhere the ground under the body is flat.
func _close_unfit(areas: Array) -> void:
	var near := PackedByteArray()
	near.resize(open.size())
	near.fill(0)
	for rect in areas:
		var inner: Rect2 = (rect as Rect2).grow(-edge_radius)
		_for_cells_in((rect as Rect2).grow(edge_radius),
			func(k: int, c: Vector2) -> void: if not (inner.size.x > 0.0 and inner.size.y > 0.0 and inner.has_point(c)): near[k] = 1)
	for k in open.size():
		if near[k] == 1 and open[k] == 1 and not EnemyHeightScript.fits(ground, cell_centre(k), edge_radius):
			open[k] = 0
			unfit[k] = 1


## The one-way drop links (T-226): from every open cell off the ramps down to
## each of its four neighbours that is open, off the ramps and more than
## MAX_STEP lower. T-419, with edge_radius: to the first open cell up to
## drop_span cells away in each of the four directions, the cells between
## closed only because the body hangs over the edge there (not a building's)
## and off the ramps.
func _add_drops() -> void:
	var step := EnemyHeightScript.MAX_STEP
	for j in rows:
		for i in cols:
			var k := j * cols + i
			if open[k] == 0 or ramp_of[k] >= 0:
				continue
			var h := heights[k]
			for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
				for s in range(1, drop_span + 1):
					var ni: int = i + int(d[0]) * s
					var nj: int = j + int(d[1]) * s
					if ni < 0 or nj < 0 or ni >= cols or nj >= rows:
						break
					var e := nj * cols + ni
					if ramp_of[e] >= 0:
						break
					if open[e] == 0:
						if unfit[e] == 1:
							continue
						break
					if h - heights[e] > step:
						astar.connect_points(k, e, false)
						drop_links += 1
					break


## True when going from path point `a` to the next one, `b`, drops off an
## edge: they are neighbouring cells, or up to drop_span cells apart (T-419; a
## drop link), and `b`'s ground is more than MAX_STEP lower than `a`'s. A
## ramp's two points (top, then foot) are much farther apart (a ramp is 12
## units long), so going down a ramp is not a drop.
func is_drop(a: Vector2, b: Vector2) -> bool:
	return a.distance_to(b) <= CELL * drop_span * 1.01 		and _gi().height_at(a) - _gi().height_at(b) > EnemyHeightScript.MAX_STEP


## True when the four cells are open and their heights within MAX_STEP of each
## other: a corner link that cuts past no edge.
func _square_level(a: int, b: int, c: int, d: int) -> bool:
	if open[a] == 0 or open[b] == 0 or open[c] == 0 or open[d] == 0:
		return false
	var lo := minf(minf(heights[a], heights[b]), minf(heights[c], heights[d]))
	var hi := maxf(maxf(heights[a], heights[b]), maxf(heights[c], heights[d]))
	return hi - lo <= EnemyHeightScript.MAX_STEP


## Marks rough every cell whose square, grown by BASE_MARGIN, the edge of
## `rect` passes through (it overlaps `rect` without lying wholly inside it).
func _mark_rough(rect: Rect2) -> void:
	var r := rect.grow(BASE_MARGIN + CELL)
	var i0 := maxi(0, int(floor((r.position.x - origin.x) / CELL)))
	var i1 := mini(cols - 1, int(floor((r.end.x - origin.x) / CELL)))
	var j0 := maxi(0, int(floor((r.position.y - origin.y) / CELL)))
	var j1 := mini(rows - 1, int(floor((r.end.y - origin.y) / CELL)))
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			var sq := Rect2(origin + Vector2(i, j) * CELL, Vector2(CELL, CELL)).grow(BASE_MARGIN)
			if sq.intersects(rect) and not rect.encloses(sq):
				rough[j * cols + i] = 1


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
	# T-444: every minion asks for the car's surface each step; the last answer is kept.
	var gi = _gi()
	var builds: int = gi.get("builds") if gi.get("builds") != null else -1
	if units == _surface_units and is_same(gi, _surface_index) and builds == _surface_builds:
		return _surface_value
	_surface_units = units
	_surface_index = gi
	_surface_builds = builds
	_surface_value = gi.area_index_at(units)
	return _surface_value


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


## T-380: true when an enemy can walk straight from `a` to `b`: the grid's
## cells under the line (sampled every SIGHT_SAMPLE units), and under two lines
## beside it `half_width` units to either side, are open (not a building's,
## a boulder's or a prop's, other than the cells at the two ends) and each
## cell's ground is within MAX_STEP of the one before, so the line crosses no
## rooftop edge and no ramp side where the ramp is high (it may cross a ramp's
## low foot, and climb along a ramp). The same rule as the grid's links, so a
## line that is not clear has a path round.
##
## After T-405 the grid is no longer exact (a short building's platform has
## its edges on half units): where a line runs through a rough cell, the true
## ground under it is also sampled every SIGHT_FINE units and must not change
## by more than MAX_STEP between two samples. Before, a minion of T-379's size
## saw the car clear past a platform's corner that lay in a street cell, walked
## straight into the corner and stood there (its detour side pointed back
## along the platform's long side).
func line_clear(a: Vector2, b: Vector2, half_width: float = 0.0) -> bool:
	var d := b - a
	var length := d.length()
	if length < 0.001:
		return true
	var ka := cell_at(a)
	var kb := cell_at(b)
	var side := d.orthogonal() / length * half_width
	var n := maxi(1, ceili(length / SIGHT_SAMPLE))
	var offsets := [Vector2.ZERO, side, -side] if half_width > 0.0 else [Vector2.ZERO]
	for off in offsets:
		var prev := -1
		var prev_p := Vector2.ZERO
		for s in n + 1:
			var p: Vector2 = a + off + d * (float(s) / float(n))
			var k := cell_at(p)
			if k < 0:
				return false
			if prev >= 0 and (rough[k] == 1 or rough[prev] == 1) and not _ground_level(prev_p, p):
				return false
			prev_p = p
			if k == prev:
				continue
			if open[k] == 0 and k != ka and k != kb:
				return false
			if prev >= 0 and absf(heights[k] - heights[prev]) > EnemyHeightScript.MAX_STEP:
				return false
			prev = k
	return true


## True when the true ground from `a` to `b` (sampled every SIGHT_FINE units)
## changes by MAX_STEP at most between two samples: no edge on the way.
func _ground_level(a: Vector2, b: Vector2) -> bool:
	var m := maxi(1, ceili(a.distance_to(b) / SIGHT_FINE))
	var h: float = _gi().height_at(a)
	for i in range(1, m + 1):
		var g: float = _gi().height_at(a.lerp(b, float(i) / float(m)))
		if absf(g - h) > EnemyHeightScript.MAX_STEP:
			return false
		h = g
	return true


## T-444: the ground's quick lookup (enemy_ground_index.gd): the same heights and surfaces as
## `ground`, without testing every area of the map each time.
func _gi():
	return GroundIndexScript.of(ground)


## The ground's height at `units` (the same as ground.height_at), through the quick lookup.
func ground_height_at(units: Vector2) -> float:
	return _gi().height_at(units)


## A new step: the path budget (PATHS_PER_STEP) starts again.
func new_step() -> void:
	paths_this_step = 0


## True while this step's path budget is not used up.
func can_find_path() -> bool:
	return paths_this_step < PATHS_PER_STEP


## A path (units) from `from` to `to` over the streets, ramps and rooftops,
## each on the ground under it. The first point is near `from`, the last at
## `to`'s cell. Empty when there is no way (or either end is off the grid).
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	Perf.begin(&"nav.find_path")
	paths_this_step += 1
	paths_total += 1
	var a := _cell_near(from, _gi().height_at(from))
	var b := _cell_near(to, _gi().height_at(to))
	if a < 0 or b < 0:
		var _perf_r = PackedVector2Array()
		Perf.end(&"nav.find_path")
		return _perf_r
	var ids := astar.get_id_path(a, b)
	if ids.is_empty():
		var _perf_r = PackedVector2Array()
		Perf.end(&"nav.find_path")
		return _perf_r
	var _perf_r = off_edges(through_ramps(ids))
	Perf.end(&"nav.find_path")
	return _perf_r


## T-380, after T-405: moves each path point in a rough cell that is less than
## EDGE_PROBE units from higher ground (more than MAX_STEP higher) EDGE_PUSH
## units away from it. A short building's platform has its edges on half
## units, so a cell centre beside it can be 0.5 units off its edge, where a
## body that keeps BASE_MARGIN off an edge cannot stand: a minion sent there
## stood at the platform's corner, its detour side pointing back along the
## wall. Grid-aligned edges are a whole unit off every cell centre, out of
## EDGE_PROBE, so those points stay where they were. A drop's landing point
## (the point before it is higher) is left as it is (is_drop).
func off_edges(points: PackedVector2Array) -> PackedVector2Array:
	for q in points.size():
		var p := points[q]
		var k := cell_at(p)
		if k < 0 or rough[k] == 0:
			continue
		var h: float = _gi().height_at(p)
		if q > 0 and _gi().height_at(points[q - 1]) - h > EnemyHeightScript.MAX_STEP:
			continue
		var push := Vector2.ZERO
		for dir in _EDGE_DIRS:
			if _gi().height_at(p + dir * EDGE_PROBE) - h > EnemyHeightScript.MAX_STEP:
				push -= dir * EDGE_PUSH
		points[q] = p + push
	return points


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
		# T-436: also when the path starts on the ramp (i == 0, h_in is the height there): an
		# enemy on a ramp's low foot whose path only skims it used to be sent back to the foot's
		# point, off the ramp, where the next path skimmed it again; it went to and fro there.
		var skim := j + 1 < n and absf(h_out - h_in) < CLIMB_MIN
		# T-419: where the body does not fit at an end point, the path's own cells.
		var blocked := (i > 0 and not _fits_at(ramp_end(r, h_in >= mid))) \
			or (j + 1 < n and not _fits_at(ramp_end(r, h_out >= mid)))
		if skim or blocked:
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


## T-419: true when the body fits at `units`: building_margin off every
## building, prop and boulder, and (with edge_radius) off the ground's edges.
## A ramp's end point can fail it (a rooftop's air-conditioning unit right at
## a ramp's top); the path then keeps its own cells over that ramp, which the
## body fits by the grid's construction.
func _fits_at(units: Vector2) -> bool:
	if clearance(units) < building_margin:
		return false
	return edge_radius <= 0.0 or EnemyHeightScript.fits(ground, units, edge_radius)


## T-419: how far `units` is from the nearest building, prop or boulder that
## closes cells (INF with none).
func clearance(units: Vector2) -> float:
	var best := INF
	for r in block_rects:
		var rr: Rect2 = r
		var q := Vector2(clampf(units.x, rr.position.x, rr.end.x), clampf(units.y, rr.position.y, rr.end.y))
		best = minf(best, units.distance_to(q))
	for c in block_circles:
		best = minf(best, units.distance_to(c[0]) - float(c[1]))
	return best


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
