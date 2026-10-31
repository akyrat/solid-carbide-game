extends Node
## Test fixture for screenshots of the driving power-up overlay (task T-459): opens the
## game, starts a run, then completes the first mission so the run pauses and the overlay
## shows its two cards, built up. With `owned` set, the car owns those power-ups at those
## tiers first, so the cards show next tiers. With `weapons_gift` on it shows the weapons
## gift (level-up) screen instead, for the side-by-side shot.

@export var owned: Dictionary = {}
@export var rng_seed: int = 3
@export var weapons_gift: bool = false
@export var highlight_moves: int = 0


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.start_run()  # straight into a run, without the tutorial slides
	await get_tree().process_frame
	await get_tree().process_frame
	var run: Node = game.run
	var state: RunState = run.state
	if weapons_gift:
		run.weapons.offers.rng.seed = rng_seed
		state.add_xp(state.xp_needed())
		run.gift_drops.pick_up_all()
		run.level_up_screen.skip_animation()
		return
	for id in owned:
		for t in int(owned[id]):
			state.grant_power_up(id)
	run.power_up_offers.rng.seed = rng_seed
	state.missions.mission_completed.emit(0)
	run.power_up_screen.skip_animation()
	run.power_up_screen.move_highlight(highlight_moves)
