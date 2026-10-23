extends Node
## Recording fixture (task T-266): a run from the main menu with the wiper at tier 1,
## the car standing still, tough minions walking in from in front one by one and
## being flung about 6 units by the arm. Recorded with --write-movie (see the
## ticket's result notes); not part of the test suite.

func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	var run: Node2D = game.run
	run.minions.spawn_multiplier = 0.0  # only the minions placed below (the spawner still walks them)
	run.minions.combo_raises_spawning = false
	var wiper = run.weapons.wiper
	if not wiper.is_owned():
		run.weapons.upgrade("wiper")
	run.car.use_keyboard = false
	run.car.scripted_input = [false, false, 0.0]
	wiper.enemy_hit.connect(func(e: Node, _a: float, pushed: bool) -> void:
		var p0: Vector2 = e.position_units()
		var c0: Vector2 = wiper.car_units()
		await get_tree().create_timer(0.3).timeout
		if is_instance_valid(e):
			print("PUSH pushed=%s moved=%.2f from_car=%.2f" % [pushed, e.position_units().distance_to(p0), p0.distance_to(c0)]))
	var degs :=[-50.0, 10.0, 60.0, -15.0, 35.0, -70.0, 0.0, 50.0]
	var i := 0
	for frame in 480:
		await get_tree().physics_frame
		if frame % 30 == 0 and i < degs.size() * 2:
			var d: float = degs[i % degs.size()]
			var m: Node = run.minions.spawn_minion_at(wiper.pivot_units() + wiper.forward().rotated(deg_to_rad(d)) * 5.0)
			m.max_health = 1000.0
			m.health = 1000.0
			i += 1
	print("PUSH-DEMO end: tier=%d hits=%d minions=%d" % [wiper.tier, wiper.hits, get_tree().get_nodes_in_group("minions").size()])
