extends Node
## Test fixture (task T-052, board's note: later level-ups needed a window resize):
## opens the game, presses Start, takes the first and second level-up's card,
## then levels up a third time and stays on that screen for a screenshot.


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var state: RunState = game.run.state
	for i in 2:
		state.add_xp(state.xp_needed())
		game.run.gift_drops.pick_up_all()  # T-144: the package opens the screen
		for f in 4:
			await get_tree().process_frame
		game.run.level_up_screen.take_highlighted()
		for f in 4:
			await get_tree().process_frame
	state.add_xp(state.xp_needed())
	game.run.gift_drops.pick_up_all()
