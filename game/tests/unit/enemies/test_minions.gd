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


## Steps the spawner `steps` physics steps (car at full health), returning how many the timer spawned.
func _spawned_over(steps: int) -> int:
	var before: int = spawner.spawned_total
	for i in steps:
		spawner.step(DT)
		run.state.health = run.state.max_health
	return spawner.spawned_total - before


func test_spawning_follows_the_timer_not_a_wanted_count() -> void:
	# T-443: one at once, then one every spawn_interval() at the run's start.
	var interval: float = data.spawn_interval(0.0)
	assert_almost_eq(spawner.spawn_interval(), interval, 0.0001)
	spawner.step(DT)
	assert_eq(spawner.minions.size(), 1, "the first one at once")
	var steps := int(round(interval / DT))
	for i in steps - 1:
		spawner.step(DT)
	assert_eq(spawner.minions.size(), 1, "not before the interval")
	spawner.step(DT)
	assert_eq(spawner.minions.size(), 2, "the next one after the interval")


func test_minions_keep_spawning_while_many_are_alive() -> void:
	# T-443: no top-up to a wanted count: 40 alive round the car, more still come on the timer.
	var car_units := _car_units()
	var tries := 0
	while spawner.minions.size() < 40 and tries < 2000:
		tries += 1
		var p: Vector2 = car_units + Vector2.RIGHT.rotated(spawner.rng.randf() * TAU) * spawner.rng.randf_range(6.0, 14.0)
		if spawner.is_free_spot(p):
			spawner.spawn_minion_at(p)
	assert_eq(spawner.minions.size(), 40, "40 placed by hand")
	var interval: float = spawner.spawn_interval()
	var n := _spawned_over(int(round(10.0 * interval / DT)))
	assert_true(n >= 9 and n <= 11, "about one per interval over 10 intervals (got %d)" % n)
	assert_gt(spawner.minions.size(), 40, "more alive than before")


func test_a_new_minion_appears_beyond_the_screen_edge_on_the_street() -> void:
	var vis: Rect2 = spawner.visible_rect()
	var margin: float = data.spawning()["spawn_margin_units"] * 16.0
	var elevation = run.map.get("elevation")
	var rad: float = MinionScript.BASE_RADIUS_UNITS * float(data.minion()["size_scale"])
	# The minions the timer really spawns, over 20 spawns.
	spawner.visible_rect_override = vis  # the same screen for every check
	var seen := 0
	var newest: Node = null
	for i in 20 * int(round(spawner.spawn_interval() / DT)):
		spawner.step(DT)
		run.state.health = run.state.max_health
		if spawner.minions.is_empty() or spawner.minions[-1] == newest:
			continue
		newest = spawner.minions[-1]
		var m: Node = newest
		var p: Vector2 = m.position_units()
		var screen: Vector2 = run.ISO_TRANSFORM * (p * 16.0)
		assert_false(vis.has_point(screen), "off the visible screen")
		# It already took its first step (0.084 units, under 2 pixels) towards the car.
		assert_true(vis.grow(margin + 4.0).has_point(screen), "at the margin, %s units out" % data.spawning()["spawn_margin_units"])
		assert_false(vis.grow(margin - 4.0).has_point(screen), "on the ring, not inside it")
		assert_true(spawner.is_free_spot(p), "clear of buildings and boulders")
		if elevation != null:
			assert_true(elevation.is_street(p, rad), "on the street")
		for b in run.map.layout.buildings:
			assert_false(run.map.rect_of(b).grow(rad).has_point(p), "not on a building")
		for b in run.map.all_boulders():
			assert_true(Vector2(float(b.x), float(b.y)).distance_to(p) >= float(b.diameter) / 2.0 + rad, "not on a boulder")
		seen += 1
	assert_gt(seen, 5, "checked several real spawns")
	# And the spawn points themselves.
	for i in 50:
		var q = spawner.pick_spawn_point()
		if q == null:
			continue
		var sc: Vector2 = run.ISO_TRANSFORM * (q * 16.0)
		assert_false(vis.has_point(sc), "off the visible screen")
		assert_true(vis.grow(margin + 1.0).has_point(sc), "at the margin")
		assert_true(spawner.is_free_spot(q), "not on a building or boulder")


func test_spawn_interval_at_the_start_at_the_boss_time_and_between() -> void:
	var s := data.spawning()
	var start: float = s["spawn_interval_at_start_seconds"]
	var boss: float = s["spawn_interval_at_boss_time_seconds"]
	var until: float = s["growth_until_seconds"]
	assert_true(until <= RunState.RUN_SECONDS - RunState.BOSS_TIME_LEFT, "peaks by the kaiju's arrival (T-522: 3:00)")
	assert_almost_eq(spawner.spawn_interval(), start, 0.0001, "the data's interval at the start")
	# Halfway (3:30): the rate is the average of the two rates.
	run.state.advance(until / 2.0 - run.state.time_elapsed())
	assert_almost_eq(spawner.spawn_interval(), 1.0 / ((1.0 / start + 1.0 / boss) / 2.0), 0.0001, "halfway")
	assert_true(spawner.spawn_interval() < start and spawner.spawn_interval() > boss, "between the two")
	# The kaiju's arrival and after: the data's interval at the kaiju's arrival, held.
	run.state.advance(until - run.state.time_elapsed())
	assert_almost_eq(spawner.spawn_interval(), boss, 0.0001, "the data's interval at the growth end")
	# The timer really runs at that interval late on: one at once, one per interval after.
	var steps := int(round(boss / DT))
	assert_eq(_spawned_over(1 + 10 * steps), 11, "11 in the first 10 intervals at the peak")
	run.state.advance(60.0)
	assert_almost_eq(spawner.spawn_interval(), boss, 0.0001, "held during the kaiju's minute")
	# The data's curve never slows down along the way.
	var last := INF
	for t in range(0, int(RunState.RUN_SECONDS) + 1, 10):
		var v := data.spawn_interval(float(t))
		assert_true(v <= last, "interval at %d s is not longer than the one before" % t)
		last = v


func test_no_combo_means_no_extra_spawning() -> void:
	assert_almost_eq(spawner.spawn_interval(), data.spawn_interval(run.state.time_elapsed()), 0.0001)
	assert_eq(spawner.spawn_multiplier, 1.0)


func test_a_high_combo_shortens_the_interval_by_the_data_amount() -> void:
	var combo := ComboData.new()
	run.state.advance(120.0)
	var base: float = spawner.spawn_interval()
	run.state.combo = combo.max_multiplier()
	var mult := combo.spawn_multiplier(run.state.combo)
	assert_gt(mult, 1.0)
	var shorter: float = spawner.spawn_interval()
	assert_eq(spawner.spawn_multiplier, mult)
	assert_almost_eq(shorter, base / mult, 0.0001, "the multiplier divides the interval")
	assert_almost_eq(shorter, data.spawn_interval(run.state.time_elapsed(), mult), 0.0001)
	# They really spawn faster: over 10 base intervals about 10 x mult come.
	var steps := int(round(10.0 * base / DT))
	var before: int = spawner.spawned_total
	for i in steps:  # contact hits and idling cut the combo, so hold it high
		run.state.combo = combo.max_multiplier()
		spawner.step(DT)
		run.state.health = run.state.max_health
	var n: int = spawner.spawned_total - before
	assert_true(n >= int(10.0 * mult) - 1 and n <= int(ceil(10.0 * mult)) + 1,
		"about %.1f with the combo (got %d)" % [10.0 * mult, n])


func test_the_safety_ceiling_holds_the_timer() -> void:
	var ceiling: int = spawner.max_minions_alive()
	assert_eq(ceiling, int(data.spawning()["max_minions_alive"]))
	assert_true(ceiling >= 100, "high: only there for the frame rate (5 times the old top count of 20)")
	spawner._spawning = data.spawning()
	spawner._spawning["max_minions_alive"] = 5.0
	_spawned_over(int(round(20.0 * spawner.spawn_interval() / DT)))
	assert_eq(spawner.minions.size(), 5, "no more than the ceiling alive")
	spawner.minions[0].take_damage(1000.0, "test")
	_spawned_over(int(round(1.5 * spawner.spawn_interval() / DT)))
	assert_eq(spawner.minions.size(), 5, "one dies, the timer brings the next")


func test_minions_move_30_percent_slower_and_the_kaiju_is_unchanged() -> void:
	assert_eq(data.minion()["move_speed"], 4.2, "4.2 units per second")
	assert_almost_eq(data.minion()["move_speed"], 6.0 * 0.7, 0.0001, "30% slower than 6")
	assert_eq(data.kaiju()["move_speed"], 3.0, "the kaiju's speed is unchanged")
	var m: Node = spawner.spawn_minion_at(_car_units() + Vector2(8.0, 3.0))
	assert_eq(m.move_speed, 4.2, "a spawned minion walks at 4.2")


func test_with_the_switch_off_the_combo_changes_nothing() -> void:
	spawner.combo_raises_spawning = false
	var base: float = spawner.spawn_interval()
	run.state.combo = ComboData.new().max_multiplier()
	assert_eq(spawner.spawn_interval(), base)
	assert_eq(spawner.spawn_multiplier, 1.0)


func test_the_switch_is_on_by_default() -> void:
	assert_true(spawner.combo_raises_spawning)


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
	# T-405: a block with no short building (the first one's short slots are platforms now, open street round them).
	var b: Rect2 = run.map.rect_of(run.map.layout.buildings[1])
	# Just outside the building's left wall, the car's x far to the right of it.
	var start := Vector2(b.position.x - 1.0, b.get_center().y)
	var target := Vector2(b.end.x + 10.0, b.get_center().y)
	var m: Node = spawner.spawn_minion_at(start)
	spawner.enabled = false
	for i in 50 * 30:  # T-443: 30 s, the minion walks 30% slower (4.2 units/s)
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
		run.state.advance(DT)  # the car's invulnerability counts down (T-334)
	push = run.car.pending_knockback()
	var lost: float = health_before - run.state.health
	var interval: float = RunData.new().invulnerability_seconds()  # the car's invulnerability spaces the hits (T-334)
	var rate: float = st["contact_damage"] / interval
	assert_eq(hits, int(seconds / interval), "one hit per invulnerability, the first at once")
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
	run.state.advance(run.state.wreck_seconds)  # past the wreck (T-360)
	assert_false(run.state.is_running())
	var at: Vector2 = m.position
	spawner.step(DT)
	assert_eq(m.position, at)


## T-360, the board's quick tuning (2026-10-29): during the wreck the minions keep
## coming and swarm the car, with no interaction.
func test_minions_swarm_the_wreck_without_touching_it() -> void:
	spawner.enabled = false
	var m: Node = spawner.spawn_minion_at(_car_units() + Vector2(6.0, 0.0))
	run.state.damage_car(10000.0)
	assert_true(run.state.is_wrecked())
	spawner.enabled = true
	var d0: float = m.position_units().distance_to(_car_units())
	var hearts: float = run.state.health
	for i in 150:
		spawner.step(DT)
	assert_lt(m.position_units().distance_to(_car_units()), d0 - 2.0, "it walks to the wreck")
	assert_eq(run.state.health, hearts, "no damage")
	assert_eq(run.car.pending_knockback(), Vector2.ZERO, "no knockback")
	assert_eq(m.contact_cooldown, 0.0, "it never made contact")
	run.state.advance(run.state.wreck_seconds)
	var at: Vector2 = m.position
	spawner.step(DT)
	assert_eq(m.position, at, "still once the run has ended")


func test_minions_far_behind_are_removed() -> void:
	spawner.enabled = false
	var vis: Rect2 = spawner.visible_rect()
	var far_screen := vis.end + vis.size * 1.5
	var far_units: Vector2 = (run.ISO_TRANSFORM.affine_inverse() * far_screen) / 16.0
	# T-405: on the street (a block's short building is a platform now; a minion up there keeps its way to a ramp).
	while not run.map.is_open_spot(far_units, 1.0):
		far_units += Vector2(2.0, 0.0)
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
	var z: int = spawner.depth.z_index_for(behind, (MinionScript.BASE_RADIUS_UNITS * float(EnemyData.new().minion().size_scale)), (MinionScript.BASE_HEIGHT_UNITS * float(EnemyData.new().minion().size_scale)))
	assert_true(z <= slot.z_index - 1, "under the building that covers it")
	assert_eq(z, map.car_z_index(behind, 0.0), "the same place the car gets there")
	m.set_position_units(behind)
	spawner.update_drawing()
	assert_eq(m.sprite.z_index, z)
	assert_eq(m.sprite.position, run.ISO_TRANSFORM * m.position, "drawn at its body in the isometric view")
	# In front of the same slot: over it.
	var front := Vector2(f.get_center().x, f.end.y + 1.0)
	assert_gt(spawner.depth.z_index_for(front, (MinionScript.BASE_RADIUS_UNITS * float(EnemyData.new().minion().size_scale)), (MinionScript.BASE_HEIGHT_UNITS * float(EnemyData.new().minion().size_scale))), slot.z_index, "in front: over it")


func test_placeholders_avoid_heart_red() -> void:
	var sprite_script := preload("res://scripts/enemies/minion_sprite.gd")
	var coin_script := preload("res://scripts/enemies/coin_sprite.gd")
	var colors := [sprite_script.BODY_COLOR, sprite_script.BELLY_COLOR, sprite_script.LEG_COLOR,
		sprite_script.OUTLINE_COLOR, sprite_script.EYE_COLOR,
		coin_script.FACE_COLOR, coin_script.EDGE_COLOR, coin_script.SHINE_COLOR,
		coin_script.OUTLINE_COLOR, coin_script.SHADOW_COLOR]
	for c in colors:
		var reddish: bool = c.r > 0.6 and c.g < 0.35 and c.b < 0.35
		assert_false(reddish, "no red: %s" % c)
	var body: Color = sprite_script.BODY_COLOR
	assert_true(body.g > body.r and body.g > body.b, "the minion is green")



# ---- T-072: the coin art and the brief red tint ----

func _live_minion() -> Node:
	spawner.enabled = false
	return spawner.spawn_minion_at(run.car.position / 16.0 + Vector2(4, 0))


func test_a_damaged_minion_is_tinted_briefly_then_back_to_normal() -> void:
	var m := _live_minion()
	assert_eq(m.sprite.modulate, Color.WHITE)
	m.take_damage(1.0)
	assert_eq(m.sprite.modulate, HitTint.proto().color, "tinted at once")
	m.hit_tint._process(HitTint.proto().seconds * 0.5)
	assert_eq(m.sprite.modulate, HitTint.proto().color, "still tinted halfway")
	m.hit_tint._process(HitTint.proto().seconds)
	assert_eq(m.sprite.modulate, Color.WHITE, "back to normal")
	assert_false(m.hit_tint.is_active())


func test_hit_tint_leaves_another_tint_alone() -> void:
	var m := _live_minion()
	var orange := Color(1, 0.62, 0.38, 1)
	m.sprite.modulate = orange
	m.take_damage(1.0)
	assert_eq(m.sprite.modulate, orange, "the flamethrower's orange is not replaced")
	# red first, then orange (the flamethrower's order): the red ending must not clear the orange
	m.sprite.modulate = Color.WHITE
	m.take_damage(1.0)
	m.sprite.modulate = orange
	m.hit_tint._process(1.0)
	assert_eq(m.sprite.modulate, orange)


func test_the_kill_hit_does_not_flash_and_the_flash_is_the_cars() -> void:
	var m := _live_minion()
	m.take_damage(1000.0)
	assert_false(m.hit_tint.is_active(), "T-404 proposal: a kill skips the flash")
	var d := RunData.new()
	assert_eq(HitTint.proto().color, d.hit_flash_color(), "the car's red, from run.json")
	assert_eq(HitTint.proto().seconds, d.hit_flash_seconds(), "the car's length")


func test_many_minions_flash_with_one_shared_proto_and_stop_processing() -> void:
	var list: Array = []
	for i in 30:
		list.append(spawner.spawn_minion_at(run.car.position / 16.0 + Vector2(4 + i, 0)))
	var proto_before := HitTint.proto()
	for m in list:
		m.take_damage(1.0)
	for m in list:
		assert_eq(m.sprite.modulate, proto_before.color)
		assert_true(m.hit_tint.is_processing())
	for m in list:
		m.hit_tint._process(proto_before.seconds + 0.1)
		m.hit_tint._process(0.0)
		assert_eq(m.sprite.modulate, Color.WHITE)
		assert_false(m.hit_tint.is_processing(), "idle: no per-frame cost")
	assert_same(HitTint.proto(), proto_before, "the numbers are read once")


func test_a_new_hit_restarts_the_flash() -> void:
	var m := _live_minion()
	m.take_damage(1.0)
	m.hit_tint._process(HitTint.proto().seconds * 0.9)
	m.take_damage(1.0)
	m.hit_tint._process(HitTint.proto().seconds * 0.9)
	assert_eq(m.sprite.modulate, HitTint.proto().color, "restarted, still red")


func test_coin_art_has_no_heart_red() -> void:
	var img: Image = preload("res://art/effects/coin.png").get_image()
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.0:
				assert_false(c.r > 0.6 and c.g < 0.35 and c.b < 0.35)


func test_car_damage_shakes_only_the_drawn_car_then_settles() -> void:
	var cs: Sprite2D = run.car_sprite
	var base: Vector2 = cs.offset
	var pos: Vector2 = cs.position
	var car_pos: Vector2 = run.car.position
	run.state.damage_car(5.0)
	assert_true(cs.is_shaking())
	cs._process(0.03)
	assert_ne(cs.offset, base, "the drawing moved")
	assert_eq(cs.position, pos, "the node's position is untouched")
	assert_eq(run.car.position, car_pos, "the car itself is untouched")
	cs._process(0.5)
	assert_false(cs.is_shaking())
	assert_eq(cs.offset, base, "settled back")


# ---- T-167: a weapon's knockback call on minions ----

## Walks `m` towards `target` (as the spawner does) for `steps` physics steps,
## checking after each that its circle stays out of `rect` (if not empty).
func _walk_checking(m: Node, target: Vector2, steps: int, rect := Rect2()) -> void:
	for i in steps:
		m.walk(DT, target)
		if rect.has_area():
			var p: Vector2 = m.position_units()
			var nearest := Vector2(clampf(p.x, rect.position.x, rect.end.x), clampf(p.y, rect.position.y, rect.end.y))
			assert_false(rect.has_point(p), "centre never inside the building")
			assert_gt(p.distance_to(nearest), (MinionScript.BASE_RADIUS_UNITS * float(EnemyData.new().minion().size_scale)) - 0.05, "body never inside the building")


## Walks `m` (as the spawner does) for as long as its knockback lasts, which
## must end within KNOCKBACK_SECONDS of physics steps (plus one for rounding).
func _walk_while_pushed(m: Node, target: Vector2, rect := Rect2()) -> void:
	var max_steps := int(ceil(MinionScript.KNOCKBACK_SECONDS / DT)) + 1
	var steps := 0
	while m.is_knocked_back() and steps < max_steps + 5:
		_walk_checking(m, target, 1, rect)
		steps += 1
	assert_false(m.is_knocked_back(), "the push is over")
	assert_lte(steps, max_steps, "within KNOCKBACK_SECONDS")


func test_knockback_pushes_a_minion_away_in_open_ground() -> void:
	spawner.enabled = false
	var origin := _car_units()
	var start := origin + Vector2(8.0, 3.0)
	var dir := (start - origin).normalized()
	var strength := 1.5
	for k in 5:  # the whole path is open ground
		assert_true(spawner.is_free_spot(start + dir * (strength + 0.6) * k / 4.0), "open ground")
	var m: Node = spawner.spawn_minion_at(start)
	assert_false(m.is_knocked_back(), "not pushed until the call")
	var before: float = m.position_units().distance_to(origin)
	m.apply_knockback(dir * 7.0, strength)  # the direction's length does not matter
	assert_true(m.is_knocked_back())
	_walk_while_pushed(m, origin)  # the car is the walking target, but the push wins
	var moved: Vector2 = m.position_units() - start
	assert_almost_eq(moved.length(), strength, 0.01, "pushed the call's distance in units")
	assert_almost_eq(moved.normalized().dot(dir), 1.0, 0.001, "in the push's direction")
	assert_almost_eq(m.position_units().distance_to(origin) - before, strength, 0.01, "farther from the push's origin")
	# Then it walks towards the car again.
	var after: float = m.position_units().distance_to(origin)
	m.walk(DT, origin)
	assert_lt(m.position_units().distance_to(origin), after, "walks on after the push")


func test_knockback_into_a_building_stops_at_its_wall() -> void:
	spawner.enabled = false
	var b: Rect2 = run.map.rect_of(run.map.layout.buildings[0])
	var start := Vector2(b.position.x - 1.5, b.get_center().y)
	assert_true(spawner.is_free_spot(start))
	var m: Node = spawner.spawn_minion_at(start)
	m.apply_knockback(Vector2.RIGHT, 6.0)  # far more than the 1 unit gap
	_walk_while_pushed(m, start, b)
	var p: Vector2 = m.position_units()
	assert_almost_eq(p.x, b.position.x - (MinionScript.BASE_RADIUS_UNITS * float(EnemyData.new().minion().size_scale)), 0.05, "stopped against the wall")
	assert_almost_eq(p.y, start.y, 0.05, "not slid along a wall it hit head-on")


func test_knockback_into_a_boulder_stops_at_it() -> void:
	spawner.enabled = false
	var bl: Dictionary = run.map.all_boulders()[0]
	var centre := Vector2(float(bl.x), float(bl.y))
	var r: float = float(bl.diameter) / 2.0
	var touching := r + (MinionScript.BASE_RADIUS_UNITS * float(EnemyData.new().minion().size_scale))
	var start := Vector2.ZERO
	var found := false
	for d in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		start = centre + d * (touching + 1.0)
		if spawner.is_free_spot(start) and spawner.is_free_spot(centre + d * (touching + 0.5)):
			found = true
			break
	assert_true(found, "open ground beside the boulder")
	var m: Node = spawner.spawn_minion_at(start)
	m.apply_knockback(centre - start, 6.0)
	var steps := 0
	while m.is_knocked_back() and steps < 100:
		m.walk(DT, start)
		steps += 1
		assert_gt(m.position_units().distance_to(centre), touching - 0.05, "never inside the boulder")
	assert_lt(m.position_units().distance_to(centre), touching + 0.1, "pushed up against it")


func test_knockback_ignores_bad_calls_and_dead_minions() -> void:
	spawner.enabled = false
	var m: Node = spawner.spawn_minion_at(_car_units() + Vector2(8.0, 3.0))
	m.apply_knockback(Vector2.RIGHT, 0.0)
	m.apply_knockback(Vector2.RIGHT, -2.0)
	m.apply_knockback(Vector2.ZERO, 2.0)
	assert_false(m.is_knocked_back(), "zero or negative strength, or no direction: nothing")
	m.take_damage(1000.0)
	m.apply_knockback(Vector2.RIGHT, 2.0)
	assert_false(m.is_knocked_back(), "a dead minion is not pushed")


func test_two_pushes_add_up() -> void:
	spawner.enabled = false
	var start := _car_units() + Vector2(8.0, 3.0)
	var m: Node = spawner.spawn_minion_at(start)
	m.apply_knockback(Vector2.DOWN, 0.5)
	m.walk(DT, _car_units())
	m.apply_knockback(Vector2.DOWN, 0.5)
	_walk_while_pushed(m, _car_units())
	assert_almost_eq(m.position_units().y - start.y, 1.0, 0.02, "both pushes travelled")


func test_only_minions_can_be_pushed() -> void:
	var KaijuScript: Script = load("res://scripts/enemies/kaiju.gd")
	var kaiju: Node = KaijuScript.new()
	assert_false(kaiju.has_method("apply_knockback"), "the kaiju has no knockback call")
	kaiju.free()
	var m: Node = _live_minion()
	assert_true(m.has_method("apply_knockback"))


## T-379: minions are twice as big, from enemies.json's minion.size_scale.
func test_minion_size_comes_from_the_data_and_is_a_whole_number() -> void:
	var sc: float = data.minion().size_scale
	assert_eq(sc, 2.0, "twice as big")
	assert_eq(sc, floorf(sc), "whole number: hard pixel edges")
	var m: Node = spawner.spawn_minion_at(_car_units() + Vector2(10.0, 0.0))
	assert_eq(m.size_scale, sc)
	assert_eq(m.sprite.size_scale, sc, "the drawing follows")
	assert_almost_eq(m.radius_units(), MinionScript.BASE_RADIUS_UNITS * sc, 0.0001)
	assert_almost_eq(m.hit_radius_units(), 1.0, 0.0001, "weapons see the bigger body")
	var shape: CircleShape2D = m.get_node("Body").shape
	assert_almost_eq(shape.radius, 1.0 * 16.0, 0.0001, "collision circle grew")


func test_bigger_minion_touches_the_car_from_farther() -> void:
	var m: Node = spawner.spawn_minion_at(Vector2(0.0, 0.0))
	# Car body half-width 0.5: touching reaches 0.5 + radius 1.0 = 1.5 centre to centre.
	assert_true(m.touches_car(Vector2(1.4, 0.0), 0.0), "old reach was 1.0; now touches at 1.4")
	assert_false(m.touches_car(Vector2(1.6, 0.0), 0.0))


func test_weapon_target_radius_is_the_bigger_body() -> void:
	var m: Node = spawner.spawn_minion_at(_car_units() + Vector2(10.0, 0.0))
	assert_almost_eq(preload("res://scripts/weapons/weapons.gd").radius_of(m), 1.0, 0.0001)


func test_the_navigation_margin_grows_with_the_minion() -> void:
	var nav = preload("res://scripts/enemies/enemy_navigation.gd").new()
	assert_eq(nav.building_margin, 0.5, "default is the old margin")
	assert_eq(preload("res://scripts/enemies/enemy_navigation.gd").BASE_MARGIN * data.minion().size_scale, 1.0)
