extends Node
## Screenshot fixture (task T-206): a run started from the main menu
## (game.tscn, Start) on the elevation sample map's layout, with the car put
## at a chosen spot (on the street, on a rooftop, in the air) and driven with
## W held for drive_steps physics steps, then stopped, so the screenshot shows
## that moment with the run going on around it (enemies, weapons, HUD).

## Where the car starts, flat units, and its heading (0 east, PI / 2 south).
@export var start_units := Vector2(-81, -50)
@export var start_rotation := -PI / 2.0
## Physics steps with W held (or standing, hold_w false) before the car stops.
@export var drive_steps := 5
@export var hold_w := true
## Camera zoom (orthographic size); 0 keeps the run's.
@export var zoom := 0.0
## Units above the ground at the start: the car is put in the air that high.
@export var lift_units := 0.0
## Seconds left on the clock at the start (0 keeps 8:00); 60.5 brings the kaiju at once.
@export var time_left := 0.0
## Keeps the car's health full, so the run never ends while the shot is taken.
@export var keep_health := true

var game: Node
var run: Node2D
var _steps := 0


func _ready() -> void:
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	run = game.run
	var car: CharacterBody2D = run.car
	car.use_keyboard = false
	car.detect_tricks = false
	car.model.set_position(start_units)
	car.model.rotation = start_rotation
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = run.elevation.ground_height  # back on the ground there
	car.scripted_input = [hold_w, false, 0.0]
	if lift_units > 0.0:
		car.height_model.height = car.height + lift_units
		car.height_model.airborne = true
		car.scripted_input = [false, false, 0.0]
	if zoom > 0.0:
		run.camera_follow.dynamic = false
		run.set_zoom(zoom)
	if time_left > 0.0:
		run.state.time_left = time_left
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()
	car.stepped.connect(_on_stepped)


func _process(_delta: float) -> void:
	if keep_health and run != null and run.state != null:
		run.state.health = run.state.max_health


func _on_stepped() -> void:
	_steps += 1
	if _steps == drive_steps:
		run.car.scripted_input = [false, false, 0.0]
		run.car.set_physics_process(false)
		var units: Vector2 = run.car.model.get_position()
		print("run_elevation_demo: stopped at %s, height %.2f, ground %.2f, minions %d, kaiju %s" % [
			units, run.car.height, run.elevation.ground_height.height_at(units),
			run.minions.minions.size(), run.kaiju_boss.kaiju != null])
