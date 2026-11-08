extends GutTest
## Task T-560 (Level design, Decisions and Content, "The practice playground"): the level the
## tutorial's practice windows load, data/level/practice_playground.json. It loads in a run, draws
## its grid ground, has a start point for each trick slide that the run starts the car on.
## T-574: the layout is the board's own, from the level creator (game/data/levels/ is the board's
## folder; this file is the copy the tutorial loads, the old builder is retired). Every slide starts
## on the spawn; the drives from it to the ramp and the rails are in test_practice_session.gd.

const PATH := "res://data/level/practice_playground.json"
const Rails := preload("res://scripts/level/rails.gd")

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


func test_every_slide_starts_on_the_spawn_a_car_can_stand_on() -> void:
	# T-574 (the board): one start for every slide, the level's spawn; no per-slide start points.
	assert_false(data.has("start_points"), "no per-slide start points")
	var spawn := Vector2(data.spawn.x, data.spawn.y)
	assert_eq(LevelSpawn.problem(data, spawn), "", "a car can stand on the spawn")
	_run()
	assert_eq(run.car.model.get_position(), spawn)


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


