extends GutTest
## Task T-581 (Level design, Decisions, "Free placement in the level creator"): without Shift every piece
## follows the mouse and goes where it is dropped, its corner on the free step (LevelDocument.FREE_STEP, a
## quarter unit); with Shift held it snaps as before (the 2 x 2 tile grid, the neighbour and ramp snaps). A
## ramp off the grid links to its rooftop when its top end comes within LevelSnapping.FREE_RAMP_REACH of the
## side, and the car drives up it; off-grid buildings and rooftops block the car, the minions' paths go round
## them, and check_level.py passes such a level. The test levels go under the test folder, never into
## game/data/levels/.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const MapScene := preload("res://scenes/level/mvp_map.tscn")
const CarScript := preload("res://scripts/driving/car.gd")
const NavScript := preload("res://scripts/enemies/enemy_navigation.gd")
const ShortPlatformsScript := preload("res://scripts/level/short_platforms.gd")
const STEP := LevelDocument.FREE_STEP
const U := 16.0

var _world: Node2D


func before_each() -> void:
	_world = Node2D.new()
	add_child_autofree(_world)


func _editor() -> LevelCreatorEditor:
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.open_new()
	e.level_data["spawn"] = {"x": 111.0, "y": 111.0, "heading": 270}
	e.levels_dir = RunPaths.file("t581_levels")
	add_child_autofree(e)
	return e


func _pick(e: LevelCreatorEditor, id: String, view: String = "") -> void:
	e.panel.pick(id)
	for i in 4:
		if view == "" or e.pick_view == view:
			return
		e.rotate_pick()


func _r(item: Dictionary) -> Rect2:
	return Rect2(float(item.x), float(item.y), float(item.w), float(item.h))


## The corner the grid gives a cursor at `u` (the corner of the 2 x 2 cell under it).
func _grid(e: LevelCreatorEditor, u: Vector2) -> Vector2:
	return e.document.cell_corner(e.document.cell_at(u))


func _on_step(v: float) -> bool:
	return is_equal_approx(v / STEP, round(v / STEP))


func _run_tool(tool: String, data: Dictionary, file_name: String) -> Array:
	var path := RunPaths.file(file_name)
	assert_eq(LevelStore.save_level(path, data), OK)
	var output: Array = []
	var code := OS.execute("python", [ProjectSettings.globalize_path("res://tools/%s" % tool),
		ProjectSettings.globalize_path(path)], output, true)
	return [code, "\n".join(output).strip_edges()]


# ---- Every kind: free without Shift, snapped with it ---------------------------------------------

## Each kind, at a cursor off the grid: without Shift its corner is the cursor on the step; with Shift
## the grid's corner, as before T-581.
func test_each_kind_goes_where_the_mouse_is_and_snaps_with_shift() -> void:
	var cases := [
		["skyscraper-1", ""], ["short-3", ""], ["building-small", ""], ["building-long", ""],
		["boulder-a", ""], ["prop-barrier", "north"], ["prop-water-tank", "east"], ["crater-1", ""],
		["rooftop-3", ""], ["rooftop-6", ""], ["ramp-0-3", "north"], ["ramp-3-6", "west"], ["alert-sign-head", ""],
	]
	var cursor := Vector2(-90.37, -70.88)
	for c in cases:
		for snap in [false, true]:
			var e := _editor()
			e.snap_held = snap
			_pick(e, c[0], c[1])
			var p := e.place_asset(c[0], cursor)
			assert_false(p.is_empty(), "%s placed (Shift %s)" % [c[0], snap])
			if p.is_empty():
				continue
			var r := e.document.piece_rect(p)
			var want := _grid(e, cursor) if snap else Vector2(-90.25, -71.0)
			assert_almost_eq(r.position, want, Vector2(0.001, 0.001), "%s, Shift %s: its corner" % [c[0], snap])
			for v in [r.position.x, r.position.y, r.end.x, r.end.y]:
				assert_true(_on_step(v), "%s: edge %s on the step" % [c[0], v])


func test_a_free_piece_is_off_the_grid_and_a_snapped_one_on_it() -> void:
	var e := _editor()
	_pick(e, "skyscraper-1")
	var free := e.place_asset("skyscraper-1", Vector2(10.3, -20.6))
	assert_eq(_r(free.item), Rect2(10.25, -20.5, 12, 12), "where it was dropped, a quarter unit step")
	e.snap_held = true
	var snapped := e.place_asset("skyscraper-1", Vector2(40.3, -20.6))
	assert_eq(_r(snapped.item), Rect2(40, -22, 12, 12), "the 2 x 2 grid, as before")


func test_neighbour_snaps_only_with_shift() -> void:
	var e := _editor()
	_pick(e, "skyscraper-1")
	e.snap_held = true
	e.place_asset("skyscraper-1", Vector2(40, 40))  # 40..52
	# 2.5 units east of it: Shift puts it flush against it; free leaves the gap.
	var free := e.place_asset("skyscraper-1", Vector2(54.5, 40))
	assert_eq(_r(free.item).position, Vector2(52, 40), "with Shift: flush")
	e.document.delete({"kind": "building", "item": free.item})
	e.snap_held = false
	var loose := e.place_asset("skyscraper-1", Vector2(54.5, 40))
	assert_eq(_r(loose.item).position, Vector2(54.5, 40), "without Shift: where it was dropped")


func test_a_free_piece_at_the_map_edge_is_moved_in() -> void:
	var e := _editor()
	_pick(e, "prop-barrier", "north")
	var p := e.place_asset("prop-barrier", Vector2(118.6, 119.4))
	assert_false(p.is_empty())
	assert_eq(_r(p.item), Rect2(116, 119, 4, 1), "the whole prop on the map")
	assert_true(e.place_asset("prop-barrier", Vector2(121, 0)).is_empty(), "a cursor off the map places nothing")


func test_a_free_drag_sizes_a_rooftop_to_the_step_and_shift_to_cells() -> void:
	var e := _editor()
	_pick(e, "rooftop-3")
	e.set_platform_size("any")
	e.begin_size_drag(Vector2(10.3, 20.1))
	var p := e.end_size_drag(Vector2(27.6, 29.9))
	assert_eq(_r(p.item), Rect2(10.25, 20, 17.25, 10), "the dragged rectangle, on the step")
	e.snap_held = true
	e.begin_size_drag(Vector2(-60.3, -40.1))
	var q := e.end_size_drag(Vector2(-45.2, -33.0))
	assert_eq(_r(q.item), Rect2(-62, -42, 18, 10), "with Shift: the cells dragged across, as before")
	# A click (a drag shorter than half a cell) is the default size at the cursor.
	e.snap_held = false
	e.begin_size_drag(Vector2(60.3, 60.4))
	var c := e.end_size_drag(Vector2(60.6, 60.7))
	assert_eq(_r(c.item), Rect2(60.25, 60.5, 16, 16), "a click: M at the cursor")


func test_a_free_ramp_drag_sets_its_width_to_the_step() -> void:
	var e := _editor()
	_pick(e, "ramp-0-3", "north")
	e.begin_size_drag(Vector2(30.1, 30.1))
	var p := e.end_size_drag(Vector2(37.4, 35.0))
	assert_eq(_r(p.item), Rect2(30, 30, 7.5, 12), "its width along the side dragged, its length fixed")


func test_the_size_readout_shows_quarter_units() -> void:
	var e := _editor()
	_pick(e, "rooftop-3")
	e.set_platform_size("any")
	e.begin_size_drag(Vector2(0, 0))
	e.hover_units = Vector2(12.25, 7.5)
	e.hover_cell = e.document.cell_at(e.hover_units)
	e._update_size_label()
	assert_eq(e.size_label.text, CreatorTexts.get_text("size_readout").format({"w": "12.25", "d": "7.5"}))
	e.end_size_drag(Vector2(12.25, 7.5))


func test_a_rail_lays_on_quarter_units_free_and_half_units_with_shift() -> void:
	var e := _editor()
	e.panel.pick("rail")
	var free: Dictionary = e.lay_rail(Vector2(1.13, 2.37), Vector2(9.74, 2.12)).item
	assert_eq([free.x1, free.y1, free.x2, free.y2], [1.25, 2.25, 9.75, 2.0])
	e.snap_held = true
	var snapped: Dictionary = e.lay_rail(Vector2(1.13, 12.37), Vector2(9.74, 12.12)).item
	assert_eq([snapped.x1, snapped.y1, snapped.x2, snapped.y2], [1.0, 12.5, 9.5, 12.0])
	# Moving a placed rail follows the same rule.
	e.selected = {"kind": "rail", "item": snapped}
	e.snap_held = false
	assert_true(e.move_rail(Vector2(0.3, 0.3)))
	assert_eq([snapped.x1, snapped.y1], [1.25, 12.75], "moved by a quarter unit")


func test_the_spawn_point_moves_freely_and_onto_its_cell_with_shift() -> void:
	var e := _editor()
	assert_true(e.move_spawn(Vector2(30.4, -20.9)))
	assert_eq(LevelSpawn.position_of(e.level_data), Vector2(30.5, -21.0), "where it was dropped")
	e.snap_held = true
	assert_true(e.move_spawn(Vector2(30.4, -20.9)))
	assert_eq(LevelSpawn.position_of(e.level_data), Vector2(31, -21), "its cell's middle, as before")


func test_shift_from_the_keyboard_and_the_mouse_sets_the_snap() -> void:
	var e := _editor()
	assert_false(e.snap_held, "free by default")
	var k := InputEventKey.new()
	k.keycode = KEY_SHIFT
	k.pressed = true
	e._unhandled_key_input(k)
	assert_true(e.snap_held, "Shift down: snap")
	k.pressed = false
	e._unhandled_key_input(k)
	assert_false(e.snap_held, "Shift up: free")
	# A click with Shift held places on the grid, one without where the mouse is.
	_pick(e, "boulder-a")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.shift_pressed = true
	click.position = e.units_to_screen(Vector2(20.6, 20.6))
	e._on_map_input(click)
	var b: Dictionary = e.level_data.pattern_copies[0].boulders[0]
	assert_almost_eq(Vector2(b.x, b.y), Vector2(21.5, 21.5), Vector2(0.001, 0.001), "Shift: on the tile")
	click.shift_pressed = false
	click.position = e.units_to_screen(Vector2(40.6, 20.6))
	e._on_map_input(click)
	var f: Dictionary = e.level_data.pattern_copies[1].boulders[0]
	assert_almost_eq(Vector2(f.x, f.y), Vector2(42.0, 22.0), Vector2(0.001, 0.001), "free: its corner at 40.5, 20.5")


func test_the_preview_follows_the_mouse_without_shift() -> void:
	var e := _editor()
	_pick(e, "skyscraper-1")
	e.hover_units = Vector2(10.3, -20.6)
	e.hover_cell = e.document.cell_at(e.hover_units)
	assert_eq(e.current_placement().rect.position, Vector2(10.25, -20.5))
	e.snap_held = true
	assert_eq(e.current_placement().rect.position, Vector2(10, -22))


# ---- Ramps off the grid -----------------------------------------------------------------------

## A rooftop at 3 off the grid (x 20.25..36.25, y 30.75..46.75) and a ramp 0 to 3 climbing north to its
## south side (y 46.75), its top end `gap` units short of it.
func _roof_and_ramp(e: LevelCreatorEditor, gap: float) -> Dictionary:
	_pick(e, "rooftop-3")
	var roof := e.place_asset("rooftop-3", Vector2(20.25, 30.75))
	assert_eq(_r(roof.item), Rect2(20.25, 30.75, 16, 16))
	_pick(e, "ramp-0-3", "north")
	var ramp := e.place_asset("ramp-0-3", Vector2(23.5, 46.75 + gap))
	return {"roof": roof.item, "ramp": ramp.item}


func test_a_free_ramp_near_its_rooftops_side_goes_onto_it_and_links() -> void:
	for gap in [0.0, 0.5, -0.75, LevelSnapping.FREE_RAMP_REACH]:
		var e := _editor()
		var p := _roof_and_ramp(e, gap)
		assert_eq(str(p.ramp.platform), str(p.roof.id), "gap %s: it links to the rooftop" % gap)
		assert_almost_eq(float(p.ramp.y), 46.75, 0.001, "gap %s: its top end on the side" % gap)
		assert_almost_eq(float(p.ramp.x), 23.5, 0.001, "gap %s: along the side where it was dropped" % gap)
		var res := _run_tool("check_level.py", e.document.file_data("t581"), "t581_ramp_%s.json" % gap)
		assert_eq(res, [0, "OK"], "gap %s: check_level.py" % gap)


func test_a_free_ramp_farther_away_stays_where_it_was_dropped() -> void:
	var e := _editor()
	var p := _roof_and_ramp(e, LevelSnapping.FREE_RAMP_REACH + 0.5)
	assert_eq(str(p.ramp.platform), "", "too far: no link")
	assert_almost_eq(float(p.ramp.y), 46.75 + LevelSnapping.FREE_RAMP_REACH + 0.5, 0.001)
	var res := _run_tool("check_level.py", e.document.file_data("t581"), "t581_ramp_far.json")
	assert_eq(res[0], 1, "check_level.py refuses a ramp that leads nowhere: " + str(res[1]))


func _car(ground, start: Vector2, rotation: float) -> CharacterBody2D:
	var car: CharacterBody2D = CarScript.new()
	car.model.set_position(start)
	car.model.rotation = rotation
	_world.add_child(car)
	car.set_physics_process(false)
	car.use_keyboard = false
	car.detect_tricks = false
	car.scripted_input = [true, false, 0.0]
	car.ground = ground
	return car


func test_the_car_drives_up_an_off_grid_ramp_onto_its_rooftop() -> void:
	var e := _editor()
	var p := _roof_and_ramp(e, 0.5)
	var g := GroundHeight.new()
	assert_true(g.load_data(e.level_data), g.error)
	var lane: float = float(p.ramp.x) + float(p.ramp.w) / 2.0
	var car := _car(g, Vector2(lane, 70.0), -PI / 2.0)
	var on_ramp := 0
	for i in 600:
		car.physics_step()
		if g.is_ramp(car.model.get_position()):
			on_ramp += 1
		if car.model.get_position().y < 38.0 and not car.airborne:
			break
	assert_gt(on_ramp, 5, "it drove up the ramp")
	assert_lt(car.model.get_position().y, 38.0, "onto the rooftop (%s)" % car.model.get_position())
	assert_almost_eq(float(car.height), 3.0, 1e-4, "at the rooftop's height")


# ---- The game: collision, the minions' paths, the checks -----------------------------------------

## A level with a skyscraper (x 10.25..22.25, y -5.75..6.25) and a rooftop at 3 without a ramp
## (x -40.75..-24.75, y -8.25..7.75), both off the grid, saved and checked.
func _off_grid_level() -> LevelCreatorEditor:
	var e := _editor()
	_pick(e, "skyscraper-1")
	assert_eq(_r(e.place_asset("skyscraper-1", Vector2(10.25, -5.75)).item), Rect2(10.25, -5.75, 12, 12))
	_pick(e, "rooftop-3")
	assert_eq(_r(e.place_asset("rooftop-3", Vector2(-40.75, -8.25)).item), Rect2(-40.75, -8.25, 16, 16))
	return e


func test_an_off_grid_level_passes_both_checks() -> void:
	var e := _off_grid_level()
	var data := e.document.file_data("t581 off grid")
	assert_eq(_run_tool("check_level.py", data, "t581_off_grid.json"), [0, "OK"])
	assert_eq(_run_tool("check_height_data.py", data, "t581_off_grid_h.json"), [0, "OK"])
	# ground_rows marks every unit the building covers part of.
	var rows: Array = data.ground_rows
	assert_eq(str(rows[int(-5.75 + 120)])[int(10.25 + 120)], "B", "the unit it starts in")
	assert_eq(str(rows[int(6.25 + 120)])[int(22.25 + 120)], "B", "the unit it ends in")
	assert_eq(str(rows[int(6.25 + 120) + 1])[int(22.25 + 120)], "G", "past it")


func test_an_off_grid_building_blocks_the_car() -> void:
	var e := _off_grid_level()
	var map = MapScene.instantiate()
	map.layout = e.document.map_layout()
	_world.add_child(map)
	await wait_physics_frames(2)
	var car := _car(null, Vector2(0, 0), 0.0)
	var furthest := -INF
	for i in 240:
		car.physics_step()
		furthest = maxf(furthest, car.model.get_position().x)
	assert_gt(furthest, 7.0, "it reached the building")
	assert_lt(furthest, 10.25, "and never got into it (its west wall at 10.25): %s" % furthest)


func test_an_off_grid_rooftop_without_a_ramp_stops_the_car() -> void:
	var e := _off_grid_level()
	var g := GroundHeight.new()
	assert_true(g.load_data(e.level_data), g.error)
	var car := _car(g, Vector2(-10, 0), PI)
	var furthest := INF
	for i in 240:
		car.physics_step()
		furthest = minf(furthest, car.model.get_position().x)
	assert_gt(furthest, -24.75, "stopped at the rooftop's east side (-24.75): %s" % furthest)
	assert_almost_eq(float(car.height), 0.0, 1e-4, "still on the street")


func _crosses(path: PackedVector2Array, rect: Rect2) -> bool:
	for i in path.size() - 1:
		var a := path[i]
		var b := path[i + 1]
		var n := maxi(1, ceili(a.distance_to(b) * 8.0))
		for k in n + 1:
			if rect.has_point(a.lerp(b, float(k) / n)):
				return true
	return false


func test_minions_walk_round_off_grid_buildings_and_rooftops() -> void:
	var e := _off_grid_level()
	var g := GroundHeight.new()
	assert_true(g.load_data(e.level_data), g.error)
	var blocks: Array = []
	for w in ShortPlatformsScript.wall_rects(e.level_data):
		blocks.append(w.rect)
	var nav = NavScript.new()
	nav.build(e.document.map_rect(), blocks, g)
	var sky := Rect2(10.25, -5.75, 12, 12)
	var path: PackedVector2Array = nav.find_path(Vector2(5, 0), Vector2(28, 0))
	assert_gt(path.size(), 1, "a path past the skyscraper")
	assert_false(_crosses(path, sky), "round the skyscraper, not through it")
	for pt in path:
		assert_false(sky.grow(0.4).has_point(pt), "every point off its walls: %s" % pt)
	var roof := Rect2(-40.75, -8.25, 16, 16)
	var round_roof: PackedVector2Array = nav.find_path(Vector2(-20, 0), Vector2(-46, 0))
	assert_gt(round_roof.size(), 1, "a path past the rooftop")
	assert_false(_crosses(round_roof, roof.grow(-0.1)), "round the rooftop it can't climb")


func test_minions_path_up_an_off_grid_ramp_onto_its_rooftop() -> void:
	var e := _editor()
	var p := _roof_and_ramp(e, 0.5)
	var g := GroundHeight.new()
	assert_true(g.load_data(e.level_data), g.error)
	var nav = NavScript.new()
	nav.build(e.document.map_rect(), [], g)
	var top := Vector2(28.25, 36.0)
	assert_almost_eq(g.height_at(top), 3.0, 0.001)
	var path: PackedVector2Array = nav.find_path(Vector2(50, 70), top)
	assert_gt(path.size(), 1, "a path onto the rooftop")
	assert_true(path.has(nav.ramp_end(0, false)) and path.has(nav.ramp_end(0, true)), "up the ramp")
	assert_almost_eq(g.height_at(path[path.size() - 1]), 3.0, 0.01, "ends on the rooftop")


# ---- Levels saved before ------------------------------------------------------------------------

func test_a_level_saved_on_the_grid_opens_and_saves_unchanged() -> void:
	var src := "res://data/level/kaiju_city_map.json"
	var before: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(src))
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.levels_dir = RunPaths.file("t581_levels_old")
	e.open_level(src)
	add_child_autofree(e)
	var after := e.document.file_data(str(before.get("name", "")))
	for key in ["buildings", "platforms", "ramps", "props", "rails", "pattern_copies", "ground_rows"]:
		assert_eq(after.get(key), before.get(key), "%s unchanged" % key)


## The board's own levels (the main checkout's levels folder, untracked): read only, never written. Each
## opens in the creator with its pieces as saved (all on the grid) and keeps them when saved again (only
## in memory here). Skipped when the folder is not on this computer.
const BOARD_LEVELS := "C:/solid-carbide-game/game/data/levels"


func test_the_boards_levels_still_open_unchanged() -> void:
	if not DirAccess.dir_exists_absolute(BOARD_LEVELS):
		pass_test("the board's levels are not on this computer")
		return
	var n := 0
	for f in DirAccess.get_files_at(BOARD_LEVELS):
		if not f.ends_with(".json"):
			continue
		var path := BOARD_LEVELS.path_join(f)
		var before = JSON.parse_string(FileAccess.get_file_as_string(path))
		assert_true(before is Dictionary, "%s reads" % f)
		if not (before is Dictionary):
			continue
		var doc := LevelDocument.new(LevelStore.load_level(path))
		var after := doc.file_data(str(before.get("name", "")))
		for key in ["buildings", "platforms", "ramps", "props", "rails", "pattern_copies"]:
			assert_eq(after.get(key), before.get(key), "%s: %s unchanged" % [f, key])
		n += 1
	assert_gt(n, 0, "the board's levels were read")
