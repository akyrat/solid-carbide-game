extends Node
## Screenshot fixture for the trick popups (task T-091): the run with one popup
## per trick, shown above the car.

func _ready() -> void:
	var run: Node2D = preload("res://scenes/run/run.tscn").instantiate()
	add_child(run)
	run.car.trick.emit("extended_drift")
	var tp: Node2D = run.trick_popups
	var at: Vector2 = run.car_sprite.position
	tp.show_popup("FULL 360!", at + Vector2(-150, 100))
	tp.show_popup("ALT DRIFT!", at + Vector2(150, 100))
	for p in tp.popups():
		p.advance(0.3)
		p.set_process(false)
