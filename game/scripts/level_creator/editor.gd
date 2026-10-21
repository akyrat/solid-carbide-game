class_name LevelCreatorEditor
extends Control
## The level creator's editor (a stub in task T-234; the editor tickets fill it in). It holds the
## level being edited: an empty map for a new level, or the loaded file for an existing one.

signal back_pressed

## The level's data (the map-file format of data/level/elevation_sample_map.json).
var level_data: Dictionary = {}
## The file the level was loaded from; "" for a new level.
var level_path: String = ""
var back_button: Button


## A new level: an empty map with the default name.
func open_new() -> void:
	level_path = ""
	level_data = empty_level()


## An existing level, loaded from its file.
func open_level(path: String) -> void:
	level_path = path
	level_data = LevelStore.load_level(path)


static func empty_level() -> Dictionary:
	return {
		"name": CreatorTexts.get_text("default_level_name"),
		"legend": {},
		"ground_rows": [],
		"buildings": [],
		"pattern_copies": [],
		"platforms": [],
		"ramps": [],
	}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.12, 0.12, 0.14)
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = CreatorTexts.get_text("back_button")
	back_button.position = Vector2(16, 16)
	back_button.pressed.connect(func(): back_pressed.emit())
	add_child(back_button)
