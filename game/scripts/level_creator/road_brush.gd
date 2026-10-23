class_name RoadBrush
extends RefCounted
## The level creator's road brush (task T-263; Level design, Decisions, "Level creator rework").
## Roads are painted, not placed tile by tile: the editor (editor.gd) hands the blocks a drag
## crosses to paint(), and the brush lays a whole road on each, today's two-tile-wide road (2 x 2
## tiles, 4 x 4 units: a "block"), and picks every tile itself from the blocks around it, so
## wherever painted roads meet they join: straights along y and x, corners, T-junctions,
## crossroads, and dead ends at the open ends (a kerb). erase() takes road off and the neighbours
## join again; zebra_at() lays a crossing across a straight road.
##
## The level's data is unchanged: the brush only writes the ground and road tiles of the cells
## (LevelDocument.set_cells, the catalogue's road tiles: T-103's straights, T-252's centre-line
## pieces on a0 and T-263's on the other asphalts, build_ground_tiles.py), so a painted level
## plays as before. What a block is (its road kind, asphalt and crossing) is read back from its
## tiles (state_of), so painting next to a road saved earlier joins it too.
##
## Blocks lie on the grid of even cells (block (i, j) is cells 2i, 2i + 1 and 2j, 2j + 1). A block
## is a road when all four of its cells are road tiles. Every road block joins every road block next
## to it (its "arms"), so two roads painted side by side become one wide road (a proposal).
##
## Road kinds (the families with "brush": "paint" in creator_assets.json, build_creator_assets.py):
## "road" and "cracked-road" (the plain tiles of their asphalt; a corner, T-junction or crossroads
## is all plain, since a closed side is just the asphalt's edge), "centre-line" (the line in the
## road's middle, joined across every piece). A road never paints over a building, platform or
## ramp (blocked).

## Cells per side of a block: a road is two tiles wide.
const BLOCK := 2
const PAINT_KINDS := ["road", "centre-line", "cracked-road"]
## The asphalts of Cracked road (the plain tiles of those asphalts are read back as cracked).
const CRACKED_ASPHALTS := ["g4", "g5", "g7"]
## The asphalts the centre-line pieces exist on (T-252's a0, T-263's others); another falls back to a0.
const LINE_ASPHALTS := ["a0", "a0m", "g6", "g9"]
const DIRS := {"n": Vector2i(0, -1), "e": Vector2i(1, 0), "s": Vector2i(0, 1), "w": Vector2i(-1, 0)}
const ARM_ORDER := "nesw"
## The T-252 piece for each set of arms (in ARM_ORDER), straights and the empty set aside.
const PIECE_OF_ARMS := {
	"ne": "corner_ne", "es": "corner_es", "sw": "corner_sw", "nw": "corner_nw",
	"nes": "t_nes", "esw": "t_esw", "nsw": "t_swn", "new": "t_wne",
	"nesw": "cross",
	"n": "dead_n", "e": "dead_e", "s": "dead_s", "w": "dead_w",
}


# ---- Blocks -------------------------------------------------------------------------------------

## The block under a point (units), (-1, -1) outside the map's whole blocks.
static func block_at(doc: LevelDocument, units: Vector2) -> Vector2i:
	var c := doc.cell_at(units)
	if c.x < 0:
		return Vector2i(-1, -1)
	var b := Vector2i(c.x / BLOCK, c.y / BLOCK)
	return b if inside(doc, b) else Vector2i(-1, -1)


static func inside(doc: LevelDocument, b: Vector2i) -> bool:
	return b.x >= 0 and b.y >= 0 and (b.x + 1) * BLOCK <= doc.cols() and (b.y + 1) * BLOCK <= doc.rows()


## The block's footprint, units.
static func block_rect(doc: LevelDocument, b: Vector2i) -> Rect2:
	return Rect2(doc.cell_corner(b * BLOCK), Vector2(BLOCK, BLOCK) * LevelDocument.CELL)


## True when a building, platform or ramp covers part of the block (a road never paints over one).
static func blocked(doc: LevelDocument, b: Vector2i) -> bool:
	var r := block_rect(doc, b)
	for key in ["buildings", "platforms", "ramps"]:
		for it in doc.data.get(key, []):
			if r.intersects(Rect2(float(it.x), float(it.y), float(it.w), float(it.h))):
				return true
	return false


## The blocks from `a` to `b`, each next to the one before (no diagonal gaps): the road a drag
## lays between two mouse positions. Steps along the axis with more left to go (x on a tie).
static func blocks_between(a: Vector2i, b: Vector2i) -> Array:
	var out: Array = [a]
	var cur := a
	while cur != b:
		var d := b - cur
		if absi(d.x) >= absi(d.y):
			cur.x += signi(d.x)
		else:
			cur.y += signi(d.y)
		out.append(cur)
	return out


# ---- Reading a road back from its tiles ---------------------------------------------------------

## What a road tile (catalogue id) is: {line, zebra ("y", "x" or ""), asphalt}; {} for a tile that
## is not a road.
static func tile_info(id: String) -> Dictionary:
	if not id.begins_with("road-"):
		return {}
	var name := id.trim_prefix("road-")
	var parts := name.split("_")
	if name == "road_tile" or name.begins_with("piece_"):
		return {"line": true, "zebra": "", "asphalt": "a0"}
	if name.begins_with("brush_line_"):
		return {"line": true, "zebra": "", "asphalt": parts[parts.size() - 2]}
	if name.begins_with("brush_plain_"):
		return {"line": false, "zebra": "", "asphalt": parts[parts.size() - 2]}
	if parts.size() >= 3 and parts[0] in ["y", "x"]:
		var kind := parts[1]
		return {"line": kind == "line", "zebra": parts[0] if kind == "zebra" else "",
			"asphalt": parts[parts.size() - 1]}
	return {"line": false, "zebra": "", "asphalt": "a0"}


## A road block's {kind, asphalt, zebra ({axis, index}: the crossing's row of tiles across the
## road, {} for none)}, read from its four tiles; {} when the block is not a road.
static func state_of(doc: LevelDocument, b: Vector2i) -> Dictionary:
	if not inside(doc, b):
		return {}
	var infos := {}
	for r in BLOCK:
		for c in BLOCK:
			var info := tile_info(doc.tile_at(b * BLOCK + Vector2i(c, r)))
			if info.is_empty():
				return {}
			infos[Vector2i(c, r)] = info
	var line := false
	var asphalt := ""
	var zebra_asphalt := ""
	for k in infos:
		var info: Dictionary = infos[k]
		if str(info.zebra) != "":
			zebra_asphalt = str(info.asphalt)
			continue
		line = line or bool(info.line)
		if asphalt == "":
			asphalt = str(info.asphalt)
	if asphalt == "":
		asphalt = zebra_asphalt
	var zebra := {}
	for i in BLOCK:
		# A crossing along y fills a row of the block (both columns), along x a column.
		var a: Vector2i = Vector2i(0, i)
		var o: Vector2i = Vector2i(1, i)
		if str(infos[a].zebra) == "y" and str(infos[o].zebra) == "y":
			zebra = {"axis": "y", "index": i}
		a = Vector2i(i, 0)
		o = Vector2i(i, 1)
		if str(infos[a].zebra) == "x" and str(infos[o].zebra) == "x":
			zebra = {"axis": "x", "index": i}
	var kind := "centre-line" if line else ("cracked-road" if asphalt in CRACKED_ASPHALTS else "road")
	return {"kind": kind, "asphalt": asphalt, "zebra": zebra}


## The arms of a road block in ARM_ORDER ("ns", "nes", ...): the sides with a road block next to
## it. `state` reads a block's state (state_of, or the brush's own while it paints).
static func arms_of(b: Vector2i, state: Callable) -> String:
	var out := ""
	for d in ARM_ORDER:
		if not (state.call(b + DIRS[d]) as Dictionary).is_empty():
			out += d
	return out


## The piece a block with these arms is: "straight_y", "straight_x", "single" (no arms), or a
## T-252 piece name (corner_ne, t_nes, cross, dead_n, ...).
static func piece_of(arms: String) -> String:
	if arms == "ns":
		return "straight_y"
	if arms == "ew":
		return "straight_x"
	if arms == "":
		return "single"
	return str(PIECE_OF_ARMS[arms])


# ---- The tiles of a block -----------------------------------------------------------------------

## The four tiles (catalogue ids) of a road block of `kind` and `asphalt` with `arms`, rows of two
## columns ([[top-left, top-right], [bottom-left, bottom-right]]), with its crossing `zebra` when the
## block is a straight along the crossing's road.
static func tiles_for(kind: String, asphalt: String, arms: String, zebra: Dictionary = {}) -> Array:
	var line := kind == "centre-line"
	var a := asphalt
	if line and not (a in LINE_ASPHALTS):
		a = "a0"
	var piece := piece_of(arms)
	var t: Array = []
	match piece:
		"straight_y":
			t = [["road-y_line_r_" + a, "road-y_line_l_" + a], ["road-y_line_r_" + a, "road-y_line_l_" + a]] if line \
				else _all("road-y_plain_" + a)
			if str(zebra.get("axis", "")) == "y":
				t[int(zebra.index)] = ["road-y_zebra_e0_" + asphalt, "road-y_zebra_e1_" + asphalt]
		"straight_x":
			t = [["road-x_line_r_" + a, "road-x_line_r_" + a], ["road-x_line_l_" + a, "road-x_line_l_" + a]] if line \
				else _all("road-x_plain_" + a)
			if str(zebra.get("axis", "")) == "x":
				t[0][int(zebra.index)] = "road-x_zebra_e0_" + asphalt
				t[1][int(zebra.index)] = "road-x_zebra_e1_" + asphalt
		"single":
			t = _all("road-y_plain_" + a)
		_:
			if line:
				t = _piece(piece, a)
			elif piece.begins_with("dead_"):
				t = [["road-brush_plain_%s_%s_00" % [piece, a], "road-brush_plain_%s_%s_10" % [piece, a]],
					["road-brush_plain_%s_%s_01" % [piece, a], "road-brush_plain_%s_%s_11" % [piece, a]]]
			else:
				t = _all("road-y_plain_" + a)
	return t


static func _all(id: String) -> Array:
	return [[id, id], [id, id]]


static func _piece(piece: String, a: String) -> Array:
	var out: Array = []
	for r in BLOCK:
		var row: Array = []
		for c in BLOCK:
			row.append("road-piece_%s_%d%d" % [piece, c, r] if a == "a0" else "road-brush_line_%s_%s_%d%d" % [piece, a, c, r])
		out.append(row)
	return out


## True when the crossing `zebra` lies across a block with these arms (a straight along its road).
static func zebra_fits(arms: String, zebra: Dictionary) -> bool:
	return (arms == "ns" and str(zebra.get("axis", "")) == "y") or (arms == "ew" and str(zebra.get("axis", "")) == "x")


# ---- Painting, erasing, crossings ---------------------------------------------------------------

## Paints a road of `kind` (PAINT_KINDS) on `asphalt` over `blocks` (block coordinates; those outside
## the map or under a building, platform or ramp are left out), and joins it with the roads around.
## Painting over a road changes its kind and asphalt and keeps its crossing. Returns the blocks
## painted.
static func paint(doc: LevelDocument, blocks: Array, kind: String, asphalt: String) -> Array:
	var cache := {}
	var painted: Array = []
	for b in blocks:
		if not inside(doc, b) or blocked(doc, b) or b in painted:
			continue
		var old := _cached(doc, cache, b)
		cache[b] = {"kind": kind, "asphalt": asphalt, "zebra": old.get("zebra", {})}
		painted.append(b)
	_retile(doc, cache, _with_neighbours(painted))
	return painted


## Takes the road off `blocks` (their road tiles go back to the plain ground) and joins the roads
## around them again. Returns the blocks that had road on them.
static func erase(doc: LevelDocument, blocks: Array) -> Array:
	var cache := {}
	var erased: Array = []
	var changes := {}
	for b in blocks:
		if not inside(doc, b) or b in erased:
			continue
		var had := false
		for r in BLOCK:
			for c in BLOCK:
				var cell: Vector2i = b * BLOCK + Vector2i(c, r)
				if not tile_info(doc.tile_at(cell)).is_empty():
					changes[cell] = LevelDocument.BASE_GROUND
					had = true
		if had:
			_cached(doc, cache, b)
			erased.append(b)
	for b in erased:
		cache[b] = {}
	var around: Array = []
	for b in _with_neighbours(erased):
		if not (b in erased):
			around.append(b)
	_retile(doc, cache, around, changes)
	return erased


## Lays a zebra crossing across the road at `units`: the row of tiles across the road under the
## point, on a straight block (not a junction, corner or dead end). Returns true when it was laid.
static func zebra_at(doc: LevelDocument, units: Vector2) -> bool:
	var b := block_at(doc, units)
	if b.x < 0:
		return false
	var cache := {}
	var s := _cached(doc, cache, b)
	if s.is_empty():
		return false
	var arms := arms_of(b, func(x): return _cached(doc, cache, x))
	var cell := doc.cell_at(units) - b * BLOCK
	var zebra := {}
	if arms == "ns":
		zebra = {"axis": "y", "index": cell.y}
	elif arms == "ew":
		zebra = {"axis": "x", "index": cell.x}
	else:
		return false
	cache[b] = {"kind": s.kind, "asphalt": s.asphalt, "zebra": zebra}
	_retile(doc, cache, [b])
	return true


## The cells a crossing clicked at `units` would take ({} rect: none), for the editor's outline.
static func zebra_rect(doc: LevelDocument, units: Vector2) -> Rect2:
	var b := block_at(doc, units)
	if b.x < 0 or state_of(doc, b).is_empty():
		return Rect2()
	var arms := arms_of(b, func(x): return state_of(doc, x))
	var cell := doc.cell_at(units)
	var r := block_rect(doc, b)
	if arms == "ns":
		return Rect2(Vector2(r.position.x, doc.cell_corner(cell).y), Vector2(r.size.x, LevelDocument.CELL))
	if arms == "ew":
		return Rect2(Vector2(doc.cell_corner(cell).x, r.position.y), Vector2(LevelDocument.CELL, r.size.y))
	return Rect2()


static func _cached(doc: LevelDocument, cache: Dictionary, b: Vector2i) -> Dictionary:
	if not cache.has(b):
		cache[b] = state_of(doc, b)
	return cache[b]


static func _with_neighbours(blocks: Array) -> Array:
	var out: Array = []
	for b in blocks:
		for x in [b, b + DIRS.n, b + DIRS.e, b + DIRS.s, b + DIRS.w]:
			if not (x in out):
				out.append(x)
	return out


## Writes the tiles of every road block in `blocks` from the states in `cache` (read from the level
## first, so every block's arms come from the level as it was plus the brush's changes), together
## with the cells in `changes`, in one go.
static func _retile(doc: LevelDocument, cache: Dictionary, blocks: Array, changes: Dictionary = {}) -> void:
	var read := func(x): return _cached(doc, cache, x)
	var plan: Array = []
	for b in blocks:
		if not inside(doc, b):
			continue
		var s: Dictionary = _cached(doc, cache, b)
		if s.is_empty():
			continue
		plan.append([b, s, arms_of(b, read)])
	for p in plan:
		var b: Vector2i = p[0]
		var s: Dictionary = p[1]
		var zebra: Dictionary = s.zebra if zebra_fits(p[2], s.zebra) else {}
		var t := tiles_for(str(s.kind), str(s.asphalt), str(p[2]), zebra)
		for r in BLOCK:
			for c in BLOCK:
				changes[b * BLOCK + Vector2i(c, r)] = str(t[r][c])
	if not changes.is_empty():
		doc.set_cells(changes)
