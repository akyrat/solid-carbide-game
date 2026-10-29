extends Node
## Fixture for the time's up screen's screenshot and GIF (task T-317): a run
## from the main menu, the car driving with minions around it, the clock set to
## 0:01 so it runs out at about 2 s. The run freezes at 0:00 while the time's
## up screen plays for its 3 seconds, then the game goes back to the main menu.
## game/tools/record_time_up.sh records it.

## Seconds of driving before the clock is set to its last second.
const DRIVE_SECONDS := 1.0


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	var run: Node = game.run
	run.car.use_keyboard = false
	run.car.scripted_input = [true, false, 0.3]
	var at: Vector2 = run.car.position / 16.0
	for i in 8:
		run.minions.spawn_minion_at(at + Vector2.from_angle(TAU * i / 8.0) * 10.0)
	await get_tree().create_timer(DRIVE_SECONDS).timeout
	run.state.time_left = 1.0  # 0:01: runs out 1 s later, at about 2 s
