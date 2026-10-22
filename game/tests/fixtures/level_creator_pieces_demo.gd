extends Control
## Screenshot fixture (task T-251): the level creator's editor with the small multi-layer level of
## level_creator_pieces_level.gd (rooftops of three sizes, a 6 on a 3, ramps in all four
## directions), drawn in the engine from the piece style. With `drag_from` set, a rooftop at
## `drag_asset` is being dragged from that cell's point to `drag_to` (units): its preview and the
## size readout show; with `ramp_view` a ramp is picked in that direction instead.
## bash game/tools/screenshot.sh res://tests/fixtures/level_creator_pieces_demo.tscn art-archive/T-251/screenshots/creator.png 30

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const Level := preload("res://tests/fixtures/level_creator_pieces_level.gd")

@export var centre_units := Vector2(0, 20)
@export var zoom_factor := 1.6
@export var drag_asset := ""
@export var drag_from := Vector2.ZERO
@export var drag_to := Vector2.ZERO
@export var ramp_view := ""
## The piece style (T-255) the whole level is built in: office, carpark or t198.
@export var style := "office"

var editor: LevelCreatorEditor


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor = EDITOR_SCENE.instantiate()
	editor.open_new()
	add_child(editor)
	editor.pick_style = style
	editor._update_style_button()
	Level.build(editor)
	await get_tree().process_frame
	editor.zoom_by(zoom_factor, editor.map_view.size / 2.0)
	editor.pan_by(editor.map_view.size / 2.0 - editor.units_to_screen(centre_units))
	if drag_asset != "":
		editor.panel.pick(drag_asset)
		for i in 4:
			if ramp_view == "" or editor.pick_view == ramp_view:
				break
			editor.rotate_pick()
		editor.begin_size_drag(drag_from)
		editor.hover_cell = editor.document.cell_at(drag_to)
		editor._update_size_label()
		editor._overlay.queue_redraw()
