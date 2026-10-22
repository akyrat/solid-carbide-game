extends "res://tests/fixtures/run_elevation_demo.gd"
## Screenshot fixture (task T-259): the run_elevation_demo drive, with the combo
## held at `combo` so the drift marks take that heat step (T-249), to show the
## marks on a rooftop or a ramp.

@export var combo := 1.0
## Prints the car's place every 10 steps (to plan a drive).
@export var trace := false
## From this physics step on (-1: never) the steering is let go: W only, straight on.
@export var steer_until := -1


func _ready() -> void:
	await super()
	run.drift_marks.set_multiplier(combo)


func _on_stepped() -> void:
	run.drift_marks.set_multiplier(combo)
	if trace and _steps % 10 == 0:
		print("trace %d: %s heading %.2f ground %.1f h %.1f" % [_steps, run.car.model.get_position(), run.car.rotation,
			run.elevation.ground_height.height_at(run.car.model.get_position()), run.car.height])
	if steer_until >= 0 and _steps + 1 == steer_until:
		run.car.scripted_input = [hold_w, false, 0.0]
	super()
