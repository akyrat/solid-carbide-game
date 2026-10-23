extends GutTest
## Task T-273: the likes bar is 64 px tall and its fill springs to a new level
## (about 0.25 s, ease-out-back: a small overshoot, never below the old value,
## never drawn past full), starts again after filling, and stops with the game.

const RUN := preload("res://scenes/run/run.tscn")
const SIZES: Array[Vector2i] = [
	Vector2i(1152, 648), Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(1024, 576)]


func after_each() -> void:
	get_tree().paused = false


func _run(size := Vector2i(1152, 648)) -> Node2D:
	var sv := SubViewport.new()
	sv.size = size
	add_child_autofree(sv)
	var r: Node2D = RUN.instantiate()
	sv.add_child(r)
	return r


func test_the_curve_starts_at_0_ends_at_1_and_overshoots_a_little() -> void:
	assert_almost_eq(LikesSpring.ease_back(0.0), 0.0, 0.0001)
	assert_almost_eq(LikesSpring.ease_back(1.0), 1.0, 0.0001)
	var peak := 0.0
	var prev := -1.0
	var rose_then_fell := false
	for i in 101:
		var v := LikesSpring.ease_back(i / 100.0)
		assert_gte(v, -0.0001, "never below the start")
		peak = maxf(peak, v)
		if v < prev:
			rose_then_fell = true
		prev = v
	assert_gt(peak, 1.01, "it overshoots")
	assert_lt(peak, 1.12, "only a little")
	assert_true(rose_then_fell, "then settles back")
	assert_almost_eq(LikesSpring.DURATION, 0.25, 0.0001)


func test_a_gain_springs_over_the_duration_instead_of_jumping() -> void:
	var r := _run()
	var hud: Hud = r.hud
	var need: float = r.state.xp_needed()
	r.state.add_xp(need * 0.5 / r.state.combo)
	var target: float = r.state.xp / need
	assert_eq(hud.likes_bar.value, 0.0, "no jump")
	var seen_over := false
	var last := 0.0
	var steps := 25
	for i in steps:
		hud.likes_spring.advance(LikesSpring.DURATION / steps)
		var v := hud.likes_bar.value / hud.likes_bar.max_value
		assert_gte(v, 0.0)
		seen_over = seen_over or v > target + 0.001
		last = v
	assert_true(seen_over, "it overshoots the new level")
	assert_false(hud.likes_spring.active, "done after the duration")
	assert_almost_eq(last, target, 0.001, "and settles on it")


func test_never_below_the_old_value_and_never_past_full() -> void:
	var r := _run()
	var hud: Hud = r.hud
	var need: float = r.state.xp_needed()
	r.state.add_xp(need * 0.4 / r.state.combo)
	hud.settle_likes()
	var old := hud.likes_bar.value
	r.state.add_xp(need * 0.58 / r.state.combo)  # just short of full: overshoot would pass it
	assert_eq(r.state.level, 1)
	for i in 30:
		hud.likes_spring.advance(0.01)
		assert_gte(hud.likes_bar.value, old - 0.0001, "never below the old value")
		assert_lte(hud.likes_bar.value, hud.likes_bar.max_value, "never past full")


func test_a_full_bar_levels_up_at_once_fills_then_starts_again() -> void:
	var r := _run()
	var hud: Hud = r.hud
	var need: float = r.state.xp_needed()
	r.state.add_xp(need * 0.9 / r.state.combo)
	hud.settle_likes()
	var old_max := hud.likes_bar.max_value
	r.state.add_xp(need * 0.3 / r.state.combo)
	assert_eq(r.state.level, 2, "the level-up is not delayed")
	assert_true(hud.level_up_flash.playing, "its animation starts at that moment")
	assert_eq(hud.level_label.text, "Hype Lv 2")
	assert_eq(hud.likes_bar.max_value, old_max, "the old bar fills first")
	hud.likes_spring.advance(LikesSpring.DURATION - 0.01)
	assert_gt(hud.likes_bar.value / old_max, 0.9, "nearly full")
	hud.likes_spring.advance(0.02)
	assert_almost_eq(hud.likes_bar.max_value, r.state.xp_needed(), 0.001, "then the next level's bar")
	assert_lt(hud.likes_bar.value, hud.likes_bar.max_value * 0.1, "starts again from empty")
	hud.settle_likes()
	assert_almost_eq(hud.likes_bar.value, r.state.xp, 0.001, "and springs to the leftover")


func test_it_stops_while_the_game_is_paused() -> void:
	var r := _run()
	var hud: Hud = r.hud
	r.state.add_xp(r.state.xp_needed() * 0.5 / r.state.combo)
	assert_true(hud.likes_spring.active)
	assert_eq(hud.likes_spring.process_mode, Node.PROCESS_MODE_PAUSABLE)
	get_tree().paused = true
	var before := hud.likes_bar.value
	await get_tree().create_timer(0.3, true).timeout
	assert_false(hud.likes_spring.can_process(), "paused")
	assert_eq(hud.likes_bar.value, before, "the fill stands still")
	get_tree().paused = false
	await wait_seconds(0.4)
	assert_false(hud.likes_spring.active)


func test_draining_does_not_spring() -> void:
	var r := _run()
	var hud: Hud = r.hud
	r.state.add_xp(r.state.xp_needed() * 0.5 / r.state.combo)
	hud.settle_likes()
	var before := hud.likes_bar.value
	r.state.xp -= 5.0
	r.state.xp_changed.emit(r.state.xp, r.state.xp_needed(), r.state.level)
	assert_lt(hud.likes_bar.value, before)
	assert_false(hud.likes_spring.active, "going down is not animated")


func test_the_bar_is_64_px_tall_and_clear_of_everything_at_every_size() -> void:
	assert_eq(Hud.LIKES_BAR_HEIGHT, 64.0)
	for size in SIZES:
		var r := _run(size)
		var hud: Hud = r.hud
		r.state._set_combo(4.5)
		await wait_frames(2)
		var bar := hud.likes_bar.get_global_rect()
		var view := Rect2(Vector2.ZERO, Vector2(size))
		assert_eq(bar.size.y, 64.0, "%s" % size)
		assert_almost_eq(bar.size.x, size.x * 0.5, 1.0)
		assert_almost_eq(size.y - bar.end.y, float(Hud.MARGIN), 0.5, "same distance from the bottom")
		for part in [hud.likes_row, hud.level_label, hud.combo_label]:
			var rect: Rect2 = part.get_global_rect()
			assert_true(view.encloses(rect), "on screen %s" % size)
			assert_lte(rect.end.y, bar.position.y + 0.01, "above the bar %s" % size)
		for name in ["airtime_counter", "drift_counter"]:
			var c: Control = hud.get(name)
			if c != null and c.visible:
				assert_false(c.get_global_rect().intersects(hud.combo_label.get_global_rect()), name)
