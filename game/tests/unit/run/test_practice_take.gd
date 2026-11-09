extends GutTest
## T-574 tweak 8 (step 1 of the board's recorded demos): the practice session's take tools. A take is
## recorded from the real car's steps, saved (the last one kept as the backup), and played back on
## the real car; the replay follows the take's checkpoints. Reset stage puts everything back.

const SessionScene := preload("res://scenes/run/practice_session.tscn")
const DIR := "user://t574_test_takes"

var session: PracticeSession


func before_each() -> void:
	_clear_dir()
	session = SessionScene.instantiate()
	session.takes_dir = DIR
	add_child_autofree(session)


func after_all() -> void:
	_clear_dir()


func _clear_dir() -> void:
	var d := DirAccess.open(DIR)
	if d == null:
		return
	for f in d.get_files():
		d.remove(f)


func _go(trick: String) -> void:
	session.setup(trick)
	session.start()
	session.set_focused(true)
	session.car.use_keyboard = false


## Steps the car with `keys` ([w, s, steer]) for `seconds`, as the window's physics does.
func _drive(keys: Array, seconds: float, held := false) -> void:
	for i in roundi(seconds * 50.0):
		session.car.use_keyboard = false
		session.car.scripted_input = keys
		session.car.scripted_jump_held = held
		session.car.physics_step()


## Steps a playing take to its end (its own keys drive the car).
func _play_out() -> void:
	var guard := 0
	while session.is_replaying() and guard < 5000:
		session.car.physics_step()
		guard += 1
	assert_false(session.is_replaying(), "the take played to its end")


func _record_alt_drift() -> Vector2:
	_go("alt_drift")
	session.start_recording()
	assert_true(session.is_recording())
	_drive([true, false, 1.0], 1.0)
	_drive([false, false, 1.0], 0.2)
	_drive([false, true, 1.0], 1.0)
	_drive([false, false, 0.0], 1.0)
	var end: Vector2 = session.car.model.get_position()
	assert_eq(session.stop_and_save(), OK)
	return end


func test_a_take_is_saved_in_the_format_and_the_last_one_kept_as_backup() -> void:
	_record_alt_drift()
	assert_eq(session.take_state, "saved")
	var path := PracticeTake.path_for("alt_drift", DIR)
	assert_true(FileAccess.file_exists(path))
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_eq(d.format, PracticeTake.FORMAT)
	assert_eq(d.trick, "alt_drift")
	assert_eq(int(d.steps), 160)
	var spawn: Dictionary = session.map.layout.spawn  # the playground's spawn (T-604: read, not written in)
	assert_eq(d.start, {"x": float(spawn.x), "y": float(spawn.y), "heading": float(spawn.heading)}, "the spawn the take started on")
	assert_lt((d.inputs as Array).size(), 10, "run-length: one row per change of keys")
	assert_eq((d.checkpoints as Array).size(), 3, "one a second")
	assert_eq(int(d.result.successes), 1, "the alt drift counted while recording")
	assert_false(FileAccess.file_exists(PracticeTake.backup_path_for("alt_drift", DIR)))
	_record_alt_drift()
	assert_true(FileAccess.file_exists(PracticeTake.backup_path_for("alt_drift", DIR)), "the previous take kept")
	assert_false(DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://data/levels/t574")), "never the board's folder")


func test_a_take_replays_on_the_real_car_exactly() -> void:
	var end := _record_alt_drift()
	session.reset_stage()
	assert_eq(session.successes, 0)
	assert_true(session.play_take())
	assert_eq(session.take_state, "playing")
	_play_out()
	assert_eq(session.take_state, "played")
	assert_almost_eq(session.car.model.get_position(), end, Vector2(0.001, 0.001), "the same end")
	assert_almost_eq(session.replay_drift, 0.0, 0.001, "on every checkpoint")
	assert_eq(session.successes, 1, "the replay does the trick")
	assert_true(session.car.use_keyboard, "the keyboard back after the take")


func test_a_grind_take_keeps_the_gift_the_hop_and_the_rail() -> void:
	_go("grind")
	session.start_recording()
	assert_eq(session.car.jump.tier, 1, "the Jump gift taken for the take")
	assert_false(session.is_gift_open())
	# West into the barrier corridor (as test_practice_session's GRIND_ROUTE), a hop held onto the rail.
	_drive([true, false, -1.0], 0.9)
	_drive([true, false, 1.0], 0.9)
	# T-590 (tweak 11): a tap hops, then Space held in the air catches the rail.
	session.car.press_jump()
	_drive([true, false, 0.0], 0.02, false)
	assert_true(session.car.airborne, "the tap hopped at once")
	_drive([true, false, 0.0], 1.5, true)
	_drive([false, false, 0.0], 1.0)
	assert_eq(session.stop_and_save(), OK)
	var take := PracticeTake.load_take("grind", DIR)
	assert_eq(take.gift, "jump")
	assert_true(take.frames.any(func(f): return f[4]), "the hop is in the take")
	var recorded_end: Vector2 = session.car.model.get_position()
	var recorded_successes := session.successes
	assert_true(session.play_take())
	_play_out()
	assert_almost_eq(session.car.model.get_position(), recorded_end, Vector2(0.001, 0.001))
	assert_eq(session.successes, recorded_successes)


## T-574 tweak 11: since T-590 a held press charges and the car hops on release, so a take keeps the
## press (not the hop) and a charged jump replays charged, at the same step and height.
func test_a_charged_jump_replays_charged() -> void:
	_go("grind")
	session.start_recording()
	_drive([true, false, 0.0], 0.5)
	session.car.press_jump()
	_drive([true, false, 0.0], 1.0, true)  # charging on the ground
	assert_false(session.car.airborne, "no hop while Space is held on the ground")
	var peak := 0.0
	for i in 60:
		_drive([true, false, 0.0], 0.02, false)
		peak = maxf(peak, session.car.height)
	assert_eq(session.stop_and_save(), OK)
	var take := PracticeTake.load_take("grind", DIR)
	assert_eq(take.frames.filter(func(f): return f[4]).size(), 1, "one press, kept at its step")
	var end: Vector2 = session.car.model.get_position()
	assert_true(session.play_take())
	var replay_peak := 0.0
	var guard := 0
	while session.is_replaying() and guard < 5000:
		session.car.physics_step()
		replay_peak = maxf(replay_peak, session.car.height)
		guard += 1
	assert_almost_eq(session.car.model.get_position(), end, Vector2(0.001, 0.001))
	assert_almost_eq(replay_peak, peak, 0.001, "as high as the charged jump")


func test_r_in_a_take_is_replayed() -> void:
	_go("drift")
	session.start_recording()
	_drive([true, false, 1.0], 0.6)
	var r := InputEventKey.new()
	r.physical_keycode = KEY_R
	r.pressed = true
	session._unhandled_input(r)
	_drive([true, false, -1.0], 0.6)
	var end: Vector2 = session.car.model.get_position()
	session.stop_and_save()
	assert_eq(PracticeTake.load_take("drift", DIR).resets, [30])
	session.play_take()
	_play_out()
	assert_almost_eq(session.car.model.get_position(), end, Vector2(0.001, 0.001))


func test_reset_stage_puts_everything_back() -> void:
	_go("alt_drift")
	_drive([true, false, 1.0], 1.0)
	session.state.add_trick("alternate_drift")
	session.state.add_trick("alternate_drift")
	session.state.add_trick("alternate_drift")
	assert_true(session.is_stamped())
	session.start_recording()
	session.reset_stage()
	assert_false(session.is_recording(), "a reset stops the recording")
	assert_eq(session.successes, 0)
	assert_false(session.is_stamped())
	var spawn: Dictionary = session.map.layout.spawn
	assert_eq(session.car.model.get_position(), Vector2(spawn.x, spawn.y), "the car on the spawn")
	assert_eq(session.car.model.get_velocity(), Vector2.ZERO, "standing still")
	assert_almost_eq(session.state.combo, ComboData.new().start_multiplier(), 0.0001, "no combo")
	assert_false(session.notebook.is_falling())
	assert_eq(session.take_state, "ready")


func test_play_with_no_take_says_so() -> void:
	_go("air_spin")
	assert_false(session.play_take())
	assert_eq(session.take_state, "no_take")
	assert_false(session.is_replaying())


# ---- T-574 tweak 9: the live keys -----------------------------------------------------------------

func test_the_live_keys_show_top_right_and_light_what_the_car_used() -> void:
	# In a viewport the size of the slide's window (1042 x 392), as the tutorial embeds it.
	var vp := SubViewport.new()
	vp.size = Vector2i(1042, 392)
	add_child_autofree(vp)
	session.get_parent().remove_child(session)
	vp.add_child(session)
	await get_tree().process_frame
	session._place_keys()  # (the slide puts the session in its viewport before it is ready)
	_go("grind")
	session._take_gift_now()
	var pad: KeyPad = session.keys_pad
	assert_not_null(pad)
	assert_true(pad.visible, "the player sees them too (data/tutorial_practice.json)")
	var vs := session.get_viewport().get_visible_rect().size
	assert_almost_eq(pad.position.x + pad.size.x, vs.x - PracticeSession.KEYS_MARGIN, 1.0, "top right")
	assert_lt(pad.position.y, vs.y / 3.0, "at the top, clear of the text band")
	assert_false(pad.get_global_rect().intersects(session.notebook.get_global_rect()), "clear of the notebook")
	_drive([true, false, 1.0], 0.1)
	assert_eq(pad.held, "WA")
	_drive([false, true, -1.0], 0.1)
	assert_eq(pad.held, "SD")
	session.car.press_jump()
	_drive([false, false, 0.0], 0.02, true)
	assert_true(pad.held.contains(KeyPad.SPACE), "Space on the hop")
	var r := InputEventKey.new()
	r.physical_keycode = KEY_R
	r.pressed = true
	session._unhandled_input(r)
	_drive([false, false, 0.0], 0.02)
	assert_false(pad.keys.has("R"), "no R keycap (T-597)")
	assert_eq(pad.keys.keys().size(), 4, "W, A, S, D")
	assert_true(pad.space_bar, "and the Space bar")
	assert_false(pad.held.contains("R"), "a reset lights no R")


func test_a_replay_lights_the_takes_keys_step_for_step() -> void:
	_go("alt_drift")
	session.start_recording()
	var seen: Array = []
	for keys in [[true, false, 1.0], [false, false, 1.0], [false, true, 1.0]]:
		_drive(keys, 0.2)
		seen.append(session.keys_pad.held)
	session.stop_and_save()
	session.play_take()
	var replayed: Array = []
	for i in 30:
		session.car.physics_step()
		if (i + 1) % 10 == 0:
			replayed.append(session.keys_pad.held)
	assert_eq(replayed, seen, "the same keys at the same steps")


func test_with_the_switch_off_the_player_sees_no_keys_but_a_take_shows_them() -> void:
	_go("alt_drift")
	session.show_keys_to_player = false
	_drive([true, false, 0.0], 0.04)
	assert_false(session.keys_pad.visible)
	session.start_recording()
	_drive([true, false, 0.0], 0.04)
	assert_true(session.keys_pad.visible, "shown while recording")
