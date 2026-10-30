extends GutTest
## Task T-400 (Level design, Decisions, "A small jump ramp"): the level creator's small jump ramp,
## one tile (4 units) long and rising 2 units from what it stands on: Ramp 0 to 2 on the street,
## 3 to 5 on a height 3 rooftop, 6 to 8 on a height 6 one (the ramp family's height steps, key H).
## It climbs to no rooftop ("jump": true): its tall end is open, so the car drives up it and flies
## off its top, and a jump pays the airtime like a ramp hop. Levels are saved only into a
## temporary folder (RunPaths); the board's own levels are never touched.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const DrawingScript := preload("res://scripts/level/elevation_platform_drawing.gd")
const MvpMapScript := preload("res://scripts/level/mvp_map.gd")
const CarScript := preload("res://scripts/driving/car.gd")
const CarHeight := preload("res://scripts/driving/car_height.gd")
const ComboDataScript := preload("res://scripts/data/combo_data.gd")
const NavScript := preload("res://scripts/enemies/enemy_navigation.gd")
const STYLE_PATH := "res://art/creator_pieces/piece_style.tres"
const SAMPLE := "res://data/level/elevation_sample_map.json"
const SMALL := {"ramp-0-2": [0, 2], "ramp-3-5": [3, 5], "ramp-6-8": [6, 8]}
const DIRECTIONS := ["north", "east", "south", "west"]
## The side of the rooftop a ramp climbing each way would go up (the height data's "side").
const SIDE_OF := {"north": "south", "east": "west", "south": "north", "west": "east"}
## The car's rotation driving each way (x east, y south).
const HEADING := {"north": -PI / 2, "east": 0.0, "south": PI / 2, "west": PI}
const UNIT := {"north": Vector2(0, -1), "east": Vector2(1, 0), "south": Vector2(0, 1), "west": Vector2(-1, 0)}

var dir: String


func before_each() -> void:
	TestSave.isolate()
	dir = RunPaths.file("t400_levels_" + str(randi()))


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


func _pick(e: LevelCreatorEditor, id: String, view: String) -> void:
	e.panel.pick(id)
	for i in 4:
		if e.pick_view == view:
			return
		e.rotate_pick()


## Places a small ramp climbing `view` with its corner near `at`, `width` across the slope.
func _place(e: LevelCreatorEditor, id: String, view: String, at: Vector2, width: float = 10.0) -> Dictionary:
	_pick(e, id, view)
	var size := Vector2(width, 0) if view in ["north", "south"] else Vector2(0, width)
	return e.place_asset(id, at, size)


# ---- The piece in the creator ---------------------------------------------------------------------

func test_the_small_ramps_are_height_steps_of_the_ramp_family_with_number_labels() -> void:
	var e := _editor()
	e.panel.pick("ramp")
	var seen := [e.panel.picked]
	for i in 5:
		e.height_pick()
		seen.append(e.panel.picked)
	assert_eq(seen, ["ramp-0-3", "ramp-3-6", "ramp-0-6", "ramp-0-2", "ramp-3-5", "ramp-6-8"])
	for id in SMALL:
		var h: Array = SMALL[id]
		assert_true(LevelDocument.is_jump_ramp(id), id)
		assert_eq(CreatorTexts.get_text(LevelCreatorAssetPanel.LABEL_KEYS[id]), "Ramp %d to %d" % [h[0], h[1]])
		_pick(e, id, "north")
		assert_eq(e.height_label.text, "Ramp %d to %d" % [h[0], h[1]], "the top bar names it")
	for id in ["ramp-0-3", "ramp-3-6", "ramp-0-6"]:
		assert_false(LevelDocument.is_jump_ramp(id), id)


func test_it_places_on_the_street_in_all_four_directions_one_tile_long_and_2_high() -> void:
	var e := _editor()
	var x := -100.0
	for view in DIRECTIONS:
		var r := _place(e, "ramp-0-2", view, Vector2(x, -80))
		assert_false(r.is_empty(), "placed climbing %s" % view)
		if r.is_empty():
			continue
		var it: Dictionary = r.item
		var along_y: bool = view in ["north", "south"]
		assert_eq(Vector2(float(it.w), float(it.h)), Vector2(10, 4) if along_y else Vector2(4, 10), view)
		assert_eq(str(it.side), SIDE_OF[view])
		assert_eq([int(it.bottom_height), int(it.top_height)], [0, 2])
		assert_eq(it.get("jump"), true, "a jump ramp")
		assert_eq(str(it.platform), "", "it climbs to no rooftop")
		assert_eq(str(it.arrows), "up")
		x += 30.0
	assert_eq(e.level_data.ramps.size(), 4)
	assert_eq(e.elevation.areas.filter(func(a): return a.kind == "ramp").size(), 4, "each is drawn")


func test_it_places_on_a_rooftop_at_3_and_at_6_in_all_four_directions() -> void:
	for roof in [["rooftop-3", "ramp-3-5", 3], ["rooftop-6", "ramp-6-8", 6]]:
		var e := _editor()
		e.panel.pick(roof[0])
		var p := e.place_asset(roof[0], Vector2(-100, -100), Vector2(64, 64))
		assert_false(p.is_empty(), "%s placed" % roof[0])
		var spots := [Vector2(-90, -90), Vector2(-60, -90), Vector2(-90, -60), Vector2(-60, -60)]
		for i in 4:
			var view: String = DIRECTIONS[i]
			var r := _place(e, roof[1], view, spots[i], 8.0)
			assert_false(r.is_empty(), "%s climbing %s on the rooftop (%s)" % [roof[1], view, e.last_problem])
			if r.is_empty():
				continue
			assert_eq(int(r.item.bottom_height), roof[2])
			assert_eq(int(r.item.top_height), roof[2] + 2)
			var rect := Rect2(float(r.item.x), float(r.item.y), float(r.item.w), float(r.item.h))
			assert_true(Rect2(float(p.item.x), float(p.item.y), float(p.item.w), float(p.item.h)).encloses(rect), "wholly on it")
		assert_eq(e.level_data.ramps.size(), 4)


func test_the_drawn_ramp_has_no_wall_above_its_lip() -> void:
	# Its tall end is the ramp's own back face, from the top (2 units above what it stands on) down
	# to that ground: nothing rises over the lip where the car leaves it.
	var style = load(STYLE_PATH)
	for id in SMALL:
		var h: Array = SMALL[id]
		for view in DIRECTIONS:
			var side: String = SIDE_OF[view]
			var d: Node2D = DrawingScript.new()
			var block := {"id": "r", "rect": Rect2(0, 0, 10, 4) if view in ["north", "south"] else Rect2(0, 0, 4, 10),
				"side": side, "bottom_height": float(h[0]), "top_height": float(h[1]), "arrows": "up"}
			d.setup("ramp", block, MvpMapScript.ISO_TRANSFORM)
			d.use_style(style, float(h[0]))
			add_child_autofree(d)
			var r: Rect2 = block.rect
			var allowed := []
			for c in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
				for z in [float(h[0]), float(h[1])]:
					allowed.append(d.drawn(c, z))
			for f in d.textured_faces():
				for pt in f.points:
					assert_true(allowed.any(func(a): return a.is_equal_approx(pt)),
						"%s %s %s: every corner is on the ramp, none above the lip" % [id, view, f.name])
			# Its arrows point up the slope, as on the other ramps.
			assert_eq(d.arrow_direction(), UNIT[view], "%s %s arrows" % [id, view])


# ---- Saving, reopening, the checks ---------------------------------------------------------------

func _jump_level(e: LevelCreatorEditor) -> void:
	for i in 4:
		assert_false(_place(e, "ramp-0-2", DIRECTIONS[i], Vector2(-100 + 30 * i, -80)).is_empty())
	e.panel.pick("rooftop-3")
	assert_false(e.place_asset("rooftop-3", Vector2(40, 40), Vector2(32, 32)).is_empty())
	assert_false(_place(e, "ramp-3-5", "east", Vector2(50, 50), 8.0).is_empty())
	e.name_field.text = "T-400 jumps"
	assert_eq(e.save(), OK)


func test_it_saves_and_reopens_as_a_jump_ramp() -> void:
	var e := _editor()
	_jump_level(e)
	var back := LevelStore.load_level(e.save_path())
	assert_eq(back.ramps.size(), 5)
	for r in back.ramps:
		assert_eq(r.get("jump"), true, str(r.id))
		assert_eq(str(r.platform), "")
	var e2 := _editor()
	e2.open_level(e.save_path())
	assert_eq(e2.level_data.ramps.size(), 5)
	assert_eq(e2.elevation.areas.filter(func(a): return a.kind == "ramp").size(), 5)
	assert_eq(int(e2.level_data.ramps[4].bottom_height), 3)
	assert_eq(int(e2.level_data.ramps[4].top_height), 5)
	assert_eq(e2.level_data.ramps[4].jump, true)


func test_the_saved_level_passes_check_level() -> void:
	var e := _editor()
	_jump_level(e)
	var out: Array = []
	var code := OS.execute("python", [ProjectSettings.globalize_path("res://tools/check_level.py"),
		ProjectSettings.globalize_path(e.save_path())], out, true)
	if code == -1:
		pending("python not found: check_level.py's own tests cover the jump ramp")
		return
	assert_eq(code, 0, str(out))
	assert_string_contains(str(out[0]), "OK")


func test_an_earlier_level_opens_unchanged_with_no_jump_ramps() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAMPLE))
	var path := dir.path_join("earlier.json")
	assert_eq(LevelStore.save_level(path, data), OK)
	var e := _editor()
	e.open_level(path)
	assert_eq(e.level_data.ramps.size(), data.ramps.size())
	for r in e.level_data.ramps:
		assert_false(r.has("jump"), str(r.id))
	assert_eq(JSON.stringify(e.level_data.ramps), JSON.stringify(data.ramps), "the ramps as they were")


# ---- Driving it ----------------------------------------------------------------------------------

## A car at `start` facing `view`, accelerating (W held), on `ground`.
func _car(ground, start: Vector2, view: String, world: Node) -> CharacterBody2D:
	var car: CharacterBody2D = CarScript.new()
	car.model.set_position(start)
	car.model.rotation = HEADING[view]
	world.add_child(car)
	car.set_physics_process(false)
	car.use_keyboard = false
	car.scripted_input = [true, false, 0.0]
	car.ground = ground
	return car


## Drives `car` up to 400 steps; returns what happened: took off from the ramp, the most height on
## the ground while on the ramp, the airtimes paid.
func _drive(car: CharacterBody2D, ground, max_steps: int = 400) -> Dictionary:
	var out := {"from_ramp": false, "ramp_height": 0.0, "airtimes": [], "wall": false}
	car.height_model.took_off.connect(func(from_ramp, _vz): out.from_ramp = out.from_ramp or from_ramp)
	car.airtime_trick.connect(func(s): out.airtimes.append(s))
	for i in max_steps:
		car.physics_step()
		var p: Vector2 = car.model.get_position()
		if not car.airborne and ground.is_ramp(p):
			out.ramp_height = maxf(out.ramp_height, car.height)
		if car.airborne:
			out.air_height = maxf(out.get("air_height", 0.0), car.height)
		if not out.airtimes.is_empty():
			break
	return out


func test_the_car_drives_up_it_and_flies_off_its_top_in_every_direction_and_the_airtime_pays() -> void:
	var world := Node2D.new()
	add_child_autofree(world)
	var c = ComboDataScript.new()
	for view in DIRECTIONS:
		var e := _editor()
		var r := _place(e, "ramp-0-2", view, Vector2(-11, -11))
		var rect := Rect2(float(r.item.x), float(r.item.y), float(r.item.w), float(r.item.h))
		var ground := GroundHeight.new()
		ground.load_data(e.level_data)
		# Start 24 units back from the ramp's foot, in line with its middle.
		var start: Vector2 = rect.get_center() - UNIT[view] * 26.0
		var car := _car(ground, start, view, world)
		var got := _drive(car, ground)
		assert_true(got.from_ramp, "%s: it left the ground off the ramp's top" % view)
		assert_almost_eq(got.ramp_height, 2.0, 0.3, "%s: it drove up to near the lip" % view)
		assert_gt(float(got.get("air_height", 0.0)), 2.2, "%s: it flies up over the lip, not just falls" % view)
		assert_eq(got.airtimes.size(), 1, "%s: one airtime on landing" % view)
		if got.airtimes.size() == 1:
			assert_gt(c.airtime_add(got.airtimes[0]), 0.0, "%s: the jump (%.2f s) pays" % [view, got.airtimes[0]])
			gut.p("%s: %.2f s in the air, %.2f units high at most" % [view, got.airtimes[0], got.air_height])
		car.queue_free()


func test_from_behind_its_tall_end_is_a_wall_like_any_raised_side() -> void:
	var world := Node2D.new()
	add_child_autofree(world)
	var e := _editor()
	var r := _place(e, "ramp-0-2", "north", Vector2(-11, -11))
	var rect := Rect2(float(r.item.x), float(r.item.y), float(r.item.w), float(r.item.h))
	var ground := GroundHeight.new()
	ground.load_data(e.level_data)
	# Driving south into its north (tall) end: the car can't climb a 2-unit step.
	var car := _car(ground, Vector2(rect.get_center().x, rect.position.y - 20), "south", world)
	var on_ramp := 0
	for i in 200:
		car.physics_step()
		if ground.is_ramp(car.model.get_position()):
			on_ramp += 1
	assert_eq(on_ramp, 0, "never got onto the ramp from behind")
	assert_eq(car.height, 0.0)


func test_a_jump_off_the_rooftop_small_ramp_takes_off_and_lands() -> void:
	var world := Node2D.new()
	add_child_autofree(world)
	var e := _editor()
	e.panel.pick("rooftop-3")
	var p := e.place_asset("rooftop-3", Vector2(-40, -40), Vector2(64, 64))
	var r := _place(e, "ramp-3-5", "north", Vector2(-10, 0), 10.0)
	assert_false(r.is_empty())
	var rect := Rect2(float(r.item.x), float(r.item.y), float(r.item.w), float(r.item.h))
	var ground := GroundHeight.new()
	ground.load_data(e.level_data)
	var car := _car(ground, rect.get_center() + Vector2(0, 18), "north", world)
	assert_eq(car.height, 3.0, "on the rooftop")
	var got := _drive(car, ground)
	assert_true(got.from_ramp)
	assert_almost_eq(got.ramp_height, 5.0, 0.3)
	assert_eq(got.airtimes.size(), 1)


# ---- Enemies and the run --------------------------------------------------------------------------

func test_enemies_find_their_way_round_or_over_it() -> void:
	var e := _editor()
	var r := _place(e, "ramp-0-2", "north", Vector2(-11, -11))
	var rect := Rect2(float(r.item.x), float(r.item.y), float(r.item.w), float(r.item.h))
	var ground := GroundHeight.new()
	ground.load_data(e.level_data)
	var nav = NavScript.new()
	nav.build(e.document.map_rect(), [], ground)
	var path: PackedVector2Array = nav.find_path(rect.get_center() + Vector2(0, 12), rect.get_center() - Vector2(0, 12))
	assert_gt(path.size(), 1, "a path from in front of it to behind it")


func test_a_run_on_the_level_has_the_jump_ramps_under_the_car() -> void:
	var e := _editor()
	_jump_level(e)
	var run: Node2D = GameFlow.add_run(self, PlayerProgress.new(), e.save_path())
	await wait_process_frames(1)
	var g = run.map.elevation.ground_height
	assert_eq(g.ramps.size(), 5)
	assert_eq(run.car.ground, g, "the car drives on the level's heights")
	var first: Dictionary = g.ramps[0]
	assert_almost_eq(g.height_at(first.rect.get_center()), 1.0, 0.01, "half way up a 0 to 2")
	run.queue_free()


func test_the_games_own_map_has_no_jump_ramps() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAMPLE))
	for r in data.ramps:
		assert_false(r.has("jump"), str(r.id))
