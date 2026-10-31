extends Node
## Screenshot fixture (T-414): a run whose car is wrecked with molotov fires and the
## underglow going, minions burning in them. Used by tools/screenshot.sh only.

const RunScene := preload("res://scenes/run/run.tscn")
var run: Node2D
var frame := 0


func _ready() -> void:
	run = RunScene.instantiate()
	add_child(run)
	run.minions.enabled = false
	run.car.use_keyboard = false
	run.car.scripted_input = [false, false, 0.0]
	await get_tree().physics_frame
	var rack = run.weapons
	rack.gun.set_tier(0)
	rack.upgrade("molotov")
	rack.upgrade("underglow")
	var c: Vector2 = run.car.model.get_position()
	for off in [Vector2(3, 0), Vector2(-3, 1), Vector2(0, 3), Vector2(0.8, -0.5)]:
		run.minions.spawn_minion_at(c + off)
	for off in [Vector2(3, 0), Vector2(-3, 1), Vector2(0, 3)]:
		rack.molotov.land(c + off)
	run.state.health = 1.0
	run.state.damage_car(1.0)
