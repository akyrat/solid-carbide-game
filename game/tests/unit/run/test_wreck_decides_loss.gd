extends GutTest
## Task T-413: the wreck decides the loss at its end (Game loop architecture,
## Decisions, "The wreck decides the loss at its end" and "A tie goes to the
## player"). The last heart starts the wreck but no result; during its 3 seconds
## a kaiju kill wins, coins and health pickups count, a trick in progress is
## dropped, and the pause screen's Restart or Exit cancels the run. The kaiju
## dying on the step the clock reaches 0:00 wins.

const RunStateScript := preload("res://scripts/run/run_state.gd")
const RunScene := preload("res://scenes/run/run.tscn")
const GameScene := preload("res://scenes/game/game.tscn")
const CoinScript := preload("res://scripts/enemies/coin.gd")
const STEP := 1.0 / 60.0

var SETTINGS_PATH := RunPaths.file("test_settings_t413.cfg")
var PROGRESS_PATH := RunPaths.file("test_progress_t413.json")

var state: RunState
var ended: Array = []


func before_each() -> void:
	state = RunStateScript.new()
	add_child_autofree(state)
	ended = []
	state.run_ended.connect(func(r: String, c: int) -> void: ended.append([r, c]))
	state.start_run()


func after_each() -> void:
	get_tree().paused = false


func _lose_last_heart(s: RunState = state) -> void:
	s.health = 1.0
	s.damage_car(1.0)


# --- The result waits for the wreck's end ------------------------------------------

func test_the_result_is_set_only_when_the_wreck_ends() -> void:
	state.advance(60.0)
	_lose_last_heart()
	assert_true(state.is_wrecked())
	assert_eq(state.result, "", "the last heart does not set the result")
	assert_eq(state.loss_reason, "")
	state.advance(2.9)
	assert_eq(state.result, "", "still not, 0.1 s before the end")
	assert_eq(ended, [])
	state.advance(0.1)
	assert_eq(state.result, "loss", "set when the 3 seconds end")
	assert_eq(state.loss_reason, "health")
	assert_eq(ended, [["loss", 0]])
	assert_almost_eq(float(state.recap().time_survived), 60.0, 0.001, "the clock stopped at the last heart")


func test_the_drift_in_progress_is_forgotten_at_the_wreck() -> void:
	state.drift_step(true, 0.6)
	_lose_last_heart()
	assert_eq(state.drift_seconds, 0.0)
	state.revive()
	var xp := state.xp
	state.drift_step(true, 0.6)
	assert_eq(state.xp, xp, "0.6 s after the revive is not a full drift second with the 0.6 s before")


func test_the_fatal_hit_drops_the_trick_in_progress_instead_of_paying_it() -> void:
	var crashes: Array = []
	state.crashed.connect(func() -> void: crashes.append(true))
	state.health = 2.0
	state.damage_car(1.0)
	assert_eq(crashes.size(), 1, "a hit that leaves a heart pays the trick (T-315)")
	state.invulnerable_left = 0.0
	var broken: Array = []
	state.combo_broken.connect(func() -> void: broken.append(true))
	state.add_trick("three_sixty")
	state.damage_car(1.0)
	assert_true(state.is_wrecked())
	assert_eq(crashes.size(), 1, "the last heart's hit sends no crashed: nothing is paid")
	assert_eq(broken.size(), 1, "the combo is still cut")


# --- A kaiju kill during the wreck wins ------------------------------------------------

func test_a_kaiju_kill_during_the_wreck_wins() -> void:
	state.add_coins(3)
	_lose_last_heart()
	state.advance(1.5)
	# kaiju_boss.gd's order: the kill for the recap, the kaiju's coins, then the win.
	state.enemy_slain("kaiju", "gun")
	state.add_coins(20)
	state.kaiju_killed()
	assert_eq(ended, [["win", 23]], "a win, with the kaiju's coins")
	assert_false(state.is_wrecked())
	assert_eq(state.result, "win")
	assert_eq(state.loss_reason, "", "no loss")
	var recap := state.recap()
	assert_eq(recap.result, "win", "the win recap")
	assert_eq(recap.loss_reason, "")
	assert_eq(recap.enemies_slain, {"kaiju": 1})
	state.advance(5.0)
	assert_eq(ended.size(), 1, "the wreck's end never comes: no loss after the win")
	assert_eq(state.recap().result, "win")


func test_in_the_game_a_kaiju_kill_during_the_wreck_shows_the_win_recap() -> void:
	var game := _game()
	var run: Node2D = game.run
	var before: int = game.history.count()
	_lose_last_heart(run.state)
	run.state.kaiju_killed()
	await wait_process_frames(2)  # the recap is shown deferred
	assert_not_null(game.recap, "the recap screen")
	assert_eq(game.history.count(), before + 1)
	assert_eq(game.history.runs()[0].result, "win", "the runs list keeps a win")


# --- Coins and health pickups count during the wreck ------------------------------

func test_coins_count_during_the_wreck() -> void:
	state.add_coins(2)
	_lose_last_heart()
	state.add_coins(5)
	assert_eq(state.coins, 7)
	state.advance(3.0)
	assert_eq(ended, [["loss", 7]], "banked with the coins from the wreck")
	state.add_coins(5)
	assert_eq(state.coins, 7, "after the end nothing counts")


func test_in_the_run_a_coin_in_the_magnet_is_pulled_and_counted_during_the_wreck() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false  # no other coins or hits (as T-424)
	run.weapons.enabled = false
	await wait_physics_frames(2)
	run.state.damage_car(1000.0)
	assert_true(run.state.is_wrecked())
	var coins: int = run.state.coins
	var coin: Area2D = CoinScript.new()
	coin.state = run.state
	coin.value = 4
	coin.position = run.car.position + Vector2(2.0 * 16.0, 0.0)  # 2 units off: inside the magnet's reach
	assert_true(2.0 <= run.state.pickup_magnet_radius_units)
	var got: Array = []
	coin.collected.connect(func(_c: Node, v: int) -> void: got.append(v))
	run.add_child(coin)
	await wait_physics_frames(30)
	assert_eq(got, [4], "pulled and picked up while wrecked")
	assert_eq(run.state.coins, coins + 4, "the coin total rises")
	assert_true(run.state.is_wrecked(), "a coin does not revive")


func test_in_the_run_the_trick_detection_is_off_while_wrecked_and_back_after_a_revive() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	assert_true(run.car.detect_tricks)
	run.state.damage_car(1000.0)
	assert_false(run.car.detect_tricks, "the trick in progress is dropped")
	run.state.heal_car(1.0)
	assert_false(run.state.is_wrecked())
	assert_true(run.car.detect_tricks, "tricks count again after a revive")


# --- Pause Restart or Exit during the wreck cancels the run ------------------------

func _game() -> Node:
	GameSettings.path = SETTINGS_PATH
	PlayerProgress.path = PROGRESS_PATH
	DirAccess.remove_absolute(SETTINGS_PATH)
	DirAccess.remove_absolute(PROGRESS_PATH)
	var game: Node = GameScene.instantiate()
	game.quit_game = func(): pass
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()
	return game


func _cleanup_game() -> void:
	get_tree().paused = false
	await wait_process_frames(1)
	DirAccess.remove_absolute(SETTINGS_PATH)
	TestSave.restore_settings()
	DirAccess.remove_absolute(PROGRESS_PATH)
	TestSave.restore_progress()


func test_pause_restart_during_the_wreck_banks_nothing_and_adds_no_run() -> void:
	var game := _game()
	var old: Node2D = game.run
	old.state.add_coins(6)
	var coins: int = game.progress.coins
	var runs: int = game.history.count()
	_lose_last_heart(old.state)
	old.state.add_coins(2)
	game.pause_screen.pause()
	game.pause_screen.restart_button.pressed.emit()
	assert_ne(game.run, old, "a fresh run")
	assert_eq(game.progress.coins, coins, "no coins banked")
	assert_eq(game.history.count(), runs, "no runs-list entry")
	await _cleanup_game()


func test_pause_exit_during_the_wreck_banks_nothing_and_adds_no_run() -> void:
	var game := _game()
	game.run.state.add_coins(6)
	var coins: int = game.progress.coins
	var runs: int = game.history.count()
	_lose_last_heart(game.run.state)
	game.pause_screen.pause()
	game.pause_screen.exit_button.pressed.emit()
	assert_null(game.run)
	assert_true(game.menu is MainMenu)
	assert_eq(game.progress.coins, coins, "no coins banked")
	assert_eq(game.history.count(), runs, "no runs-list entry")
	await _cleanup_game()


func test_pause_exit_outside_the_wreck_cancels_too() -> void:
	var game := _game()
	game.run.state.add_coins(6)
	var coins: int = game.progress.coins
	var runs: int = game.history.count()
	game.pause_screen.pause()
	game.pause_screen.exit_button.pressed.emit()
	assert_eq(game.progress.coins, coins, "cancelled outside the wreck too: coins lost (board, 2026-10-30)")
	assert_eq(game.history.count(), runs, "no runs-list entry")
	await _cleanup_game()


# --- A tie goes to the player ---------------------------------------------------------

func test_the_kaiju_dying_on_the_step_the_clock_reaches_0_00_wins() -> void:
	state.advance(RunState.RUN_SECONDS - 0.01)
	state.advance(0.02)  # the clock reaches 0:00 first in this step...
	assert_true(state.is_timed_out())
	assert_true(get_tree().paused, "the time's up froze the run")
	# ...and the kaiju dies in the same step (kaiju_boss.gd's order).
	state.enemy_slain("kaiju", "gun")
	state.add_coins(20)
	state.kaiju_killed()
	assert_eq(ended, [["win", 20]], "a win, with the kaiju's coins")
	assert_false(state.is_timed_out(), "the time's up is called off")
	assert_false(get_tree().paused, "the run is not frozen any more")
	assert_eq(state.process_mode, Node.PROCESS_MODE_INHERIT)
	assert_eq(state.recap().result, "win")
	assert_eq(state.recap().enemies_slain, {"kaiju": 1})
	state.advance(10.0)
	assert_eq(ended.size(), 1, "no time's up loss after it")


func test_the_kaiju_dying_first_in_the_step_wins_too() -> void:
	state.advance(RunState.RUN_SECONDS - 0.01)
	state.kaiju_killed()
	state.advance(0.02)
	assert_eq(ended, [["win", 0]])
	assert_false(state.is_timed_out())


func test_a_kaiju_kill_after_the_step_of_0_00_is_too_late() -> void:
	state.advance(RunState.RUN_SECONDS + 1.0)
	assert_true(state.is_timed_out())
	await get_tree().process_frame
	state.add_coins(20)
	state.kaiju_killed()
	assert_eq(ended, [], "ignored: the time's up goes on")
	assert_eq(state.coins, 0)
	state.advance(state.time_up_left)
	assert_eq(ended, [["loss", 0]])
	assert_eq(state.loss_reason, "time")
