extends Node
## GIF fixture (task T-217): a run started from the main menu on the run's map
## (the elevation sample layout), the car driven by a script, for the README's
## three GIFs. The scene is chosen by the environment variable README_GIF:
##   street  the car drifting in weaving curves on the street, enemies chasing it
##   jump    the car drifting on the height-6 rooftop, off its east edge, landing below
##   kaiju   as street, with the kaiju brought in at once (60.5 seconds left)
## Record it with game/tools/record_readme_gif.sh, which runs it with --write-movie.
## The car's health is kept full so the run goes on; nothing else is changed.

var game: Node
var run: Node2D
var mode := "street"
var _steps := 0


func _ready() -> void:
	var m := OS.get_environment("README_GIF")
	if m != "":
		mode = m
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	run = game.run
	var car: CharacterBody2D = run.car
	car.use_keyboard = false
	car.detect_tricks = false
	var start := Vector2(-20, 0)
	var rot := 0.0
	if mode == "jump":
		start = Vector2(-41, -81)
		rot = 0.0
	car.model.set_position(start)
	car.model.rotation = rot
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = run.elevation.ground_height
	car.scripted_input = [true, false, 0.0]
	# A fixed camera, so the GIFs do not depend on the camera options saved on this machine.
	run.camera_follow.dynamic = false
	run.set_zoom({"street": 10.0, "jump": 13.0, "kaiju": 16.0}.get(mode, 14.4))
	if mode == "kaiju":
		run.state.time_left = 60.5
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()
	car.stepped.connect(_on_stepped)


func _process(_delta: float) -> void:
	if run != null and run.state != null:
		run.state.health = run.state.max_health


## The inputs for physics step n: [W, S, steer].
func inputs_at(n: int) -> Array:
	if mode == "jump":
		# Straight to build speed, a drift kick (W with D), then counter-steer and hold the drift to the edge.
		if n < 22:
			return [true, false, 0.0]
		if n < 34:
			return [true, false, 1.0]
		return [true, false, -0.7]
	# Weave: drift one way, then the other, W held all the time.
	if n < 25:
		return [true, false, 0.0]
	var phase := (n - 25) / 100
	return [true, false, 1.0 if phase % 2 == 0 else -1.0]


func _on_stepped() -> void:
	_steps += 1
	run.car.scripted_input = inputs_at(_steps)
	if _steps % 10 == 0:
		var car: CharacterBody2D = run.car
		print("readme_gif: step %d pos %s height %.2f airborne %s drifting %s minions %d kaiju %s" % [
			_steps, car.model.get_position().snapped(Vector2(0.1, 0.1)), car.height, car.airborne,
			car.model.is_drifting, run.minions.minions.size(), run.kaiju_boss.kaiju != null])
