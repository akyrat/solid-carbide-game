extends Node
## Screenshot fixture for T-523: a run from the main menu with `weapon_n` weapons (1 to 3)
## and `power_n` driving power-ups (0 to 3) in the HUD's slot grids.

@export var weapon_n := 1
@export var power_n := 0


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.start_run()
	await get_tree().process_frame
	await get_tree().process_frame
	var rack: Node = game.run.weapons
	var ids := ["wiper", "flamethrower"]
	for i in weapon_n - 1:
		rack.get_weapon(ids[i]).set_tier(1 + i)
	rack.gun.set_tier(2)
	var pu := ["jump", "rev_charge", "bouncy_bumpers"]
	for i in power_n:
		game.run.state.grant_power_up(pu[i])
		if i == 0:
			game.run.state.grant_power_up(pu[i])
