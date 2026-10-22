extends Control
## Screenshot fixture (task T-254): the creator's new buildings beside today's. In a row, left to
## right: a skyscraper, a short building (12 x 12), the small building (6 x 6), the long building
## (12 x 6) and the long building rotated (6 x 12).
## bash game/tools/screenshot.sh res://tests/fixtures/level_creator_buildings_demo.tscn art-archive/T-254/screenshots/new_buildings.png 30

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")

@export var centre_units := Vector2(-20, 6)
@export var zoom_factor := 1.7

var editor: LevelCreatorEditor


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor = EDITOR_SCENE.instantiate()
	editor.open_new()
	add_child(editor)
	for step in [["skyscraper-3", Vector2(-59.5, 0.5), 0], ["short-0", Vector2(-41.5, 0.5), 0],
			["building-small", Vector2(-23.5, 0.5), 0], ["building-long", Vector2(-11.5, 0.5), 0],
			["building-long", Vector2(12.5, 0.5), 1]]:
		editor.panel.pick(step[0])
		for i in int(step[2]):
			editor.rotate_pick()
		editor.place_asset(step[0], step[1])
	editor.panel.pick("")
	await get_tree().process_frame
	editor.zoom_by(zoom_factor, editor.map_view.size / 2.0)
	editor.pan_by(editor.map_view.size / 2.0 - editor.units_to_screen(centre_units))
