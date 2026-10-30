extends GutTest
## Task T-405 (Level design, Decisions, "Short buildings become platforms"): the low-rise, small and
## long buildings are platforms at height 3 with their own art; side by side (or beside a 3-high
## rooftop) they join with no wall, parapet or bump; everything works at its height (the altitude
## audit): nothing below a platform stops the car on it, a jump off one lands on the ground or a
## lower platform, a skyscraper blocks at any height; saved levels and the game's own map load them.

const RunScene := preload("res://scenes/run/run.tscn")
const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const Level := preload("res://tests/fixtures/t405_platforms_level.gd")
const ShortPlatforms := preload("res://scripts/level/short_platforms.gd")
const BuildingTowers := preload("res://scripts/level/building_towers.gd")
const NavScript := preload("res://scripts/enemies/enemy_navigation.gd")
const MvpMapScript := preload("res://scripts/level/mvp_map.gd")

const SHORT_0 := "building@-12,-12"
const SHORT_1 := "building@0,-12"
const SMALL_A := "building@-12,0"
const SMALL_B := "building@-6,0"
const LONG := "building@0,0"


func _run(data: Dictionary, file: String = "t405_level.json") -> Node2D:
	var path := RunPaths.file(file)
	assert_eq(LevelStore.save_level(path, data), OK)
	var run: Node2D = RunScene.instantiate()
	run.layout_path = path
	add_child_autofree(run)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	return run


func _editor(data: Dictionary) -> LevelCreatorEditor:
	var path := RunPaths.file("t405_editor/t405.json")
	assert_eq(LevelStore.save_level(path, data), OK)
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.levels_dir = RunPaths.file("t405_editor")
	add_child_autofree(e)
	e.open_level(path)
	return e


func _area(map: Node2D, id: String) -> Node2D:
	for a in map.elevation.areas:
		if str(a.block.id) == id:
			return a
	return null


func _face_names(area: Node2D) -> Array:
	return area.building_faces().map(func(f): return str(f.name))


func _place_car(run: Node2D, at: Vector2, rotation: float = 0.0) -> void:
	var car = run.car
	car.model.set_position(at)
	car.model.rotation = rotation
	car.model.set_velocity(Vector2.ZERO)
	car.height_model.reset(at)
	car._sync_from_model()


## Drives east along y with W held for up to `steps` physics steps (or until `stop` says so), keeping
## the heading. Returns one record per step: {x, height, airborne}; hits go into `hits`.
func _drive_east(run: Node2D, steps: int, hits: Array, stop: Callable = Callable()) -> Array:
	var car = run.car
	car.hit_obstacle.connect(func(c, _i, _n, _s): hits.append({"collider": c, "x": car.model.x, "height": car.height}))
	car.scripted_input = [true, false, 0.0]
	var log: Array = []
	for i in steps:
		car.model.rotation = 0.0
		car.physics_step()
		log.append({"x": car.model.x, "height": car.height, "airborne": car.airborne})
		if stop.is_valid() and stop.call(car):
			break
	return log


# ---- The platforms ----------------------------------------------------------------------------

func test_the_short_buildings_are_platforms_at_3_and_only_skyscrapers_are_walls() -> void:
	var data := Level.file_data()
	var run := _run(data)
	var g = run.elevation.ground_height
	for p in [Vector2(-6, -6), Vector2(6, -6), Vector2(-9, 3), Vector2(-3, 3), Vector2(6, 3)]:
		assert_eq(g.height_at(p), 3.0, "a short building at %s is a platform at 3" % p)
	assert_eq(g.height_at(Vector2(-30, 20)), 0.0, "the street")
	for id in [SHORT_0, SHORT_1, SMALL_A, SMALL_B, LONG]:
		var a := _area(run.map, id)
		assert_not_null(a, id + " is a raised area")
		assert_true(a.is_building(), id + " is drawn from its own art")
		assert_eq(float(a.block.height), ShortPlatforms.HEIGHT)
	# Walls: the skyscraper (and the map's edges), never a short building.
	var wall_names: Array = run.map.walls.get_children().map(func(c): return str(c.name))
	var sky_index := -1
	for i in data.buildings.size():
		if str(data.buildings[i].asset) == "skyscraper-1":
			sky_index = i
	assert_true(wall_names.has("Building%02d" % (sky_index + 1)), "the skyscraper is a wall")
	assert_eq(wall_names.filter(func(n: String): return n.begins_with("Building")).size(), 1, "only the skyscraper")
	# The map keeps one node per building, in order; the short ones never fade or sort.
	assert_eq(run.map.buildings.size(), data.buildings.size())
	for b in run.map.fade_items():
		assert_false(b.platform)


func test_the_editor_draws_them_as_platforms_and_the_panel_shows_their_platform_art() -> void:
	var e := _editor(Level.file_data())
	assert_true(_area(e.map, SHORT_0).is_building())
	assert_eq(e.map.slots.size(), 1, "one slot: the skyscraper")
	var t := LevelDocument.texture_of("short-0", "iso", false)
	assert_string_starts_with(str(t.texture), "res://art/buildings/platforms/")
	assert_true(t.has("anchor_art_px"), "the preview stands it on its footprint")


# ---- Driving on them ---------------------------------------------------------------------------

func test_the_car_climbs_the_ramp_crosses_the_joins_without_a_bump_and_falls_off_the_far_edge() -> void:
	var run := _run(Level.file_data())
	_place_car(run, Level.SPAWN)
	var hits: Array = []
	var log := _drive_east(run, 900, hits, func(car) -> bool: return car.model.x > 30.0 and not car.airborne)
	# Off the ramp's top it jumps (the ramp launches it) and lands on the low-rise before x 2.
	var landed := log.any(func(r): return r.x > -12.0 and r.x < 2.0 and absf(float(r.height) - 3.0) < 0.001 and not r.airborne)
	assert_true(landed, "it landed on the low-rise")
	var on_top := log.filter(func(r): return r.x > 2.0 and r.x < 23.5)
	assert_gt(on_top.size(), 10, "it drove across the platforms")
	for r in on_top:
		assert_almost_eq(float(r.height), 3.0, 0.001, "at 3 all the way across, x %.2f" % r.x)
		assert_false(r.airborne, "no bump at the joins (x 0, x 12), x %.2f" % r.x)
	for h in hits:
		assert_gt(float(h.x), 23.5, "nothing stopped it on the platforms (hit at x %.2f)" % h.x)
	var flying := log.filter(func(r): return r.airborne and r.x > 2.0)
	assert_false(flying.is_empty(), "it left the rooftop's east edge in the air")
	assert_gt(float(flying[0].x), 23.9, "at the edge")
	assert_eq(run.car.height, 0.0, "and landed on the street")
	assert_gt(run.car.model.x, 27.0, "past the barrier")
	for h in hits:
		assert_false(h.collider is Node and (h.collider as Node).has_meta("prop_id"), "it flew over the barrier")


func test_a_jump_off_a_platform_lands_on_a_lower_platform() -> void:
	# A 6 rooftop with a low-rise (3) just east of it: off the 6's east edge, onto the low-rise.
	var doc := LevelDocument.new(LevelDocument.new_level_data("T-405 drop"))
	doc.place("rooftop-6", Vector2(-24, -30), "", false, Vector2(12, 12))
	doc.place("short-0", Vector2(-10, -30))
	doc.data["spawn"] = {"x": 101.0, "y": 101.0, "heading": 0}
	var run := _run(doc.file_data("T-405 drop"), "t405_drop.json")
	_place_car(run, Vector2(-20, -24))
	assert_eq(run.car.height, 6.0)
	var hits: Array = []
	var log := _drive_east(run, 300, hits, func(car) -> bool: return car.model.x > -6.0 and not car.airborne)
	assert_true(log.any(func(r): return r.airborne), "it jumped off the 6")
	assert_eq(run.car.height, 3.0, "and landed on the low-rise")
	assert_gt(run.car.model.x, -10.0)
	assert_eq(hits.size(), 0, "nothing in the way")


func test_a_skyscraper_blocks_the_car_at_any_height() -> void:
	var run := _run(Level.file_data())
	for h in [0.0, 3.0, 12.0, 40.0]:
		_place_car(run, Vector2(35, -6))
		run.car.height_model.airborne = h > 0.0
		run.car.height_model.height = h
		run.car.height_model.vertical_speed = 30.0 if h > 0.0 else 0.0  # stays high for the few steps
		# In the air W does nothing (T-219): it flies at cruise speed towards the skyscraper.
		run.car.model.set_velocity(Vector2(run.car.tuning.forward_speed, 0.0))
		var hits: Array = []
		var car = run.car
		var on_hit := func(c, _i, _n, _s): hits.append(c)
		car.hit_obstacle.connect(on_hit)
		car.scripted_input = [true, false, 0.0]
		for i in 120:
			car.model.rotation = 0.0
			car.physics_step()
			if not hits.is_empty():
				break
		car.hit_obstacle.disconnect(on_hit)
		assert_eq(hits.size(), 1, "the skyscraper stops it at height %s" % h)
		if not hits.is_empty():
			assert_eq(hits[0], run.map.walls)
		assert_lt(car.model.x, 38.0, "west of the skyscraper at height %s" % h)


# ---- The altitude audit: obstacles at their heights ---------------------------------------------

## A level as saved before T-405, with the board's cases: a low-rise (x 0..12, y -30..-18) half under
## a rooftop at 3 (x 8..24: before, the low-rise's invisible body stopped the car on the rooftop), a
## barrier inside the low-rise's footprint (Kaiju City's prop-19; x 6..7, y -30..-26), a boulder on
## the street just east of the rooftop that reaches 0.5 into it ((25, -24), 3 across), and a 0-to-3
## ramp up the low-rise's west side (x -12..0, y -28..-20), saved unlinked.
func _old_level() -> Dictionary:
	var doc := LevelDocument.new(LevelDocument.new_level_data("T-405 old"))
	doc.data["buildings"] = [{"x": 0, "y": -30, "w": 12, "h": 12, "asset": "short-0", "look": 0}]
	doc.data["platforms"] = [{"id": "roof-1", "x": 8, "y": -30, "w": 16, "h": 12, "height": 3}]
	doc.data["props"] = [{"id": "prop-1", "asset": "prop-barrier", "rotation": "east", "x": 6, "y": -30, "w": 1, "h": 4}]
	doc.data["pattern_copies"] = [{"id": "boulder-1", "boulders": [{"x": 25.0, "y": -24.0, "diameter": 3.0, "variant": ""}]}]
	doc.data["ramps"] = [{"id": "ramp-1", "platform": "", "side": "west", "x": -12, "y": -28, "w": 12, "h": 8,
		"bottom_height": 0, "top_height": 3}]
	doc._relink()
	doc.data["spawn"] = {"x": 101.0, "y": 101.0, "heading": 0}
	return doc.file_data("T-405 old")


func test_the_ramp_links_to_the_short_building() -> void:
	var data := _old_level()
	assert_eq(str(data.ramps[0].platform), "building@0,-30", "the ramp climbs to the low-rise")


func test_nothing_below_a_platform_stops_the_car_on_top_of_it() -> void:
	var run := _run(_old_level(), "t405_old.json")
	_place_car(run, Vector2(-14, -24))
	var hits: Array = []
	var log := _drive_east(run, 600, hits, func(car) -> bool: return car.model.x > 23.9)
	assert_gt(run.car.model.x, 23.9, "across the low-rise and the rooftop over it, to the rooftop's far edge")
	assert_eq(hits.size(), 0, "nothing stopped it: not the low-rise under the rooftop, not the boulder's edge")
	var level := log.filter(func(r): return r.x > 13.0 and r.x < 23.9)
	assert_gt(level.size(), 5)
	for r in level:
		assert_almost_eq(float(r.height), 3.0, 0.001, "on the rooftop at 3, x %.2f" % r.x)
		assert_false(r.airborne)
	assert_true(run.map.is_passing(run.map.boulder_bodies[0]), "the street boulder under the rooftop's edge is passed")
	# The barrier inside the low-rise's footprint now stands on its roof (T-393's rule: the height under its centre).
	var barrier: StaticBody2D = run.map.prop_bodies[0]
	assert_eq(barrier.get_meta("base_units"), 3.0, "the barrier stands on the low-rise now")
	assert_eq(run.map.prop_sprites[0].ground_units, 3.0, "and is drawn there")


func test_a_prop_on_the_street_stops_the_car_on_the_street_but_not_one_flying_over_it() -> void:
	var doc := LevelDocument.new(LevelDocument.new_level_data("T-405 prop"))
	doc.place("prop-barrier", Vector2(10, -8), "east")  # 1 x 4 at x 10..11, y -8..-4
	doc.data["spawn"] = {"x": 101.0, "y": 101.0, "heading": 0}
	var run := _run(doc.file_data("T-405 prop"), "t405_prop.json")
	_place_car(run, Vector2(0, -6))
	var hits: Array = []
	_drive_east(run, 200, hits, func(car) -> bool: return not hits.is_empty())
	assert_eq(hits.size(), 1, "on the street it crashes into the barrier")
	assert_lt(run.car.model.x, 10.5)
	# The same barrier with the car in the air above it (2 units up, the barrier is 1.2 high).
	_place_car(run, Vector2(6, -6))
	run.car.height_model.airborne = true
	run.car.height_model.height = 2.0
	run.car.height_model.vertical_speed = 6.0
	run.car.model.set_velocity(Vector2(run.car.tuning.forward_speed, 0.0))  # W does nothing in the air
	var hits2: Array = []
	_drive_east(run, 60, hits2, func(car) -> bool: return car.model.x > 13.0)
	assert_eq(hits2.size(), 0, "in the air it flies over it")
	assert_gt(run.car.model.x, 11.0)


func test_every_collider_works_at_its_height() -> void:
	# The audit's list, checked on the T-405 level: what blocks the car, from where to where.
	var run := _run(Level.file_data())
	var map: Node2D = run.map
	for b in map.prop_bodies:
		var hr: Array = map.obstacle_heights(b)
		var ground: float = run.elevation.ground_height.height_at(LevelProps.rect_of(
			map.layout.props.filter(func(p): return p.id == b.get_meta("prop_id"))[0]).get_center())
		assert_eq(float(hr[0]), ground, "a prop stands at the ground under it")
		assert_gt(float(hr[1]), float(hr[0]))
	var ac: StaticBody2D = map.prop_bodies.filter(func(b): return str(b.get_meta("prop_id")) == "prop-1")[0]
	assert_eq(float(map.obstacle_heights(ac)[0]), 3.0, "the AC unit stands on the low-rise")
	assert_eq(map.obstacle_heights(map.walls), [-INF, INF], "the walls block at any height")
	map.update_car_obstacles(run.car, 3.0)
	var barrier: StaticBody2D = map.prop_bodies.filter(func(b): return str(b.get_meta("prop_id")) == "prop-2")[0]
	assert_true(map.is_passing(barrier), "a car at 3 passes over a street barrier")
	assert_false(map.is_passing(ac), "but not the AC unit on the roof it drives on")
	map.update_car_obstacles(run.car, 0.0)
	assert_false(map.is_passing(barrier), "on the street the barrier blocks again")
	assert_true(map.is_passing(ac), "and the AC unit up on the roof is out of reach")


# ---- Joins --------------------------------------------------------------------------------------

func test_side_by_side_they_join_with_no_wall_or_parapet_between() -> void:
	var run := _run(Level.file_data())
	var s0 := _face_names(_area(run.map, SHORT_0))
	var s1 := _face_names(_area(run.map, SHORT_1))
	var sa := _face_names(_area(run.map, SMALL_A))
	var lg := _face_names(_area(run.map, LONG))
	# short-0 | short-1 (x = 0), short-0 over the two small ones (y = 0), short-1 over the long one.
	assert_false(s0.has("wall_east") or s0.has("parapet_east"), "short-0's east side joins short-1")
	assert_false(s0.has("wall_south") or s0.has("parapet_south"), "short-0's south side joins the small ones")
	assert_false(s1.has("parapet_west"), "short-1's west side joins short-0")
	assert_false(s1.has("wall_south") or s1.has("parapet_south"), "short-1 joins the long building")
	assert_false(s1.has("wall_east") or s1.has("parapet_east"), "short-1 joins the rooftop")
	assert_false(lg.has("wall_east") or lg.has("parapet_east"), "the long building joins the rooftop")
	# The outer sides keep their walls and parapets.
	assert_true(sa.has("wall_south") and sa.has("parapet_south") and sa.has("parapet_west"), "the small one's outside")
	assert_true(s0.has("parapet_north") and s0.has("corner_nw"), "short-0's back corner")
	assert_true(lg.has("wall_south"), "the long building's front wall")
	# The ramp breaks short-0's west parapet where it meets it (y -10..-2), not its wall.
	var gaps: Array = _area(run.map, SHORT_0).band_gaps.west
	assert_true(gaps.any(func(g): return float(g[0]) <= -10.0 and float(g[1]) >= -2.0), "no parapet at the ramp")
	# The rooftop beside them draws no parapet along the join (its west edge, y -12..6).
	var roof: Node2D = null
	for a in run.map.elevation.areas:
		if str(a.block.id).begins_with("roof-"):
			roof = a
	var rg: Array = roof.edge_gaps.west
	assert_true(rg.any(func(g): return float(g[0]) <= -12.0 and float(g[1]) >= 0.0), "along short-1")
	assert_true(rg.any(func(g): return float(g[0]) <= 0.0 and float(g[1]) >= 6.0), "along the long building")


func test_a_short_building_alone_draws_every_wall_and_parapet() -> void:
	var doc := LevelDocument.new(LevelDocument.new_level_data("T-405 alone"))
	doc.place("building-small", Vector2(0, 0))
	doc.data["spawn"] = {"x": 101.0, "y": 101.0, "heading": 0}
	var run := _run(doc.file_data("T-405 alone"), "t405_alone.json")
	var names := _face_names(_area(run.map, "building@0,0"))
	for n in ["roof", "parapet_north", "parapet_south", "parapet_west", "parapet_east", "corner_nw", "corner_ne",
			"corner_sw", "corner_se", "wall_south", "wall_east"]:
		assert_true(names.has(n), n)


# ---- Enemies, props, spawn, editor rules --------------------------------------------------------

func test_enemies_walk_up_the_ramp_onto_the_platforms() -> void:
	var run := _run(Level.file_data())
	var nav = NavScript.build_for_map(run.map)
	var top := Vector2(5, -5)
	assert_eq(nav.heights[nav.cell_at(top)], 3.0, "the low-rise's cells are at 3")
	assert_eq(nav.open[nav.cell_at(top)], 1, "and open (not a building)")
	var path: PackedVector2Array = nav.find_path(Vector2(-40, 20), top)
	assert_gt(path.size(), 1, "a path from the street onto the joined platforms")
	# It goes up by the ramp: the path crosses the low-rise's west side (x -12) where the ramp meets it.
	var by_ramp := false
	for i in range(1, path.size()):
		var a: Vector2 = path[i - 1]
		var b: Vector2 = path[i]
		if (a.x - (-12.0)) * (b.x - (-12.0)) <= 0.0 and a.x != b.x:
			var y := lerpf(a.y, b.y, (-12.0 - a.x) / (b.x - a.x))
			by_ramp = by_ramp or (y >= -10.0 and y <= -2.0)
	assert_true(by_ramp, "by the ramp: %s" % [path])


func test_props_stand_on_them_at_3_and_the_spawn_may_too() -> void:
	var e := _editor(Level.file_data())
	e.panel.pick("prop-crates")
	var p := e.place_asset("prop-crates", Vector2(-7.9, -7.9))  # 2 x 2 on short-0
	e.panel.pick("")
	assert_false(p.is_empty(), "a prop goes on a low-rise like on a rooftop")
	var sp = e.map.prop_sprites.filter(func(s): return s.prop_id == str(p.item.id))[0]
	assert_eq(sp.ground_units, 3.0, "at its height")
	e.panel.pick("prop-barrier")  # 4 x 1, x -14..-10 at y 2: across the small building's west edge
	assert_true(e.place_asset("prop-barrier", Vector2(-13.9, 2.1)).is_empty(), "not across its edge")
	e.panel.pick("")
	assert_eq(LevelSpawn.problem(e.level_data, Vector2(-5, -5)), "", "the car may start on a low-rise")
	assert_eq(LevelSpawn.problem(e.level_data, Vector2(43, -5)), LevelSpawn.BLOCKED, "not in a skyscraper")


func test_the_game_map_makes_platforms_of_its_blocks_short_slots() -> void:
	var data := MvpMapScript.load_layout("res://data/level/elevation_sample_map.json")
	var ids: Array = ShortPlatforms.platforms_of(data).map(func(p): return str(p.id))
	# The same list as game/tools/test_short_platforms.py (the Python mirror).
	assert_eq(ids, ["block@12,-96/0,1", "block@12,-96/1,1", "block@-96,-42/1,1", "block@-96,12/1,1", "block@66,12/1,1"])
	assert_eq(BuildingTowers.hash_of(12, -96), 4282437368)
	# A building with no asset that is not a 30 x 30 block stays a building.
	assert_eq(ShortPlatforms.platforms_of({"platforms": [], "buildings": [{"x": -8, "y": -8, "w": 4, "h": 4}]}), [])
	var walls := ShortPlatforms.wall_rects(data)
	assert_eq(walls.filter(func(w): return int(w.building) == 0).size(), 2, "block 1 keeps its two skyscraper slots")
	# The old MVP map without heights keeps its whole blocks.
	var mvp := MvpMapScript.load_layout("res://data/level/mvp_map.json")
	assert_eq(ShortPlatforms.platforms_of(mvp), [])
	assert_eq(ShortPlatforms.wall_rects(mvp).size(), mvp.buildings.size())


func test_the_game_map_runs_with_them() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	var a := _area(run.map, "block@12,-96/1,1")
	assert_not_null(a)
	assert_true(a.is_building())
	assert_eq(run.elevation.ground_height.height_at(Vector2(34.5, -73.5)), 3.0)
	for s in run.map.slots:
		assert_false(str(s.name).begins_with("Short"), "no short slot node: they are platforms")


func test_the_level_and_one_saved_before_pass_check_level() -> void:
	for pair in [["t405_check.json", Level.file_data()], ["t405_check_old.json", _old_level()]]:
		var path := RunPaths.file(str(pair[0]))
		assert_eq(LevelStore.save_level(path, pair[1]), OK)
		var output: Array = []
		var code := OS.execute("python", [ProjectSettings.globalize_path("res://tools/check_level.py"),
			ProjectSettings.globalize_path(path)], output, true)
		assert_eq(code, 0, "%s: %s" % [pair[0], "\n".join(output)])
