extends GutTest
## LevelStore (task T-231). Files go only under the per-run test folder (RunPaths).

const SAMPLE := "res://data/level/elevation_sample_map.json"

var dir: String


func before_each() -> void:
	dir = RunPaths.file("levels_" + str(randi()))


func _level(level_name: String) -> Dictionary:
	return {
		"name": level_name,
		"map": {"width": 20.0, "height": 20.0, "rect": {"x": -10.0, "y": -10.0, "w": 20.0, "h": 20.0}},
		"legend": {"R": "road", "B": "building"},
		"buildings": [{"x": -4.0, "y": -4.0, "w": 8.0, "h": 8.0}],
		"platforms": [{"id": "roof", "x": -4.0, "y": -4.0, "w": 8.0, "h": 8.0, "height": 3.0}],
		"ramps": [],
	}


func test_save_list_and_load_round_trip() -> void:
	var data := _level("Beta")
	var path := dir.path_join("beta.json")
	assert_eq(LevelStore.save_level(path, data), OK)
	var found := LevelStore.list_levels(dir)
	assert_eq(found.size(), 1)
	assert_eq(found[0].name, "Beta")
	assert_eq(found[0].path, path)
	assert_eq(LevelStore.load_level(path), data)


func test_list_is_sorted_by_name() -> void:
	LevelStore.save_level(dir.path_join("a.json"), _level("Zulu"))
	LevelStore.save_level(dir.path_join("b.json"), _level("Alpha"))
	var no_name := _level("")
	no_name.erase("name")
	LevelStore.save_level(dir.path_join("Mike.json"), no_name)
	var names := []
	for l in LevelStore.list_levels(dir):
		names.append(l.name)
	assert_eq(names, ["Alpha", "Mike", "Zulu"])


func test_list_skips_other_files_and_missing_folder() -> void:
	LevelStore.save_level(dir.path_join("ok.json"), _level("Ok"))
	var f := FileAccess.open(dir.path_join("notes.txt"), FileAccess.WRITE)
	f.store_string("hello")
	f.close()
	f = FileAccess.open(dir.path_join("bad.json"), FileAccess.WRITE)
	f.store_string("{ not json")
	f.close()
	assert_eq(LevelStore.list_levels(dir).size(), 1)
	assert_eq(LevelStore.list_levels(dir.path_join("nowhere")), [])


func test_load_missing_file_gives_empty() -> void:
	assert_eq(LevelStore.load_level(dir.path_join("missing.json")), {})


func test_saving_overwrites() -> void:
	var path := dir.path_join("x.json")
	LevelStore.save_level(path, _level("One"))
	LevelStore.save_level(path, _level("Two"))
	assert_eq(LevelStore.load_level(path).name, "Two")
	assert_eq(LevelStore.list_levels(dir).size(), 1)


func test_sample_map_loads_with_its_sections() -> void:
	var data := LevelStore.load_level(SAMPLE)
	for key in ["map", "legend", "ground_rows", "buildings", "pattern_copies", "platforms", "ramps"]:
		assert_true(data.has(key), key)
