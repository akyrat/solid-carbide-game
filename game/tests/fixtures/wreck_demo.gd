extends Node
## Fixture for the wreck's screenshot and GIF (task T-360): a run from the main
## menu, the car driven at speed into a drift, then its last heart taken. The
## car slides on with dead controls, smoking and burning, for the wreck's 3
## seconds while the minions swarm it, and the game goes back to the main menu.
## game/tools/record_wreck.sh records it.

## Seconds of driving before the last heart goes.
const DRIVE_SECONDS := 1.5


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	var run: Node = game.run
	run.car.use_keyboard = false
	run.car.scripted_input = [true, false, 0.0]
	await get_tree().create_timer(DRIVE_SECONDS * 0.6).timeout
	run.car.scripted_input = [true, false, 0.7]  # into a drift, so it slides
	await get_tree().create_timer(DRIVE_SECONDS * 0.4).timeout
	# A ring of minions just off the car (the quick tuning, 2026-10-29: they keep
	# coming and swarm the wreck, with no interaction).
	var at: Vector2 = run.car.position / 16.0
	for i in 10:
		run.minions.spawn_minion_at(at + Vector2.from_angle(TAU * i / 10.0) * 9.0)
	run.state.damage_car(run.state.max_health)
	# The fixture keeps "pressing": the dead controls ignore it.
