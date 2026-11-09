extends GutTest
## Task T-604: the level creator opens a level file named by --open=<path> straight in the editor,
## and Save writes back to that same file (editor.save_in_place), so the board can edit the
## tutorial's practice playground (data/level/practice_playground.json). The real playground is
## only read here: saving is tested on a copy in a temporary folder (RunPaths).

const PLAYGROUND := "res://data/level/practice_playground.json"

var dir: String
var copy_path: String


func before_each() -> void:
	dir = RunPaths.file("t604_" + str(randi()))
	copy_path = dir.path_join("playground_copy.json")
	assert_eq(LevelStore.save_level(copy_path, LevelStore.load_level(PLAYGROUND)), OK)


func after_each() -> void:
	get_tree().paused = false
	await wait_process_frames(1)


func _creator() -> LevelCreator:
	var c: LevelCreator = load("res://scenes/level_creator/level_creator.tscn").instantiate()
	c.levels_dir = dir.path_join("levels")  # the levels folder: must stay empty
	add_child_autofree(c)
	return c


func test_open_arg_reads_the_path() -> void:
	assert_eq(LevelCreator.open_arg(PackedStringArray(["--open=" + PLAYGROUND])), PLAYGROUND)
	assert_eq(LevelCreator.open_arg(PackedStringArray(["--x", "--open=\"res://a b.json\""])), "res://a b.json")
	assert_eq(LevelCreator.open_arg(PackedStringArray(["--record-perf"])), "")
	assert_eq(LevelCreator.open_arg(PackedStringArray()), "")


func test_open_in_place_shows_the_editor_on_that_file() -> void:
	var c := _creator()
	c.open_editor_in_place(copy_path)
	assert_not_null(c.editor)
	assert_true(c.editor.save_in_place)
	assert_eq(c.editor.level_path, copy_path)
	assert_eq(c.editor.save_path(), copy_path, "Save writes back to the opened file")
	assert_eq(c.editor.name_field.text, "Practice playground")


func test_save_writes_back_to_the_file_and_nothing_into_the_levels_folder() -> void:
	var c := _creator()
	c.open_editor_in_place(copy_path)
	var before := LevelStore.load_level(copy_path)
	assert_eq(c.editor.save(), OK)
	var after := LevelStore.load_level(copy_path)
	for key in before:
		assert_true(after.has(key), "kept key " + key)
	assert_eq(JSON.stringify(after, "", true), JSON.stringify(before, "", true),
		"saved with no edit, the playground is written back unchanged")
	assert_eq(after.get("ground_style"), before.get("ground_style"), "the grid ground is kept")
	assert_eq(after.get("spawn"), before.get("spawn"))
	assert_eq(after.get("rails").size(), before.get("rails").size())
	assert_eq(after.get("ramps").size(), before.get("ramps").size())
	assert_false(DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(c.levels_dir)),
		"nothing written into the levels folder")


func test_a_saved_playground_still_loads_in_the_practice() -> void:
	var c := _creator()
	c.open_editor_in_place(copy_path)
	assert_eq(c.editor.save(), OK)
	var data := LevelStore.load_level(copy_path)
	assert_false(data.is_empty())
	assert_true(data.get("ground_style") is Dictionary and data.ground_style.get("kind") == "grid")
	assert_true(data.get("spawn") is Dictionary)


func test_without_the_arg_a_level_from_elsewhere_still_saves_as_a_new_file() -> void:
	var c := _creator()
	c.open_editor_with(copy_path)
	assert_false(c.editor.save_in_place)
	assert_ne(c.editor.save_path(), copy_path, "the old behaviour is unchanged")
