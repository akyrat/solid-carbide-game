extends Control
## Screenshot fixture (task T-400): the level creator's editor with the small jump ramps of
## level_creator_jump_ramps_level.gd (four directions on the street, on a 3 and on a 6), the ramp
## family picked at `pick` so the top bar shows its label, zoomed on `centre_units`.
## bash game/tools/screenshot.sh res://tests/fixtures/level_creator_jump_ramps_street.tscn art-archive/T-400/screenshots/street.png 30

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const Level := preload("res://tests/fixtures/level_creator_jump_ramps_level.gd")

@export var centre_units := Vector2(-30, 0)
@export var zoom_factor := 2.6
@export var pick := "ramp-0-2"

var editor: LevelCreatorEditor


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor = EDITOR_SCENE.instantiate()
	editor.open_new()
	add_child(editor)
	Level.build(editor)
	editor.panel.pick(pick)
	await get_tree().process_frame
	editor.zoom_by(zoom_factor, editor.map_view.size / 2.0)
	editor.pan_by(editor.map_view.size / 2.0 - editor.units_to_screen(centre_units))
