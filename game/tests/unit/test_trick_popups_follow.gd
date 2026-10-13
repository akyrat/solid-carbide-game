extends GutTest
## Task T-125: trick popups stay with the car for their whole life and do not
## sit on top of each other.

const RunScene := preload("res://scenes/run/run.tscn")
const PrototypeScene := preload("res://scenes/drift_prototype/drift_prototype.tscn")
const Popups := preload("res://scripts/hud/trick_popups.gd")


func _rect(p) -> Rect2:
	return Rect2(p.position - p.size() / 2.0, p.size())


func test_popup_keeps_its_offset_from_a_moving_car_for_its_whole_life() -> void:
	var tp: Node2D = Popups.new()
	add_child_autofree(tp)
	var car := [Vector2(100, 100)]
	var follow := func() -> Vector2: return car[0]
	var pop = tp.show_popup("FULL 360!", car[0], 28, follow)
	var t := 0.0
	while t < 0.95:
		car[0] += Vector2(37, -21)
		pop.advance(0.05)
		t += 0.05
		var expected: Vector2 = car[0] + Popups.START_OFFSET + Vector2(0, -pop.rise())
		assert_true(pop.position.is_equal_approx(expected), "at %.2f s the popup is where the moving car puts it" % t)
		assert_almost_eq(pop.position.y - car[0].y, Popups.START_OFFSET.y - pop.rise(), 0.001)
	assert_almost_eq(pop.position.x - car[0].x, 0.0, 0.001, "centred over the car")


func test_physics_step_places_the_popup_at_the_cars_current_position() -> void:
	var tp: Node2D = Popups.new()
	add_child_autofree(tp)
	var car := [Vector2.ZERO]
	var pop = tp.show_popup("FULL 360!", car[0], 28, func() -> Vector2: return car[0])
	car[0] = Vector2(500, 300)
	pop.place()
	assert_eq(pop.position, Vector2(500, 300) + Popups.START_OFFSET)


func test_popup_without_follow_stays_put() -> void:
	var tp: Node2D = Popups.new()
	add_child_autofree(tp)
	var pop = tp.show_popup("FULL 360!", Vector2(10, 10))
	pop.advance(0.0)
	assert_eq(pop.position, Vector2(10, 10) + Popups.START_OFFSET)


func test_run_popup_follows_the_drawn_car() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.car.trick.emit("three_sixty")
	var pop = run.trick_popups.popups().back()
	for i in 5:
		run.car_sprite.position += Vector2(60, 25)
		pop.advance(0.1)
		var rel: Vector2 = pop.position - run.car_sprite.position
		assert_eq(rel, pop.offset(), "same offset from the drawn car, frame %d" % i)
	assert_lt(pop.position.y, run.car_sprite.position.y, "still above the car")


func test_challenge_popup_follows_the_car() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.state.score.emit(120.0, "c")
	var pop = run.trick_popups.popups().back()
	assert_true(pop.text.begins_with("Trending"))
	run.car_sprite.position += Vector2(300, 0)
	pop.advance(0.2)
	assert_eq(pop.position - run.car_sprite.position, pop.offset())


func test_prototype_popup_follows_the_drawn_car() -> void:
	var proto: Node2D = PrototypeScene.instantiate()
	add_child_autofree(proto)
	proto.car.trick.emit("three_sixty")
	var pop = proto.trick_popups.popups().back()
	proto.car_sprite.position += Vector2(200, -80)
	pop.advance(0.3)
	assert_true((pop.position - proto.car_sprite.position).is_equal_approx(pop.offset()))


func test_popups_shown_together_do_not_overlap() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	for id in ["extended_drift", "three_sixty", "alternate_drift", "three_sixty"]:
		run.car.trick.emit(id)
	var shown: Array = run.trick_popups.popups()
	# Under the screen-height limit (T-125, round 2) not all four fit above the
	# car: the oldest make room. Whatever shows does not overlap.
	assert_gte(shown.size(), 1)
	assert_lte(shown.size(), 3, "never more than 3")
	for i in shown.size():
		for j in range(i + 1, shown.size()):
			assert_false(_rect(shown[i]).intersects(_rect(shown[j])), "popups %d and %d overlap" % [i, j])


func test_three_popups_stack_without_overlap_when_there_is_no_screen_limit() -> void:
	# No camera, so no limit: the plain stacking from round 1 still holds (three at most since round 3).
	var tp: Node2D = Popups.new()
	add_child_autofree(tp)
	for t in ["LONG DRIFT!", "FULL 360!", "ALT DRIFT!", "FULL 360!"]:
		tp.show_popup(t, Vector2.ZERO, 28)
	var shown: Array = tp.popups()
	assert_eq(shown.size(), 3, "the fourth made the oldest leave")
	for i in shown.size():
		for j in range(i + 1, shown.size()):
			assert_false(_rect(shown[i]).intersects(_rect(shown[j])))


func test_popups_born_a_little_apart_do_not_cover_an_older_one() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.car.trick.emit("extended_drift")
	for i in 6:
		for p in run.trick_popups.popups():
			p.advance(0.1)
		run.car.trick.emit("extended_drift" if i % 2 == 0 else "three_sixty")
	var shown: Array = run.trick_popups.popups()
	assert_gte(shown.size(), 1)
	for i in shown.size():
		for j in range(i + 1, shown.size()):
			assert_false(_rect(shown[i]).intersects(_rect(shown[j])), "popups %d and %d overlap" % [i, j])


func test_stack_resets_once_popups_are_gone() -> void:
	var tp: Node2D = Popups.new()
	add_child_autofree(tp)
	var a = tp.show_popup("FULL 360!", Vector2.ZERO)
	var b = tp.show_popup("FULL 360!", Vector2.ZERO)
	assert_lt(b.stack, a.stack, "the second goes above the first")
	a.advance(2.0)
	b.advance(2.0)
	await get_tree().process_frame
	var c = tp.show_popup("FULL 360!", Vector2.ZERO)
	assert_eq(c.stack, 0.0)


# --- Round 2 (board's playtest 2026-10-14): lower and smaller -----------------

## A SubViewport of the given size with a camera at `zoom` holding the popups,
## the car (the camera's centre) at (0, 0).
func _view(size: Vector2i, zoom: float) -> Array:
	var sv := SubViewport.new()
	sv.size = size
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child_autofree(sv)
	var cam := Camera2D.new()
	cam.zoom = Vector2(zoom, zoom)
	cam.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	sv.add_child(cam)
	cam.make_current()
	var tp: Node2D = Popups.new()
	sv.add_child(tp)
	return [sv, cam, tp]


func test_stacked_popups_never_reach_above_a_quarter_of_the_screen_height() -> void:
	for size in [Vector2i(1152, 648), Vector2i(640, 900)]:
		for zoom in [1.0, 2.0]:
			var v := _view(size, zoom)
			var sv: SubViewport = v[0]
			var tp: Node2D = v[2]
			await get_tree().process_frame
			await get_tree().process_frame
			var quarter := float(size.y) * 0.25
			var limit: float = tp.top_limit()
			assert_lt(limit, 0.0, "a limit exists with a camera")
			# Many popups, a new one every 0.1 s for 2 s, each checked at birth
			# and over its whole life.
			for i in 20:
				tp.show_popup("FULL 360! +0.25" if i % 2 == 0 else "LONG DRIFT!", Vector2.ZERO, 28 if i % 2 == 0 else 16, func() -> Vector2: return Vector2.ZERO)
				for p in tp.popups():
					p.advance(0.1)
				for p in tp.popups():
					# The car is at the screen's centre; the top edge's offset from it
					# in screen pixels is at most a quarter of the height.
					var top_offset: float = (p.position.y - p.size().y / 2.0) * zoom
					assert_gte(top_offset, -quarter - 0.01, "%s zoom %s popup %d: top edge within the limit" % [size, zoom, i])
			if zoom == 1.0:
				assert_gt(tp.popups().size(), 1, "several popups still show")


func test_popups_still_do_not_overlap_under_the_limit() -> void:
	var v := _view(Vector2i(1152, 648), 1.5)
	var tp: Node2D = v[2]
	await get_tree().process_frame
	await get_tree().process_frame
	for i in 12:
		tp.show_popup("FULL 360!", Vector2.ZERO, 28, func() -> Vector2: return Vector2.ZERO)
	var ps: Array = tp.popups()
	assert_gte(ps.size(), 1)
	for a in ps.size():
		for b in range(a + 1, ps.size()):
			assert_false(_rect(ps[a]).intersects(_rect(ps[b])), "popups %d and %d apart" % [a, b])


func test_oldest_popup_makes_room_when_the_stack_would_go_too_high() -> void:
	var v := _view(Vector2i(1152, 648), 2.0)
	var tp: Node2D = v[2]
	await get_tree().process_frame
	await get_tree().process_frame
	var first = tp.show_popup("FIRST", Vector2.ZERO, 28, func() -> Vector2: return Vector2.ZERO)
	for i in 10:
		tp.show_popup("FULL 360!", Vector2.ZERO, 28, func() -> Vector2: return Vector2.ZERO)
	assert_true(first.is_queued_for_deletion(), "the oldest popup was removed to make room")


func test_popups_are_smaller_than_before() -> void:
	# Round 1 drew 0.8 drawn px per popup pixel; round 3 draws less, normal and small alike.
	assert_lt(Popups.PIXEL_SCALE, 0.6)
	var tp: Node2D = Popups.new()
	add_child_autofree(tp)
	var big = tp.show_popup("FULL 360!", Vector2.ZERO, Popups.SIZE_NORMAL)
	var small = tp.show_popup("LONG DRIFT!", Vector2.ZERO, Popups.SIZE_SMALL)
	for p in [big, small]:
		var tex_size := Vector2(Popups.Art.texture(p.text, Popups.Art.style_for(p.font_size)).get_size())
		assert_true(p.size().is_equal_approx(tex_size * Popups.PIXEL_SCALE), "%s drawn at the pixel scale" % p.text)


# --- Round 3 (board, 2026-10-14): three at most, eased rise -------------------

func test_three_of_the_biggest_popups_fit_at_the_default_zoom_and_window() -> void:
	var v := _view(Vector2i(1152, 648), 1.40625)
	var tp: Node2D = v[2]
	# The run's default zoom 14.4 in a 1152x648 window is a camera zoom of 1.40625 (limit 115.2 drawn px).
	await get_tree().process_frame
	await get_tree().process_frame
	var texts := ["FULL 360! +0.25", "ALT DRIFT! +0.5", "FULL 360! +0.25"]
	var ps := []
	for t in texts:
		ps.append(tp.show_popup(t, Vector2.ZERO, 28, func() -> Vector2: return Vector2.ZERO))
	assert_eq(tp.popups().size(), 3, "all three show at once")
	for p in ps:
		assert_false(p.is_queued_for_deletion(), "none had to make room")
	# Also with the long-drift popup and a 360 and an alt drift (the usual mix).
	for p in ps:
		p.queue_free()
	await get_tree().process_frame
	for t in ["LONG DRIFT! +0.05", "FULL 360! +0.25", "ALT DRIFT! +0.5"]:
		tp.show_popup(t, Vector2.ZERO, 16 if t.begins_with("LONG") else 28, func() -> Vector2: return Vector2.ZERO)
	assert_eq(tp.popups().size(), 3)


func test_never_more_than_three_popups() -> void:
	var tp: Node2D = Popups.new()
	add_child_autofree(tp)
	for i in 10:
		tp.show_popup("FULL 360!", Vector2.ZERO, 28)
		assert_lte(tp.popups().size(), 3)
	var first = tp.show_popup("FIRST", Vector2.ZERO, 28)
	tp.show_popup("B", Vector2.ZERO, 28)
	tp.show_popup("C", Vector2.ZERO, 28)
	var d = tp.show_popup("D", Vector2.ZERO, 28)
	assert_true(first.is_queued_for_deletion(), "the oldest makes room for a fourth")
	assert_false(d.is_queued_for_deletion())


func test_rise_eases_out() -> void:
	var tp: Node2D = Popups.new()
	add_child_autofree(tp)
	var pop = tp.show_popup("FULL 360!", Vector2.ZERO, 28)
	var prev := 0.0
	var step := Popups.LIFETIME / 20.0
	var first_half := 0.0
	var last_step := INF
	for i in 20:
		pop.age = step * (i + 1)
		var r: float = pop.rise()
		var d := r - prev
		assert_lte(d, last_step + 0.0001, "each step rises no more than the one before (step %d)" % i)
		last_step = d
		prev = r
		if i == 9:
			first_half = r
	assert_almost_eq(prev, Popups.RISE, 0.0001, "the whole rise is made over the lifetime")
	assert_gt(first_half, Popups.RISE - first_half, "more distance in the first half of the life than the second")
	pop.age = 0.0
	assert_eq(pop.rise(), 0.0)
