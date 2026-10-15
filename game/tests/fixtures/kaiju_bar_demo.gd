extends Node
## Screenshot fixture (task T-050): a run started from the main menu with the
## placeholder kaiju standing on the gravel square, beside the car,
## and some placeholder minions around, for size.
## bash game/tools/screenshot.sh res://tests/fixtures/kaiju_bar_demo.tscn screenshots/kaiju_bar.png 20


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	var run: Node2D = game.run
	run.car.use_keyboard = false
	var car_units: Vector2 = run.car.position / 16.0
	var boss: Node = run.kaiju_boss
	boss.enabled = false  # stands still for the picture
	var k: Node = boss.appear_at(car_units + Vector2(2.0, 9.0))
	k.heading = Vector2(1.0, 1.0).normalized()
	k.take_damage(k.max_health * 0.37)  # partly emptied
	boss.update_drawing()
	run.kaiju_health_bar._follow()
	var spawner: Node = run.minions
	spawner.enabled = false
	spawner.rng.seed = 45
	for p in [Vector2(5.0, 2.0), Vector2(4.0, -3.0), Vector2(-2.0, 6.0), Vector2(7.0, 6.0)]:
		spawner.spawn_minion_at(car_units + p)
	spawner.update_drawing()
	print("T-050 demo: kaiju at %s health %.0f/%.0f z=%d car=%s" % [
		k.position_units(), k.health, k.max_health, k.sprite.z_index, car_units])
