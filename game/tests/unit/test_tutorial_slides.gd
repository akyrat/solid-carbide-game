extends GutTest
## Tasks T-382, T-485 and T-562: the interactive tutorial slides: six slides in order (the loop,
## four trick slides with a practice window, the last slide), the dots, the arrows and Skip, texts
## from the file (T-559's keys; none from code, the retired keys unused), the practice windows
## (each embeds the practice scene set to its trick, only the showing one runs and has the
## keyboard, the success message over the window after the third success), the keys (A, D and
## Space drive on the trick slides and press nothing), Go live and Don't show again.
## The practice scene is a stand-in here (tests/fixtures/fake_practice_session.tscn, the same API
## as T-561's); test_tutorial_practice_real.gd runs the real one once it is in.

const RETIRED_KEYS := ["slide1.controls", "slide1.drift", "slide2.chain", "slide2.gift", "slide3.goal",
	"slide1.title", "slide2.title", "slide3.title", "slide3.missions", "kicker.controls", "kicker.loop",
	"kicker.missions", "slide1.drift_rule", "slide2.clip_ramp"]
const SOURCE := "res://scripts/menu/tutorial_slides.gd"
const FAKE := "res://tests/fixtures/fake_practice_session.tscn"
const TRICK_KEYS := ["drift", "altdrift", "airspin", "grind"]
const TRICK_NAMES := ["drift", "alt_drift", "air_spin", "grind"]

var slides: TutorialSlides
var _old_size := Vector2i.ZERO


func before_each() -> void:
	slides = load("res://scenes/menu/tutorial_slides.tscn").instantiate()
	add_child_autofree(slides)
	slides.practice_scene_path = FAKE  # before a trick slide first shows


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = true
	return e


func _push(code: Key) -> void:
	slides.get_viewport().push_input(_key(code))
	var up := _key(code)
	up.pressed = false
	slides.get_viewport().push_input(up)


## Makes the window 1280 x 720 for a click test (the headless window is 64 x 64, too small to aim
## a click); after_each puts it back.
func _full_size() -> void:
	_old_size = get_tree().root.size
	get_tree().root.size = Vector2i(TutorialSlides.STAGE)
	await wait_process_frames(2)


func after_each() -> void:
	if _old_size != Vector2i.ZERO:
		get_tree().root.size = _old_size
		_old_size = Vector2i.ZERO


func _click(control: Control) -> void:
	var centre: Vector2 = control.get_global_rect().get_center()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = centre
	click.global_position = centre
	click.pressed = true
	slides.get_viewport().push_input(click)
	var up := click.duplicate() as InputEventMouseButton
	up.pressed = false
	slides.get_viewport().push_input(up)


func _visible_slide() -> int:
	for i in range(slides.slides.size()):
		if slides.slides[i].visible:
			return i
	return -1


func _file() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/tutorial_text.json"))


func _at(key: String) -> String:
	var node: Variant = _file()
	for part in key.split("."):
		node = node[part]
	return node


func _all(node: Node, kind: String) -> Array:
	var out: Array = []
	for c in node.get_children():
		if c.is_class(kind):
			out.append(c)
		out.append_array(_all(c, kind))
	return out


# --- The six slides and their texts ----------------------------------------------------------------

func test_six_slides_in_order_with_their_headlines() -> void:
	assert_eq(slides.slides.size(), 6)
	var keys := ["tutorial.loop.title", "tutorial.trick.drift.title", "tutorial.trick.altdrift.title",
		"tutorial.trick.airspin.title", "tutorial.trick.grind.title", "slide4.title"]
	for i in range(6):
		assert_eq(slides.slides[i].name, "Slide%d" % (i + 1))
		var title: Label = slides.slides[i].get_node("Title")
		assert_eq(title.text, _at(keys[i]))
		assert_true(title.uppercase, "shown in capitals")
	assert_eq(_at("tutorial.loop.title"), "The content loop")
	assert_eq(_at("tutorial.trick.grind.title"), "Grind style")
	assert_eq(_at("slide4.title"), "Survive the stream")


func test_the_loop_slide_has_its_four_steps_and_its_point() -> void:
	var s: Control = slides.slides[0]
	for n in range(1, 5):
		var l: Label = slides.text_labels["tutorial.loop.step%d" % n]
		assert_true(s.is_ancestor_of(l), "step %d on the loop slide" % n)
		assert_eq(l.text, _at("tutorial.loop.step%d" % n))
	assert_eq(slides.step_pictures.size(), 4)
	var point: Label = slides.text_labels["tutorial.loop.point"]
	assert_true(s.is_ancestor_of(point))
	assert_eq(point.text, _at("tutorial.loop.point"))


func test_each_trick_slide_has_its_instruction_and_window() -> void:
	for i in range(4):
		var s: Control = slides.slides[1 + i]
		var l: Label = slides.text_labels["tutorial.trick.%s.instruction" % TRICK_KEYS[i]]
		assert_true(s.is_ancestor_of(l), TRICK_KEYS[i])
		assert_eq(l.text, _at("tutorial.trick.%s.instruction" % TRICK_KEYS[i]))
		assert_true(s.is_ancestor_of(slides.practice_frames[i]), "window on slide %d" % (i + 2))
	assert_true(slides.slides[4].is_ancestor_of(slides.text_labels["tutorial.grind_hint"]), "the Jump hint on the grind slide")
	assert_eq(slides.text_labels["tutorial.grind_hint"].text, _at("tutorial.grind_hint"))


func test_the_window_spans_the_slide_at_the_same_height() -> void:
	# T-574 (the board): side to side (the content width, between the arrows), still 400 high.
	for i in range(4):
		var frame: Control = slides.practice_frames[i]
		assert_almost_eq(frame.position.x, TutorialSlides.SIDE, 0.5, "from the left padding")
		assert_almost_eq(frame.position.x + frame.size.x, TutorialSlides.STAGE.x - TutorialSlides.SIDE, 0.5, "to the right padding")
		assert_almost_eq(frame.size.y, 400.0, 0.5, "the same height")
		assert_gt(frame.position.x, slides.left_arrow.position.x + slides.left_arrow.size.x, "clear of the left arrow")
		assert_lt(frame.position.x + frame.size.x, slides.right_arrow.position.x, "clear of the right arrow")


func test_the_tutorial_text_is_in_the_game_window() -> void:
	# T-574 (the board): the instruction (and the grind's hint) on a band along the window's bottom.
	await get_tree().process_frame
	for i in range(4):
		var frame: Control = slides.practice_frames[i]
		var l: Label = slides.text_labels["tutorial.trick.%s.instruction" % TRICK_KEYS[i]]
		assert_true(frame.is_ancestor_of(l), "%s: inside the window" % TRICK_KEYS[i])
		var band: Control = frame.get_node("Instructions")
		var r := band.get_rect()
		assert_almost_eq(r.end.y, frame.size.y - TutorialSlides.WINDOW_BORDER, 1.0, "on the bottom edge")
		assert_gt(r.position.y, frame.size.y / 2.0, "below the centre (clear of the success message)")
		assert_eq(band.mouse_filter, Control.MOUSE_FILTER_IGNORE, "clicks reach the game")
	assert_true(slides.practice_frames[3].is_ancestor_of(slides.text_labels["tutorial.grind_hint"]))


func test_the_dots_show_six_and_follow_the_slide() -> void:
	var dots: Node = slides.stage.get_node("Dots")
	assert_eq(dots.get_child_count(), 6)
	slides.show_slide(2)
	for i in range(6):
		var on: bool = (dots.get_child(i) as ColorRect).color == TutorialSlides.DOT_ON
		assert_eq(on, i == 2, "dot %d" % i)


func test_kickers_follow_the_pattern() -> void:
	for i in range(5):
		assert_eq(slides.kickers[i].text, "%d / 6" % (i + 1), "slides 1 to 5 have no topic text")
	var expected: String = _at("kicker.pattern").replace("{n}", "6").replace("{total}", "6") \
		.replace("{topic}", _at("kicker.goal"))
	assert_eq(slides.kickers[5].text, expected)


func test_texts_match_the_file() -> void:
	for key in slides.text_labels:
		var expected := _at(key)
		var node: Control = slides.text_labels[key]
		var shown: String = node.tooltip_text if key.begins_with("arrow.") else node.text
		if key == "button.skip":
			assert_eq(shown, expected.to_upper(), key)
		else:
			assert_eq(shown, expected, key)
	for key in ["tutorial.loop.title", "tutorial.loop.step1", "tutorial.loop.step4", "tutorial.loop.point",
			"tutorial.trick.drift.title", "tutorial.trick.drift.instruction", "tutorial.trick.altdrift.instruction",
			"tutorial.trick.airspin.instruction", "tutorial.trick.grind.instruction",
			"tutorial.grind_hint", "slide4.title", "slide4.kaiju", "button.start", "checkbox.dont_show",
			"button.skip", "arrow.left", "arrow.right"]:
		assert_true(slides.text_labels.has(key), "uses " + key)


func test_the_retired_keys_are_not_used() -> void:
	var source := FileAccess.get_file_as_string(SOURCE)
	for key in RETIRED_KEYS:
		assert_false(slides.text_labels.has(key), key)
		assert_false(source.contains('"%s"' % key), "no use of " + key)
	assert_false(source.contains("ClipPlayer"), "no clips any more")


func test_no_word_on_the_slides_comes_from_code() -> void:
	var allowed := {}
	for key in slides.text_labels:
		allowed[_at(key).to_lower()] = true
	for k in slides.kickers:
		allowed[k.text.to_lower()] = true
	var numbers := RegEx.create_from_string("^[0-9:,/ ]+$")
	for l in _all(slides, "Label"):
		var t: String = l.text.to_lower()
		if t == "" or numbers.search(t) != null:
			continue  # the timeline's times, the kickers' numbers
		assert_true(allowed.has(t), "text from a file: '%s'" % t)


func test_the_pictures_are_the_games_own_art() -> void:
	for path in slides.picture_paths:
		assert_true(path.begins_with("res://art/"), path)
		assert_true(ResourceLoader.exists(path), path)
	for expected in ["res://art/hud/subs_icon.png", "res://art/gift_pack/package.png",
			"res://art/kaiju/kaiju_s.png", "res://art/hud/live_badge.png",
			"res://art/tutorial/tricks/extended_drift.png", "res://art/hud/weapon_icons.png"]:
		assert_true(slides.picture_paths.has(expected), expected)
	assert_eq(slides.gift_packs.size(), 4, "four gift packs on the timeline")
	assert_not_null(slides.kaiju_picture.texture)


func test_the_last_slide_timeline_times_and_the_kaiju() -> void:
	var times: Array = []
	for l in slides.time_labels:
		times.append(l.text)
	assert_eq(times, ["4:00", "2:00", "1:00"])
	assert_eq(slides.kaiju_label.text, _at("slide4.kaiju"))
	assert_true(slides.slides[5].is_ancestor_of(slides.kaiju_label))


# --- Arrows, Skip, Go live, Don't show again --------------------------------------------------------

func test_starts_on_slide_one_without_left_arrow() -> void:
	assert_eq(_visible_slide(), 0)
	assert_false(slides.left_arrow.visible)
	assert_true(slides.right_arrow.visible)


func test_arrows_move_forward_and_back() -> void:
	for i in range(1, 6):
		slides.right_arrow.pressed.emit()
		assert_eq(_visible_slide(), i)
		assert_true(slides.left_arrow.visible)
	assert_false(slides.right_arrow.visible, "no right arrow on the last slide")
	slides.right_arrow.pressed.emit()
	assert_eq(_visible_slide(), 5, "no slide 7")
	for i in range(4, -1, -1):
		slides.left_arrow.pressed.emit()
		assert_eq(_visible_slide(), i)
	slides.left_arrow.pressed.emit()
	assert_eq(_visible_slide(), 0, "no slide 0")


func test_the_arrows_and_skip_work_by_mouse_on_a_trick_slide() -> void:
	await _full_size()
	slides.show_slide(2)
	await wait_process_frames(2)
	_click(slides.right_arrow)
	await wait_process_frames(2)
	assert_eq(_visible_slide(), 3, "a click on the right arrow")
	assert_false(slides.right_arrow.has_focus(), "the click gives it no focus")
	_click(slides.left_arrow)
	await wait_process_frames(2)
	assert_eq(_visible_slide(), 2, "a click on the left arrow")
	_click(slides.skip_button)
	await wait_process_frames(2)
	assert_eq(_visible_slide(), 5, "a click on Skip")


func test_skip_jumps_to_the_last_slide_from_every_slide() -> void:
	for i in range(5):
		slides.show_slide(i)
		assert_true(slides.skip_button.is_visible_in_tree(), "Skip on slide %d" % (i + 1))
		slides.skip_button.pressed.emit()
		assert_eq(_visible_slide(), 5)
		assert_true(slides.start_button.has_focus())
	assert_eq(slides.skip_button.text, _at("button.skip").to_upper())


func test_the_last_slide_has_no_skip_and_going_back_brings_it_back() -> void:
	slides.show_slide(5)
	assert_false(slides.skip_button.is_visible_in_tree(), "no Skip on the last slide")
	assert_true(slides.start_button.is_visible_in_tree(), "Go live stays")
	slides.previous_slide()
	assert_true(slides.skip_button.is_visible_in_tree(), "Skip is back on slide 5")
	slides.show_slide(0)
	slides.next_slide()
	slides.skip_to_last()
	assert_false(slides.skip_button.is_visible_in_tree(), "none after Skip either")


func test_go_live_and_the_checkbox_only_on_the_last_slide() -> void:
	assert_true(slides.slides[5].is_ancestor_of(slides.start_button))
	assert_true(slides.slides[5].is_ancestor_of(slides.dont_show_checkbox))
	assert_false(slides.start_button.is_visible_in_tree())
	slides.show_slide(5)
	assert_true(slides.start_button.is_visible_in_tree())
	assert_true(slides.dont_show_checkbox.is_visible_in_tree())
	assert_not_null(slides.start_button.icon, "the HUD's LIVE badge")


func test_start_signal_checkbox_off() -> void:
	slides.show_slide(5)
	watch_signals(slides)
	slides.start_button.pressed.emit()
	assert_signal_emitted_with_parameters(slides, "start_pressed", [false])


func test_start_signal_checkbox_on() -> void:
	slides.show_slide(5)
	slides.dont_show_checkbox.button_pressed = true
	watch_signals(slides)
	slides.start_button.pressed.emit()
	assert_signal_emitted_with_parameters(slides, "start_pressed", [true])


func test_go_live_and_the_checkbox_by_mouse() -> void:
	await _full_size()
	slides.show_slide(5)
	await wait_process_frames(2)
	watch_signals(slides)
	_click(slides.dont_show_checkbox)
	await wait_process_frames(2)
	assert_true(slides.dont_show_checkbox.button_pressed, "a click ticks it")
	_click(slides.start_button)
	await wait_process_frames(2)
	assert_signal_emitted_with_parameters(slides, "start_pressed", [true])


func test_enter_on_the_focused_start_button() -> void:
	slides.show_slide(5)
	watch_signals(slides)
	assert_true(slides.start_button.has_focus())
	_push(KEY_ENTER)
	await wait_process_frames(2)
	assert_signal_emitted(slides, "start_pressed")


# --- Keys -------------------------------------------------------------------------------------------

func test_only_fresh_key_presses_count() -> void:
	var echo := _key(KEY_RIGHT)
	echo.echo = true
	slides._input(echo)
	assert_eq(_visible_slide(), 0, "a held key's echo does nothing")
	var up := _key(KEY_RIGHT)
	up.pressed = false
	slides._input(up)
	assert_eq(_visible_slide(), 0, "a release does nothing")
	slides._input(_key(KEY_RIGHT))
	assert_eq(_visible_slide(), 1)


func test_arrow_keys_change_slides_everywhere() -> void:
	for i in range(1, 6):
		slides._input(_key(KEY_RIGHT))
		assert_eq(_visible_slide(), i)
	for i in range(4, -1, -1):
		slides._input(_key(KEY_LEFT))
		assert_eq(_visible_slide(), i)


func test_a_and_d_change_slides_only_on_the_loop_and_last_slides() -> void:
	slides._input(_key(KEY_D))
	assert_eq(_visible_slide(), 1, "D on the loop slide")
	for i in range(1, 5):
		slides.show_slide(i)
		slides._input(_key(KEY_D))
		assert_eq(_visible_slide(), i, "D steers on trick slide %d" % (i + 1))
		slides._input(_key(KEY_A))
		assert_eq(_visible_slide(), i, "A steers on trick slide %d" % (i + 1))
	slides.show_slide(5)
	slides._input(_key(KEY_A))
	assert_eq(_visible_slide(), 4, "A on the last slide")


func test_on_a_trick_slide_a_d_and_space_press_nothing_and_reach_the_practice() -> void:
	for slide in range(1, 5):
		slides.show_slide(slide)
		await wait_process_frames(2)
		watch_signals(slides)
		assert_null(slides.get_viewport().gui_get_focus_owner(), "no button has the focus")
		for b in [slides.left_arrow, slides.right_arrow, slides.skip_button]:
			assert_eq(b.focus_mode, Control.FOCUS_NONE, b.name)
		var session = slides.practices[slide - 1]
		for code in [KEY_A, KEY_D, KEY_SPACE, KEY_ENTER, KEY_TAB, KEY_SPACE]:
			_push(code)
			await wait_process_frames(1)
		assert_eq(_visible_slide(), slide, "still on slide %d" % (slide + 1))
		assert_null(slides.get_viewport().gui_get_focus_owner(), "Tab finds no button")
		assert_signal_not_emitted(slides, "start_pressed")
		assert_true(session.focused, "the window has the keyboard")
		assert_true(session.keys.has(KEY_A), "A reaches the practice")
		assert_true(session.keys.has(KEY_D), "D reaches the practice")
		assert_true(session.keys.has(KEY_SPACE), "Space reaches the practice")


func test_the_arrow_keys_do_not_reach_the_practice() -> void:
	slides.show_slide(2)
	await wait_process_frames(2)
	var session = slides.practices[1]
	_push(KEY_RIGHT)
	await wait_process_frames(1)
	assert_eq(_visible_slide(), 3)
	assert_false(session.keys.has(KEY_RIGHT), "the slide took it")


func test_leaving_a_trick_slide_gives_the_buttons_their_focus_back() -> void:
	slides.show_slide(1)
	slides.show_slide(0)
	assert_eq(slides.right_arrow.focus_mode, Control.FOCUS_ALL)
	assert_true(slides.right_arrow.has_focus(), "the loop slide: the right arrow")
	slides.show_slide(5)
	assert_true(slides.start_button.has_focus(), "the last slide: Go live")


# --- The practice windows ---------------------------------------------------------------------------

func test_each_trick_slide_embeds_the_practice_set_to_its_trick() -> void:
	for i in range(4):
		assert_null(slides.practices[i], "built only when its slide first shows")
	for i in range(4):
		slides.show_slide(1 + i)
		var session = slides.practices[i]
		assert_not_null(session, TRICK_NAMES[i])
		assert_eq(session.setup_calls, [TRICK_NAMES[i]], "set up once, to its trick")
		var viewport := slides.practice_containers[i].get_child(0) as SubViewport
		assert_eq(session.get_parent(), viewport, "in the window's SubViewport")
		assert_true(slides.practice_frames[i].is_ancestor_of(viewport))


func test_the_real_scene_path_is_t561s() -> void:
	assert_eq(TutorialSlides.PRACTICE_SCENE, "res://scenes/run/practice_session.tscn")
	assert_eq(TutorialSlides.TRICK_SLIDES.map(func(t): return t[1]), TRICK_NAMES)


func test_only_the_showing_practice_runs_and_has_the_keyboard() -> void:
	for i in range(4):
		slides.show_slide(1 + i)
	for shown in range(4):
		slides.show_slide(1 + shown)
		for i in range(4):
			assert_eq(slides.practices[i].running, i == shown, "slide %d shown: practice %d" % [shown + 2, i])
			assert_eq(slides.practices[i].focused, i == shown)
	slides.show_slide(0)
	for i in range(4):
		assert_false(slides.practices[i].running, "the loop slide: all paused")
		assert_false(slides.practices[i].focused)
	slides.show_slide(2)
	slides.hide()
	assert_false(slides.practices[1].running, "hidden slides: paused")
	slides.show()
	assert_true(slides.practices[1].running)


func test_a_practice_keeps_its_count_when_its_slide_hides() -> void:
	slides.show_slide(1)
	var session = slides.practices[0]
	session.succeed()
	slides.show_slide(2)
	slides.show_slide(1)
	assert_eq(slides.practices[0], session, "the same session")
	assert_eq(session.successes, 1)
	assert_eq(session.setup_calls.size(), 1, "not set up again")


func test_no_success_message_over_the_window_when_the_goal_is_done() -> void:
	# T-574 (the board): the big centred message is gone; the practice session stamps its notebook.
	slides.show_slide(3)
	var session = slides.practices[2]
	for n in 3:
		session.succeed()
	assert_false(slides.text_labels.has("tutorial.success"), "the success text is no longer shown")
	assert_null(slides.find_child("Success", true, false))


func test_a_missing_practice_scene_leaves_an_empty_window() -> void:
	slides.practice_scene_path = "res://scenes/run/no_such_practice.tscn"
	slides.show_slide(1)
	assert_null(slides.practices[0])
	assert_true(slides.practice_frames[0].is_visible_in_tree(), "the frame still shows")
	slides.show_slide(2)
	slides.right_arrow.pressed.emit()
	assert_eq(_visible_slide(), 3, "the slides still work")


func test_the_stage_and_the_windows_scale_with_the_window() -> void:
	slides.set_anchors_preset(Control.PRESET_TOP_LEFT)  # so the test can set its size
	slides.size = Vector2(2560, 1440)
	slides._fit()
	assert_eq(slides.stage.scale, Vector2(2, 2))
	var c: SubViewportContainer = slides.practice_containers[0]
	var inner := TutorialSlides.WINDOW_SIZE - Vector2(TutorialSlides.WINDOW_BORDER, TutorialSlides.WINDOW_BORDER) * 2.0
	assert_eq(c.size, inner * 2.0, "the window renders at the screen's own pixels")
	assert_eq(c.scale, Vector2(0.5, 0.5))
	slides.size = Vector2(1280, 720)
	slides._fit()
	assert_eq(slides.stage.scale, Vector2(1, 1))
	assert_eq(c.size, inner)
	slides.size = Vector2(1000, 720)
	slides._fit()
	assert_almost_eq(slides.stage.scale.x, 1000.0 / 1280.0, 0.001)


func test_the_take_tools_show_on_each_trick_slide_only_in_a_dev_build() -> void:
	# T-574 tweak 8: temporary recording controls, dev builds only (never in an exported game).
	assert_eq(slides.take_panels.size(), 4, "one per trick slide")
	slides.set_dev_tools(false)
	slides.show_slide(1)
	assert_false(slides.take_panels[0].is_visible_in_tree(), "hidden when not a dev build")
	_push(KEY_F6)
	assert_eq(slides.current, 1)
	slides.set_dev_tools(true)
	assert_true(slides.take_panels[0].is_visible_in_tree())
	for i in range(4):
		assert_true(slides.slides[1 + i].is_ancestor_of(slides.take_panels[i]))
		for b in slides.take_panels[i].get_children():
			if b is Button:
				assert_eq((b as Button).focus_mode, Control.FOCUS_NONE, "clicked only")
	for code in [KEY_F5, KEY_F6, KEY_F7, KEY_F9]:
		_push(code)
		assert_eq(slides.current, 1, "a take key changes no slide")
	assert_false(slides.TAKE_KEYS.has(KEY_W) or slides.TAKE_KEYS.has(KEY_SPACE) or slides.TAKE_KEYS.has(KEY_R),
		"no clash with driving")
