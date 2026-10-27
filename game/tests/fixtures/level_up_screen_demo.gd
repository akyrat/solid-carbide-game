extends Node
## Test fixture for a screenshot of the level-up screen (task T-052): opens the
## game, presses Start, then levels the car up so the run pauses and the screen
## shows the first level-up's two cards (the gun's upgrade and the flamethrower,
## each with its weapon image since T-173).
## T-173: with `offer_ids` set, the screen shows those cards instead, so the new
## weapons' cards and images can be shot too (screenshot only; nothing is taken).

@export var offer_ids: Array[String] = []
## T-303: after the build-up, move the highlight this many cards to the right,
## so the highlight frame can be shot on the second card too.
@export var highlight_moves: int = 0


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var state: RunState = game.run.state
	state.add_xp(state.xp_needed())
	game.run.gift_drops.pick_up_all()  # T-144: the screen opens when the package is picked up
	if not offer_ids.is_empty():
		game.run.level_up_screen.show_offers(offer_ids)
	if highlight_moves != 0:
		var screen: Node = game.run.level_up_screen
		screen.skip_animation()
		screen.move_highlight(highlight_moves)
