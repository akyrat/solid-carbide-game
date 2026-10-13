extends Node2D
## The final art of one city block (task T-064): a dense 7 x 7 grid of narrow
## towers, each one sprite from the building atlas (buildings.json), drawn at
## the art's scale (32 art pixels per unit, 16 world pixels per unit, so 0.5)
## in the map's screen pixels of the isometric view. The node is a child of
## the block's map_building.gd node, so the block's fade (its modulate) fades
## every tower together; the towers keep no semi-transparent pixels.
##
## Which tower, mirror, neon colour and height goes where comes from a fixed
## integer hash of the block's position and the tower's grid place, so it is
## the same on every map and every run. Neighbouring towers are always
## different base towers.

const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
const PX_PER_UNIT := 16.0
## Art pixels per unit in the atlas; the sprites are drawn at half size (SPRITE_SCALE).
const ART_PX_PER_UNIT := 32.0
const SPRITE_SCALE := 0.5
## Towers per side, the distance between two towers' front corners and the
## ground one tower takes, in units (a 30 x 30 block: 6 * 4.5 + 3 = 30).
const GRID := 7
const PITCH := 4.5
const CELL := 3.0
const BASE_TOWERS := 8

## One placed tower: {gx, gy, variant (id), tower, position (screen px)}.
var plan: Array = []
## The tallest tower, in units.
var tallest_units := 0.0
## The outline of every tower together, in the map's screen pixels (convex).
var outline := PackedVector2Array()

var _art: Dictionary = {}


static func hash_of(gx: int, gy: int, block_x: int, block_y: int) -> int:
	var h := ((gx * 73856093) ^ (gy * 19349663) ^ (block_x * 83492791) ^ (block_y * 2654435761)) & 0xFFFFFFFF
	# Mix the bits, so blocks that differ in a few bits still differ in every choice.
	h = (h * 0x2C1B3C6D) & 0xFFFFFFFF
	h ^= h >> 12
	h = (h * 0x297A2D39) & 0xFFFFFFFF
	h ^= h >> 15
	return h


## Groups the atlas JSON's variants by base tower: tower number -> Array of variant dictionaries.
static func by_tower(art: Dictionary) -> Dictionary:
	var out := {}
	for v in art.get("variants", []):
		var t := int(v.tower)
		if not out.has(t):
			out[t] = []
		out[t].append(v)
	return out


## The plan of one block whose footprint starts at (block_x, block_y): for each
## grid place the variant id and base tower. No nodes: tests run it directly.
static func make_plan(art: Dictionary, block_x: int, block_y: int) -> Array:
	var groups := by_tower(art)
	var towers: Array = groups.keys()
	towers.sort()
	var n := towers.size()
	var out: Array = []
	if n == 0:
		return out
	var shift := hash_of(0, 0, block_x, block_y) % n
	for gy in GRID:
		for gx in GRID:
			# Steps of 1 (along x) and 3 (along y) are never 0 modulo 8, and neither is
			# a step times 3, so neighbouring towers are always different base towers.
			var k := ((gx + 3 * gy + shift) * 3) % n
			var list: Array = groups[towers[k]]
			var h := hash_of(gx, gy, block_x, block_y)
			var v: Dictionary = list[(h >> 4) % list.size()]
			out.append({"gx": gx, "gy": gy, "variant": str(v.id), "tower": int(v.tower)})
	return out


## Builds the sprites. `footprint_units` is the block's footprint (units from the map's centre).
func setup(art: Dictionary, atlas: Texture2D, footprint_units: Rect2) -> void:
	_art = art
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var by_id := {}
	for v in art.variants:
		by_id[str(v.id)] = v
	plan = make_plan(art, roundi(footprint_units.position.x), roundi(footprint_units.position.y))
	# Back to front: the far corner first.
	plan.sort_custom(func(p, q):
		var a: int = p.gx + p.gy
		var b: int = q.gx + q.gy
		if a != b:
			return a < b
		return p.gx < q.gx)
	var points := PackedVector2Array()
	for e in plan:
		var v: Dictionary = by_id[e.variant]
		# The tower's front-bottom (south) corner on the ground, in units.
		var corner := footprint_units.position + Vector2(e.gx * PITCH + CELL, e.gy * PITCH + CELL)
		var anchor := Vector2(float(v.anchor[0]), float(v.anchor[1]))
		var pos := ISO_TRANSFORM * (corner * PX_PER_UNIT) - anchor * SPRITE_SCALE
		var sp := Sprite2D.new()
		sp.name = "Tower_%d_%d" % [e.gx, e.gy]
		sp.texture = atlas
		sp.region_enabled = true
		var r: Array = v.region
		sp.region_rect = Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
		sp.centered = false
		sp.position = pos
		sp.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
		add_child(sp)
		e["position"] = pos
		tallest_units = maxf(tallest_units, float(v.height_units))
		for p in v.hull:
			points.append(pos + Vector2(float(p[0]), float(p[1])) * SPRITE_SCALE)
	outline = Geometry2D.convex_hull(points)
	if not outline.is_empty() and outline[0] == outline[outline.size() - 1]:
		outline.remove_at(outline.size() - 1)
