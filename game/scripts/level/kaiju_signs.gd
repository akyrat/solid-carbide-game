extends RefCounted
## The kaiju alert signs of a level (task T-441; Level design, Decisions, "Kaiju alert signs are level
## creator pieces"): placed by the board in the level creator and written to the level file's
## "alert_signs" list. The fixed list of T-130 (data/level/kaiju_signs.json) is retired: a map shows only
## the signs its own level places. Pictures only: sprites, no bodies, areas or shapes, so no collisions.
##
## Two kinds, each in two designs (head: red triangle, body: red circle), with the art of T-130
## (art/banners/, game/tools/build_kaiju_banners.py):
## - a standing sign {id, asset: "alert-sign-<design>", x, y, w, h, mirror}: x, y, w, h is the cell it
##   stands on (units); its post stands on the cell's middle, at the height of what is under it (the
##   street, a rooftop, a short building, a ramp; GroundHeight). "mirror" flips the picture.
## - a banner {id, asset: "alert-banner-<design>", building: [x, y], wall, along, bottom_units}: hangs on
##   the skyscraper of the level's `buildings` standing at x, y (never on a platform or a short building),
##   on its "south" wall (the +y face) or its "east" wall (the +x face), `along` units from the wall's
##   left end on screen, its bottom `bottom_units` above the ground.
##
## In a run (and in the creator's drawing, the same code) a banner is a Sprite2D child of its skyscraper's
## art node (map_building.gd `towers`), so it fades with that skyscraper and shares its depth (T-130's
## look: the 2:1-sheared sprite, flipped for the east wall). A standing sign is a LevelProps.PropSprite
## under the map's `alert_signs_root`, listed in `map.alert_sign_sprites`, so it takes part in the depth
## order like a prop's sprite (map.depth_sprites: the buildings, rooftops and the car).
##
## This script is the one place for the signs' geometry; the level creator (LevelDocument, editor.gd)
## reads it too.

const BuildingTowers := preload("res://scripts/level/building_towers.gd")
const ART_DIR := "res://art/banners/"
const PX_PER_UNIT := 16.0
const SPRITE_SCALE := 0.5
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
## A skyscraper's height in units (art/buildings/skyscrapers.json height_units), for finding the one
## under the mouse on screen.
const SKYSCRAPER_HEIGHT := 30.0
const SHAPE_OF := {"head": "triangle", "body": "circle"}
const DESIGNS := ["head", "body"]
## The two walls a banner hangs on (the two a skyscraper shows): south = the +y face, east = the +x face.
const WALLS := ["south", "east"]
## A standing sign's cell (units).
const SIGN_CELL := 2.0

static var _textures: Dictionary = {}


## The signs a layout (a level's data) lists.
static func items_of(layout: Dictionary) -> Array:
	var l = layout.get("alert_signs", [])
	return l if l is Array else []


## "sign" or "banner" for a catalogue id or a placed item's asset ("" for neither).
static func kind_of_asset(asset: String) -> String:
	if asset.begins_with("alert-sign-"):
		return "sign"
	if asset.begins_with("alert-banner-"):
		return "banner"
	return ""


static func kind_of(item: Dictionary) -> String:
	return kind_of_asset(str(item.get("asset", "")))


## "head" or "body" (the design) of a catalogue id or an item's asset.
static func design_of_asset(asset: String) -> String:
	var d := asset.get_slice("-", asset.get_slice_count("-") - 1)
	return d if d in DESIGNS else "head"


static func design_of(item: Dictionary) -> String:
	return design_of_asset(str(item.get("asset", "")))


static func texture_path(design: String, kind: String) -> String:
	var shape: String = SHAPE_OF.get(design, "triangle")
	if kind == "banner":
		return "%skaiju_%s_%s_building_wall.png" % [ART_DIR, design, shape]
	return "%skaiju_%s_%s_sign.png" % [ART_DIR, design, shape]


static func texture_of(item: Dictionary) -> Texture2D:
	var path := texture_path(design_of(item), kind_of(item))
	if not _textures.has(path):
		_textures[path] = BuildingTowers.load_texture(path)
	return _textures[path]


static func iso(p_units: Vector2) -> Vector2:
	return ISO_TRANSFORM * (p_units * PX_PER_UNIT)


## "south" or "east" for a wall name (T-130's "y" and "x" too).
static func wall_name(wall: String) -> String:
	return "east" if wall in ["east", "x"] else "south"


# ---- Banners ------------------------------------------------------------------------------------

## True for a building entry a banner can hang on: a skyscraper placed in the level creator (never a
## platform, a short building, a small or long building, or a whole block of the old map).
static func can_hang_on(building: Dictionary) -> bool:
	return str(building.get("asset", "")).begins_with("skyscraper-")


static func building_rect(building: Dictionary) -> Rect2:
	return Rect2(float(building.x), float(building.y), float(building.w), float(building.h))


## The skyscraper entry of `layout` a banner hangs on ({} when it is gone).
static func building_of(layout: Dictionary, item: Dictionary) -> Dictionary:
	var at = item.get("building", [])
	if not (at is Array) or at.size() < 2:
		return {}
	for b in layout.get("buildings", []):
		if can_hang_on(b) and absf(float(b.x) - float(at[0])) < 0.01 and absf(float(b.y) - float(at[1])) < 0.01:
			return b
	return {}


## How far a banner reaches along its wall, in units (its picture is 3 units wide).
static func banner_length(tex: Texture2D) -> float:
	return float(tex.get_width()) * SPRITE_SCALE / PX_PER_UNIT if tex != null else 3.0


## The largest `along` on a wall of `foot` for a banner of `tex`: the banner stays on the wall.
static func max_along(foot: Rect2, wall: String, tex: Texture2D) -> float:
	var wall_len := foot.size.x if wall_name(wall) == "south" else foot.size.y
	return maxf(0.0, wall_len - banner_length(tex))


## The ground point under the banner's bottom-left corner on screen, in units: along the south (+y) wall
## it is `along` units from the wall's left end; along the east (+x) wall `along` units from the front corner.
static func banner_ground_point(foot: Rect2, wall: String, along: float) -> Vector2:
	if wall_name(wall) == "south":
		return Vector2(foot.position.x + along, foot.end.y)
	return Vector2(foot.end.x, foot.end.y - along)


## The ground point at the left end of a wall on screen (where `along` is 0).
static func wall_start(foot: Rect2, wall: String) -> Vector2:
	return banner_ground_point(foot, wall, 0.0)


## The banner sprite's position in the slot's art node (map screen pixels). `tex` is the sheared sprite.
static func banner_sprite_position(foot: Rect2, wall: String, along: float, bottom_units: float, tex: Texture2D) -> Vector2:
	var w := float(tex.get_width())
	var front_h := float(tex.get_height()) - floorf((w - 1.0) / 2.0)
	var corner := iso(banner_ground_point(foot, wall, along)) - Vector2(0.0, bottom_units * PX_PER_UNIT)
	# South wall: the unsheared bottom-left corner is row (front_h - 1) of column 0.
	# East wall (flipped): the lowest bottom corner is the last row of column 0.
	var row := front_h - 1.0 if wall_name(wall) == "south" else float(tex.get_height()) - 1.0
	return corner - Vector2(0.0, row * SPRITE_SCALE)


## The banner's outline on screen (map screen pixels): the parallelogram on the wall.
static func banner_quad(foot: Rect2, wall: String, along: float, bottom_units: float, tex: Texture2D) -> PackedVector2Array:
	var length := banner_length(tex)
	var a := banner_ground_point(foot, wall, along)
	var b := banner_ground_point(foot, wall, along + length)
	var h := (float(tex.get_height()) - floorf((float(tex.get_width()) - 1.0) / 2.0)) * SPRITE_SCALE if tex != null else 48.0
	var lift := Vector2(0.0, bottom_units * PX_PER_UNIT)
	return PackedVector2Array([iso(a) - lift, iso(b) - lift, iso(b) - lift - Vector2(0, h), iso(a) - lift - Vector2(0, h)])


## A skyscraper's outline on screen (map screen pixels): its footprint and its top, as one convex shape.
static func skyscraper_outline(foot: Rect2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var up := Vector2(0.0, SKYSCRAPER_HEIGHT * PX_PER_UNIT)
	for c in [foot.position, Vector2(foot.end.x, foot.position.y), foot.end, Vector2(foot.position.x, foot.end.y)]:
		pts.append(iso(c))
		pts.append(iso(c) - up)
	return Geometry2D.convex_hull(pts)


## The skyscraper of `layout` drawn at the screen point `screen` (map screen pixels; the nearest to the
## viewer when several overlap there), {} for none.
static func skyscraper_at_screen(layout: Dictionary, screen: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_key := -INF
	for b in layout.get("buildings", []):
		if not can_hang_on(b):
			continue
		var foot := building_rect(b)
		if Geometry2D.is_point_in_polygon(screen, skyscraper_outline(foot)) and foot.end.x + foot.end.y > best_key:
			best = b
			best_key = foot.end.x + foot.end.y
	return best


## Where a banner of `asset` goes with the mouse at the screen point `screen` (map screen pixels): the
## skyscraper drawn there, on `wall`, centred on the mouse along the wall (in half units, kept on the
## wall), `bottom_units` up. {building, wall, along, bottom_units} or {} when no skyscraper is there.
static func banner_target(layout: Dictionary, asset: String, screen: Vector2, wall: String, bottom_units: float) -> Dictionary:
	var b := skyscraper_at_screen(layout, screen)
	if b.is_empty():
		return {}
	var foot := building_rect(b)
	var tex := texture_of({"asset": asset})
	var along := (screen.x - iso(wall_start(foot, wall)).x) / PX_PER_UNIT - banner_length(tex) / 2.0
	along = clampf(roundf(along * 2.0) / 2.0, 0.0, max_along(foot, wall, tex))
	return {"building": b, "wall": wall_name(wall), "along": along, "bottom_units": bottom_units}


# ---- Standing signs -----------------------------------------------------------------------------

## The ground point a standing sign stands on (units): the middle of its cell.
static func sign_ground_point(item: Dictionary) -> Vector2:
	return Vector2(float(item.x) + float(item.get("w", SIGN_CELL)) / 2.0, float(item.y) + float(item.get("h", SIGN_CELL)) / 2.0)


## The standing sign's sprite position (map screen pixels): the post's foot on the ground point, lifted by
## the height `ground_h` (units) it stands on.
static func sign_sprite_position(ground: Vector2, ground_h: float, tex: Texture2D) -> Vector2:
	return iso(ground) - Vector2(float(tex.get_width()) * 0.5, float(tex.get_height())) * SPRITE_SCALE \
		- Vector2(0.0, ground_h * PX_PER_UNIT)


## The standing sign's picture on screen (map screen pixels), as four corners.
static func sign_quad(ground: Vector2, ground_h: float, tex: Texture2D) -> PackedVector2Array:
	var p := sign_sprite_position(ground, ground_h, tex)
	var s := Vector2(tex.get_width(), tex.get_height()) * SPRITE_SCALE
	return PackedVector2Array([p, p + Vector2(s.x, 0), p + s, p + Vector2(0, s.y)])


# ---- Both ---------------------------------------------------------------------------------------

## The picture of a placed sign or banner on screen (map screen pixels), for selecting it in the creator
## and its outline there. `ground` is a GroundHeight of the layout (for a standing sign's height). Empty
## for a banner whose skyscraper is gone.
static func screen_quad(layout: Dictionary, item: Dictionary, ground = null) -> PackedVector2Array:
	var tex := texture_of(item)
	if tex == null:
		return PackedVector2Array()
	if kind_of(item) == "banner":
		var b := building_of(layout, item)
		if b.is_empty():
			return PackedVector2Array()
		return banner_quad(building_rect(b), str(item.get("wall", "south")), float(item.get("along", 0.0)),
			float(item.get("bottom_units", 3.0)), tex)
	var g := sign_ground_point(item)
	var h: float = ground.height_at(g) if ground != null else 0.0
	return sign_quad(g, h, tex)


static func _find_slot(map, foot: Rect2):
	for s in map.slots:
		if s.footprint.position.distance_to(foot.position) < 0.01 and s.footprint.size.distance_to(foot.size) < 0.01:
			return s
	return null


static func _bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var r := Rect2(points[0], Vector2.ZERO)
	for p in points:
		r = r.expand(p)
	return r


## Builds the signs and banners of `map.layout` (needs map.slots, i.e. the building art loaded, and the
## map's view_root). Returns the sprites (also map.alert_signs). A level without "alert_signs" gets none.
static func build(map) -> Array:
	var items := items_of(map.layout)
	var out: Array = []
	if items.is_empty():
		return out
	var root := Node2D.new()
	root.name = "AlertSigns"
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map.view_root.add_child(root)
	map.alert_signs_root = root
	var ground := GroundHeight.new()
	ground.load_data(map.layout)
	for it in items:
		var kind := kind_of(it)
		var tex := texture_of(it)
		if kind == "" or tex == null:
			continue
		if kind == "banner":
			var b := building_of(map.layout, it)
			var slot = _find_slot(map, building_rect(b)) if not b.is_empty() else null
			if slot == null:
				continue
			var foot := building_rect(b)
			var wall := wall_name(str(it.get("wall", "south")))
			var along := float(it.get("along", 0.0))
			var sp := Sprite2D.new()
			sp.name = str(it.get("id", "banner"))
			sp.texture = tex
			sp.centered = false
			sp.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
			sp.flip_h = wall == "east"
			sp.position = banner_sprite_position(foot, wall, along, float(it.get("bottom_units", 3.0)), tex)
			sp.set_meta("alert_kind", "banner")
			sp.set_meta("alert_id", str(it.get("id", "")))
			sp.set_meta("ground", banner_ground_point(foot, wall, along))
			slot.towers.add_child(sp)
			out.append(sp)
		else:
			var g := sign_ground_point(it)
			var h := ground.height_at(g)
			var sp := LevelProps.PropSprite.new()
			sp.name = str(it.get("id", "sign"))
			sp.prop_id = str(it.get("id", ""))
			sp.centre_units = g
			sp.ground_units = h
			sp.texture = tex
			sp.centered = false
			sp.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
			sp.flip_h = bool(it.get("mirror", false))
			sp.position = sign_sprite_position(g, h, tex)
			sp.outline = sign_quad(g, h, tex)
			sp.box = _bounds(sp.outline)
			sp.z_index = map._boulder_z(g, sp.outline, h)
			sp.set_meta("alert_kind", "sign")
			sp.set_meta("alert_id", str(it.get("id", "")))
			sp.set_meta("ground", g)
			sp.set_meta("ground_height", h)
			root.add_child(sp)
			map.alert_sign_sprites.append(sp)
			out.append(sp)
	return out
