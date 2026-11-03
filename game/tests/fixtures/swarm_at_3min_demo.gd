extends Node
## Screenshot fixture (task T-522): the swarm near 3:00, when the minions' growth has peaked and the
## kaiju arrives: the run's clock at the growth end, a crowd of minions round the car, the kaiju
## off to one side.
## bash game/tools/screenshot.sh res://tests/fixtures/swarm_at_3min_demo.tscn screenshots/swarm.png 20


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.start_run()  # no tutorial slides
	await get_tree().create_timer(0.3).timeout
	var run: Node2D = game.run
	run.car.use_keyboard = false
	var until: float = float(EnemyData.new().spawning()["growth_until_seconds"])
	run.state.advance(until - run.state.time_elapsed())
	var car_units: Vector2 = run.car.position / 16.0
	var spawner: Node = run.minions
	spawner.enabled = false
	spawner.rng.seed = 522
	# At the peak a minion comes every 0.3 s and each lives a few seconds: about 60 round the car.
	var rng := RandomNumberGenerator.new()
	rng.seed = 522
	var placed := 0
	for i in 400:
		var p := car_units + Vector2(rng.randf_range(-14.0, 14.0), rng.randf_range(-9.0, 9.0))
		if p.distance_to(car_units) < 2.5 or not spawner.is_free_spot(p):
			continue
		spawner.spawn_minion_at(p)
		placed += 1
		if placed >= 60:
			break
	var boss: Node = run.kaiju_boss
	boss.enabled = false
	var k: Node = boss.appear_at(car_units + Vector2(9.0, 0.0))
	k.heading = Vector2(-1.0, 1.0).normalized()
	boss.update_drawing()
	spawner.update_drawing()
	print("T-522 demo: %d minions, clock %.0f s, interval %.2f s" % [placed, run.state.time_elapsed(), spawner.spawn_interval()])
