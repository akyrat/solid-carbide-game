extends Node
## Screenshot and play fixture (task T-170): a run started from the main menu
## with the windshield wiper given (rack.upgrade("wiper")), minions in front of
## the car being hit and pushed away by the placeholder blade.
## Screenshot: bash game/tools/screenshot.sh res://tests/fixtures/weapons/wiper_demo.tscn screenshots/wiper.png 60
## To play it yourself: open this scene in the editor and press F6; the
## keyboard drives the car once the scripted part is over (2 seconds).

func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	var run: Node2D = game.run
	run.minions.rng.seed = 42
	var wiper = run.weapons.wiper
	if not wiper.is_owned():  # whatever the playtest switch says
		run.weapons.upgrade("wiper")
	wiper.enemy_hit.connect(func(e: Node, amount: float, pushed: bool) -> void:
		print("T-170 demo: hit %s for %.2f, pushed %s" % [e.name, amount, pushed]))
	# Minions spread across the semicircle in front of the car.
	for deg in [-60.0, -20.0, 20.0, 60.0]:
		run.minions.spawn_minion_at(wiper.pivot_units() + wiper.forward().rotated(deg_to_rad(deg)) * 2.0)
	run.car.use_keyboard = false
	run.car.scripted_input = [false, false, 0.0]
	for i in 100:
		await get_tree().physics_frame
	print("T-170 demo: wiper tier=%d length=%.2f hits=%d" % [wiper.tier, wiper.length(), wiper.hits])
	run.car.use_keyboard = true
