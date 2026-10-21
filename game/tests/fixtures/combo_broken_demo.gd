extends Node
## Screenshot and GIF fixture for the combo broken popup (task T-245): a run
## started from the main menu, a combo built from two tricks, then a crash
## after CRASH_FRAME frames. The popups show over the car as in a real run.

const CRASH_FRAME := 10


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var state: RunState = game.run.state
	for _i in CRASH_FRAME:
		await get_tree().process_frame
	state.add_trick("alternate_drift")
	state.add_trick("three_sixty")
	for _i in 3:
		await get_tree().process_frame
	state.collision()
