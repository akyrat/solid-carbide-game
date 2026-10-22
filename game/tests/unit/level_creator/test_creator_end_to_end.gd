extends GutTest
## Task T-240: the level creator end to end. From a creator with no levels: New level, one asset of
## every kind (ground tile, road, building, boulder, rooftops at 3 and 6, ramps 0 to 3 and 3 to 6),
## rotate, mirror and delete, a name, Save, Back to the list, the level is listed, Play: the run
## starts on that file with 8:00 on the clock and minions spawning. Files go only into a temporary
## levels folder (RunPaths).

const GameScene := preload("res://scenes/game/game.tscn")
const SAMPLE := "res://data/level/elevation_sample_map.json"
const LEVEL_NAME := "End To End"

var dir: String


func before_each() -> void:
	TestSave.isolate()
	dir = RunPaths.file("t240_levels_" + str(randi()))


func after_each() -> void:
	get_tree().paused = false
	await wait_process_frames(1)
	TestSave.restore()


func _place(e: LevelCreatorEditor, id: String, at: Vector2) -> Dictionary:
	e.panel.pick(id)
	var r := e.place_asset(id, at)
	assert_false(r.is_empty(), id + " placed")
	return r


func test_empty_creator_to_playing_the_level() -> void:
	var c: LevelCreator = load("res://scenes/level_creator/level_creator.tscn").instantiate()
	c.levels_dir = dir
	add_child_autofree(c)
	# No levels: only New level on the list.
	assert_eq(c.list_screen.rows.size(), 0, "no levels yet")
	c.list_screen.new_button.pressed.emit()
	var e: LevelCreatorEditor = c.editor
	assert_not_null(e, "the editor is open")

	# One of every kind.
	var ids := ["ground-gravel2", "road-x_zebra_g4", "skyscraper-3", "boulder-a"]
	var spots := [Vector2(-30.5, -30.5), Vector2(-20.0, -30.0), Vector2(40.0, 40.0), Vector2(-50.0, 20.0)]
	for i in ids.size():
		_place(e, ids[i], spots[i])
	var r3 := _place(e, "rooftop-3", Vector2(-95.5, -95.5))
	var r6 := _place(e, "rooftop-6", Vector2(-41.5, -95.5))
	_place(e, "ramp-0-3", Vector2(-85.5, -65.5))
	_place(e, "ramp-3-6", Vector2(-53.5, -85.5))
	assert_eq(r6.item.on, r3.item.id, "the 6 stands on the 3")

	# Rotate and mirror: a rooftop 3 in its other view, a mirrored boulder.
	e.panel.pick("rooftop-3")
	assert_eq(e.rotate_pick(), "se")
	assert_false(e.place_asset("rooftop-3", Vector2(-100.5, 40.5)).is_empty())
	assert_eq(e.level_data.platforms[2].view, "se")
	e.panel.pick("boulder-b")
	assert_true(e.mirror_pick())
	assert_false(e.place_asset("boulder-b", Vector2(60.5, -60.5)).is_empty())
	assert_eq(e.level_data.pattern_copies[1].boulders[0].variant, "b_mirror")

	# Delete: select the second boulder and remove it.
	e.panel.pick("")
	var boulders_before: int = e.level_data.pattern_copies.size()
	assert_false(e.select_at(Vector2(61.0, -60.0)).is_empty(), "the boulder is selected")
	e.delete_selected()
	assert_eq(e.level_data.pattern_copies.size(), boulders_before - 1, "the boulder is deleted")

	# Name and save, then back to the list.
	e.name_field.text = LEVEL_NAME
	assert_eq(e.save(), OK)
	var path := dir.path_join("end_to_end.json")
	assert_true(FileAccess.file_exists(path))
	e.back_button.pressed.emit()
	assert_not_null(c.list_screen, "the list is shown again")
	assert_eq(c.list_screen.rows.size(), 1, "the saved level is listed")

	# The saved file passes the level checker.
	var output: Array = []
	var code := OS.execute("python", [ProjectSettings.globalize_path("res://tools/check_level.py"),
		ProjectSettings.globalize_path(path)], output, true)
	assert_eq(code, 0, "check_level.py: " + "\n".join(output))

	# Play: the run is on that file, 8:00, minions spawn.
	c.list_screen.rows[0].play.pressed.emit()
	var run: Node2D = c.run
	assert_not_null(run)
	assert_eq(run.layout_path, path)
	assert_eq(str(run.map.layout.name), LEVEL_NAME)
	assert_true(run.state.is_running())
	assert_eq(run.state.time_left_text(), "8:00")
	for i in 40:
		run.minions.step(0.25)
		if run.minions.minions.size() > 0:
			break
	assert_gt(run.minions.minions.size(), 0, "minions spawned")


func test_the_main_menu_run_uses_the_elevation_sample_map() -> void:
	var game: GameFlow = GameScene.instantiate()
	game.quit_game = func(): pass
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()
	assert_eq(game.run.layout_path, SAMPLE)
	assert_eq(game.run.map.layout_path, SAMPLE)
