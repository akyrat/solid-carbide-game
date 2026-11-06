extends RefCounted
## A quick lookup of the ground's heights for the enemies (task T-444, "The game stays fast
## with a crowd of minions"). GroundHeight.height_at and area_index_at (ground_height.gd) test
## every rooftop, short building and ramp of the map, and an enemy asks them many times a step
## (its height, the edges round each move, its surface, the depth order): on Kaiju City that
## was most of a minion's step. This index puts each area's rectangle in the BUCKET by BUCKET
## unit buckets it touches, once, and answers the same two questions from one bucket's few
## areas, through GroundHeight's own height_among and area_among (T-411, made for the car's
## footprint), which give exactly what height_at and area_index_at give anywhere inside the
## box they were asked for. Off every area's bounding box the answer is the street's (0, -1).
##
## One per GroundHeight, kept in its meta (of()). It is rebuilt when the ground's platform or
## ramp list is replaced or grows or shrinks (a level loaded again, a test adding a platform);
## a rectangle changed in place inside the lists is not seen, and nothing in the game does that.
## It answers like a GroundHeight for height_at and area_index_at, so enemy_height.gd passes it
## where it passed the ground.

const META_KEY := "enemy_ground_index"
## Bucket size, units. A rooftop or ramp is 6 to 80 units across; a bucket of 4 has a handful.
const BUCKET := 4.0

## Marks an index (of() returns one given in place of a ground as it is).
var is_enemy_ground_index := true
var ground = null
var origin := Vector2.ZERO
var cols := 0
var rows := 0
## The bounding box of every area (closed), units; outside it is the street.
var bounds := Rect2()
## Per bucket: {"ramps": [...], "platforms": [...]} (GroundHeight.areas_near's form), or an
## empty one shared by every bucket with no area.
var buckets: Array = []
var _platforms_ref: Array = []
var _ramps_ref: Array = []
var _sizes := Vector2i(-1, -1)
## How many times it was built (tests).
var builds := 0
## T-538: goes up by one every time any index is built, so what an enemy kept from an index
## (minion.gd: its ground height and its index) is read again after a rebuild.
static var generation := 0


## The index of `ground` (a GroundHeight), built on first use and kept in its meta; rebuilt
## when its lists changed (see the top). An index given in place of a ground is returned as it
## is; null stays null.
static func of(ground):
	if ground == null:
		return null
	if ground.get("is_enemy_ground_index") == true:
		return ground
	# Anything else that answers height_at (not a GroundHeight) is asked as it is.
	if not ground.has_method("height_among"):
		return ground
	var idx = ground.get_meta(META_KEY) if ground.has_meta(META_KEY) else null
	if idx == null:
		idx = load("res://scripts/enemies/enemy_ground_index.gd").new()
		ground.set_meta(META_KEY, idx)
	if not idx.is_current(ground):
		idx.build(ground)
	return idx


## True when it was built from `g`'s current platform and ramp lists.
func is_current(g) -> bool:
	return ground == g and is_same(_platforms_ref, g.platforms) and is_same(_ramps_ref, g.ramps) \
		and _sizes == Vector2i(g.platforms.size(), g.ramps.size())


func build(g) -> void:
	ground = g
	_platforms_ref = g.platforms
	_ramps_ref = g.ramps
	_sizes = Vector2i(g.platforms.size(), g.ramps.size())
	builds += 1
	generation += 1
	buckets = []
	var rects: Array = []
	for p in g.platforms:
		rects.append(p.rect)
	for r in g.ramps:
		rects.append(r.rect)
	if rects.is_empty():
		bounds = Rect2()
		cols = 0
		rows = 0
		return
	bounds = rects[0]
	for r in rects:
		bounds = bounds.merge(r)
	origin = bounds.position
	cols = maxi(1, ceili(bounds.size.x / BUCKET) + 1)
	rows = maxi(1, ceili(bounds.size.y / BUCKET) + 1)
	var empty := {"ramps": [], "platforms": []}
	buckets.resize(cols * rows)
	buckets.fill(empty)
	for i in g.ramps.size():
		_add(g.ramps[i].rect, "ramps", i, empty)
	for i in g.platforms.size():
		_add(g.platforms[i].rect, "platforms", i, empty)


## Adds area `i` of `kind` to every bucket its rectangle touches (borders included).
func _add(rect: Rect2, kind: String, i: int, empty: Dictionary) -> void:
	var i0 := clampi(int(floor((rect.position.x - origin.x) / BUCKET)) - 1, 0, cols - 1)
	var i1 := clampi(int(floor((rect.end.x - origin.x) / BUCKET)) + 1, 0, cols - 1)
	var j0 := clampi(int(floor((rect.position.y - origin.y) / BUCKET)) - 1, 0, rows - 1)
	var j1 := clampi(int(floor((rect.end.y - origin.y) / BUCKET)) + 1, 0, rows - 1)
	for j in range(j0, j1 + 1):
		for k in range(i0, i1 + 1):
			if not rect.intersects(bucket_rect(k, j), true):
				continue
			var n := j * cols + k
			if is_same(buckets[n], empty):
				buckets[n] = {"ramps": [], "platforms": []}
			buckets[n][kind].append(i)


## The box of bucket (i, j), units.
func bucket_rect(i: int, j: int) -> Rect2:
	return Rect2(origin + Vector2(i, j) * BUCKET, Vector2(BUCKET, BUCKET))


## The areas near `point` (GroundHeight.areas_near's form), or null off every area's box.
func near(point: Vector2):
	if cols == 0 or point.x < bounds.position.x or point.y < bounds.position.y \
			or point.x > bounds.end.x or point.y > bounds.end.y:
		return null
	var i := mini(int(floor((point.x - origin.x) / BUCKET)), cols - 1)
	var j := mini(int(floor((point.y - origin.y) / BUCKET)), rows - 1)
	return buckets[j * cols + i]


## GroundHeight.height_at(point), the same number.
func height_at(point: Vector2) -> float:
	var n = near(point)
	if n == null:
		return 0.0
	return ground.height_among(point, n)


## GroundHeight.area_index_at(point), the same index.
func area_index_at(point: Vector2) -> int:
	var n = near(point)
	if n == null:
		return -1
	return ground.area_among(point, n)


## True when no rooftop, short building or ramp touches `box` (units, borders included): the
## ground is the street's (height 0) everywhere in it.
func flat_street(box: Rect2) -> bool:
	if cols == 0 or not box.intersects(bounds, true):
		return true
	var i0 := clampi(int(floor((box.position.x - origin.x) / BUCKET)), 0, cols - 1)
	var i1 := clampi(int(floor((box.end.x - origin.x) / BUCKET)), 0, cols - 1)
	var j0 := clampi(int(floor((box.position.y - origin.y) / BUCKET)), 0, rows - 1)
	var j1 := clampi(int(floor((box.end.y - origin.y) / BUCKET)), 0, rows - 1)
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			var b: Dictionary = buckets[j * cols + i]
			if not b.ramps.is_empty() or not b.platforms.is_empty():
				return false
	return true
