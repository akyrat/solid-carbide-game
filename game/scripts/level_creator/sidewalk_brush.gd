class_name SidewalkBrush
extends RefCounted
## The level creator's sidewalk brush (task T-398; Level design, Decisions, "Sidewalks and parked
## cars in the level creator"). A sidewalk is painted like a road, cell by cell (one 2 x 2 unit
## ground tile: a proposal, so a sidewalk can be one tile wide beside a road), and wherever a
## sidewalk tile meets a road the curb is added by itself: rejoin() gives every sidewalk cell the
## tile of its curb piece, so painting or erasing a road next to a sidewalk changes its curb too.
##
## The level's data stays a ground tile per cell (LevelDocument.cells, catalogue ids): the sidewalk
## tiles are the catalogue's ground entries with "sidewalk" (build_creator_assets.py
## sidewalk_entries, from art/ground/sidewalk_tiles.json, game/tools/build_street_pieces.py), named
## after their curb piece, the same names here and there:
##   edges   the sides with a road next to them, of "nesw" (n = -y, the screen's upper right; e = +x,
##           lower right; s = +y, lower left; w = -x, upper left): a straight curb along each.
##   corners the inner corners (ne, se, sw, nw): a road diagonally next to the cell while neither side
##           of that corner has one. Two edges next to each other make an outer corner by themselves.
##   name    "sidewalk", then "-<edges>" with edges, then "-in_<corner>_..." with inner corners.
## A sidewalk is never painted over a road, a building, a platform or a ramp (they stay; a proposal,
## as roads stop at buildings). Erasing a sidewalk cell gives it the plain ground back.
##
## In the run a sidewalk is ground like the street, height 0 (the curb is drawn on the tile): the car
## drives over the curb, a step under the 0.1-unit curb rule (Drifting, Decisions, "Curbs").

const BASE := "sidewalk"
const EDGE_ORDER := "nesw"
const CORNER_ORDER := ["ne", "se", "sw", "nw"]
const DIRS := {"n": Vector2i(0, -1), "e": Vector2i(1, 0), "s": Vector2i(0, 1), "w": Vector2i(-1, 0)}


## True for a sidewalk tile's catalogue id (any curb piece).
static func is_sidewalk(id: String) -> bool:
	return id == BASE or id.begins_with(BASE + "-")


## The tile name of a curb piece (edges in EDGE_ORDER, corners in CORNER_ORDER).
static func tile_name(edges: String, corners: Array) -> String:
	var s := BASE
	if edges != "":
		s += "-" + edges
	if not corners.is_empty():
		s += "-in_" + "_".join(PackedStringArray(corners))
	return s


## {edges, corners} of a sidewalk tile's name ({} for another tile).
static func curbs_of(id: String) -> Dictionary:
	if not is_sidewalk(id):
		return {}
	var edges := ""
	var corners: Array = []
	for part in id.trim_prefix(BASE).split("-", false):
		if part.begins_with("in_"):
			for c in part.trim_prefix("in_").split("_", false):
				corners.append(c)
		else:
			edges = part
	return {"edges": edges, "corners": corners}


static func _is_road_at(doc: LevelDocument, c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= doc.cols() or c.y >= doc.rows():
		return false
	return LevelDocument._kind_of_tile(doc.tile_at(c)) == "road"


## The curb piece a sidewalk on cell `c` takes from the roads around it.
static func tile_for(doc: LevelDocument, c: Vector2i) -> String:
	var edges := ""
	for d in EDGE_ORDER:
		if _is_road_at(doc, c + DIRS[d]):
			edges += d
	var corners: Array = []
	for k in CORNER_ORDER:
		var a: String = k[0]
		var b: String = k[1]
		if a in edges or b in edges:
			continue
		if _is_road_at(doc, c + DIRS[a] + DIRS[b]):
			corners.append(k)
	return tile_name(edges, corners)


## Gives every sidewalk cell of `doc` the tile of its curb piece (in doc.cells; the caller writes the
## data). Returns how many cells changed.
static func rejoin(doc: LevelDocument) -> int:
	var n := 0
	for j in doc.rows():
		var row: Array = doc.cells[j]
		for i in doc.cols():
			if not is_sidewalk(str(row[i])):
				continue
			var t := tile_for(doc, Vector2i(i, j))
			if t != str(row[i]):
				row[i] = t
				n += 1
	return n


# ---- Painting -----------------------------------------------------------------------------------

## The cell under a point (units), (-1, -1) outside the map.
static func cell_at(doc: LevelDocument, units: Vector2) -> Vector2i:
	return doc.cell_at(units)


## The cell's footprint, units.
static func cell_rect(doc: LevelDocument, c: Vector2i) -> Rect2:
	return Rect2(doc.cell_corner(c), Vector2(LevelDocument.CELL, LevelDocument.CELL))


## True when a sidewalk can't go on the cell: a road, or a building, platform or ramp over it.
static func blocked(doc: LevelDocument, c: Vector2i) -> bool:
	if _is_road_at(doc, c):
		return true
	var r := cell_rect(doc, c)
	for key in ["buildings", "platforms", "ramps"]:
		for it in doc.data.get(key, []):
			if r.intersects(Rect2(float(it.x), float(it.y), float(it.w), float(it.h))):
				return true
	return false


## Paints sidewalk on `cells` (those inside the map and not blocked). Returns the cells painted.
static func paint(doc: LevelDocument, cells: Array) -> Array:
	var changes := {}
	for c in cells:
		var cell: Vector2i = c
		if cell.x < 0 or cell.y < 0 or cell.x >= doc.cols() or cell.y >= doc.rows():
			continue
		if is_sidewalk(doc.tile_at(cell)) or blocked(doc, cell):
			continue
		changes[cell] = BASE
	if not changes.is_empty():
		doc.set_cells(changes)  # rejoins the curbs (LevelDocument._write_cells)
	return changes.keys()


## Erases the sidewalk on `cells` (back to the plain ground). Returns the cells erased.
static func erase(doc: LevelDocument, cells: Array) -> Array:
	var changes := {}
	for c in cells:
		var cell: Vector2i = c
		if cell.x < 0 or cell.y < 0 or cell.x >= doc.cols() or cell.y >= doc.rows():
			continue
		if is_sidewalk(doc.tile_at(cell)):
			changes[cell] = LevelDocument.BASE_GROUND
	if not changes.is_empty():
		doc.set_cells(changes)
	return changes.keys()
