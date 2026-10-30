class_name LevelProps
extends RefCounted
## The props of a level (task T-253; Level design, Decisions, "Level creator piece set"): barriers,
## cones, crates and the rooftop kit, placed in the level creator and written to the level file's
## "props" list, [{id, asset, rotation, x, y, w, h}] (x, y, w, h: the footprint in units, already
## turned to the rotation). Everything about a prop's kind lives in data/level/props.json
## (footprint, collision, height and the sprite of each rotation with its anchor), so T-256 swaps
## the art by changing that file and the PNGs.
##
## Each prop is a solid obstacle like a boulder: a static body on collision layer 1 (the car crashes
## into it, which cuts the combo through the car's hit_obstacle, and the minions and the kaiju are
## stopped by it), and the enemies' pathfinding closes the cells it takes (enemy_navigation.gd).
## It stands at the ground height under its centre (a rooftop's, a ramp's), drawn as a sprite in
## the map's screen pixels with the boulders' depth rules (the sprites join map.prop_sprites, which
## the car, the enemies and the elevation layer read next to map.boulder_sprites).

const DATA_PATH := "res://data/level/props.json"
## One map unit, in screen pixels of the isometric view, and the drawn scale of the art.
const PX_PER_UNIT := 16.0
const MvpMapScript := preload("res://scripts/level/mvp_map.gd")

static var _data: Dictionary = {}
static var _textures: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		_data = d if d is Dictionary else {"props": []}
	return _data


static func rotations() -> Array:
	return data().get("rotations", ["north", "east", "south", "west"])


static func props() -> Array:
	return data().get("props", [])


## One prop's data by id ("prop-barrier"), {} for an unknown id.
static func prop(id: String) -> Dictionary:
	for p in props():
		if str(p.id) == id:
			return p
	return {}


## The footprint (units) of `id` facing `rotation`: its data's, with the two numbers swapped for
## east and west.
static func footprint(id: String, rotation: String) -> Vector2:
	var p := prop(id)
	if p.is_empty():
		return Vector2.ZERO
	var f := Vector2(float(p.footprint_units[0]), float(p.footprint_units[1]))
	return Vector2(f.y, f.x) if rotation in ["east", "west"] else f


static func rect_of(item: Dictionary) -> Rect2:
	return Rect2(float(item.x), float(item.y), float(item.w), float(item.h))


## The collision of a placed prop `item`: {shape: "rect", rect: Rect2} (the footprint) or
## {shape: "circle", centre: Vector2, radius: float} (in the middle of the footprint), in units.
static func collision_of(item: Dictionary) -> Dictionary:
	var p := prop(str(item.get("asset", "")))
	var r := rect_of(item)
	if p.is_empty():
		return {"shape": "rect", "rect": r}
	var c: Dictionary = p.get("collision", {})
	if str(c.get("shape", "rect")) == "circle":
		return {"shape": "circle", "centre": r.get_center(), "radius": float(c.get("radius", 0.5))}
	return {"shape": "rect", "rect": r}


## The props a layout (a level's data) lists.
static func items_of(layout: Dictionary) -> Array:
	var l = layout.get("props", [])
	return l if l is Array else []


## What the props of `layout` take on the ground, for the enemies' paths and spawn spots:
## {rects: [Rect2], circles: [[centre, radius]]}.
static func obstacles(layout: Dictionary) -> Dictionary:
	var rects: Array = []
	var circles: Array = []
	for it in items_of(layout):
		var c := collision_of(it)
		if c.shape == "circle":
			circles.append([c.centre, c.radius])
		else:
			rects.append(c.rect)
	return {"rects": rects, "circles": circles}


## True when a round thing of `radius` units at `units` would overlap a prop of `layout`.
static func blocks_spot(layout: Dictionary, units: Vector2, radius: float) -> bool:
	for it in items_of(layout):
		var c := collision_of(it)
		if c.shape == "circle":
			if units.distance_to(c.centre) < float(c.radius) + radius:
				return true
		else:
			var r: Rect2 = c.rect
			var nearest := Vector2(clampf(units.x, r.position.x, r.end.x), clampf(units.y, r.position.y, r.end.y))
			if units.distance_to(nearest) < radius:
				return true
	return false


## The sprite of `id` facing `rotation`: {texture: Texture2D, anchor_px: Vector2}, {} when the
## prop or its PNG is missing.
static func sprite_of(id: String, rotation: String) -> Dictionary:
	var p := prop(id)
	if p.is_empty() or not p.get("textures", {}).has(rotation):
		return {}
	var t: Dictionary = p.textures[rotation]
	var path := str(t.texture)
	if not _textures.has(path):
		_textures[path] = load(path) as Texture2D
	if _textures[path] == null:
		return {}
	return {"texture": _textures[path], "anchor_px": Vector2(float(t.anchor_px[0]), float(t.anchor_px[1]))}


## The prop's outline on screen (the convex hull of its box, from the ground at `ground` units up
## to its height), in the map's screen pixels of the isometric view.
static func outline_of(item: Dictionary, ground: float) -> PackedVector2Array:
	var r := rect_of(item)
	var p := prop(str(item.get("asset", "")))
	var h := float(p.get("height_units", 1.0)) if not p.is_empty() else 1.0
	var pts := PackedVector2Array()
	for corner in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		for z in [ground, ground + h]:
			pts.append(MvpMapScript.ISO_TRANSFORM * (corner * PX_PER_UNIT) - Vector2(0.0, z * PX_PER_UNIT))
	return Geometry2D.convex_hull(pts)


## Builds the props of `map` (an mvp_map.gd node, after its physics_root and view_root exist): a
## static body for each (map.prop_bodies) and a sprite for each (map.prop_sprites, under
## map.prop_sprites_root). Without props in the layout nothing is made.
static func build(map: Node2D) -> void:
	var items := items_of(map.layout)
	if items.is_empty():
		return
	var ground := GroundHeight.new()
	ground.load_data(map.layout)
	var scale: float = float(data().get("draw_scale", 0.5))
	var root := Node2D.new()
	root.name = "PropSprites"
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map.view_root.add_child(root)
	map.prop_sprites_root = root
	var k := 0
	for it in items:
		k += 1
		var c := collision_of(it)
		var body := StaticBody2D.new()
		body.name = "Prop_%s" % str(it.get("id", k)).replace("-", "_")
		body.set_meta("prop_id", str(it.get("id", "")))
		# T-405: the heights it blocks the car at (mvp_map.gd update_car_obstacles): from the ground
		# under its centre (a rooftop's, a short building's, a ramp's) up by its own height.
		var foot_h := ground.height_at(rect_of(it).get_center())
		var pdata := prop(str(it.get("asset", "")))
		body.set_meta("base_units", foot_h)
		body.set_meta("top_units", foot_h + float(pdata.get("height_units", 1.0)) if not pdata.is_empty() else foot_h + 1.0)
		map.physics_root.add_child(body)
		var cs := CollisionShape2D.new()
		cs.name = "Shape"
		if c.shape == "circle":
			var circle := CircleShape2D.new()
			circle.radius = float(c.radius) * PX_PER_UNIT
			cs.shape = circle
			cs.position = c.centre * PX_PER_UNIT
		else:
			var box := RectangleShape2D.new()
			box.size = (c.rect as Rect2).size * PX_PER_UNIT
			cs.shape = box
			cs.position = (c.rect as Rect2).get_center() * PX_PER_UNIT
		body.add_child(cs)
		map.prop_bodies.append(body)
		var centre := rect_of(it).get_center()
		var h := ground.height_at(centre)
		var sp := PropSprite.new()
		sp.name = "Prop%03d" % k
		sp.prop_id = str(it.get("id", ""))
		sp.centre_units = centre
		sp.ground_units = h
		sp.outline = outline_of(it, h)
		sp.box = _bounds(sp.outline)
		var s := sprite_of(str(it.get("asset", "")), str(it.get("rotation", "north")))
		if not s.is_empty():
			sp.texture = s.texture
			sp.centered = false
			sp.scale = Vector2(scale, scale)
			sp.position = MvpMapScript.ISO_TRANSFORM * (centre * PX_PER_UNIT) - s.anchor_px * scale \
				- Vector2(0.0, h * PX_PER_UNIT)
		sp.z_index = map._boulder_z(sp.centre_units, sp.outline, h)
		root.add_child(sp)
		map.prop_sprites.append(sp)


static func _bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var r := Rect2(points[0], Vector2.ZERO)
	for p in points:
		r = r.expand(p)
	return r


## A prop's sprite. Has what the depth order reads of a boulder sprite (centre_units, outline, box,
## z_index, covers).
class PropSprite extends Sprite2D:
	var prop_id := ""
	## The prop's centre on the ground, in units.
	var centre_units := Vector2.ZERO
	## The height it stands on, units (a rooftop's, a ramp's; T-393).
	var ground_units := 0.0
	## The outline of the prop on screen (convex), and its box.
	var outline := PackedVector2Array()
	var box := Rect2()

	## True when the prop covers the car: the car's centre (units) is behind the prop's centre
	## (smaller x + y) and the car's screen shape overlaps the prop's outline.
	func covers(car_centre_units: Vector2, car_shape: PackedVector2Array, car_box: Rect2) -> bool:
		if car_centre_units.x + car_centre_units.y >= centre_units.x + centre_units.y:
			return false
		if not box.intersects(car_box):
			return false
		return not Geometry2D.intersect_polygons(outline, car_shape).is_empty()
