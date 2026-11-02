extends GutTest
## Task T-320: the recap screen shows a run's summary (T-319) with pictures, every
## word from T-318's recap_text.json, and closes with Continue, the X or Enter.

const RecapScene := preload("res://scenes/menu/recap_screen.tscn")
const RunStateScript := preload("res://scripts/run/run_state.gd")
const TEXT_PATH := "res://data/recap_text.json"

var screen: RecapScreen


func _file_texts() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(TEXT_PATH))


func _all_strings(d: Variant, out: Array) -> Array:
	if typeof(d) == TYPE_DICTIONARY:
		for k in d:
			if not str(k).begins_with("_"):
				_all_strings(d[k], out)
	elif typeof(d) == TYPE_STRING:
		out.append(d)
	return out


func _sample() -> Dictionary:
	return {
		"result": "win", "loss_reason": "", "time_survived": 300.0, "coins": 40,
		"likes": 900, "level": 5,
		"enemies_slain": {"minion": 42, "kaiju": 1},
		"tricks": {"three_sixty": 3, "alternate_drift": 0, "airtime": 7, "thread_the_needle": 1},
		"highest_combo": 3.4, "peak_viewers": 236026.0,
		"weapons": {"gun": {"tier": 4, "kills": 30}, "wiper": {"tier": 2, "kills": 12}},
	}


func _show(s: Dictionary) -> RecapScreen:
	screen = RecapScene.instantiate()
	add_child_autofree(screen)
	screen.show_summary(s)
	return screen


func _labels(n: Node, out: Array = []) -> Array:
	if n is Label:
		out.append(n)
	for c in n.get_children():
		_labels(c, out)
	return out


func test_the_title_follows_how_the_run_ended() -> void:
	var t := _file_texts()
	var s := _sample()
	assert_eq(_show(s).title_label.text, t.title.win)
	s.result = "loss"
	s.loss_reason = "time"
	assert_eq(_show(s).title_label.text, t.title.time_up)
	s.loss_reason = "health"
	assert_eq(_show(s).title_label.text, t.title.wreck)


func test_each_enemy_and_trick_above_zero_shows_with_its_count() -> void:
	var t := _file_texts()
	_show(_sample())
	assert_eq(screen.enemy_rows.keys(), ["minion", "kaiju"])
	assert_eq(screen.enemy_rows.minion.count.text, "x42")
	assert_eq(screen.enemy_rows.minion.name.text, t.enemy.minion)
	assert_eq(screen.enemy_rows.kaiju.count.text, "x1")
	assert_eq(screen.enemy_rows.kaiju.name.text, t.enemy.kaiju)
	assert_eq(screen.trick_rows.keys(), ["three_sixty", "airtime", "thread_the_needle"], "0 counts left out, in the file's order")
	assert_eq(screen.trick_rows.three_sixty.count.text, "x3")
	assert_eq(screen.trick_rows.airtime.count.text, "x7")
	assert_eq(screen.trick_rows.thread_the_needle.count.text, "x1")
	assert_false(screen.trick_rows.has("alternate_drift"))


func test_the_trick_pictures_are_the_trick_popups() -> void:
	var t := _file_texts()
	_show(_sample())
	for id in screen.trick_rows:
		var expected := TrickPopupArt.texture(t.trick[id], RecapScreen.TRICK_STYLE, 0)
		assert_eq(screen.trick_rows[id].image.texture, expected, "%s is its popup" % id)


func test_each_weapon_shows_its_card_image_name_and_tier() -> void:
	var t := _file_texts()
	_show(_sample())
	assert_eq(screen.weapon_rows.keys(), ["gun", "wiper"])
	assert_eq(screen.weapon_rows.gun.name.text, t.weapon.gun)
	assert_eq(screen.weapon_rows.gun.tier.text, t.tier.format({"tier": 4}))
	assert_eq(screen.weapon_rows.wiper.tier.text, t.tier.format({"tier": 2}))
	assert_eq(screen.weapon_rows.gun.image.texture, LevelUpScreen.weapon_image("gun"))
	assert_eq(screen.weapon_rows.wiper.image.texture, LevelUpScreen.weapon_image("wiper"))
	assert_eq(screen.weapon_rows.gun.image.texture.resource_path, "res://art/level_up/weapon_gun.png", "the card's final art")


func test_the_enemies_show_their_own_sprites() -> void:
	_show(_sample())
	var minion: Texture2D = screen.enemy_rows.minion.image.texture
	var kaiju: Texture2D = screen.enemy_rows.kaiju.image.texture
	assert_not_null(minion)
	assert_not_null(kaiju)
	assert_ne(minion, kaiju)
	# The minion's picture is the sheet's first frame, cropped to its pixels.
	var sheet: Image = (load("res://art/minion/minion_s.png") as Texture2D).get_image()
	var frame := sheet.get_region(Rect2i(0, 0, sheet.get_height(), sheet.get_height()))
	var cropped := frame.get_region(frame.get_used_rect())
	assert_eq(minion.get_image().get_data(), cropped.get_data(), "the minion sheet's first frame")
	assert_eq(screen.enemy_rows.minion.image.custom_minimum_size, RecapScreen.SLOT)


## T-514 (T-512's text): the recap's peak is the highest combo multiplier, written as the HUD writes it.
func test_peak_combo_shows_the_highest_multiplier_as_the_tag_writes_it() -> void:
	_show(_sample())
	assert_eq(screen.peak_label.text, RecapScreen.text("peak_value").format({"multiplier": "3.40"}))
	assert_eq(screen.peak_label.text, "x3.40")
	var heat := ComboHeat.step_for(3.4)
	assert_eq(screen.combo_heat.step, heat, "the multiplier's heat step for that number")
	assert_eq(screen.peak_label.get_theme_color("font_color"), ComboHeat.STEPS[heat].color)
	var s := _sample()
	s.highest_combo = 6.0
	_show(s)
	assert_eq(screen.peak_label.text, "x6.00")
	assert_eq(screen.combo_heat.step, ComboHeat.STEPS.size() - 1, "the cap takes the top look")


func test_a_low_peak_takes_the_multiplier_colour() -> void:
	var s := _sample()
	s.highest_combo = 1.0
	_show(s)
	assert_eq(screen.peak_label.text, "x1.00")
	assert_eq(screen.combo_heat.step, 0)
	assert_eq(screen.peak_label.get_theme_color("font_color"), RecapScreen.multiplier_color())
	assert_eq(RecapScreen.multiplier_color(), Color("#33e1ff"))


func test_an_older_summary_with_peak_viewers_still_loads_and_shows_its_highest_combo() -> void:
	var s := _sample()
	s["peak_viewers"] = 236026.0
	_show(s)
	assert_eq(screen.peak_label.text, "x3.40")
	s.erase("highest_combo")
	_show(s)
	assert_eq(screen.peak_label.text, "x1.00", "no combo recorded: no combo")


func test_no_viewers_eye_beside_the_number() -> void:
	_show(_sample())
	assert_null(screen.sections.combo.find_child("Eye", true, false), "T-514: the eye went with the viewers")


func test_a_run_with_no_kills_or_tricks_leaves_those_sections_out() -> void:
	var s := _sample()
	s.enemies_slain = {}
	s.tricks = {"three_sixty": 0}
	_show(s)
	assert_false(screen.sections.has("enemies"))
	assert_false(screen.sections.has("tricks"))
	assert_true(screen.sections.has("combo"))
	assert_true(screen.sections.has("weapons"))


func test_a_saved_summary_from_json_shows_the_same() -> void:
	# The runs list (T-364) reopens saved runs: JSON turns every number into a float.
	var back: Dictionary = JSON.parse_string(JSON.stringify(_sample()))
	_show(back)
	assert_eq(screen.enemy_rows.minion.count.text, "x42")
	assert_eq(screen.trick_rows.airtime.count.text, "x7")
	assert_eq(screen.weapon_rows.gun.tier.text, _file_texts().tier.format({"tier": 4}))


func test_every_label_comes_from_the_text_file() -> void:
	var allowed := _all_strings(_file_texts(), [])
	for n in range(1, 9):
		allowed.append((_file_texts().tier as String).format({"tier": n}))
	_show(_sample())
	var count_form := RegEx.create_from_string("^x[0-9]+$")
	var peak_number := RecapScreen.text("peak_value").format({"multiplier": "3.40"})
	for l: Label in _labels(screen):
		var ok: bool = l.text in allowed or count_form.search(l.text) != null or l.text == peak_number
		assert_true(ok, "label '%s' is from recap_text.json, the HUD's x{n} form or the peak value" % l.text)
	assert_eq(screen.continue_button.text, _file_texts().button.continue)
	assert_eq(screen.close_button.tooltip_text, _file_texts().button.close)
	assert_eq(screen.close_button.text, "", "the X is a picture, not text")


func test_the_code_writes_no_words() -> void:
	# Every string literal in the script is a path, a node name, a key or a format.
	var src := FileAccess.get_file_as_string("res://scripts/ui/recap_screen.gd")
	for word in _all_strings(_file_texts(), []):
		if (word as String).length() > 3:
			assert_false(src.contains('"%s"' % word), "'%s' is not typed in the code" % word)


func test_continue_the_x_and_enter_close_once() -> void:
	_show(_sample())
	watch_signals(screen)
	screen.continue_button.pressed.emit()
	assert_signal_emit_count(screen, "closed", 1)
	screen.close_button.pressed.emit()
	assert_signal_emit_count(screen, "closed", 1, "only once")
	_show(_sample())
	watch_signals(screen)
	screen.close_button.pressed.emit()
	assert_signal_emit_count(screen, "closed", 1, "the X closes")
	_show(_sample())
	watch_signals(screen)
	var e := InputEventKey.new()
	e.keycode = KEY_ENTER
	e.pressed = true
	e.echo = true
	screen._unhandled_key_input(e)
	assert_signal_emit_count(screen, "closed", 0, "a key-repeat does nothing")
	e.echo = false
	screen._unhandled_key_input(e)
	assert_signal_emit_count(screen, "closed", 1, "Enter closes")


func test_the_buttons_take_no_keyboard_focus() -> void:
	_show(_sample())
	assert_eq(screen.continue_button.focus_mode, Control.FOCUS_NONE)
	assert_eq(screen.close_button.focus_mode, Control.FOCUS_NONE)


func test_the_x_sits_at_the_top_right_and_nothing_overlaps() -> void:
	var win := get_window()
	var old := win.size
	win.size = Vector2i(1152, 648)
	_show(_sample())
	screen.finish_animation()
	await wait_process_frames(3)
	var view := screen.get_viewport_rect()
	var x := screen.close_button.get_global_rect()
	assert_gt(x.position.x, view.size.x * 0.8, "at the right")
	assert_lt(x.end.y, view.size.y * 0.2, "at the top")
	var rects := [x, screen.continue_button.get_global_rect()]
	for key in screen.sections:
		rects.append(screen.sections[key].get_global_rect())
	rects.append(screen.title_label.get_parent().get_global_rect())
	for r: Rect2 in rects:
		assert_true(view.encloses(r), "on screen: %s" % r)
	for i in rects.size():
		for j in range(i + 1, rects.size()):
			assert_false(rects[i].intersects(rects[j]), "%s and %s apart" % [rects[i], rects[j]])
	win.size = old


func test_the_sections_pop_in_one_by_one() -> void:
	_show(_sample())
	assert_true(screen.is_animating())
	var title_panel: Control = screen.title_label.get_parent()
	assert_lt(title_panel.modulate.a, 1.0, "not shown in full at once")
	screen._process(RecapScreen.FRAME * 3.0 + 0.001)
	assert_eq(title_panel.modulate.a, 1.0, "the title first")
	assert_eq(screen.sections.weapons.modulate.a, 0.0, "the weapons later")
	screen.finish_animation()
	assert_false(screen.is_animating())
	for key in screen.sections:
		assert_eq(screen.sections[key].modulate.a, 1.0)


func test_a_scripted_run_shows_its_own_sample() -> void:
	var state: RunState = RunStateScript.new()
	add_child_autofree(state)
	var tiers := {"gun": 3, "molotov": 1}
	state.weapons_source = func() -> Dictionary: return tiers
	state.start_run()
	for i in 5:
		state.enemy_slain("minion", "gun")
	state.add_trick("three_sixty")
	state.add_trick("three_sixty")
	state.add_trick("alternate_drift")
	state.add_needle_trick()
	state.kaiju_killed()
	var r := state.recap()
	_show(r)
	assert_eq(screen.title_label.text, _file_texts().title.win)
	assert_eq(screen.enemy_rows.minion.count.text, "x5")
	assert_false(screen.enemy_rows.has("kaiju"), "no kaiju kill counted here")
	assert_eq(screen.trick_rows.three_sixty.count.text, "x2")
	assert_eq(screen.trick_rows.alternate_drift.count.text, "x1")
	assert_eq(screen.trick_rows.thread_the_needle.count.text, "x1")
	assert_false(r.has("peak_viewers"), "T-514: the summary keeps only the highest combo")
	assert_eq(screen.peak_label.text, RecapScreen.text("peak_value").format({"multiplier": MultiplierTag.format_number(r.highest_combo)}))
	assert_eq(screen.weapon_rows.keys(), ["gun", "molotov"])
	assert_eq(screen.weapon_rows.gun.tier.text, _file_texts().tier.format({"tier": 3}))
	assert_eq(screen.weapon_rows.molotov.image.texture, LevelUpScreen.weapon_image("molotov"))
