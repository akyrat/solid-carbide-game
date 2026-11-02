extends GutTest
## Task T-498: what tier 8's widest wave costs, headless, in a real run with a crowd of
## real minions round the car (T-481's benchmark, at tier 8). Times (ms) are printed:
## the landing step (the inner ring's hits and the wave's setup: its sheet and strip
## record, read once and kept), the outer rings' steps, and whole frames while the
## wave is drawn. The limits are loose (headless timings are noisy); the board's
## recorder run gives the strict numbers.

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
	rack.gun.set_tier(0)
	rack.bricks.set_tier(8)


func after_each() -> void:
	Bricks.playtest_override = -1
	get_tree().paused = false


func _ms(t0: int) -> float:
	return (Time.get_ticks_usec() - t0) / 1000.0


func test_bench_widest_wave_landings_with_a_crowd() -> void:
	await _bench(8, 80)


## The same crowd at tier 7 (one ring of 8.4), for comparison only.
func test_bench_tier_7_for_comparison() -> void:
	await _bench(7, 80)


## The wave alone (no enemies): what the widest wave itself costs, sheet and drawing.
func test_bench_widest_wave_alone() -> void:
	await _bench(8, 0)
	assert_lt(_last_worst_landing, 5.0, "the wave's own setup costs next to nothing (sheet and record kept)")


## Tier 7's wave alone, for comparison only.
func test_bench_tier_7_alone() -> void:
	await _bench(7, 0)


var _last_worst_landing := 0.0


func _bench(tier: int, crowd: int) -> void:
	var b = rack.bricks
	b.set_tier(tier)
	var worst_landing := 0.0
	var first_landing := 0.0
	var worst_ring := 0.0
	var worst_frame := 0.0
	var frames_sum := 0.0
	var frames_n := 0
	for round_ in 4:
		# A crowd of real minions spread over the whole widest radius (about 80).
		run.minions.enabled = false
		var c: Vector2 = b.car_units()
		for i in crowd:
			var a := TAU * float(i) / float(crowd) * 7.0
			var d := 2.0 + 23.0 * float(i) / float(crowd)
			run.minions.spawn_minion_at(c + Vector2(cos(a), sin(a)) * d)
		await wait_physics_frames(2)
		var car = run.car
		car.height_model.height = car.height + 3.0
		car.height_model.airborne = true
		var steps := 0
		var landing := 0.0
		var waves_before: int = b.waves
		while b.waves == waves_before and steps < 500:
			car.physics_step()
			var t0 := Time.get_ticks_usec()
			b.step(DT)  # the landing is the step that sends the wave
			landing = _ms(t0)
			steps += 1
		var t0 := 0
		if round_ == 0:
			first_landing = landing
		worst_landing = maxf(worst_landing, landing)
		var w: Node2D = b.last_wave
		# The outer rings and the wave's drawing, frame by frame.
		while is_instance_valid(w) and not w.is_done():
			var pending: int = b.pending_rings.size()
			t0 = Time.get_ticks_usec()
			b.step(DT)
			var s := _ms(t0)
			if b.pending_rings.size() < pending:
				worst_ring = maxf(worst_ring, s)
			t0 = Time.get_ticks_usec()
			await get_tree().process_frame
			var f := _ms(t0)
			worst_frame = maxf(worst_frame, f)
			frames_sum += f
			frames_n += 1
		print("BENCH T-498 round %d: landing %.2f ms (waves %d, hits so far %d)" % [
			round_, landing, b.waves, b.hits])
	_last_worst_landing = worst_landing
	print("BENCH T-498 tier %d, %d minions: first landing %.2f ms, worst landing %.2f ms, worst outer ring step %.2f ms, worst frame while drawn %.2f ms, mean frame %.2f ms" % [
		tier, crowd, first_landing, worst_landing, worst_ring, worst_frame, frames_sum / maxf(frames_n, 1)])
	assert_eq(b.waves, 4)
