extends GutTest
## Task T-534: dots fly from the car to the gift when a trick pays subs.

const HUD_SCENE := preload("res://scenes/hud/hud.tscn")


func after_each() -> void:
	get_tree().paused = false


func _hud(size := Vector2i(1152, 648), hud_size := 100.0) -> Hud:
	var sv := SubViewport.new()
	sv.size = size
	add_child_autofree(sv)
	var hud: Hud = HUD_SCENE.instantiate()
	sv.add_child(hud)
	hud.set_hud_size(hud_size)
	return hud


func _flights(hud: Hud) -> Array:
	return hud.root.get_children().filter(func(c): return c is SubsFlight)


func test_a_paid_trick_spawns_a_flight_that_ends_at_the_gift_and_frees_itself() -> void:
	var hud := _hud()
	await get_tree().process_frame
	var f := hud.spawn_subs_flight()
	assert_not_null(f)
	assert_eq(_flights(hud).size(), 1)
	assert_eq(f.point_at(0.0), hud.root.size / 2.0, "starts at the car's place")
	assert_almost_eq(f.point_at(1.0).distance_to(hud.gift_center()), 0.0, 0.01, "ends at the gift")
	f.advance(f.seconds + 0.01)
	assert_true(f.done)
	await get_tree().process_frame
	assert_eq(_flights(hud).size(), 0, "freed on arrival")
	assert_not_null(hud.spawn_subs_flight(), "its slot is free again")


func test_the_signal_from_the_run_state_spawns_one() -> void:
	var hud := _hud()
	var state := RunState.new()
	hud.bind(state)
	state.trick_subs_paid.emit("drift", 5.0)
	assert_eq(_flights(hud).size(), 1)


func test_it_goes_to_the_moved_gift_and_scales_with_the_hud() -> void:
	var hud := _hud()
	await get_tree().process_frame
	var before := hud.gift_center()
	hud.move_piece("sub_goal", Vector2(500, 200))
	await get_tree().process_frame
	var after := hud.gift_center()
	assert_ne(before, after, "the gift moved")
	var f := hud.spawn_subs_flight()
	assert_almost_eq(f.point_at(1.0).distance_to(after), 0.0, 0.01, "ends at the moved gift")
	var small := _hud(Vector2i(1152, 648), 50.0)
	await get_tree().process_frame
	var g := small.spawn_subs_flight()
	# The flight is a child of the scaled area: its screen size follows the HUD's scale.
	assert_almost_eq(g.get_global_transform().get_scale().x, small.hud_scale(), 0.0001)
	assert_almost_eq(small.hud_scale(), 0.5, 0.0001)
	var screen_end := g.get_global_transform() * g.point_at(1.0)
	var gift_screen := small.sub_goal.gift.get_global_rect().get_center()
	assert_almost_eq(screen_end.distance_to(gift_screen), 0.0, 0.01)


func test_ten_trick_payments_on_one_frame_are_bounded_by_data() -> void:
	var hud := _hud()
	await get_tree().process_frame
	var cap := int(hud.subs_flight_cfg["max_per_frame"])
	assert_gt(cap, 0)
	for i in 10:
		hud._on_trick_subs_paid("drift", 1.0)
	assert_eq(_flights(hud).size(), cap)
	assert_lt(cap, 10)


func test_the_total_on_screen_is_bounded_by_data() -> void:
	var hud := _hud()
	var max_alive := int(hud.subs_flight_cfg["max_alive"])
	for i in max_alive * 2:
		await get_tree().process_frame
		hud.spawn_subs_flight()
		hud.spawn_subs_flight()
	assert_lte(_flights(hud).size(), max_alive)
