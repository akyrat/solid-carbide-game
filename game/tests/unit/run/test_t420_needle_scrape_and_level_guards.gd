extends GutTest
## Task T-420: thread the needle voids a pass while the car is still scraping a paired obstacle,
## the ground-height data guards, and the run's start on a level without a spawn point.
## Bad level files are in tests/fixtures/t420/ (never in data/levels/).

const RunScene := preload("res://scenes/run/run.tscn")
const FIXTURES := "res://tests/fixtures/t420/"
const DT := 0.02


# ---- Thread the needle while scraping -----------------------------------------------------------

func _layout() -> Dictionary:
	var d := LevelDocument.new_level_data("T-420 needle")
	d.pattern_copies = [
		{"id": "boulder-1", "boulders": [{"x": -3.0, "y": -40.0, "diameter": 3.0, "variant": "a"}]},
		{"id": "boulder-2", "boulders": [{"x": 3.0, "y": -40.0, "diameter": 3.0, "variant": "b"}]},
	]
	d["pairs"] = [{"id": "pair-1", "a": "boulder-1", "b": "boulder-2"}]
	return d


func _body(copy_id: String) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.set_meta("copy_id", copy_id)
	autofree(body)
	return body


func test_still_touching_for_longer_than_the_window_pays_nothing() -> void:
	var n := ThreadTheNeedle.new(_layout(), ComboData.new().needle_rules())
	var body := _body("boulder-1")
	var paid: Array = []
	# One new contact, then ten seconds of scraping (held contacts every step), then the crossing.
	n.touched(body, 0)
	for i in 500:
		n.touching([[body, 0]])
		paid.append_array(n.observe(Vector2(-1.0, -30.0 - i * 0.01), false, DT))
	var y := -35.0
	while y > -45.0:
		n.touching([[body, 0]])
		paid.append_array(n.observe(Vector2(-1.0, y), false, DT))
		y -= 0.1
	for i in 40:
		n.touching([[body, 0]])
		paid.append_array(n.observe(Vector2(-1.0, -45.0), false, DT))
	assert_eq(paid, [], "crossing while still in contact pays nothing, however long the contact")


func test_the_same_crossing_without_contact_still_pays() -> void:
	var n := ThreadTheNeedle.new(_layout(), ComboData.new().needle_rules())
	var paid: Array = []
	n.touched(_body("boulder-1"), 0)
	for i in 200:  # 4 s with no contact at all
		paid.append_array(n.observe(Vector2(0, -30.0), false, DT))
	var y := -35.0
	while y > -45.0:
		paid.append_array(n.observe(Vector2(0, y), false, DT))
		y -= 0.1
	for i in 30:
		paid.append_array(n.observe(Vector2(0, -45.0), false, DT))
	assert_eq(paid, ["pair-1"])


func test_a_held_contact_of_an_unpaired_obstacle_does_not_count() -> void:
	var n := ThreadTheNeedle.new(_layout(), ComboData.new().needle_rules())
	var other := StaticBody2D.new()
	other.set_meta("prop_id", "prop-9")
	autofree(other)
	var paid: Array = []
	var y := -35.0
	while y > -45.0:
		n.touching([[other, 0]])
		paid.append_array(n.observe(Vector2(0, y), false, DT))
		y -= 0.1
	for i in 30:
		paid.append_array(n.observe(Vector2(0, -45.0), false, DT))
	assert_eq(paid, ["pair-1"])


func _run_on(layout: Dictionary, name := "t420_run_level.json") -> Node2D:
	var path := RunPaths.file(name)
	assert_eq(LevelStore.save_level(path, layout), OK)
	var run: Node2D = RunScene.instantiate()
	run.layout_path = path
	add_child_autofree(run)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	return run


func _place(car, at: Vector2) -> void:
	car.model.set_position(at)
	car.model.rotation = -PI / 2.0
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()


func test_the_car_reports_its_held_contacts() -> void:
	var run := _run_on(_layout())
	var car = run.car
	assert_eq(car.held_contacts(), [], "free on the street")
	_place(car, Vector2(-1.2, -30.0))
	car.scripted_input = [true, false, 0.0]
	var max_held := 0
	for i in 400:
		car.physics_step()
		max_held = maxi(max_held, car.held_contacts().size())
	assert_gt(max_held, 0, "the car scraped the boulder at some point")


## Two long barriers, one each side of a 3-unit gap (x -1.5 to 1.5), running north-south along the
## car's road from y -60 to -20, paired: a car can scrape the west one's east face for 20 units before the gap line.
func _barrier_layout() -> Dictionary:
	var d := LevelDocument.new_level_data("T-420 barriers")
	d["props"] = [
		{"id": "prop-1", "asset": "prop-barrier", "rotation": "north", "x": -2.5, "y": -60.0, "w": 1.0, "h": 40.0},
		{"id": "prop-2", "asset": "prop-barrier", "rotation": "north", "x": 1.5, "y": -60.0, "w": 1.0, "h": 40.0},
	]
	d["pairs"] = [{"id": "pair-1", "a": "prop-1", "b": "prop-2"}]
	return d


func test_a_run_scraping_through_the_gap_pays_nothing() -> void:
	var run := _run_on(_barrier_layout())
	var car = run.car
	var tricks: Array = []
	run.state.combo_trick.connect(func(id, _a, _m): tricks.append(id))
	# Start against the west boulder's inner side, press into it with the nose and drive north
	# along it, across the gap line and out the far side.
	car.tuning.wall_bounce = 0.0  # slide along the boulder, as a scrape does
	_place(car, Vector2(-0.75, -2.0))
	car.model.rotation = -PI / 2.0 - 0.01  # nose a little into the barrier (west)
	run.needle.last_position = null
	var hits: Array = []  # the car's hit_obstacle fires once per contact, not per step of the scrape
	car.hit_obstacle.connect(func(_c, _i, _n, _s): hits.append(run.needle.time))
	var crossed := false
	var held_at_cross := false
	var prev_y: float = car.model.get_position().y
	for i in 900:
		car.scripted_input = [true, false, 0.0]
		car.physics_step()
		var p: Vector2 = car.model.get_position()
		if prev_y > -40.0 and p.y <= -40.0 and absf(p.x) < 1.5:
			crossed = true
			held_at_cross = not car.held_contacts().is_empty()
		prev_y = p.y
		if p.y < -46.0:
			break
	for i in 40:
		car.scripted_input = [false, false, 0.0]
		car.physics_step()
	assert_true(crossed, "the car's centre crossed the gap line")
	assert_eq(hits.size(), 1, "one hit_obstacle for the whole scrape")
	assert_true(held_at_cross, "still in contact with a paired obstacle at the crossing")
	assert_false("thread_the_needle" in tricks, "crossed while still in contact: nothing paid")


# ---- Ground height data guards ------------------------------------------------------------------

func _load(file: String) -> GroundHeight:
	var g := GroundHeight.new()
	var data = JSON.parse_string(FileAccess.get_file_as_string(FIXTURES + file))
	assert_typeof(data, TYPE_DICTIONARY, file)
	g.load_data(data)
	return g


func test_the_good_fixture_loads_cleanly() -> void:
	var g := _load("good.json")
	assert_eq(g.error, "")
	assert_eq(g.platforms.size(), 1)
	assert_eq(g.ramps.size(), 1)
	assert_almost_eq(g.height_at(Vector2(14, 0)), 1.5, 0.0001)


func test_a_missing_key_is_a_clear_error_naming_the_piece() -> void:
	var g := _load("platform_missing_height.json")
	assert_push_error("roof-1")
	assert_string_contains(g.error, "platform roof-1")
	assert_string_contains(g.error, "height")
	assert_eq(g.platforms.size(), 0, "flat, not half loaded")
	g = _load("platform_missing_x.json")
	assert_push_error("roof-1")
	assert_string_contains(g.error, "\"x\"")
	g = _load("ramp_missing_top_height.json")
	assert_push_error("ramp-1")
	assert_string_contains(g.error, "ramp ramp-1")
	assert_string_contains(g.error, "top_height")
	assert_eq(g.platforms.size(), 0)
	assert_eq(g.ramps.size(), 0)
	assert_eq(g.height_at(Vector2(0, 0)), 0.0)


func test_an_unknown_ramp_side_is_a_clear_error() -> void:
	var g := _load("ramp_unknown_side.json")
	assert_push_error("ramp-1")
	assert_string_contains(g.error, "ramp ramp-1")
	assert_string_contains(g.error, "\"up\"")
	assert_eq(g.ramps.size(), 0, "not a flat ramp")


func test_a_zero_size_ramp_is_a_clear_error_and_no_nan() -> void:
	for file in ["ramp_zero_width.json", "ramp_zero_height.json"]:
		var g := _load(file)
		assert_push_error("ramp-1")
		assert_string_contains(g.error, "ramp ramp-1")
		assert_string_contains(g.error, "above 0")
		for pt in [Vector2(14, 0), Vector2(8, 0), Vector2(20, 0), Vector2(0, 0)]:
			assert_false(is_nan(g.height_at(pt)), "%s at %s" % [file, pt])


func test_a_hand_built_zero_size_ramp_never_gives_nan() -> void:
	var g := GroundHeight.new()
	g.ramps.append({"id": "r", "platform": "", "side": "east", "rect": Rect2(8, -4, 0, 8),
		"bottom_height": 0.0, "top_height": 3.0, "art": "", "style": "", "arrows": "up"})
	assert_false(is_nan(g.height_at(Vector2(8, 0))))


func test_the_games_ground_data_still_loads() -> void:
	var g := GroundHeight.from_file()
	assert_eq(g.error, "")
	assert_eq(g.platforms.size(), 1)


# ---- The run's start without a spawn ------------------------------------------------------------

func test_a_level_with_no_spawn_starts_where_level_spawn_says() -> void:
	var layout := _layout()
	assert_false(LevelSpawn.has_spawn(layout))
	var run := _run_on(layout, "t420_no_spawn.json")
	var want := LevelSpawn.position_of(layout)
	assert_eq(want, LevelSpawn.centre_of(layout))
	assert_eq(run.car.model.get_position(), want, "the map's centre, snapped to a cell, not (0, 0)")
	assert_almost_eq(run.car.model.rotation, deg_to_rad(LevelSpawn.DEFAULT_HEADING), 0.0001)
	assert_eq(run.spawn_problem, "")


func test_a_level_with_a_spawn_still_starts_on_it() -> void:
	var layout := _layout()
	layout["spawn"] = {"x": 11.0, "y": 13.0, "heading": 90}
	var run := _run_on(layout, "t420_spawn.json")
	assert_eq(run.car.model.get_position(), Vector2(11, 13))


func test_a_spawn_inside_geometry_is_reported() -> void:
	var layout := _layout()
	layout["buildings"] = [{"id": "b1", "x": 8.0, "y": 8.0, "w": 10.0, "h": 10.0}]
	layout["spawn"] = {"x": 13.0, "y": 13.0, "heading": 270}
	var run := _run_on(layout, "t420_blocked.json")
	assert_eq(run.spawn_problem, LevelSpawn.BLOCKED)
	layout["spawn"] = {"x": 500.0, "y": 0.0, "heading": 270}
	run = _run_on(layout, "t420_off.json")
	assert_eq(run.spawn_problem, LevelSpawn.OFF_MAP)


func test_the_games_own_map_keeps_its_start() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	assert_eq(run.car.model.get_position(), run.START_POSITION_UNITS)
	assert_eq(run.spawn_problem, "")
