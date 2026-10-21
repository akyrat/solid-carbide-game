extends Control
## Screenshot fixture (task T-236): the level creator's editor on a new level with rooftops at 3
## and 6 and their ramps, placed through the editor in both of the art's views: the north-west view
## (a 3, a 6 on it, a ramp 0 to 3 up the 3's south side and a ramp 3 to 6 up the 6's west side) and
## the south-east view (the same, rotated: ramps up the north and east sides). A rooftop at 6 is
## picked, rotated to its south-east view and mirrored where it can be, with its preview under the
## "mouse".
## bash game/tools/screenshot.sh res://tests/fixtures/level_creator_heights_demo.tscn art-archive/T-236/screenshots/heights.png 30

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")

## Where the view is centred (map units) and how far it is zoomed in.
@export var centre_units := Vector2(-10, -10)
@export var zoom_factor := 1.0

var editor: LevelCreatorEditor


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor = EDITOR_SCENE.instantiate()
	editor.open_new()
	add_child(editor)
	# North-west view (each asset's first view), as in test_editor_rotate_heights.gd.
	for step in [["rooftop-3", Vector2(-95.5, -95.5)], ["rooftop-6", Vector2(-41.5, -95.5)],
			["ramp-0-3", Vector2(-85.5, -65.5)], ["ramp-3-6", Vector2(-53.5, -85.5)]]:
		editor.panel.pick(step[0])
		editor.place_asset(step[0], step[1])
	# South-east view: rotated once.
	for step in [["rooftop-3", Vector2(12.5, 66.5)], ["rooftop-6", Vector2(12.5, 66.5)],
			["ramp-0-3", Vector2(76.5, 54.5)], ["ramp-3-6", Vector2(42.5, 76.5)]]:
		editor.panel.pick(step[0])
		editor.rotate_pick()
		editor.place_asset(step[0], step[1])
	await get_tree().process_frame
	editor.zoom_by(zoom_factor, editor.map_view.size / 2.0)
	editor.pan_by(editor.map_view.size / 2.0 - editor.units_to_screen(centre_units))
	# The picked rooftop at 6, rotated to its south-east view, previewed on the street.
	editor.panel.pick("rooftop-6")
	editor.rotate_pick()
	editor.hover_cell = editor.document.cell_at(centre_units + Vector2(-30, 30))
	editor._overlay.queue_redraw()
