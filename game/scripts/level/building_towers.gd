extends Node2D
## The art of one city block (task T-064): 2 x 2 slots of 15 x 15 units, each
## holding one skyscraper (a 768 x 960 art px body drawn at scale 0.5 like the
## car and ground, anchored at the front corner of its 12 x 12 footprint), plus
## a script-drawn pavement per slot.
##
## Each slot's skyscraper is its own fade node (`slot_nodes`, map_building.gd):
## only the skyscraper covering the car fades, not its whole block. The map adds
## the slot nodes to its buildings container and keeps them in `map.slots`. The
## pavement sprites live in `pavement_root`, which the map adds at ground level
## so the pavement never fades.
##
## Which of the 6 skyscrapers and which of its 2 variants (flip, sign wall and
## height, facade bands, rubble) a slot gets comes from a fixed hash of the
## block's position, so it is the same on every run. The four slots of a block
## are four different skyscrapers.

const MapBuilding := preload("res://scripts/level/map_building.gd")
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
const PX_PER_UNIT := 16.0
const SPRITE_SCALE := 0.5
const TOWERS := 6
const VARIANTS := 2

## One placed skyscraper: {si, sj, tower (0..5), variant (0..1), body (index), position (screen px)}.
var plan: Array = []
## The tallest wall, in units.
var tallest_units := 0.0
## The outline of the block's art together, in the map's screen pixels (convex).
var outline := PackedVector2Array()
## The pavement node (the map adds it under the buildings container, at ground level).
var pavement_root: Node2D
## The slots' fade nodes (map_building.gd), back to front.
var slot_nodes: Array = []

var _art: Dictionary = {}


static func hash_of(block_x: int, block_y: int) -> int:
	var h := ((block_x * 73856093) ^ (block_y * 83492791)) & 0xFFFFFFFF
	h = (h * 0x2C1B3C6D) & 0xFFFFFFFF
	h ^= h >> 12
	h = (h * 0x297A2D39) & 0xFFFFFFFF
	h ^= h >> 15
	return h


## The skyscraper and variant per slot of the block at (block_x, block_y). The four slots always
## differ (tower steps 0, 1, 3 and 4 are different modulo 6); neighbouring blocks are shifted by their position.
static func make_plan(block_x: int, block_y: int) -> Array:
	var h := hash_of(block_x, block_y)
	var base := (h + posmod(floori(block_x / 30.0), 6) * 2 + posmod(floori(block_y / 30.0), 6) * 3) % TOWERS
	var out: Array = []
	for sj in 2:
		for si in 2:
			var tower := (base + si + 3 * sj) % TOWERS
			var variant := (h >> (4 + si + 2 * sj)) & 1
			out.append({"si": si, "sj": sj, "tower": tower, "variant": variant, "body": tower * VARIANTS + variant})
	return out


static func load_texture(path: String) -> Texture2D:
	var t := load(path) as Texture2D
	if t != null:
		return t
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	return ImageTexture.create_from_image(img) if img != null else null


## Builds the pavement sprites and the slot nodes. `footprint_units` is the block's footprint (units from the map's centre).
func setup(art: Dictionary, _atlas: Texture2D, footprint_units: Rect2) -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var slot := float(art.slot_units)
	var foot := float(art.foot_units)
	var margin := float(art.margin_units)
	var bsize := Vector2(float(art.body_size[0]), float(art.body_size[1]))
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
		pv.position = ISO_TRANSFORM * (origin * PX_PER_UNIT) - Vector2(float(pv.texture.get_width()) * 0.5, 0.0) * SPRITE_SCALE
		pv.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
		pavement_root.add_child(pv)
		var foot_rect := Rect2(origin + Vector2(margin, margin), Vector2(foot, foot))
		var pos := ISO_TRANSFORM * (foot_rect.end * PX_PER_UNIT) - Vector2(bsize.x * 0.5, bsize.y) * SPRITE_SCALE
		var hull := PackedVector2Array()
		var w := bsize.x
		var h := bsize.y
		for q in [Vector2(0, 0), Vector2(w, 0), Vector2(w, h - 192.0), Vector2(w * 0.5, h), Vector2(0, h - 192.0)]:
			hull.append(pos + q * SPRITE_SCALE)
			points.append(pos + q * SPRITE_SCALE)
		# The slot's own fade node: footprint, silhouette and a child sprite.
		var node = MapBuilding.new()
		node.name = "Skyscraper_%d_%d" % [e.si, e.sj]
		node.footprint = foot_rect
		node.height_units = float(art.height_units)
		node.custom_silhouette = hull
		node.draw_placeholder = false
		var art_node := Node2D.new()
		art_node.name = "Art"
		var sp := Sprite2D.new()
		sp.name = "Sprite"
		sp.texture = load_texture(str(art.bodies[e.body]))
		sp.centered = false
		sp.position = pos
		sp.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
		art_node.add_child(sp)
		node.add_child(art_node)
		node.towers = art_node
		slot_nodes.append(node)
		e["position"] = pos
	tallest_units = float(art.height_units)
	outline = Geometry2D.convex_hull(points)
	if not outline.is_empty() and outline[0] == outline[outline.size() - 1]:
		outline.remove_at(outline.size() - 1)
