extends Node
## Fixture for T-413's screenshots (the wreck decides the loss at its end): a run
## from the main menu, the car driven at speed, its last heart taken with coins
## lying beside its slide. The wrecked car pulls the coins in and the HUD's coin
## count rises; then the kaiju is killed during the wreck and the win recap shows.
## game/tools/record_wreck_decides.sh records it.

const DRIVE_SECONDS := 1.5


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.start_run()  # straight into a run, past the tutorial slides
	await get_tree().process_frame
	var run: Node = game.run
	run.minions.enabled = false  # only the coins placed here
	run.car.use_keyboard = false
	run.car.scripted_input = [true, false, 0.0]
	await get_tree().create_timer(DRIVE_SECONDS).timeout
	run.state.damage_car(run.state.max_health)
	var ahead: Vector2 = run.car.model.get_velocity().normalized()
	var side := Vector2(-ahead.y, ahead.x)
	var at: Vector2 = run.car.position / 16.0
	for i in 6:
		run.minions.spawn_coin_at(at + ahead * (2.0 + i) + side * (1.5 if i % 2 == 0 else -1.5), 5)
	await get_tree().create_timer(1.8).timeout
	run.state.kaiju_killed()  # during the wreck: a win
