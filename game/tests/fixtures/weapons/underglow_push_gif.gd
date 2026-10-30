extends Node
## Recording fixture (task T-409): the neon underglow in a swarm. A run from the
## main menu with the underglow at tier 1 (gun off), the car standing still and a
## ring of minions walking in: each dies on its second tick and is nudged back on
## every tick. Not part of the test suite.
##   bash game/tools/record_underglow_push_gif.sh <out.gif>

func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	var run: Node2D = game.run
	run.minions.rng.seed = 7
	run.minions.spawn_multiplier = 0.0
	run.weapons.gun.set_tier(0)
	run.weapons.upgrade("underglow")
	var c: Vector2 = run.car.model.get_position()
	for i in 14:
		var a := TAU * float(i) / 14.0
		run.minions.spawn_minion_at(c + Vector2(cos(a), sin(a)) * (5.0 + 1.5 * float(i % 3)))
	run.car.use_keyboard = false
	run.car.scripted_input = [false, false, 0.0]
