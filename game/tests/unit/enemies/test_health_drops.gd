extends GutTest
## Task T-220: minions drop health pickups at the data's chance, where they died
## and at their height; driving over one restores 30% of the maximum health,
## capped; the numbers come from enemies.json; pause and a new run.

const RunScene := preload("res://scenes/run/run.tscn")
const SpriteScript := preload("res://scripts/enemies/health_pickup_sprite.gd")

var run: Node2D
var spawner: Node
var data: EnemyData


func before_each() -> void:
	run = RunScene.instantiate()
	add_child_autofree(run)
	spawner = run.minions
	spawner.rng.seed = 220
	spawner.enabled = false
	data = EnemyData.new()


func after_each() -> void:
	get_tree().paused = false


func _car_units() -> Vector2:
	return run.car.position / 16.0


func test_data_has_the_numbers() -> void:
	var d := data.health_drops()
	assert_eq(d["drop_chance"], 0.3)
	assert_eq(data.coins()["drop_chance"], 0.6, "the coins' rate is unchanged")
	assert_almost_eq(float(d["drop_chance"]) * 2.0, float(data.coins()["drop_chance"]), 0.0001, "half the coins' rate")
	assert_eq(d["restore_fraction"], 0.3)


func test_drops_at_about_the_data_chance_where_it_died() -> void:
	var d := data.health_drops()
	var kills := 600
	var spots: Array = []
	for i in kills:
		var at := _car_units() + Vector2(6.0, 0.0)
		var m: Node = spawner.spawn_minion_at(at)
		var before: int = spawner.health_pickups.size()
		m.take_damage(1000.0)
		if spawner.health_pickups.size() > before:
			spots.append(Vector2(spawner.health_pickups[-1].position_units() - at))
	var share := float(spawner.health_pickups.size()) / kills
	gut.p("health drops %d of %d (%.3f)" % [spawner.health_pickups.size(), kills, share])
	assert_almost_eq(share, d["drop_chance"], 0.06)
	for off in spots:
		assert_lt(off.length(), 0.001, "dropped where the minion died")


func test_health_drops_are_about_half_the_coins_over_many_kills() -> void:
	var kills := 1000
	var coin_drops := 0
	var health_drops := 0
	for i in kills:
		var at := _car_units() + Vector2(6.0, 0.0)
		var m: Node = spawner.spawn_minion_at(at)
		var c0: int = spawner.coins.size()
		var h0: int = spawner.health_pickups.size()
		m.take_damage(1000.0)
		coin_drops += 1 if spawner.coins.size() > c0 else 0
		health_drops += 1 if spawner.health_pickups.size() > h0 else 0
	gut.p("coin drops %d, health drops %d of %d" % [coin_drops, health_drops, kills])
	assert_almost_eq(float(health_drops) / maxf(1.0, float(coin_drops)), 0.5, 0.12)


func test_the_chance_is_read_from_the_data() -> void:
	spawner._health_drops = {"drop_chance": 0.0, "restore_fraction": 0.3}
	for i in 50:
		spawner.spawn_minion_at(_car_units() + Vector2(6.0, 0.0)).take_damage(1000.0)
	assert_eq(spawner.health_pickups.size(), 0, "chance 0: none")
	spawner._health_drops = {"drop_chance": 1.0, "restore_fraction": 0.5}
	for i in 5:
		spawner.spawn_minion_at(_car_units() + Vector2(6.0, 0.0)).take_damage(1000.0)
	assert_eq(spawner.health_pickups.size(), 5, "chance 1: always")
	assert_eq(spawner.health_pickups[0].restore_fraction, 0.5, "the fraction from the data too")


func test_drop_sits_at_the_height_it_died_at() -> void:
	var units := _car_units() + Vector2(6.0, 0.0)
	var p: Node = spawner.spawn_health_pickup_at(units)
	var h: float = preload("res://scripts/enemies/enemy_height.gd").height_at(spawner.ground, units)
	var expected: Vector2 = spawner.ISO_TRANSFORM * p.position + Vector2(0.0, -h * 16.0)
	assert_eq(p.sprite.position, expected, "drawn at the ground's height")


func test_healing_is_30_percent_of_max_and_capped() -> void:
	var st: Node = run.state
	st.health = 20.0
	var pickup: Node = spawner.spawn_health_pickup_at(_car_units() + Vector2(20.0, 0.0))
	var want: float = 0.3 * st.max_health
	pickup.collect()
	assert_almost_eq(st.health, 20.0 + want, 0.001, "30% of the maximum")
	st.health = st.max_health - 1.0
	spawner.spawn_health_pickup_at(_car_units() + Vector2(20.0, 0.0)).collect()
	assert_eq(st.health, st.max_health, "never above the maximum")
	spawner.spawn_health_pickup_at(_car_units() + Vector2(20.0, 0.0)).collect()
	assert_eq(st.health, st.max_health, "a full car stays full (and the pickup is used up)")


func test_collects_once_and_does_not_cut_the_combo() -> void:
	var st: Node = run.state
	st.health = 10.0
	var pickup: Node = spawner.spawn_health_pickup_at(_car_units() + Vector2(20.0, 0.0))
	assert_eq(pickup.collision_layer, 8, "pickups layer")
	assert_eq(pickup.collision_mask, 2, "notices only the car")
	pickup.collect()
	var after: float = st.health
	pickup.collect()
	assert_eq(st.health, after, "once only")


func test_driving_over_it_heals() -> void:
	run.car.use_keyboard = false
	run.state.health = 10.0
	var p: Node = spawner.spawn_health_pickup_at(_car_units() + Vector2(0.0, -5.0))
	var sprite: Node2D = p.sprite
	run.car.scripted_input = [true, false, 0.0]
	var frames := 0
	while is_instance_valid(p) and not p.is_taken() and frames < 100:
		await wait_physics_frames(1)
		run.state.health = minf(run.state.health, run.state.health)
		frames += 1
	assert_gt(run.state.health, 10.0, "health went up")
	await wait_process_frames(2)
	assert_false(is_instance_valid(p), "the pickup is gone")
	assert_false(is_instance_valid(sprite), "and its drawing")


func test_stands_still_while_paused_and_is_gone_in_a_new_run() -> void:
	var p: Node = spawner.spawn_health_pickup_at(_car_units() + Vector2(8.0, 3.0))
	await wait_physics_frames(2)
	get_tree().paused = true
	var frozen: Vector2 = p.position
	var sprite_pos: Vector2 = p.sprite.position
	await wait_physics_frames(20)
	assert_eq(p.position, frozen)
	assert_eq(p.sprite.position, sprite_pos)
	get_tree().paused = false
	run.start_run()
	assert_eq(spawner.health_pickups.size(), 0, "none in a new run")
	await wait_process_frames(2)
	assert_false(is_instance_valid(p), "freed")
	assert_eq(spawner.draw_root.get_child_count(), 0, "no drawings left")


func test_the_group_finds_it_and_coins_still_work() -> void:
	var p: Node = spawner.spawn_health_pickup_at(_car_units() + Vector2(8.0, 3.0))
	var coin: Node = spawner.spawn_coin_at(_car_units() + Vector2(9.0, 3.0))
	assert_true(p.is_in_group("health_pickups"))
	assert_false(p.is_in_group("coins"))
	assert_true(coin.is_in_group("coins"))
	coin.collect()
	assert_eq(run.state.coins, 1)


func test_canister_art_is_not_redgull_red() -> void:
	# T-221: the final art. Redgull's red is (135,17,27); no pixel may be near it, and the
	# sprite is about a coin's size with hard (fully opaque or transparent) pixels.
	var img: Image = SpriteScript.CANISTER_TEXTURE.get_image()
	assert_lte(img.get_width(), 16, "about a coin wide")
	assert_lte(img.get_height(), 12, "about a coin high")
	var redgull := Vector3(135.0, 17.0, 27.0)
	var white := 0
	for y in img.get_height():
		for x in img.get_width():
			var c: Color = img.get_pixel(x, y)
			assert_true(c.a == 0.0 or c.a == 1.0, "no semi-transparent pixels")
			if c.a == 0.0:
				continue
			var v := Vector3(c.r8, c.g8, c.b8)
			assert_gt(v.distance_to(redgull), 45.0, "far from Redgull's red")
			if c.r8 > 240 and c.g8 > 240 and c.b8 > 240:
				white += 1
	assert_eq(white, 5, "the white cross is five pixels (a plus)")
