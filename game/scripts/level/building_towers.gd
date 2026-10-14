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
## Short building bodies (task T-129): 4 designs x 2 looks.
const SHORT_BODIES := 8

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
	var short := short_slots(block_x, block_y)
	var short_base := (hash_of(block_x + 31, block_y + 17) >> 5) % SHORT_BODIES
	var short_count := 0
	var out: Array = []
	for sj in 2:
		for si in 2:
			var tower := (base + si + 3 * sj) % TOWERS
			var variant := (h >> (4 + si + 2 * sj)) & 1
			var is_short := Vector2i(si, sj) in short
			# Two short buildings in a block are 3 apart in the list of 8 (4 designs x 2 looks): never the same design.
			out.append({"si": si, "sj": sj, "tower": tower, "variant": variant, "body": tower * VARIANTS + variant,
				"short": is_short, "short_body": (short_base + 3 * short_count) % SHORT_BODIES})
			if is_short:
				short_count += 1
	return out


## Which slots hold a short building (task T-129): the front slot (1,1) half the time, and one of the
## side slots (1,0) or (0,1) 40% of the time; the back slot (0,0) never (a tall tower in front would hide a
## roof behind it). About 0.9 short buildings per block, from a fixed hash of the block's position.
static func short_slots(block_x: int, block_y: int) -> Array:
	var h := hash_of(block_x + 7919, block_y + 104729)
	var out: Array = []
	if h % 100 < 50:
		out.append(Vector2i(1, 1))
	if (h >> 8) % 100 < 40:
		out.append(Vector2i(1, 0) if (h >> 16) % 2 == 0 else Vector2i(0, 1))
	return out


## The fade outline of a short building's sprite (w x h art px, task T-129), in sprite pixels: six points
## following the roof diamond on top and the two walls' bottom edges. The roof's back edges fall 2:1 from the
## centre, so the side corners sit w / 4 below the top. One pixel of margin on every point takes in the pixel
## steps of the 2:1 edges, so every opaque pixel lies inside. Unlike the skyscrapers' outline (a full-width
## top), it leaves out the empty triangles above the roof's back edges, so a car on the road behind the roof
## does not fade the building (T-034: only the building covering the car fades).
static func short_outline(w: float, h: float) -> Array:
	var drop := w * 0.25
	return [Vector2(w * 0.5, -1.0), Vector2(w, drop - 1.0), Vector2(w, h - drop + 1.0),
		Vector2(w * 0.5, h + 1.0), Vector2(0.0, h - drop + 1.0), Vector2(0.0, drop - 1.0)]


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
	var short_texs: Array = []
	if art.has("short"):
		for p in art.short.bodies:
			short_texs.append(load_texture(str(p)))
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
		var is_short: bool = e.short and not short_texs.is_empty()
		var short_tex: Texture2D = short_texs[e.short_body] if is_short else null
		var sz := Vector2(short_tex.get_width(), short_tex.get_height()) if is_short else bsize
		var pos := ISO_TRANSFORM * (foot_rect.end * PX_PER_UNIT) - Vector2(sz.x * 0.5, sz.y) * SPRITE_SCALE
		var hull := PackedVector2Array()
		var w := sz.x
		var h := sz.y
		# A short building's outline follows its roof (short_outline); a skyscraper keeps its 5-point outline.
		var shape: Array = short_outline(w, h) if is_short else [Vector2(0, 0), Vector2(w, 0), Vector2(w, h - 192.0), Vector2(w * 0.5, h), Vector2(0, h - 192.0)]
		for q in shape:
			hull.append(pos + q * SPRITE_SCALE)
			points.append(pos + q * SPRITE_SCALE)
		# The slot's own fade node: footprint, silhouette and a child sprite.
		var node = MapBuilding.new()
		node.name = ("Short_%d_%d" if is_short else "Skyscraper_%d_%d") % [e.si, e.sj]
		node.footprint = foot_rect
		node.height_units = float(art.short.height_units) if is_short else float(art.height_units)
		node.custom_silhouette = hull
		node.draw_placeholder = false
		var art_node := Node2D.new()
		art_node.name = "Art"
		var sp := Sprite2D.new()
		sp.name = "Sprite"
		sp.texture = short_tex if is_short else load_texture(str(art.bodies[e.body]))
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
