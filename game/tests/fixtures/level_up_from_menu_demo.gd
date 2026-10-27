extends Node
## Test fixture for a screenshot of the open level-up screen in a run started from the main
## menu (task T-309): opens the game, presses Start, gives the likes for one level, picks up
## the gift pack, then waits until the opening animation has finished and both cards are in.
## Check the shot with game/tools/check_level_up_shot.py.

const MAX_WAIT_FRAMES := 600


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var state: RunState = game.run.state
	state.add_xp(state.xp_needed())
	game.run.gift_drops.pick_up_all()
	var screen: Node = game.run.level_up_screen
	# Today's pool offers one card at this level; show two, as the screen is built for.
	screen.show_offers(["upgrade_gun", "get_wiper"])
	var waited := 0
	while screen.is_animating() and waited < MAX_WAIT_FRAMES:
		await get_tree().process_frame
		waited += 1
	# One more frame so the finished layout is drawn before the shot.
	await get_tree().process_frame
