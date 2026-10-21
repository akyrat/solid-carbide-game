extends Control
## Screenshot fixture (task T-238): the level creator's editor on a new level with a piece of every
## kind, named in the level name field and saved with the Save button: the top bar shows the save
## confirmation. It saves into this run's own temporary folder (RunPaths), never the real levels
## folder, and removes it afterwards.
## bash game/tools/screenshot.sh res://tests/fixtures/level_creator_save_demo.tscn art-archive/T-238/screenshots/saved.png 30

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
## The name typed in the field (a demo name, not shown to players).
@export var demo_name := "Rooftop corner"
@export var centre_units := Vector2(-40, -40)
@export var zoom_factor := 1.0

var editor: LevelCreatorEditor


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor = EDITOR_SCENE.instantiate()
	editor.levels_dir = RunPaths.file("t238_screenshot_levels")
	editor.open_new()
	add_child(editor)
	for step in [["ground-gravel2", Vector2(-30.5, -30.5)], ["road-x_zebra_g4", Vector2(-20.0, -30.0)],
			["skyscraper-3", Vector2(-10.0, -10.0)], ["boulder-a", Vector2(-50.0, -20.0)],
			["rooftop-3", Vector2(-95.5, -95.5)], ["rooftop-6", Vector2(-41.5, -95.5)],
			["ramp-0-3", Vector2(-85.5, -65.5)], ["ramp-3-6", Vector2(-53.5, -85.5)]]:
		editor.panel.pick(step[0])
		editor.place_asset(step[0], step[1])
	editor.panel.pick("")
	await get_tree().process_frame
	editor.zoom_by(zoom_factor, editor.map_view.size / 2.0)
	editor.pan_by(editor.map_view.size / 2.0 - editor.units_to_screen(centre_units))
	editor.name_field.text = demo_name
	editor.save_button.pressed.emit()
	print("saved: ", editor.level_path, " -> ", ProjectSettings.globalize_path(editor.level_path))


func _exit_tree() -> void:
	RunPaths.cleanup()
