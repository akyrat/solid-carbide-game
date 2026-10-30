extends Node
## Fixture for the revive's GIF (task T-406): a run from the main menu, the car
## driven at speed, its last heart taken, and a health pickup lying just ahead of
## its slide. The wrecked car picks it up and drives again with 1 heart.
## game/tools/record_revive.sh records it.

const DRIVE_SECONDS := 1.5


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	var run: Node = game.run
	run.car.use_keyboard = false
	run.car.scripted_input = [true, false, 0.0]
	await get_tree().create_timer(DRIVE_SECONDS).timeout
	run.state.damage_car(run.state.max_health)
	var ahead: Vector2 = run.car.model.get_velocity().normalized()
	var at: Vector2 = run.car.position / 16.0
	run.minions.spawn_health_pickup_at(at + ahead * 6.0)
	await get_tree().create_timer(1.2).timeout
	run.car.scripted_input = [true, false, 0.0]  # the revived car answers the keys again
