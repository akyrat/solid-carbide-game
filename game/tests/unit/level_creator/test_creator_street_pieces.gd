extends GutTest
## Task T-398: the level creator's sidewalks (painted like roads, the curb added by itself where a
## sidewalk meets a road), meteor craters (ground decals the car drives over) and parked and broken
## cars (solid obstacles at four facings, a few models each, pairable for thread the needle), with
## placeholders. Names from T-396 and T-401 in creator_texts.json.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const RunScene := preload("res://scenes/run/run.tscn")
const NavScript := preload("res://scripts/enemies/enemy_navigation.gd")
const ROAD_TILE := "road-y_plain_a0"
const CARS := ["prop-parked-car-1", "prop-parked-car-2", "prop-parked-car-3", "prop-broken-car-1", "prop-broken-car-2"]
const ROTATIONS := ["north", "east", "south", "west"]
const FACINGS := {"north": "facing_top_right", "east": "facing_bottom_right", "south": "facing_bottom_left",
	"west": "facing_top_left"}


func _editor() -> LevelCreatorEditor:
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.open_new()
	e.level_data["spawn"] = {"x": 111.0, "y": 111.0, "heading": 270}
	e.levels_dir = RunPaths.file("t398_levels")
	add_child_autofree(e)
	return e


func _doc() -> LevelDocument:
	return LevelDocument.new(LevelDocument.new_level_data("T-398"))


func _pick(e: LevelCreatorEditor, id: String, view: String) -> void:
	e.panel.pick(id)
	for i in 4:
		if e.pick_view == view:
			return
		e.rotate_pick()


func _check_level(path: String) -> Array:
	var output: Array = []
	var code := OS.execute("python", [ProjectSettings.globalize_path("res://tools/check_level.py"),
		ProjectSettings.globalize_path(path)], output, true)
	return [code, "\n".join(output)]


# ---- The curbs ----------------------------------------------------------------------------------

func test_every_curb_piece_has_a_catalogue_tile() -> void:
	var names := {}
	for e in LevelDocument.entries():
		if e.has("sidewalk"):
			names[str(e.id)] = true
			var c: Dictionary = SidewalkBrush.curbs_of(str(e.id))
			assert_eq(SidewalkBrush.tile_name(c.edges, c.corners), str(e.id), "names read back")
			assert_eq(str(e.kind), "ground")
	assert_eq(names.size(), 47)


func test_straight_curbs_on_every_side_of_a_road() -> void:
	var d := _doc()
	var road := Vector2i(10, 10)
	d.set_cells({road: ROAD_TILE})
	var want := {Vector2i(10, 9): "sidewalk-s", Vector2i(11, 10): "sidewalk-w", Vector2i(10, 11): "sidewalk-n",
		Vector2i(9, 10): "sidewalk-e"}
	var changes := {}
	for c in want:
		changes[c] = "sidewalk"
	d.set_cells(changes)
	for c in want:
		assert_eq(d.tile_at(c), want[c], str(c))


func test_inner_corners_where_a_road_is_only_diagonal() -> void:
	var d := _doc()
	d.set_cells({Vector2i(10, 10): ROAD_TILE})
	d.set_cells({Vector2i(9, 9): "sidewalk", Vector2i(11, 9): "sidewalk", Vector2i(11, 11): "sidewalk",
		Vector2i(9, 11): "sidewalk"})
	assert_eq(d.tile_at(Vector2i(9, 9)), "sidewalk-in_se")
	assert_eq(d.tile_at(Vector2i(11, 9)), "sidewalk-in_sw")
	assert_eq(d.tile_at(Vector2i(11, 11)), "sidewalk-in_nw")
	assert_eq(d.tile_at(Vector2i(9, 11)), "sidewalk-in_ne")


func test_outer_corners_from_two_edges() -> void:
	var d := _doc()
	# A road bending round the sidewalk: road east and south of it, and on the diagonal.
	d.set_cells({Vector2i(11, 10): ROAD_TILE, Vector2i(10, 11): ROAD_TILE, Vector2i(11, 11): ROAD_TILE})
	d.set_cells({Vector2i(10, 10): "sidewalk"})
	assert_eq(d.tile_at(Vector2i(10, 10)), "sidewalk-es")
	d.set_cells({Vector2i(9, 9): ROAD_TILE, Vector2i(10, 9): ROAD_TILE, Vector2i(9, 10): ROAD_TILE})
	assert_eq(d.tile_at(Vector2i(10, 10)), "sidewalk-nesw", "a road all round")


func test_a_sidewalk_away_from_roads_is_plain_and_the_map_edge_is_no_road() -> void:
	var d := _doc()
	d.set_cells({Vector2i(0, 0): "sidewalk", Vector2i(30, 30): "sidewalk"})
	assert_eq(d.tile_at(Vector2i(0, 0)), "sidewalk")
	assert_eq(d.tile_at(Vector2i(30, 30)), "sidewalk")


func test_the_brush_paints_along_a_drag_and_the_curb_follows_the_road() -> void:
	var e := _editor()
	e.panel.pick("road")
	e.paint_road([Vector2(1, -20), Vector2(1, 20)])  # a road along y, units x 0..4
	e.panel.pick("sidewalk")
	assert_eq(e.brush_mode(), "sidewalk")
	e.paint_sidewalk([Vector2(5, -10), Vector2(5, 10)])  # cells at x 4..6, beside the road
	e.paint_sidewalk([Vector2(-1, -10), Vector2(-1, 10)])  # cells at x -2..0
	var d := e.document
	for y in range(-10, 11, 2):
		assert_eq(d.tile_at(d.cell_at(Vector2(5, y + 0.5))), "sidewalk-w", "east side at y %d" % y)
		assert_eq(d.tile_at(d.cell_at(Vector2(-1, y + 0.5))), "sidewalk-e", "west side at y %d" % y)
	# Erasing the road takes the curb away; painting it again brings it back.
	e.panel.pick("road")
	e.erase_road([Vector2(1, -20), Vector2(1, 20)])
	assert_eq(d.tile_at(d.cell_at(Vector2(5, 0.5))), "sidewalk")
	e.paint_road([Vector2(1, -20), Vector2(1, 20)])
	assert_eq(d.tile_at(d.cell_at(Vector2(5, 0.5))), "sidewalk-w")
	# The run's ground layout draws them (cells outside the atlas: the sheet's regions).
	var lay := d.ground_layout()
	var k := int(lay.cells[d.cell_at(Vector2(5, 0.5)).y][d.cell_at(Vector2(5, 0.5)).x])
	assert_gte(k, LevelGround.EXTRA_BASE)
	assert_true(lay.extra[k - LevelGround.EXTRA_BASE] is Dictionary, "a region of the sheet")


func test_a_sidewalk_is_not_painted_over_a_road_or_a_building_and_erases() -> void:
	var e := _editor()
	e.panel.pick("road")
	e.paint_road([Vector2(1, 1)])
	e.panel.pick("building-small")
	assert_false(e.place_asset("building-small", Vector2(20.5, 20.5)).is_empty())
	e.panel.pick("sidewalk")
	e.paint_sidewalk([Vector2(1, 1)])
	assert_eq(LevelDocument._kind_of_tile(e.document.tile_at(e.document.cell_at(Vector2(1, 1)))), "road")
	var b: Dictionary = e.level_data.buildings[0]
	var inside := Vector2(float(b.x) + 1.0, float(b.y) + 1.0)
	e.paint_sidewalk([inside])
	assert_false(SidewalkBrush.is_sidewalk(e.document.tile_at(e.document.cell_at(inside))))
	e.paint_sidewalk([Vector2(-30, -30), Vector2(-20, -30)])
	assert_true(SidewalkBrush.is_sidewalk(e.document.tile_at(e.document.cell_at(Vector2(-25, -29.5)))))
	e.erase_sidewalk([Vector2(-30, -30), Vector2(-20, -30)])
	assert_eq(e.document.tile_at(e.document.cell_at(Vector2(-25, -29.5))), LevelDocument.BASE_GROUND)


# ---- Craters ------------------------------------------------------------------------------------

func test_craters_place_with_their_models_and_are_refused_on_a_building() -> void:
	var e := _editor()
	var fam := CreatorFamilies.family("meteor-crater")
	assert_eq(int(fam.looks), 3)
	for i in 3:
		e.panel.pick("crater-%d" % (i + 1))
		var p := e.place_asset("crater-%d" % (i + 1), Vector2(-20 + 4 * i, 30) + Vector2(0.1, 0.1))
		assert_false(p.is_empty())
		assert_eq(p.kind, "crater")
	assert_eq(e.level_data.craters.size(), 3)
	assert_eq(e.panel.look_counter.text, CreatorTexts.get_text("model_counter").format({"n": 3, "count": 3}))
	e.panel.pick("building-small")
	var b := e.place_asset("building-small", Vector2(40.5, 40.5))
	e.panel.pick("crater-1")
	assert_true(e.place_asset("crater-1", Rect2(float(b.item.x), float(b.item.y), 1, 1).position + Vector2(0.5, 0.5)).is_empty())
	# Selected and deleted.
	e.panel.pick("")
	assert_eq(e.select_at(Vector2(-19, 31)).kind, "crater")
	e.delete_selected()
	assert_eq(e.level_data.craters.size(), 2)


func test_craters_are_drawn_on_the_ground_and_are_no_obstacle() -> void:
	var e := _editor()
	e.panel.pick("crater-2")
	e.place_asset("crater-2", Vector2(0.1, 0.1))
	var decals := LevelCraters.decals_of(e.map.layout)
	assert_eq(decals.size(), 1)
	# Over the cell's ground tile, exactly its diamond (64 x 32 screen px for 2 x 2 units).
	assert_eq((decals[0].rect as Rect2).size, Vector2(64, 32))
	assert_eq((decals[0].rect as Rect2).position, e.map.ground_cell_top(60, 60) - Vector2(32, 0))
	assert_false(e.map.prop_blocks_spot(Vector2(1, 1), 0.5))
	assert_true(e.map.is_open_spot(Vector2(1, 1), 0.5))
	var nav = NavScript.build_for_map(e.map)
	assert_eq(nav.open[nav.cell_at(Vector2(1, 1))], 1, "enemies cross it")


# ---- Cars ---------------------------------------------------------------------------------------

func test_cars_place_at_four_facings_and_each_model_with_the_facing_label() -> void:
	var e := _editor()
	var n := 0
	for id in CARS:
		for rot in ROTATIONS:
			_pick(e, id, rot)
			assert_eq(e.direction_label.text, CreatorTexts.get_text(FACINGS[rot]), "%s %s label" % [id, rot])
			var p := e.place_asset(id, Vector2(-100 + 6 * n, 40) + Vector2(0.1, 0.1))
			assert_false(p.is_empty(), "%s %s" % [id, rot])
			assert_eq(p.item.rotation, rot)
			assert_eq(Rect2(float(p.item.x), float(p.item.y), float(p.item.w), float(p.item.h)).size, LevelProps.footprint(id, rot))
			n += 1
	assert_eq(e.level_data.props.size(), 20)
	e.panel.pick("prop-parked-car-2")
	assert_eq(e.panel.look_counter.text, CreatorTexts.get_text("model_counter").format({"n": 2, "count": 3}))
	assert_eq(CreatorFamilies.family("broken-car").looks, 2)


func test_the_panel_shows_the_new_names() -> void:
	var e := _editor()
	var by_cat := e.panel.entries_by_category()
	assert_eq(by_cat[CreatorTexts.get_text("group_ground")], ["gravel", "sidewalk", "meteor-crater"])
	assert_eq(by_cat[CreatorTexts.get_text("group_obstacles")], ["boulder", "barrier", "cones", "crates", "parked-car", "broken-car"])
	assert_eq(e.panel.buttons["sidewalk"].text, "Sidewalk")
	assert_eq(e.panel.buttons["meteor-crater"].text, "Meteor crater")
	assert_eq(e.panel.buttons["parked-car"].text, "Parked car")
	assert_eq(e.panel.buttons["broken-car"].text, "Broken car")


func test_cars_pair_and_chain_for_thread_the_needle() -> void:
	var e := _editor()
	var cars: Array = []
	for i in 3:
		_pick(e, CARS[i * 2 % CARS.size()], "east")
		var p := e.place_asset(CARS[i * 2 % CARS.size()], Vector2(-20 + 8 * i, -30.9))
		assert_false(p.is_empty())
		assert_true(LevelDocument.is_obstacle(p), "a car is an obstacle")
		cars.append(p)
	var made := e.document.make_chain(cars)
	assert_eq(made.size(), 2)
	assert_eq(e.document.pairs().size(), 2)


# ---- Saving, the check, earlier levels, the game's map ------------------------------------------

func test_new_pieces_save_reopen_and_pass_check_level() -> void:
	var e := _editor()
	e.panel.pick("road")
	e.paint_road([Vector2(1, -20), Vector2(1, 20)])
	e.panel.pick("sidewalk")
	e.paint_sidewalk([Vector2(5, -10), Vector2(5, 10)])
	e.panel.pick("crater-3")
	e.place_asset("crater-3", Vector2(1.5, -15.5))
	_pick(e, "prop-parked-car-1", "south")
	var a := e.place_asset("prop-parked-car-1", Vector2(-8.9, 0.1))
	_pick(e, "prop-broken-car-1", "west")
	var b := e.place_asset("prop-broken-car-1", Vector2(-8.9, 8.1))
	e.document.make_pair(a, b)
	e.name_field.text = "T-398 street"
	assert_eq(e.save(), OK)
	var path := e.level_path
	var res := _check_level(path)
	assert_eq(res[0], 0, res[1])
	var saved := LevelStore.load_level(path)
	var e2: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e2.levels_dir = e.levels_dir
	e2.open_level(path)
	add_child_autofree(e2)
	assert_eq(e2.level_data.craters, saved.craters)
	assert_eq(e2.level_data.props, saved.props)
	assert_eq(e2.level_data.pairs, saved.pairs)
	assert_eq(e2.document.tile_at(e2.document.cell_at(Vector2(5, 0.5))), "sidewalk-w")
	assert_eq(LevelCraters.decals_of(e2.map.layout).size(), 1)


func test_a_level_saved_before_opens_unchanged() -> void:
	var data := LevelDocument.new_level_data("old")
	data["spawn"] = {"x": 0.0, "y": 0.0, "heading": 270}
	var before := JSON.stringify(data)
	var d := LevelDocument.new(data)
	d.refresh_ground_rows()
	assert_false(data.has("craters"))
	assert_eq(JSON.stringify(d.data), before)


func test_the_games_own_map_has_none_of_the_new_pieces() -> void:
	var gg := LevelGround.game_ground()
	assert_false(gg.is_empty())
	assert_eq(gg.get("extra", []).filter(func(x): return x is Dictionary).size(), 0)
	var layout = JSON.parse_string(FileAccess.get_file_as_string("res://data/level/mvp_map.json"))
	assert_false((layout as Dictionary).has("craters"))


# ---- In a run -----------------------------------------------------------------------------------

func _run_on(e: LevelCreatorEditor, file: String) -> Node2D:
	var path := RunPaths.file(file)
	assert_eq(LevelStore.save_level(path, e.document.file_data("T-398 run")), OK)
	var run: Node2D = RunScene.instantiate()
	run.layout_path = path
	add_child_autofree(run)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	return run


## Drives the car from `start` heading `angle` (radians) for `steps` physics steps, full throttle.
## Returns {hits, min_speed (after getting going), max_height, end}.
func _drive(run: Node2D, start: Vector2, angle: float, steps: int) -> Dictionary:
	var car = run.car
	car.model.set_position(start)
	car.model.rotation = angle
	car.model.set_velocity(Vector2.from_angle(angle) * 8.0)
	car._sync_from_model()
	var hits: Array = []
	car.hit_obstacle.connect(func(c, _i, _n, _s): hits.append(c))
	car.scripted_input = [true, false, 0.0]
	var min_speed := INF
	var max_h := 0.0
	for i in steps:
		car.physics_step()
		if i > 5:
			min_speed = minf(min_speed, (car.model.get_velocity() as Vector2).length())
		max_h = maxf(max_h, absf(float(car.height)))
	return {"hits": hits, "min_speed": min_speed, "max_height": max_h, "end": car.model.get_position()}


func test_the_car_drives_up_over_the_curb_onto_the_sidewalk_and_back_down() -> void:
	var e := _editor()
	e.panel.pick("road")
	e.paint_road([Vector2(1, -40), Vector2(1, 40)])  # road x 0..4
	e.panel.pick("sidewalk")
	for x in [5, 7, 9, 11]:
		e.paint_sidewalk([Vector2(x, -20), Vector2(x, 20)])  # sidewalk x 4..12, curb on its road side
	e.panel.pick("road")
	e.paint_road([Vector2(13, -40), Vector2(13, 40)])  # a second road x 12..16, a curb on the far side too
	assert_eq(e.document.tile_at(e.document.cell_at(Vector2(5, 0.5))), "sidewalk-w")
	assert_eq(e.document.tile_at(e.document.cell_at(Vector2(11, 0.5))), "sidewalk-e")
	var run := _run_on(e, "t398_curb_run.json")
	var r := _drive(run, Vector2(-6, 0.5), 0.0, 120)  # east: road, up the curb, sidewalk, down the curb, road
	assert_eq(r.hits.size(), 0, "no crash at either curb")
	assert_gt((r.end as Vector2).x, 16.0, "it crossed the sidewalk and the second road")
	assert_gt(r.min_speed, 6.0, "no bump to a stop")
	assert_lt(r.max_height, 0.1, "the step is under the 0.1-unit curb rule")
	assert_false(run.car.airborne)


func test_the_car_drives_over_a_crater() -> void:
	var e := _editor()
	e.panel.pick("crater-1")
	e.place_asset("crater-1", Vector2(0.1, 0.1))
	var run := _run_on(e, "t398_crater_run.json")
	var r := _drive(run, Vector2(-10, 1), 0.0, 90)
	assert_eq(r.hits.size(), 0, "no crash")
	assert_gt((r.end as Vector2).x, 4.0, "drove across it")
	assert_gt(r.min_speed, 6.0)


func test_every_car_stops_the_car_and_cuts_the_combo() -> void:
	for id in CARS:
		for rot in ["north", "east"]:
			var e := _editor()
			_pick(e, id, rot)
			assert_false(e.place_asset(id, Vector2(0.1, -39.9)).is_empty())
			var run := _run_on(e, "t398_car_run.json")
			run.state.add_trick("alternate_drift")
			run.state.add_trick("alternate_drift")
			var before: float = run.state.combo
			var f := LevelProps.footprint(id, rot)
			var car = run.car
			car.model.set_position(Vector2(f.x / 2.0, -25))
			car.model.rotation = -PI / 2.0
			car.model.set_velocity(Vector2.ZERO)
			car._sync_from_model()
			var hits: Array = []
			car.hit_obstacle.connect(func(c, _i, _n, _s): hits.append(c))
			car.scripted_input = [true, false, 0.0]
			for i in 400:
				car.physics_step()
				if not hits.is_empty():
					break
			assert_eq(hits.size(), 1, "%s %s: one crash" % [id, rot])
			assert_true(hits[0].has_meta("prop_id"), id)
			assert_gt(car.model.get_position().y, -39.9 + f.y * 0.0, "%s stopped south of it" % id)
			assert_lt(run.state.combo, before, "%s: the combo is cut" % id)
			run.queue_free()
			e.queue_free()
