extends Control
## Screenshot fixture (task T-604): the level creator opened on the tutorial's practice playground,
## as the --open=res://data/level/practice_playground.json launch does (LevelCreator.open_editor_in_place).
## It never saves. bash game/tools/screenshot.sh res://tests/fixtures/creator_practice_playground_demo.tscn <out.png> 60

const PLAYGROUND := "res://data/level/practice_playground.json"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var c: LevelCreator = load("res://scenes/level_creator/level_creator.tscn").instantiate()
	add_child(c)
	c.open_editor_in_place(PLAYGROUND)
