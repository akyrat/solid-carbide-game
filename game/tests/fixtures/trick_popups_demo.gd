extends Node
## Screenshot fixture for the trick popups (tasks T-091, T-083, T-084): the run
## with every popup of the comic look, shown around the car: the three tricks
## with their amounts (extended drift small) and the challenge popup.

func _ready() -> void:
	var run: Node2D = preload("res://scenes/run/run.tscn").instantiate()
	add_child(run)
	var tp: Node2D = run.trick_popups
	var at: Vector2 = run.car_sprite.position
	tp.show_popup("LONG DRIFT! +0.05", at + Vector2(0, 60), tp.SIZE_SMALL)
	tp.show_popup("FULL 360! +0.25", at + Vector2(-190, 140))
	tp.show_popup("ALT DRIFT! +0.5", at + Vector2(190, 140))
	tp.show_popup("Trending! +120 Likes", at + Vector2(0, 220))
	for p in tp.popups():
		p.advance(0.3)
		p.set_process(false)
