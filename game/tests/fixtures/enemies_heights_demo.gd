extends Node
## Screenshot fixture (task T-207): a run started from the main menu on the
## elevation map, the car parked at `car_units`, minions put at
## `minion_spots` (and the kaiju at `kaiju_spot`, if set) and walked for
## `walk_seconds` towards the car by the run's own spawner (paths up and down
## the ramps), then everything stands still for the screenshot:
## bash game/tools/screenshot.sh res://tests/fixtures/enemies_heights_ramp.tscn screenshots/x.png 20
## The minions and the kaiju get a huge health so the car's weapons do not
## kill them before the picture (the fixture's own change, not the data's).

@export var car_units := Vector2(-81, -75)
@export var car_rotation := -PI / 2.0
@export var minion_spots: Array[Vector2] = []
@export var kaiju_spot := Vector2.INF
@export var walk_seconds := 3.0
## The camera's orthographic size (units).
@export var zoom := 14.0

const DT := 0.02

var game: Node
var run: Node2D


func _ready() -> void:
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	run = game.run
	var car = run.car
	car.use_keyboard = false
	car.detect_tricks = false
	car.model.set_position(car_units)
	car.model.rotation = car_rotation
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = run.elevation.ground_height
	car.scripted_input = [false, false, 0.0]
	car.set_physics_process(false)
	run.camera_follow.dynamic = false
	run.set_zoom(zoom)
	var spawner = run.minions
	spawner.enabled = false
	spawner.clear()
	for p in minion_spots:
		var m = spawner.spawn_minion_at(p)
		m.max_health = 1000000.0
		m.health = m.max_health
	var boss = run.kaiju_boss
	if kaiju_spot != Vector2.INF:
		var k = boss.appear_at(kaiju_spot)
		k.max_health = 1000000.0
		k.health = k.max_health
	var t := 0.0
	while t < walk_seconds:
		spawner.move_step(DT)
		if boss.kaiju != null:
			boss.step(DT)
		run.state.health = run.state.max_health
		t += DT
	spawner.update_drawing()
	boss.enabled = false
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()
	for m in spawner.minions:
		m.sprite.reset_physics_interpolation()
	var heights := []
	for m in spawner.minions:
		heights.append("%s h%.1f" % [m.position_units().round(), m.ground_height()])
	print("enemies_heights_demo: car %s height %.1f; minions: %s; kaiju %s" % [
		car_units, car.height, ", ".join(heights),
		"%s h%.1f" % [boss.kaiju.position_units().round(), boss.kaiju.ground_height()] if boss.kaiju != null else "none"])


func _process(_delta: float) -> void:
	if run != null and run.state != null:
		run.state.health = run.state.max_health
