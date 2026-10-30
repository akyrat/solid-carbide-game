extends Node
## Screenshot fixture for T-428 (the HUD reads its look from HudStyle): a run
## started from the game scene (past the tutorial slides, as pause_from_menu_demo),
## with damage, subs, coins, a combo and the gun at tier 3, so the hearts, the
## weapon icon and its count, the coins, the clock, the sub goal and its label
## and the live viewers counter all show a value. `mode` "level_up"
## (t428_level_up_demo.tscn) opens the level-up screen with two cards instead,
## as level_up_from_menu_demo did before the tutorial slides came first.

@export var mode := "hud"
var game: Node


func _ready() -> void:
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.start_run()  # the menu's Start opens the tutorial slides first (T-389)
	await get_tree().process_frame
	await get_tree().process_frame
	var state: RunState = game.run.state
	if mode == "level_up":
		state.add_xp(state.xp_needed())
		game.run.gift_drops.pick_up_all()
		var screen: Node = game.run.level_up_screen
		screen.show_offers(["upgrade_gun", "get_wiper"])
		screen.skip_animation()
		return
	state.damage_car(state.max_health * 0.3)
	state.add_xp(state.xp_needed() * 0.6)
	state.add_coins(37)
	state.add_trick("alternate_drift")
	state.add_trick("three_sixty")
	game.run.weapons.get_weapon("gun").set_tier(3)
