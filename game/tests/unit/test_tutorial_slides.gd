extends GutTest
## Task T-382: the tutorial slides screen: arrows, Start and its signal, texts from the file,
## keyboard.

var slides: TutorialSlides


func before_each() -> void:
	slides = load("res://scenes/menu/tutorial_slides.tscn").instantiate()
	add_child_autofree(slides)


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	return e


func _visible_slide() -> int:
	for i in range(slides.slides.size()):
		if slides.slides[i].visible:
			return i
	return -1


func test_starts_on_slide_one_without_left_arrow() -> void:
	assert_eq(slides.slides.size(), 3)
	assert_eq(_visible_slide(), 0)
	assert_false(slides.left_arrow.visible)
	assert_true(slides.right_arrow.visible)


func test_arrows_move_forward_and_back() -> void:
	slides.right_arrow.pressed.emit()
	assert_eq(_visible_slide(), 1)
	assert_true(slides.left_arrow.visible)
	assert_true(slides.right_arrow.visible)
	slides.right_arrow.pressed.emit()
	assert_eq(_visible_slide(), 2)
	assert_false(slides.right_arrow.visible)
	slides.right_arrow.pressed.emit()
	assert_eq(_visible_slide(), 2, "no slide 4")
	slides.left_arrow.pressed.emit()
	assert_eq(_visible_slide(), 1)
	slides.left_arrow.pressed.emit()
	assert_eq(_visible_slide(), 0)
	slides.left_arrow.pressed.emit()
	assert_eq(_visible_slide(), 0, "no slide 0")


func test_slide_two_uses_the_trick_list_scene() -> void:
	assert_true(slides.trick_list is TrickList)
	assert_true(slides.slides[1].is_ancestor_of(slides.trick_list))
	assert_eq(slides.trick_list.labels.size(), 7)


func test_start_and_checkbox_only_on_slide_three() -> void:
	assert_true(slides.slides[2].is_ancestor_of(slides.start_button))
	assert_true(slides.slides[2].is_ancestor_of(slides.dont_show_checkbox))
	assert_false(slides.start_button.is_visible_in_tree())
	slides.show_slide(2)
	assert_true(slides.start_button.is_visible_in_tree())
	assert_true(slides.dont_show_checkbox.is_visible_in_tree())


func test_start_signal_checkbox_off() -> void:
	slides.show_slide(2)
	watch_signals(slides)
	slides.start_button.pressed.emit()
	assert_signal_emitted_with_parameters(slides, "start_pressed", [false])


func test_start_signal_checkbox_on() -> void:
	slides.show_slide(2)
	slides.dont_show_checkbox.button_pressed = true
	watch_signals(slides)
	slides.start_button.pressed.emit()
	assert_signal_emitted_with_parameters(slides, "start_pressed", [true])


func test_texts_match_the_file() -> void:
	var data: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/tutorial_text.json"))
	for key in slides.text_labels:
		var parts: PackedStringArray = key.split(".")
		var expected: String = data[parts[0]][parts[1]]
		var node: Control = slides.text_labels[key]
		var shown: String = node.tooltip_text if key.begins_with("arrow.") else node.text
		assert_eq(shown, expected, key)
	assert_gt(slides.text_labels.size(), 8)


func test_keyboard_arrows_and_a_d() -> void:
	slides._input(_key(KEY_RIGHT))
	assert_eq(_visible_slide(), 1)
	slides._input(_key(KEY_D))
	assert_eq(_visible_slide(), 2)
	slides._input(_key(KEY_D))
	assert_eq(_visible_slide(), 2)
	slides._input(_key(KEY_LEFT))
	assert_eq(_visible_slide(), 1)
	slides._input(_key(KEY_A))
	assert_eq(_visible_slide(), 0)
	slides._input(_key(KEY_A))
	assert_eq(_visible_slide(), 0)


func test_focus_order() -> void:
	assert_true(slides.right_arrow.has_focus(), "slide 1: the right arrow")
	slides.show_slide(1)
	assert_true(slides.right_arrow.has_focus(), "slide 2: the right arrow")
	slides.show_slide(2)
	assert_true(slides.start_button.has_focus(), "slide 3: Start")


func test_enter_on_the_focused_start_button() -> void:
	slides.show_slide(2)
	watch_signals(slides)
	assert_true(slides.start_button.has_focus())
	var e := InputEventKey.new()
	e.keycode = KEY_ENTER
	e.physical_keycode = KEY_ENTER
	e.pressed = true
	slides.get_viewport().push_input(e)
	var up := InputEventKey.new()
	up.keycode = KEY_ENTER
	up.physical_keycode = KEY_ENTER
	up.pressed = false
	slides.get_viewport().push_input(up)
	await wait_process_frames(2)
	assert_signal_emitted(slides, "start_pressed")
