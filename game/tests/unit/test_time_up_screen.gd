extends GutTest
## Task T-317: the time's up screen. When the 8-minute timer runs out with the
## kaiju alive, the run is lost and frozen at 0:00 while the screen plays for
## run.json's time_up.seconds (3 s), with T-316's headline; then run_ended, as
## before. A kaiju kill and a health loss (its own wreck, T-360) don't show it.

const RunStateScript := preload("res://scripts/run/run_state.gd")
const TimeUpScreenScript := preload("res://scripts/ui/time_up_screen.gd")
const GameScene := preload("res://scenes/game/game.tscn")
const TEXTS_PATH := "res://data/screen_texts.json"
var TEST_PATH := RunPaths.file("test_settings_t317.cfg")
var PROGRESS_PATH := RunPaths.file("test_progress_t317.json")

var state: RunState
var ended: Array = []
var time_ups: Array = []


func before_each() -> void:
	state = RunStateScript.new()
	add_child_autofree(state)
	ended = []
	time_ups = []
	state.run_ended.connect(func(r: String, c: int) -> void: ended.append([r, c]))
	state.time_up_started.connect(func(s: float) -> void: time_ups.append(s))
	state.start_run()


func after_each() -> void:
	get_tree().paused = false


func _headline() -> String:
	var data = JSON.parse_string(FileAccess.get_file_as_string(TEXTS_PATH))
	return String(data.time_up.headline)


func _run_out_the_clock(s: RunState) -> void:
	s.advance(s.time_left)


# --- The state: the 3 seconds, the result ----------------------------------------

func test_the_data_gives_3_seconds() -> void:
	assert_eq(RunData.new().time_up_seconds(), 3.0)
	assert_eq(state.time_up_seconds, 3.0)


func test_at_0_00_the_screen_starts_and_run_ended_comes_3_seconds_later() -> void:
	state.add_coins(7)
	state.advance(RunState.RUN_SECONDS - 0.5)
	assert_eq(time_ups, [])
	state.advance(0.5)
	assert_eq(state.time_left, 0.0)
	assert_eq(time_ups, [3.0], "the time's up screen, once, for 3 s")
	assert_true(state.is_timed_out())
	assert_eq(state.result, "loss", "lost from 0:00")
	assert_eq(state.loss_reason, "time")
	assert_false(state.is_running())
	assert_eq(ended, [], "run_ended waits for the screen")
	for i in 29:
		state.advance(0.1)
	assert_eq(ended, [], "not before 2.9 s")
	state.advance(0.1)
	assert_eq(ended, [["loss", 7]], "at 3 s, the same result and coins as before")
	assert_false(state.is_timed_out())
	state.advance(10.0)
	assert_eq(ended.size(), 1, "once")
	assert_eq(time_ups.size(), 1)


func test_the_run_is_frozen_while_the_screen_plays() -> void:
	state.add_coins(4)
	var xp_before := state.xp
	_run_out_the_clock(state)
	assert_true(get_tree().paused, "the scene tree is paused: enemies, car and pickups stand still")
	assert_eq(state.process_mode, Node.PROCESS_MODE_ALWAYS, "only the state counts the seconds")
	# T-413: a kaiju kill on the very step the clock reaches 0:00 still wins (a tie
	# goes to the player); from the next step on nothing counts.
	await get_tree().process_frame
	var hearts := state.health
	state.damage_car(1.0)
	state.add_coins(5)
	state.add_xp(50.0)
	state.enemy_slain("minion", "gun")
	state.kaiju_killed()
	state.advance(1.0)
	assert_eq(state.time_left, 0.0, "the timer stays at 0:00")
	assert_eq(state.health, hearts, "no damage")
	assert_eq(state.coins, 4, "no pickups")
	assert_eq(state.xp, xp_before, "no likes")
	assert_eq(state.recap().enemies_slain.get("minion", 0), 0, "no kills")
	assert_eq(state.result, "loss", "a kaiju kill now changes nothing")
	state.advance(2.0)
	assert_eq(ended, [["loss", 4]])
	assert_false(get_tree().paused, "unfrozen when the run ends")
	assert_eq(state.process_mode, Node.PROCESS_MODE_INHERIT)


func test_the_seconds_count_on_their_own_while_paused() -> void:
	var t := [0, 0]  # lambdas capture by value: an array they can write into
	state.time_up_started.connect(func(_s: float) -> void: t[0] = Time.get_ticks_msec())
	state.run_ended.connect(func(_r: String, _c: int) -> void: t[1] = Time.get_ticks_msec())
	state.time_left = 0.001  # the state's own frame runs the clock out
	await wait_until(func() -> bool: return not ended.is_empty(), 6.0)
	assert_eq(ended.size(), 1)
	var secs: float = (int(t[1]) - int(t[0])) / 1000.0
	# 3 s; the upper margin allows for one slow headless frame.
	assert_between(secs, 2.9, 3.2, "about 3 s of real time (%.3f)" % secs)


func test_0_seconds_ends_at_once_as_before() -> void:
	state.time_up_seconds = 0.0
	_run_out_the_clock(state)
	assert_eq(ended, [["loss", 0]])
	assert_false(get_tree().paused)
	assert_false(state.is_timed_out())


func test_a_new_run_during_the_screen_unfreezes() -> void:
	_run_out_the_clock(state)
	state.start_run()
	assert_false(get_tree().paused)
	assert_false(state.is_timed_out())
	assert_true(state.is_running())
	assert_eq(state.process_mode, Node.PROCESS_MODE_INHERIT)


func test_a_kaiju_kill_ends_at_once_without_the_screen() -> void:
	state.advance(RunState.RUN_SECONDS - 1.0)
	state.kaiju_killed()
	assert_eq(ended, [["win", 0]])
	assert_eq(time_ups, [])
	state.advance(5.0)
	assert_eq(time_ups, [], "the clock no longer runs")


func test_a_health_loss_has_its_wreck_not_the_screen() -> void:
	var wrecks := []
	state.wreck_started.connect(func(s: float) -> void: wrecks.append(s))
	state.damage_car(state.max_health)
	assert_eq(wrecks, [state.wreck_seconds])
	assert_eq(time_ups, [])
	state.advance(state.wreck_seconds)
	assert_eq(ended, [["loss", 0]])
	assert_eq(state.loss_reason, "health")
	assert_eq(time_ups, [], "never the time's up screen")
	assert_false(get_tree().paused)


# --- The screen -----------------------------------------------------------------

func _screen() -> CanvasLayer:
	var s: CanvasLayer = TimeUpScreenScript.new()
	add_child_autofree(s)
	s.bind(state)
	return s


func test_the_headline_is_the_data_files_word_for_word() -> void:
	var s := _screen()
	assert_ne(_headline(), "")
	assert_eq(s.headline, _headline())
	assert_eq(TimeUpScreenScript.load_headline(), _headline())


func test_no_text_is_written_in_the_code() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/ui/time_up_screen.gd")
	assert_false(src.contains(_headline()), "the headline is not in the script")
	for word in _headline().split(" "):
		var w := word.strip_edges().trim_suffix(",").trim_suffix("!")
		if w.length() >= 5:
			assert_false(src.contains("\"" + w), "no piece of the headline in the script: " + w)


func test_hidden_until_the_clock_runs_out_then_shown_then_hidden_at_the_end() -> void:
	var s := _screen()
	assert_false(s.visible)
	state.advance(100.0)
	assert_false(s.visible)
	_run_out_the_clock(state)
	assert_true(s.visible)
	assert_true(s.is_playing())
	assert_eq(s.duration, 3.0)
	assert_eq(s.process_mode, Node.PROCESS_MODE_ALWAYS, "animates while the run is frozen")
	assert_gt(s.layer, 10, "over the HUD")
	assert_lt(s.layer, 20, "under the pause screen")
	state.advance(3.0)
	assert_false(s.visible, "gone when the run ends")
	assert_false(s.is_playing())


func test_the_card_is_the_cracked_comic_card_at_a_whole_pixel_scale() -> void:
	var s := _screen()
	_run_out_the_clock(state)
	var tex: Texture2D = s.left_half.texture
	assert_not_null(tex)
	assert_eq(s.right_half.texture.get_size(), tex.get_size(), "two halves of one card")
	assert_eq(s.left_half.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "hard pixel edges")
	assert_between(s.art_scale, 1, TimeUpScreenScript.MAX_SCALE)
	var vp := s.get_viewport().get_visible_rect().size
	if vp.x >= tex.get_size().x:
		assert_lte(tex.get_size().x * s.art_scale, vp.x * TimeUpScreenScript.MAX_WIDTH_SHARE, "fits the screen")
	else:
		assert_eq(s.art_scale, 1, "a screen narrower than the card: 1")
	var img := tex.get_image()
	var opaque := 0
	var partial := 0
	for y in img.get_height():
		for x in img.get_width():
			var a := img.get_pixel(x, y).a
			if a == 1.0:
				opaque += 1
			elif a != 0.0:
				partial += 1
	assert_gt(opaque, 100)
	assert_eq(partial, 0, "opaque or fully transparent pixels only")


func test_the_animation_slams_in_shakes_cracks_and_holds() -> void:
	var P := TimeUpScreenScript
	var p0: Dictionary = P.pose(0.0)
	assert_eq(p0.dim, 0.0)
	assert_eq(p0.scale, P.SLAM_FROM, "starts big")
	var p1: Dictionary = P.pose(P.SLAM_TIME + 1.0 / P.STEP_FPS)
	assert_almost_eq(float(p1.scale), 1.0, 0.0001, "slammed down to size")
	var shaking := false
	for i in range(6, 18):
		if (P.pose(i / 30.0).shake as Vector2) != Vector2.ZERO:
			shaking = true
	assert_true(shaking, "it shakes after the slam")
	assert_eq(P.pose(0.8).shake, Vector2.ZERO, "the shake has died away")
	assert_eq(P.pose(0.8).crack, 0.0, "not cracked yet")
	var end: Dictionary = P.pose(3.0)
	assert_almost_eq(float(end.dim), P.DIM_ALPHA, 0.0001, "the run dimmed")
	assert_eq(end.crack, 1.0, "cracked")
	assert_lt((end.left as Vector2).x, 0.0, "the left half moves left")
	assert_gt((end.right as Vector2).y, 0.0, "the right half drops")
	assert_eq(P.pose(2.0), P.pose(3.0), "it holds still to the end")


func test_the_screen_follows_its_pose_and_holds_at_the_end() -> void:
	var s := _screen()
	_run_out_the_clock(state)
	s.advance(0.5)
	assert_almost_eq(s.dim.color.a, TimeUpScreenScript.DIM_ALPHA, 0.0001)
	s.advance(10.0)
	assert_eq(s.elapsed, 3.0, "never past its 3 s")
	assert_almost_eq(s.right_half.rotation_degrees, TimeUpScreenScript.RIGHT_TILT_DEG, 0.0001)


# --- In the game ----------------------------------------------------------------

func _game() -> Node:
	GameSettings.path = TEST_PATH
	PlayerProgress.path = PROGRESS_PATH
	DirAccess.remove_absolute(TEST_PATH)
	DirAccess.remove_absolute(PROGRESS_PATH)
	var g: Node = GameScene.instantiate()
	g.quit_game = func(): pass
	add_child_autofree(g)
	g.start_run()
	return g


func _cleanup_game() -> void:
	get_tree().paused = false
	await wait_process_frames(1)
	DirAccess.remove_absolute(TEST_PATH)
	TestSave.restore_settings()
	DirAccess.remove_absolute(PROGRESS_PATH)
	TestSave.restore_progress()


func test_in_the_game_the_run_freezes_then_the_recap_then_the_menu() -> void:
	var g := _game()
	var run: Node2D = g.run
	var s: CanvasLayer = run.get_node("TimeUpScreenLayer")
	var m: Node = run.minions.spawn_minion_at(run.car.position / 16.0 + Vector2(8.0, 0.0))
	var coin: Node = run.minions.spawn_coin_at(run.car.position / 16.0 + Vector2(0.0, 8.0))
	await wait_physics_frames(5)
	var st: RunState = run.state
	st.add_coins(3)
	st.advance(st.time_left)
	assert_true(s.visible, "the time's up screen")
	assert_eq(s.headline, _headline())
	var minion_at: Vector2 = m.position
	var car_at: Vector2 = run.car.position
	var coin_at: Vector2 = coin.position
	var hearts := st.health
	await wait_physics_frames(20)
	assert_eq(m.position, minion_at, "enemies frozen")
	assert_eq(run.car.position, car_at, "the car frozen")
	assert_eq(coin.position, coin_at, "pickups frozen")
	assert_eq(st.health, hearts, "no damage")
	assert_eq(st.time_left_text(), "0:00")
	assert_not_null(g.run, "the run stays on screen during the 3 s")
	# Escape can't pause or unfreeze it.
	var ps = run.get_node("PauseScreenLayer")
	ps.toggle()
	assert_true(get_tree().paused)
	assert_false(ps.visible, "no pause screen over it")
	assert_true(s.visible)
	st.advance(st.time_up_left - 0.1)
	await wait_process_frames(2)
	assert_null(g.recap, "no recap before the 3 s are over")
	assert_not_null(g.run)
	st.advance(0.1)
	await wait_process_frames(2)
	assert_null(g.run, "the run ended as before")
	# Then the recap (T-320), as after every run end, and its Continue to the menu.
	assert_not_null(g.recap, "the recap follows the time's up screen")
	assert_null(g.menu)
	assert_eq(g.recap.summary.loss_reason, "time")
	assert_eq(g.recap.title_label.text, RecapScreen.text("title.time_up"))
	assert_false(get_tree().paused)
	assert_eq(g.progress.coins, 3, "the coins banked as before")
	g.recap.continue_button.pressed.emit()
	await wait_process_frames(2)
	assert_not_null(g.menu, "then the main menu")
	await _cleanup_game()


func test_the_crack_runs_between_words_so_no_letter_is_cut_away() -> void:
	const Broken := preload("res://scripts/hud/combo_broken_art.gd")
	const Art := preload("res://scripts/hud/trick_popup_art.gd")
	var letters: Dictionary = Art._letter(_headline(), TimeUpScreenScript.ART_STYLE)
	var tw: int = letters.w
	var th: int = letters.h
	var w := tw + 2 * Art.MARGIN_X
	var ox := (w - tw) / 2
	var mid := Broken.gap_mid(letters.idx, tw, th, ox, w)
	assert_ne(mid, w / 2, "not simply the middle")
	assert_lt(absi(mid - w / 2), w / 4, "near the middle")
	assert_false(Broken._column_has_letter(letters.idx, tw, th, mid - ox), "in a space between words")
	assert_eq(Broken.crack_x(w, 0), w / 2 + Broken.CRACK[0], "the combo broken popup's crack is unchanged")
