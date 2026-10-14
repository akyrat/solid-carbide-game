extends Node
## Screenshot fixture (task T-041): a run started from the main menu, the car
## standing in the gravel square with minions around it, and the starting gun
## firing its placeholder bullets at them. `tier` sets the gun's tier (1 = the
## base gun; 2 fires 3 bullets a volley, so more bullets are in the air).
## The gun's clock is set to fire on the first physics step, so a short
## capture shows bullets in flight.
## bash game/tools/screenshot.sh res://tests/fixtures/starting_gun_demo.tscn screenshots/starting_gun.png 16
## bash game/tools/screenshot.sh res://tests/fixtures/starting_gun_tier2_demo.tscn screenshots/starting_gun_tier2.png 18

@export var tier := 1

const OFFSETS := [Vector2(7.0, -2.0), Vector2(-4.0, 6.0), Vector2(5.0, 6.5), Vector2(-8.0, -5.0)]


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	var run: Node2D = game.run
	run.car.use_keyboard = false
	var spawner: Node = run.minions
	spawner.enabled = false  # only the minions placed here, standing still
	var car_units: Vector2 = run.car.position / 16.0
	for o in OFFSETS:
		spawner.spawn_minion_at(car_units + o)
	spawner.update_drawing()
	var gun: Node = run.weapons.gun
	gun.set_tier(tier)
	gun.fire_clock = gun.fire_interval()
	gun.fired.connect(func(b: Node, target: Node) -> void:
		print("T-041 demo: fired at %s from %s" % [target.position_units() if target != null else null, b.units]))
	print("T-041 demo: tier=%d range=%.1f interval=%.3f bullets=%d minions=%d" % [
		gun.tier, gun.stats["range"], gun.fire_interval(), gun.stats["bullets"], spawner.minions.size()])
