extends GutTest
## Task T-481: scripted benchmark of a bricks landing in a real run: the car drops
## (a real jump off the ground), the trick popups and the combo hear the landing,
## and a crowd of real minions stands around the car. Times (ms) are printed.

const RunScene := preload("res://scenes/run/run.tscn")
const Bricks := preload("res://scripts/weapons/bricks.gd")
const DT := 0.02

var run: Node2D
var rack: Node


func before_each() -> void:
	Bricks.playtest_override = 0
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.car.use_keyboard = false
	run.car.scripted_input = [false, false, 0.0]
	rack = run.weapons
	rack.upgrade("bricks")


func after_each() -> void:
	Bricks.playtest_override = -1
	get_tree().paused = false


func _drop(lift: float) -> Dictionary:
	var car = run.car
	car.height_model.height = car.height + lift
	car.height_model.airborne = true
	var worst_car := 0.0
	var worst_bricks := 0.0
	var steps := 0
	while car.airborne and steps < 500:
		var t0 := Time.get_ticks_usec()
		car.physics_step()
		var t1 := Time.get_ticks_usec()
		rack.bricks.step(DT)
		var t2 := Time.get_ticks_usec()
		worst_car = maxf(worst_car, (t1 - t0) / 1000.0)
		worst_bricks = maxf(worst_bricks, (t2 - t1) / 1000.0)
		steps += 1
	var t1 := Time.get_ticks_usec()
	rack.bricks.step(DT)
	worst_bricks = maxf(worst_bricks, (Time.get_ticks_usec() - t1) / 1000.0)
	return {"car": worst_car, "bricks": worst_bricks, "steps": steps}


func test_bench_landings_with_a_crowd() -> void:
	var worst_car := 0.0
	var worst_bricks := 0.0
	for round in 6:
		# Spawn a crowd of real minions around the car by running the spawner a while.
		run.minions.enabled = true
		for i in 100:
			run.minions.step(DT) if run.minions.has_method("step") else null
			await wait_physics_frames(1)
		var r := _drop(3.0 + round)
		worst_car = maxf(worst_car, r.car)
		worst_bricks = maxf(worst_bricks, r.bricks)
		print("BENCH round %d: car.physics_step %.2f ms, bricks.step %.2f ms (waves %d, minions %d)" % [
			round, r.car, r.bricks, rack.bricks.waves, get_tree().get_nodes_in_group("minions").size()])
	print("BENCH worst car %.2f bricks %.2f" % [worst_car, worst_bricks])
	assert_gt(rack.bricks.waves, 0)
	# Before T-481: car.physics_step 12 to 14 ms and bricks.step 5 ms on a landing. Headless
	# timings are noisy, so the limits are loose; the recorder run gives the strict numbers.
	assert_lt(worst_bricks, 3.0, "a landing's wave costs next to nothing")
	assert_lt(worst_car, 5.0, "a landing's trick popup is not baked in the physics step")


func test_the_wave_sheet_is_kept_between_landings() -> void:
	var r: float = rack.bricks.radius()
	var a = Bricks.BricksWave.sheet_for(r)
	var b = Bricks.BricksWave.sheet_for(r)
	assert_not_null(a, "the sheet for tier 1's radius exists")
	assert_same(a, b, "the same texture, not loaded again for every wave")
	rack.bricks.send_wave(rack.bricks.car_units())
	assert_same(rack.bricks.last_wave.sheet, a)


func test_a_landing_trick_popup_needs_no_bake_for_its_size() -> void:
	var Art = TrickPopupArt
	for text in ["HANG TIME! +12.3K", "AIR 360!", "THREAD THE NEEDLE! +1.5K"]:
		for viewers in [false, true]:
			var plain := Vector2i(Art.texture(text, "normal", 0, 0, viewers).get_size())
			assert_eq(Art.plain_size(text, "normal", viewers), plain, "size of '%s' (viewers %s)" % [text, viewers])

