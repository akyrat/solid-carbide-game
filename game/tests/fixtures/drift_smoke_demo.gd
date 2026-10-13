extends Node
## Screenshot fixture for the drift smoke (task T-121): a run started from the
## main menu with the car driven by script. mode "drift": W for a moment, then
## W + D, so the car drifts in a circle and smoke puffs off its rear tyres.
## mode "straight": W only, so no smoke. Take it with about 150 frames.

@export var mode := "drift"
## Where the car starts, in units (T-073: (54, 0) is on the asphalt road east
## of the centre; the default, the run's own start, is on the gravel).
@export var start_units := Vector2.ZERO
## Physics steps of W alone before the drift starts.
const STRAIGHT_STEPS := 15


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	var car: CharacterBody2D = game.run.car
	car.use_keyboard = false
	if start_units != Vector2.ZERO:
		car.model.set_position(start_units)
		car.position = start_units * car.PX_PER_UNIT
	car.scripted_input = [true, false, 0.0]
	if mode != "drift":
		return
	for i in STRAIGHT_STEPS:
		await get_tree().physics_frame
	car.scripted_input = [true, false, -1.0]
