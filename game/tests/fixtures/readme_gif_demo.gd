extends Node
## GIF fixture (tasks T-217 and T-229): a run started from the main menu on the
## run's map (the elevation sample layout), the car driven by a script, for the
## README's GIFs. The scene is chosen by the environment variable README_GIF:
##   street  the car on the asphalt street: a straight run, a long drift, then straight
##           again, enemies chasing it; the drift counter counts and LONG DRIFT! pays at its end
##   jump    the car drifting along the height-6 rooftop and off its east edge, landing in
##           the street below: the camera follows its height (T-228)
##   trick   the car off the rooftop with the drift keys held in the air: an air 360,
##           the airtime counter counting, HANG TIME! on landing
##   kaiju   the car weaving on the gravel with the kaiju brought in at once (60.5 seconds left)
##   drop    the car parked on the street below a rooftop's edge, minions walking after it off
##           the edge and falling (T-207, T-226)
##   magnet  the car cruising the gravel while coins and health canisters lie beside its path
## Record it with game/tools/record_readme_gif.sh, which runs it with --write-movie.
## The car's health is kept full so the run goes on; nothing else is changed.

var game: Node
var run: Node2D
var mode := "street"
var _steps := 0
var _was_airborne := false


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
	car.detect_tricks = mode in ["street", "trick"]
	var start := Vector2(-20, 0)
	var rot := 0.0
	match mode:
		"magnet":
			start = Vector2(-34, 0)
		"drop":
			start = Vector2(-45, -59)
		"street":
			start = Vector2(-30, -54)
		"trick":
			start = Vector2(-27, -80)
			rot = PI / 2.0
		"jump":
			start = Vector2(-41, -81)
	car.model.set_position(start)
	car.model.rotation = rot
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = run.elevation.ground_height
	car.scripted_input = [true, false, 0.0]
	# A fixed camera, so the GIFs do not depend on the camera options saved on this machine.
	run.camera_follow.dynamic = false
	run.set_zoom({"street": 10.5, "jump": 13.0, "trick": 11.0, "kaiju": 20.0, "magnet": 9.0, "drop": 9.5}.get(mode, 14.4))
	if mode == "kaiju":
		run.state.time_left = 60.5
	if mode == "street":
		# A chase that reads at once: minions all round the car, a little way off.
		for p in [Vector2(-50, -50), Vector2(-48, -58), Vector2(-56, -54), Vector2(-44, -62), Vector2(-52, -46),
				Vector2(-40, -48), Vector2(-58, -60), Vector2(-46, -54)]:
			run.minions.spawn_minion_at(p)
	if mode == "magnet":
		run.minions.enabled = false
	if mode == "drop":
		# The minions walk off the height-3 rooftop north of the street (the spawner steps them in
		# _on_stepped), with a huge health so the car's weapons do not clear them before they fall.
		car.scripted_input = [false, false, 0.0]
		car.set_physics_process(false)
		run.minions.enabled = false
		run.minions.clear()
		for p in [Vector2(-52, -73), Vector2(-45, -76), Vector2(-38, -72), Vector2(-48, -80), Vector2(-41, -79),
				Vector2(-55, -77), Vector2(-34, -76)]:
			var minion = run.minions.spawn_minion_at(p)
			minion.max_health = 1000000.0
			minion.health = minion.max_health
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()
	_was_airborne = car.airborne
	car.stepped.connect(_on_stepped)


func _process(_delta: float) -> void:
	if run != null and run.state != null:
		# The magnet GIF keeps the car at half health, so the canisters are pulled in too.
		run.state.health = run.state.max_health * (0.5 if mode == "magnet" else 1.0)


func _physics_process(delta: float) -> void:
	# The parked car does not step, so the spawner is stepped here (as T-226's drop fixture does).
	if mode == "drop" and run != null:
		run.minions.move_step(delta)
		run.minions.update_drawing()


## The inputs for physics step n (street, kaiju): [W, S, steer].
func inputs_at(n: int) -> Array:
	if mode == "street":
		# Straight to build speed, one long drift, then straight again.
		if n < 40:
			return [true, false, 0.0]
		if n < 190:
			return [true, false, 1.0]
		return [true, false, 0.0]
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
	var car: CharacterBody2D = run.car
	match mode:
		"trick":
			_drive_trick()
		"magnet":
			_drive_magnet()
		_:
			car.scripted_input = inputs_at(_steps)
	_was_airborne = car.airborne
	if _steps % 10 == 0:
		print("readme_gif: step %d pos %s height %.2f airborne %s drifting %s minions %d kaiju %s" % [
			_steps, car.model.get_position().snapped(Vector2(0.1, 0.1)), car.height, car.airborne,
			car.model.is_drifting, run.minions.minions.size(), run.kaiju_boss.kaiju != null])


## Off the rooftop's side with W held; in the air W with D too (an air 360); after landing W only.
func _drive_trick() -> void:
	var car: CharacterBody2D = run.car
	if car.airborne:
		car.scripted_input = [true, false, 1.0]
	else:
		car.scripted_input = [true, false, 0.0]


## Straight along the gravel; every few steps a coin lies ahead to one side,
## and a health canister now and then (the health is kept full, the canister still shows).
func _drive_magnet() -> void:
	run.car.scripted_input = [true, false, 0.0]
	if _steps % 12 == 0:
		var at: Vector2 = run.car.position / 16.0
		var k := _steps / 12
		var side := 1.0 if k % 2 == 0 else -1.0
		var ahead := 14.0 + 3.0 * float(k % 3)
		var spot := at + Vector2(ahead, side * (1.8 + 0.5 * float(k % 3)))
		if k % 5 == 3:
			run.minions.spawn_health_pickup_at(spot)
		else:
			run.minions.spawn_coin_at(spot, 1)
