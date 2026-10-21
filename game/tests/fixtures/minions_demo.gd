extends Node
## Screenshot fixture (task T-044): a run started from the main menu with
## placeholder minions around the car and two dropped coins. With
## `near_buildings` the car stands at a crossing and minions are put behind
## and in front of the skyscrapers there, to show their draw order.
## bash game/tools/screenshot.sh res://tests/fixtures/minions_demo.tscn screenshots/minions.png 20
## bash game/tools/screenshot.sh res://tests/fixtures/minions_draw_order_demo.tscn screenshots/minions_draw_order.png 20

@export var near_buildings := false

## On the road east of the gravel square, beside the skyscrapers of the block to its east.
const CROSSING := Vector2(54.0, -27.0)


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	var run: Node2D = game.run
	run.car.use_keyboard = false
	var spawner: Node = run.minions
	spawner.rng.seed = 44
	if near_buildings:
		run.car.model.x = CROSSING.x
		run.car.model.y = CROSSING.y
		run.car._sync_from_model()
		run.sync_view()
		run.car_sprite.reset_physics_interpolation()
		run.camera.reset_physics_interpolation()
	var car_units: Vector2 = run.car.position / 16.0
	var placed := 0
	var tries := 0
	while placed < 12 and tries < 400:
		tries += 1
		var p: Vector2 = car_units + Vector2.RIGHT.rotated(spawner.rng.randf() * TAU) * spawner.rng.randf_range(3.0, 11.0)
		if spawner.is_free_spot(p):
			spawner.spawn_minion_at(p)
			placed += 1
	if not near_buildings:
		spawner.spawn_coin_at(car_units + Vector2(-3.0, -4.0), 1)
		spawner.spawn_coin_at(car_units + Vector2(-2.4, -4.4), 1)
		# T-220: two health pickups (placeholder canisters).
		spawner.spawn_health_pickup_at(car_units + Vector2(3.0, -4.0))
		spawner.spawn_health_pickup_at(car_units + Vector2(4.2, -3.2))
	spawner.update_drawing()
	var behind := 0
	for m in spawner.minions:
		if m.sprite.z_index < run.map.top_z_index():
			behind += 1
	print("T-044 demo: minions=%d coins=%d car=%s top_z=%d minions_under_a_building=%d" % [
		spawner.minions.size(), spawner.coins.size(), car_units, run.map.top_z_index(), behind])
