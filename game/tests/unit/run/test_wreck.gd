extends GutTest
## Task T-360: wrecked. When the last heart is gone the run is lost at once, but
## run_ended waits for the wreck's seconds (run.json's wreck.seconds, 3 s) while
## the car slides on with dead controls, smoking and burning.

const RunStateScript := preload("res://scripts/run/run_state.gd")
const RunScene := preload("res://scenes/run/run.tscn")
const CarScript := preload("res://scripts/driving/car.gd")
const WreckEffectScript := preload("res://scripts/run/wreck_effect.gd")
const STEP := 1.0 / 60.0
## Greenbull's colours (Visual style, Content, "Rules", rule 6).
const GREENBULL := [Color8(12, 76, 44), Color8(104, 220, 96), Color8(247, 208, 52)]

var state: RunState
var ended: Array = []
var wrecks: Array = []


func before_each() -> void:
	state = RunStateScript.new()
	add_child_autofree(state)
	ended = []
	wrecks = []
	state.run_ended.connect(func(r: String, c: int) -> void: ended.append([r, c]))
	state.wreck_started.connect(func(s: float) -> void: wrecks.append(s))
	state.start_run()


func after_each() -> void:
	get_tree().paused = false


func _lose_last_heart() -> void:
	state.health = 1.0
	state.damage_car(1.0)


# --- The run's state -------------------------------------------------------------

func test_the_wreck_lasts_3_seconds_from_the_data_file() -> void:
	assert_eq(RunData.new().wreck_seconds(), 3.0, "run.json's wreck.seconds")
	assert_eq(state.wreck_seconds, 3.0)


func test_the_last_heart_starts_the_wreck_and_decides_the_loss() -> void:
	state.add_coins(4)
	_lose_last_heart()
	assert_eq(wrecks, [3.0])
	assert_true(state.is_wrecked())
	assert_false(state.is_running(), "nothing counts any more")
	assert_eq(state.result, "loss")
	assert_eq(state.recap().result, "loss")
	assert_eq(state.recap().loss_reason, "health")
	assert_eq(ended, [], "run_ended waits for the wreck")


func test_run_ended_comes_3_seconds_later_with_the_same_result_and_coins() -> void:
	state.add_coins(7)
	_lose_last_heart()
	var t := 0.0
	while ended.is_empty() and t < 10.0:
		state.advance(STEP)
		t += STEP
	assert_almost_eq(t, 3.0, 0.1, "3 s +- 0.1")
	assert_eq(ended, [["loss", 7]])
	assert_false(state.is_wrecked())
	state.advance(10.0)
	assert_eq(ended.size(), 1, "once")
	assert_eq(state.recap().loss_reason, "health", "the recap still says the health loss")


func test_the_clock_stops_at_the_last_heart() -> void:
	state.advance(100.0)
	_lose_last_heart()
	var left := state.time_left
	state.advance(2.0)
	assert_eq(state.time_left, left)
	assert_almost_eq(float(state.recap().time_survived), 100.0, 0.001)


func test_nothing_counts_during_the_wreck() -> void:
	state.add_coins(2)
	var xp := state.xp
	var combo := state.combo
	var level := state.level
	_lose_last_heart()
	state.add_coins(5)
	state.damage_car(1.0)
	state.add_xp(500.0)
	state.challenge_completed("c")
	state.drift_step(true, 2.0)
	state.add_trick("three_sixty")
	state.add_airtime_trick(3.0)
	state.add_needle_trick()
	state.open_choice(2)  # a gift pack picked up
	state.enemy_slain("minion", "gun")
	state.kaiju_killed()
	assert_eq(state.coins, 2, "no coins")
	assert_eq(state.health, 0.0, "no damage, no healing")
	assert_eq(state.xp, xp, "no likes")
	assert_eq(state.level, level)
	assert_eq(state.combo, combo, "no tricks")
	assert_false(state.is_waiting_for_choice(), "no gift pack")
	assert_eq(state.recap().enemies_slain, {})
	assert_eq(ended, [], "a kaiju kill does not end it early")
	state.advance(3.0)
	assert_eq(ended, [["loss", 2]], "still the health loss")


func test_a_kaiju_kill_ends_at_once_and_the_time_up_has_no_wreck() -> void:
	state.kaiju_killed()
	assert_eq(ended, [["win", 0]])
	assert_eq(wrecks, [])
	state.start_run()
	state.advance(RunState.RUN_SECONDS + 1.0)
	state.advance(state.time_up_seconds)  # its own time's up screen (T-317)
	assert_eq(ended, [["win", 0], ["loss", 0]])
	assert_eq(state.loss_reason, "time")
	assert_eq(wrecks, [], "no wreck for the time's up")


func test_pause_freezes_the_wreck() -> void:
	_lose_last_heart()
	get_tree().paused = true
	var left := state.wreck_left
	await get_tree().create_timer(0.3, true).timeout
	assert_eq(state.wreck_left, left, "paused: the wreck waits")
	get_tree().paused = false
	await get_tree().create_timer(0.3).timeout
	assert_lt(state.wreck_left, left, "unpaused: it counts down again")
	assert_eq(ended, [])


func test_a_new_run_clears_the_wreck() -> void:
	_lose_last_heart()
	state.start_run()
	assert_false(state.is_wrecked())
	assert_true(state.is_running())
	state.advance(5.0)
	assert_eq(ended, [], "the old wreck never ends the new run")


func test_0_seconds_ends_at_once() -> void:
	state.wreck_seconds = 0.0
	_lose_last_heart()
	assert_eq(ended, [["loss", 0]])


# --- A health pickup revives the wreck (T-406) ----------------------------------------

func test_a_health_pickup_revives_with_one_heart_and_no_recap() -> void:
	var revived: Array = []
	state.revived.connect(func() -> void: revived.append(true))
	state.add_coins(3)
	state.max_health = 5.0
	state.advance(50.0)
	_lose_last_heart()
	state.advance(1.0)
	assert_eq(state.heal_car(2.0), 1.0, "1 heart, whatever the pickup restores")
	assert_eq(revived.size(), 1)
	assert_eq(state.hearts, 1)
	assert_false(state.is_wrecked())
	assert_true(state.is_running(), "the run goes on")
	assert_eq(state.result, "")
	assert_eq(state.recap().result, "", "the recap is live again")
	state.advance(10.0)
	assert_eq(ended, [], "no run_ended, so no recap")
	assert_lt(state.time_left, RunState.RUN_SECONDS - 50.0, "the clock runs again")
	state.add_coins(2)
	assert_eq(state.coins, 5, "coins count again")


func test_the_revive_is_invulnerable_for_the_usual_second() -> void:
	_lose_last_heart()
	state.heal_car(1.0)
	assert_true(state.is_invulnerable())
	assert_almost_eq(state.invulnerable_left, RunData.new().invulnerability_seconds(), 0.001)
	state.damage_car(1.0)
	assert_eq(state.hearts, 1, "the swarm cannot finish it at once")
	state.advance(state.invulnerable_left + 0.01)
	state.damage_car(1.0)
	assert_true(state.is_wrecked(), "after it, a hit wrecks it again")


func test_the_combo_stays_cut_and_viewers_keep_their_peak() -> void:
	state.add_trick("three_sixty")
	var peak: float = state.recap().peak_viewers
	_lose_last_heart()
	var combo := state.combo
	state.heal_car(1.0)
	assert_eq(state.combo, combo, "the combo the fatal hit left")
	assert_gte(float(state.recap().peak_viewers), peak, "the peak is not lost")


func test_no_pickup_no_revive_and_the_wreck_ends_as_before() -> void:
	_lose_last_heart()
	assert_eq(state.revive(), 1.0)
	assert_eq(state.revive(), 0.0, "not wrecked any more: nothing to revive")
	state.start_run()
	assert_eq(state.heal_car(1.0), 0.0, "full health: nothing restored")
	_lose_last_heart()
	state.advance(3.0)
	assert_eq(ended, [["loss", 0]])
	assert_eq(state.heal_car(1.0), 0.0, "after the recap starts it is too late")
	assert_eq(state.revive(), 0.0)


func test_in_the_run_a_sliding_wreck_picks_up_a_health_pickup_and_drives_again() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	# T-424: the test is about the wreck, the slide, the pickup and the revive. The starting gun
	# and the minions (kills drop coins and hearts, bodies hit the car) would change what it
	# watches, so they are off before the first frame (minions.enabled, weapons.enabled).
	run.minions.enabled = false
	run.weapons.enabled = false
	var run_ended: Array = []
	run.state.run_ended.connect(func(r: String, c: int) -> void: run_ended.append([r, c]))
	run.car.use_keyboard = false
	run.car.scripted_input = [true, false, 0.0]
	await wait_physics_frames(40)
	run.state.damage_car(1000.0)
	assert_true(run.state.is_wrecked())
	var coin_state: int = run.state.coins
	var p: Area2D = load("res://scripts/enemies/health_pickup.gd").new()
	p.state = run.state
	p.position = run.car.position + Vector2(2.0 * 16.0, 0.0)  # 2 units off: inside the magnet's reach
	var picked: Array = []
	p.collected.connect(func(_n: Node, restored: float) -> void: picked.append(restored))
	run.add_child(p)
	assert_true(2.0 <= run.state.pickup_magnet_radius_units)
	await wait_physics_frames(90)
	assert_eq(picked, [1.0], "picked up while wrecked")
	assert_false(run.state.is_wrecked())
	assert_eq(run.state.hearts, 1)
	assert_true(run.car.input_enabled, "controls back")
	assert_false(run.wreck_effect.is_playing(), "the smoke and flames stopped")
	run.state.advance(10.0)
	assert_eq(run_ended, [], "no recap")
	assert_eq(run.state.coins, coin_state)


func test_coins_stand_still_during_the_wreck_but_health_is_pulled() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.state.damage_car(1000.0)
	var at: Vector2 = run.car.position
	var far := Node2D.new()
	far.add_to_group("coins")
	far.position = at + Vector2(48.0, 0.0)
	run.add_child(far)
	run.pickup_magnet.step(0.1)
	assert_eq(far.position, at + Vector2(48.0, 0.0), "a coin is not pulled")
	var h := Node2D.new()
	h.add_to_group("health_pickups")
	h.position = at + Vector2(48.0, 0.0)
	run.add_child(h)
	run.pickup_magnet.step(0.1)
	assert_lt(h.position.distance_to(at), 48.0, "a health pickup is")


# --- The car's controls -----------------------------------------------------------

func _car(world: Node2D) -> CharacterBody2D:
	var car: CharacterBody2D = CarScript.new()
	world.add_child(car)
	car.set_physics_process(false)
	car.use_keyboard = false
	return car


func _drive(car: CharacterBody2D, input: Array, steps: int) -> void:
	car.scripted_input = input
	for i in steps:
		car.physics_step()


func test_dead_controls_coast_exactly_like_no_keys_held() -> void:
	var world := Node2D.new()
	add_child_autofree(world)
	var a := _car(world)
	var b := _car(world)
	b.position = Vector2(0.0, 2000.0)
	b.model.set_position(b.position / CarScript.PX_PER_UNIT)
	for c in [a, b]:
		_drive(c, [true, false, 0.6], 60)  # at speed, drifting
	var speed_before: float = a.model.get_velocity().length()
	a.input_enabled = false
	_drive(a, [true, false, 1.0], 1)  # W and steering held: ignored
	_drive(b, [false, false, 0.0], 1)
	assert_gt(a.model.get_velocity().length(), speed_before * 0.9, "keeps the movement it had")
	_drive(a, [true, true, -1.0], 40)
	_drive(b, [false, false, 0.0], 40)
	assert_almost_eq(a.model.get_velocity(), b.model.get_velocity(), Vector2(0.0001, 0.0001), "the same coasting")
	assert_almost_eq(a.model.rotation, b.model.rotation, 0.0001, "no steering")
	assert_lt(a.model.get_velocity().length(), speed_before, "it slows down")


func test_live_controls_are_unchanged() -> void:
	var world := Node2D.new()
	add_child_autofree(world)
	var a := _car(world)
	var b := _car(world)
	b.position = Vector2(0.0, 2000.0)
	b.model.set_position(b.position / CarScript.PX_PER_UNIT)
	assert_true(a.input_enabled, "on by default")
	b.input_enabled = false
	b.input_enabled = true
	for c in [a, b]:
		_drive(c, [true, false, 0.5], 50)
	assert_almost_eq(a.model.get_velocity(), b.model.get_velocity(), Vector2(0.000001, 0.000001))
	assert_gt(a.model.get_velocity().length(), 1.0, "it drove")


# --- The smoke and flames ----------------------------------------------------------

func test_the_effect_reads_its_numbers_and_smokes_and_burns() -> void:
	var fx = WreckEffectScript.new()
	add_child_autofree(fx)
	var cfg := RunData.new().wreck()
	fx.configure(cfg)
	assert_eq(fx.puffs_per_second, float(cfg.smoke_puffs_per_second))
	assert_false(fx.is_playing())
	fx.start(Vector2(100.0, 50.0))
	assert_true(fx.is_playing())
	assert_true(fx.visible)
	assert_eq(fx.flame_heights().size(), int(cfg.flame_tongues))
	for i in 60:
		fx.advance(STEP)
	assert_gt(fx.puffs.size(), 3, "smoke for the whole second")
	fx.stop()
	assert_false(fx.visible)
	assert_eq(fx.puffs.size(), 0)


func test_flames_follow_the_car_and_puffs_stay_where_they_were_left() -> void:
	var fx = WreckEffectScript.new()
	add_child_autofree(fx)
	fx.start(Vector2.ZERO)
	fx.advance(0.2)
	var first: Dictionary = fx.puffs[0]
	var at: Vector2 = fx.puff_position(first)
	fx.follow(Vector2(80.0, 40.0))
	assert_eq(fx.flame_base().x, 80.0, "the flames are on the car")
	assert_eq(fx.puff_position(first), at, "a puff left behind stays")
	fx.advance(0.2)
	var newest: Dictionary = fx.puffs[-1]
	assert_lt(newest.at.distance_to(Vector2(80.0, 40.0)), 20.0, "new puffs come off the car")
	assert_lt(fx.puff_position(first).y, at.y, "smoke rises")


func test_flames_flicker_and_puffs_grow_then_shrink() -> void:
	var fx = WreckEffectScript.new()
	add_child_autofree(fx)
	fx.start(Vector2.ZERO)
	var seen := {}
	for i in 30:
		fx.advance(1.0 / 30.0)
		seen[str(fx.flame_heights())] = true
	assert_gt(seen.size(), 3, "the flames change")
	var p := {"at": Vector2.ZERO, "velocity": Vector2.ZERO, "born": fx.time}
	var r0: float = fx.puff_radius(p)
	fx.time += fx.smoke_life * 0.5
	var r_mid: float = fx.puff_radius(p)
	fx.time += fx.smoke_life * 0.45
	assert_gt(r_mid, r0, "grows")
	assert_lt(fx.puff_radius(p), r_mid, "then shrinks")


func test_placeholder_colours_are_opaque_and_not_greenbulls() -> void:
	for c in WreckEffectScript.COLOURS:
		assert_eq(c.a, 1.0, "no see-through pixels")
		for g in GREENBULL:
			var d := Vector3(c.r - g.r, c.g - g.g, c.b - g.b).length() * 255.0
			assert_gt(d, 40.0, "%s is not Greenbull's %s" % [c, g])


func test_the_art_swap_takes_sprite_frames() -> void:
	var fx = WreckEffectScript.new()
	add_child_autofree(fx)
	var frames := SpriteFrames.new()
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color8(90, 90, 100))
	frames.add_frame("default", ImageTexture.create_from_image(img))
	fx.smoke_frames = frames
	fx.flame_frames = frames
	fx.start(Vector2.ZERO)
	fx.advance(0.5)
	await wait_process_frames(2)  # draws with the frames without errors
	assert_true(fx.is_playing())


# --- In the run ------------------------------------------------------------------

func test_in_the_run_the_car_slides_on_with_dead_controls_smoking() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	var run_ended: Array = []
	run.state.run_ended.connect(func(r: String, c: int) -> void: run_ended.append([r, c]))
	var fx: Node2D = run.wreck_effect
	assert_eq(fx.get_parent(), run.view_root)
	assert_gt(fx.get_index(), run.car_sprite.get_index(), "drawn above the car")
	assert_false(fx.is_playing())
	run.car.use_keyboard = false
	run.car.scripted_input = [true, false, 0.0]
	await wait_physics_frames(40)
	var speed: float = run.car.model.get_velocity().length()
	assert_gt(speed, 1.0, "at speed")
	run.state.damage_car(1000.0)
	assert_false(run.car.input_enabled, "controls dead")
	assert_true(fx.is_playing(), "smoking and burning")
	var pos: Vector2 = run.car.position
	run.car.scripted_input = [true, false, 1.0]  # still pressing: nothing happens
	var rot: float = run.car.model.rotation
	await wait_physics_frames(10)
	assert_ne(run.car.position, pos, "it slides on")
	assert_lt(run.car.model.get_velocity().length(), speed, "slowing down, no throttle")
	assert_almost_eq(run.car.model.rotation, rot, 0.0001, "no steering")
	assert_eq(fx.emitter, run.car_sprite.position, "the fire is where the car is drawn")
	run.state.add_coins(5)
	assert_eq(run.state.coins, 0, "no coins")
	assert_eq(run_ended, [])
	run.state.advance(run.state.wreck_left)
	assert_eq(run_ended, [["loss", 0]])
	run.start_run()
	assert_true(run.car.input_enabled, "a new car, controls live")
	assert_false(fx.is_playing())
