extends GutTest
## Tasks T-382 and T-485: the redrawn tutorial slides screen: four slides in order, the dots, the
## arrows and Skip, texts from the files (none from code, the retired keys unused), the clips
## playing with their timing, the pictures being the game's own art, Go live and Don't show again,
## keyboard (fresh presses only).

const RETIRED_KEYS := ["slide1.controls", "slide1.drift", "slide2.chain", "slide2.gift", "slide3.goal"]
const SOURCE := "res://scripts/menu/tutorial_slides.gd"

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


func _file() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/tutorial_text.json"))


func _at(key: String) -> String:
	var parts: PackedStringArray = key.split(".")
	return _file()[parts[0]][parts[1]]


func _all(node: Node, kind: String) -> Array:
	var out: Array = []
	for c in node.get_children():
		if c.is_class(kind):
			out.append(c)
		out.append_array(_all(c, kind))
	return out


func test_four_slides_in_order_with_their_headlines() -> void:
	assert_eq(slides.slides.size(), 4)
	var keys := ["slide1.title", "slide2.title", "slide3.title", "slide4.title"]
	for i in range(4):
		assert_eq(slides.slides[i].name, "Slide%d" % (i + 1))
		var title: Label = slides.slides[i].get_node("Title")
		assert_eq(title.text, _at(keys[i]))
		assert_true(title.uppercase, "shown in capitals")
	assert_eq(_at("slide1.title"), "Drive")
	assert_eq(_at("slide2.title"), "Tricks bring gift packs")
	assert_eq(_at("slide3.title"), "Missions power your car")
	assert_eq(_at("slide4.title"), "Survive the stream")


func test_the_dots_show_four_and_follow_the_slide() -> void:
	var dots: Node = slides.stage.get_node("Dots")
	assert_eq(dots.get_child_count(), 4)
	slides.show_slide(2)
	for i in range(4):
		var on: bool = (dots.get_child(i) as ColorRect).color == TutorialSlides.DOT_ON
		assert_eq(on, i == 2, "dot %d" % i)


func test_kickers_follow_the_pattern() -> void:
	var topics := ["kicker.controls", "kicker.loop", "kicker.missions", "kicker.goal"]
	for i in range(4):
		var expected: String = _at("kicker.pattern").replace("{n}", str(i + 1)) \
			.replace("{total}", "4").replace("{topic}", _at(topics[i]))
		assert_eq(slides.kickers[i].text, expected)
	assert_eq(slides.kickers[1].text, "2 / 4 · How you get stronger")


func test_starts_on_slide_one_without_left_arrow() -> void:
	assert_eq(_visible_slide(), 0)
	assert_false(slides.left_arrow.visible)
	assert_true(slides.right_arrow.visible)


func test_arrows_move_forward_and_back() -> void:
	slides.right_arrow.pressed.emit()
	assert_eq(_visible_slide(), 1)
	assert_true(slides.left_arrow.visible)
	assert_true(slides.right_arrow.visible)
	slides.right_arrow.pressed.emit()
	slides.right_arrow.pressed.emit()
	assert_eq(_visible_slide(), 3)
	assert_false(slides.right_arrow.visible)
	slides.right_arrow.pressed.emit()
	assert_eq(_visible_slide(), 3, "no slide 5")
	slides.left_arrow.pressed.emit()
	assert_eq(_visible_slide(), 2)
	slides.left_arrow.pressed.emit()
	slides.left_arrow.pressed.emit()
	assert_eq(_visible_slide(), 0)
	slides.left_arrow.pressed.emit()
	assert_eq(_visible_slide(), 0, "no slide 0")


func test_skip_jumps_to_slide_four_from_every_slide() -> void:
	for i in range(4):
		slides.show_slide(i)
		assert_true(slides.skip_button.is_visible_in_tree(), "Skip on slide %d" % (i + 1))
		slides.skip_button.pressed.emit()
		assert_eq(_visible_slide(), 3)
		assert_true(slides.start_button.has_focus())
	assert_eq(slides.skip_button.text, _at("button.skip").to_upper())


func test_go_live_and_the_checkbox_only_on_slide_four() -> void:
	assert_true(slides.slides[3].is_ancestor_of(slides.start_button))
	assert_true(slides.slides[3].is_ancestor_of(slides.dont_show_checkbox))
	assert_false(slides.start_button.is_visible_in_tree())
	slides.show_slide(3)
	assert_true(slides.start_button.is_visible_in_tree())
	assert_true(slides.dont_show_checkbox.is_visible_in_tree())
	assert_not_null(slides.start_button.icon, "the HUD's LIVE badge")


func test_start_signal_checkbox_off() -> void:
	slides.show_slide(3)
	watch_signals(slides)
	slides.start_button.pressed.emit()
	assert_signal_emitted_with_parameters(slides, "start_pressed", [false])


func test_start_signal_checkbox_on() -> void:
	slides.show_slide(3)
	slides.dont_show_checkbox.button_pressed = true
	watch_signals(slides)
	slides.start_button.pressed.emit()
	assert_signal_emitted_with_parameters(slides, "start_pressed", [true])


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


func test_texts_match_the_file() -> void:
	for key in slides.text_labels:
		var expected := _at(key)
		var node: Control = slides.text_labels[key]
		var shown: String = node.tooltip_text if key.begins_with("arrow.") else node.text
		if key == "button.skip":
			assert_eq(shown, expected.to_upper(), key)
		else:
			assert_eq(shown, expected, key)
	for key in ["slide1.title", "slide1.key_w", "slide1.key_a", "slide1.key_s", "slide1.key_d",
			"slide2.step1_title", "slide2.step4_caption", "slide2.clip_ramp", "slide3.missions",
			"slide4.kaiju", "trick.extended_drift", "trick.alternate_drift", "button.start"]:
		assert_true(slides.text_labels.has(key), "uses " + key)


func test_the_drift_rule_is_the_file_line_split_on_plus_and_equals() -> void:
	assert_eq(slides.rule_keycap.text, "W", "the W is a keycap")
	var line := " ".join([slides.rule_labels[0].text, "+", slides.rule_labels[1].text, "=",
		slides.rule_labels[2].text])
	assert_eq(line, _at("slide1.drift_rule"))
	assert_eq(TutorialSlides._split_rule("W + turn = drift"), PackedStringArray(["W", "turn", "drift"]))


func test_the_retired_keys_are_not_used() -> void:
	var source := FileAccess.get_file_as_string(SOURCE)
	for key in RETIRED_KEYS:
		assert_false(slides.text_labels.has(key), key)
		assert_false(source.contains('"%s"' % key), "no use of " + key)


func test_no_word_on_the_slides_comes_from_code() -> void:
	var allowed := {}
	for group in _file().values():
		if group is Dictionary:
			for k in group:
				if not String(k).ends_with("comment") and group[k] is String:
					allowed[String(group[k]).to_lower()] = true
	var texts: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/screen_texts.json"))
	for n in texts["power_ups"]["names"].values():
		allowed[String(n).to_lower()] = true
	allowed[String(texts["missions"]["header"]).to_lower()] = true
	for row in slides.notebook_page.rows:
		allowed[(row as Node).get_node("Text").text.to_lower()] = true
	for k in slides.kickers:
		allowed[k.text.to_lower()] = true
	for part in slides.rule_labels:
		allowed[part.text.to_lower()] = true  # the drift rule's parts, split from its file line
	var numbers := RegEx.create_from_string("^[0-9:,]+$")
	for l in _all(slides, "Label"):
		var t: String = l.text.to_lower()
		if t == "" or t.length() == 1 or numbers.search(t) != null:
			continue  # key letters and numbers (the times, the viewer count)
		assert_true(allowed.has(t), "text from a file: '%s'" % t)


func test_slide_one_and_slide_two_clips_are_the_recorded_ones() -> void:
	var names: Array = []
	for p in slides.clip_players:
		names.append(p.clip)
	assert_eq(names, ["drift", "long_drift", "alt_drift", "ramp_jump"])
	assert_true(slides.slides[0].is_ancestor_of(slides.clip_players[0]))
	for i in range(1, 4):
		assert_true(slides.slides[1].is_ancestor_of(slides.clip_players[i]))
	assert_eq(slides.text_labels["trick.extended_drift"].text, _at("trick.extended_drift"))


func test_a_clip_loads_when_its_slide_shows_and_its_frames_advance_with_the_gifs_timing() -> void:
	var drift: ClipPlayer = slides.clip_players[0]
	var long_drift: ClipPlayer = slides.clip_players[1]
	assert_not_null(drift.sheet, "slide 1 is on screen: its clip is loaded")
	assert_eq(drift.pages.size(), 2, "149 frames of 480 x 320 take two pages")
	assert_null(long_drift.sheet, "slide 2's clips wait until it shows")
	slides.show_slide(1)
	assert_not_null(long_drift.sheet)
	assert_null(drift.sheet, "slide 1's clip is freed when its slide is hidden")
	assert_eq(drift.pages.size(), 0)
	# The drift clip's first frame lasts 80 ms in its GIF, then 40 ms frames.
	assert_eq(drift.frame, 0)
	assert_eq(drift.frame_count(), 149)
	drift.ensure_loaded()
	drift.advance(0.079)
	assert_eq(drift.frame, 0, "still on the first frame")
	drift.advance(0.002)
	assert_eq(drift.frame, 1)
	drift.advance(0.040)
	assert_eq(drift.frame, 2)
	drift.advance(6.0)
	assert_between(drift.frame, 0, 148, "the clip loops")
	assert_eq(long_drift.frame_count(), 84)
	long_drift.advance(0.061)
	assert_eq(long_drift.frame, 1, "60 ms frames")
	for p in slides.clip_players:
		p.ensure_loaded()
		var sum := 0.0
		for d in p.meta["durations_ms"]:
			sum += d
		var record: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string("res://art/tutorial/clips/%s.json" % p.clip))
		assert_almost_eq(sum / 1000.0, float(record["seconds"]), 0.1, p.clip + " keeps its length")
		assert_eq(p.frame_count(), int(p.meta["frames"]))


func test_every_sheet_page_is_at_most_4096_pixels_a_side() -> void:
	for clip in ["drift", "long_drift", "alt_drift", "ramp_jump"]:
		var player := ClipPlayer.new()
		player.set_clip(clip, true)
		assert_gt(player.pages.size(), 0, clip)
		for page in player.pages:
			assert_lte(page.get_width(), 4096, clip)
			assert_lte(page.get_height(), 4096, clip)
		player.free()


func test_a_visible_clip_plays_on_its_own() -> void:
	var drift: ClipPlayer = slides.clip_players[0]
	await wait_seconds(0.5)
	assert_true(drift.frame > 0 or drift.elapsed_ms > 0.0, "the clock runs while it is visible")
	slides.show_slide(1)
	var long_drift: ClipPlayer = slides.clip_players[1]
	await wait_seconds(0.3)
	assert_true(long_drift.frame > 0 or long_drift.elapsed_ms > 0.0)
	var held: int = drift.frame
	var held_ms: float = drift.elapsed_ms
	await wait_seconds(0.2)
	assert_eq(drift.frame, held, "a clip on a hidden slide stands still")
	assert_eq(drift.elapsed_ms, held_ms)


func test_the_pictures_are_the_games_own_art() -> void:
	assert_gt(slides.picture_paths.size(), 14)
	for path in slides.picture_paths:
		assert_true(path.begins_with("res://art/"), path)
		assert_true(path.ends_with(".png"), path)
		assert_true(ResourceLoader.exists(path), path)
	for expected in ["res://art/hud/eye_icon.png", "res://art/hud/subs_icon.png",
			"res://art/gift_pack/package.png", "res://art/kaiju/kaiju_s.png",
			"res://art/hud/live_badge.png", "res://art/hud/mission_page.png",
			"res://art/tutorial/tricks/extended_drift.png", "res://art/hud/weapon_icons.png",
			"res://art/power_ups/rev_charge.png", "res://art/power_ups/jump.png",
			"res://art/power_ups/bouncy_bumpers.png", "res://art/power_ups/rusty_overcoat.png",
			"res://art/power_ups/polarized_steering_wheel.png"]:
		assert_true(slides.picture_paths.has(expected), expected)
	assert_eq(slides.gift_packs.size(), 4, "four gift packs on the timeline")
	assert_not_null(slides.kaiju_picture.texture)
	assert_eq(slides.step_pictures.size(), 4)


func test_slide_three_has_the_notebook_page_and_the_five_power_ups() -> void:
	assert_eq(slides.notebook_page.rows.size(), 2)
	assert_true(slides.notebook_page.rows[0].ticked, "one ticked line")
	assert_false(slides.notebook_page.rows[1].ticked, "one open line")
	assert_eq(slides.power_up_labels.keys().size(), PowerUpData.IDS.size(), "every power-up (five since T-502)")
	var names: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/screen_texts.json"))["power_ups"]["names"]
	for id in slides.power_up_labels:
		assert_eq(slides.power_up_labels[id].text, names[id])


func test_slide_four_timeline_times_and_the_kaiju() -> void:
	var times: Array = []
	for l in slides.time_labels:
		times.append(l.text)
	assert_eq(times, ["8:00", "4:00", "1:00"])
	assert_eq(slides.kaiju_label.text, _at("slide4.kaiju"))
	var gradient: Gradient = (slides.timeline_bar.texture as GradientTexture1D).gradient
	assert_eq(gradient.colors[0], TutorialSlides.CYAN)
	assert_eq(gradient.colors[gradient.colors.size() - 1], TutorialSlides.DANGER, "red at the end")


func test_the_stage_scales_with_the_window() -> void:
	slides.set_anchors_preset(Control.PRESET_TOP_LEFT)  # so the test can set its size
	slides.size = Vector2(2560, 1440)
	slides._fit()
	assert_eq(slides.stage.scale, Vector2(2, 2))
	slides.size = Vector2(1280, 720)
	slides._fit()
	assert_eq(slides.stage.scale, Vector2(1, 1))
	slides.size = Vector2(1000, 720)
	slides._fit()
	assert_almost_eq(slides.stage.scale.x, 1000.0 / 1280.0, 0.001)


func test_keyboard_arrows_and_a_d() -> void:
	slides._input(_key(KEY_RIGHT))
	assert_eq(_visible_slide(), 1)
	slides._input(_key(KEY_D))
	assert_eq(_visible_slide(), 2)
	slides._input(_key(KEY_D))
	assert_eq(_visible_slide(), 3)
	slides._input(_key(KEY_D))
	assert_eq(_visible_slide(), 3)
	slides._input(_key(KEY_LEFT))
	assert_eq(_visible_slide(), 2)
	slides._input(_key(KEY_A))
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
	assert_true(slides.right_arrow.has_focus(), "slide 3: the right arrow")
	slides.show_slide(3)
	assert_true(slides.start_button.has_focus(), "slide 4: Go live")


func test_enter_on_the_focused_start_button() -> void:
	slides.show_slide(3)
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


func test_slide_two_clips_have_the_live_key_pad_and_slide_one_does_not() -> void:
	assert_null(slides.clip_players[0].get_node_or_null("KeyPad"), "slide 1's clip is unchanged")
	for i in range(1, 4):
		var pad := slides.clip_players[i].get_node_or_null("KeyPad") as KeyPad
		assert_not_null(pad, "slide 2 clip %d" % i)
		assert_eq(pad.player, slides.clip_players[i])
	assert_eq(slides.clip_players.size(), 4)
