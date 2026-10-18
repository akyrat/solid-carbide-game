extends Node
## Screenshot fixture (task T-175): a run started from the main menu with all
## five weapons owned (the all_weapons_at_start switch, forced on here), so the
## final underglow, molotov bottle, fire area and wiper art show in the world.
## Screenshot: bash game/tools/screenshot.sh res://tests/fixtures/weapons/weapon_art_demo.tscn screenshots/weapon_art.png 90

const WeaponsScript := preload("res://scripts/weapons/weapons.gd")


func _ready() -> void:
	WeaponsScript.all_weapons_override = 1
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	var run: Node2D = game.run
	run.minions.rng.seed = 42
	var mol = run.weapons.molotov
	mol.rng.seed = 7
	var c: Vector2 = run.car.model.get_position()
	for i in 10:
		run.minions.spawn_minion_at(c + Vector2.from_angle(TAU * i / 10.0) * 5.0)
	mol.throw_volley()
	mol.throw_volley()
	run.car.use_keyboard = false
	run.car.scripted_input = [false, false, 0.0]
	for i in 45:
		await get_tree().physics_frame
	mol.throw_volley()
	for i in 20:
		await get_tree().physics_frame
	run.car.use_keyboard = true
