extends Node
## GIF fixture (task T-222): the car cruises along the street in a gentle weave
## while coins lie ahead, 1.5 to 2.9 units to either side of its path, inside the
## magnet's reach; they are pulled to the car and collected. Record it with
## game/tools/record_readme_gif.sh's pattern (--write-movie). Health is kept full.

var game: Node
var run: Node2D
var _steps := 0


func _ready() -> void:
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	run = game.run
	run.minions.enabled = false
	var car: CharacterBody2D = run.car
	car.use_keyboard = false
	car.detect_tricks = false
	car.model.set_position(Vector2(-20, 0))
	car.model.rotation = 0.0
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = run.elevation.ground_height
	car.scripted_input = [true, false, 0.0]
	run.camera_follow.dynamic = false
	run.set_zoom(9.0)
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()
	car.stepped.connect(_on_stepped)


func _process(_delta: float) -> void:
	if run != null and run.state != null:
		run.state.health = run.state.max_health


func _on_stepped() -> void:
	_steps += 1
	run.car.scripted_input = [true, false, 0.0]
	# Every 12 steps a coin lies a little ahead, off to one side, alternating.
	if _steps % 12 == 0:
		var at: Vector2 = run.car.position / 16.0
		var side := 1.0 if (_steps / 12) % 2 == 0 else -1.0
		var ahead := 14.0 + 3.0 * (float((_steps / 12) % 3))
		run.minions.spawn_coin_at(at + Vector2(ahead, side * (1.8 + 0.5 * float((_steps / 12) % 3))), 1)
