extends GutTest
## Task T-351: reaction icons. A burst out of the sub goal square when the goal is
## reached (once per goal), and floaters rising from the bottom in the left and
## right thirds at a rate set by the live viewers counter's look step (none below
## the first heat step, at uneven gaps). Small, partly transparent, under every HUD
## piece, never starting over the car, at most the cap at once; pause freezes
## them and a new run clears them.

const RUN := preload("res://scenes/run/run.tscn")
const SIZE := Vector2(1152, 648)


func after_each() -> void:
	get_tree().paused = false


func _reactions(step := 0, seed_value := 7) -> Reactions:
	var r := Reactions.new()
	r.rng.seed = seed_value
	r.step_source = func() -> int: return step
	add_child_autofree(r)
	r.area_override = SIZE
	return r


func _run() -> Node2D:
	var sv := SubViewport.new()
	sv.size = Vector2i(1152, 648)
	add_child_autofree(sv)
	var r: Node2D = RUN.instantiate()
	sv.add_child(r)
	return r


func _spawn_times(step: int, seconds: float, seed_value := 7) -> Array:
	var r := _reactions(step, seed_value)
	r.set_process(false)
	var times: Array = []
	var t := 0.0
	var before := r.bursts_started
	while t < seconds:
		var n := r.next_in
		r.advance(0.05)
		t += 0.05
		# next_in jumps back up when a group spawns.
		if r.next_in > n and n >= 0.0:
			times.append(t)
		r.items.clear()
	assert_eq(r.bursts_started, before)
	return times


func test_the_numbers_are_in_hud_json_with_the_proposed_shape() -> void:
	var r := _reactions()
	assert_eq(r.cap(), 60)
	assert_almost_eq(float(r.cfg["alpha"]), 0.9, 0.001)
	assert_eq(int(r.cfg["icon_scale"]), 2)
	var rates: Array = r.cfg["rates_per_second"]
	assert_eq(rates.size(), 5, "one rate per look step")
	assert_eq(rates[0], 0.0, "none at the base step")
	assert_gte(rates[1], 2.0, "a lively flow from the first heat step")
	for i in range(1, rates.size()):
		assert_gt(rates[i], rates[i - 1], "more often at each higher step")
	assert_gt(rates[4], 7.0, "a real stream at fire")
	assert_eq(r.rate_for_step(99), rates[4], "the fire step's rate goes on")


func test_nothing_floats_below_the_first_heat_step() -> void:
	var r := _reactions(0)
	for i in 600:
		r.advance(0.05)
	assert_eq(r.count(), 0)
	assert_eq(r.next_in, -1.0)


func test_the_first_heat_step_is_already_a_flow() -> void:
	var r := _reactions(1)
	for i in 200:
		r.advance(0.05)
	assert_gte(r.count(), 5, "several on screen after 10 s")


func test_higher_steps_float_more_often() -> void:
	var counts: Array = []
	for step in range(0, 5):
		counts.append(_spawn_times(step, 120.0).size())
	assert_eq(counts[0], 0)
	for i in range(1, 5):
		assert_gt(counts[i], counts[i - 1], "step %d has more groups than %d: %s" % [i, i - 1, counts])


func test_gaps_are_uneven_and_never_a_constant_stream() -> void:
	var times := _spawn_times(3, 120.0)
	assert_gt(times.size(), 20)
	var gaps: Array = []
	for i in range(1, times.size()):
		gaps.append(times[i] - times[i - 1])
	var lo: float = gaps.min()
	var hi: float = gaps.max()
	assert_gt(hi, lo * 1.8, "the gaps differ: %f to %f" % [lo, hi])
	assert_gt(lo, 0.0)


func test_same_seed_same_floaters() -> void:
	var a := _spawn_times(2, 60.0, 11)
	var b := _spawn_times(2, 60.0, 11)
	assert_eq(a, b)


func test_floaters_start_below_the_screen_in_the_right_side_lane() -> void:
	var r := _reactions(4)
	r.set_process(false)
	var xs: Array = []
	for i in 60:
		r.items.clear()
		r.spawn_group()
		for it in r.items:
			assert_gt(it["pos"].y, SIZE.y, "starts below the bottom edge")
			xs.append(it["pos"].x)
	assert_gte(float(xs.min()), SIZE.x * 0.75, "right side only")
	assert_lte(float(xs.max()), SIZE.x * 0.99)
	assert_gt(float(xs.max()) - float(xs.min()), 120.0, "spread over the counter's width")


func test_floaters_never_drift_into_the_middle() -> void:
	var r := _reactions(4)
	r.set_process(false)
	for i in 1500:
		r.advance(0.01)
		for it in r.items:
			if it["floater"]:
				assert_gt(it["pos"].x, SIZE.x * 0.7, "stays on the right side")


func test_floaters_rise_and_sway_up_to_near_the_top() -> void:
	var r := _reactions(4)
	r.set_process(false)
	r.spawn_group()
	var it: Dictionary = r.items[0]
	var y0: float = it["pos"].y
	var x0: float = it["pos"].x
	var xmin := x0
	var xmax := x0
	var top: float = y0
	for i in 600:
		r.advance(0.01)
		if it["age"] >= it["life"]:
			break
		xmin = minf(xmin, it["pos"].x)
		xmax = maxf(xmax, it["pos"].x)
		top = minf(top, it["pos"].y)
	assert_lt(top, SIZE.y * 0.2, "climbs to near the top")
	assert_gt(xmax - xmin, 10.0, "some sideways sway")


func test_a_floater_pops_in_and_is_gone_before_the_top() -> void:
	var r := _reactions(4)
	r.set_process(false)
	r.spawn_group()
	var it: Dictionary = r.items[0]
	assert_almost_eq(r.scale_of(it), float(r.cfg["pop_from"]), 0.001)
	it["age"] = 1.0
	assert_eq(r.scale_of(it), 1.0)
	r.items.clear()
	r.spawn_group()
	for i in 300:
		r.advance(0.01)
		for f in r.items:
			if f["floater"] and f["age"] >= f["life"] - 0.05:
				assert_lt(r.alpha_of(f), 0.1, "faded out at the end")


func test_they_fade_in_and_out_and_are_partly_transparent() -> void:
	var r := _reactions()
	var it := r._new_item(Vector2(100, 100), Vector2.ZERO, 2.0, true)
	assert_eq(r.alpha_of(it), 0.0, "starts invisible")
	it["age"] = 0.5
	assert_almost_eq(r.alpha_of(it), 0.9, 0.001, "holds at 0.9, not opaque")
	it["age"] = 1.5
	assert_lt(r.alpha_of(it), 0.9, "fading")
	it["age"] = 2.0
	assert_eq(r.alpha_of(it), 0.0, "gone at the end")


func test_the_cap_holds_for_floaters_and_bursts() -> void:
	var r := _reactions(4)
	r.set_process(false)
	for i in 100:
		r.spawn_group()
		assert_lte(r.count(), r.cap())
	r.burst(Vector2(1052, 430))
	assert_lte(r.count(), r.cap())
	for i in 100:
		r.advance(0.1)
		assert_lte(r.count(), r.cap(), "step %d" % i)


func test_a_burst_pops_out_all_at_once_from_the_origin() -> void:
	var r := _reactions()
	r.set_process(false)
	var origin := Vector2(1052, 430)
	var n := r.burst(origin)
	assert_eq(n, int(r.cfg["burst_count"]))
	assert_eq(r.count(), n)
	for it in r.items:
		assert_eq(it["pos"], origin)
		assert_lt(it["vel"].y, 0.0, "fanned upward")
	r.advance(0.3)
	var spread := 0.0
	for it in r.items:
		spread = maxf(spread, it["pos"].distance_to(origin))
	assert_gt(spread, 20.0, "flying out")


func test_a_burst_fades_out_and_stays_clear_of_the_middle() -> void:
	var r := _reactions()
	r.set_process(false)
	for trial in 20:
		r.items.clear()
		r.burst(Vector2(1052, 430))
		for i in 200:
			r.advance(0.01)
			for it in r.items:
				assert_gt(it["pos"].x, SIZE.x * 0.6, "never over the car in the middle")
	r.items.clear()
	r.cfg["rates_per_second"] = [0.0]  # only the burst
	r.burst(Vector2(1052, 430))
	for i in 250:
		r.advance(0.01)
	assert_eq(r.count(), 0, "all gone within 2.5 s")


func test_pause_freezes_them() -> void:
	var r := _reactions(4)
	r.burst(Vector2(1052, 430))
	r.spawn_group()
	await get_tree().process_frame
	get_tree().paused = true
	var before: Array = []
	for it in r.items:
		before.append([it["pos"], it["age"]])
	var next_before := r.next_in
	for i in 10:
		await get_tree().process_frame
	var after: Array = []
	for it in r.items:
		after.append([it["pos"], it["age"]])
	assert_eq(after, before, "standing still while paused")
	assert_eq(r.next_in, next_before)
	assert_eq(r.process_mode, Node.PROCESS_MODE_PAUSABLE)


func test_clear_empties_it() -> void:
	var r := _reactions(4)
	r.burst(Vector2(1052, 430))
	r.clear()
	assert_eq(r.count(), 0)
	assert_eq(r.next_in, -1.0)


func test_six_icons_are_16_pixel_pngs_and_each_kind_can_be_drawn() -> void:
	assert_eq(Reactions.ICONS.size(), 6)
	for t: Texture2D in Reactions.ICONS:
		assert_eq(t.get_size(), Vector2(16, 16))
	var r := _reactions(4)
	r.burst(Vector2(500, 300))
	r.items[0]["kind"] = 5
	r.advance(0.1)
	assert_gt(r.count(), 0)


func test_the_hud_draws_them_under_every_other_piece() -> void:
	var r := _run()
	await get_tree().process_frame
	var hud: Hud = r.hud
	assert_eq(hud.reactions.get_index(), 0, "the first child, so drawn first")
	assert_eq(hud.reactions.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(hud.reactions.get_parent(), hud)


func test_reaching_the_sub_goal_bursts_once_per_goal() -> void:
	var r := _run()
	await get_tree().process_frame
	r.state.pause_on_level_up = false
	var hud: Hud = r.hud
	assert_eq(hud.reactions.bursts_started, 0)
	r.state.add_xp(r.state.xp_needed() * 0.5)
	assert_eq(hud.reactions.bursts_started, 0, "not before the goal")
	assert_eq(hud.reactions.count(), 0)
	r.state.add_xp(r.state.xp_needed() * 0.6)
	assert_eq(hud.reactions.bursts_started, 1, "one burst at the goal")
	assert_gt(hud.reactions.count(), 0)
	var origin: Vector2 = hud.sub_goal.get_global_rect().get_center()
	for it in hud.reactions.items:
		assert_eq(it["pos"], origin, "from the sub goal square")
	r.state.add_xp(r.state.xp_needed() * 0.3)
	assert_eq(hud.reactions.bursts_started, 1, "still one: the next goal is not reached")


func test_the_hud_feeds_the_viewers_step_and_a_new_run_clears_them() -> void:
	var r := _run()
	await get_tree().process_frame
	var hud: Hud = r.hud
	hud.viewers_counter.step = 3
	assert_eq(hud.reactions.step_source.call(), 3)
	hud.reactions.burst(Vector2(1052, 430))
	assert_gt(hud.reactions.count(), 0)
	hud.bind(r.state)
	assert_eq(hud.reactions.count(), 0, "a new run starts with none")
