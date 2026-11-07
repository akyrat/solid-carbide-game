extends Control
## Task T-560: a scene for the screenshot tool (game/docs/setup/screenshots.md) that plays the practice
## playground (data/level/practice_playground.json) with the car in a scripted pose. The mode comes
## from the environment variable T560_MODE: "drift" (the drift start, turning at speed), "ramp" (on
## the jump ramp), "air" (in the air off the ramp, spinning), "rail" (grinding rail-2), "overview"
## (zoomed out on the whole level).

const RunScene := preload("res://scenes/run/run.tscn")
const PATH := "res://data/level/practice_playground.json"


func _ready() -> void:
	var mode := OS.get_environment("T560_MODE")
	var run: Node2D = RunScene.instantiate()
	run.layout_path = PATH
	run.start_point_id = "drift" if mode in ["", "drift"] else "air_spin"
	add_child(run)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.car.use_keyboard = false
	await get_tree().process_frame
	var car = run.car
	match mode:
		"ramp":
			_place(car, Vector2(6.0, 0.0), 3.0, 15.0)
			car.scripted_input = [true, false, 0.0]
		"air":
			_place(car, Vector2(22.0, 0.0), 4.0, 15.0)
			car.height_model.airborne = true
			car.height_model.vertical_speed = 2.0
			car.scripted_input = [true, false, 1.0]
		"rail":
			_place(car, Vector2(30.0, 0.0), 2.0, 14.0)
			car.height_model.airborne = true
			car.height_model.vertical_speed = -3.0
			car.scripted_jump_held = true
			car.scripted_input = [true, false, 0.0]
		"overview":
			run.set_zoom(40.0)
			_place(car, Vector2(8.0, 0.0), 3.0, 0.0)
		_:
			car.scripted_input = [true, false, 1.0]
			car.model.set_velocity(Vector2(14.0, 0.0))


func _place(car, pos: Vector2, height: float, speed: float) -> void:
	car.model.set_position(pos)
	car.model.rotation = 0.0
	car.model.set_velocity(Vector2(speed, 0.0))
	car.height_model.height = height
