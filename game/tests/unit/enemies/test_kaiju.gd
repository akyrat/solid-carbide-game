extends GutTest
## Task T-045: the kaiju appears at boss time just off-screen and walks towards
## the car, can be damaged at any time through the minions' damage function,
## sends its health, damages and knocks back the car on contact, and its death
## adds its coins and ends the run as a win (kaiju_killed called once). Pause,
## a new run, the collision layers, the draw order, the playtest switch.

const RunScene := preload("res://scenes/run/run.tscn")
const KaijuScript := preload("res://scripts/enemies/kaiju.gd")
const KaijuBossScript := preload("res://scripts/enemies/kaiju_boss.gd")
const KaijuSpriteScript := preload("res://scripts/enemies/kaiju_sprite.gd")
const GameScene := preload("res://scenes/game/game.tscn")
const DevSettings := preload("res://scripts/run/dev_settings.gd")
const TEST_PLAYTEST := "user://test_playtest_t045.json"
const DT := 0.02  # one physics step (50 per second)

var run: Node2D
var boss: Node
var data: EnemyData


func before_each() -> void:
	run = RunScene.instantiate()
	add_child_autofree(run)
	boss = run.kaiju_boss
	boss.rng.seed = 45
	run.minions.enabled = false  # the kaiju on its own
	run.car.use_keyboard = false
	data = EnemyData.new()


func after_each() -> void:
	get_tree().paused = false
	DevSettings.enabled = false  # as the suite's pre-run hook leaves it
	DevSettings.file = DevSettings.FILE
	DirAccess.remove_absolute(TEST_PLAYTEST)


## Writes a dev settings file for the test and points the dev settings at it.
func _use_playtest(d: Dictionary) -> void:
	var f := FileAccess.open(TEST_PLAYTEST, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	DevSettings.enabled = true
	DevSettings.file = TEST_PLAYTEST


func _car_units() -> Vector2:
	return run.car.position / 16.0


## Moves the run's clock to boss time (7 minutes in), firing the signal.
func _to_boss_time() -> void:
	run.state.advance(RunState.RUN_SECONDS - RunState.BOSS_TIME_LEFT - run.state.time_elapsed() + 0.01)


## A free spot `distance` units from the car, for placing the kaiju by hand.
func _free_spot_near(distance: float) -> Vector2:
	for i in 64:
		var p := _car_units() + Vector2.RIGHT.rotated(TAU * i / 64.0) * distance
		if boss.is_free_spot(p):
			return p
	fail_test("no free spot %.1f units from the car" % distance)
	return _car_units() + Vector2(distance, 0)


func test_run_has_the_boss_and_no_kaiju_before_boss_time() -> void:
	assert_not_null(boss, "run.kaiju_boss")
	assert_eq(boss.state, run.state)
	assert_eq(boss.car, run.car)
	assert_eq(boss.bodies_root.get_parent(), run.physics_world, "body in the flat physics world")
	assert_eq(boss.draw_root, run.minions.draw_root, "drawn in the enemies' node, before the car's View")
	run.state.advance(300.0)
	for i in 20:
		boss.step(DT)
	assert_null(boss.kaiju, "no kaiju before boss time")
	assert_eq(get_tree().get_nodes_in_group("kaiju").size(), 0)


func test_boss_time_makes_the_kaiju_appear_off_screen_and_walk_towards_the_car() -> void:
	var appeared := []
	boss.kaiju_appeared.connect(func(k: Node) -> void: appeared.append(k))
	_to_boss_time()
	var k: Node = boss.kaiju
	assert_not_null(k, "the kaiju appeared on boss time")
	assert_eq(appeared.size(), 1, "kaiju_appeared once")
	assert_true(k.is_in_group("enemies"), "weapons find it with the minions")
	# Just off-screen: its whole drawing outside the visible screen, but near it.
	var vis: Rect2 = boss.visible_rect()
	var foot: Vector2 = run.ISO_TRANSFORM * k.position
	var drawn := Rect2(foot - Vector2(KaijuScript.RADIUS_UNITS * 16.0 * 1.5, KaijuScript.HEIGHT_UNITS * 16.0),
		Vector2(KaijuScript.RADIUS_UNITS * 16.0 * 3.0, KaijuScript.HEIGHT_UNITS * 16.0 + KaijuScript.RADIUS_UNITS * 16.0))
	assert_false(vis.intersects(drawn), "off the visible screen")
	assert_true(boss.arrival_ring().grow(1.0).has_point(foot), "just beyond the screen's edge")
	assert_true(boss.is_free_spot(k.position_units()), "not on a building or boulder")
	# It walks towards the car at the data's speed.
	var speed: float = data.kaiju()["move_speed"]
	var before: float = k.position_units().distance_to(_car_units())
	var steps := 50
	for i in steps:
		boss.step(DT)
	var after: float = k.position_units().distance_to(_car_units())
	assert_lt(after, before, "closer to the car")
	assert_almost_eq(before - after, speed * steps * DT, 0.25, "slowly, at about the data's speed")
	assert_lt(speed, data.minion()["move_speed"], "slower than a minion")
	# One kaiju per run.
	run.state.boss_time.emit()
	assert_eq(boss.kaiju, k, "boss time again does not bring a second one")
	assert_eq(get_tree().get_nodes_in_group("kaiju").size(), 1)


func test_kaiju_walks_straight_at_the_car_in_the_open() -> void:
	var start := _free_spot_near(12.0)
	var k: Node = boss.appear_at(start)
	var before: float = k.position_units().distance_to(_car_units())
	for i in 25:
		k.walk(DT, _car_units())
	var speed: float = data.kaiju()["move_speed"]
	assert_almost_eq(before - k.position_units().distance_to(_car_units()), speed * 25 * DT, 0.01, "the data's speed")
	var dir: Vector2 = (k.position_units() - start).normalized()
	assert_almost_eq(dir.dot((_car_units() - start).normalized()), 1.0, 0.001, "straight at the car")


func test_kaiju_walks_round_a_building() -> void:
	var b: Rect2 = run.map.rect_of(run.map.layout.buildings[0])
	var r: float = KaijuScript.RADIUS_UNITS
	var start := Vector2(b.position.x - r - 0.5, b.get_center().y)
	var target := Vector2(b.end.x + 12.0, b.get_center().y)
	var k: Node = boss.appear_at(start)
	for i in 50 * 60:
		k.walk(DT, target)
		var u: Vector2 = k.position_units()
		var nearest := Vector2(clampf(u.x, b.position.x, b.end.x), clampf(u.y, b.position.y, b.end.y))
		assert_gt(u.distance_to(nearest), r - 0.1, "never into the building")
		if k.position_units().distance_to(target) < 2.0:
			break
	assert_lt(k.position_units().distance_to(target), 2.0, "got round it")


func test_weapon_damage_lowers_health_as_soon_as_it_appears_and_sends_health() -> void:
	var sent := []
	boss.kaiju_health_changed.connect(func(h: float, m: float) -> void: sent.append([h, m]))
	_to_boss_time()
	var k: Node = boss.kaiju
	var hp: float = data.kaiju()["health"]
	assert_eq(k.health, hp, "the data's health")
	assert_eq(k.max_health, hp)
	assert_eq(boss.kaiju_health(), hp, "readable for the HUD")
	assert_eq(sent.back(), [hp, hp], "health sent when it appears")
	var own := []
	k.health_changed.connect(func(h: float, m: float) -> void: own.append([h, m]))
	# A weapon finds it the way it finds minions, and damages it at once.
	var targets := get_tree().get_nodes_in_group("enemies")
	assert_true(targets.has(k), "in the enemies group")
	targets[targets.find(k)].take_damage(7.0)
	assert_eq(k.health, hp - 7.0, "health went down right after it appeared")
	assert_eq(boss.kaiju_health(), hp - 7.0)
	assert_eq(own, [[hp - 7.0, hp]], "the kaiju's health_changed fired")
	assert_eq(sent.back(), [hp - 7.0, hp], "relayed by the boss for the HUD")
	k.take_damage(0.0)
	k.take_damage(-3.0)
	assert_eq(k.health, hp - 7.0, "zero and negative damage ignored")
	assert_eq(own.size(), 1)


func test_projectile_area_on_the_enemies_mask_finds_the_kaiju() -> void:
	var k: Node = boss.appear_at(_free_spot_near(10.0))
	await wait_physics_frames(2)
	var q := PhysicsPointQueryParameters2D.new()
	q.position = k.global_position
	q.collision_mask = 4
	q.collide_with_bodies = true
	var hits: Array = k.get_world_2d().direct_space_state.intersect_point(q)
	var found := hits.any(func(h) -> bool: return h.collider == k)
	assert_true(found, "a mask of 4 (enemies layer) finds the kaiju's body")


func test_killing_the_kaiju_adds_its_coins_and_calls_kaiju_killed_once() -> void:
	_to_boss_time()
	var k: Node = boss.kaiju
	var calls := {"killed": 0, "ended": [], "coins_at_end": -1}
	# Count calls to the run's kaiju_killed() through its effect: the run ends as a win once.
	run.state.run_ended.connect(func(r: String, c: int) -> void:
		calls.ended.append(r)
		calls.coins_at_end = c)
	boss.kaiju_defeated.connect(func(_n: int) -> void: calls.killed += 1)
	var died := []
	k.died.connect(func(who: Node, _at: Vector2) -> void: died.append(who))
	run.state.add_coins(3)
	var hp: float = data.kaiju()["health"]
	k.take_damage(hp - 1.0)
	assert_false(k.is_dead(), "alive at 1")
	assert_true(run.state.is_running())
	k.take_damage(1.0)
	assert_true(k.is_dead(), "dead at 0")
	assert_eq(died.size(), 1, "died once")
	assert_eq(calls.killed, 1, "defeated once")
	assert_eq(calls.ended, ["win"], "kaiju_killed ended the run once, as a win")
	assert_eq(run.state.result, "win")
	var kc := data.kaiju_coins_on_defeat()
	assert_eq(calls.coins_at_end, 3 + kc, "its coins counted in the run_ended coins")
	assert_eq(run.state.coins, 3 + kc)
	k.take_damage(5.0)
	assert_eq(died.size(), 1, "dies once")
	assert_eq(calls.ended.size(), 1, "the run ends once")
	assert_null(boss.kaiju, "no live kaiju")
	assert_false(k.is_in_group("enemies"))
	await wait_process_frames(2)
	assert_false(is_instance_valid(k), "removed")


func test_kaiju_killed_called_exactly_once_on_the_state() -> void:
	# A stand-in state that counts kaiju_killed() calls.
	var counter := KaijuKilledCounter.new()
	add_child_autofree(counter)
	boss.state = counter
	var k: Node = boss.appear_at(_free_spot_near(10.0))
	k.take_damage(1e9)
	k.take_damage(1e9)
	assert_eq(counter.killed_calls, 1, "kaiju_killed() called once")
	assert_eq(counter.coins_before_killed, data.kaiju_coins_on_defeat(), "coins added before it")


func test_contact_damages_the_car_and_knocks_it_back() -> void:
	var st := data.kaiju()
	var offset := Vector2(KaijuScript.RADIUS_UNITS + 0.4, 0.0).rotated(run.car.rotation)
	var k: Node = boss.appear_at(_car_units() + offset)
	assert_true(k.touches_car(_car_units(), run.car.rotation))
	var health_before: float = run.state.health
	var seconds := 2.0
	var hits := 0
	for i in int(round(seconds / DT)):
		k.set_position_units(_car_units() + offset)
		if k.contact_step(DT, run.car, run.state):
			hits += 1
	var push: Vector2 = run.car.pending_knockback()
	assert_eq(hits, int(seconds / st["contact_damage_interval"]), "one hit per interval, the first at once")
	assert_almost_eq(health_before - run.state.health, st["contact_damage"] * hits, 0.0001, "the data's damage")
	assert_almost_eq(push.length(), st["knockback"] * hits, 0.001, "the data's knockback each hit")
	assert_almost_eq(push.normalized().dot(-offset.normalized()), 1.0, 0.001, "away from the kaiju")
	var car_before := _car_units()
	run.car.physics_step()
	assert_gt((_car_units() - car_before).dot(-offset), 0.0, "the car moves away")


func test_contact_through_the_boss_step() -> void:
	var offset := Vector2(0.0, KaijuScript.RADIUS_UNITS + 0.3).rotated(run.car.rotation)
	boss.appear_at(_car_units() + offset)
	var before: float = run.state.health
	boss.step(DT)
	assert_almost_eq(before - run.state.health, data.kaiju()["contact_damage"], 0.0001, "hit on the first step")
	assert_gt(run.car.pending_knockback().length(), 0.0, "knocked back")


func test_no_damage_without_touching() -> void:
	var k: Node = boss.appear_at(_free_spot_near(8.0))
	var before: float = run.state.health
	for i in 20:
		k.contact_step(DT, run.car, run.state)
	assert_eq(run.state.health, before)
	assert_eq(run.car.pending_knockback(), Vector2.ZERO)


func test_kaiju_stands_still_while_paused() -> void:
	var k: Node = boss.appear_at(_free_spot_near(12.0))
	await wait_physics_frames(3)
	get_tree().paused = true
	var frozen: Vector2 = k.position
	await wait_physics_frames(20)
	assert_eq(k.position, frozen, "paused: it does not move")
	get_tree().paused = false
	await wait_physics_frames(5)
	assert_ne(k.position, frozen, "unpaused: it walks again")


func test_nothing_moves_after_the_run_ends() -> void:
	var k: Node = boss.appear_at(_free_spot_near(12.0))
	run.state.damage_car(100000.0)
	var at: Vector2 = k.position
	boss.step(DT)
	assert_eq(k.position, at)


func test_new_run_removes_the_kaiju_and_it_comes_back_at_boss_time() -> void:
	_to_boss_time()
	var k: Node = boss.kaiju
	var sprite: Node2D = k.sprite
	run.start_run()
	assert_null(boss.kaiju, "no kaiju at the start of a new run")
	assert_false(boss.has_appeared())
	assert_eq(boss.car, run.car, "follows the new car")
	await wait_process_frames(2)
	assert_false(is_instance_valid(k), "the old one is gone")
	assert_false(is_instance_valid(sprite), "and its drawing")
	_to_boss_time()
	assert_not_null(boss.kaiju, "it appears again at the new run's boss time")


func test_layers_follow_the_collision_table() -> void:
	var k: Node = boss.appear_at(_free_spot_near(10.0))
	assert_eq(k.collision_layer, 4, "enemies layer (3), like the minions")
	assert_eq(k.collision_mask, 1, "obstacles only: never pushes the car")
	assert_true(k.is_in_group("enemies"))
	assert_true(k.is_in_group("kaiju"))
	assert_false(k.is_in_group("minions"))
	assert_true(k.has_method("take_damage") and k.has_method("position_units") and k.has_method("is_dead"))


func test_draw_order_follows_the_buildings() -> void:
	var map: Node2D = run.map
	var k: Node = boss.appear_at(_free_spot_near(12.0))
	boss.update_drawing()
	assert_eq(k.sprite.position, run.ISO_TRANSFORM * k.position, "drawn at its body in the isometric view")
	var slot = map.fade_items()[0]
	var f: Rect2 = slot.footprint
	var behind := Vector2(f.get_center().x, f.position.y - KaijuScript.RADIUS_UNITS - 1.0)
	k.set_position_units(behind)
	boss.update_drawing()
	assert_true(k.sprite.z_index <= slot.z_index - 1, "behind a building: under it")
	var front := Vector2(f.get_center().x, f.end.y + KaijuScript.RADIUS_UNITS + 1.0)
	k.set_position_units(front)
	boss.update_drawing()
	assert_gt(k.sprite.z_index, slot.z_index, "in front: over it")


func test_placeholder_is_large_and_not_redgull_red() -> void:
	var colors := [KaijuSpriteScript.BODY_COLOR, KaijuSpriteScript.BELLY_COLOR, KaijuSpriteScript.PLATE_COLOR,
		KaijuSpriteScript.OUTLINE_COLOR, KaijuSpriteScript.EYE_COLOR, KaijuSpriteScript.SHADOW_COLOR]
	for c in colors:
		var reddish: bool = c.r > 0.6 and c.g < 0.35 and c.b < 0.35
		assert_false(reddish, "no red: %s" % c)
	assert_gte(KaijuScript.RADIUS_UNITS * 2.0, 4.0 * 1.0, "four times the car's 1-unit width across")
	assert_gte(KaijuScript.HEIGHT_UNITS, 2.0 * 3.0, "over twice the car's 3-unit length tall")
	assert_eq(KaijuSpriteScript.RADIUS_UNITS, KaijuScript.RADIUS_UNITS, "drawing and body the same size")
	assert_eq(KaijuSpriteScript.HEIGHT_UNITS, KaijuScript.HEIGHT_UNITS)


func test_hit_radius_matches_its_body_on_the_ground() -> void:
	var k: Node = boss.appear_at(_free_spot_near(10.0))
	assert_true(k.has_method("hit_radius_units"), "weapons read hit_radius_units()")
	var shape: CircleShape2D = k.get_node("Body").shape
	assert_almost_eq(k.hit_radius_units(), shape.radius / 16.0, 0.0001, "the collision circle's radius, in units")
	assert_eq(k.hit_radius_units(), KaijuScript.RADIUS_UNITS)
	assert_eq(k.hit_radius_units(), KaijuSpriteScript.RADIUS_UNITS, "the drawn ground circle's size")


func test_dev_timer_starts_a_run_from_the_main_menu_with_that_time_and_the_kaiju_at_boss_time() -> void:
	_use_playtest({"flamethrower_at_start": true,
		"run_timer_start": {"enabled": true, "minutes": 1, "seconds": 5}})
	var game: Node = GameScene.instantiate()
	game.quit_game = func(): pass
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()
	var r: Node2D = game.run
	var st: RunState = r.state
	r.minions.enabled = false
	r.car.use_keyboard = false
	assert_eq(st.time_left_text(), "1:05", "the run starts with the set time on the clock")
	assert_eq(r.hud.timer_label.text, "1:05", "and the HUD shows it")
	assert_almost_eq(st.time_elapsed(), 415.0, 0.001, "fast-forwarded: 6:55 into the run")
	assert_eq(r.minions.minions_wanted_now(), data.minions_wanted(415.0), "minion numbers of that moment")
	var heard := []
	st.boss_time.connect(func() -> void: heard.append(true))
	st.advance(4.9)
	assert_eq(heard.size(), 0, "no boss time before 1:00")
	assert_null(r.kaiju_boss.kaiju, "no kaiju before 1:00")
	st.advance(0.2)
	assert_eq(heard.size(), 1, "boss time at 1:00 left")
	assert_not_null(r.kaiju_boss.kaiju, "the kaiju arrives on boss time")
	# A second run from the menu starts at the set time again.
	r.start_run()
	assert_eq(st.time_left_text(), "1:05")
	assert_null(r.kaiju_boss.kaiju)


func test_dev_timer_off_missing_or_invalid_gives_8_00() -> void:
	assert_eq(DevSettings.run_start_time_left(), 480.0, "the suite runs with dev settings off")
	_use_playtest({"run_timer_start": {"enabled": true, "minutes": 2, "seconds": 30}})
	assert_eq(DevSettings.run_start_time_left(), 150.0, "on: minutes and seconds")
	DevSettings.enabled = false
	assert_eq(DevSettings.run_start_time_left(), 480.0, "dev settings off: 8:00")
	DevSettings.enabled = true
	_use_playtest({"run_timer_start": {"enabled": false, "minutes": 1, "seconds": 30}})
	assert_eq(DevSettings.run_start_time_left(), 480.0, "enabled false: 8:00")
	_use_playtest({"other_setting": 1})
	assert_eq(DevSettings.run_start_time_left(), 480.0, "no run_timer_start: 8:00")
	_use_playtest({"run_timer_start": {"enabled": true, "minutes": 0, "seconds": 0}})
	assert_eq(DevSettings.run_start_time_left(), 480.0, "0:00 is not a run: 8:00")
	_use_playtest({"run_timer_start": {"enabled": true, "minutes": 12, "seconds": 0}})
	assert_eq(DevSettings.run_start_time_left(), 480.0, "never over 8:00")
	assert_eq(DevSettings.run_start_time_left("no_such_file"), 480.0, "missing file: 8:00")


func test_a_run_started_with_less_time_stays_consistent() -> void:
	var st := RunState.new()
	add_child_autofree(st)
	st.start_time_left = 90.0
	st.start_run()
	assert_eq(st.time_left_text(), "1:30")
	assert_almost_eq(st.time_elapsed(), 390.0, 0.001)
	var heard := []
	st.boss_time.connect(func() -> void: heard.append(true))
	st.advance(29.0)
	assert_eq(heard.size(), 0)
	st.advance(1.5)
	assert_eq(heard.size(), 1, "boss time once, at 1:00 left")
	st.advance(60.0)
	assert_eq(st.result, "loss", "the clock still ends the run at 0:00")
	st.start_run()
	assert_eq(st.time_left_text(), "1:30", "a new run starts at the same time")
	assert_true(st.is_running())
	# Under a minute: boss time on the first tick.
	st.start_time_left = 45.0
	st.start_run()
	st.advance(0.01)
	assert_eq(heard.size(), 2, "boss time at once when the run starts under 1:00 left")


func test_committed_playtest_file_has_the_dev_timer() -> void:
	var r := GameData.load_file("playtest")
	assert_true(r.ok, "data/playtest.json loads: %s" % r.get("error", ""))
	var s: Dictionary = r.data["run_timer_start"]
	assert_true(s.has("enabled") and s.has("minutes") and s.has("seconds"))
	assert_false(r.data.has("kaiju_early_arrival"), "the old early-arrival switch is gone")


class KaijuKilledCounter:
	extends Node
	var killed_calls := 0
	var coins := 0
	var coins_before_killed := -1

	func is_running() -> bool:
		return killed_calls == 0

	func add_coins(n: int) -> void:
		coins += n

	func damage_car(_amount: float) -> void:
		pass

	func time_elapsed() -> float:
		return 0.0

	func kaiju_killed() -> void:
		killed_calls += 1
		if killed_calls == 1:
			coins_before_killed = coins
