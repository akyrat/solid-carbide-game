extends GutTest
## Task T-121: drift smoke. While the car drifts, puffs come off its two rear
## tyres, stay where they were left in the world, grow then shrink and pop
## out within their lifetime; the number of puffs is capped. Drawn with the
## car: over the ground, marks and boulders, under the HUD, and covered by a
## building that covers the car.

const SmokeScene := preload("res://scenes/driving/drift_smoke.tscn")
const MarksScene := preload("res://scenes/driving/drift_marks.tscn")
const RunScene := preload("res://scenes/run/run.tscn")
const PrototypeScene := preload("res://scenes/drift_prototype/drift_prototype.tscn")
const GameScene := preload("res://scenes/game/game.tscn")
const HudScript := preload("res://scripts/hud/hud.gd")
const MvpMap := preload("res://scripts/level/mvp_map.gd")
const TEST_PATH := "user://test_settings_t121.cfg"

const W_ONLY := [true, false, 0.0]
const W_AND_D := [true, false, -1.0]
const W_AND_A := [true, false, 1.0]
const NOTHING := [false, false, 0.0]

## T-034's test spots: the block south of the gravel centre, a road point
## behind it (hidden by it on screen), and the open centre.
const BLOCK := Rect2(12, 66, 30, 30)
const BEHIND := Vector2(27, 60)
const OPEN := Vector2.ZERO


func after_each() -> void:
	get_tree().paused = false


func _smoke() -> Node2D:
	var s: Node2D = SmokeScene.instantiate()
	add_child_autofree(s)
	s.set_process(false)  # tests move time by hand with advance()
	return s


func _run() -> Node2D:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.drift_smoke.set_process(false)
	return run


## Drives `car` for `steps` physics steps with the given input, by hand.
## With `smoke`, time moves on by one physics step after each step.
func _drive(car: CharacterBody2D, input: Array, steps: int, smoke: Node2D = null) -> void:
	car.use_keyboard = false
	car.scripted_input = input
	for i in steps:
		car.physics_step()
		if smoke != null:
			smoke.advance(car.model.dt)


func _tyres_seen(smoke: Node2D) -> Array:
	var seen: Array = []
	for p in smoke.puffs():
		if not seen.has(p.tyre):
			seen.append(p.tyre)
	seen.sort()
	return seen


# --- When smoke is made ----------------------------------------------------

func test_smoke_comes_off_both_rear_tyres_while_the_car_drifts() -> void:
	var run := _run()
	var smoke: Node2D = run.drift_smoke
	_drive(run.car, W_AND_D, 40, smoke)
	assert_true(run.car.model.is_drifting)
	assert_gt(smoke.puff_count(), 4)
	assert_eq(_tyres_seen(smoke), [0, 1], "puffs from the left and the right rear tyre")
	# Run one more step and check the puffs made in it sit on the rear tyres.
	smoke.puffs_per_second = 500.0
	smoke.max_puffs = 1000
	var before: int = smoke.puffs_made
	_drive(run.car, W_AND_D, 1)
	var made: int = smoke.puffs_made - before
	assert_gt(made, 2)
	var tyres: Array = run.drift_marks.rear_tyres(run.car.model.get_position(), run.car.model.rotation)
	var newest: Array = smoke.puffs().slice(smoke.puff_count() - made)
	var per_tyre := [0, 0]
	for p in newest:
		per_tyre[p.tyre] += 1
		var want: Vector2 = tyres[p.tyre] * smoke.PX_PER_UNIT
		assert_lt(p.world.distance_to(want), smoke.spawn_jitter_units * smoke.PX_PER_UNIT + 0.001,
			"on the drift marks' rear tyre place")
	assert_gt(per_tyre[0], 0)
	assert_gt(per_tyre[1], 0)


func test_no_smoke_while_driving_straight() -> void:
	var run := _run()
	_drive(run.car, W_ONLY, 100, run.drift_smoke)
	assert_gt(run.car.model.get_velocity().length(), 5.0, "the car is moving")
	assert_false(run.car.model.is_drifting)
	assert_eq(run.drift_smoke.puff_count(), 0)
	assert_eq(run.drift_smoke.puffs_made, 0)


func test_no_smoke_while_standing_still() -> void:
	var run := _run()
	_drive(run.car, NOTHING, 50, run.drift_smoke)
	_drive(run.car, [false, false, 1.0], 50, run.drift_smoke)  # steering on the spot is not a drift
	assert_false(run.car.model.is_drifting)
	assert_eq(run.drift_smoke.puffs_made, 0)


func test_smoke_stops_when_the_drift_stops() -> void:
	var run := _run()
	var smoke: Node2D = run.drift_smoke
	_drive(run.car, W_AND_D, 30, smoke)
	assert_gt(smoke.puffs_made, 0)
	_drive(run.car, W_ONLY, 10, smoke)
	assert_false(run.car.model.is_drifting)
	var made: int = smoke.puffs_made
	_drive(run.car, W_ONLY, 60, smoke)
	assert_eq(smoke.puffs_made, made, "nothing made while straight")
	assert_eq(smoke.puff_count(), 0, "the drift's puffs have all popped")


func test_the_smoke_uses_the_drift_marks_tyre_places() -> void:
	var s := _smoke()
	var marks: Node2D = MarksScene.instantiate()
	add_child_autofree(marks)
	# Without marks it uses its own copy of the same geometry.
	var own: Array = s.rear_tyres(Vector2(10, 5), 0.7)
	var theirs: Array = marks.rear_tyres(Vector2(10, 5), 0.7)
	for t in 2:
		assert_almost_eq(own[t].distance_to(theirs[t]), 0.0, 0.0001)
	marks.rear_axle_units = 1.2
	s.tyre_source = marks
	theirs = marks.rear_tyres(Vector2(10, 5), 0.7)
	own = s.rear_tyres(Vector2(10, 5), 0.7)
	for t in 2:
		assert_almost_eq(own[t].distance_to(theirs[t]), 0.0, 0.0001, "follows the marks")


# --- Where puffs stay, how long they live, the cap -------------------------

func test_puffs_stay_where_they_were_left_in_the_world() -> void:
	var run := _run()
	var smoke: Node2D = run.drift_smoke
	smoke.lifetime = 100.0  # keep them all for this test
	smoke.lifetime_randomness = 0.0
	smoke.max_puffs = 1000
	_drive(run.car, W_AND_D, 20, smoke)
	var first: Array = smoke.puffs()
	assert_gt(first.size(), 2)
	var car_before: Vector2 = run.car.model.get_position()
	_drive(run.car, W_ONLY, 100, smoke)  # drive away
	assert_gt(run.car.model.get_position().distance_to(car_before), 5.0, "the car has moved on")
	var later: Array = smoke.puffs()
	var max_drift: float = (smoke.rise_speed + smoke.spread_speed)
	for i in first.size():
		assert_eq(later[i].world, first[i].world, "left in the world, not moving with the car")
		var base: Vector2 = run.ISO_TRANSFORM * Vector2(later[i].world)
		var drift: float = Vector2(later[i].drawn).distance_to(base)
		assert_lt(drift, max_drift * later[i].age + 0.01, "only drifts a little, by itself")


func test_puffs_grow_then_shrink_and_pop_out_within_their_lifetime() -> void:
	var s := _smoke()
	s.lifetime_randomness = 0.0
	s.emit_step(true, Vector2.ZERO, 0.0, 0.02)  # one puff per tyre
	s.emit_step(false, Vector2.ZERO, 0.0, 0.02)
	assert_eq(s.puff_count(), 2)
	var life: float = s.lifetime
	var sizes: Array = []
	for k in [0.0, 0.5, 0.99]:
		s.advance(k * life - s.time)
		sizes.append(s.puffs()[0].size)
	assert_gt(sizes[1], sizes[0], "grows")
	assert_lt(sizes[2], sizes[1], "then shrinks")
	assert_gt(sizes[2], 0.0, "still there just before its end")
	s.advance(life - s.time + 0.001)
	assert_eq(s.puff_count(), 0, "popped out at the end of its life")


func test_every_puff_ends_within_its_lifetime() -> void:
	var run := _run()
	var smoke: Node2D = run.drift_smoke
	_drive(run.car, W_AND_D, 100, smoke)
	var longest: float = smoke.lifetime * (1.0 + smoke.lifetime_randomness)
	for p in smoke.puffs():
		assert_true(p.life <= longest + 0.0001, "life within the lifetime and its randomness")
		assert_true(p.age < p.life)
	_drive(run.car, W_ONLY, 1, smoke)
	smoke.advance(longest + 0.001)
	assert_eq(smoke.puff_count(), 0, "all gone once the longest life has passed")


## T-073 round 2 (the board's playtest): in a steady full-circle drift the live
## smoke trail spans about 20 degrees of the circle, not half of it.
const TRAIL_ARC_DEGREES := 20.0
const TRAIL_ARC_TOLERANCE := 5.0


## The average angle (degrees) of the circle that the live puffs of one tyre
## span, from the oldest to the newest, seen from the circle's centre, over
## `samples` physics steps. The centre is fitted from three points of the car's
## own path (about one circle).
func _trail_arc_degrees(run: Node2D, smoke: Node2D, samples: int) -> float:
	var car: CharacterBody2D = run.car
	var path: Array = []
	var puff_sets: Array = []
	for i in samples:
		car.physics_step()
		smoke.advance(car.model.dt)
		path.append(car.model.get_position())
		var ws: Array = []
		for p in smoke.puffs():
			if p.tyre == 0:
				ws.append(Vector2(p.world) / car.PX_PER_UNIT)
		puff_sets.append(ws)  # oldest first
	var a: Vector2 = path[0]
	var b: Vector2 = path[path.size() / 2]
	var c: Vector2 = path[path.size() - 1]
	var d := 2.0 * (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y))
	var centre := Vector2(
		(a.length_squared() * (b.y - c.y) + b.length_squared() * (c.y - a.y) + c.length_squared() * (a.y - b.y)) / d,
		(a.length_squared() * (c.x - b.x) + b.length_squared() * (a.x - c.x) + c.length_squared() * (b.x - a.x)) / d)
	var total := 0.0
	var counted := 0
	for ws in puff_sets:
		if ws.size() < 2:
			continue
		var first: float = (ws[0] - centre).angle()
		var last: float = (ws[ws.size() - 1] - centre).angle()
		total += absf(rad_to_deg(wrapf(last - first, -PI, PI)))
		counted += 1
	return total / maxf(1.0, counted)


func test_the_smoke_trail_spans_about_twenty_degrees_in_a_full_circle_drift() -> void:
	var run := _run()
	var smoke: Node2D = run.drift_smoke
	_drive(run.car, W_AND_D, 250, smoke)  # into the steady drift
	var arc := _trail_arc_degrees(run, smoke, 300)
	gut.p("measured trail arc: %.1f degrees (lifetime %.3f s)" % [arc, smoke.lifetime])
	assert_almost_eq(arc, TRAIL_ARC_DEGREES, TRAIL_ARC_TOLERANCE, "the trail covers about 20 degrees of the circle")
	assert_lt(smoke.lifetime, 0.2, "a short life, so a short trail")


func test_a_long_drift_never_goes_over_the_cap() -> void:
	var run := _run()
	var smoke: Node2D = run.drift_smoke
	var cap: int = smoke.max_puffs
	var steps := int(30.0 / run.car.model.dt)  # 30 seconds of drift
	var most := 0
	run.car.use_keyboard = false
	run.car.scripted_input = W_AND_D
	for i in steps:
		run.car.physics_step()
		smoke.advance(run.car.model.dt)
		most = maxi(most, smoke.puff_count())
		assert_true(smoke.puff_count() <= cap, "step %d: %d puffs over the cap %d" % [i, smoke.puff_count(), cap])
		if smoke.puff_count() > cap:
			break
	# A steady drift holds about 2 tyres x rate x life puffs (T-073: a short life, so well under the cap).
	assert_gt(most, int(smoke.puffs_per_second * smoke.lifetime), "a steady drift keeps a good amount of smoke")
	# With time standing still nothing pops, so only the cap holds the count.
	for i in 200:
		run.car.physics_step()
		assert_true(smoke.puff_count() <= cap)
	assert_eq(smoke.puff_count(), cap, "reaches the cap and holds it")


func test_smoke_does_not_age_while_paused() -> void:
	var s: Node2D = SmokeScene.instantiate()
	add_child_autofree(s)
	assert_eq(s.process_mode, Node.PROCESS_MODE_INHERIT, "pausable")
	s.emit_step(true, Vector2.ZERO, 0.0, 0.02)
	get_tree().paused = true
	var t: float = s.time
	await wait_process_frames(3)
	assert_eq(s.time, t)
	get_tree().paused = false
	await wait_process_frames(3)
	assert_gt(s.time, t)


# --- Drawing, look and settings --------------------------------------------

func test_in_the_run_smoke_is_drawn_with_the_car_over_the_map_and_under_the_hud() -> void:
	var run := _run()
	var smoke: Node2D = run.drift_smoke
	var map: Node2D = run.map
	assert_eq(smoke.get_parent(), run.view_root, "in the car's drawing")
	assert_lt(smoke.get_index(), run.car_sprite.get_index(), "under the car sprite")
	assert_gt(run.view_root.get_index(), map.get_index(), "drawn after the map")
	assert_eq(smoke.z_index, 0)
	assert_true(smoke.z_as_relative)
	assert_false(smoke.top_level)
	assert_eq(smoke.transform, Transform2D.IDENTITY)
	assert_eq(smoke.view_transform, run.ISO_TRANSFORM, "puffs drawn through the run's projection")
	# Ground, marks and boulders are in the map's drawing at z 0; the car's
	# drawing (and so the smoke) is always over them.
	var marks: Node2D = run.drift_marks
	assert_eq(marks.z_index, 0)
	assert_eq(map.boulders_draw.z_index, 0)
	assert_eq(map.ground_draw.z_index, 0)
	assert_gt(run.view_root.z_index, 0, "over the ground, the marks and the boulders")
	# The HUD is a canvas layer over the whole world.
	assert_true(run.hud is CanvasLayer)
	assert_gt(run.hud.layer, 0, "under the HUD")
	assert_false(smoke.get_parent() is CanvasLayer)


func test_a_building_that_covers_the_car_also_covers_the_smoke() -> void:
	var run := _run()
	var map: Node2D = run.map
	var block: Node2D = null
	for b in map.buildings:
		if b.footprint == BLOCK:
			block = b
	assert_not_null(block)
	run.car.use_keyboard = false
	run.car.scripted_input = NOTHING
	run.car.model.x = BEHIND.x
	run.car.model.y = BEHIND.y
	run.car._sync_from_model()
	run.sync_view()
	assert_lt(run.view_root.z_index, block.z_index, "the car is under the block")
	var smoke: Node2D = run.drift_smoke
	assert_eq(smoke.get_parent(), run.view_root)
	assert_eq(smoke.z_index, 0)
	assert_lt(run.view_root.z_index + smoke.z_index, block.z_index, "so is its smoke")
	run.car.model.x = OPEN.x
	run.car.model.y = OPEN.y
	run.car._sync_from_model()
	run.sync_view()
	assert_gt(run.view_root.z_index + smoke.z_index, block.z_index, "in the open, over it")


func test_in_the_prototype_smoke_is_over_the_room_and_under_the_car() -> void:
	var proto: Node2D = PrototypeScene.instantiate()
	add_child_autofree(proto)
	var smoke: Node2D = proto.drift_smoke
	assert_eq(smoke.get_parent(), proto.view_root)
	assert_gt(smoke.get_index(), proto.ground.get_index(), "over the ground")
	assert_gt(smoke.get_index(), proto.drift_marks.get_index(), "over the marks")
	assert_gt(smoke.get_index(), proto.test_room.get_index(), "over the walls and boulder")
	assert_lt(smoke.get_index(), proto.car_sprite.get_index(), "under the car")
	assert_eq(smoke.view_transform, proto.ISO_TRANSFORM)
	proto.set_view("flat")
	assert_eq(smoke.view_transform, Transform2D.IDENTITY)
	proto.set_view("iso")
	assert_eq(smoke.view_transform, proto.ISO_TRANSFORM)


func test_the_prototype_makes_smoke_while_drifting() -> void:
	var proto: Node2D = PrototypeScene.instantiate()
	add_child_autofree(proto)
	proto.drift_smoke.set_process(false)
	_drive(proto.car, W_ONLY, 20)
	assert_eq(proto.drift_smoke.puffs_made, 0)
	_drive(proto.car, W_AND_A, 20)
	assert_gt(proto.drift_smoke.puff_count(), 0)
	assert_eq(_tyres_seen(proto.drift_smoke), [0, 1])


func test_puff_art_is_nearest_opaque_cool_grey_violet_and_not_redgull_red() -> void:
	var s := _smoke()
	assert_eq(s.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "nearest filtering")
	assert_eq(s.puff_color.a, 1.0, "no fading tint")
	assert_eq(s.modulate.a, 1.0)
	assert_eq(s.self_modulate.a, 1.0)
	assert_null(s.material, "no shader smoothing the pixels")
	var img: Image = s.puff_texture.get_image()
	assert_true(img.get_width() <= 32 and img.get_height() <= 32, "a small sprite")
	var red: Color = HudScript.HEART_COLOR
	var opaque := 0
	for y in img.get_height():
		for x in img.get_width():
			var c: Color = img.get_pixel(x, y) * s.puff_color
			assert_true(c.a == 0.0 or c.a == 1.0, "no semi-transparent pixels")
			if c.a == 0.0:
				continue
			opaque += 1
			assert_gt(c.get_luminance(), 0.2, "light enough to read on the dark ground")
			assert_true(c.b > c.r and c.b > c.g, "violet-tinted grey (T-073 art)")
			assert_lt(maxf(c.r, maxf(c.g, c.b)) - minf(c.r, minf(c.g, c.b)), 0.2, "greyish")
			var d := Vector3(c.r - red.r, c.g - red.g, c.b - red.b).length()
			assert_gt(d, 0.5, "far from Redgull red")
			assert_false(c.r > c.g + 0.1 and c.r > c.b + 0.1, "not any red")
	assert_gt(opaque, 0)


func test_settings_live_in_the_scene() -> void:
	var state := SmokeScene.get_state()
	var names: Array = []
	for i in state.get_node_property_count(0):
		names.append(state.get_node_property_name(0, i))
	for setting in ["texture_filter", "puff_texture", "puff_color", "puff_scale", "size_curve",
			"lifetime", "lifetime_randomness", "puffs_per_second", "max_puffs", "rise_speed",
			"spread_speed", "spawn_jitter_units"]:
		assert_true(names.has(setting), "%s is set in the scene" % setting)
	var s := _smoke()
	assert_not_null(s.size_curve)
	assert_gt(s.max_puffs, 0)
	# A steady drift needs about 2 tyres x rate x average life puffs: the cap
	# sits at or above that, so it is a safety net more than a limit.
	assert_true(s.max_puffs >= int(2.0 * s.puffs_per_second * s.lifetime), "room for a steady drift")


# --- Runs ----------------------------------------------------------------

func test_a_new_run_starts_with_no_smoke() -> void:
	var run := _run()
	_drive(run.car, W_AND_D, 30)
	assert_gt(run.drift_smoke.puff_count(), 0)
	run.start_run()
	assert_eq(run.drift_smoke.puff_count(), 0)
	_drive(run.car, W_AND_D, 30)
	assert_eq(_tyres_seen(run.drift_smoke), [0, 1], "the new car makes smoke")
	assert_eq(run.drift_smoke.tyre_source, run.drift_marks, "from the new map's marks' tyre places")
	await wait_process_frames(1)  # let the old map and car be freed


func test_smoke_in_a_run_started_from_the_main_menu() -> void:
	GameSettings.path = TEST_PATH
	DirAccess.remove_absolute(TEST_PATH)
	var game = GameScene.instantiate()
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()
	await wait_process_frames(1)
	var run: Node2D = game.run
	assert_not_null(run.drift_smoke)
	run.drift_smoke.set_process(false)
	_drive(run.car, W_ONLY, 20)
	assert_eq(run.drift_smoke.puffs_made, 0)
	_drive(run.car, W_AND_D, 30)
	assert_eq(_tyres_seen(run.drift_smoke), [0, 1])
	DirAccess.remove_absolute(TEST_PATH)
	GameSettings.path = GameSettings.DEFAULT_PATH
