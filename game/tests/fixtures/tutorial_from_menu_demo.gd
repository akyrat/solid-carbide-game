extends Node
## Test fixture for a screenshot of the tutorial slides shown by the main menu's Start (task T-387):
## opens the game with a fresh settings file (never the player's real save), presses Start, and
## leaves the slides on screen. `slide` (0 to 2) picks the slide to show.

@export var slide := 0

var game: Node


func _ready() -> void:
	GameSettings.path = "user://t387_screenshot_settings.cfg"
	DirAccess.remove_absolute(GameSettings.path)
	GameFlow.tutorial_enabled = true
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	game.tutorial.show_slide(slide)
