extends GutTest
## Task T-230: the run plays any map file (run.gd's layout_path, or
## start_run(path)), with the elevation sample map as the default. The copy
## used here is elevation_sample_map.json saved under the per-run test folder
## (user://, RunPaths) with its first building (12, -96) and the rooftop
## roof-se-6 (with ramp-se-3-6, the ramp up to it) removed.

const RunScene := preload("res://scenes/run/run.tscn")
const RunScript := preload("res://scripts/run/run.gd")
const NavScript := preload("res://scripts/enemies/enemy_navigation.gd")
const DEFAULT_LAYOUT := "res://data/level/elevation_sample_map.json"
const REMOVED_PLATFORM := "roof-se-6"
const REMOVED_RAMP := "ramp-se-3-6"

var copy_path := ""
var default_data: Dictionary


func before_all() -> void:
	default_data = JSON.parse_string(FileAccess.get_file_as_string(DEFAULT_LAYOUT))
	var data: Dictionary = default_data.duplicate(true)
	data.buildings.remove_at(0)
	data.platforms = data.platforms.filter(func(p): return str(p.id) != REMOVED_PLATFORM)
	data.ramps = data.ramps.filter(func(r): return str(r.id) != REMOVED_RAMP)
	data.name = "T-230 test copy"
	copy_path = RunPaths.file("t230_custom_map.json")
	var f := FileAccess.open(copy_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, " "))
	f.close()


func _new_run(path: String = "") -> Node2D:
	var run: Node2D = RunScene.instantiate()
	if path != "":
		run.layout_path = path
	add_child_autofree(run)
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	run.minions.enabled = false
	return run


func _platform_ids(run: Node2D) -> Array:
	return run.elevation.ground_height.platforms.map(func(p): return str(p.id))


# --- The default ---------------------------------------------------------------

func test_with_no_path_the_run_plays_the_elevation_sample_map() -> void:
	var run := _new_run()
	assert_eq(run.layout_path, RunScript.ELEVATION_LAYOUT_PATH)
	assert_eq(run.current_layout_path(), DEFAULT_LAYOUT)
	assert_eq(run.map.layout_path, DEFAULT_LAYOUT)
	assert_eq(run.map.buildings.size(), default_data.buildings.size())
	assert_eq(run.elevation.ground_height.platforms.size(), default_data.platforms.size())


func test_an_empty_path_falls_back_to_the_default() -> void:
	var run := _new_run()
	run.layout_path = ""
	run.start_run()
	assert_eq(run.map.layout_path, DEFAULT_LAYOUT)
	assert_eq(str(run.map.layout.name), "Elevation sample map")


# --- Another map file ------------------------------------------------------------

func test_the_copy_is_saved_under_user() -> void:
	assert_true(copy_path.begins_with("user://"), copy_path)
	assert_true(FileAccess.file_exists(copy_path))


func test_a_run_set_before_the_tree_plays_the_copy() -> void:
	var run := _new_run(copy_path)
	assert_eq(run.map.layout_path, copy_path, "the map read the copy")
	assert_eq(str(run.map.layout.name), "T-230 test copy")
	assert_eq(run.map.buildings.size(), default_data.buildings.size() - 1, "one building fewer")
	assert_eq(run.map.layout.buildings.size(), default_data.buildings.size() - 1)
	assert_eq(run.elevation.ground_height.platforms.size(), default_data.platforms.size() - 1,
		"the elevation layer read the copy: one platform fewer")
	assert_false(_platform_ids(run).has(REMOVED_PLATFORM))
	assert_eq(run.elevation.areas.size(),
		default_data.platforms.size() - 1 + default_data.ramps.size() - 1, "one drawing per area")
	assert_eq(run.car.ground, run.elevation.ground_height, "the car drives on the copy's heights")


func test_the_removed_building_is_open_street() -> void:
	var run := _new_run(copy_path)
	var b: Dictionary = default_data.buildings[0]
	var centre := Vector2(float(b.x) + float(b.w) / 2.0, float(b.y) + float(b.h) / 2.0)
	for item in run.map.buildings:
		assert_false(item.footprint.has_point(centre), "no building at the removed one's place")


func test_start_run_with_a_path_switches_maps() -> void:
	var run := _new_run()
	assert_eq(run.map.buildings.size(), default_data.buildings.size())
	run.start_run(copy_path)
	assert_eq(run.layout_path, copy_path)
	assert_eq(run.map.layout_path, copy_path)
	assert_eq(run.map.buildings.size(), default_data.buildings.size() - 1)
	assert_eq(run.elevation.ground_height.platforms.size(), default_data.platforms.size() - 1)
	run.start_run()
	assert_eq(run.map.layout_path, copy_path, "a new run keeps the run's map file")


func test_the_mvp_switch_still_wins() -> void:
	var run := _new_run(copy_path)
	run.use_elevation_map = false
	run.start_run()
	assert_eq(run.map.layout_path, "res://data/level/mvp_map.json")
	assert_null(run.elevation)


# --- Enemy navigation on the copy -------------------------------------------------

## True when the segment a-b passes over `rect` (sampled every quarter unit).
func _segment_over(a: Vector2, b: Vector2, rect: Rect2) -> bool:
	var steps := maxi(1, int(ceil(a.distance_to(b) * 4.0)))
	for i in steps + 1:
		if rect.has_point(a.lerp(b, float(i) / steps)):
			return true
	return false


func test_enemy_navigation_climbs_a_ramp_on_the_copy() -> void:
	var run := _new_run(copy_path)
	var nav = NavScript.for_map(run.map)
	assert_not_null(nav, "navigation builds for the run's map")
	assert_eq(nav.ground, run.elevation.ground_height, "from the copy's heights")
	var street := Vector2(-60, -48)  # the street south-east of roof-nw-3's ramp
	var rooftop := Vector2(-80, -80)  # on roof-nw-3, height 3
	assert_almost_eq(run.elevation.ground_height.height_at(street), 0.0, 0.001)
	assert_almost_eq(run.elevation.ground_height.height_at(rooftop), 3.0, 0.001)
	var path: PackedVector2Array = nav.find_path(street, rooftop)
	assert_gt(path.size(), 0, "a path from the street to the rooftop")
	var over_ramp := false
	for r in run.elevation.ground_height.ramps:
		for i in path.size() - 1:
			if _segment_over(path[i], path[i + 1], r.rect):
				over_ramp = true
	assert_true(over_ramp, "the path goes over a ramp's rectangle")
	assert_eq(run.elevation.ground_height.area_index_at(path[path.size() - 1]),
		run.elevation.ground_height.area_index_at(rooftop), "it ends on the rooftop")


func test_navigation_on_the_copy_has_no_removed_building() -> void:
	var run := _new_run(copy_path)
	var nav = NavScript.for_map(run.map)
	var b: Dictionary = default_data.buildings[0]
	var centre := Vector2(float(b.x) + float(b.w) / 2.0, float(b.y) + float(b.h) / 2.0)
	var k: int = nav.cell_at(centre)
	assert_gt(k, -1)
	assert_eq(nav.open[k], 1, "the removed building's cells are open on the copy")
