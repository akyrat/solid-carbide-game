extends Node
## Screenshot/GIF fixture (task T-515): the car drives east with the Jump's tier 1 and hops over a
## minion standing still in its way: no hit while it is above 0.5 units. Record it with
## record_jump_minion_gif.sh. The minion stands still (no movement) and the car's health is topped up.

var run: Node2D
var _jumped := false
var _minion: Node


func _ready() -> void:
	run = preload("res://scenes/run/run.tscn").instantiate()
	add_child(run)
	await get_tree().process_frame
	run.minions.enabled = false
	var car: CharacterBody2D = run.car
	car.use_keyboard = false
	car.detect_tricks = false
	car.jump.set_tier(1)
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
	_minion = run.minions.spawn_minion_at(Vector2(-8, 0))
	car.stepped.connect(_on_stepped)


func _on_stepped() -> void:
	var car: CharacterBody2D = run.car
	car.model.rotation = 0.0
	car.scripted_input = [true, false, 0.0]
	if not _jumped and _minion.position_units().x - car.model.x < 3.5:
		car.press_jump()
		_jumped = true
	run.state.health = run.state.max_health
	run.minions.update_drawing()
