extends GutTest
## Task T-549 (Level design, Decisions, "A ramp may climb onto several rooftops"): the level creator
## loads, relinks, snaps and saves a ramp whose top end meets two rooftops of its top height side by
## side, and what it saves passes check_level.py and check_height_data.py. Levels are saved only
## into a temporary folder (RunPaths); the board's own levels are read, never written.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const FIXTURE := "res://tests/fixtures/height/ramp_onto_two_rooftops.json"
## The board's own Kaiju City (main checkout, untracked): read only. Its tests are skipped when absent.
const BOARD_KAIJU_CITY := "C:/solid-carbide-game/game/data/levels/kaiju_city.json"

var dir: String


func before_each() -> void:
	TestSave.isolate()
	dir = RunPaths.file("t549_levels_" + str(randi()))


func after_each() -> void:
	TestSave.restore()


## An editor on a new level holding the fixture's rooftops and ramps (ramps unlinked), opened
## from a file in the temporary folder.
func _editor_with_fixture() -> LevelCreatorEditor:
	var d := LevelCreatorEditor.empty_level()
	var fx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	d["platforms"] = fx.platforms.duplicate(true)
	d["ramps"] = fx.ramps.duplicate(true)
	d["spawn"] = {"x": 60.0, "y": 60.0, "heading": 270.0}  # on the street, away from the pieces
	var path := dir.path_join("two_rooftops.json")
	assert_eq(LevelStore.save_level(path, d), OK)
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.levels_dir = dir
	add_child_autofree(e)
	e.open_level(path)
	return e


func _ramp(e: LevelCreatorEditor, id: String) -> Dictionary:
	for r in e.document.data.ramps:
		if str(r.id) == id:
			return r
	return {}


## Runs one of the level checks on a saved file: [exit code, output].
func _check(tool: String, path: String) -> Array:
	var output: Array = []
	var code := OS.execute("python", [ProjectSettings.globalize_path("res://tools/" + tool),
		ProjectSettings.globalize_path(path)], output, true)
	return [code, "\n".join(output)]


func _assert_checks_pass(path: String) -> void:
	for tool in ["check_level.py", "check_height_data.py"]:
		var res := _check(tool, path)
		assert_eq(res[0], 0, "%s: %s" % [tool, res[1]])


func test_top_areas_finds_both_rooftops_and_their_cover() -> void:
	var e := _editor_with_fixture()
	var shared := LevelDocument.top_areas("west", Rect2(-88, -108, 12, 18), e.document.surfaces(), 6.0)
	assert_eq(shared.areas.map(func(a): return str(a.id)), ["roof-6", "roof-7"])
	assert_true(shared.covered)
	var short := LevelDocument.top_areas("west", Rect2(-88, -112, 12, 22), e.document.surfaces(), 6.0)
	assert_false(short.covered, "4 units of its top end meet no rooftop")
	assert_true(LevelDocument.top_areas("west", Rect2(-90, -108, 12, 18), e.document.surfaces(), 6.0).areas.is_empty())


func test_relink_names_the_first_rooftop_and_keeps_a_right_link() -> void:
	var e := _editor_with_fixture()
	e.document._relink()
	assert_eq(str(_ramp(e, "ramp-2").platform), "roof-6", "the first of roof-6 and roof-7 in the file")
	assert_eq(str(_ramp(e, "ramp-13").platform), "roof-3", "the first of roof-3 and roof-6 in the file")
	_ramp(e, "ramp-2")["platform"] = "roof-7"
	e.document._relink()
	assert_eq(str(_ramp(e, "ramp-2").platform), "roof-7", "the other rooftop is still right: kept")
	_ramp(e, "ramp-2")["platform"] = "roof-3"
	e.document._relink()
	assert_eq(str(_ramp(e, "ramp-2").platform), "roof-6", "a wrong link is filled in again")


func test_relink_leaves_a_ramp_meeting_nothing_unlinked() -> void:
	var e := _editor_with_fixture()
	_ramp(e, "ramp-2")["x"] = -90.0
	e.document._relink()
	assert_eq(str(_ramp(e, "ramp-2").platform), "")


func test_a_ramp_snaps_onto_the_two_rooftops_side_by_side() -> void:
	var e := _editor_with_fixture()
	# Its top end 2 units short of the rooftops' west sides, 2 units north of roof-6: neither side
	# alone holds its 18 units, together they do.
	var snap := LevelSnapping.ramp_snap(e.document, Rect2(-90, -110, 12, 18), "west", 6.0)
	assert_false(snap.is_empty(), "it snaps")
	assert_eq(snap.rect, Rect2(-88, -108, 12, 18))


func test_saved_after_relinking_it_passes_the_checks_and_loads() -> void:
	var e := _editor_with_fixture()
	_assert_checks_pass(e.level_path)  # as loaded, "platform" empty
	e.document._relink()
	e.name_field.text = "two rooftops"
	assert_eq(e.save(), OK)
	_assert_checks_pass(e.save_path())
	var back := LevelStore.load_level(e.save_path())
	var g := GroundHeight.new()
	assert_true(g.load_data(back), g.error)
	assert_almost_eq(g.height_at(Vector2(-70, -102)), 6.0, 1e-4)
	assert_almost_eq(g.height_at(Vector2(-70, -92)), 6.0, 1e-4)


func test_the_boards_kaiju_city_loads_relinks_and_saves() -> void:
	if not FileAccess.file_exists(BOARD_KAIJU_CITY):
		pass_test("the board's Kaiju City is not on this computer")
		return
	var before := FileAccess.get_file_as_string(BOARD_KAIJU_CITY)
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.levels_dir = dir
	add_child_autofree(e)
	e.open_level(BOARD_KAIJU_CITY)
	assert_eq(str(_ramp(e, "ramp-2").platform), "", "as the board saved it")
	e.document._relink()
	assert_eq(str(_ramp(e, "ramp-2").platform), "roof-6")
	assert_eq(str(_ramp(e, "ramp-13").platform), "roof-3")
	# Saved into the temporary folder only, never over the board's file.
	var out := dir.path_join("kaiju_city_copy.json")
	assert_eq(LevelStore.save_level(out, e.document.file_data("Kaiju City")), OK)
	_assert_checks_pass(out)
	assert_eq(FileAccess.get_file_as_string(BOARD_KAIJU_CITY), before, "the board's file is unchanged")
