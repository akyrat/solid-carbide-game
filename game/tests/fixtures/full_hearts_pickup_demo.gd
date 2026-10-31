extends Node
## Fixture for the screenshot of task T-415: at full hearts the car sits on a health pickup and
## it stays (no pull, no pickup).


func _ready() -> void:
	var run: Node2D = preload("res://scenes/run/run.tscn").instantiate()
	add_child(run)
	await get_tree().process_frame
	run.minions.enabled = false
	run.car.use_keyboard = false
	run.car.scripted_input = [false, false, 0.0]
	var at: Vector2 = run.car.position / 16.0
	run.minions.spawn_health_pickup_at(at + Vector2(-1.5, 0.0))
	run.minions.spawn_health_pickup_at(at + Vector2(0.0, 2.0))
