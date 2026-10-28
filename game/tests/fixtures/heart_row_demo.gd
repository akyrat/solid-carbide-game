extends Node
## Fixture for the hearts row's screenshots (task T-338): a run from the main menu.
## HEART_MODE picks what it shows: full (the start), hit (two hearts lost),
## garage (a garage heart bought: one more heart).

var _mode := "full"


func _ready() -> void:
	var m := OS.get_environment("HEART_MODE")
	if m != "":
		_mode = m
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	if _mode == "garage":
		game.progress.levels["car_health"] = 1
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	if _mode == "hit":
		game.run.state.damage_car(2.0)
		game.run.hud.heart_row.advance(1.0)
	elif _mode == "garage":
		game.run.state.damage_car(1.0)
		game.run.hud.heart_row.advance(1.0)
