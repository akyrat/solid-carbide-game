extends GutTest
## Task T-372 (Level design, Decisions, "The board's own level becomes the game's map"): the main
## menu's Start plays the board's level from the level creator, copied into the game's own data
## as data/level/kaiju_city_map.json (GameFlow.GAME_MAP_PATH). A scripted run on it: the map is
## built from the file (buildings, rooftops, ramps, props, boulders), the car starts on its spawn
## point on a road, minions spawn and reach the parked car through the run's navigation, the
## kaiju arrives on open ground and walks to the car, its meteors find spots, and gift packs land
## on open ground. The elevation sample map stays the run's default for the tests and the creator.

const GameScene := preload("res://scenes/game/game.tscn")
const RunScript := preload("res://scripts/run/run.gd")
const ShortPlatformsScript := preload("res://scripts/level/short_platforms.gd")
const SAMPLE := "res://data/level/elevation_sample_map.json"
const GAME_MAP := "res://data/level/kaiju_city_map.json"
const DT := 0.05

var game: GameFlow
var run: Node2D
var data: Dictionary


func before_each() -> void:
	TestSave.isolate()
	data = JSON.parse_string(FileAccess.get_file_as_string(GAME_MAP))
	game = GameScene.instantiate()
	game.quit_game = func(): pass
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()
	run = game.run
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	run.car.set_physics_process(false)
	run.minions.set_physics_process(false)
	run.kaiju_boss.set_physics_process(false)


func after_each() -> void:
	get_tree().paused = false
	await wait_process_frames(1)
	TestSave.restore()


func _ids(items: Array) -> Array:
	return items.map(func(p): return str(p.id))


func _car_units() -> Vector2:
	return run.car.position / 16.0


func _rect(r: Dictionary) -> Rect2:
	return Rect2(float(r.x), float(r.y), float(r.w), float(r.h))


func _spawn_units() -> Vector2:
	return Vector2(float(data.spawn.x), float(data.spawn.y))


## True when `units` is inside a solid building (a skyscraper: short buildings are platforms).
func _in_solid_building(units: Vector2) -> bool:
	for b in run.map.layout.buildings:
		if ShortPlatformsScript.is_platform_entry(b):
			continue
		if _rect(b).has_point(units):
			return true
	return false


# --- Start plays the board's level ------------------------------------------------

func test_start_plays_the_game_map_file() -> void:
	assert_eq(GameFlow.GAME_MAP_PATH, GAME_MAP)
	assert_true(GAME_MAP.begins_with("res://data/level/"), "a copy in the game's own data")
	assert_false(GAME_MAP.contains("data/levels/"), "never the creator's levels folder")
	assert_eq(run.layout_path, GAME_MAP)
	assert_eq(run.map.layout_path, GAME_MAP)
	assert_eq(str(run.map.layout.name), "Kaiju City")
	assert_true(run.state.is_running())
	assert_eq(run.state.time_left_text(), "8:00")


func test_the_elevation_sample_map_stays_the_runs_default() -> void:
	assert_true(FileAccess.file_exists(SAMPLE))
	assert_eq(RunScript.ELEVATION_LAYOUT_PATH, SAMPLE)


func test_the_pause_screens_restart_plays_the_game_map_again() -> void:
	game.pause_screen.restart_pressed.emit()
	assert_eq(game.run.layout_path, GAME_MAP)


# --- The map is built from the file ------------------------------------------------

func test_the_map_holds_the_levels_buildings_rooftops_ramps_props_and_boulders() -> void:
	assert_eq(run.map.buildings.size(), data.buildings.size(), "the level's buildings")
	var gh = run.elevation.ground_height
	var rooftops: Array = gh.platforms.filter(func(p): return not bool(p.get("short", false)))
	assert_eq(_ids(rooftops), _ids(data.platforms), "the level's rooftops")
	assert_eq(_ids(gh.ramps), _ids(data.ramps), "the level's ramps")
	assert_eq(run.map.layout.props.size(), data.props.size(), "the level's props")
	var boulders := 0
	for c in data.pattern_copies:
		boulders += c.boulders.size()
	assert_eq(run.map.all_boulders().size(), boulders, "the level's boulders")
	assert_eq(run.car.ground, gh, "the car drives on the level's heights")
	# T-441: the fixed sign list is retired; Kaiju City has no alert signs until the board places them.
	assert_eq(run.map.alert_signs.size(), 0, "no kaiju alert signs on the game map yet")


func test_the_map_draws_the_levels_own_ground() -> void:
	assert_eq(run.map.ground_layout, LevelGround.layout_of(run.map.layout))


func test_the_car_starts_on_the_spawn_point_on_a_road() -> void:
	var spawn := _spawn_units()
	assert_almost_eq(_car_units().x, spawn.x, 0.01)
	assert_almost_eq(_car_units().y, spawn.y, 0.01)
	assert_eq(LevelSpawn.problem(data, spawn), "", "a place a car can stand")
	var m: Rect2 = _rect(data.map.rect)
	var row: String = data.ground_rows[int(spawn.y - m.position.y)]
	assert_eq(row[int(spawn.x - m.position.x)], "R", "the spawn cell is road")
	assert_almost_eq(run.elevation.ground_height.height_at(spawn), 0.0, 0.001, "on the street")


# --- Minions find their way to the car ---------------------------------------------

func test_minions_spawn_and_reach_the_parked_car() -> void:
	run.kaiju_boss.enabled = false
	var spawner = run.minions
	assert_not_null(spawner.navigation, "the run's navigation is built for the level")
	spawner.rng.seed = 372
	var car := _car_units()
	var reached := {}
	var seen := {}
	var t := 0.0
	while t < 30.0:
		run.state.health = run.state.max_health
		run.state.advance(DT)
		spawner.step(DT)
		t += DT
		for m in spawner.minions:
			var id: int = m.get_instance_id()
			seen[id] = true
			if m.touches_car(car, run.car.rotation):
				reached[id] = true
	gut.p("game map: %d minions spawned, %d reached the car in 30 s" % [seen.size(), reached.size()])
	assert_gt(seen.size(), 5, "minions spawned on the level")
	assert_gt(reached.size(), 3, "minions reached the car")


# --- The kaiju and gift packs land --------------------------------------------------

func _bring_the_kaiju() -> void:
	run.minions.enabled = false
	run.state.advance(RunState.RUN_SECONDS - RunState.BOSS_TIME_LEFT + 0.5)
	for i in 40:
		if run.kaiju_boss.has_appeared():
			break
		run.kaiju_boss.step(1.0 / 60.0)


func test_the_kaiju_arrives_on_open_ground_and_walks_to_the_car() -> void:
	_bring_the_kaiju()
	assert_true(run.kaiju_boss.has_appeared(), "the kaiju found somewhere to land")
	var kaiju: Node = run.kaiju_boss.kaiju
	assert_not_null(kaiju)
	var start: Vector2 = kaiju.position / 16.0
	assert_true(run.kaiju_boss.is_free_spot(start), "it arrived on open street")
	var d0: float = start.distance_to(_car_units())
	for i in 300:
		run.state.health = run.state.max_health
		run.kaiju_boss.step(1.0 / 60.0)
	var d1: float = (kaiju.position / 16.0).distance_to(_car_units())
	assert_lt(d1, d0, "it walks towards the car")


func test_the_kaijus_meteors_find_spots_on_the_level() -> void:
	_bring_the_kaiju()
	var meteors: Node = run.kaiju_boss.meteors
	assert_not_null(meteors)
	var found := 0
	for i in 10:
		if meteors.pick_spot() != null:
			found += 1
	assert_gt(found, 0, "meteors have somewhere to land")


func test_gift_packs_land_on_open_ground_near_the_spawn() -> void:
	run.minions.enabled = false
	var drops: GiftDrops = run.gift_drops
	for i in 3:
		run.state.add_xp(run.state.xp_needed())
		drops.land_all()
		get_tree().paused = false
	var landed: Array = drops.landed_packages()
	assert_gt(landed.size(), 0, "gift packs landed")
	for pkg in landed:
		var spot: Vector2 = pkg.ground_units()
		assert_false(_in_solid_building(spot), "not inside a building: %s" % spot)
		assert_true(drops.is_open_road(spot), "on open road: %s" % spot)


## The rooftops of the board's level with no ramp up to them (reached only from the air, off a
## higher jump): minions can't walk onto them, so a car parked there is not reached. Reported to
## the Project Lead in T-372's result notes, not changed (the level is the board's).
const NO_WAY_UP := ["roof-13"]


## The car parked in turn at the spawn and on each rooftop of the level, with minions on free spots
## round it (the 12 nearest free street spots, 10 to 48 units away) walking as in a run (move_step: pushing apart, the
## navigation's paths) for 40 s. Prints how many reached the car at each stop; every stop but the
## rooftops in NO_WAY_UP is reached by at least one.
func test_scripted_chase_minions_reach_the_car_on_the_street_and_every_rooftop() -> void:
	run.kaiju_boss.enabled = false
	var spawner = run.minions
	spawner.enabled = false
	spawner.rng.seed = 3720
	var gh = run.elevation.ground_height
	var stops: Array = [{"id": "spawn", "at": _spawn_units()}]
	for p in data.platforms:
		stops.append({"id": str(p.id), "at": _rect(p).get_center()})
	var unreached: Array = []
	for s in stops:
		var stop: Vector2 = s.at
		var car = run.car
		car.model.set_position(stop)
		car.model.rotation = 0.0
		car.model.set_velocity(Vector2.ZERO)
		car._sync_from_model()
		car.ground = gh
		run.sync_view()
		spawner.clear()
		var spots: Array = []
		for gx in range(-48, 49, 6):
			for gy in range(-48, 49, 6):
				var p: Vector2 = stop + Vector2(gx, gy)
				var d := p.distance_to(stop)
				if d >= 10.0 and d <= 48.0 and spawner.is_free_spot(p):
					spots.append(p)
		spots.sort_custom(func(a, b): return a.distance_to(stop) < b.distance_to(stop))
		for p in spots.slice(0, 12):
			spawner.spawn_minion_at(p)
		var placed: int = spawner.minions.size()
		assert_gt(placed, 0, "minions placed round %s" % s.id)
		var reached := {}
		var t := 0.0
		while t < 40.0 and reached.size() < placed:
			run.state.health = run.state.max_health
			spawner.move_step(DT, false)
			t += DT
			for m in spawner.minions:
				if m.touches_car(stop, 0.0):
					reached[m.get_instance_id()] = true
		gut.p("%s %s (height %.0f): %d of %d minions reached the car" % [s.id, stop, gh.height_at(stop), reached.size(), placed])
		if reached.is_empty():
			unreached.append(s.id)
	assert_eq(unreached, NO_WAY_UP, "the car stops no minion reached")



## Where minions can spawn (a finding for the Project Lead, T-372): minions spawn only on the
## street (T-207), on a ring just beyond the visible screen. The car is put on the spawn point,
## every rooftop's centre and every 16-unit cell of the map it can stand on, and the spawn ring is
## tried 30 times there; the places where no try is free are printed. Only the spawn point must
## have spawn spots (the run's start).
func test_report_where_the_spawn_ring_finds_no_street() -> void:
	var sp = run.minions
	var car = run.car
	var gh = run.elevation.ground_height
	var none: Array = []
	var cells := 0
	var places: Array = [_spawn_units()]
	for p in data.platforms:
		places.append(_rect(p).get_center())
	for gx in range(-112, 113, 16):
		for gy in range(-112, 113, 16):
			places.append(Vector2(gx, gy))
	for at in places:
		if LevelSpawn.problem(data, at) != "":
			continue
		cells += 1
		car.model.set_position(at)
		car.model.set_velocity(Vector2.ZERO)
		car._sync_from_model()
		car.ground = gh
		run.sync_view(true)
		await wait_process_frames(1)
		var ok := false
		for i in 30:
			if sp.pick_spawn_point() != null:
				ok = true
				break
		if not ok:
			none.append("%s h%.0f" % [at, gh.height_at(at)])
	gut.p("spawn ring: no street spot from %d of %d car places: %s" % [none.size(), cells, none])
	assert_false(none.has("%s h0" % _spawn_units()), "minions can spawn round the spawn point")
