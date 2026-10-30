extends Node
## Test fixture for screenshots of the pause screen's trick list panel (task T-386):
## starts a run from the main menu, pauses, and opens the trick list panel.

var game: Node
var _frames := 0


func _ready() -> void:
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.start_run()  # the menu's Start opens the tutorial slides first (T-389)


func _process(_delta: float) -> void:
	_frames += 1
	if _frames == 40:
		game.pause_screen.pause()
		game.pause_screen.open_trick_list()
