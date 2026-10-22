extends GutTest
## Task T-238: the level creator's Save button writes the level, under the name in the level name
## field, through LevelStore.save_level into the levels folder, in the elevation map's file format;
## the file passes game/tools/check_level.py, the list shows it, and the game's own map saved from
## the editor builds into the same buildings, boulders, platforms and ramps. Files are written only
## into a temporary levels folder (RunPaths), never the real one.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const MapScene := preload("res://scenes/level/mvp_map.tscn")
const ElevationLayerScript := preload("res://scripts/level/elevation_layer.gd")
const SAMPLE := "res://data/level/elevation_sample_map.json"
const FORMAT_KEYS := ["map", "legend", "ground_rows", "buildings", "pattern_copies", "platforms", "ramps"]

var dir: String


func before_each() -> void:
	dir = RunPaths.file("t238_levels_" + str(randi()))


func _editor(path: String = "") -> LevelCreatorEditor:
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.levels_dir = dir
	if path == "":
		e.open_new()
	else:
		e.open_level(path)
	add_child_autofree(e)
	return e


func _check_level(path: String) -> Array:
	var output: Array = []
	var code := OS.execute("python", [ProjectSettings.globalize_path("res://tools/check_level.py"),
		ProjectSettings.globalize_path(path)], output, true)
	return [code, "\n".join(output)]


## One piece of every kind: a ground tile, a road tile, a building, a boulder, a 3 with a 6 on it,
## a ramp 0 to 3 up the 3 and a ramp 3 to 6 up the 6 (test_editor_rotate_heights.gd's corner).
func _place_one_of_each(e: LevelCreatorEditor) -> void:
	for step in [["ground-gravel2", Vector2(-30.5, -30.5)], ["road-x_zebra_g4", Vector2(-20.0, -30.0)],
			["skyscraper-3", Vector2(40.0, 40.0)], ["boulder-a", Vector2(-50.0, 20.0)],
			["rooftop-3", Vector2(-95.5, -95.5)], ["rooftop-6", Vector2(-41.5, -95.5)],
			["ramp-0-3", Vector2(-85.5, -65.5)], ["ramp-3-6", Vector2(-53.5, -85.5)]]:
		e.panel.pick(step[0])
		if step[0] == "ramp-3-6":
			e.rotate_pick()  # climbing east, up the 6's west side (T-251)
		assert_false(e.place_asset(step[0], step[1]).is_empty(), step[0] + " placed")
	e.panel.pick("")


# ---- Saving a level ------------------------------------------------------------------------------

func test_save_writes_every_kind_in_the_map_format_and_passes_check_level() -> void:
	var e := _editor()
	_place_one_of_each(e)
	e.name_field.text = "Test Level One"
	assert_eq(e.save(), OK)
	var path := dir.path_join("test_level_one.json")
	assert_eq(e.level_path, path, "saved into the levels folder, named after the level")
	assert_true(FileAccess.file_exists(path))
	var saved := LevelStore.load_level(path)
	for key in FORMAT_KEYS:
		assert_true(saved.has(key), "the file has " + key)
	assert_eq(saved.name, "Test Level One")
	assert_eq(saved.buildings.size(), 1)
	assert_eq(saved.pattern_copies.size(), 1)
	assert_eq(saved.pattern_copies[0].boulders.size(), 1)
	assert_eq(saved.platforms.size(), 2)
	assert_eq(saved.ramps.size(), 2)
	assert_eq(saved.ground_rows.size(), 240)
	assert_eq(saved.ground_rows[-30 + 120][-20 + 120], "R", "the road is in ground_rows")
	var res := _check_level(path)
	assert_eq(res[0], 0, "check_level.py: " + res[1])
	assert_string_contains(res[1], "OK")


func test_saving_shows_the_confirmation_from_the_texts() -> void:
	var e := _editor()
	assert_eq(e.save_button.text, CreatorTexts.get_text("save_label"))
	assert_eq(e.name_label.text, CreatorTexts.get_text("name_field_label"))
	assert_eq(e.name_field.text, CreatorTexts.get_text("default_level_name"), "a new level shows the default name")
	assert_eq(e.message_label.text, "")
	e.save_button.pressed.emit()
	assert_ne(CreatorTexts.get_text("save_confirmation"), "")
	assert_eq(e.message_label.text, CreatorTexts.get_text("save_confirmation"))


func test_saving_again_writes_the_same_file_and_a_second_level_gets_its_own() -> void:
	var e := _editor()
	e.name_field.text = "Alpha"
	assert_eq(e.save(), OK)
	var first := e.level_path
	e.place_asset("boulder-a", Vector2(10, 10))
	assert_eq(e.save(), OK)
	assert_eq(e.level_path, first, "the second save overwrites the level's own file")
	assert_eq(LevelStore.load_level(first).pattern_copies.size(), 1)
	var other := _editor()
	other.name_field.text = "Alpha"
	assert_eq(other.save(), OK)
	assert_ne(other.level_path, first, "another level of the same name doesn't overwrite it")
	assert_eq(LevelStore.list_levels(dir).size(), 2)


func test_an_empty_name_saves_under_the_default_name() -> void:
	var e := _editor()
	e.name_field.text = "   "
	assert_eq(e.save(), OK)
	assert_eq(LevelStore.load_level(e.level_path).name, CreatorTexts.get_text("default_level_name"))


func test_file_stem() -> void:
	assert_eq(LevelDocument.file_stem("My Level 2!"), "my_level_2")
	assert_eq(LevelDocument.file_stem("a-b_c"), "a-b_c")
	assert_eq(LevelDocument.file_stem("???"), "level")


# ---- The list shows it --------------------------------------------------------------------------

func test_after_saving_the_list_shows_the_level_and_edit_reopens_it() -> void:
	var c: LevelCreator = load("res://scenes/level_creator/level_creator.tscn").instantiate()
	c.levels_dir = dir
	add_child_autofree(c)
	assert_eq(c.list_screen.rows.size(), 0)
	c.list_screen.new_button.pressed.emit()
	assert_eq(c.editor.levels_dir, dir, "the editor saves into the creator's folder")
	c.editor.place_asset("skyscraper-3", Vector2(40.0, 40.0))
	c.editor.name_field.text = "Saved Level"
	assert_eq(c.editor.save(), OK)
	var path := c.editor.level_path
	c.editor.back_button.pressed.emit()
	assert_eq(c.list_screen.rows.size(), 1)
	assert_eq(c.list_screen.rows[0].name, "Saved Level")
	assert_eq(c.list_screen.rows[0].path, path)
	c.list_screen.rows[0].edit.pressed.emit()
	assert_eq(c.editor.level_path, path)
	assert_eq(c.editor.name_field.text, "Saved Level")
	assert_eq(c.editor.level_data.buildings.size(), 1)


# ---- The game's own map, opened and saved --------------------------------------------------------

## The map and its elevation layer as the run builds them from a file.
func _build_from(path: String) -> Dictionary:
	var map: Node2D = MapScene.instantiate()
	map.layout_path = path
	map.alert_signs_enabled = false
	add_child_autofree(map)
	var elev: Node2D = ElevationLayerScript.new()
	map.add_child(elev)
	elev.setup(map, path)
	var footprints: Array = []
	for b in map.buildings:
		footprints.append(b.footprint)
	var boulders: Array = []
	for b in map.all_boulders():
		boulders.append(b)
	return {"buildings": footprints, "boulders": boulders,
		"platforms": elev.ground_height.platforms, "ramps": elev.ground_height.ramps, "areas": elev.areas.size()}


func test_the_sample_map_opened_and_saved_builds_the_same() -> void:
	var e := _editor(SAMPLE)
	assert_eq(e.name_field.text, "Elevation sample map")
	assert_eq(e.save(), OK)
	var path := e.level_path
	assert_ne(path, SAMPLE, "the game's own map is not overwritten")
	assert_eq(path.get_base_dir(), dir, "it goes into the levels folder")
	var a := _build_from(SAMPLE)
	var b := _build_from(path)
	assert_gt(a.buildings.size(), 0)
	assert_gt(a.boulders.size(), 0)
	assert_gt(a.platforms.size(), 0)
	assert_gt(a.ramps.size(), 0)
	for key in ["buildings", "boulders", "platforms", "ramps", "areas"]:
		assert_eq(b[key], a[key], "same " + key)
	var res := _check_level(path)
	assert_eq(res[0], 0, "check_level.py: " + res[1])
