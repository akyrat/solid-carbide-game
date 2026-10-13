extends Node
## Test fixture for a screenshot of the HUD in a run started from the main
## menu (task T-049): opens the game, presses Start, then gives the run some
## damage, likes, coins and a combo so every part of the HUD shows a value
## (since T-113 the health bar stands upright at the top left and the likes bar
## lies across the bottom centre).


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var state: RunState = game.run.state
	state.damage_car(state.max_health * 0.3)
	state.add_xp(state.xp_needed() * 1.4)
	state.add_coins(37)
	state.add_trick("alternate_drift")
	state.add_trick("three_sixty")
