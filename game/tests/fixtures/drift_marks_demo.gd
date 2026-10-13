extends Node
## Screenshot fixture for the drift marks (task T-117): a run started from the
## main menu with the car driven by script. mode "drift": W for a moment, then
## W + D, so the car drifts in a circle and its rear tyres leave marks.
## mode "straight": W only, so nothing is laid. Take it with about 150 frames.

@export var mode := "drift"
## Physics steps of W alone before the drift starts.
const STRAIGHT_STEPS := 15


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	var car: CharacterBody2D = game.run.car
	car.use_keyboard = false
	car.scripted_input = [true, false, 0.0]
	if mode != "drift":
		return
	for i in STRAIGHT_STEPS:
		await get_tree().physics_frame
	car.scripted_input = [true, false, -1.0]
