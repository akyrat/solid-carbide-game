extends GutTest
## Task T-491: the trick list's detail pane (clip with the key pad, rule, keycap recipe) and its data.

var list: TrickList
var _texts: Dictionary


func before_each() -> void:
	_texts = JSON.parse_string(FileAccess.get_file_as_string("res://data/tutorial_text.json"))
	list = load("res://scenes/menu/trick_list.tscn").instantiate()
	add_child_autofree(list)


func _caps(step: Node) -> Array:
	return step.get_node("Keys").get_children().filter(func(c): return c.name.begins_with("Key"))


func test_all_ten_tricks_are_listed_and_each_has_a_clip_that_exists() -> void:
	assert_eq(list.rows.size(), 10)
	for id in TrickList.TRICK_IDS:
		var clip := TrickList.clip_for(id)
		assert_ne(clip, "", id)
		assert_true(FileAccess.file_exists("res://art/tutorial/clips/%s_sheet.json" % clip), id)


func test_selecting_a_trick_shows_its_clip_pad_name_and_rule() -> void:
	for id in TrickList.TRICK_IDS:
		list.select(id)
		assert_eq(list.clip_player.clip, TrickList.clip_for(id), id)
		assert_not_null(list.clip_player.sheet, id + " clip is loaded while shown")
		assert_true(list.key_pad.get_parent() == list.clip_player)
		assert_eq(list.detail_name.text, _texts["trick"][id])
		assert_eq(list.rule_label.text, _texts["trick_rule"][id])
		assert_ne(list.rule_label.text, "")
		assert_true(list.rows[id].button_pressed)


func test_nine_tricks_show_a_recipe_and_the_needle_none() -> void:
	for id in TrickList.TRICK_IDS:
		list.select(id)
		var steps := TrickList.steps_for(id)
		var shown := list.recipe_box.get_children().filter(func(c): return c.name.begins_with("Step"))
		if id == "thread_the_needle":
			assert_eq(steps.size(), 0)
			assert_eq(list.recipe_box.get_child_count(), 0, "no recipe for the needle")
			continue
		assert_gt(steps.size(), 0, id)
		assert_eq(shown.size(), steps.size(), id)
		var arrows := list.recipe_box.get_children().filter(func(c): return "Arrow" in c.name)
		assert_eq(arrows.size(), steps.size() - 1, id)
		for i in range(steps.size()):
			var n := i + 1
			var note: String = _texts["trick_recipe"][id]["step%d_note" % n]
			assert_eq(shown[i].get_node("Note").text, note, "%s note %d" % [id, n])
			if steps[i].has("keys"):
				var letters: Array = _caps(shown[i]).map(func(c): return c.find_child("Letter", true, false).text)
				assert_eq(letters, steps[i]["keys"], "%s step %d keys" % [id, n])
				assert_false(shown[i].has_node("Keys/Badge"))
			else:
				var badge: String = _texts["trick_recipe"][id]["step%d_badge" % n]
				assert_eq(shown[i].get_node("Keys/Badge/Word").text, badge.to_upper(), "%s badge %d" % [id, n])
				assert_eq(_caps(shown[i]).size(), 0)


func test_either_turn_key_tags_are_exactly_the_data_files() -> void:
	list.select("extended_drift")
	assert_eq(list.recipe_box.find_children("EitherTag", "Label", true, false).size(), 1)
	list.select("alternate_drift")
	assert_eq(list.recipe_box.find_children("EitherTag", "Label", true, false).size(), 1, "W + A/D, then S + A")
	list.select("airtime")
	assert_eq(list.recipe_box.find_children("EitherTag", "Label", true, false).size(), 0)
	list.select("air_one_eighty")
	assert_eq(list.recipe_box.find_children("EitherTag", "Label", true, false).size(), 1)


func test_alt_drift_recipe_is_w_a_then_s_a() -> void:
	var steps := TrickList.steps_for("alternate_drift")
	assert_eq(steps[0]["keys"], ["W", "A"])
	assert_eq(steps[1]["keys"], ["S", "A"])
	assert_false(steps[1].has("either"))


func test_every_recipe_text_key_exists_and_is_short() -> void:
	for id in TrickList.TRICK_IDS:
		var steps := TrickList.steps_for(id)
		for i in range(steps.size()):
			var key := "trick_recipe.%s.step%d_" % [id, i + 1]
			assert_ne(TrickList.text(key + "note"), "", key)
			if not steps[i].has("keys"):
				assert_ne(TrickList.text(key + "badge"), "", key)


func test_mouse_and_keyboard_select() -> void:
	list.rows["airtime"].pressed.emit()
	assert_eq(list.selected, "airtime")
	list.rows["three_sixty"].focus_entered.emit()
	assert_eq(list.selected, "three_sixty")
	watch_signals(list)
	list.select("three_sixty")
	assert_signal_not_emitted(list, "selected_changed")
	list.select("alternate_drift")
	assert_signal_emitted(list, "selected_changed")


func test_the_clip_is_freed_when_hidden_and_loaded_again_when_shown() -> void:
	list.select("alternate_drift")
	assert_not_null(list.clip_player.sheet)
	list.hide()
	assert_null(list.clip_player.sheet, "freed when hidden")
	list.show()
	assert_not_null(list.clip_player.sheet, "read again when shown")
	assert_eq(list.key_pad.held, list.clip_player.held_keys())


func test_rows_are_focusable_list_entries_not_buttons() -> void:
	for id in TrickList.TRICK_IDS:
		var row: Control = list.rows[id]
		assert_false(row is BaseButton, id)
		assert_eq(row.focus_mode, Control.FOCUS_ALL)
	var ev := InputEventAction.new()
	ev.action = "ui_accept"
	ev.pressed = true
	list.rows["airtime"]._gui_input(ev)
	assert_eq(list.selected, "airtime", "Enter or Space selects")


## T-543: REVERSE DRIFT!, AURA FARMING! and GRIND! in the list, with the texts of T-533 word for word.
func test_the_three_new_tricks_have_t533s_texts_and_recipes() -> void:
	var names := {"reverse_drift": "REVERSE DRIFT!", "aura": "AURA FARMING!", "rail_grind": "GRIND!"}
	var rules := {
		"reverse_drift": "Hold reverse and steer to drift while moving backwards.",
		"aura": "Stop and sit still for 5 seconds, then every second you stay put pays subs.",
		"rail_grind": "In the air, hold Space and touch a rail to grind it. Let go to launch the way you face.",
	}
	var notes := {"reverse_drift": "Slide backwards", "aura": "5 s, then every s", "rail_grind": "Touch a rail mid-air"}
	var badges := {"aura": "Stand still", "rail_grind": "Hold space"}
	for id in names:
		assert_true(id in TrickList.TRICK_IDS, id)
		assert_eq(_texts["trick"][id], names[id])
		assert_eq(_texts["trick_rule"][id], rules[id])
		assert_eq(_texts["trick_recipe"][id]["step1_note"], notes[id])
		assert_lte(String(notes[id]).length(), 20)
		if badges.has(id):
			assert_eq(_texts["trick_recipe"][id]["step1_badge"], badges[id])
		assert_eq(TrickList.clip_for(id), id)
		assert_eq(TrickList.steps_for(id).size(), 1, id)
		assert_true(FileAccess.file_exists("res://art/tutorial/tricks/%s.png" % id), id)
		assert_true(list.is_loaded(id), id)
	var rev: Dictionary = TrickList.steps_for("reverse_drift")[0]
	assert_eq(rev["keys"], ["S", "A"], "S + A/D")
	assert_eq(rev["either"], ["A"])
	assert_false(TrickList.steps_for("aura")[0].has("keys"), "aura: no keys")
	assert_false(TrickList.steps_for("rail_grind")[0].has("keys"), "grind: no keys shown")


func test_the_list_is_ground_then_air_then_rail_then_the_needle() -> void:
	assert_eq(TrickList.TRICK_IDS, ["extended_drift", "three_sixty", "alternate_drift", "reverse_drift", "aura",
		"air_one_eighty", "air_three_sixty", "airtime", "rail_grind", "thread_the_needle"])
	assert_eq(list.rows.size(), 10)


func test_new_tricks_show_their_one_step_with_the_badge_and_note() -> void:
	list.select("aura")
	var shown := list.recipe_box.get_children().filter(func(c): return c.name.begins_with("Step"))
	assert_eq(shown.size(), 1)
	assert_eq(shown[0].get_node("Keys/Badge/Word").text, "STAND STILL")
	list.select("reverse_drift")
	shown = list.recipe_box.get_children().filter(func(c): return c.name.begins_with("Step"))
	assert_eq(_caps(shown[0]).size(), 2)
	assert_eq(list.recipe_box.find_children("EitherTag", "Label", true, false).size(), 1)
