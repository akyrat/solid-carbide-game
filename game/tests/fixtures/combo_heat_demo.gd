extends Node
## Screenshot fixture for the combo's heat steps (task T-131): a run started
## from the main menu with some damage, likes and coins, then `tricks`
## alternate drifts (+0.5 each) so the combo sits at one heat step. The four
## scenes combo_heat_base.tscn (x1.5), combo_heat_step1.tscn (x2.0),
## combo_heat_step2.tscn (x3.0) and combo_heat_step3.tscn (x4.5) show the four
## looks; game/tools/combo_heat_shots.sh takes all four and puts them side by side.

## How many alternate drifts to chain.
@export var tricks := 1


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var state: RunState = game.run.state
	# Damage first: a hit cuts the combo.
	state.damage_car(state.max_health * 0.3)
	state.add_xp(state.xp_needed() * 0.6)
	state.add_coins(37)
	for i in tricks:
		state.add_trick("alternate_drift")
