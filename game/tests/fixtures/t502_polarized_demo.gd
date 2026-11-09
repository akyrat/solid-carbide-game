extends Node
## Screenshot fixture (task T-502; T-603: the new trigger): the car with the Polarized
## Steering Wheel at `tier` drives up to speed, drifts forward (W + A) for 0.5 s, then
## switches to a backward drift (S + A) until the trick detector pays the ALT DRIFT!: the
## burst (the stronger motion lines and the ground arrows, T-603). With `minions` on, a
## ring of minions waits round the car once the backward drift starts, so a tier 2
## burst's shock (Bricks' wave) hits and shoves them. The tree pauses `freeze_steps` physics steps after the burst, so
## the screenshot tool's frame count only has to be late enough. Needs a real window
## (screenshot.sh).

@export var tier := 1
@export var minions := false
@export var freeze_steps := 6

var run: Node2D
var phase := 0
var n := 0
var since_burst := -1


func _ready() -> void:
	run = preload("res://scenes/run/run.tscn").instantiate()
	add_child(run)
	await get_tree().process_frame
	run.minions.enabled = false
	var car: CharacterBody2D = run.car
	car.use_keyboard = false
	car.detect_tricks = true
	car.scripted_input = [true, false, 0.0]
	run.camera_follow.dynamic = false
	run.set_zoom(9.0)
	run.sync_view()
	for i in tier:
		run.state.grant_power_up("polarized_steering_wheel")
	car.polarized.fired.connect(func(_s, _sec, _d) -> void: since_burst = 0)


func _physics_process(_delta: float) -> void:
	if run == null or run.car == null:
		return
	var car = run.car
	run.state.health = run.state.max_health
	n += 1
	if phase == 0:
		car.scripted_input = [true, false, 0.0]
		if n >= 45:
			phase = 1
	elif phase == 1:
		car.scripted_input = [true, false, 1.0]
		if n >= 45 + 25:
			phase = 2
			if minions:
				var c: Vector2 = car.model.get_position()
				for k in 8:
					var off := Vector2.from_angle(TAU * k / 8.0) * (2.2 + 0.6 * (k % 2))
					var m: Node = run.minions.spawn_minion_at(c + off)
					m.max_health = 40.0
					m.health = 40.0
				run.minions.update_drawing()
	elif phase == 2:
		car.scripted_input = [false, true, 1.0]
	if since_burst >= 0:
		since_burst += 1
		if since_burst >= freeze_steps:
			get_tree().paused = true
