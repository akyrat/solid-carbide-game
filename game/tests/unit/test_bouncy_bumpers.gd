extends GutTest
## Task T-462: Bouncy Bumpers (Drifting, Content, "Bouncy Bumpers (task T-462)").
## The real car is driven head-on into a wall with W held, from the same spot at
## the same speed, with no power-up and at each tier; the furthest it gets from
## the wall is its bounce distance. No power-up equals the T-435 bounce, and the
## distance grows tier by tier by power_ups.json's bounce_distance_multiplier.

const CarScript := preload("res://scripts/driving/car.gd")
const PowerUpDataScript := preload("res://scripts/data/power_up_data.gd")
const U := 16.0
## Steps watched after the hit (1.6 s: longer than the biggest bounce lasts).
const WATCH_STEPS := 80
## The distance ratio may differ from the multiplier by this share (W's pull-back
## acts on the steps, not as an exact formula).
const RATIO_TOLERANCE := 0.12

var _world: Node2D
var _hits: Array = []


func before_each() -> void:
	_world = Node2D.new()
	add_child_autofree(_world)
	_hits = []
	var body := StaticBody2D.new()
	body.collision_layer = CarScript.LAYER_OBSTACLES
	body.collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 2) * U
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Rect2(-10, -12, 20, 2).get_center() * U
	body.add_child(cs)
	_world.add_child(body)


## Furthest the car gets from the wall after a head-on hit at `speed` with the
## given Bouncy Bumpers tier (0 = none), W held.
func _bounce_distance(tier: int, speed: float = 11.0) -> float:
	_hits = []
	var car: CharacterBody2D = CarScript.new()
	car.model.set_position(Vector2(0, -8.5))
	car.model.rotation = -PI / 2.0
	_world.add_child(car)
	car.set_physics_process(false)
	car.use_keyboard = false
	car.detect_tricks = false
	car.hit_obstacle.connect(func(c, i, n, s): _hits.append([c, i, n, s]))
	car.set_bouncy_bumpers_tier(tier)
	car.model.set_velocity(Vector2(0, -speed))
	car.scripted_input = [true, false, 0.0]
	for i in 30:
		car.physics_step()
		if not _hits.is_empty():
			break
	assert_false(_hits.is_empty(), "tier %d: hit the wall" % tier)
	var n: Vector2 = _hits[0][2] if not _hits.is_empty() else Vector2.DOWN
	var at: Vector2 = car.model.get_position()
	var best := 0.0
	for i in WATCH_STEPS:
		car.physics_step()
		best = maxf(best, (car.model.get_position() - at).dot(n))
	car.queue_free()
	return best


func _multiplier(tier: int) -> float:
	return float(PowerUpDataScript.new().at("bouncy_bumpers", tier)["bounce_distance_multiplier"])


func test_not_owned_is_todays_bounce() -> void:
	await wait_physics_frames(2)
	var none := _bounce_distance(0)
	assert_gt(none, 0.15, "the plain bounce moves the car away")
	# Tier 0 set explicitly after a tier was owned (a new run) is the plain bounce again.
	assert_almost_eq(_bounce_distance(0), none, 1e-6, "same hit, same distance")
	var car: CharacterBody2D = CarScript.new()
	assert_eq(car.bounce_distance_multiplier, 1.0, "no multiplier by default")
	car.set_bouncy_bumpers_tier(2)
	car.set_bouncy_bumpers_tier(0)
	assert_eq(car.bounce_distance_multiplier, 1.0, "losing the power-up resets the multiplier")
	car.free()


func test_distance_grows_tier_by_tier_by_the_data_factors() -> void:
	await wait_physics_frames(2)
	var base := _bounce_distance(0)
	var last := base
	for tier in range(1, PowerUpDataScript.new().max_tier("bouncy_bumpers") + 1):
		var d := _bounce_distance(tier)
		var m := _multiplier(tier)
		assert_gt(d, last + 0.05, "tier %d bounces further than the tier before (%.3f vs %.3f)" % [tier, d, last])
		assert_almost_eq(d / base, m, m * RATIO_TOLERANCE, "tier %d: %.3f / %.3f is about x%.1f" % [tier, d, base, m])
		gut.p("BOUNCE_DISTANCE tier=%d multiplier=%.2f distance=%.4f base=%.4f" % [tier, m, d, base])
		last = d


func test_the_maximum_scales_the_same_way() -> void:
	await wait_physics_frames(2)
	var cap: float = preload("res://scripts/driving/car_tuning.gd").new().wall_bounce_max_hit_speed
	var base := _bounce_distance(0, cap + 10.0)
	var top: int = PowerUpDataScript.new().max_tier("bouncy_bumpers")
	var tier4 := _bounce_distance(top, cap + 10.0)
	var m := _multiplier(top)
	assert_almost_eq(tier4 / base, m, m * RATIO_TOLERANCE, "a hit over the cap also bounces x%.1f further" % m)
	assert_almost_eq(_bounce_distance(top, cap + 30.0), tier4, 1e-3, "above the (scaled) cap every hit bounces the same")


## T-540: every tier is clearly further than the T-435/T-462 factors (1.4 and 2.6).
func test_factors_are_higher_than_before_t540() -> void:
	var old := {1: 1.4, 2: 2.6}
	for tier in old:
		assert_gt(_multiplier(tier), float(old[tier]) * 1.3, "tier %d is clearly above the old x%.1f" % [tier, old[tier]])
	assert_almost_eq(_multiplier(1), 2.1, 1e-6)
	assert_almost_eq(_multiplier(2), 3.9, 1e-6)
