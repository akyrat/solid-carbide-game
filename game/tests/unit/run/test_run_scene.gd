extends GutTest
## Task T-036: the run scene (map, car, camera) and starting a second run.

const RunScene := preload("res://scenes/run/run.tscn")

var run: Node2D


func before_each() -> void:
	run = RunScene.instantiate()
	add_child_autofree(run)


func test_run_starts_with_map_car_and_fresh_state() -> void:
	assert_not_null(run.map, "map loaded")
	assert_eq(run.map.challenge_ids().size(), run.map.layout.challenges.size(), "the MVP map's challenges")
	assert_eq(run.map.challenge_ids().size(), 24, "30% of the 80 pattern copies (T-094)")
	assert_not_null(run.car, "car loaded")
	assert_eq(run.car.get_script(), preload("res://scripts/driving/car.gd"))
	assert_eq(run.map.car, run.car, "the map checks challenges against the car")
	assert_eq(run.car.position, run.START_POSITION_UNITS * 16.0)
	assert_almost_eq(run.car.rotation, run.START_ROTATION, 0.000001)
	assert_eq(run.state.time_left_text(), "8:00")
	assert_eq(run.state.health, RunData.new().starting_health())
	assert_eq(run.state.coins, 0)
	assert_true(run.state.is_running())
	assert_eq(get_tree().get_first_node_in_group("run_state"), run.state)


func test_start_is_clear_of_buildings_and_boulders() -> void:
	var start: Vector2 = run.START_POSITION_UNITS
	var g: Rect2 = run.map.rect_of(run.map.layout.gravel)
	assert_true(g.grow(-1.0).has_point(start), "inside the gravel square")
	for b in run.map.layout.buildings:
		assert_false(run.map.rect_of(b).grow(1.0).has_point(start))
	for copy in run.map.layout.pattern_copies:
		for b in copy.boulders:
			var d := start.distance_to(Vector2(float(b.x), float(b.y)))
			assert_gt(d, float(b.diameter) / 2.0 + 1.0)


func test_camera_follows_car() -> void:
	run.car.use_keyboard = false
	run.car.scripted_input = [true, false, 0.0]
	await wait_physics_frames(30)
	var drawn: Vector2 = run.ISO_TRANSFORM * run.car.position
	assert_ne(run.car.position, Vector2.ZERO, "the car moved")
	assert_eq(run.camera.position, drawn)
	assert_eq(run.car_sprite.position, drawn)
	assert_true(run.camera.is_current())


func test_second_run_resets_world_and_state() -> void:
	var ended := []
	run.state.run_ended.connect(func(r: String, c: int) -> void: ended.append([r, c]))
	run.car.use_keyboard = false
	run.car.scripted_input = [true, false, 0.0]
	await wait_physics_frames(20)
	run.state.add_coins(5)
	run.state.damage_car(1000.0)
	assert_eq(ended, [["loss", 5]])
	var old_map = run.map
	run.map._complete(run.map.challenge_ids()[0])
	run.start_run()
	assert_ne(run.map, old_map, "a fresh map")
	for id in run.map.challenge_ids():
		assert_false(run.map.is_challenge_completed(id), "every challenge open again")
	assert_eq(run.car.position, run.START_POSITION_UNITS * 16.0, "car back at the start")
	assert_eq(Vector2(run.car.model.vx, run.car.model.vy), Vector2.ZERO, "car standing still")
	assert_eq(run.map.car, run.car)
	assert_eq(run.state.time_left_text(), "8:00")
	assert_eq(run.state.health, run.state.max_health)
	assert_eq(run.state.coins, 0)
	assert_true(run.state.is_running())
	assert_eq(run.get_node("Map"), run.map)
