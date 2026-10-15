extends Node
## Screenshot fixture for the boost effect (task T-008): a run started from the
## main menu, the car standing still, then W is pressed. Take it with about 8
## frames (the effect lasts about a third of a second).

func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	var car: CharacterBody2D = game.run.car
	car.use_keyboard = false
	car.scripted_input = [true, false, 0.0]
