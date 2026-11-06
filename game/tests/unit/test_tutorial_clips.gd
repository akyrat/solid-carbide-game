extends GutTest
## Task T-483: the tutorial clips' fixtures (tests/fixtures/tutorial_clip_*.tscn, tutorial_clip_demo.gd).
## The four scenes load with their script and a non-empty drive; the ramp clip's own ground
## (tests/fixtures/data/tutorial_ramp.json) is a valid ramp up to a short rooftop; and the real car,
## driven the way the ramp clip drives it (W held along the ramp, W + A held in the air), takes off
## from the ramp's top with more airtime than the airtime trick's minimum and turns at least 180
## degrees in the air.

const CarScript := preload("res://scripts/driving/car.gd")
const GroundHeightScript := preload("res://scripts/level/ground_height.gd")
const RAMP_DATA := "res://tests/fixtures/data/tutorial_ramp.json"
const CLIPS := ["drift", "long_drift", "alt_drift", "ramp_jump", "three_sixty", "air_three_sixty", "airtime", "thread_the_needle",
	"reverse_drift", "aura", "rail_grind"]


func test_every_clip_scene_loads_with_a_drive() -> void:
	for clip in CLIPS:
		var scene: PackedScene = load("res://tests/fixtures/tutorial_clip_%s.tscn" % clip)
		assert_not_null(scene, clip)
		var node: Node = scene.instantiate()
		if clip == "rail_grind":
			# T-543: its own script (a run on the game's map), not the demo's parts.
			assert_gt(node.hop_step, 0, clip)
			node.free()
			continue
		assert_eq(node.clip, clip)
		assert_gt(node.parts.size(), 0, clip)
		assert_gt(node.zoom, 0.0, clip)
		node.free()


func test_the_drift_clip_is_zoomed_out_against_the_runs_camera() -> void:
	var node: Node = load("res://tests/fixtures/tutorial_clip_drift.tscn").instantiate()
	assert_gt(node.zoom, 14.4 * 1.5)
	assert_true(node.fixed_camera, "the camera holds still so the path reads")
	node.free()


func test_the_ramp_ground_is_a_ramp_up_to_a_short_rooftop() -> void:
	var g = GroundHeightScript.from_file(RAMP_DATA)
	assert_eq(g.error, "")
	assert_eq(g.platforms.size(), 1)
	assert_eq(g.ramps.size(), 1)
	assert_eq(g.platforms[0].rect.size.x, 8.0)
	assert_eq(g.ramps[0].top_height, 3.0)


func test_the_ramp_drive_flies_and_spins_at_least_a_half_turn() -> void:
	var car = CarScript.new()
	add_child_autofree(car)
	var g = GroundHeightScript.from_file(RAMP_DATA)
	car.model.set_position(Vector2(48.0, 0.0))
	car.model.rotation = PI
	car._sync_from_model()
	car.ground = g
	car.use_keyboard = false
	car.scripted_input = [true, false, 0.0]
	var air_steps := 0
	var turned := 0.0
	var took_off_from_ramp := []
	car.height_model.took_off.connect(func(from_ramp: bool, _vz: float) -> void: took_off_from_ramp.append(from_ramp))
	var before: float = car.model.rotation
	for i in 600:
		if car.airborne:
			car.scripted_input = [true, false, 1.0]
		car.physics_step()
		if car.airborne:
			air_steps += 1
			turned += wrapf(car.model.rotation - before, -PI, PI)
		before = car.model.rotation
		if air_steps > 0 and not car.airborne:
			break
	assert_eq(took_off_from_ramp, [true], "one takeoff, off the ramp's top")
	assert_gt(air_steps * car.model.dt, car.tricks.airtime_min_seconds, "more airtime than the airtime trick needs")
	assert_gt(rad_to_deg(absf(turned)), 180.0, "a half turn or more in the air")


func test_the_needle_clip_has_two_boulders_with_a_gap_and_the_air_clip_a_taller_ramp() -> void:
	var node: Node = load("res://tests/fixtures/tutorial_clip_thread_the_needle.tscn").instantiate()
	assert_eq(node.needle_boulders.size(), 2)
	var gap: float = node.needle_boulders[0].distance_to(node.needle_boulders[1]) - node.needle_diameter
	assert_gt(gap, 3.0, "a gap the car passes without touching")
	node.free()
	var air: Node = load("res://tests/fixtures/tutorial_clip_air_three_sixty.tscn").instantiate()
	assert_eq(air.clip, "air_three_sixty")
	var g = GroundHeightScript.from_file(air.ramp_data)
	assert_not_null(g)
	assert_gt(float(g.ramps[0].top_height), 3.0)
	air.free()


func test_the_clips_keys_come_from_the_scripted_input() -> void:
	var node: Node = load("res://tests/fixtures/tutorial_clip_alt_drift.tscn").instantiate()
	node.car = CarScript.new()
	node.car.scripted_input = [true, false, 1.0]
	assert_eq(node._keys_now(), "WA")
	node.car.scripted_input = [false, true, 1.0]
	assert_eq(node._keys_now(), "AS")
	node.car.scripted_input = [true, false, -1.0]
	assert_eq(node._keys_now(), "WD")
	node.car.scripted_input = [false, false, 0.0]
	assert_eq(node._keys_now(), "")
	node.car.free()
	node.free()


## T-543: each new clip has its GIF, its sheet and a record saying the detector's trick fired and nothing unwanted did.
func test_the_three_new_clips_were_recorded_with_their_tricks() -> void:
	for pair in [["reverse_drift", "reverse_drift"], ["aura", "aura"], ["rail_grind", "rail_grind"]]:
		var clip: String = pair[0]
		assert_true(FileAccess.file_exists("res://art/tutorial/clips/%s_sheet.png" % clip), clip)
		assert_true(FileAccess.file_exists("res://art/tutorial/clips/%s_sheet.json" % clip), clip)
		var rec = JSON.parse_string(FileAccess.get_file_as_string("res://art/tutorial/clips/%s.json" % clip))
		assert_eq(rec["task"], "T-543")
		assert_eq(rec["problems"], [], clip)
		assert_true(" | ".join(rec["tricks"]).contains(pair[1]), clip)
		assert_lte(int(rec["bytes"]), 1500000, clip)
