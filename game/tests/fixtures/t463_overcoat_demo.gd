extends Node
## Screenshot fixture (task T-463): the car with Rusty Overcoat (tier 2) stands among minions
## that touch it; each loses health and flashes red. Needs a real window (screenshot.sh).

var run: Node2D
var n := 0
var minions: Array = []


func _ready() -> void:
	run = preload("res://scenes/run/run.tscn").instantiate()
	add_child(run)
	await get_tree().process_frame
	run.minions.enabled = false
	var car: CharacterBody2D = run.car
	car.use_keyboard = false
	car.detect_tricks = false
	car.scripted_input = [false, false, 0.0]
	run.camera_follow.dynamic = false
	run.set_zoom(9.0)
	run.sync_view()
	run.state.grant_power_up("rusty_overcoat")
	run.state.grant_power_up("rusty_overcoat")
	var c: Vector2 = car.position / 16.0
	for off in [Vector2(0.9, 0.0), Vector2(-0.9, 0.0), Vector2(0.0, 0.9), Vector2(0.0, -0.9)]:
		var m: Node = run.minions.spawn_minion_at(c + off.rotated(car.rotation))
		m.max_health = 40.0
		m.health = 40.0
		minions.append(m)
	run.minions.update_drawing()


func _physics_process(_delta: float) -> void:
	if run == null:
		return
	n += 1
	run.state.health = run.state.max_health
	run.state.invulnerable_left = 0.0
	for m in minions:
		if is_instance_valid(m):
			m.contact_step(0.02, run.car, run.state)
