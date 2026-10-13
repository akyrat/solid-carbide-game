extends Node
## Screenshot fixture for T-125: the run with the car in a fast drift, two
## popups (a 360 and a long drift) shown at frame 10. Take two screenshots a
## few frames apart: the popups stay above the moving car.

var run: Node2D
var frame := 0


func _ready() -> void:
	run = preload("res://scenes/run/run.tscn").instantiate()
	add_child(run)
	run.car.use_keyboard = false
	run.car.scripted_input = [true, false, 1.0]


func _process(_dt: float) -> void:
	frame += 1
	# T-125 rounds 2 and 3 (up to 3 stacked): a long drift (a LONG DRIFT! every 12 frames) with a 360 at the start.
	if frame == 10:
		run.car.trick.emit("three_sixty")
	if frame >= 10 and (frame - 10) % 12 == 0:
		run.car.trick.emit("extended_drift")
