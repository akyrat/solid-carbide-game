extends GutTest
## Task T-044: minions spawn, chase the car, damage and knock it back, die
## and drop coins; coins are collected by driving over them; pause and a new
## run; their place in the buildings' depth order.

const RunScene := preload("res://scenes/run/run.tscn")
const MinionScript := preload("res://scripts/enemies/minion.gd")
const DT := 0.02  # one physics step (50 per second)

var run: Node2D
var spawner: Node
var data: EnemyData


func before_each() -> void:
	run = RunScene.instantiate()
	add_child_autofree(run)
	spawner = run.minions
	spawner.rng.seed = 44
	data = EnemyData.new()


func after_each() -> void:
	get_tree().paused = false


func _car_units() -> Vector2:
	return run.car.position / 16.0


## Steps the spawner by hand for `seconds`, keeping the car at full health so
## the run does not end while the minions crowd it.
func _simulate_spawner(seconds: float) -> void:
	var t := 0.0
	while t < seconds - 0.000001:
		spawner.step(DT)
		run.state.health = run.state.max_health
		t += DT


func test_run_has_the_spawner_and_its_draw_order_place() -> void:
	assert_not_null(spawner, "run.minions")
	assert_eq(spawner.state, run.state)
	assert_eq(spawner.car, run.car)
	assert_eq(spawner.bodies_root.get_parent(), run.physics_world, "bodies in the flat physics world")
	assert_lt(spawner.draw_root.get_index(), run.view_root.get_index(), "drawn before the car's View")
	assert_gt(spawner.draw_root.get_index(), run.map.get_index(), "drawn after the map")


func test_more_minions_at_the_end_of_the_7_minutes_than_at_the_start() -> void:
	var s := data.spawning()
	# Start of the run: the spawner fills up to the data's starting count.
	_simulate_spawner(15.0)
	var at_start: int = spawner.minions.size()
	assert_eq(at_start, int(s["minions_at_start"]), "12 at the start")
	assert_eq(spawner.minions_wanted_now(), data.minions_wanted(run.state.time_elapsed()))
	# Halfway: the run's clock moves on, the count grows.
	run.state.advance(210.0 - run.state.time_elapsed())
	_simulate_spawner(10.0)
	var halfway: int = spawner.minions.size()
	assert_eq(halfway, data.minions_wanted(run.state.time_elapsed()))
	# 7 minutes: the kaiju's arrival, the data's top count.
	run.state.advance(s["growth_until_seconds"] - run.state.time_elapsed())
	_simulate_spawner(10.0)
	var at_end: int = spawner.minions.size()
	assert_eq(at_end, int(s["minions_at_boss_time"]), "20 at 7:00")
	assert_gt(at_end, at_start, "more minions at the end of the 7 minutes")
	assert_true(halfway > at_start and halfway < at_end, "growing in between")
	assert_lt(at_end, at_start * 2, "slightly: under double")


func test_spawns_one_per_interval_beyond_the_screen_edge() -> void:
	spawner.step(DT)
	assert_eq(spawner.minions.size(), 1, "the first one at once")
	var interval: float = data.spawning()["spawn_interval_seconds"]
	var steps := int(round(interval / DT))
	for i in steps - 1:
		spawner.step(DT)
	assert_eq(spawner.minions.size(), 1, "not before the interval")
	spawner.step(DT)
	assert_eq(spawner.minions.size(), 2, "the next one after spawn_interval_seconds")
	var vis: Rect2 = spawner.visible_rect()
	for i in 50:
		var p = spawner.pick_spawn_point()
		if p == null:
			continue
		var screen: Vector2 = run.ISO_TRANSFORM * (p * 16.0)
		assert_false(vis.has_point(screen), "off the visible screen")
		assert_true(vis.grow(data.spawning()["spawn_margin_units"] * 16.0 + 1.0).has_point(screen), "at the margin")
		assert_true(spawner.is_free_spot(p), "not on a building or boulder")


func test_combo_hook_multiplies_minions_wanted() -> void:
	assert_eq(spawner.spawn_multiplier, 1.0, "no extra spawning until T-085 wires the combo")
	spawner.spawn_multiplier = 1.5
	assert_eq(spawner.minions_wanted_now(), data.minions_wanted(run.state.time_elapsed(), 1.5))


func test_minion_moves_towards_the_car() -> void:
	var start := _car_units() + Vector2(8.0, 3.0)
	assert_true(spawner.is_free_spot(start))
	var m: Node = spawner.spawn_minion_at(start)
	spawner.enabled = false  # no more spawning; walk this one by hand
	var before: float = m.position_units().distance_to(_car_units())
	for i in 25:
		m.walk(DT, _car_units())
	var after: float = m.position_units().distance_to(_car_units())
	var speed: float = data.minion()["move_speed"]
	assert_almost_eq(before - after, speed * 25 * DT, 0.01, "straight at the car at the data's speed")
	var dir: Vector2 = (m.position_units() - start).normalized()
	assert_almost_eq(dir.dot((_car_units() - start).normalized()), 1.0, 0.001, "towards the car")


func test_minion_walks_round_a_building() -> void:
	var b: Rect2 = run.map.rect_of(run.map.layout.buildings[0])
	# Just outside the building's left wall, the car's x far to the right of it.
	var start := Vector2(b.position.x - 1.0, b.get_center().y)
	var target := Vector2(b.end.x + 10.0, b.get_center().y)
	var m: Node = spawner.spawn_minion_at(start)
	spawner.enabled = false
	for i in 50 * 20:
		m.walk(DT, target)
		assert_false(b.has_point(m.position_units()), "never inside the building")
	assert_lt(m.position_units().distance_to(target), 2.0, "got round it")


func test_touching_minion_damages_the_car_at_the_data_rate_and_knocks_it_back() -> void:
	var st := data.minion()
	spawner.enabled = false
	run.car.use_keyboard = false
	var offset := Vector2(0.9, 0.0).rotated(run.car.rotation)  # touching the car's side
	var m: Node = spawner.spawn_minion_at(_car_units() + offset)
	assert_true(m.touches_car(_car_units(), run.car.rotation))
	var health_before: float = run.state.health
	var seconds := 2.0
	var steps := int(round(seconds / DT))
	var hits := 0
	var push := Vector2.ZERO
	for i in steps:
		m.set_position_units(_car_units() + offset)  # keep it touching
		if m.contact_step(DT, run.car, run.state):
			hits += 1
	push = run.car.pending_knockback()
	var lost: float = health_before - run.state.health
	var rate: float = st["contact_damage"] / st["contact_damage_interval"]
	assert_eq(hits, int(seconds / st["contact_damage_interval"]), "one hit per interval, the first at once")
	assert_almost_eq(lost, st["contact_damage"] * hits, 0.0001, "the data's damage per hit")
	assert_almost_eq(lost / seconds, rate, st["contact_damage"] / seconds, "about the data's rate")
	assert_almost_eq(push.length(), st["knockback"] * hits, 0.001, "knocked back with the data's strength each hit")
	assert_almost_eq(push.normalized().dot(-offset.normalized()), 1.0, 0.001, "away from the minion")
	var car_before := _car_units()
	run.car.physics_step()
	assert_gt((_car_units() - car_before).dot(-offset), 0.0, "the car moves away")


func test_minion_not_touching_does_no_damage() -> void:
	spawner.enabled = false
	var m: Node = spawner.spawn_minion_at(_car_units() + Vector2(3.0, 0.0))
	var before: float = run.state.health
	for i in 50:
		m.contact_step(DT, run.car, run.state)
	assert_eq(run.state.health, before)
	assert_eq(run.car.pending_knockback(), Vector2.ZERO)


func test_minion_dies_at_zero_health() -> void:
	spawner.enabled = false
	var m: Node = spawner.spawn_minion_at(_car_units() + Vector2(6.0, 0.0))
	var died := []
	m.died.connect(func(who: Node, at: Vector2) -> void: died.append([who, at]))
	var hp: float = data.minion()["health"]
	assert_eq(m.health, hp)
	m.take_damage(hp - 1.0)
	assert_false(m.is_dead(), "still alive at 1")
	m.take_damage(0.0)
	m.take_damage(-5.0)
	assert_eq(m.health, 1.0, "zero and negative damage ignored")
	m.take_damage(1.0)
	assert_true(m.is_dead(), "dead at 0")
	assert_eq(died.size(), 1)
	m.take_damage(1.0)
	assert_eq(died.size(), 1, "dies once")
	assert_false(spawner.minions.has(m), "no longer one of the run's minions")
	assert_false(m.is_in_group("enemies"))
	await wait_process_frames(2)
	assert_false(is_instance_valid(m), "removed")


func test_coins_drop_at_about_the_data_chance() -> void:
	spawner.enabled = false
	var c := data.coins()
	var kills := 600
	var tally := {"drops": 0, "coins": 0}  # lambdas capture locals by value
	spawner.minion_killed.connect(func(_m: Node, n: int) -> void:
		tally.coins += n
		if n > 0:
			tally.drops += 1)
	for i in kills:
		var m: Node = spawner.spawn_minion_at(_car_units() + Vector2(6.0, 0.0))
		m.take_damage(1000.0)
	var drops: int = tally.drops
	var coins_dropped: int = tally.coins
	var share := float(drops) / kills
	gut.p("drops %d of %d kills (%.3f), %d coins" % [drops, kills, share, coins_dropped])
	assert_almost_eq(share, c["drop_chance"], 0.06, "drop chance about the data's")
	assert_eq(coins_dropped, drops * int(c["coins_per_drop"]), "coins_per_drop each")
	assert_eq(spawner.coins.size(), coins_dropped, "a coin on the ground for each")
	assert_eq(run.state.coins, 0, "not collected until picked up")


func test_driving_over_a_coin_collects_it() -> void:
	spawner.enabled = false
	run.car.use_keyboard = false
	# The car's nose points along -y at the start.
	var coin: Node = spawner.spawn_coin_at(_car_units() + Vector2(0.0, -5.0), 1)
	var sprite: Node2D = coin.sprite
	assert_eq(run.state.coins, 0)
	run.car.scripted_input = [true, false, 0.0]
	var frames := 0
	while is_instance_valid(coin) and not coin.is_taken() and frames < 100:
		await wait_physics_frames(1)
		frames += 1
	assert_eq(run.state.coins, 1, "the run's coins went up")
	await wait_process_frames(2)
	assert_false(is_instance_valid(coin), "the coin is gone")
	assert_false(is_instance_valid(sprite), "and its drawing")


func test_coin_ignores_minions_and_collects_once() -> void:
	spawner.enabled = false
	var coin: Node = spawner.spawn_coin_at(_car_units() + Vector2(20.0, 0.0), 2)
	assert_eq(coin.collision_layer, 8, "pickups layer")
	assert_eq(coin.collision_mask, 2, "notices only the car")
	coin.collect()
	coin.collect()
	assert_eq(run.state.coins, 2)


func test_minions_stand_still_while_paused() -> void:
	spawner.enabled = true
	var m: Node = spawner.spawn_minion_at(_car_units() + Vector2(10.0, 0.0))
	await wait_physics_frames(3)
	get_tree().paused = true
	var frozen: Vector2 = m.position
	var count: int = spawner.minions.size()
	await wait_physics_frames(30)
	assert_eq(m.position, frozen, "paused: it does not move")
	assert_eq(spawner.minions.size(), count, "paused: none spawn")
	get_tree().paused = false
	await wait_physics_frames(5)
	assert_ne(m.position, frozen, "unpaused: it walks again")


func test_new_run_clears_minions_and_coins() -> void:
	_simulate_spawner(3.0)
	var m: Node = spawner.spawn_minion_at(_car_units() + Vector2(6.0, 0.0))
	var coin: Node = spawner.spawn_coin_at(_car_units() + Vector2(6.0, 4.0))
	assert_gt(spawner.minions.size(), 1)
	run.start_run()
	assert_eq(spawner.minions.size(), 0, "no minions in a new run")
	assert_eq(spawner.coins.size(), 0, "no coins in a new run")
	assert_eq(spawner.car, run.car, "follows the new car")
	assert_eq(spawner.map, run.map, "and the new map")
	spawner.enabled = false  # nothing new spawns while we wait for the old ones to go
	await wait_process_frames(2)
	assert_false(is_instance_valid(m))
	assert_false(is_instance_valid(coin))
	assert_eq(spawner.draw_root.get_child_count(), 0, "no drawings left")
	assert_eq(spawner.bodies_root.get_child_count(), 0, "no bodies left")
	spawner.enabled = true
	spawner.step(DT)
	assert_eq(spawner.minions.size(), 1, "spawning starts again")


func test_nothing_moves_after_the_run_ends() -> void:
	var m: Node = spawner.spawn_minion_at(_car_units() + Vector2(10.0, 0.0))
	run.state.damage_car(10000.0)
	assert_false(run.state.is_running())
	var at: Vector2 = m.position
	spawner.step(DT)
	assert_eq(m.position, at)


func test_minions_far_behind_are_removed() -> void:
	spawner.enabled = false
	var vis: Rect2 = spawner.visible_rect()
	var far_screen := vis.end + vis.size * 1.5
	var far_units: Vector2 = (run.ISO_TRANSFORM.affine_inverse() * far_screen) / 16.0
	var m: Node = spawner.spawn_minion_at(far_units)
	var near: Node = spawner.spawn_minion_at(_car_units() + Vector2(8.0, 0.0))
	spawner.enabled = true
	spawner.step(DT)
	assert_false(spawner.minions.has(m), "a screen behind: removed")
	assert_true(spawner.minions.has(near), "near the car: kept")
	assert_eq(run.state.coins, 0)


func test_layers_follow_the_collision_table() -> void:
	var m: Node = spawner.spawn_minion_at(_car_units() + Vector2(6.0, 0.0))
	assert_eq(m.collision_layer, 4, "enemies layer (3)")
	assert_eq(m.collision_mask, 1, "obstacles only: never pushes the car")
	assert_true(m.is_in_group("enemies"))
	assert_true(m.is_in_group("minions"))


func test_draw_order_under_a_covering_building_over_the_rest() -> void:
	var map: Node2D = run.map
	var top: int = map.top_z_index()
	var m: Node = spawner.spawn_minion_at(_car_units() + Vector2(6.0, 0.0))
	spawner.enabled = false
	spawner.update_drawing()
	assert_eq(m.sprite.z_index, top, "in the open: over every building")
	# Behind a skyscraper slot: just behind its back wall, in the middle.
	var slot = map.fade_items()[0]
	var f: Rect2 = slot.footprint
	var behind := Vector2(f.get_center().x, f.position.y - 1.0)
	var z: int = spawner.depth.z_index_for(behind, MinionScript.RADIUS_UNITS, MinionScript.HEIGHT_UNITS)
	assert_true(z <= slot.z_index - 1, "under the building that covers it")
	assert_eq(z, map.car_z_index(behind, 0.0), "the same place the car gets there")
	m.set_position_units(behind)
	spawner.update_drawing()
	assert_eq(m.sprite.z_index, z)
	assert_eq(m.sprite.position, run.ISO_TRANSFORM * m.position, "drawn at its body in the isometric view")
	# In front of the same slot: over it.
	var front := Vector2(f.get_center().x, f.end.y + 1.0)
	assert_gt(spawner.depth.z_index_for(front, MinionScript.RADIUS_UNITS, MinionScript.HEIGHT_UNITS), slot.z_index, "in front: over it")


func test_placeholders_avoid_redgull_red() -> void:
	var sprite_script := preload("res://scripts/enemies/minion_sprite.gd")
	var coin_script := preload("res://scripts/enemies/coin_sprite.gd")
	var colors := [sprite_script.BODY_COLOR, sprite_script.BELLY_COLOR, sprite_script.LEG_COLOR,
		sprite_script.OUTLINE_COLOR, sprite_script.EYE_COLOR, sprite_script.SHADOW_COLOR,
		coin_script.FACE_COLOR, coin_script.EDGE_COLOR, coin_script.SHINE_COLOR,
		coin_script.OUTLINE_COLOR, coin_script.SHADOW_COLOR]
	for c in colors:
		var reddish: bool = c.r > 0.6 and c.g < 0.35 and c.b < 0.35
		assert_false(reddish, "no red: %s" % c)
	var body: Color = sprite_script.BODY_COLOR
	assert_true(body.g > body.r and body.g > body.b, "the minion is green")
