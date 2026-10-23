extends RefCounted
## Task T-263: the street grid of the road brush's tests, screenshots and GIF, painted through the
## level creator's editor as the board would: pick a road kind (and a look), drag along the road
## (editor.gd paint_road), click a zebra crossing across a road (place_zebra). Every junction kind
## comes out of a few drags: corners, T-junctions, crossroads, dead ends, and straights along y
## and x, for each road kind (Centre line, Road, Cracked road).
##
## Blocks are the brush's 2 x 2 tiles (4 x 4 units), counted from ORIGIN (a block of the map's grid).

## The grid's first block (block coordinates of the map's grid of blocks, 60 x 60 on a new level).
const ORIGIN := Vector2i(24, 24)

## [family, look (V presses), the drag's turning points (blocks from ORIGIN)].
const STROKES := [
	# Centre line: a ring with a road across its middle and one down its middle.
	["centre-line", 0, [Vector2i(0, 8), Vector2i(0, 0), Vector2i(12, 0), Vector2i(12, 8), Vector2i(0, 8)]],
	["centre-line", 0, [Vector2i(0, 4), Vector2i(16, 4)]],
	["centre-line", 0, [Vector2i(6, 0), Vector2i(6, 8)]],
	# Road (V once: asphalt g6) off the ring's bottom: a straight down, a corner, a dead end.
	["road", 1, [Vector2i(3, 9), Vector2i(3, 12), Vector2i(9, 12)]],
	# Cracked road (V once: asphalt g5) off the ring's west side: a T-junction and two dead ends.
	["cracked-road", 1, [Vector2i(-1, 2), Vector2i(-5, 2)]],
	["cracked-road", 1, [Vector2i(-3, 1), Vector2i(-3, -1)]],
]
## What the grid's junctions come out as (blocks from ORIGIN -> RoadBrush.piece_of), for the tests.
const EXPECTED := {
	Vector2i(0, 0): "corner_es", Vector2i(12, 0): "corner_sw", Vector2i(12, 8): "corner_nw", Vector2i(0, 8): "corner_ne",
	Vector2i(0, 4): "t_nes", Vector2i(6, 0): "t_esw", Vector2i(0, 2): "t_swn", Vector2i(6, 8): "t_wne",
	Vector2i(6, 4): "cross", Vector2i(12, 4): "cross",
	Vector2i(16, 4): "dead_w", Vector2i(3, 12): "corner_ne", Vector2i(9, 12): "dead_w", Vector2i(3, 8): "t_esw",
	Vector2i(-3, 2): "t_wne", Vector2i(-5, 2): "dead_e", Vector2i(-3, -1): "dead_s",
	Vector2i(2, 0): "straight_x", Vector2i(0, 6): "straight_y", Vector2i(3, 10): "straight_y", Vector2i(-4, 2): "straight_x",
}
## Zebra crossings (blocks from ORIGIN, and the tile (column, row) clicked inside the block).
const ZEBRAS := [
	[Vector2i(3, 0), Vector2i(0, 1)],
	[Vector2i(9, 4), Vector2i(1, 0)],
	[Vector2i(3, 10), Vector2i(0, 0)],
	[Vector2i(14, 4), Vector2i(0, 0)],
]


## A point (units) in the middle of block `b` (from ORIGIN) of `editor`'s level.
static func block_middle(editor, b: Vector2i) -> Vector2:
	return RoadBrush.block_rect(editor.document, ORIGIN + b).get_center()


## A point in the middle of tile `t` (column, row) of block `b`.
static func tile_middle(editor, b: Vector2i, t: Vector2i) -> Vector2:
	return RoadBrush.block_rect(editor.document, ORIGIN + b).position + Vector2(t) * 2.0 + Vector2(1, 1)


## Picks `family` at look `look` (V pressed that many times).
static func pick(editor, family: String, look: int) -> void:
	editor.panel.pick(family)
	for i in look:
		editor.look_pick()


## The drag of a stroke: its turning points as points on the map.
static func points_of(editor, stroke: Array) -> Array:
	return (stroke[2] as Array).map(func(b): return block_middle(editor, b))


## Paints every stroke and lays every crossing through `editor` (LevelCreatorEditor).
static func build(editor) -> void:
	for s in STROKES:
		pick(editor, s[0], s[1])
		editor.paint_road(points_of(editor, s))
	editor.panel.pick("zebra-crossing")
	for z in ZEBRAS:
		editor.place_zebra(tile_middle(editor, z[0], z[1]))
	editor.panel.pick("")
