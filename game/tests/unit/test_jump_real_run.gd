extends GutTest
## Task T-478 (the board's playtest, 2026-11-01): the Jump in the real run as the board plays it
## (game.tscn, "Start", the Kaiju City map), over the map's own boulders and barriers: a tier 1
## hop pressed when the car's nose looks level with the obstacle clears it, the car lands on top of
## one and drives off its edge, and without the hop the same obstacle stops the car.

const GameScene := preload("res://scenes/game/game.tscn")

var game: Node
var run: Node2D
var car: CharacterBody2D
var hits: Array = []


func before_each() -> void:
	hits = []
	game = GameScene.instantiate()
	add_child_autofree(game)
	game.start_run()
	run = game.run
	run.state.grant_power_up("jump")
	await wait_physics_frames(3)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	car = run.car
	car.use_keyboard = false
	car.set_physics_process(false)
	car.hit_obstacle.connect(func(c, _i, _n, _s): hits.append(str(c.name) if c is Node else "ground"))


## The boulders and barriers of the real map: [body, centre units, half width along x].
func _targets(kind: String) -> Array:
	var out := []
	if kind == "boulder":
		for b in run.map.boulder_bodies:
			out.append([b, b.get_child(0).global_position / 16.0, 1.5])
	else:
		for b in run.map.prop_bodies:
			var pid := str(b.get_meta("prop_id"))
			for p in run.map.layout.props:
				if str(p.id) == pid and str(p.asset) == "prop-barrier":
					var cs: CollisionShape2D = b.get_child(0)
					out.append([b, cs.global_position / 16.0, (cs.shape as RectangleShape2D).size.x / 32.0])
	return out


func _place(at: Vector2, v := Vector2.ZERO) -> void:
	car.model.set_position(at)
	car.model.rotation = 0.0
	car.model.set_velocity(v)
	car.height_model.reset(at)
	car._sync_from_model()
	car.jump.reset()
	hits.clear()


## Drives east at the obstacle with W held, from 30 units away; Space when the car's drawn nose
## (1.5 units ahead of its centre) is `lead` units short of the obstacle's near edge.
## Returns {x (past the centre at the end), maxh, hits}.
func _drive_at(t: Array, lead: float, press := true) -> Dictionary:
	var tp: Vector2 = t[1]
	_place(tp + Vector2(-30.0, 0.0))
	var pressed := not press
	var maxh := 0.0
	for i in 400:
		if not pressed and car.model.x + 1.5 >= tp.x - float(t[2]) - lead:
			car.press_jump()
			pressed = true
		car.scripted_input = [true, false, 0.0]
		car.model.rotation = 0.0
		car.physics_step()
		await wait_physics_frames(1)
		maxh = maxf(maxh, car.height)
		if not hits.is_empty() or car.model.x > tp.x + 6.0:
			break
	return {"x": car.model.x - tp.x, "maxh": maxh, "hits": hits.duplicate()}




func test_the_run_has_boulders_and_barriers_that_go_through_the_height_path() -> void:
	assert_gt(_targets("boulder").size(), 0)
	assert_gt(_targets("barrier").size(), 0)
	for t in _targets("boulder") + _targets("barrier"):
		var hr: Array = run.map.obstacle_heights(t[0])
		assert_lt(float(hr[1]) - float(hr[0]), 1.0, "%s is lower than the car" % t[0].name)


func test_a_tier_1_hop_pressed_at_the_nose_clears_the_maps_boulders() -> void:
	var cleared := 0
	var tried := 0
	for t in _targets("boulder"):
		var ground_hr: Array = run.map.obstacle_heights(t[0])
		if float(ground_hr[0]) > 0.0:
			continue  # on a rooftop: not reached from the street
		var plain: Dictionary = await _drive_at(t, 0.0, false)
		if plain.hits.size() != 1 or plain.hits[0] != t[0].name:
			continue  # the lane has other things in it
		tried += 1
		var r: Dictionary = await _drive_at(t, 0.0)
		if not r.hits.has(t[0].name) and r.x > 1.6:  # a map wall further on is not this obstacle
			cleared += 1
		else:
			gut.p("boulder %s: %s" % [t[0].name, r])
	assert_gt(tried, 0, "a boulder with a clean lane")
	assert_eq(cleared, tried, "every clean-lane boulder is cleared with the press at the nose")


func test_a_tier_1_hop_clears_a_barrier_and_the_ground_does_not() -> void:
	var cleared := 0
	var tried := 0
	for t in _targets("barrier"):
		var plain: Dictionary = await _drive_at(t, 0.0, false)
		if plain.hits.size() != 1 or plain.hits[0] != t[0].name:
			continue
		tried += 1
		var r: Dictionary = await _drive_at(t, 0.0)
		if not r.hits.has(t[0].name) and r.x > 1.6:  # a map wall further on is not this obstacle
			cleared += 1
		else:
			gut.p("barrier %s: %s" % [t[0].name, r])
	assert_gt(tried, 0, "a barrier with a clean lane")
	assert_eq(cleared, tried, "every clean-lane barrier is cleared")


func _land_on(kind: String) -> bool:
	for t in _targets(kind):
		if float(run.map.obstacle_heights(t[0])[0]) > 0.0:
			continue
		var tp: Vector2 = t[1]
		var half: float = t[2]
		_place(tp + Vector2(-2.0 - 1.3 * half, 0.0), Vector2(4.0, 0.0))
		car.scripted_input = [false, false, 0.0]
		car.press_jump()
		var stood := false
		var top := float(run.map.obstacle_heights(t[0])[1])
		for i in 60:
			car.model.rotation = 0.0
			car.physics_step()
			await wait_physics_frames(1)
			if absf(car.model.x - tp.x) < half + 0.4 and not car.airborne:
				stood = true
				assert_almost_eq(car.height, top, 0.001, "%s: standing on top, not inside" % t[0].name)
			if stood:
				break
		if not stood or not hits.is_empty():
			continue
		for i in 200:
			car.scripted_input = [true, false, 0.0]
			car.model.rotation = 0.0
			car.physics_step()
			await wait_physics_frames(1)
			if car.model.x > tp.x + half + 3.0 and not car.airborne:
				break
		assert_gt(car.model.x, tp.x + half + 1.0, "%s: it drove along the top and off the far edge" % t[0].name)
		assert_false(hits.has(t[0].name), "never stopped by it")
		return true
	return false


func test_landing_on_a_boulder_stands_on_it_drives_along_and_off_its_edge() -> void:
	assert_true(await _land_on("boulder"), "landed on a real boulder and drove off it")


func test_landing_on_a_barrier_stands_on_it_drives_along_and_off_its_edge() -> void:
	assert_true(await _land_on("barrier"), "landed on a real barrier and drove off it")


func test_a_press_too_late_still_meets_the_obstacle_as_a_wall() -> void:
	var t: Array = _targets("boulder")[1]
	var r: Dictionary = await _drive_at(t, -2.5)
	assert_gt(r.hits.size(), 0)
