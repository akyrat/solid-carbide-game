extends GutTest
## Task T-391 (Level design, Decisions, "Roads painted in the creator show in the run"): roads
## painted with the creator's road brush are drawn in the run. Before the fix the run's map always
## drew the game's own ground (data/level/mvp_ground.json), whatever the level's "ground" held;
## now mvp_map.gd draws the level's own ground (LevelGround.layout_of), the same layout the editor
## draws (LevelDocument.ground_layout). The game's own map, and a level without creator ground,
## draw the game's ground as before. Levels are saved only into a temporary folder (RunPaths).

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const MapScene := preload("res://scenes/level/mvp_map.tscn")
const SAMPLE := "res://data/level/elevation_sample_map.json"
const GROUND_PATH := "res://data/level/mvp_ground.json"

var dir: String


func before_each() -> void:
	TestSave.isolate()
	dir = RunPaths.file("t391_levels_" + str(randi()))


func after_each() -> void:
	get_tree().paused = false
	await wait_process_frames(1)
	TestSave.restore()


func _editor() -> LevelCreatorEditor:
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.levels_dir = dir
	e.open_new()
	add_child_autofree(e)
	return e


func _at(e: LevelCreatorEditor, b: Vector2i) -> Vector2:
	return RoadBrush.block_rect(e.document, b).get_center()


func _paint(e: LevelCreatorEditor, family: String, blocks: Array) -> void:
	e.panel.pick(family)
	e.paint_road(blocks.map(func(b): return _at(e, b)))


## A level with roads of every kind, a crossroads, T-junctions, corners, dead ends, a zebra crossing
## and a rooftop with its ramp beside a road, saved; returns the editor (its document is the level).
func _painted_level() -> LevelCreatorEditor:
	var e := _editor()
	# Road: a crossroads with four dead ends.
	_paint(e, "road", [Vector2i(10, 10), Vector2i(20, 10)])
	_paint(e, "road", [Vector2i(15, 6), Vector2i(15, 14)])
	# Centre line: a crossroads, a T-junction and a corner (a plain road's junctions are all plain).
	_paint(e, "centre-line", [Vector2i(10, 25), Vector2i(20, 25)])
	_paint(e, "centre-line", [Vector2i(15, 21), Vector2i(15, 30)])
	_paint(e, "centre-line", [Vector2i(12, 25), Vector2i(12, 30)])
	_paint(e, "centre-line", [Vector2i(30, 25), Vector2i(36, 25), Vector2i(36, 30)])
	# Cracked road with a zebra crossing on its straight.
	_paint(e, "cracked-road", [Vector2i(10, 40), Vector2i(20, 40)])
	e.panel.pick("zebra-crossing")
	assert_true(e.place_zebra(RoadBrush.block_rect(e.document, Vector2i(13, 40)).position + Vector2(1, 1)), "zebra laid")
	# A rooftop and its ramp beside the first road's east end.
	e.panel.pick("")
	var roof_corner := RoadBrush.block_rect(e.document, Vector2i(22, 8)).position
	assert_false(e.place_asset("rooftop-3", roof_corner, Vector2(8, 8)).is_empty(), "rooftop placed")
	assert_false(e.place_asset("ramp-0-3", roof_corner + Vector2(0, 8), Vector2(8, 0)).is_empty(), "ramp placed")
	e.name_field.text = "T-391 roads"
	assert_eq(e.save(), OK)
	return e


func _road_cells(doc: LevelDocument) -> Array:
	var out: Array = []
	for j in doc.cells.size():
		for i in doc.cells[j].size():
			if str(doc.cells[j][i]).begins_with("road-"):
				out.append(Vector2i(i, j))
	return out


func _run_on(path: String) -> Node2D:
	var progress := PlayerProgress.new()
	return GameFlow.add_run(self, progress, path)


# ---- Painted roads are drawn in the run --------------------------------------------------------

func test_every_painted_road_cell_is_drawn_in_the_run_with_its_tile() -> void:
	var e := _painted_level()
	var doc: LevelDocument = e.document
	var roads := _road_cells(doc)
	assert_gt(roads.size(), 100, "roads were painted")
	# Every kind of piece is among the painted tiles.
	var ids := {}
	for c in roads:
		ids[str(doc.cells[c.y][c.x])] = true
	var joined := " ".join(ids.keys())
	for part in ["cross", "t_", "corner", "dead", "zebra", "line", "g4", "plain_a0"]:
		assert_true(joined.contains(part), "a painted %s tile" % part)
	var path := e.level_path
	assert_true(path.begins_with("user://"), path)
	var run := _run_on(path)
	await wait_process_frames(1)
	var g: Dictionary = run.map.ground_layout
	var values := LevelGround.values()
	var wrong: Array = []
	for c in roads:
		var id := str(doc.cells[c.y][c.x])
		assert_true(values.has(id), "a known tile: " + id)
		if int(g.cells[c.y][c.x]) != int(values.get(id, -2)):
			wrong.append("%s %s" % [c, id])
	assert_eq(wrong.size(), 0, "painted cells drawn with another tile: %s" % str(wrong.slice(0, 5)))
	# The whole ground is the one the editor drew, at the map's corner.
	assert_eq(g, doc.ground_layout())
	assert_eq(Vector2(float(g.origin[0]), float(g.origin[1])), doc.map_rect().position)
	# And the run draws it: the ground tiles node has the atlas.
	assert_true(run.map.ground_tiles.has_art())
	run.queue_free()


func test_a_saved_level_reopened_keeps_drawing_its_roads() -> void:
	var e := _painted_level()
	var data := LevelStore.load_level(e.level_path)
	assert_eq(LevelGround.layout_of(data), e.document.ground_layout())


# ---- The game's own map and earlier levels are as before ---------------------------------------

func _map_of(layout: Dictionary) -> Node2D:
	var m: Node2D = MapScene.instantiate()
	m.layout = LevelDocument.new(layout.duplicate(true)).map_layout() if layout.has("ground") else layout
	m.alert_signs_enabled = false
	add_child_autofree(m)
	return m


func test_the_games_own_map_draws_the_games_ground() -> void:
	var sample: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAMPLE))
	assert_false(sample.has("ground"))
	var game_ground: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GROUND_PATH))
	assert_eq(_map_of(sample).ground_layout, game_ground)
	var default_map: Node2D = MapScene.instantiate()
	add_child_autofree(default_map)
	assert_eq(default_map.ground_layout, game_ground, "the MVP map's default too")


func test_a_level_without_creator_ground_draws_the_games_ground() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAMPLE))
	data.name = "T-391 old level"
	var path := dir.path_join("old.json")
	assert_eq(LevelStore.save_level(path, data), OK)
	var game_ground: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GROUND_PATH))
	assert_eq(LevelGround.layout_of(LevelStore.load_level(path)), {})
	var run := _run_on(path)
	await wait_process_frames(1)
	assert_eq(run.map.ground_layout, game_ground)
	run.queue_free()


func test_a_level_saved_before_draws_its_own_saved_ground() -> void:
	# The board's level saved before T-262 (all gravel cells with a creator ground): drawn as saved.
	var data := LevelStore.load_level("res://tests/fixtures/t262_level_saved_before.json")
	assert_true(data.has("ground"))
	var layout := LevelGround.layout_of(data)
	var doc := LevelDocument.new(data.duplicate(true))
	assert_eq(layout, doc.ground_layout())
	assert_eq(_map_of(data).ground_layout, layout)


# ---- LevelGround -------------------------------------------------------------------------------

func test_level_ground_reads_the_saved_tile_list() -> void:
	var data := {"map": {"rect": {"x": -4, "y": -2, "w": 4, "h": 4}},
		"ground": {"cell_units": 2, "origin": [-4, -2], "cols": 2.0, "rows": 2.0,
			"tiles": ["ground-gravel0", "road-y_plain_a0"], "cells": [[0, 1], [1.0, 7]]}}
	var g := LevelGround.layout_of(data)
	var v := LevelGround.values()
	assert_eq(g.cells, [[v["ground-gravel0"], v["road-y_plain_a0"]], [v["road-y_plain_a0"], v["ground-gravel0"]]],
		"float indices read, an index out of the list is the base ground")
	assert_eq(g.origin, [-4.0, -2.0])
	assert_eq([g.cols, g.rows], [2, 2])
	assert_eq(LevelGround.layout_of({}), {})
	assert_eq(LevelGround.EXTRA_BASE, LevelDocument.EXTRA_BASE)
