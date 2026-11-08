extends GutTest
## Task T-560 (Level design, Decisions and Content, "The practice playground"): the level the
## tutorial's practice windows load, data/level/practice_playground.json. It loads in a run, draws
## its grid ground, has a start point for each trick slide that the run starts the car on.
## T-574: the layout is the board's own, from the level creator (game/data/levels/ is the board's
## folder; this file is the copy the tutorial loads, the old builder is retired): the air spin start
## drives straight into a jump ramp for an air spin, and the grind start hops (Jump) onto its rails.
## The drives use the real car (scripted inputs, stepped by the test), as test_run_rails.gd does.

const PATH := "res://data/level/practice_playground.json"
const Rails := preload("res://scripts/level/rails.gd")
const SLIDES := ["drift", "alt_drift", "air_spin", "grind"]
const FULL_SPEED := 16.5

var run: Node2D
var data: Dictionary


func before_each() -> void:
	TestSave.isolate()
	data = JSON.parse_string(FileAccess.get_file_as_string(PATH))


func after_each() -> void:
	get_tree().paused = false
	await wait_process_frames(1)
	TestSave.restore()


func _run(start_id: String = "") -> void:
	run = GameFlow.add_run(self, PlayerProgress.new(), PATH, null, start_id)
	autofree(run)
	run.car.use_keyboard = false
	run.car.set_physics_process(false)
	run.minions.set_physics_process(false)
	run.kaiju_boss.set_physics_process(false)


## Puts the car on the street at `pos` (units) heading east at `speed` units/s.
func _place(pos: Vector2, speed: float) -> void:
	var car = run.car
	car.model.set_position(pos)
	car.model.rotation = 0.0
	car.ground = run.elevation.ground_height
	car.model.set_velocity(Vector2(speed, 0))
	car.position = pos * 16.0
	car.scripted_input = [false, false, 0.0]


func test_the_file_is_the_levels_format_with_a_small_map() -> void:
	assert_eq(data.name, "Practice playground")
	assert_lte(float(data.map.width) * float(data.map.height), 120.0 * 72.0, "small, to load fast")
	assert_eq(data.ground_style.kind, "grid")
	assert_eq(data.ground_rows.size(), int(data.map.height))
	assert_gt(Rails.from_layout(data).size(), 1)
	assert_eq(data.task, "T-574", "the board's layout (T-574)")
	assert_gt(data.ramps.size(), 0)


func test_it_has_a_start_point_for_each_trick_slide_on_open_ground() -> void:
	assert_eq(LevelStartPoints.ids(data), SLIDES)
	for id in SLIDES:
		var p := LevelStartPoints.of(data, id)
		assert_false(p.is_empty(), id)
		assert_eq(LevelSpawn.problem(data, Vector2(p.x, p.y)), "", "%s: a car can stand there" % id)
	assert_eq(LevelStartPoints.of(data, "nope"), {})
	assert_eq(LevelStartPoints.with_spawn(data, "nope"), data)


func test_each_start_point_starts_the_car_there_and_no_id_keeps_the_spawn() -> void:
	for id in SLIDES:
		_run(id)
		var p := LevelStartPoints.of(data, id)
		assert_eq(run.car.model.get_position(), Vector2(p.x, p.y), id)
		assert_almost_eq(rad_to_deg(run.car.model.rotation), float(p.heading), 0.01, id)
		run.queue_free()
		await wait_process_frames(1)
	_run()
	assert_eq(run.car.model.get_position(), Vector2(data.spawn.x, data.spawn.y), "no id: the level's spawn")


func test_the_run_draws_the_grid_ground_not_the_tiles() -> void:
	_run()
	assert_false(run.map.grid_style.is_empty())
	assert_eq(run.map.grid_style.ground_color, Color(0.23, 0.21, 0.37), "lightened so the dark tyre marks show")
	assert_false(run.map.ground_tiles.visible, "no tiles over the grid")
	assert_false(run.map.uses_ground_art())
	assert_true(GridGround.of({}).is_empty(), "a level without it keeps the usual ground")
	assert_true(GridGround.of({"ground_style": {"kind": "other"}}).is_empty())
	var kaiju: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/level/kaiju_city_map.json"))
	assert_true(GridGround.of(kaiju).is_empty(), "Kaiju City keeps its ground")


func test_the_old_builder_is_retired_and_writes_nothing() -> void:
	# T-574: the board's layout is the source now; the T-560 script must not overwrite it.
	var src := FileAccess.get_file_as_string("res://tools/build_practice_playground.py")
	assert_string_contains(src, "RETIRED (T-574")
	assert_string_contains(src, "raise SystemExit")


## Drives the car from start point `id` with W held (scripted). `spin`: A held in the air.
## `hop_at_x`: Space pressed once at that x on the ground (Jump owned), then held in the air.
## Stops after the first landing (or after a grind ended). Returns {tricks, caught, airtime, end}.
func _drive_from(id: String, spin: bool, hop_at_x := INF) -> Dictionary:
	var p := LevelStartPoints.of(data, id)
	_run(id)
	_place(Vector2(p.x, p.y), 0.0)
	if hop_at_x < INF:
		run.car.jump.set_tier(1)
	var tricks: Array = []
	run.car.trick.connect(func(t: String) -> void: tricks.append(t))
	var out := {"caught": "", "airtime": 0.0}
	var pressed := false
	var flew := false
	for i in 900:
		var in_air: bool = run.car.airborne
		if not pressed and hop_at_x < INF and not in_air and run.car.model.get_position().x >= hop_at_x:
			run.car.press_jump()
			pressed = true
		run.car.scripted_input = [true, false, 1.0 if (spin and in_air) else 0.0]
		run.car.scripted_jump_held = pressed and (in_air or run.car.grind.active)
		run.car.physics_step()
		if run.car.grind.active:
			out.caught = run.car.grind.rail.id
		if run.car.airborne:
			flew = true
			out.airtime += 0.02
		if flew and not run.car.airborne and not run.car.grind.active:
			break
	out["tricks"] = tricks
	out["end"] = run.car.model.get_position()
	return out


func test_the_air_spin_start_drives_straight_into_a_jump_ramp_for_an_air_spin() -> void:
	var r := _drive_from("air_spin", true)
	gut.p("air_spin drive: %s" % [r])
	assert_gte(r.airtime, 1.2, "a real flight off the jump ramp")
	assert_true(r.tricks.has("air_one_eighty") or r.tricks.has("air_three_sixty"), "an air spin: %s" % [r.tricks])


func test_the_grind_start_hops_onto_a_rail() -> void:
	var p := LevelStartPoints.of(data, "grind")
	var r := _drive_from("grind", false, p.x + 1.0)
	gut.p("grind drive: %s" % [r])
	assert_ne(r.caught, "", "a rail is caught with a hop from the grind start")
