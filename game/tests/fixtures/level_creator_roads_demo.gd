extends Control
## Screenshot fixture (task T-252): the level creator's editor on a new level with a small street
## grid built from today's two-tile-wide straight roads (the centre-lined tiles the game's map
## uses) and every new road piece (each 2 x 2 tiles, placed with one click): the four corners, the
## four T-junctions, a crossroads, and two short roads closed with a dead end at both ends (all four
## dead end rotations). A corner is picked with its outline under the "mouse".
## bash game/tools/screenshot.sh res://tests/fixtures/level_creator_roads_demo.tscn art-archive/T-252/screenshots/street_grid.png 30

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")

## The grid's top-left corner (map units, even) and how far the view is zoomed in.
const ORIGIN := Vector2(-24, -20)
@export var zoom_factor := 4.4

## Block (column, row; each block is 2 x 2 tiles, 4 x 4 units) -> what stands there: a road piece,
## "sx" (a straight along x) or "sy" (a straight along y).
const GRID := {
	Vector2i(0, 0): "corner_es", Vector2i(1, 0): "sx", Vector2i(2, 0): "t_esw", Vector2i(3, 0): "sx",
	Vector2i(4, 0): "corner_sw",
	Vector2i(0, 1): "sy", Vector2i(2, 1): "sy", Vector2i(4, 1): "sy",
	Vector2i(0, 2): "t_nes", Vector2i(1, 2): "sx", Vector2i(2, 2): "cross", Vector2i(3, 2): "sx",
	Vector2i(4, 2): "t_swn",
	Vector2i(0, 3): "sy", Vector2i(2, 3): "sy", Vector2i(4, 3): "sy",
	Vector2i(0, 4): "corner_ne", Vector2i(1, 4): "sx", Vector2i(2, 4): "t_wne", Vector2i(3, 4): "sx",
	Vector2i(4, 4): "corner_nw",
	# Two short roads, each closed at both ends.
	Vector2i(6, 1): "dead_e", Vector2i(7, 1): "sx", Vector2i(8, 1): "dead_w",
	Vector2i(6, 3): "dead_s", Vector2i(6, 4): "sy", Vector2i(6, 5): "dead_n",
}

var editor: LevelCreatorEditor


## The top-left corner of block (column, row) in map units.
static func block_corner(b: Vector2i) -> Vector2:
	return ORIGIN + Vector2(b) * 4.0


func _place_straight(kind: String, corner: Vector2) -> void:
	for k in 2:
		for m in 2:
			# Across the road: the first tile has the centre line on its far edge, the second on its near one.
			var id := "road-y_line_r_a0" if kind == "sy" else "road-x_line_r_a0"
			var id2 := "road-y_line_l_a0" if kind == "sy" else "road-x_line_l_a0"
			var across := 0 if m == 0 else 1
			var at := corner + (Vector2(across, k) if kind == "sy" else Vector2(k, across)) * 2.0 + Vector2(1, 1)
			editor.place_asset(id if m == 0 else id2, at)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor = EDITOR_SCENE.instantiate()
	editor.open_new()
	add_child(editor)
	for b in GRID:
		var corner := block_corner(b)
		if GRID[b] in ["sx", "sy"]:
			_place_straight(GRID[b], corner)
		else:
			editor.place_asset("road-piece_" + GRID[b], corner + Vector2(1, 1))
	await get_tree().process_frame
	editor.zoom_by(zoom_factor, editor.map_view.size / 2.0)
	var middle := block_corner(Vector2i(4, 3)) + Vector2(0, 2)
	editor.pan_by(editor.map_view.size / 2.0 - editor.units_to_screen(middle))
	editor.panel.pick("road-piece_corner_es")
	editor.hover_cell = editor.document.cell_at(block_corner(Vector2i(9, 3)) + Vector2(1, 1))
	editor._overlay.queue_redraw()
