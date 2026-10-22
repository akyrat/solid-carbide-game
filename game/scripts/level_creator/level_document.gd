class_name LevelDocument
extends RefCounted
## The level being edited in the level creator (task T-235), as data in the map-file format of
## data/level/elevation_sample_map.json (map, legend, ground_rows, buildings, pattern_copies for
## the boulders, platforms, ramps), plus "ground": the ground and road tile on every 2 x 2 unit
## cell, which mvp_map.gd draws (its ground layout). Placing and deleting pieces change `data`
## itself (the same Dictionary the editor holds).
##
## Pieces go at the clicked tile here: the piece's top-left corner on the corner of the 2 x 2 unit
## cell under the cursor. The editor snaps first (snapping.gd, T-237) and passes a point in the
## snapped corner's cell.
##
## Rotate and mirror (T-236; Level design, Decisions, "Level creator"): a piece is placed in one of
## the views its catalogue entry lists ("views") and one of its mirrors ("mirrors"), and only
## those, since the art exists only in the angles that were generated. The texture of that view
## and mirror (texture_of) decides what the piece writes: a building's look, a boulder's variant,
## a rooftop's or a ramp's art, and a ramp's side.
##
## What a placed piece writes (catalogue ids from data/level/creator_assets.json):
## - ground, road: the cell's tile in data.ground (tiles = the catalogue ids used, cells = an index
##   into tiles per cell, rows of cols), and ground_rows/legend kept in step (G ground, R road,
##   B building, one letter per unit).
## - building: {x, y, w, h, asset, look} in buildings (the catalogue footprint; mvp_map.gd draws
##   the one tower named, building_towers.gd single_of; look = the view's texture variant, so a
##   short building's mirror is its look 1).
## - boulder: its own pattern copy {id, boulders: [{x, y, diameter, variant}]} (the mirror's
##   variant, "a_mirror").
## - rooftop: {id, x, y, w, h, height, view, art[, on]} in platforms: art = the view's art piece
##   (art/elevation_sample/<art>.png); "on" = the lower rooftop holding its whole footprint (a 6
##   on a 3), as in the elevation sample map's height data.
## - ramp: {id, platform, side, x, y, w, h, bottom_height, top_height, view, art} in ramps: side =
##   the side of the rooftop it climbs, from the view's art; platform = the rooftop at its top
##   height whose side its top end touches ("" while there is none).
## The links ("on", "platform") are filled in again after every place and delete (_relink), so a
## rooftop placed after its ramp, or a 3 deleted under a 6, keep the data in step.

const CATALOGUE_PATH := "res://data/level/creator_assets.json"
## The game's own ground tiles (T-103): the atlas, its tile size and columns.
const GAME_GROUND_PATH := "res://data/level/mvp_ground.json"
## A new level is today's map's size (elevation_sample_map.json: 240 x 240 units, centred).
const MAP_SIZE := 240
const CELL := 2
## Proposal: a new level's ground is all this plain tile (the first ground tile of the catalogue).
const BASE_GROUND := "ground-gravel0"
const KINDS := ["ground", "road", "building", "boulder", "rooftop", "ramp"]
const LEGEND := {"R": "road", "G": "gravel", "B": "building"}
## mvp_map.gd's ground tiles: cell values from here on draw the layout's "extra" textures.
const EXTRA_BASE := 1000

static var _catalogue: Dictionary = {}
static var _game_ground: Dictionary = {}

var data: Dictionary = {}
## The ground cells, kept here even when `data` has no "ground" yet (a loaded file): catalogue
## ids, rows of cols.
var cells: Array = []


## The catalogue (creator_assets.json).
static func catalogue() -> Dictionary:
	if _catalogue.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE_PATH))
		_catalogue = d if d is Dictionary else {"entries": []}
	return _catalogue


static func entries() -> Array:
	return catalogue().get("entries", [])


static func entry(id: String) -> Dictionary:
	for e in entries():
		if str(e.id) == id:
			return e
	return {}


## The views the asset's art exists in (its catalogue entry's "views"), in the catalogue's order.
static func views_of(id: String) -> Array:
	return entry(id).get("views", []).duplicate()


## The mirrors the asset's art exists in (its catalogue entry's "mirrors": false, true).
static func mirrors_of(id: String) -> Array:
	return entry(id).get("mirrors", []).duplicate()


## The asset's view, or its first view when it has no such view.
static func valid_view(id: String, view: String) -> String:
	var vs := views_of(id)
	if vs.is_empty():
		return ""
	return view if view in vs else str(vs[0])


## The asset's mirror, or its first mirror when it has no such mirror.
static func valid_mirror(id: String, mirror: bool) -> bool:
	var ms := mirrors_of(id)
	if ms.is_empty():
		return false
	return mirror if mirror in ms else bool(ms[0])


## The asset's texture (its catalogue record: view, mirror, variant, texture[, region, side]) for a
## view and mirror: the first that matches both, else the first of that view, else its first.
static func texture_of(id: String, view: String, mirror: bool) -> Dictionary:
	var e := entry(id)
	var ts: Array = e.get("textures", [])
	if ts.is_empty():
		return {}
	for t in ts:
		if str(t.get("view", "")) == view and bool(t.get("mirror", false)) == mirror:
			return t
	for t in ts:
		if str(t.get("view", "")) == view:
			return t
	return ts[0]


## The footprint (units) the asset covers in a view and mirror: its texture's own "footprint_units"
## when it has one (a long building covers 12 x 6 in one view and 6 x 12 in the other, T-254), else
## the entry's.
static func footprint_of(id: String, view: String, mirror: bool) -> Vector2:
	var e := entry(id)
	var t := texture_of(id, view, mirror)
	var f: Array = t.get("footprint_units", e.get("footprint_units", [0, 0]))
	return Vector2(float(f[0]), float(f[1]))


static func game_ground() -> Dictionary:
	if _game_ground.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(GAME_GROUND_PATH))
		_game_ground = d if d is Dictionary else {}
	return _game_ground


## A new level's data: an empty map of today's size, all ground BASE_GROUND.
static func new_level_data(level_name: String) -> Dictionary:
	var half := MAP_SIZE / 2.0
	var n := MAP_SIZE / CELL
	var row: Array = []
	row.resize(n)
	row.fill(0)
	var rows: Array = []
	for j in n:
		rows.append(row.duplicate())
	var d := {
		"name": level_name,
		"map": {"width": MAP_SIZE, "height": MAP_SIZE,
			"rect": {"x": -half, "y": -half, "w": MAP_SIZE, "h": MAP_SIZE}, "edge": "hard stop"},
		"legend": LEGEND.duplicate(),
		"ground_rows": [],
		"ground": {"cell_units": CELL, "origin": [-half, -half], "cols": n, "rows": n,
			"tiles": [BASE_GROUND], "cells": rows},
		"buildings": [],
		"pattern_copies": [],
		"platforms": [],
		"ramps": [],
	}
	var doc := LevelDocument.new(d)
	doc.refresh_ground_rows()
	return d


func _init(the_data: Dictionary = {}) -> void:
	data = the_data
	_read_cells()


# ---- The map ------------------------------------------------------------------------------------

func map_rect() -> Rect2:
	var m = data.get("map", {})
	if m is Dictionary and m.get("rect") is Dictionary:
		var r: Dictionary = m.rect
		return Rect2(float(r.x), float(r.y), float(r.w), float(r.h))
	var half := MAP_SIZE / 2.0
	return Rect2(-half, -half, MAP_SIZE, MAP_SIZE)


func cols() -> int:
	return int(map_rect().size.x) / CELL


func rows() -> int:
	return int(map_rect().size.y) / CELL


## The 2 x 2 unit cell under a point (units), or (-1, -1) outside the map.
func cell_at(units: Vector2) -> Vector2i:
	var m := map_rect()
	var c := Vector2i(floori((units.x - m.position.x) / CELL), floori((units.y - m.position.y) / CELL))
	if c.x < 0 or c.y < 0 or c.x >= cols() or c.y >= rows():
		return Vector2i(-1, -1)
	return c


## A cell's top-left corner, in units.
func cell_corner(c: Vector2i) -> Vector2:
	return map_rect().position + Vector2(c) * CELL


## The ground or road tile (catalogue id) on a cell.
func tile_at(c: Vector2i) -> String:
	return str(cells[c.y][c.x])


func _read_cells() -> void:
	cells = []
	var g = data.get("ground", {})
	if g is Dictionary and g.has("cells") and g.has("tiles"):
		var tiles: Array = g.tiles
		for row in g.cells:
			var out: Array = []
			for k in row:
				out.append(str(tiles[int(k)]) if int(k) >= 0 and int(k) < tiles.size() else BASE_GROUND)
			cells.append(out)
		if cells.size() == rows() and (cells.is_empty() or cells[0].size() == cols()):
			return
		cells = []
	# A file without the creator's ground (the game's own map): the game's ground tiles when it is
	# today's map's size, otherwise all BASE_GROUND.
	var gg := game_ground()
	var by_variant := {}
	for e in entries():
		if str(e.kind) in ["ground", "road"]:
			by_variant[str(e.textures[0].variant)] = str(e.id)
	var use_game: bool = not gg.is_empty() and int(gg.get("cols", 0)) == cols() and int(gg.get("rows", 0)) == rows() \
		and Vector2(float(gg.origin[0]), float(gg.origin[1])) == map_rect().position
	for j in rows():
		var out: Array = []
		for i in cols():
			var id := BASE_GROUND
			if use_game:
				var k := int(gg.cells[j][i])
				if k >= 0 and k < gg.names.size():
					id = str(by_variant.get(str(gg.names[k]), BASE_GROUND))
			out.append(id)
		cells.append(out)


## Writes `cells` into data.ground (tiles used, and an index per cell).
func _write_cells() -> void:
	var tiles: Array = []
	var index := {}
	var out_rows: Array = []
	for row in cells:
		var out: Array = []
		for id in row:
			if not index.has(id):
				index[id] = tiles.size()
				tiles.append(id)
			out.append(index[id])
		out_rows.append(out)
	var m := map_rect()
	data["ground"] = {"cell_units": CELL, "origin": [m.position.x, m.position.y], "cols": cols(), "rows": rows(),
		"tiles": tiles, "cells": out_rows}


## Rebuilds ground_rows (one letter per unit: G ground, R road, B building) and the legend.
func refresh_ground_rows() -> void:
	var m := map_rect()
	var out: Array = []
	for j in rows():
		var s := ""
		for i in cols():
			s += "RR" if _kind_of_tile(tile_at(Vector2i(i, j))) == "road" else "GG"
		out.append(s)
		out.append(s)
	for b in data.get("buildings", []):
		var r := Rect2(float(b.x), float(b.y), float(b.w), float(b.h)).intersection(m)
		var x0 := int(r.position.x - m.position.x)
		var w := int(r.size.x)
		if w <= 0:
			continue
		for y in range(int(r.position.y - m.position.y), int(r.end.y - m.position.y)):
			var row: String = out[y]
			out[y] = row.substr(0, x0) + "B".repeat(w) + row.substr(x0 + w)
	data["ground_rows"] = out
	data["legend"] = LEGEND.duplicate()


static var _tile_kinds: Dictionary = {}


static func _kind_of_tile(id: String) -> String:
	if _tile_kinds.is_empty():
		for e in entries():
			_tile_kinds[str(e.id)] = str(e.kind)
	return str(_tile_kinds.get(id, "ground"))


# ---- Placing and deleting ----------------------------------------------------------------------

## Places the catalogue asset `asset_id` with its top-left corner on the cell under `units`, in
## `view` and `mirror` (one its entry lists; another, or "", gives its first view and mirror).
## Returns the placed piece (see piece_at), or {} for an unknown asset or a point outside the map.
func place(asset_id: String, units: Vector2, view: String = "", mirror: bool = false) -> Dictionary:
	var e := entry(asset_id)
	var c := cell_at(units)
	if e.is_empty() or c.x < 0:
		return {}
	var kind := str(e.kind)
	var corner := cell_corner(c)
	view = valid_view(asset_id, view)
	mirror = valid_mirror(asset_id, mirror)
	var foot := footprint_of(asset_id, view, mirror)
	var tex := texture_of(asset_id, view, mirror)
	match kind:
		"ground", "road":
			cells[c.y][c.x] = asset_id
			_write_cells()
			refresh_ground_rows()
			return {"kind": kind, "cell": c}
		"building":
			var look := int(str(tex.get("variant", "0"))) if str(tex.get("variant", "0")).is_valid_int() else 0
			var b := {"x": corner.x, "y": corner.y, "w": foot.x, "h": foot.y, "asset": asset_id, "look": look}
			_list("buildings").append(b)
			refresh_ground_rows()
			return {"kind": kind, "item": b}
		"boulder":
			var boulder := {"x": corner.x + foot.x / 2.0, "y": corner.y + foot.y / 2.0, "diameter": foot.x,
				"variant": str(tex.variant)}
			var copy := {"id": _next_id("pattern_copies", "boulder-"), "boulders": [boulder]}
			_list("pattern_copies").append(copy)
			return {"kind": kind, "item": boulder, "copy": copy}
		"rooftop":
			var p := {"id": _next_id("platforms", "roof-"), "x": corner.x, "y": corner.y, "w": foot.x, "h": foot.y,
				"height": int(e.height), "view": view, "art": str(tex.variant)}
			_list("platforms").append(p)
			_relink()
			return {"kind": kind, "item": p}
		"ramp":
			var r := {"id": _next_id("ramps", "ramp-"), "platform": "", "side": str(tex.get("side", "east")),
				"x": corner.x, "y": corner.y, "w": foot.x, "h": foot.y,
				"bottom_height": int(e.heights[0]), "top_height": int(e.heights[1]),
				"view": view, "art": str(tex.variant)}
			_list("ramps").append(r)
			_relink()
			return {"kind": kind, "item": r}
	return {}


# ---- Heights: a 6 on a 3, a ramp on the side it climbs -----------------------------------------

## The highest rooftop lower than `height` that holds the whole of `r` (units), {} for none.
func rooftop_under(r: Rect2, height: float, except: Dictionary = {}) -> Dictionary:
	var best: Dictionary = {}
	for p in _list("platforms"):
		if is_same(p, except) or float(p.height) >= height:
			continue
		if _holds(_rect(p), r) and (best.is_empty() or float(p.height) > float(best.height)):
			best = p
	return best


## The rooftop a ramp climbs to: at its top height, with the ramp's top end on its `side` and
## within it (check_height_data.py's rule); {} for none.
func ramp_target(ramp: Dictionary) -> Dictionary:
	var rr := _rect(ramp)
	for p in _list("platforms"):
		if absf(float(p.height) - float(ramp.top_height)) > 0.001:
			continue
		if top_touches(str(ramp.side), rr, _rect(p)):
			return p
	return {}


## True when a ramp `ramp` (units) touches area `area` along its `side` (the side of the area it
## climbs), within that side.
static func top_touches(side: String, ramp: Rect2, area: Rect2) -> bool:
	const E := 0.001
	match side:
		"east":
			return absf(ramp.position.x - area.end.x) <= E and ramp.position.y >= area.position.y - E and ramp.end.y <= area.end.y + E
		"west":
			return absf(ramp.end.x - area.position.x) <= E and ramp.position.y >= area.position.y - E and ramp.end.y <= area.end.y + E
		"north":
			return absf(ramp.end.y - area.position.y) <= E and ramp.position.x >= area.position.x - E and ramp.end.x <= area.end.x + E
		"south":
			return absf(ramp.position.y - area.end.y) <= E and ramp.position.x >= area.position.x - E and ramp.end.x <= area.end.x + E
	return false


static func _holds(outer: Rect2, inner: Rect2) -> bool:
	const E := 0.001
	return inner.position.x >= outer.position.x - E and inner.position.y >= outer.position.y - E \
		and inner.end.x <= outer.end.x + E and inner.end.y <= outer.end.y + E


## Fills in the links again: each rooftop's "on" (the highest lower rooftop holding it whole, none
## on the street) and each ramp's "platform" (ramp_target). A link still right is left as it is.
func _relink() -> void:
	var by_id := {}
	for p in _list("platforms"):
		by_id[str(p.get("id", ""))] = p
	for p in _list("platforms"):
		var on := str(p.get("on", ""))
		if on != "" and by_id.has(on) and float(by_id[on].height) < float(p.height) \
				and _holds(_rect(by_id[on]), _rect(p)):
			continue
		var under := rooftop_under(_rect(p), float(p.height), p)
		if under.is_empty():
			p.erase("on")
		else:
			p["on"] = str(under.id)
	for r in _list("ramps"):
		var cur := str(r.get("platform", ""))
		if cur != "" and by_id.has(cur) and absf(float(by_id[cur].height) - float(r.top_height)) <= 0.001 \
				and top_touches(str(r.side), _rect(r), _rect(by_id[cur])):
			continue
		var t := ramp_target(r)
		r["platform"] = str(t.id) if not t.is_empty() else ""


func _list(key: String) -> Array:
	if not (data.get(key) is Array):
		data[key] = []
	return data[key]


## "<prefix><n>" with the smallest n from 1 no entry of data[key] has as its id.
func _next_id(key: String, prefix: String) -> String:
	var used := {}
	for x in _list(key):
		used[str(x.get("id", ""))] = true
	var n := 1
	while used.has(prefix + str(n)):
		n += 1
	return prefix + str(n)


## The piece drawn on top at a point (units): a boulder, a ramp, a rooftop (the highest first), a
## building, else the ground or road tile of the cell. {kind, item[, copy]} or {kind, cell}; {}
## outside the map.
func piece_at(units: Vector2) -> Dictionary:
	for copy in _list("pattern_copies"):
		for b in copy.get("boulders", []):
			if units.distance_to(Vector2(float(b.x), float(b.y))) <= float(b.diameter) / 2.0:
				return {"kind": "boulder", "item": b, "copy": copy}
	for r in _list("ramps"):
		if _rect(r).has_point(units):
			return {"kind": "ramp", "item": r}
	var best = null
	for p in _list("platforms"):
		if _rect(p).has_point(units) and (best == null or float(p.height) > float(best.height)):
			best = p
	if best != null:
		return {"kind": "rooftop", "item": best}
	for b in _list("buildings"):
		if _rect(b).has_point(units):
			return {"kind": "building", "item": b}
	var c := cell_at(units)
	if c.x < 0:
		return {}
	return {"kind": _kind_of_tile(tile_at(c)), "cell": c}


static func _rect(d: Dictionary) -> Rect2:
	return Rect2(float(d.x), float(d.y), float(d.w), float(d.h))


## The piece's footprint in units (a boulder's square around its circle).
func piece_rect(piece: Dictionary) -> Rect2:
	if piece.has("cell"):
		return Rect2(cell_corner(piece.cell), Vector2(CELL, CELL))
	var it: Dictionary = piece.item
	if piece.kind == "boulder":
		var r := float(it.diameter) / 2.0
		return Rect2(float(it.x) - r, float(it.y) - r, 2.0 * r, 2.0 * r)
	return _rect(it)


## Removes a placed piece from the data. A ground or road tile goes back to the plain ground
## (BASE_GROUND). Returns true when something was removed.
func delete(piece: Dictionary) -> bool:
	if piece.is_empty():
		return false
	if piece.has("cell"):
		var c: Vector2i = piece.cell
		if tile_at(c) == BASE_GROUND:
			return false
		cells[c.y][c.x] = BASE_GROUND
		_write_cells()
		refresh_ground_rows()
		return true
	match str(piece.kind):
		"building":
			if _erase_same(_list("buildings"), piece.item):
				refresh_ground_rows()
				return true
		"boulder":
			var copy: Dictionary = piece.copy
			if _erase_same(copy.get("boulders", []), piece.item):
				if copy.boulders.is_empty():
					_erase_same(_list("pattern_copies"), copy)
				return true
		"rooftop":
			if _erase_same(_list("platforms"), piece.item):
				_relink()
				return true
		"ramp":
			if _erase_same(_list("ramps"), piece.item):
				_relink()
				return true
	return false


## Removes the very Dictionary `item` (not an equal one) from `list`.
static func _erase_same(list: Array, item) -> bool:
	for i in list.size():
		if is_same(list[i], item):
			list.remove_at(i)
			return true
	return false


# ---- Saving (T-238) -----------------------------------------------------------------------------

## The level as it is written to its file, in the map-file format of elevation_sample_map.json:
## `data` named `level_name` (also set in `data` itself), with every key the run, GroundHeight and
## the enemies' pathfinding read present (map, legend, ground_rows, buildings, pattern_copies,
## platforms, ramps). Keys already there are kept as they are, so an opened file (the game's own
## map) is written unchanged apart from its name. A deep copy: later edits don't change it.
func file_data(level_name: String) -> Dictionary:
	data["name"] = level_name
	var m = data.get("map")
	if not (m is Dictionary and m.get("rect") is Dictionary and m.has("width") and m.has("height")):
		var r := map_rect()
		var keep: Dictionary = m if m is Dictionary else {}
		keep["width"] = r.size.x
		keep["height"] = r.size.y
		keep["rect"] = {"x": r.position.x, "y": r.position.y, "w": r.size.x, "h": r.size.y}
		data["map"] = keep
	for key in ["buildings", "pattern_copies", "platforms", "ramps"]:
		_list(key)
	if not (data.get("ground_rows") is Array) or not (data.get("legend") is Dictionary):
		refresh_ground_rows()
	return data.duplicate(true)


## A file name (without .json) for a level name: lower case, letters, digits, "-" and "_" kept,
## spaces as "_", anything else dropped; "level" when nothing is left.
static func file_stem(level_name: String) -> String:
	var out := ""
	for ch in level_name.strip_edges().to_lower():
		if ch == " ":
			out += "_"
		elif (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") or ch == "-" or ch == "_":
			out += ch
	return out if out != "" else "level"


# ---- For the drawing (mvp_map.gd and elevation_layer.gd) ---------------------------------------

## The layout mvp_map.gd builds from: the data, with the map's own keys it needs and a file
## without them lacks (map rect, gravel, buildings, pattern_copies) filled in.
func map_layout() -> Dictionary:
	var out := data.duplicate()
	var m := map_rect()
	out["map"] = {"rect": {"x": m.position.x, "y": m.position.y, "w": m.size.x, "h": m.size.y}}
	if not (out.get("gravel") is Dictionary):
		out["gravel"] = {"x": 0.0, "y": 0.0, "w": 0.0, "h": 0.0}
	for key in ["buildings", "pattern_copies", "platforms", "ramps"]:
		if not (out.get(key) is Array):
			out[key] = []
	return out


## The ground layout mvp_map.gd draws (the format of data/level/mvp_ground.json): the game's
## ground atlas, one atlas tile per cell; tiles outside the atlas (road_tile.png) as "extra".
func ground_layout() -> Dictionary:
	var gg := game_ground()
	var extra: Array = []
	var value := {}
	for e in entries():
		if not (str(e.kind) in ["ground", "road"]):
			continue
		if e.has("atlas_index"):
			value[str(e.id)] = int(e.atlas_index)
		else:
			value[str(e.id)] = EXTRA_BASE + extra.size()
			extra.append(str(e.textures[0].texture))
	var out_rows: Array = []
	for row in cells:
		var out: Array = []
		for id in row:
			out.append(int(value.get(id, -1)))
		out_rows.append(out)
	var m := map_rect()
	return {"atlas": gg.get("atlas", "res://art/ground/ground_atlas.png"), "tile_px": gg.get("tile_px", [128, 64]),
		"atlas_columns": gg.get("atlas_columns", 8), "cell_units": CELL, "origin": [m.position.x, m.position.y],
		"cols": cols(), "rows": rows(), "extra": extra, "cells": out_rows}


## Every placed piece except the ground and road tiles: [{kind, item[, copy]}].
func placed_pieces() -> Array:
	var out: Array = []
	for b in _list("buildings"):
		out.append({"kind": "building", "item": b})
	for copy in _list("pattern_copies"):
		for b in copy.get("boulders", []):
			out.append({"kind": "boulder", "item": b, "copy": copy})
	for p in _list("platforms"):
		out.append({"kind": "rooftop", "item": p})
	for r in _list("ramps"):
		out.append({"kind": "ramp", "item": r})
	return out
