extends GutTest
## Task T-117: drift marks. While the car drifts, its two rear tyres leave
## marks on the ground; each piece stays `lifetime` seconds, fades as a whole
## and is removed; the number of segments is capped.

const MarksScene := preload("res://scenes/driving/drift_marks.tscn")
const RunScene := preload("res://scenes/run/run.tscn")
const PrototypeScene := preload("res://scenes/drift_prototype/drift_prototype.tscn")
const GameScene := preload("res://scenes/game/game.tscn")
const HudScript := preload("res://scripts/hud/hud.gd")
var TEST_PATH := RunPaths.file("test_settings_t117.cfg")

const W_ONLY := [true, false, 0.0]
const W_AND_D := [true, false, -1.0]
const W_AND_A := [true, false, 1.0]
const NOTHING := [false, false, 0.0]


func after_each() -> void:
	get_tree().paused = false


func _marks() -> Node2D:
	var m: Node2D = MarksScene.instantiate()
	add_child_autofree(m)
	m.set_process(false)  # tests move time by hand with advance()
	return m


## Drives `car` for `steps` physics steps with the given input, by hand.
func _drive(car: CharacterBody2D, input: Array, steps: int) -> void:
	car.use_keyboard = false
	car.scripted_input = input
	for i in steps:
		car.physics_step()


func _run() -> Node2D:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.drift_marks.set_process(false)
	return run


## Lays a drift of `steps` steps by hand, moving 0.5 units per step along +x.
func _lay_drift(m: Node2D, steps: int, from_x := 0.0) -> void:
	for i in steps:
		m.lay(true, Vector2(from_x + 0.5 * i, 0.0), 0.3)


# --- When marks are laid ---------------------------------------------------

func test_marks_are_laid_while_the_car_drifts_one_per_rear_tyre() -> void:
	var run := _run()
	var marks: Node2D = run.drift_marks
	_drive(run.car, W_AND_D, 40)
	assert_true(run.car.model.is_drifting)
	assert_true(marks.is_laying())
	var by_mark: Dictionary = marks.marks()
	assert_eq(by_mark.size(), 2, "one mark per rear tyre")
	var tyres: Array = []
	for k in by_mark:
		tyres.append(by_mark[k].tyre)
	tyres.sort()
	assert_eq(tyres, [0, 1], "a left and a right tyre")
	assert_gt(marks.segment_count(), 30)
	# Each mark's newest point is exactly where that rear tyre is now.
	var expected: Array = marks.rear_tyres(run.car.model.get_position(), run.car.model.rotation)
	for k in by_mark:
		var lines: Array = by_mark[k].lines
		var line: Line2D = lines[lines.size() - 1]
		var last := line.get_point_position(line.get_point_count() - 1)
		var want: Vector2 = expected[by_mark[k].tyre] * marks.PX_PER_UNIT
		assert_almost_eq(last.distance_to(want), 0.0, 0.001, "on the rear tyre")


func test_no_marks_while_driving_straight() -> void:
	var run := _run()
	_drive(run.car, W_ONLY, 100)
	assert_gt(run.car.model.get_velocity().length(), 5.0, "the car is moving")
	assert_false(run.car.model.is_drifting)
	assert_eq(run.drift_marks.pieces().size(), 0)
	assert_eq(run.drift_marks.segment_count(), 0)


func test_no_marks_while_standing_still() -> void:
	var run := _run()
	_drive(run.car, NOTHING, 50)
	_drive(run.car, [false, false, 1.0], 50)  # steering on the spot is not a drift
	assert_false(run.car.model.is_drifting)
	assert_eq(run.drift_marks.pieces().size(), 0)


func test_a_new_drift_starts_a_new_mark() -> void:
	var run := _run()
	var marks: Node2D = run.drift_marks
	_drive(run.car, W_AND_D, 30)
	var first: Array = marks.marks().keys()
	assert_eq(first.size(), 2)
	_drive(run.car, W_ONLY, 20)
	assert_false(marks.is_laying(), "straight driving ends the drift's marks")
	var after_straight: int = marks.segment_count()
	_drive(run.car, W_ONLY, 20)
	assert_eq(marks.segment_count(), after_straight, "nothing laid while straight")
	_drive(run.car, W_AND_A, 30)
	var keys: Array = marks.marks().keys()
	assert_eq(keys.size(), 4, "two marks per drift")
	for k in first:
		assert_true(keys.has(k), "the first drift's marks are kept")
	assert_eq(marks.marks_started, 4)


func test_rear_tyres_follow_the_heading_and_size() -> void:
	var m := _marks()
	# Nose along +x: tyres 0.9 units behind, 0.375 to each side.
	var t: Array = m.rear_tyres(Vector2(10, 5), 0.0)
	assert_almost_eq(t[0].distance_to(Vector2(9.1, 4.625)), 0.0, 0.0001, "left")
	assert_almost_eq(t[1].distance_to(Vector2(9.1, 5.375)), 0.0, 0.0001, "right")
	# Nose along -y (up): behind is +y, left is -x.
	t = m.rear_tyres(Vector2.ZERO, -PI / 2.0)
	assert_almost_eq(t[0].distance_to(Vector2(-0.375, 0.9)), 0.0, 0.0001)
	assert_almost_eq(t[1].distance_to(Vector2(0.375, 0.9)), 0.0, 0.0001)
	assert_lt(m.rear_axle_units, 1.5, "inside the car's 3-unit length")
	assert_lt(m.half_track_units, 0.5, "inside the car's 1-unit width")


# --- Lifetime, fade and cap ------------------------------------------------

func test_a_mark_stays_for_its_lifetime_then_fades_as_a_whole_and_goes() -> void:
	var m := _marks()
	_lay_drift(m, 10)
	m.lay(false, Vector2.ZERO, 0.0)
	var lines: Array = m.pieces()
	assert_eq(lines.size(), 2)
	m.advance(m.lifetime - 0.05)
	for l in lines:
		assert_eq(l.modulate.a, 1.0, "fully visible during its lifetime")
	m.advance(0.05 + m.fade_time * 0.5)
	for l in lines:
		assert_almost_eq(l.modulate.a, 0.5, 0.01, "half faded, as a whole (the node's modulate)")
		assert_eq(l.default_color.a, 1.0, "the colour itself stays opaque")
		assert_eq(l.self_modulate.a, 1.0)
		assert_null(l.gradient, "no per-point transparency")
	assert_eq(m.pieces().size(), 2, "still there while fading")
	m.advance(m.fade_time * 0.5 + 0.01)
	assert_eq(m.pieces().size(), 0, "removed after the fade")
	assert_eq(m.segment_count(), 0)
	await wait_process_frames(1)
	for l in lines:
		assert_false(is_instance_valid(l), "the nodes are freed")


func test_lifetime_counts_from_when_a_piece_was_laid() -> void:
	var m := _marks()
	_lay_drift(m, 3)
	m.advance(m.lifetime + m.fade_time + 5.0)  # still drifting: nothing ages yet
	assert_eq(m.pieces().size(), 2)
	m.lay(false, Vector2.ZERO, 0.0)
	m.advance(m.lifetime)
	assert_eq(m.pieces()[0].modulate.a, 1.0)


func test_a_long_drift_never_goes_over_the_cap() -> void:
	var run := _run()
	var marks: Node2D = run.drift_marks
	var cap: int = marks.max_segments
	var most := 0
	run.car.use_keyboard = false
	run.car.scripted_input = W_AND_D
	var steps := int(30.0 / run.car.model.dt)  # 30 seconds of drift
	for i in steps:
		run.car.physics_step()  # no aging (time not moved), so only the cap removes pieces
		most = maxi(most, marks.segment_count())
		assert_true(marks.segment_count() <= cap, "step %d: %d segments over the cap %d" % [i, marks.segment_count(), cap])
		if marks.segment_count() > cap:
			break
	assert_eq(most, cap, "a long drift reaches the cap")
	var counted := 0
	for l in marks.pieces():
		counted += l.get_point_count() - 1
	assert_eq(counted, marks.segment_count(), "the count matches the lines")


func test_the_cap_holds_with_only_pieces_being_laid() -> void:
	var m := _marks()
	m.max_segments = 10
	m.piece_segments = 1000  # pieces never close by themselves
	_lay_drift(m, 50)
	assert_eq(m.segment_count(), 10)
	var counted := 0
	for l in m.pieces():
		counted += l.get_point_count() - 1
	assert_eq(counted, 10)


func test_marks_stay_joined_across_pieces() -> void:
	var m := _marks()
	_lay_drift(m, int(m.piece_segments) * 3)
	var by_mark: Dictionary = m.marks()
	for k in by_mark:
		var lines: Array = by_mark[k].lines
		assert_gt(lines.size(), 2)
		for i in range(1, lines.size()):
			var prev: Line2D = lines[i - 1]
			assert_eq(lines[i].get_point_position(0), prev.get_point_position(prev.get_point_count() - 1))


func test_marks_do_not_age_while_paused() -> void:
	var m: Node2D = MarksScene.instantiate()
	add_child_autofree(m)
	assert_eq(m.process_mode, Node.PROCESS_MODE_INHERIT, "pausable")
	_lay_drift(m, 5)
	m.lay(false, Vector2.ZERO, 0.0)
	get_tree().paused = true
	var t: float = m.time
	await wait_process_frames(3)
	assert_eq(m.time, t)
	get_tree().paused = false
	await wait_process_frames(3)
	assert_gt(m.time, t)


# --- Drawing, look and settings --------------------------------------------

func test_in_the_run_marks_are_over_the_ground_and_under_buildings_and_the_car() -> void:
	var run := _run()
	var marks: Node2D = run.drift_marks
	var map: Node2D = run.map
	assert_eq(marks.get_parent(), map.view_root, "in the map's drawing, in the view's projection")
	assert_gt(marks.get_index(), map.ground_draw.get_index(), "over the ground")
	assert_gt(marks.get_index(), map.ground_tiles.get_index(), "over the ground tiles")
	assert_lt(marks.get_index(), map.buildings_draw.get_index(), "under the buildings")
	assert_lt(marks.get_index(), map.boulders_draw.get_index(), "under the boulders")
	assert_lt(map.get_index(), run.view_root.get_index(), "the car (View) is drawn after the map")
	assert_eq(marks.z_index, 0)
	assert_false(marks.top_level)
	assert_eq(marks.transform, Transform2D.IDENTITY, "uses the map view's isometric projection")
	assert_lt(map.get_index(), run.hud.get_index())


func test_in_the_prototype_marks_are_over_the_ground_and_under_the_car() -> void:
	var proto: Node2D = PrototypeScene.instantiate()
	add_child_autofree(proto)
	var marks: Node2D = proto.drift_marks
	assert_eq(marks.get_parent(), proto.view_root)
	assert_gt(marks.get_index(), proto.ground.get_index(), "over the ground")
	assert_lt(marks.get_index(), proto.test_room.get_index(), "under the walls and boulder")
	assert_lt(marks.get_index(), proto.car_sprite.get_index(), "under the car")
	assert_eq(marks.transform, proto.view_transform())
	proto.set_view("flat")
	assert_eq(marks.transform, Transform2D.IDENTITY)
	proto.set_view("iso")
	assert_eq(marks.transform, proto.ISO_TRANSFORM)


func test_the_prototype_lays_marks_while_drifting() -> void:
	var proto: Node2D = PrototypeScene.instantiate()
	add_child_autofree(proto)
	_drive(proto.car, W_ONLY, 20)
	assert_eq(proto.drift_marks.pieces().size(), 0)
	_drive(proto.car, W_AND_A, 20)
	assert_eq(proto.drift_marks.marks().size(), 2)


func test_placeholder_is_nearest_opaque_dark_and_not_redgull_red() -> void:
	var m := _marks()
	assert_eq(m.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	_lay_drift(m, 5)
	for l in m.pieces():
		assert_eq(l.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "nearest-neighbour")
		assert_false(l.antialiased)
		assert_eq(l.texture, m.mark_texture, "the scene's texture")
		assert_almost_eq(l.width, m.width_units * m.PX_PER_UNIT, 0.0001, "the scene's width")
		assert_eq(l.modulate.a, 1.0)
	assert_eq(m.mark_color.a, 1.0)
	var img: Image = m.mark_texture.get_image()
	assert_true(img.get_width() <= 8 and img.get_height() <= 8, "a tiny texture")
	var red: Color = HudScript.HEART_COLOR
	for y in img.get_height():
		for x in img.get_width():
			var c: Color = img.get_pixel(x, y) * m.mark_color
			# T-118: the final texture has a transparent background (the shoulders'
			# gaps), so a pixel is fully clear or fully opaque, never in between.
			assert_true(c.a == 0.0 or c.a == 1.0, "no semi-transparent pixels")
			if c.a == 0.0:
				continue
			assert_lt(c.get_luminance(), 0.2, "dark")
			var d := Vector3(c.r - red.r, c.g - red.g, c.b - red.b).length()
			assert_gt(d, 0.5, "far from Redgull red")
			assert_false(c.r > c.g + 0.1 and c.r > c.b + 0.1, "not any red")


func test_settings_live_in_the_scene() -> void:
	var state := MarksScene.get_state()
	var names: Array = []
	for i in state.get_node_property_count(0):
		names.append(state.get_node_property_name(0, i))
	for setting in ["mark_texture", "texture_mode", "mark_color", "width_units", "lifetime",
			"fade_time", "max_segments", "piece_segments", "rear_axle_units", "half_track_units"]:
		assert_true(names.has(setting), "%s is set in the scene" % setting)
	var m := _marks()
	assert_almost_eq(m.lifetime, 6.0, 0.0001, "about 6 seconds")
	assert_gt(m.fade_time, 0.0)
	assert_gt(m.max_segments, 2 * m.piece_segments, "room for both tyres' open pieces")


# --- Runs ----------------------------------------------------------------

func test_a_new_run_starts_with_no_marks() -> void:
	var run := _run()
	_drive(run.car, W_AND_D, 30)
	assert_gt(run.drift_marks.pieces().size(), 0)
	run.start_run()
	run.drift_marks.set_process(false)
	assert_eq(run.drift_marks.pieces().size(), 0)
	assert_eq(run.drift_marks.get_parent(), run.map.view_root)
	_drive(run.car, W_AND_D, 30)
	assert_eq(run.drift_marks.marks().size(), 2, "the new car lays on the new map")
	await wait_process_frames(1)  # let the old map and car be freed


func test_marks_in_a_run_started_from_the_main_menu() -> void:
	GameSettings.path = TEST_PATH
	DirAccess.remove_absolute(TEST_PATH)
	var game = GameScene.instantiate()
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()
	await wait_process_frames(1)
	var run: Node2D = game.run
	assert_not_null(run.drift_marks)
	_drive(run.car, W_ONLY, 20)
	assert_eq(run.drift_marks.pieces().size(), 0)
	_drive(run.car, W_AND_D, 30)
	assert_eq(run.drift_marks.marks().size(), 2)
	DirAccess.remove_absolute(TEST_PATH)
	GameSettings.path = GameSettings.DEFAULT_PATH
