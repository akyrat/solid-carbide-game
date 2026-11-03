extends Node
## Screenshot fixture for T-521 (screenshots only). `kind`: "kaiju" (the kaiju arrives at 3:00),
## "levelup" (a level-up with 3 weapons owned: upgrades only), "heal" (every owned weapon at its
## last tier: the full sub goal heals the car and shows the heal message).

@export var kind := "kaiju"


func _ready() -> void:
	var run: Node2D = preload("res://scenes/run/run.tscn").instantiate()
	add_child(run)
	run.minions.enabled = false
	await get_tree().process_frame
	var rack: Node = run.weapons
	var state: RunState = run.state
	if kind != "newweapon":
		rack.pick("flamethrower")
		rack.pick("underglow")
	match kind:
		"newweapon":
			# A gift pack offering a weapon the car does not own: it arrives at tier 2.
			rack.pick("flamethrower")
			state.add_xp(state.xp_needed())
			run.gift_drops.pick_up_all()
			run.level_up_screen.show_offers(["get_underglow", "upgrade_flamethrower"])
			run.level_up_screen.skip_animation()
		"slots":
			rack.pick("flamethrower")
			rack.pick("flamethrower")
			state.grant_power_up("jump")
			state.grant_power_up("jump")
			state.grant_power_up("rev_charge")
			for i in 30:
				await get_tree().process_frame
		"kaiju":
			state.advance(RunState.RUN_SECONDS - RunState.BOSS_TIME_LEFT - state.time_elapsed() + 0.01)
			for i in 90:
				await get_tree().physics_frame
		"levelup":
			rack.pick("flamethrower")
			state.add_xp(state.xp_needed())
			run.gift_drops.pick_up_all()
			run.level_up_screen.skip_animation()
		"heal":
			for id in ["gun", "flamethrower", "underglow"]:
				while not rack.get_weapon(id).is_max_tier():
					rack.pick(id)
			state.damage_car(3.0)
			await get_tree().process_frame
			state.add_xp(state.xp_needed())
			for i in 20:
				await get_tree().process_frame
