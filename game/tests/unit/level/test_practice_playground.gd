extends GutTest
## Task T-560 (Level design, Decisions and Content, "The practice playground"): the level the
## tutorial's practice windows load, data/level/practice_playground.json. It loads in a run, draws
## its grid ground, has a start point for each trick slide that the run starts the car on, and the
## ramp throws a car at full speed into an AIR 360! and onto the rails beyond it. The drive uses the
## real car (scripted inputs, stepped by the test), as test_run_rails.gd does.

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
	assert_eq(data.platforms.size(), 1)
	assert_eq(data.ramps.size(), 2)


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
	assert_eq(run.car.model.get_position(), Vector2(data.spawn.x, data.spawn.y), "the spawn is the drift start")


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


func test_the_rails_are_in_the_ramps_flight_path_and_one_a_jump_beside_another() -> void:
	var rails := Rails.from_layout(data)
	var ids := rails.map(func(r): return r.id)
	assert_eq(ids, ["rail-1", "rail-2", "rail-3"])
	var top := Vector2(12.0, 0.0)  # the jump ramp's top, at height 5
	for r in rails:
		assert_gt(r.a.x, top.x + 2.0, "%s lies beyond the ramp's top" % r.id)
		assert_lte(absf(r.a.y), 4.0)
	assert_almost_eq(absf(rails[2].a.y - rails[1].a.y), 3.5, 0.01, "rail-3 a jump from rail-2")


## Drives east from `from` with W held (scripted), turning with A (steer 1) in the air when
## `spin`, Space held in the air past x `space_from_x`. Returns {tricks, caught, airtime, speed_at_top, land_x}.
func _drive(from: Vector2, speed: float, spin: bool, hold_space: bool = true, w: bool = true,
		space_from_x: float = 11.0) -> Dictionary:
	_run()
	_place(from, speed)
	var tricks: Array = []
	run.car.trick.connect(func(id: String) -> void: tricks.append(id))
	var out := {"caught": "", "airtime": 0.0, "speed_at_top": 0.0, "land_x": 0.0}
	var airborne_before := false
	for i in 900:
		var in_air: bool = run.car.airborne
		run.car.scripted_input = [w, false, 1.0 if (spin and in_air and run.car.model.get_position().x > 11.0) else 0.0]
		run.car.scripted_jump_held = hold_space and in_air and run.car.model.get_position().x > space_from_x
		run.car.physics_step()
		var x: float = run.car.model.get_position().x
		if run.car.airborne and not airborne_before and x > 10.0 and out.speed_at_top == 0.0:
			out.speed_at_top = run.car.model.get_velocity().length()
		airborne_before = run.car.airborne
		if run.car.airborne and x > 10.0:
			out.airtime += 0.02
		if run.car.grind.active:
			out.caught = run.car.grind.rail.id
			break
		if x > 12.0 and not run.car.airborne and out.airtime > 0.0:
			out.land_x = x
			break
	out["tricks"] = tricks
	out["end"] = run.car.model.get_position()
	out["height"] = run.car.height
	return out


func test_the_air_spin_start_reaches_full_speed_and_the_jump_ramp_gives_an_air_360() -> void:
	var p := LevelStartPoints.of(data, "air_spin")
	var r := _drive(Vector2(p.x, p.y), 0.0, true, false)
	gut.p("air_spin drive: %s" % [r])
	assert_gte(r.speed_at_top, FULL_SPEED - 0.5, "full speed at the jump ramp's top")
	assert_true(r.tricks.has("air_three_sixty"), "AIR 360! %s" % [r.tricks])
	assert_gte(r.airtime, 1.7, "an airtime with room to spare for the 360")


func test_the_air_spin_start_with_space_held_catches_a_rail() -> void:
	var p := LevelStartPoints.of(data, "air_spin")
	var r := _drive(Vector2(p.x, p.y), 0.0, false)
	gut.p("air_spin grind drive: %s" % [r])
	assert_ne(r.caught, "", "a rail is caught from the ramp at full speed")


func test_the_grind_start_reaches_a_rail_from_the_ramp() -> void:
	var p := LevelStartPoints.of(data, "grind")
	var r := _drive(Vector2(p.x, p.y), 0.0, false)
	gut.p("grind drive: %s" % [r])
	assert_ne(r.caught, "", "a rail is caught from the ramp, starting at the grind point")


func test_every_rail_is_caught_from_the_ramp() -> void:
	# Full speed down the middle: rail-2; a lane over (y 3.5, 3.5 units beside it): rail-3; with W let go
	# at 11 units/s on the roof: the nearer rail-1.
	# T-566 (a grind starts when the car's drawing crosses a rail's, at any height): in the lane over,
	# the car flying high off the ramp is drawn on rail-1 (a car 3.5 units nearer the viewer and 3.5
	# higher is drawn on a bar), so Space held from the takeoff catches rail-1 there. The player catches
	# rail-3 by holding Space later, once past rail-1 (x 37, rail-1 ends at 34) and low enough over rail-3.
	var r2 := _drive(Vector2(-55.0, 0.0), 0.0, false)
	assert_eq(r2.caught, "rail-2")
	var r3 := _drive(Vector2(-55.0, 3.5), 0.0, false, true, true, 37.0)
	gut.p("lane drive: %s" % [r3])
	assert_eq(r3.caught, "rail-3")
	var r1 := _drive(Vector2(4.0, 0.0), 11.0, false, true, false)
	gut.p("cruise drive: %s" % [r1])
	assert_eq(r1.caught, "rail-1")
