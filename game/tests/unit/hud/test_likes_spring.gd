extends GutTest
## Task T-273: the fill springs to a new level (about 0.25 s, ease-out-back: a
## small overshoot, never below the old value, never drawn past full), starts
## again after filling, and stops with the game. Since T-337 it is the sub goal
## square's fill (`hud.sub_goal.fill`, a share 0 to 1), and after filling it
## stays full while the square celebrates before starting again.

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
	assert_eq(hud.sub_goal.fill, 0.0, "no jump")
	var seen_over := false
	var last := 0.0
	var steps := 25
	for i in steps:
		hud.likes_spring.advance(LikesSpring.DURATION / steps)
		var v := hud.sub_goal.fill
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
	var old := hud.sub_goal.fill
	r.state.add_xp(need * 0.58 / r.state.combo)  # just short of full: overshoot would pass it
	assert_eq(r.state.level, 1)
	for i in 30:
		hud.likes_spring.advance(0.01)
		assert_gte(hud.sub_goal.fill, old - 0.0001, "never below the old value")
		assert_lte(hud.sub_goal.fill, 1.0, "never past full")
		assert_false(hud.sub_goal.lit, "the gift stays grey short of the goal, overshoot or not")


func test_a_full_square_levels_up_at_once_fills_holds_then_starts_again() -> void:
	var r := _run()
	var hud: Hud = r.hud
	var need: float = r.state.xp_needed()
	r.state.add_xp(need * 0.9 / r.state.combo)
	hud.settle_likes()
	var old_goal := hud.sub_goal.goal
	r.state.add_xp(need * 0.3 / r.state.combo)
	assert_eq(r.state.level, 2, "the level-up is not delayed")
	assert_true(hud.sub_goal.celebrating, "its celebration starts at that moment")
	assert_true(hud.sub_goal.lit, "the gift lights up")
	assert_eq(hud.sub_goal.label.text, SubGoal.label_text(old_goal, old_goal), "the label reads the goal reached")
	hud.likes_spring.advance(LikesSpring.DURATION - 0.01)
	assert_gt(hud.sub_goal.fill, 0.9, "nearly full")
	hud.likes_spring.advance(0.02)
	assert_eq(hud.sub_goal.fill, 1.0, "full, held while the square celebrates")
	assert_true(hud.sub_goal.lit)
	var hold := SubGoal.celebrate_length() - LikesSpring.DURATION
	hud.likes_spring.advance(hold - 0.03)
	assert_eq(hud.sub_goal.fill, 1.0, "still full just before the celebration ends")
	hud.likes_spring.advance(0.04)
	assert_lt(hud.sub_goal.fill, 0.1, "then starts again from empty")
	assert_false(hud.sub_goal.lit, "the gift greys again")
	assert_eq(hud.sub_goal.goal, int(ceilf(r.state.xp_needed())), "the next goal")
	hud.settle_likes()
	assert_almost_eq(hud.sub_goal.fill, r.state.xp / r.state.xp_needed(), 0.001, "and springs to the leftover")
	assert_eq(hud.sub_goal.subs, int(floorf(r.state.xp)))


func test_it_stops_while_the_game_is_paused() -> void:
	var r := _run()
	var hud: Hud = r.hud
	r.state.add_xp(r.state.xp_needed() * 0.5 / r.state.combo)
	assert_true(hud.likes_spring.active)
	assert_eq(hud.likes_spring.process_mode, Node.PROCESS_MODE_PAUSABLE)
	get_tree().paused = true
	var before := hud.sub_goal.fill
	await get_tree().create_timer(0.3, true).timeout
	assert_false(hud.likes_spring.can_process(), "paused")
	assert_eq(hud.sub_goal.fill, before, "the fill stands still")
	get_tree().paused = false
	await wait_seconds(0.4)
	assert_false(hud.likes_spring.active)


func test_draining_does_not_spring() -> void:
	var r := _run()
	var hud: Hud = r.hud
	r.state.add_xp(r.state.xp_needed() * 0.5 / r.state.combo)
	hud.settle_likes()
	var before := hud.sub_goal.fill
	r.state.xp -= 5.0
	r.state.xp_changed.emit(r.state.xp, r.state.xp_needed(), r.state.level)
	assert_lt(hud.sub_goal.fill, before)
	assert_false(hud.likes_spring.active, "going down is not animated")


func test_the_hold_only_follows_a_fill_then() -> void:
	var s := LikesSpring.new()
	add_child_autofree(s)
	s.spring_to(0.5)
	s.advance(LikesSpring.DURATION + 0.01)
	assert_false(s.active, "a plain gain stops at the duration")
	s.fill_then(0.2, 0.5)
	s.advance(LikesSpring.DURATION + 0.1)
	assert_eq(s.shown, 1.0, "held full")
	assert_true(s.has_follow)
	s.advance(0.45)
	assert_lt(s.shown, 0.2, "started again after the hold")
	assert_false(s.has_follow)
	s.fill_then(0.3, 5.0)
	s.finish()
	assert_almost_eq(s.shown, 0.3, 0.0001, "finish skips the hold")
