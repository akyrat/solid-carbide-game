extends GutTest
## Task T-562: the tutorial slides with T-561's real practice session in their windows (the seam:
## TutorialSlides.PRACTICE_SCENE). Pending until T-561's scene is merged into this branch; then it
## checks that each trick slide's window holds the real session set to its trick, that only the
## showing one runs and has the keyboard (the car's own input_enabled), that Space reaches the car
## in the window, that the grind window opens with its gift, and that the session's completed
## signal shows the success message over its window.

var slides: TutorialSlides
var _old_size := Vector2i.ZERO


func before_each() -> void:
	if not ResourceLoader.exists(TutorialSlides.PRACTICE_SCENE):
		return
	_old_size = get_tree().root.size
	get_tree().root.size = Vector2i(TutorialSlides.STAGE)
	slides = load("res://scenes/menu/tutorial_slides.tscn").instantiate()
	add_child_autofree(slides)


func after_each() -> void:
	if _old_size != Vector2i.ZERO:
		get_tree().root.size = _old_size
		_old_size = Vector2i.ZERO


func _ready_or_pending() -> bool:
	if slides == null:
		pending("T-561's practice scene is not in this branch yet")
		return false
	return true


func test_each_window_holds_the_real_session_set_to_its_trick() -> void:
	if not _ready_or_pending():
		return
	for i in range(4):
		slides.show_slide(1 + i)
		await wait_process_frames(2)
		var session = slides.practices[i]
		assert_not_null(session, "slide %d" % (i + 2))
		assert_eq(session.scene_file_path, TutorialSlides.PRACTICE_SCENE)
		assert_eq(session.trick, TutorialSlides.TRICK_SLIDES[i][1])
		assert_true(session.focused, "the showing window has the keyboard")
		assert_true(session.car.input_enabled, "the car reads the keys")
		for j in range(i):
			assert_false(slides.practices[j].is_running(), "the hidden ones are paused")
			assert_false(slides.practices[j].focused)


func test_space_reaches_the_car_and_presses_no_button() -> void:
	if not _ready_or_pending():
		return
	slides.show_slide(1)
	await wait_process_frames(3)
	watch_signals(slides)
	var session = slides.practices[0]
	var car = session.car
	var e := InputEventKey.new()
	e.keycode = KEY_SPACE
	e.physical_keycode = KEY_SPACE
	e.pressed = true
	slides.get_viewport().push_input(e)
	assert_true(car._jump_pressed, "the Space press reached the car in the window")
	assert_eq(slides.current, 1, "no slide change")
	assert_signal_not_emitted(slides, "start_pressed")


func test_the_grind_window_opens_with_its_gift() -> void:
	if not _ready_or_pending():
		return
	slides.show_slide(4)
	await wait_process_frames(3)
	assert_true(slides.practices[3].is_gift_open(), "the Jump gift is offered")


func test_the_real_completed_signal_stamps_the_notebook_and_shows_no_message() -> void:
	# T-574 (the board): a green check stamp on the notebook page, no big message over the window.
	if not _ready_or_pending():
		return
	slides.show_slide(2)
	await wait_process_frames(2)
	assert_false(slides.practices[1].is_stamped())
	slides.practices[1].completed.emit()
	assert_true(slides.practices[1].is_stamped())
	assert_true(slides.practices[1].notebook.is_ancestor_of(slides.practices[1].stamp), "on the notebook page")
	assert_null(slides.find_child("Success", true, false), "no success message on the slides")
	slides.show_slide(0)
	assert_false(slides.practices[1].is_running(), "paused when its slide hides")


## One success of `trick_id` from the car in the window, the way T-561's own tests make one.
func _do(session, trick_id: String) -> void:
	var car = session.car
	match trick_id:
		"rail_grind":
			car.grind.grind_ended.emit("end", 1.0, 6.0)
		"extended_drift":
			car.tricks.last_trick_seconds = 1.2
			car.trick.emit(trick_id)
		_:
			car.trick.emit(trick_id)
	car.stepped.emit()


func test_every_trick_slide_counts_to_three_and_stamps_its_notebook() -> void:
	if not _ready_or_pending():
		return
	var tricks := ["extended_drift", "alternate_drift", "air_three_sixty", "rail_grind"]
	for i in range(4):
		slides.show_slide(1 + i)
		await wait_process_frames(3)
		var session = slides.practices[i]
		if i == 3:
			assert_true(session.is_gift_open(), "the grind starts with the Jump gift")
			session.gift_screen.skip_animation()
			session.take_gift()
			assert_eq(session.car.jump.tier, 1, "Jump taken")
		if i == 0:
			# T-565: the drift slide counts 3 s of drifting in total, over several drifts.
			for n in range(3):
				_do(session, tricks[i])
				assert_eq(session.successes, 0, "a LONG DRIFT! is no success on the drift slide")
				assert_false(session.is_stamped(), "slide 2: no stamp before 3 s")
				session.add_drift_seconds(0.9)
			assert_false(session.is_stamped(), "slide 2: no stamp at 2.7 s")
			session.add_drift_seconds(0.3)
			assert_true(session.notebook.rows[0].label.text.contains("3.0/3"), "the notebook shows 3.0/3")
			assert_true(session.is_stamped(), "slide 2: the stamp at 3 s in total")
			continue
		for n in range(3):
			assert_false(session.is_stamped(), "slide %d: no stamp after %d" % [i + 2, n])
			_do(session, tricks[i])
			assert_eq(session.successes, n + 1)
		session.notebook.finish_falls()  # T-563: the count arrives when the name box has landed
		assert_true(session.notebook.rows[0].label.text.contains("3/3"), "the notebook shows 3/3")
		assert_true(session.is_stamped(), "slide %d: the stamp after the third" % (i + 2))


func _hold(code: Key, on: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = on
	Input.parse_input_event(e)


func test_w_and_a_drive_the_car_on_a_trick_slide_and_change_no_slide() -> void:
	if not _ready_or_pending():
		return
	slides.show_slide(1)
	await wait_process_frames(3)
	var car = slides.practices[0].car
	var start_pos: Vector2 = car.position
	var start_rot: float = car.rotation
	_hold(KEY_W, true)
	_hold(KEY_A, true)
	await wait_physics_frames(40)
	_hold(KEY_A, false)
	_hold(KEY_D, true)
	await wait_physics_frames(10)
	_hold(KEY_D, false)
	_hold(KEY_W, false)
	Input.flush_buffered_events()
	assert_gt(car.position.distance_to(start_pos), 0.5, "W drove the car")
	assert_ne(car.rotation, start_rot, "A and D steered it")
	assert_eq(slides.current, 1, "A and D changed no slide")
