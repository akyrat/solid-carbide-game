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


func test_the_real_completed_signal_shows_the_success_message() -> void:
	if not _ready_or_pending():
		return
	slides.show_slide(2)
	await wait_process_frames(2)
	assert_false(slides.success_messages[1].visible)
	slides.practices[1].completed.emit()
	assert_true(slides.success_messages[1].visible)
	slides.show_slide(0)
	assert_false(slides.practices[1].is_running(), "paused when its slide hides")
