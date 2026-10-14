extends RefCounted
## The kaiju alert signs on the map (task T-130): 4 banners hanging on skyscraper walls and 2 signs standing on
## the pavement, from data/level/kaiju_signs.json (a small list the board can edit). Pictures only: sprites,
## no bodies, areas or shapes, so no collisions.
##
## A hanging banner is a Sprite2D child of its slot's art node (map_building.gd `towers`), so it fades with
## that skyscraper and follows its depth order. A pavement sign lives in the map's `alert_signs_root` under the
## buildings container, never fades, and its z is one above the block's front slot, so it is drawn over that
## skyscraper's wall behind it and under every nearer slot.

const BuildingTowers := preload("res://scripts/level/building_towers.gd")
const DATA_PATH := "res://data/level/kaiju_signs.json"
const ART_DIR := "res://art/banners/"
const PX_PER_UNIT := 16.0
const SPRITE_SCALE := 0.5
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
## Block origins on each axis (units from the map's centre) and the block and slot sizes.
const BLOCK_STARTS := [-96.0, -42.0, 12.0, 66.0]
const BLOCK_SIZE := 30.0
const SLOT_SIZE := 15.0
const SLOT_MARGIN := 1.5
const FOOT := 12.0
const SHAPE_OF := {"head": "triangle", "body": "circle"}


static func load_data(path: String = DATA_PATH) -> Array:
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	return d.signs if d is Dictionary and d.has("signs") else []


static func block_origin(block: Array) -> Vector2:
	return Vector2(BLOCK_STARTS[int(block[0])], BLOCK_STARTS[int(block[1])])


static func texture_path(design: String, kind: String) -> String:
	var shape: String = SHAPE_OF[design]
	if kind == "banner":
		return "%skaiju_%s_%s_building_wall.png" % [ART_DIR, design, shape]
	return "%skaiju_%s_%s_sign.png" % [ART_DIR, design, shape]


static func iso(p_units: Vector2) -> Vector2:
	return ISO_TRANSFORM * (p_units * PX_PER_UNIT)


## The slot's footprint (12 x 12 units) for slot [si, sj] of a block.
static func slot_footprint(block: Array, slot: Array) -> Rect2:
	var o := block_origin(block) + Vector2(int(slot[0]), int(slot[1])) * SLOT_SIZE + Vector2(SLOT_MARGIN, SLOT_MARGIN)
	return Rect2(o, Vector2(FOOT, FOOT))


## The ground point under the banner's bottom-left corner on screen, in units: along the +y wall it is
## `along` units from the wall's left end; along the +x wall it is `along` units from the front corner.
static func banner_ground_point(foot: Rect2, wall: String, along: float) -> Vector2:
	if wall == "y":
		return Vector2(foot.position.x + along, foot.end.y)
	return Vector2(foot.end.x, foot.end.y - along)


## The banner sprite's position in the slot's art node (map screen pixels). `tex` is the sheared sprite.
static func banner_sprite_position(foot: Rect2, wall: String, along: float, bottom_units: float, tex: Texture2D) -> Vector2:
	var w := float(tex.get_width())
	var front_h := float(tex.get_height()) - floorf((w - 1.0) / 2.0)
	var corner := iso(banner_ground_point(foot, wall, along)) - Vector2(0.0, bottom_units * PX_PER_UNIT)
	# +y wall: the unsheared bottom-left corner is row (front_h - 1) of column 0.
	# +x wall (flipped): the lowest bottom corner is the last row of column 0.
	var row := front_h - 1.0 if wall == "y" else float(tex.get_height()) - 1.0
	return corner - Vector2(0.0, row * SPRITE_SCALE)


## The ground point of a pavement sign, in units: the block's +x/+y corner, `inset` units in from the kerb.
static func sign_ground_point(block: Array, inset: float) -> Vector2:
	return block_origin(block) + Vector2(BLOCK_SIZE - inset, BLOCK_SIZE - inset)


static func _find_slot(map, foot: Rect2):
	for s in map.slots:
		if s.footprint.position.distance_to(foot.position) < 0.01:
			return s
	return null


## Builds every banner and sign for the map (needs map.slots, i.e. the building art loaded). Returns the sprites.
static func build(map, data: Array = []) -> Array:
	var entries: Array = data if not data.is_empty() else load_data()
	var out: Array = []
	if map.slots.is_empty():
		return out
	var root := Node2D.new()
	root.name = "AlertSigns"
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map.buildings_draw.add_child(root)
	map.alert_signs_root = root
	for e in entries:
		var tex := BuildingTowers.load_texture(texture_path(str(e.design), str(e.kind)))
		if tex == null:
			continue
		var sp := Sprite2D.new()
		sp.name = str(e.id)
		sp.texture = tex
		sp.centered = false
		sp.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
		sp.set_meta("alert_kind", str(e.kind))
		if str(e.kind) == "banner":
			var foot := slot_footprint(e.block, e.slot)
			var slot = _find_slot(map, foot)
			if slot == null:
				sp.free()
				continue
			sp.flip_h = str(e.wall) == "x"
			sp.position = banner_sprite_position(foot, str(e.wall), float(e.along), float(e.bottom_units), tex)
			sp.set_meta("ground", banner_ground_point(foot, str(e.wall), float(e.along)))
			slot.towers.add_child(sp)
		else:
			var g := sign_ground_point(e.block, float(e.inset))
			sp.position = iso(g) - Vector2(float(tex.get_width()) * 0.5, float(tex.get_height())) * SPRITE_SCALE
			sp.set_meta("ground", g)
			var front = _find_slot(map, slot_footprint(e.block, [1, 1]))
			sp.z_index = (front.z_index + 1) if front != null else 0
			root.add_child(sp)
		out.append(sp)
	return out
