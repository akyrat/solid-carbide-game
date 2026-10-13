extends Node
## Screenshot fixture for the HUD with no combo (task T-116): a run started
## from the main menu with some damage, likes and coins but no trick, so the
## combo is at "no combo" and its counter is hidden.


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
