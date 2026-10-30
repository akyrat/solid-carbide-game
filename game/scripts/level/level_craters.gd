class_name LevelCraters
extends RefCounted
## The meteor craters of a level (task T-398; Level design, Decisions, "Sidewalks and parked cars
## in the level creator", Meteor craters): holes the meteors left in the ground, placed in the level
## creator and written to the level file's "craters" list, [{id, asset, x, y, w, h}] (x, y, w, h:
## the footprint in units). Everything about a crater's kind is in data/level/craters.json (its
## footprint and texture), so T-399 swaps the art by changing that file and the PNGs.
##
## A crater is not an obstacle: no body, no height. The car drives over it with no crash and the
## enemies cross it. It is drawn as a decal over the ground tiles (mvp_map.gd _GroundTiles), under
## everything else: its texture is the footprint's diamond, as a ground tile's (128 x 64 art px for
## 2 x 2 units), fitted to the footprint on screen.

const DATA_PATH := "res://data/level/craters.json"
const PX_PER_UNIT := 16.0
const MvpMapScript := preload("res://scripts/level/mvp_map.gd")

static var _data: Dictionary = {}
static var _textures: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		_data = d if d is Dictionary else {"craters": []}
	return _data


## One crater kind by its catalogue id ("crater-1"), {} for an unknown id.
static func crater(id: String) -> Dictionary:
	for c in data().get("craters", []):
		if str(c.id) == id:
			return c
	return {}


static func texture_of(id: String) -> Texture2D:
	var c := crater(id)
	if c.is_empty():
		return null
	var path := str(c.texture)
	if not _textures.has(path):
		_textures[path] = load(path) as Texture2D
	return _textures[path]


## The craters a layout (a level's data) lists.
static func items_of(layout: Dictionary) -> Array:
	var l = layout.get("craters", [])
	return l if l is Array else []


## Where a placed crater is drawn, in the map's screen pixels of the isometric view: its texture
## stretched over its footprint's diamond (top vertex on the footprint's north-west corner).
static func rect_of(item: Dictionary, texture: Texture2D) -> Rect2:
	var x := float(item.x)
	var y := float(item.y)
	var w := float(item.w)
	var h := float(item.h)
	var top: Vector2 = MvpMapScript.ISO_TRANSFORM * (Vector2(x, y) * PX_PER_UNIT)
	var left: Vector2 = MvpMapScript.ISO_TRANSFORM * (Vector2(x, y + h) * PX_PER_UNIT)
	var right: Vector2 = MvpMapScript.ISO_TRANSFORM * (Vector2(x + w, y) * PX_PER_UNIT)
	var width := right.x - left.x
	var size := Vector2(width, width * texture.get_size().y / maxf(texture.get_size().x, 1.0))
	return Rect2(Vector2(left.x, top.y), size)


## The decals to draw for `layout`: [{texture, rect}], in the list's order (unknown kinds left out).
static func decals_of(layout: Dictionary) -> Array:
	var out: Array = []
	for it in items_of(layout):
		var tex := texture_of(str(it.get("asset", "")))
		if tex == null:
			continue
		out.append({"texture": tex, "rect": rect_of(it, tex)})
	return out
