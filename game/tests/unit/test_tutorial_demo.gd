extends GutTest
## T-574 tweak 10, step 2: the recorded demo on the tutorial's trick slides, with the real practice
## session. A trick slide with a saved take plays it in its window first (the real car replaying the
## keys, the keys lit); at its end the window minimises (shrinks toward the corner and fades), the
## stage resets and the player drives, the window back at full size. A driving key skips it. With
## no take, or the demo off, the slide is as before.

const DIR := "user://t574_test_demo_takes"

var slides: TutorialSlides
var _old_size := Vector2i.ZERO
var finished: Array = []


func before_each() -> void:
	_clear_dir()
	_old_size = get_tree().root.size
	get_tree().root.size = Vector2i(TutorialSlides.STAGE)
	slides = load("res://scenes/menu/tutorial_slides.tscn").instantiate()
	slides.takes_dir_override = DIR
	add_child_autofree(slides)
	finished = []
	slides.demo_finished.connect(func(i: int, skipped: bool) -> void: finished.append([i, skipped]))


func after_each() -> void:
	get_tree().root.size = _old_size


func after_all() -> void:
	_clear_dir()


func _clear_dir() -> void:
	var d := DirAccess.open(DIR)
	if d == null:
		return
	for f in d.get_files():
		d.remove(f)


## A short drift take (W + A for `seconds`) saved for the drift slide.
func _save_drift_take(seconds := 1.0) -> PracticeTake:
	var t := PracticeTake.new()
	t.trick = "drift"
	t.start = {"x": -7.0, "y": -1.0, "heading": 0.0}
	for i in roundi(seconds * 50.0):
		t.add_frame(true, false, 1.0, false, false)
	assert_eq(t.save(DIR), OK)
	return t


## Steps the showing practice's car until its demo take has played out.
func _play_out(session) -> void:
	var guard := 0
	while session.is_replaying() and guard < 3000:
		session.car.physics_step()
		guard += 1


func _key(code: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = true
	slides._input(e)


func test_the_settings_are_read_from_the_practice_file() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TutorialSlides.PRACTICE_SETTINGS_PATH))
	assert_eq(slides.demo_enabled, bool(d.demo_enabled))
	assert_almost_eq(slides.demo_minimise_seconds, float(d.demo_minimise_seconds), 0.0001)
	assert_eq(slides.demo_minimise_corner, String(d.demo_minimise_corner))
	assert_true(TutorialSlides.DEMO_CORNERS.has(slides.demo_minimise_corner))
	assert_almost_eq(float(d.demo_minimise_seconds), 0.4, 0.0001, "about 0.4 s, as asked")


func test_a_take_plays_first_then_the_window_minimises_and_the_player_drives() -> void:
	_save_drift_take()
	slides.demo_minimise_seconds = 30.0
	slides.show_slide(1)
	var session = slides.practices[0]
	assert_eq(slides.demo_states[0], "playing")
	assert_true(session.is_replaying(), "the take plays in the window")
	assert_false(session.car.use_keyboard, "the keyboard is off while it plays")
	assert_true(session.keys_pad.visible, "the keys light")
	session.car.physics_step()
	assert_true(session.held_keys().contains("W") and session.held_keys().contains("A"), session.held_keys())
	_play_out(session)
	assert_gt(session.drift_seconds, 0.0, "the take drove the real car")
	await wait_process_frames(2)
	assert_eq(slides.demo_states[0], "minimising")
	assert_false(session.is_running(), "the last picture holds while it minimises")
	# The tween stepped by hand: headless frames can be long enough to finish it in one.
	var frame: Control = slides.practice_frames[0]
	slides._demo_tween.custom_step(slides.demo_minimise_seconds * 0.5)
	assert_lt(frame.scale.x, 1.0, "the window shrinks")
	assert_gt(frame.scale.x, slides.demo_minimise_scale)
	assert_lt(frame.modulate.a, 1.0, "and fades")
	assert_eq(frame.pivot_offset, frame.size, "toward the bottom right corner")
	assert_eq(slides.demo_states[0], "minimising")
	slides._demo_tween.custom_step(slides.demo_minimise_seconds)
	assert_eq(slides.demo_states[0], "done")
	assert_eq(finished, [[0, false]])
	assert_eq(frame.scale, Vector2.ONE, "the window back at full size")
	assert_eq(frame.modulate.a, 1.0)
	assert_almost_eq(session.drift_seconds, 0.0, 0.0001, "the stage reset")
	assert_true(session.is_running())
	assert_true(session.car.use_keyboard and session.car.input_enabled, "the player drives")
	var start: Dictionary = session.start_point()
	assert_almost_eq(session.car.model.get_position(), start.position, Vector2(0.001, 0.001), "on the spawn")


func test_the_demo_plays_once_per_slide() -> void:
	_save_drift_take(0.2)
	slides.demo_minimise_seconds = 0.0
	slides.show_slide(1)
	_play_out(slides.practices[0])
	await wait_process_frames(2)
	assert_eq(slides.demo_states[0], "done")
	slides.show_slide(2)
	slides.show_slide(1)
	assert_false(slides.practices[0].is_replaying(), "coming back, the player's practice goes on")


func test_a_driving_key_skips_the_demo() -> void:
	for code in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SPACE, KEY_R]:
		_clear_dir()
		_save_drift_take(3.0)
		slides.demo_states[0] = ""
		slides.show_slide(0)
		slides.show_slide(1)
		var session = slides.practices[0]
		assert_true(session.is_replaying())
		for i in 20:
			session.car.physics_step()
		_key(code)
		assert_false(session.is_replaying(), "key %d skips" % code)
		assert_eq(slides.demo_states[0], "done")
		assert_almost_eq(session.drift_seconds, 0.0, 0.0001, "the stage reset at once")
		assert_eq(slides.practice_frames[0].scale, Vector2.ONE, "no minimise on a skip")
		assert_true(session.car.use_keyboard)
	assert_eq(finished.size(), 6)
	assert_true(finished.all(func(f): return f[1]), "each a skip")


func test_other_keys_do_not_skip() -> void:
	_save_drift_take(3.0)
	slides.show_slide(1)
	_key(KEY_Q)
	assert_true(slides.practices[0].is_replaying())


func test_without_a_take_the_slide_is_as_before() -> void:
	slides.show_slide(1)
	var session = slides.practices[0]
	assert_eq(slides.demo_states[0], "done")
	assert_false(session.is_replaying())
	assert_true(session.car.use_keyboard and session.car.input_enabled, "the player drives at once")
	assert_eq(finished, [])
	assert_eq(slides.practice_frames[0].scale, Vector2.ONE)


func test_with_the_demo_off_a_take_is_not_played() -> void:
	_save_drift_take()
	slides.demo_enabled = false
	slides.show_slide(1)
	assert_false(slides.practices[0].is_replaying())


func test_leaving_the_slide_while_it_minimises_hands_over_at_once() -> void:
	_save_drift_take(0.2)
	slides.demo_minimise_seconds = 5.0
	slides.show_slide(1)
	_play_out(slides.practices[0])
	await wait_process_frames(2)
	assert_eq(slides.demo_states[0], "minimising")
	slides.show_slide(2)
	assert_eq(slides.demo_states[0], "done")
	assert_eq(slides.practice_frames[0].scale, Vector2.ONE)
	assert_false(slides.practices[0].is_running(), "paused: its slide is hidden")


func test_a_take_tool_during_the_demo_ends_it() -> void:
	_save_drift_take(3.0)
	slides.show_slide(1)
	slides.practices[0].reset_stage()  # F5
	assert_eq(slides.demo_states[0], "done")
	assert_false(slides.practices[0].is_replaying())


# ---- T-574 tweak 12: Replay, Skip demo and "Your turn" -------------------------------------------

func _text(key: String) -> String:
	return TrickList.text(key)


func test_the_buttons_and_label_use_t594s_texts_and_never_take_the_focus() -> void:
	assert_eq(slides.replay_buttons.size(), 4)
	assert_eq(slides.skip_demo_buttons.size(), 4)
	assert_eq(slides.your_turn_labels.size(), 4)
	for i in 4:
		assert_eq(slides.replay_buttons[i].text, _text("demo.replay").to_upper())
		assert_eq(slides.skip_demo_buttons[i].text, _text("demo.skip").to_upper())
		assert_eq(slides.your_turn_labels[i].text, _text("demo.your_turn"))
		assert_true(slides.your_turn_labels[i].uppercase)
		for b in [slides.replay_buttons[i], slides.skip_demo_buttons[i]]:
			assert_eq(b.focus_mode, Control.FOCUS_NONE, "clicked only")
			assert_eq(b.get_meta("hud_button"), "button", "the tutorial's shared button")
	assert_eq(_text("demo.replay"), "Replay")
	assert_eq(_text("demo.skip"), "Skip demo")
	assert_eq(_text("demo.your_turn"), "Your turn")


func test_the_buttons_sit_under_the_window_and_above_the_dots() -> void:
	_save_drift_take(3.0)
	slides.show_slide(1)
	await wait_process_frames(2)
	var window: Rect2 = slides.practice_frames[0].get_global_rect()
	for b in [slides.replay_buttons[0], slides.skip_demo_buttons[0]]:
		var r: Rect2 = b.get_global_rect()
		assert_gt(r.position.y, window.end.y, "under the window")
		assert_lt(r.end.y, slides._dots[0].get_global_rect().position.y, "above the dots")
		assert_true(r.position.x >= window.position.x and r.end.x <= window.end.x + 0.5, "within its width")


func test_skip_demo_shows_while_the_recording_plays_and_ends_it() -> void:
	_save_drift_take(3.0)
	slides.show_slide(1)
	var session = slides.practices[0]
	assert_true(slides.skip_demo_buttons[0].visible, "while it plays")
	assert_true(slides.replay_buttons[0].visible)
	slides.skip_demo_buttons[0].pressed.emit()
	assert_false(session.is_replaying())
	assert_eq(finished, [[0, true]])
	assert_false(slides.skip_demo_buttons[0].visible, "gone once the player drives")
	assert_true(slides.replay_buttons[0].visible, "Replay stays")
	assert_true(session.car.use_keyboard)
	assert_true(slides.is_your_turn_showing(0), "Your turn after a skip")


func test_replay_plays_the_recording_again_at_any_time() -> void:
	_save_drift_take(0.4)
	slides.demo_minimise_seconds = 0.0
	slides.show_slide(1)
	var session = slides.practices[0]
	_play_out(session)
	await wait_process_frames(2)
	assert_eq(slides.demo_states[0], "done")
	for i in 30:
		session.car.physics_step()  # the player drives a bit
	slides.replay_buttons[0].pressed.emit()
	assert_true(session.is_replaying(), "the recording plays again")
	assert_eq(slides.demo_states[0], "playing")
	assert_true(slides.skip_demo_buttons[0].visible)
	assert_false(slides.is_your_turn_showing(0))
	for i in 5:
		session.car.physics_step()
	slides.replay_buttons[0].pressed.emit()  # mid-replay: from the start again
	assert_eq(session.replay_step, 0)
	assert_true(session.is_replaying())


func test_your_turn_shows_2_s_after_the_recording_ends_then_fades() -> void:
	_save_drift_take(0.2)
	slides.demo_minimise_seconds = 0.0
	slides.show_slide(1)
	assert_false(slides.is_your_turn_showing(0), "not while it plays")
	_play_out(slides.practices[0])
	await wait_process_frames(2)
	var label: Label = slides.your_turn_labels[0]
	assert_true(label.visible)
	assert_eq(label.modulate.a, 1.0)
	assert_true(slides.practice_frames[0].get_global_rect().encloses(label.get_global_rect()), "over the window")
	var tw: Tween = slides._turn_tween
	tw.custom_step(slides.your_turn_seconds - tw.get_total_elapsed_time() - 0.05)
	assert_eq(label.modulate.a, 1.0, "in full for 2 s")
	tw.custom_step(0.05 + slides.your_turn_fade_seconds * 0.5)
	assert_lt(label.modulate.a, 1.0, "then it fades")
	assert_gt(label.modulate.a, 0.0)
	tw.custom_step(slides.your_turn_fade_seconds)
	assert_false(label.visible, "and is gone")


func test_your_turn_numbers_come_from_the_settings_file() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TutorialSlides.PRACTICE_SETTINGS_PATH))
	assert_almost_eq(slides.your_turn_seconds, float(d.your_turn_seconds), 0.0001)
	assert_almost_eq(slides.your_turn_fade_seconds, float(d.your_turn_fade_seconds), 0.0001)
	assert_almost_eq(float(d.your_turn_seconds), 2.0, 0.0001, "2 seconds, as asked")


func test_without_a_recording_there_is_no_replay_or_skip_button() -> void:
	slides.show_slide(1)
	assert_false(slides.replay_buttons[0].visible)
	assert_false(slides.skip_demo_buttons[0].visible)
	assert_false(slides.is_your_turn_showing(0))
