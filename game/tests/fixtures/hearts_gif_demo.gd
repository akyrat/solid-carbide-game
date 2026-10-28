extends Node
## GIF fixture (task T-334): the car drives along the street into a swarm of
## minions waiting across it: the first one to touch it takes a heart, the car
## blinks for its 1 s of invulnerability, the others neither hit nor push it,
## and it drives out of the swarm. The HUD's health bar shows the hearts as a
## fraction (until T-338's heart row). Record it with record_hearts_gif.sh.
## No new minions spawn; the ones placed walk and hit as in a run. Once the car
## is down to 1 heart it is topped up, so the recording never ends the run.

var game: Node
var run: Node2D


func _ready() -> void:
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	run = game.run
	run.minions.enabled = false  # only the swarm below, stepped by hand
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
	# The swarm: a loose block of minions across the street ahead.
	for i in 9:
		var at := Vector2(-9.0 + 1.4 * float(i % 3), -1.6 + 1.6 * float(i / 3))
		var m: Node = run.minions.spawn_minion_at(at)
		m.max_health = 1000000.0
		m.health = m.max_health
	car.stepped.connect(_on_stepped)


func _on_stepped() -> void:
	run.car.scripted_input = [true, false, 0.0]
	run.minions.move_step(run.car.model.dt)
	run.minions.update_drawing()
	if run.state.health <= 1.0:
		run.state.health = run.state.max_health
