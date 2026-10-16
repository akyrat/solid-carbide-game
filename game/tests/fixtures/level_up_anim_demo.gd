extends Node
## Test fixture (task T-141): opens the level-up screen and holds its build-up at
## a chosen moment, for a screenshot sequence. The moment (seconds) comes from
## the user argument --at=<seconds>; without it the finished screen shows.


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var state: RunState = game.run.state
	state.add_xp(state.xp_needed())
	game.run.gift_drops.pick_up_all()
	var screen: LevelUpScreen = game.run.level_up_screen
	var at := 99.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--at="):
			at = float(a.substr(5))
	screen.set_process(false)
	var t := 0.0
	while t < at and screen.is_animating():
		screen.advance(0.01)
		t += 0.01
