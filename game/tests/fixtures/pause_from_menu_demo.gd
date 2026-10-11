extends Node
## Test fixture for a screenshot of a paused run started from the main menu
## (task T-095): opens the game, presses Start, then pauses.

var game: Node
var _frames := 0


func _ready() -> void:
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()


func _process(_delta: float) -> void:
	_frames += 1
	if _frames == 40:
		game.pause_screen.pause()
