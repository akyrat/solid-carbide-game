extends GutTest
## Task T-009: the PixelLab motion lines replace T-008's placeholder streaks on
## the same Car.boost signal, play behind the car, and end by themselves.

const RunScene := preload("res://scenes/run/run.tscn")
const BoostScript := preload("res://scripts/driving/boost_effect.gd")
const SHEET_PATH := "res://art/effects/boost_lines.png"
const W_ONLY := [true, false, 0.0]


func _run() -> Node2D:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.boost_effect.set_process(false)
	run.car.use_keyboard = false
	return run


func test_sheet_imports_and_matches_its_record() -> void:
	var tex: Texture2D = load(SHEET_PATH)
	assert_not_null(tex, "Godot imports the sheet")
	var rec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/effects/boost_lines.json"))
	assert_eq(tex.get_width(), int(rec.frames) * int(rec.frame_size))
	assert_eq(tex.get_height(), int(rec.directions) * int(rec.frame_size))
	assert_true(rec.check.pass)


func test_sheet_has_no_semi_transparent_pixels_and_no_redgull_red() -> void:
	var img: Image = (load(SHEET_PATH) as Texture2D).get_image()
	img.decompress()
	var heart := Color(0.86, 0.08, 0.16)
	var semi := 0
	var closest := 9.0
	for y in range(0, img.get_height()):
		for x in range(0, img.get_width()):
			var c := img.get_pixel(x, y)
			if c.a > 0.0 and c.a < 1.0:
				semi += 1
			if c.a > 0.0:
				closest = minf(closest, Vector3(c.r - heart.r, c.g - heart.g, c.b - heart.b).length())
	assert_eq(semi, 0)
	assert_gt(closest, 0.5, "not Redgull red")


func test_the_effect_draws_the_pixellab_art_not_the_streaks() -> void:
	var effect: Node2D = BoostScript.new()
	add_child_autofree(effect)
	assert_eq(effect.SHEET.resource_path, SHEET_PATH)
	assert_false("streak_count" in effect, "the placeholder streaks are gone")
	assert_eq(effect.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	assert_eq(effect.frame_count, 5)


func test_w_press_plays_the_animation_behind_the_car_and_it_ends() -> void:
	var run := _run()
	var effect: Node2D = run.boost_effect
	run.car.scripted_input = W_ONLY
	run.car.physics_step()
	assert_eq(effect.burst_count(), 1, "the W press played it")
	var drawn: Array = effect.drawn()
	assert_eq(drawn.size(), 1)
	assert_eq(drawn[0].frame, 0)
	# Behind the car on screen: the art's centre is against the car's heading.
	var heading: float = run.car.model.rotation
	var car_view: Vector2 = effect.view_transform * (run.car.model.get_position() * effect.PX_PER_UNIT)
	var forward_view: Vector2 = effect.view_transform.basis_xform(Vector2.from_angle(heading))
	assert_lt((drawn[0].at - car_view).dot(forward_view), 0.0, "behind the car")
	# Under the car sprite in the drawing order.
	assert_lt(effect.get_index(), run.car_sprite.get_index())
	# It plays every frame in turn, then ends by itself (W still held: no new burst).
	var seen := []
	for i in 40:
		run.car.physics_step()
		effect.advance(1.0 / 50.0)
		for d in effect.drawn():
			if not seen.has(d.frame):
				seen.append(d.frame)
		# It follows the car: always right behind it.
		for d in effect.drawn():
			var cv: Vector2 = effect.view_transform * (run.car.model.get_position() * effect.PX_PER_UNIT)
			var fv: Vector2 = effect.view_transform.basis_xform(Vector2.from_angle(run.car.model.rotation))
			assert_lt((d.at - cv).dot(fv), 0.0, "still behind the car")
			assert_lt((d.at - cv).length(), 60.0, "close to the car")
	assert_eq(seen, [0, 1, 2, 3, 4], "all five frames, in order")
	assert_eq(effect.burst_count(), 0, "it ended")
	assert_eq(effect.bursts_made, 1)


func test_rows_follow_the_cars_heading_on_screen() -> void:
	var effect: Node2D = BoostScript.new()
	add_child_autofree(effect)
	effect.view_transform = Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
	for i in 64:
		var heading := TAU * i / 64.0
		var screen: Vector2 = effect.view_transform.basis_xform(Vector2.from_angle(heading))
		var row_angle: float = effect.direction_row(heading) * TAU / effect.directions
		assert_lt(absf(angle_difference(row_angle, screen.angle())), TAU / effect.directions / 2.0 + 0.001)


func test_lifetime_is_close_to_t008s() -> void:
	var effect: Node2D = BoostScript.new()
	add_child_autofree(effect)
	assert_almost_eq(effect.lifetime, 0.35, 0.05)
