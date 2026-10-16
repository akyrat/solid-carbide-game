extends Node
## Test fixture for a screenshot of the level-up screen (task T-052): opens the
## game, presses Start, then levels the car up so the run pauses and the screen
## shows the first level-up's two cards.


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var state: RunState = game.run.state
	state.add_xp(state.xp_needed())
