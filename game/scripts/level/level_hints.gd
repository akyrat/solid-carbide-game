class_name LevelHints
extends RefCounted
## The hint pieces of a level (task T-576; Level design, Decisions, "Hint pieces in the level creator"):
## gas (the W keycap), brake (the S keycap), a straight arrow, a curved arrow (a turn) and a circular arrow,
## placed by the board in the level creator and written to the level file's "hints" list:
##   {id: "hint-N", icon, mode, heading, mirror, x, y, w, h}
## - icon: "gas", "brake", "arrow-straight", "arrow-curved" or "arrow-circular" (data/level/hints.json);
## - mode: "ground" (painted flat on the street) or "sign" (a standing roadside sign);
## - heading: the way it points, degrees as the spawn point's (0 faces +x, 270 faces -y), one of 8;
## - mirror: true flips the curved arrow to a left turn and the circular arrow to anticlockwise;
## - x, y, w, h: its footprint (units), the mode's footprint_units.
## A level without "hints" has none.
##
## How each is drawn and what it does (the run and the creator draw them with this script):
## - ground: the icon's picture, made top-down pointing up the picture, laid flat on the isometric ground
##   by the engine and turned to its heading, so one picture serves all 8 directions. A node of the map's
##   view_root right over the ground (HintDecals), under the buildings, rooftops, props, the car and the
##   minions. No body: the car drives over it.
## - sign: the sign picture standing on its footprint's middle (at the height there: GroundHeight), with the
##   icon put on its face by the engine, turned to the heading as it shows on screen. A LevelProps.PropSprite
##   in map.prop_sprites (the depth order of the props) and a static body in map.prop_bodies (a circle at the
##   post, collision layer 1, the props' heights), so it blocks the car like a prop; the enemies' paths and
##   spawn spots go round it (LevelProps.obstacles, blocks_spot).
## Everything about the art (paths, sizes, the sign's face) is in data/level/hints.json, so T-577 swaps
## the art by dropping its PNGs in (game/docs/level/hint-pieces.md).

const DATA_PATH := "res://data/level/hints.json"
const PX_PER_UNIT := 16.0
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
const MODES := ["ground", "sign"]

static var _data: Dictionary = {}
static var _textures: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		_data = d if d is Dictionary else {"icons": []}
	return _data


static func icons() -> Array:
	return data().get("icons", [])


static func icon(id: String) -> Dictionary:
	for i in icons():
		if str(i.id) == id:
			return i
	return {}


static func headings() -> Array:
	return data().get("headings", [270, 315, 0, 45, 90, 135, 180, 225])


## The mode's settings ("ground" or "sign"), {} for an unknown mode.
static func mode_data(mode: String) -> Dictionary:
	return data().get(mode, {}) if mode in MODES else {}


static func footprint(mode: String) -> Vector2:
	var f: Array = mode_data(mode).get("footprint_units", [2.0, 2.0])
	return Vector2(float(f[0]), float(f[1]))


static func _load(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _textures[path]


static func icon_texture(id: String) -> Texture2D:
	var i := icon(id)
	return _load(str(i.texture)) if not i.is_empty() else null


static func sign_texture() -> Texture2D:
	return _load(str(mode_data("sign").get("texture", "")))


## The hints a layout (a level's data) lists.
static func items_of(layout: Dictionary) -> Array:
	var l = layout.get("hints", [])
	return l if l is Array else []


static func is_sign(item: Dictionary) -> bool:
	return str(item.get("mode", "ground")) == "sign"


static func rect_of(item: Dictionary) -> Rect2:
	return Rect2(float(item.x), float(item.y), float(item.w), float(item.h))


static func centre_of(item: Dictionary) -> Vector2:
	return rect_of(item).get_center()


## The way the hint points on the map (a unit vector, units).
static func direction_of(item: Dictionary) -> Vector2:
	var a := deg_to_rad(float(item.get("heading", 270)))
	return Vector2(cos(a), sin(a))


## The turn (radians) that takes the icon's picture (pointing up the picture) to the hint's heading on
## the flat map: 0 for heading 270 (-y).
static func ground_angle(item: Dictionary) -> float:
	return deg_to_rad(float(item.get("heading", 270)) + 90.0)


## The turn (radians) of the icon on a sign's face: the heading as it shows on screen (the isometric
## projection of the map direction), the picture's up turned to it.
static func sign_icon_angle(item: Dictionary) -> float:
	var s := ISO_TRANSFORM.basis_xform(direction_of(item))
	return s.angle() + PI / 2.0


# ---- Ground hints -------------------------------------------------------------------------------

## Draws a ground hint on `ci` (any CanvasItem): its icon flat on the ground, turned to its heading.
## `base`: the transform from the map's flat pixels (units * PX_PER_UNIT) to `ci`'s own: IDENTITY for a
## node of the map's view_root (which applies the isometric projection), ISO_TRANSFORM for a node in the
## map's screen pixels (the creator's overlay).
static func draw_ground(ci: CanvasItem, item: Dictionary, base: Transform2D, modulate := Color.WHITE) -> void:
	var tex := icon_texture(str(item.get("icon", "")))
	if tex == null:
		return
	var size := float(mode_data("ground").get("size_units", 4.0)) * PX_PER_UNIT
	var flip := -1.0 if bool(item.get("mirror", false)) else 1.0  # flipped left to right, before the turn
	ci.draw_set_transform_matrix(base * Transform2D(ground_angle(item), Vector2(flip, 1.0), 0.0, centre_of(item) * PX_PER_UNIT))
	ci.draw_texture_rect(tex, Rect2(Vector2(-size, -size) / 2.0, Vector2(size, size)), false, modulate)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


## The ground hint's outline on the flat map (units): its drawn square, turned.
static func ground_quad(item: Dictionary) -> PackedVector2Array:
	var half := float(mode_data("ground").get("size_units", 4.0)) / 2.0
	var t := Transform2D(ground_angle(item), centre_of(item))
	var out := PackedVector2Array()
	for c in [Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)]:
		out.append(t * c)
	return out


# ---- Signs --------------------------------------------------------------------------------------

## Where a sign is drawn, standing at `ground_h` (units): {position (the sprite's top-left, map screen
## pixels), scale, icon_position (the icon's centre in the sign picture's pixels), icon_scale (in the sign
## picture's pixels), icon_rotation, flip}. {} without the sign's art.
static func sign_geometry(item: Dictionary, ground_h: float) -> Dictionary:
	var s := mode_data("sign")
	var tex := sign_texture()
	var icon_tex := icon_texture(str(item.get("icon", "")))
	if tex == null or s.is_empty():
		return {}
	var scale := float(s.get("draw_scale", 0.5))
	var anchor: Array = s.get("anchor_px", [tex.get_width() / 2.0, tex.get_height() - 1.0])
	var face: Array = s.get("face_px", [0, 0, tex.get_width(), tex.get_width()])
	var foot := ISO_TRANSFORM * (centre_of(item) * PX_PER_UNIT) - Vector2(0.0, ground_h * PX_PER_UNIT)
	var icon_scale := 1.0
	if icon_tex != null:
		icon_scale = minf(float(face[2]) / icon_tex.get_width(), float(face[3]) / icon_tex.get_height())
	return {"position": foot - Vector2(float(anchor[0]), float(anchor[1])) * scale, "scale": scale,
		"icon_position": Vector2(float(face[0]) + float(face[2]) / 2.0, float(face[1]) + float(face[3]) / 2.0),
		"icon_scale": icon_scale, "icon_rotation": sign_icon_angle(item), "flip": bool(item.get("mirror", false)),
		"size": Vector2(tex.get_width(), tex.get_height()) * scale}


## The sign's picture on screen (map screen pixels) standing at `ground_h`, as four corners.
static func sign_quad(item: Dictionary, ground_h: float) -> PackedVector2Array:
	var g := sign_geometry(item, ground_h)
	if g.is_empty():
		return PackedVector2Array()
	var p: Vector2 = g.position
	var sz: Vector2 = g.size
	return PackedVector2Array([p, p + Vector2(sz.x, 0), p + sz, p + Vector2(0, sz.y)])


## Draws a sign on `ci` in map screen pixels (the creator's preview), as the run's sprites show it.
static func draw_sign(ci: CanvasItem, item: Dictionary, ground_h: float, modulate := Color.WHITE) -> void:
	var g := sign_geometry(item, ground_h)
	if g.is_empty():
		return
	ci.draw_texture_rect(sign_texture(), Rect2(g.position, g.size), false, modulate)
	var icon_tex := icon_texture(str(item.get("icon", "")))
	if icon_tex == null:
		return
	var at: Vector2 = g.position + (g.icon_position as Vector2) * float(g.scale)
	var sc := float(g.icon_scale) * float(g.scale)
	ci.draw_set_transform(at, float(g.icon_rotation), Vector2(-sc if g.flip else sc, sc))
	ci.draw_texture_rect(icon_tex, Rect2(-icon_tex.get_size() / 2.0, icon_tex.get_size()), false, modulate)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


## A sign's collision: {centre, radius} (units), a circle at the post.
static func collision_of(item: Dictionary) -> Dictionary:
	return {"centre": centre_of(item), "radius": float(mode_data("sign").get("collision_radius", 0.5))}


## The signs' collision circles of `layout`, as LevelProps.obstacles lists circles: [[centre, radius]].
static func sign_circles(layout: Dictionary) -> Array:
	var out: Array = []
	for it in items_of(layout):
		if it is Dictionary and is_sign(it):
			var c := collision_of(it)
			out.append([c.centre, c.radius])
	return out


# ---- Building them in a map ---------------------------------------------------------------------

## Builds the hints of `map.layout` (an mvp_map.gd node, after its physics_root, view_root and
## ground_tiles exist): the ground hints' node (map.hint_decals) and the signs' bodies and sprites
## (map.prop_bodies, map.prop_sprites, under map.prop_sprites_root). A level without hints gets nothing.
static func build(map) -> void:
	var items := items_of(map.layout)
	if items.is_empty():
		return
	var grounds: Array = []
	var signs: Array = []
	for it in items:
		if not (it is Dictionary) or icon(str(it.get("icon", ""))).is_empty():
			continue
		(signs if is_sign(it) else grounds).append(it)
	if not grounds.is_empty():
		var decals := Decals.new()
		decals.name = "HintDecals"
		decals.items = grounds
		map.view_root.add_child(decals)
		# Right over the ground (its tiles, or the grid ground), under everything else of the view.
		var after: Node = map.ground_tiles if map.ground_tiles != null else map.ground_draw
		if after != null:
			map.view_root.move_child(decals, after.get_index() + 1)
		map.hint_decals = decals
	if signs.is_empty():
		return
	var ground := GroundHeight.new()
	ground.load_data(map.layout)
	if map.prop_sprites_root == null:
		var root := Node2D.new()
		root.name = "PropSprites"
		root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		map.view_root.add_child(root)
		map.prop_sprites_root = root
	var height := float(mode_data("sign").get("height_units", 3.0))
	for it in signs:
		var c := collision_of(it)
		var h := ground.height_at(c.centre)
		var body := StaticBody2D.new()
		body.name = "Hint_%s" % str(it.get("id", "")).replace("-", "_")
		body.set_meta("prop_id", str(it.get("id", "")))
		body.set_meta("hint_id", str(it.get("id", "")))
		body.set_meta("base_units", h)
		body.set_meta("top_units", h + height)
		var cs := CollisionShape2D.new()
		cs.name = "Shape"
		var circle := CircleShape2D.new()
		circle.radius = float(c.radius) * PX_PER_UNIT
		cs.shape = circle
		cs.position = (c.centre as Vector2) * PX_PER_UNIT
		body.add_child(cs)
		map.physics_root.add_child(body)
		map.prop_bodies.append(body)
		var g := sign_geometry(it, h)
		if g.is_empty():
			continue
		var sp := LevelProps.PropSprite.new()
		sp.name = "HintSign_%s" % str(it.get("id", "")).replace("-", "_")
		sp.prop_id = str(it.get("id", ""))
		sp.centre_units = c.centre
		sp.ground_units = h
		sp.top_units = float(map.obstacle_heights(body)[1])
		sp.texture = sign_texture()
		sp.centered = false
		sp.scale = Vector2(g.scale, g.scale)
		sp.position = g.position
		sp.outline = sign_quad(it, h)
		sp.box = _bounds(sp.outline)
		sp.z_index = map._boulder_z(sp.centre_units, sp.outline, h)
		sp.set_meta("hint_id", str(it.get("id", "")))
		var face := Sprite2D.new()
		face.name = "Icon"
		face.texture = icon_texture(str(it.icon))
		face.position = g.icon_position
		face.rotation = g.icon_rotation
		face.scale = Vector2(-g.icon_scale if g.flip else g.icon_scale, g.icon_scale)
		sp.add_child(face)
		map.prop_sprites_root.add_child(sp)
		map.prop_sprites.append(sp)


static func _bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var r := Rect2(points[0], Vector2.ZERO)
	for p in points:
		r = r.expand(p)
	return r


## The ground hints of a map, drawn in the map's flat pixels (the view_root's projection lays them on the
## isometric ground).
class Decals extends Node2D:
	var items: Array = []

	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _draw() -> void:
		for it in items:
			LevelHints.draw_ground(self, it, Transform2D.IDENTITY)
