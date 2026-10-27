extends GutTest
## Task T-234: the level creator's list screen and the editor it opens. Levels are saved only in a
## per-run test folder (RunPaths).

var dir: String


func before_each() -> void:
	dir = RunPaths.file("creator_levels_" + str(randi()))


func _level(level_name: String) -> Dictionary:
	return {"name": level_name, "buildings": [{"x": 0.0, "y": 0.0, "w": 4.0, "h": 4.0}]}


func _creator() -> LevelCreator:
	var c: LevelCreator = load("res://scenes/level_creator/level_creator.tscn").instantiate()
	c.levels_dir = dir
	add_child_autofree(c)
	return c


func test_no_levels_shows_only_the_new_level_button() -> void:
	var list := _creator().list_screen
	assert_eq(list.rows.size(), 0)
	assert_not_null(list.new_button)
	assert_eq(list.new_button.text, CreatorTexts.get_text("new_level_button"))
	var buttons := list.find_children("*", "Button", true, false)
	assert_eq(buttons.size(), 1)


func test_two_levels_are_listed_with_play_and_edit() -> void:
	LevelStore.save_level(dir.path_join("b.json"), _level("Beta"))
	LevelStore.save_level(dir.path_join("a.json"), _level("Alpha"))
	var list := _creator().list_screen
	assert_eq(list.rows.size(), 2)
	assert_eq(list.rows[0].name, "Alpha")
	assert_eq(list.rows[1].name, "Beta")
	for r in list.rows:
		assert_eq(r.play.text, CreatorTexts.get_text("play_action"))
		assert_eq(r.edit.text, CreatorTexts.get_text("edit_action"))
		var names: Array = []
		for l in r.row.find_children("*", "Label", true, false):
			names.append(l.text)
		assert_has(names, r.name)


func test_new_level_opens_the_editor_with_an_empty_map() -> void:
	LevelStore.save_level(dir.path_join("a.json"), _level("Alpha"))
	var c := _creator()
	c.list_screen.new_button.pressed.emit()
	assert_not_null(c.editor)
	assert_eq(c.editor.level_path, "")
	assert_eq(c.editor.level_data.name, CreatorTexts.get_text("default_level_name"))
	assert_eq(c.editor.level_data.buildings, [])
	assert_eq(c.editor.level_data.platforms, [])


func test_edit_opens_the_editor_with_that_level() -> void:
	var path := dir.path_join("a.json")
	LevelStore.save_level(path, _level("Alpha"))
	var c := _creator()
	c.list_screen.rows[0].edit.pressed.emit()
	assert_not_null(c.editor)
	assert_eq(c.editor.level_path, path)
	var opened: Dictionary = c.editor.level_data.duplicate(true)
	opened.erase("spawn")  # T-280: a level without one opens with one at the centre
	assert_eq(opened, _level("Alpha"))


func test_back_returns_to_the_list() -> void:
	var c := _creator()
	c.list_screen.new_button.pressed.emit()
	c.editor.back_button.pressed.emit()
	assert_not_null(c.list_screen)
	assert_null(c.editor)


func test_play_emits_the_signal_with_the_path() -> void:
	# Play now starts a run on the file (T-239), so the level is a whole map: the sample map's data.
	var path := dir.path_join("a.json")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/level/elevation_sample_map.json"))
	data.name = "Alpha"
	LevelStore.save_level(path, data)
	var c := _creator()
	watch_signals(c)
	c.list_screen.rows[0].play.pressed.emit()
	assert_signal_emitted_with_parameters(c, "play_requested", [path])
