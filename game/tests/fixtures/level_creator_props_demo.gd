extends Control
## Screenshot fixture (task T-253): the level creator's editor with every prop in its four rotations
## on the street (west) and on a rooftop (east), see level_creator_props_level.gd. With `pick` set, that
## prop is picked (rotated to `pick_rotation`) with the mouse over `hover_units`, so its preview shows.
## bash game/tools/screenshot.sh res://tests/fixtures/level_creator_props_demo.tscn art-archive/T-253/screenshots/creator.png 30

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const Level := preload("res://tests/fixtures/level_creator_props_level.gd")

@export var centre_units := Vector2(-45, 2)
@export var zoom_factor := 1.4
## Hides the side panel, so the map has the whole window.
@export var hide_panel := true
## Scrolls the panel to its end (the Props category).
@export var scroll_panel := false
@export var pick := ""
@export var pick_rotation := "north"
@export var hover_units := Vector2.ZERO

var editor: LevelCreatorEditor


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor = EDITOR_SCENE.instantiate()
	editor.open_new()
	add_child(editor)
	Level.build(editor)
	await get_tree().process_frame
	editor.panel.visible = not hide_panel
	if scroll_panel:
		editor.panel.get_node("Scroll").scroll_vertical = 100000
	await get_tree().process_frame
	editor.zoom_by(zoom_factor, editor.map_view.size / 2.0)
	editor.pan_by(editor.map_view.size / 2.0 - editor.units_to_screen(centre_units))
	if pick != "":
		editor.panel.pick(pick)
		for i in 4:
			if editor.pick_view == pick_rotation:
				break
			editor.rotate_pick()
		editor.hover_cell = editor.document.cell_at(hover_units)
		editor.hover_units = hover_units
		editor._overlay.queue_redraw()
