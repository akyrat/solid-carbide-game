extends GutTest
## Task T-478 (Drifting, Content, "The Jump clears obstacles"): with the Jump power-up the car
## passes over an obstacle while it is higher than the obstacle's top and meets it as a wall
## when it is lower. A boulder stands BOULDER_HEIGHT_UNITS (0.8) high, so a tier 1 hop (peak
## about 1.04) clears it; walls (skyscrapers, the map's edge) block at any height. The car lands
## on the obstacle it flies over, never inside it.

const RunScene := preload("res://scenes/run/run.tscn")
const MvpMapScript := preload("res://scripts/level/mvp_map.gd")
const JumpScript := preload("res://scripts/driving/jump_power_up.gd")

var _run: Node2D
var _hits: Array = []


func before_each() -> void:
	_hits = []
	_run = RunScene.instantiate()
	add_child_autofree(_run)
	_run.minions.enabled = false
	_run.kaiju_boss.enabled = false
	_run.car.use_keyboard = false
	_run.car.detect_tricks = false
	_run.car.hit_obstacle.connect(func(c, _i, _n, _s): _hits.append(c))


## A street point with street (height 0, no ramp) for 14 units east and 5 around it.
func _street_start() -> Vector2:
	var g = _run.elevation.ground_height
	for y in range(-120, 121, 2):
		for x in range(-120, 60, 2):
			var ok := true
			for dx in range(-5, 28, 3):
				for dy in [-5, 0, 5]:
					var p := Vector2(x + dx, y + dy)
					if g.is_ramp(p) or g.height_at(p) != 0.0 or not _run.map.rect_of(_run.map.layout.map.rect).has_point(p):
						ok = false
			if ok:
				return Vector2(x, y)
	return Vector2.INF


func _place(at: Vector2) -> void:
	var car = _run.car
	car.model.set_position(at)
	car.model.rotation = 0.0
	car.model.set_velocity(Vector2.ZERO)
	car.height_model.reset(at)
	car._sync_from_model()


## Drives east with W held toward a meteor boulder at `bx`, pressing Space (when `jump_at` is a
## real number) once the car's centre is `jump_at` units short of the boulder's centre. Returns
## the per-step log {x, height, airborne}.
func _drive(start: Vector2, bx: float, jump_at: float, steps := 200) -> Array:
	var car = _run.car
	var log: Array = []
	car.scripted_input = [true, false, 0.0]
	var pressed := false
	for i in steps:
		car.model.rotation = 0.0
		if not pressed and not is_nan(jump_at) and bx - car.model.x <= jump_at:
			car.press_jump()
			pressed = true
		car.physics_step()
		await wait_physics_frames(1)
		log.append({"x": car.model.x, "height": car.height, "airborne": car.airborne})
		if car.model.x > bx + 8.0:
			break
	return log


func _setup_boulder() -> Array:
	var start := _street_start()
	assert_ne(start, Vector2.INF, "a clear street run")
	_place(start)
	var bx := start.x + 14.0
	var body: StaticBody2D = _run.map.add_meteor_boulder(Vector2(bx, start.y))
	await wait_physics_frames(2)
	return [start, bx, body]


func test_a_boulder_is_lower_than_the_car_and_a_tier_1_hop_is_higher_than_a_boulder() -> void:
	assert_lt(MvpMapScript.BOULDER_HEIGHT_UNITS, 1.0, "lower than the car")
	var d := PowerUpData.new()
	var peak := JumpScript.peak_for(float(d.at("jump", 1).takeoff_speed), 12.0)
	assert_gt(peak, MvpMapScript.BOULDER_HEIGHT_UNITS + 0.1, "tier 1 peak %.2f" % peak)


func test_a_tier_1_hop_clears_a_boulder_with_no_bounce() -> void:
	_run.car.jump.set_tier(1)
	var s: Array = await _setup_boulder()
	var start: Vector2 = s[0]
	var bx: float = s[1]
	var log: Array = await _drive(start, bx, 7.5)
	assert_eq(_hits.size(), 0, "no hit_obstacle")
	assert_gt(_run.car.model.x, bx + 3.0, "past the boulder")
	var top: float = MvpMapScript.BOULDER_HEIGHT_UNITS
	var flew := false
	for r in log:
		if absf(r.x - bx) < 1.4 and r.height >= top - 0.05:
			flew = true
		assert_true(absf(r.x - bx) > 1.9 or r.height >= top - 0.06, "never inside the boulder at x %.2f h %.2f" % [r.x, r.height])
	assert_true(flew, "it was above the boulder")
	assert_false(_run.car.airborne)
	assert_almost_eq(_run.car.height, 0.0, 0.001, "back on the street")


func test_the_same_car_on_the_ground_bounces_off_the_boulder() -> void:
	_run.car.jump.set_tier(1)
	var s: Array = await _setup_boulder()
	await _drive(s[0], s[1], NAN, 150)
	assert_gt(_hits.size(), 0, "it hit the boulder")
	assert_lt(_run.car.model.x, float(s[1]), "and stayed in front of it")


func test_a_car_that_jumps_too_late_meets_the_boulder_as_a_wall() -> void:
	_run.car.jump.set_tier(1)
	var s: Array = await _setup_boulder()
	await _drive(s[0], s[1], 2.3, 150)  # the nose is at the boulder before the hop is high enough
	assert_gt(_hits.size(), 0)


func test_without_the_power_up_space_does_not_clear_it() -> void:
	var s: Array = await _setup_boulder()
	await _drive(s[0], s[1], 7.5, 150)
	assert_gt(_hits.size(), 0)


func test_landing_on_the_boulder_the_car_stands_on_it_and_is_never_inside() -> void:
	_run.car.jump.set_tier(1)
	var s: Array = await _setup_boulder()
	var start: Vector2 = s[0]
	var bx: float = s[1]
	var car = _run.car
	# Slowly: the hop lands over the boulder's middle.
	car.model.set_position(Vector2(bx - 3.5, start.y))
	car.height_model.reset(car.model.get_position())
	car._sync_from_model()
	car.model.set_velocity(Vector2(4.0, 0.0))
	car.scripted_input = [false, false, 0.0]
	car.press_jump()
	var top: float = MvpMapScript.BOULDER_HEIGHT_UNITS
	var stood := false
	for i in 150:
		car.model.rotation = 0.0
		car.physics_step()
		await wait_physics_frames(1)
		var inside: bool = absf(car.model.x - bx) < 1.4
		if inside and not car.airborne:
			stood = true
			assert_almost_eq(car.height, top, 0.001, "on top, not inside, at x %.2f" % car.model.x)
		if inside:
			assert_gte(car.height, top - 0.06, "never below the top over the boulder")
	assert_eq(_hits.size(), 0)
	assert_true(stood, "it landed on the boulder")


func test_a_tier_4_hop_still_cannot_clear_a_wall_and_the_edge_always_blocks() -> void:
	var map: Node2D = _run.map
	assert_eq(map.obstacle_heights(map.walls), [-INF, INF], "walls and the edge block at any height")
	map.update_car_obstacles(_run.car, 500.0)
	assert_false(map.is_passing(map.walls), "even from very high")
	# Flown at the right-hand edge at a made-up height of 6, well above any hop.
	var car = _run.car
	var r: Rect2 = map.rect_of(map.layout.map.rect)
	_place(Vector2(r.end.x - 8.0, r.position.y + r.size.y * 0.5))
	car.height_model.airborne = true
	car.model.set_velocity(Vector2(20.0, 0.0))
	car.scripted_input = [true, false, 0.0]
	for i in 120:
		car.model.rotation = 0.0
		car.height_model.height = 6.0
		car.height_model.vertical_speed = 0.0
		car.physics_step()
		await wait_physics_frames(1)
		if not _hits.is_empty():
			break
	assert_gt(_hits.size(), 0, "the map's edge stopped the flying car")
	assert_lt(car.model.x, r.end.x + 0.1)


func test_the_obstacle_table() -> void:
	var map: Node2D = _run.map
	for b in map.boulder_bodies:
		var hr: Array = map.obstacle_heights(b)
		assert_almost_eq(float(hr[1]) - float(hr[0]), MvpMapScript.BOULDER_HEIGHT_UNITS, 0.0001)
	var body: StaticBody2D = map.add_meteor_boulder(Vector2(0, 0))
	assert_eq(map.obstacle_heights(body), [0.0, MvpMapScript.BOULDER_HEIGHT_UNITS])
