extends Node2D
## The art of one city block (task T-064, round 2 sample): 2 x 2 slots of 15 x 15
## units, each holding one skyscraper body (768 x 960 art px, drawn at scale 0.5
## like the car and ground) anchored at the front corner of its 12 x 12 footprint,
## plus a script-drawn pavement per slot (`make_pavements`, kept in its own node
## at ground level so it does not fade). Which of the 4 sample variations
## (flip, sign colour, sign wall and height, facade start row, rubble) a slot
## gets comes from a fixed hash of the block's position, so it is the same on
## every run. The node is a child of the block's map_building.gd node: the block
## fades as a whole for now (per-slot fade comes with the full set).

const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
const PX_PER_UNIT := 16.0
const SPRITE_SCALE := 0.5

## One placed skyscraper: {si, sj, body (index), position (screen px)}.
var plan: Array = []
## The tallest wall, in units.
var tallest_units := 0.0
## The outline of the block's art together, in the map's screen pixels (convex).
var outline := PackedVector2Array()
## The pavement node (a child of nothing until the map adds it under the buildings).
var pavement_root: Node2D

var _art: Dictionary = {}


static func hash_of(block_x: int, block_y: int) -> int:
	var h := ((block_x * 73856093) ^ (block_y * 83492791)) & 0xFFFFFFFF
	h = (h * 0x2C1B3C6D) & 0xFFFFFFFF
	h ^= h >> 12
	h = (h * 0x297A2D39) & 0xFFFFFFFF
	h ^= h >> 15
	return h


## Body index per slot: the four slots of a block always differ (a rotation of 0..3).
static func make_plan(block_x: int, block_y: int) -> Array:
	var shift := hash_of(block_x, block_y) % 4
	var out: Array = []
	for sj in 2:
		for si in 2:
			out.append({"si": si, "sj": sj, "body": (si + 2 * sj + shift) % 4})
	return out


static func load_texture(path: String) -> Texture2D:
	var t := load(path) as Texture2D
	if t != null:
		return t
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	return ImageTexture.create_from_image(img) if img != null else null


## Builds the sprites. `footprint_units` is the block's footprint (units from the map's centre).
func setup(art: Dictionary, _atlas: Texture2D, footprint_units: Rect2) -> void:
	_art = art
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var slot := float(art.slot_units)
	var foot := float(art.foot_units)
	var margin := float(art.margin_units)
	var bsize := Vector2(float(art.body_size[0]), float(art.body_size[1]))
	var bodies: Array = []
	for p in art.bodies:
		bodies.append(load_texture(str(p)))
	var pavs: Array = []
	for p in art.pavements:
		pavs.append(load_texture(str(p)))
	plan = make_plan(roundi(footprint_units.position.x), roundi(footprint_units.position.y))
	plan.sort_custom(func(p, q):
		var a: int = p.si + p.sj
		var b: int = q.si + q.sj
		if a != b:
			return a < b
		return p.si < q.si)
	pavement_root = Node2D.new()
	pavement_root.name = "Pavements"
	pavement_root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var points := PackedVector2Array()
	for e in plan:
		var origin := footprint_units.position + Vector2(e.si * slot, e.sj * slot)
		var pv := Sprite2D.new()
		pv.name = "Pavement_%d_%d" % [e.si, e.sj]
		pv.texture = pavs[e.si + 2 * e.sj]
		pv.centered = false
		var pw: float = pv.texture.get_width()
		pv.position = ISO_TRANSFORM * (origin * PX_PER_UNIT) - Vector2(pw * 0.5, 0.0) * SPRITE_SCALE
		pv.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
		pavement_root.add_child(pv)
		var corner := origin + Vector2(margin + foot, margin + foot)
		var pos := ISO_TRANSFORM * (corner * PX_PER_UNIT) - Vector2(bsize.x * 0.5, bsize.y) * SPRITE_SCALE
		var sp := Sprite2D.new()
		sp.name = "Skyscraper_%d_%d" % [e.si, e.sj]
		sp.texture = bodies[e.body]
		sp.centered = false
		sp.position = pos
		sp.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
		add_child(sp)
		e["position"] = pos
		var w := bsize.x
		var h := bsize.y
		for q in [Vector2(0, 0), Vector2(w, 0), Vector2(w, h - 192.0), Vector2(w * 0.5, h), Vector2(0, h - 192.0)]:
			points.append(pos + q * SPRITE_SCALE)
	tallest_units = float(art.height_units)
	outline = Geometry2D.convex_hull(points)
	if not outline.is_empty() and outline[0] == outline[outline.size() - 1]:
		outline.remove_at(outline.size() - 1)
