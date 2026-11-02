extends Node
## Screenshot fixture (task T-499): the wiper at tier 8, front and back wiper
## sweeping, minions around the car.
## bash game/tools/screenshot.sh res://tests/fixtures/weapons/wiper_back_demo.tscn ../art-archive/T-499/screenshots/both_wipers.png 120

func _ready() -> void:
	var run: Node2D = preload("res://scenes/run/run.tscn").instantiate()
	add_child(run)
	await get_tree().process_frame
	run.minions.rng.seed = 42
	var wiper = run.weapons.wiper
	run.weapons.gun.set_tier(0)
	for i in 8:
		run.weapons.upgrade("wiper")
	wiper.grow.snap(float(wiper.stats["length"]))
	wiper.back_wiper.grow.snap(float(wiper.stats["length"]))
	for deg in [-60.0, -20.0, 20.0, 60.0]:
		run.minions.spawn_minion_at(wiper.pivot_units() + wiper.forward().rotated(deg_to_rad(deg)) * 3.0)
		run.minions.spawn_minion_at(wiper.back_wiper.pivot_units() + wiper.back_wiper.forward().rotated(deg_to_rad(deg)) * 3.0)
	run.car.use_keyboard = false
	run.car.scripted_input = [false, false, 0.0]
