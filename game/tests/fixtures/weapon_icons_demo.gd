extends Node
## Test fixture for screenshots of the HUD's top left (T-276): a run from the
## main menu with the gun only, or with all five weapons at mixed tiers
## (the scene's `mixed` flag).

@export var mixed := false


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var state: RunState = game.run.state
	state.damage_car(state.max_health * 0.3)
	if mixed:
		var rack: Node = game.run.weapons
		var order := ["wiper", "flamethrower", "molotov", "underglow"]
		var tiers := [3, 1, 8, 2]
		for i in order.size():
			rack.get_weapon(order[i]).set_tier(tiers[i])
		rack.gun.set_tier(2)
