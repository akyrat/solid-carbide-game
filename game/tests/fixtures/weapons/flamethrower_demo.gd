extends Node
## Screenshot fixture (task T-042): a run started from the main menu, the car
## drifting in a circle (W and A held) with the exhaust flamethrower, its
## placeholder flames behind the car, minions coming in.
## bash game/tools/screenshot.sh res://tests/fixtures/weapons/flamethrower_demo.tscn screenshots/flamethrower.png 90

func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	var run: Node2D = game.run
	run.minions.rng.seed = 42
	var flame = run.weapons.flamethrower
	if not flame.is_owned():  # whatever the playtest switch says
		run.weapons.upgrade("flamethrower")
	run.car.use_keyboard = false
	run.car.scripted_input = [true, false, 1.0]
	flame.enemy_hit.connect(func(e: Node, amount: float) -> void:
		print("T-042 demo: hit %s for %.1f" % [e.name, amount]))
	for i in 120:
		await get_tree().physics_frame
	print("T-042 demo: flame on=%s size=%.2f hits=%d" % [flame.active, flame.size_fraction(), flame.hits])
