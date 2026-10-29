extends GutTest
## Task T-334: hearts in the run (Game loop architecture, Decisions, "Hearts instead of
## health points"). 5 hearts plus 1 per garage level; a minion and a meteor take 1, the
## kaiju 2; after any hit 1 s of invulnerability with a blink, in which hits do nothing
## (no hearts, no knockback, no combo cut); a health pickup heals 1 heart, capped; 0 hearts
## ends the run as a loss.

const RunScene := preload("res://scenes/run/run.tscn")
const RunStateScript := preload("res://scripts/run/run_state.gd")
const KaijuScript := preload("res://scripts/enemies/kaiju.gd")
const KaijuBossScript := preload("res://scripts/enemies/kaiju_boss.gd")
const FlameScript := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const DT := 0.02
var PATH := RunPaths.file("test_progress_t334.json")

var state: RunState
var run_data: RunData


func before_each() -> void:
	run_data = RunData.new()
	state = RunStateScript.new()
	add_child_autofree(state)
	state.start_run()


func after_each() -> void:
	get_tree().paused = false
	KaijuBossScript.playtest_override = -2.0
	FlameScript.playtest_override = -1
	DirAccess.remove_absolute(PATH)


## A combo above "no combo", so a cut shows.
func _raise_combo() -> void:
	for i in 4:
		state.add_trick("alternate_drift")
	assert_gt(state.combo, 1.0, "a combo going")


func _run_scene() -> Node2D:
	KaijuBossScript.playtest_override = -1.0
	FlameScript.playtest_override = 0
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	run.car.use_keyboard = false
	return run


# --- Hearts at the start ----------------------------------------------------------

func test_a_run_starts_with_5_hearts() -> void:
	assert_eq(run_data.starting_hearts(), 5.0, "run.json: 5 hearts")
	assert_eq(state.health, 5.0)
	assert_eq(state.max_health, 5.0)
	assert_eq(state.hearts, 5)
	assert_eq(state.max_hearts, 5)


func test_each_garage_level_adds_1_heart() -> void:
	var garage := GarageData.new()
	for lvl in range(garage.max_level() + 1):
		var p := PlayerProgress.new(null, PATH)
		p.levels["car_health"] = lvl
		var s := RunStateScript.new()
		s.progress = p
		s.start_run()
		assert_eq(s.max_hearts, 5 + lvl, "level %d" % lvl)
		assert_eq(s.hearts, 5 + lvl, "full at the start, level %d" % lvl)
		s.free()


# --- Damage in hearts, from each enemy -------------------------------------------

func test_a_minion_hit_takes_1_heart() -> void:
	var run := _run_scene()
	var at: Vector2 = run.car.position / 16.0 + Vector2(0.9, 0.0).rotated(run.car.rotation)
	var m: Node = run.minions.spawn_minion_at(at)
	assert_true(m.contact_step(DT, run.car, run.state), "it hits")
	assert_eq(run.state.hearts, 4, "1 heart")


func test_a_meteor_takes_1_heart() -> void:
	var run := _run_scene()
	var hit: bool = run.kaiju_boss.meteors.land(run.car.position / 16.0 + Vector2(0.6, 0.0))
	assert_true(hit)
	assert_eq(run.state.hearts, 4, "1 heart")


func test_the_kaiju_takes_2_hearts() -> void:
	var run := _run_scene()
	run.kaiju_boss.rng.seed = 334
	var offset := Vector2(0.0, KaijuScript.RADIUS_UNITS + 0.3).rotated(run.car.rotation)
	var k: Node = run.kaiju_boss.appear_at(run.car.position / 16.0 + offset)
	assert_true(k.touches_car(run.car.position / 16.0, run.car.rotation))
	assert_true(k.contact_step(DT, run.car, run.state), "it hits")
	assert_eq(run.state.hearts, 3, "2 hearts")


# --- The invulnerability ----------------------------------------------------------

func test_after_a_hit_the_car_is_invulnerable_for_1_second() -> void:
	assert_false(state.is_invulnerable(), "not before a hit")
	var starts: Array = []
	state.invulnerability_started.connect(func(s: float) -> void: starts.append(s))
	state.damage_car(1.0)
	assert_true(state.is_invulnerable())
	assert_eq(starts, [1.0], "the signal, with run.json's 1 s")
	var t := 0.0
	while state.is_invulnerable() and t < 3.0:
		state.advance(1.0 / 60.0)
		t += 1.0 / 60.0
	assert_almost_eq(t, run_data.invulnerability_seconds(), 0.05, "1 s (+-0.05)")
	assert_almost_eq(t, 1.0, 0.05)


func test_a_hit_inside_the_second_takes_nothing_and_does_not_cut_the_combo() -> void:
	state.damage_car(1.0)
	_raise_combo()
	var combo := state.combo
	var broken := [0]
	var damaged := [0]
	state.combo_broken.connect(func() -> void: broken[0] += 1)
	state.car_damaged.connect(func(_a: float) -> void: damaged[0] += 1)
	state.advance(0.9)
	state.damage_car(1.0)
	state.damage_car(2.0)
	assert_eq(state.hearts, 4, "no hearts")
	assert_eq(state.combo, combo, "the combo stays")
	assert_eq(broken[0], 0, "no combo broken")
	assert_eq(damaged[0], 0, "no damage signal (no shake)")
	assert_almost_eq(state.invulnerable_left, 0.1, 0.0001, "an ignored hit does not restart the second")


func test_a_hit_after_the_second_counts_and_cuts_the_combo() -> void:
	state.damage_car(1.0)
	state.advance(1.05)
	assert_false(state.is_invulnerable())
	_raise_combo()
	var combo := state.combo
	var broken := [0]
	state.combo_broken.connect(func() -> void: broken[0] += 1)
	state.damage_car(1.0)
	assert_eq(state.hearts, 3, "a heart off")
	assert_lt(state.combo, combo, "the combo is cut")
	assert_eq(broken[0], 1)
	assert_true(state.is_invulnerable(), "a new second starts")


func test_the_first_hit_cuts_the_combo() -> void:
	_raise_combo()
	var combo := state.combo
	state.damage_car(1.0)
	assert_lt(state.combo, combo)


func test_no_knockback_from_a_minion_while_invulnerable() -> void:
	var run := _run_scene()
	var at: Vector2 = run.car.position / 16.0 + Vector2(0.9, 0.0).rotated(run.car.rotation)
	var a: Node = run.minions.spawn_minion_at(at)
	assert_true(a.contact_step(DT, run.car, run.state))
	var push: Vector2 = run.car.pending_knockback()
	var b: Node = run.minions.spawn_minion_at(at)
	assert_false(b.contact_step(DT, run.car, run.state), "a second minion does not hit")
	assert_false(a.contact_step(DT, run.car, run.state), "nor the first again")
	assert_eq(run.car.pending_knockback(), push, "no extra knockback")
	assert_eq(run.state.hearts, 4)


func test_no_meteor_hit_while_invulnerable() -> void:
	var run := _run_scene()
	run.state.damage_car(1.0)
	var hit: bool = run.kaiju_boss.meteors.land(run.car.position / 16.0 + Vector2(0.6, 0.0))
	assert_false(hit)
	assert_eq(run.state.hearts, 4)
	assert_eq(run.car.pending_knockback(), Vector2.ZERO)


# --- The blink --------------------------------------------------------------------

func test_the_car_blinks_during_the_second_then_shows() -> void:
	assert_true(state.car_blink_visible(), "shown before a hit")
	state.damage_car(1.0)
	var interval := run_data.blink_interval_seconds()
	var seen: Array = []
	var t := 0.0
	while t < 1.2:
		seen.append(state.car_blink_visible())
		state.advance(0.01)
		t += 0.01
	assert_false(seen[0], "off at once, so the hit shows")
	var changes := 0
	for i in range(1, seen.size()):
		if seen[i] != seen[i - 1]:
			changes += 1
	assert_almost_eq(changes, int(round(1.0 / interval)), 1, "a change every blink phase (%.2f s)" % interval)
	assert_true(seen[-1], "shown after the second")
	assert_true(state.car_blink_visible())


func test_the_run_scene_hides_and_shows_the_drawn_car() -> void:
	var run := _run_scene()
	assert_true(run.car_sprite.visible)
	run.state.damage_car(1.0)
	run.apply_blink()
	assert_false(run.car_sprite.visible, "off at once")
	run.state.advance(run_data.blink_interval_seconds() + 0.001)
	run.apply_blink()
	assert_true(run.car_sprite.visible, "on in the next phase")
	run.state.damage_car(0.0)
	run.state.advance(1.0)
	run.apply_blink()
	assert_true(run.car_sprite.visible, "shown after the second")
	run.state.damage_car(1.0)
	run.start_run()
	assert_true(run.car_sprite.visible, "a new run shows the car")
	assert_false(run.state.is_invulnerable(), "and is not invulnerable")


# --- Health pickups ---------------------------------------------------------------

func test_a_pickup_heals_1_heart_never_above_the_maximum() -> void:
	var d := EnemyData.new().health_drops()
	assert_eq(d["restore_hearts"], 1)
	assert_eq(d["drop_chance"], 0.15, "T-333's chance")
	state.damage_car(1.0)
	state.advance(1.1)
	state.damage_car(1.0)
	assert_eq(state.hearts, 3)
	assert_eq(state.heal_car(float(d["restore_hearts"])), 1.0)
	assert_eq(state.hearts, 4)
	assert_eq(state.heal_car(1.0), 1.0)
	assert_eq(state.heal_car(1.0), 0.0, "never above the maximum")
	assert_eq(state.hearts, 5)


# --- The end at 0 hearts ----------------------------------------------------------

func test_0_hearts_ends_the_run_as_a_loss_with_the_coins() -> void:
	var ended: Array = []
	state.run_ended.connect(func(r: String, c: int) -> void: ended.append([r, c]))
	state.add_coins(9)
	for i in 5:
		assert_eq(ended.size(), 0, "still going at %d hearts" % state.hearts)
		state.damage_car(1.0)
		state.advance(1.01)
	assert_eq(state.hearts, 0)
	state.advance(state.wreck_seconds)  # the wreck (T-360); 1.01 s of it passed already
	assert_eq(ended, [["loss", 9]], "a loss with the coins, as at 0 health")
	assert_false(state.is_running())


func test_a_kaiju_hit_from_2_hearts_ends_the_run() -> void:
	var ended: Array = []
	state.run_ended.connect(func(r: String, c: int) -> void: ended.append([r, c]))
	state.health = 2.0
	state.damage_car(2.0)
	state.advance(state.wreck_seconds)  # the wreck (T-360)
	assert_eq(ended, [["loss", 0]])
	assert_eq(state.hearts, 0)
