extends Control
## Screenshot fixture (task T-252): the level creator's editor on a new level with a small street
## grid built from every road piece: the four corners, the four T-junctions, a crossroads and the
## 1-tile-wide straights between them, and two short roads with dead ends in all four rotations,
## all placed through the editor. A corner is picked with its outline under the "mouse".
## bash game/tools/screenshot.sh res://tests/fixtures/level_creator_roads_demo.tscn art-archive/T-252/screenshots/street_grid.png 30

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")

## The grid's top-left cell corner (map units, even) and how far the view is zoomed in.
const ORIGIN := Vector2(-10, -10)
@export var zoom_factor := 8.0

## Cell (column, row) -> the road piece placed there.
const GRID := {
	Vector2i(1, 1): "corner_es", Vector2i(2, 1): "mid_x", Vector2i(3, 1): "t_esw", Vector2i(4, 1): "mid_x",
	Vector2i(5, 1): "corner_sw",
	Vector2i(1, 2): "mid_y", Vector2i(3, 2): "mid_y", Vector2i(5, 2): "mid_y",
	Vector2i(1, 3): "t_nes", Vector2i(2, 3): "mid_x", Vector2i(3, 3): "cross", Vector2i(4, 3): "mid_x",
	Vector2i(5, 3): "t_swn",
	Vector2i(1, 4): "mid_y", Vector2i(3, 4): "mid_y", Vector2i(5, 4): "mid_y",
	Vector2i(1, 5): "corner_ne", Vector2i(2, 5): "mid_x", Vector2i(3, 5): "t_wne", Vector2i(4, 5): "mid_x",
	Vector2i(5, 5): "corner_nw",
	# Two short roads, each closed at both ends.
	Vector2i(7, 3): "dead_e", Vector2i(8, 3): "dead_w",
	Vector2i(7, 5): "dead_s", Vector2i(7, 6): "dead_n",
}

var editor: LevelCreatorEditor


## The centre of cell (column, row), in map units.
static func cell_centre(c: Vector2i) -> Vector2:
	return ORIGIN + Vector2(c) * 2.0 + Vector2(1, 1)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor = EDITOR_SCENE.instantiate()
	editor.open_new()
	add_child(editor)
	for c in GRID:
		editor.place_asset("road-piece_" + GRID[c], cell_centre(c))
	await get_tree().process_frame
	editor.zoom_by(zoom_factor, editor.map_view.size / 2.0)
	var middle := cell_centre(Vector2i(4, 3))
	editor.pan_by(editor.map_view.size / 2.0 - editor.units_to_screen(middle))
	editor.panel.pick("road-piece_corner_es")
	editor.hover_cell = editor.document.cell_at(cell_centre(Vector2i(8, 1)))
	editor._overlay.queue_redraw()
