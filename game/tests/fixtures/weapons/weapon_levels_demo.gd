extends Node
## Screenshot fixture (task T-326): weapons hit only enemies on their own level.
## A run started from the main menu on the elevation map; the car is parked on
## roof-nw-3 (height 3) next to its south edge with the neon underglow and the
## gun off. One minion stands beside it on the rooftop and three on the street
## just below the edge, all inside the ring's reach (2.5 units): only the one on
## the rooftop is hit. The minions are held still (the spawner is off; their
## drawing is updated by hand) and have a lot of health so they stay on screen.
## Screenshot: bash game/tools/screenshot.sh res://tests/fixtures/weapons/weapon_levels_demo.tscn screenshots/weapon_levels.png 60

const CAR_AT := Vector2(-60.0, -67.2)
const ON_ROOF := [Vector2(-58.3, -67.6)]
const BELOW := [Vector2(-60.0, -65.2), Vector2(-61.5, -65.3), Vector2(-58.6, -65.4)]

var run: Node2D
var minions: Array = []


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	run = game.run
	run.minions.enabled = false
	run.minions.clear()  # none but the demo's own
	var car = run.car
	car.use_keyboard = false
	car.scripted_input = [false, false, 0.0]
	var ground = car.ground
	car.ground = null
	car.model.x = CAR_AT.x
	car.model.y = CAR_AT.y
	car.model.vx = 0.0
	car.model.vy = 0.0
	car.model.rotation = -PI / 4.0
	car.position = CAR_AT * 16.0
	car.ground = ground  # back on the map's heights: the car stands on the rooftop
	run.sync_view(true)
	var rack = run.weapons
	rack.gun.set_tier(0)
	if not rack.underglow.is_owned():
		rack.upgrade("underglow")
	for p in ON_ROOF + BELOW:
		var m: Node = run.minions.spawn_minion_at(p)
		m.max_health = 1000.0
		m.health = 1000.0
		minions.append(m)
	rack.underglow.enemy_hit.connect(func(e: Node, amount: float) -> void:
		print("T-326 demo: hit %s (height %.1f) for %.2f" % [e.name, e.body_height(), amount]))
	print("T-326 demo: car height %.2f, level %.2f" % [car.height, rack.car_level()])
	for i in 50:
		await get_tree().physics_frame
		run.minions.update_drawing()
	for m in minions:
		print("T-326 demo: %s at height %.1f, %.1f units from the car, health %.0f" % [
			m.name, m.body_height(), m.position_units().distance_to(rack.car_units()), m.health])
