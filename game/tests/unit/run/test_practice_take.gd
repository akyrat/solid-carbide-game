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
	assert_eq(d.start, {"x": -7.0, "y": -1.0, "heading": 0.0}, "the spawn the take started on")
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
	session.car.press_jump()
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
	assert_eq(session.car.model.get_position(), Vector2(-7, -1), "the car on the spawn")
	assert_eq(session.car.model.get_velocity(), Vector2.ZERO, "standing still")
	assert_almost_eq(session.state.combo, ComboData.new().start_multiplier(), 0.0001, "no combo")
	assert_false(session.notebook.is_falling())
	assert_eq(session.take_state, "ready")


func test_play_with_no_take_says_so() -> void:
	_go("air_spin")
	assert_false(session.play_take())
	assert_eq(session.take_state, "no_take")
	assert_false(session.is_replaying())
