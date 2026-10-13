extends Node
## Screenshot fixture for the level-up effect (task T-112): a run started from
## the main menu, and a level-up a few frames before the picture, so the
## burst is spread around the car. Take it with 40 frames.

## Frames to wait after the start before the level-up (the picture comes at
## the screenshot tool's frame count).
const LEVEL_UP_AT_FRAME := 20


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	for i in LEVEL_UP_AT_FRAME:
		await get_tree().process_frame
	var run: Node2D = game.run
	run.state.add_xp(run.state.xp_needed())
