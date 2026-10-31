extends GutTest
## Task T-451: threading the needle flashes the two paired obstacles and their dashed line, and only
## the pair just threaded (a chained row flashes one gap at a time); going round flashes nothing;
## the flash ends after NeedleFlash.DURATION.

const RunScene := preload("res://scenes/run/run.tscn")
const DT := 0.02


func _layout() -> Dictionary:
	var d := LevelDocument.new_level_data("T-451 needle")
	d.pattern_copies = [
		{"id": "boulder-1", "boulders": [{"x": -3.0, "y": -40.0, "diameter": 3.0, "variant": "a"}]},
		{"id": "boulder-2", "boulders": [{"x": 3.0, "y": -40.0, "diameter": 3.0, "variant": "b"}]},
	]
	d["pairs"] = [{"id": "pair-1", "a": "boulder-1", "b": "boulder-2"}]
	return d


func _chain_layout() -> Dictionary:
	var d := LevelDocument.new_level_data("T-451 chain")
	d.pattern_copies = [
		{"id": "boulder-1", "boulders": [{"x": -3.0, "y": -40.0, "diameter": 3.0, "variant": "a"}]},
		{"id": "boulder-2", "boulders": [{"x": 3.0, "y": -46.0, "diameter": 3.0, "variant": "b"}]},
		{"id": "boulder-3", "boulders": [{"x": -3.0, "y": -52.0, "diameter": 3.0, "variant": "a"}]},
		{"id": "boulder-4", "boulders": [{"x": 3.0, "y": -58.0, "diameter": 3.0, "variant": "b"}]},
	]
	d["pairs"] = [
		{"id": "pair-1", "a": "boulder-1", "b": "boulder-2"},
		{"id": "pair-2", "a": "boulder-2", "b": "boulder-3"},
		{"id": "pair-3", "a": "boulder-3", "b": "boulder-4"},
	]
	return d


func _run_on(layout: Dictionary) -> Node2D:
	var path := RunPaths.file("t451_run_level.json")
	assert_eq(LevelStore.save_level(path, layout), OK)
	var run: Node2D = RunScene.instantiate()
	run.layout_path = path
	add_child_autofree(run)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	return run


## Starts the car at `start` heading north with throttle, steps until it is north of `stop_y`.
func _drive_north(run: Node2D, start: Vector2, stop_y: float) -> void:
	var car = run.car
	car.model.set_position(start)
	car.model.rotation = -PI / 2.0
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	run.needle.last_position = null
	car.scripted_input = [true, false, 0.0]
	for i in 600:
		car.physics_step()
		if car.model.get_position().y < stop_y:
			break


## Steps the car (coasting) until `pair` flashes, at most 60 steps.
func _step_until_flash(run: Node2D, pair: String) -> bool:
	run.car.scripted_input = [false, false, 0.0]
	for i in 60:
		if run.needle_flash.is_flashing(pair):
			return true
		run.car.physics_step()
	return run.needle_flash.is_flashing(pair)


## How far the sprite is mixed towards white (0 at rest: no flash material).
func _brightness(sp) -> float:
	if sp.material == null:
		return 0.0
	return float((sp.material as ShaderMaterial).get_shader_parameter("flash"))


func test_the_pulse_is_bright_at_the_start_and_ends_at_rest() -> void:
	assert_almost_eq(NeedleFlash.intensity_at(0.0), 1.0, 0.0001)
	assert_almost_eq(NeedleFlash.intensity_at(NeedleFlash.DURATION / NeedleFlash.PULSES / 2.0), 0.0, 0.0001)
	assert_eq(NeedleFlash.intensity_at(NeedleFlash.DURATION), 0.0)
	assert_eq(NeedleFlash.intensity_at(-1.0), 0.0)


func test_threading_flashes_both_obstacles_and_the_line_then_stops() -> void:
	var run := _run_on(_layout())
	var fl: NeedleFlash = run.needle_flash
	assert_not_null(fl, "a level with pairs has the flash")
	var a = NeedleFlash.sprite_of(run.map, "boulder-1")
	var b = NeedleFlash.sprite_of(run.map, "boulder-2")
	assert_not_null(a)
	assert_not_null(b)
	var m = run.needle.markers["pair-1"]
	assert_false(fl.is_flashing("pair-1"))
	_drive_north(run, Vector2(0, -25), -43.5)
	assert_true(_step_until_flash(run, "pair-1"), "the flash starts on the step the trick pays")
	assert_gt(_brightness(a), 0.5, "obstacle A flashes")
	assert_gt(_brightness(b), 0.5, "obstacle B flashes")
	assert_gt(m.flash, 0.9, "the dashed line flashes")
	fl.advance(NeedleFlash.DURATION / 4.0)  # the pulse's low point
	assert_lt(_brightness(a), 0.05)
	fl.advance(NeedleFlash.DURATION)
	assert_false(fl.is_flashing("pair-1"), "it stops after the proposed time")
	assert_null(a.material)
	assert_null(b.material)
	assert_eq(m.flash, 0.0)


func test_a_chained_row_flashes_only_the_pair_just_threaded() -> void:
	var run := _run_on(_chain_layout())
	var fl: NeedleFlash = run.needle_flash
	_drive_north(run, Vector2(0, -25), -43.5)
	assert_true(_step_until_flash(run, "pair-1"))
	assert_false(fl.is_flashing("pair-2"))
	assert_false(fl.is_flashing("pair-3"))
	assert_gt(_brightness(NeedleFlash.sprite_of(run.map, "boulder-1")), 0.5)
	assert_gt(_brightness(NeedleFlash.sprite_of(run.map, "boulder-2")), 0.5)
	assert_eq(_brightness(NeedleFlash.sprite_of(run.map, "boulder-3")), 0.0, "the next gap's far obstacle is still")
	assert_eq(_brightness(NeedleFlash.sprite_of(run.map, "boulder-4")), 0.0)
	assert_eq(run.needle.markers["pair-2"].flash, 0.0, "the other gaps' lines are still")
	assert_eq(run.needle.markers["pair-3"].flash, 0.0)


func test_going_round_flashes_nothing() -> void:
	var run := _run_on(_layout())
	var fl: NeedleFlash = run.needle_flash
	# Beside the pair, x 8, well clear of the right boulder (x 3 +- 1.5).
	_drive_north(run, Vector2(8, -25), -50.0)
	run.car.scripted_input = [false, false, 0.0]
	for i in 60:
		run.car.physics_step()
		fl.advance(DT)
		assert_false(fl.is_flashing("pair-1"))
	assert_eq(_brightness(NeedleFlash.sprite_of(run.map, "boulder-1")), 0.0)
	assert_eq(run.needle.markers["pair-1"].flash, 0.0)


func test_a_touch_voids_the_pass_and_no_flash() -> void:
	var run := _run_on(_layout())
	_drive_north(run, Vector2(-3, -25), -45.0)  # straight into boulder-1
	run.car.scripted_input = [false, false, 0.0]
	for i in 60:
		run.car.physics_step()
	assert_false(run.needle_flash.is_flashing("pair-1"))


func test_a_level_without_pairs_has_no_flash() -> void:
	var run := _run_on(LevelDocument.new_level_data("T-451 none"))
	assert_null(run.needle_flash)
