extends Control
## Screenshot fixture (task T-263): the level creator's editor on a new level with the street grid
## of level_creator_road_brush_grid.gd, painted with the road brush in a few drags (Centre line,
## Road and Cracked road, with zebra crossings), every junction kind joined by the brush. Centre
## line is picked, its block outline under the "mouse".
## bash game/tools/screenshot.sh res://tests/fixtures/level_creator_road_brush_demo.tscn art-archive/T-263/screenshots/street_grid.png 30
## (level_creator_road_brush_close.tscn: closer, on the centre line's junctions.)

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const Grid := preload("res://tests/fixtures/level_creator_road_brush_grid.gd")

## How far the view is zoomed in, and the block (from the grid's origin) in the middle of the view.
@export var zoom_factor := 2.3
@export var centre := Vector2(5.5, 5.5)
## The block (from the grid's origin) under the "mouse".
@export var hover := Vector2i(16, 9)

var editor: LevelCreatorEditor


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor = EDITOR_SCENE.instantiate()
	editor.open_new()
	add_child(editor)
	Grid.build(editor)
	await get_tree().process_frame
	editor.zoom_by(zoom_factor, editor.map_view.size / 2.0)
	var rect := RoadBrush.block_rect(editor.document, Grid.ORIGIN)
	var middle := rect.position + centre * 4.0
	editor.pan_by(editor.map_view.size / 2.0 - editor.units_to_screen(middle))
	Grid.pick(editor, "centre-line", 0)
	editor.hover_units = Grid.block_middle(editor, hover)
	editor.hover_cell = editor.document.cell_at(editor.hover_units)
	editor._overlay.queue_redraw()
