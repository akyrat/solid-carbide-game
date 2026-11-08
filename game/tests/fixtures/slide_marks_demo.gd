extends Node
## Screenshot fixture for the slide marks (task T-600): the run scene with the car driven
## by script: W, then W + D (a drift), then no keys (a slide), then W for a moment. Take it
## with about 190 frames for the drift into the slide, with both kinds of marks.

const DRIFT_STEPS := 40
const SLIDE_STEPS := 45


func _ready() -> void:
	var run: Node2D = preload("res://scenes/run/run.tscn").instantiate()
	add_child(run)
	var car: CharacterBody2D = run.car
	car.use_keyboard = false
	car.scripted_input = [true, false, 0.0]
	for i in 10:
		await get_tree().physics_frame
	car.scripted_input = [true, false, -1.0]
	for i in DRIFT_STEPS:
		await get_tree().physics_frame
	car.scripted_input = [false, false, 0.0]
	for i in SLIDE_STEPS:
		await get_tree().physics_frame
	car.scripted_input = [true, false, 0.0]
