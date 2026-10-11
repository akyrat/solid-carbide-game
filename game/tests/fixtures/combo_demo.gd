extends Node
## Screenshot fixture for the combo counter and the trick popups with the
## amount (task T-083): a run started from the main menu, a combo going, and
## one popup per trick.


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var run: Node2D = game.run
	for id in ["alternate_drift", "three_sixty", "alternate_drift"]:
		run.state.add_trick(id)
	var at: Vector2 = run.car_sprite.position
	var tp: Node2D = run.trick_popups
	for old in tp.popups():
		old.queue_free()
	await get_tree().process_frame
	run.car.trick.emit("extended_drift")
	run.car.trick.emit("three_sixty")
	run.car.trick.emit("alternate_drift")
	var offsets := [Vector2(0, 0), Vector2(-190, 90), Vector2(190, 90)]
	var i := 0
	for p in tp.popups():
		p.start = at + Vector2(0, -50) + offsets[i]
		i += 1
		p.advance(0.3)
		p.set_process(false)
