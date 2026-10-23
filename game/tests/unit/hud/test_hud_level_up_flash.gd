extends GutTest
## Task T-139: the likes bar's level-up animation. It starts at the level-up,
## ends within its length and leaves the bar and texts as they were, plays
## while the run is paused and while it keeps going, ignores other changes to
## the bar, stays clear of the other HUD parts at the HUD's window sizes and
## never uses Redgull red.

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


func _level_up(r: Node2D) -> void:
	r.state.add_xp(r.state.xp_needed() / maxf(r.state.combo, 1.0) + 0.01)


func test_starts_at_the_level_up_and_ends_within_its_length() -> void:
	var r := _run()
	var f: LevelUpFlash = r.hud.level_up_flash
	assert_false(f.playing)
	assert_false(f.visible)
	_level_up(r)
	assert_eq(r.state.level, 2)
	assert_true(f.playing)
	assert_eq(f.plays, 1)
	assert_almost_eq(LevelUpFlash.length(), 0.75, 0.001)
	f.advance(LevelUpFlash.length() - 0.02)
	assert_true(f.playing, "still playing just before its length")
	f.advance(0.03)
	assert_false(f.playing)
	assert_false(f.visible)


func test_leaves_the_bar_and_texts_as_they_were() -> void:
	var r := _run()
	var hud: Hud = r.hud
	_level_up(r)
	hud.settle_likes()
	var value := hud.likes_bar.value
	var max_v := hud.likes_bar.max_value
	var text := hud.level_label.text
	var pos := hud.level_label.position
	assert_eq(text, "Hype Lv 2")
	var seen_big := false
	for i in 20:
		hud.level_up_flash.advance(ComboHeat.FLICKER_FRAME)
		seen_big = seen_big or hud.level_label.scale.x > 1.1
		assert_eq(hud.likes_bar.value, value, "the bar's value is never touched")
		assert_eq(hud.likes_bar.max_value, max_v)
		assert_eq(hud.level_label.text, text, "the new level shows the whole time")
		assert_eq(hud.level_label.position, pos)
	assert_true(seen_big, "the label pops")
	assert_eq(hud.level_label.scale, Vector2.ONE)
	assert_eq(hud.level_label.get_theme_color("font_color"), Hud.LABEL_COLOR)
	assert_lt(hud.likes_bar.value, hud.likes_bar.max_value * 0.5, "the bar starts again")
	assert_true(hud.level_up_flash.overlay_rects(8).is_empty())


func test_plays_while_the_run_is_paused() -> void:
	var r := _run()
	r.state.pause_on_level_up = true
	_level_up(r)
	assert_true(r.state.is_waiting_for_choice(), "the level-up paused the run")
	var f: LevelUpFlash = r.hud.level_up_flash
	assert_true(f.playing)
	assert_eq(f.process_mode, Node.PROCESS_MODE_ALWAYS)
	assert_true(f.can_process(), "it processes even though the tree is paused")
	f.advance(ComboHeat.FLICKER_FRAME * 3.5)
	assert_eq(f.frame, 3)
	f.advance(1.0)
	assert_false(f.playing)


func test_plays_in_real_frames_while_the_tree_is_paused() -> void:
	var r := _run()
	_level_up(r)
	get_tree().paused = true
	var f: LevelUpFlash = r.hud.level_up_flash
	await get_tree().create_timer(0.3, true).timeout
	assert_gt(f.time, 0.1, "time moved on while paused")
	await get_tree().create_timer(0.7, true).timeout
	assert_false(f.playing)


func test_plays_while_the_run_keeps_going() -> void:
	var r := _run()
	r.state.pause_on_level_up = false
	_level_up(r)
	assert_false(r.state.is_waiting_for_choice())
	assert_true(r.hud.level_up_flash.playing)
	assert_true(r.state.running)


func test_other_changes_to_the_bar_do_not_play_it() -> void:
	var r := _run()
	var f: LevelUpFlash = r.hud.level_up_flash
	r.state.add_xp(r.state.xp_needed() * 0.3)
	assert_false(f.playing, "likes going up")
	assert_eq(f.plays, 0)
	r.state._set_combo(3.0)
	r.state.add_xp(0.01)
	r.state._set_combo(1.0)
	r.state._drain_combo(1.0)
	assert_eq(f.plays, 0, "a combo change or its drain")
	r.state.damage_car(1.0)
	r.state.add_coins(3)
	assert_eq(f.plays, 0)


func test_two_level_ups_in_a_row_restart_it() -> void:
	var r := _run()
	_level_up(r)
	r.hud.level_up_flash.advance(0.3)
	_level_up(r)
	assert_eq(r.hud.level_up_flash.plays, 2)
	assert_eq(r.hud.level_up_flash.frame, 0)
	assert_eq(r.hud.level_label.text, "Hype Lv 3")


func test_a_new_run_state_stops_it() -> void:
	var r := _run()
	_level_up(r)
	r.hud.bind(r.state)
	assert_false(r.hud.level_up_flash.playing)
	assert_eq(r.hud.level_label.scale, Vector2.ONE)


func test_no_redgull_red_and_hard_pixel_edges() -> void:
	for c in LevelUpFlash.all_colors():
		assert_false(c.r > 0.7 and c.g < 0.35 and c.b < 0.35, "not red: %s" % c)
		var h := Hud.HEART_COLOR
		assert_gt(absf(c.r - h.r) + absf(c.g - h.g) + absf(c.b - h.b), 0.6, "not near the heart's red: %s" % c)
		assert_eq(c.a, 1.0, "no semi-transparent colour")
	var r := _run()
	var f: LevelUpFlash = r.hud.level_up_flash
	assert_eq(f.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	for i in LevelUpFlash.FRAME_COUNT:
		for pair in f.overlay_rects(i) + f.spark_rects(i):
			var rect: Rect2 = pair[0]
			assert_eq(fmod(rect.position.x, 2.0), 0.0, "on the pixel grid")
			assert_eq(fmod(rect.size.x, 2.0), 0.0)


func test_clear_of_the_other_hud_parts_at_every_size() -> void:
	for size in SIZES:
		var r := _run(size)
		var hud: Hud = r.hud
		r.state._set_combo(4.5)  # the counter at its biggest step
		await wait_frames(2)
		_level_up(r)
		var f := hud.level_up_flash
		var combo := hud.combo_label.get_global_rect()
		var bar := hud.likes_bar.get_global_rect()
		var view := Rect2(Vector2.ZERO, Vector2(size))
		for i in LevelUpFlash.FRAME_COUNT:
			f.advance(ComboHeat.FLICKER_FRAME if i > 0 else 0.0)
			var label := hud.level_label.get_global_rect()
			assert_true(view.encloses(label.grow(0)), "label on screen %s frame %d" % [size, i])
			var grown_h := hud.level_label.size.y * (hud.level_label.scale.y - 1.0)
			var grown_w := hud.level_label.size.x * (hud.level_label.scale.x - 1.0)
			var popped := Rect2(label.position - Vector2(grown_w, grown_h), label.size + Vector2(grown_w, grown_h))
			assert_false(popped.intersects(combo), "popped label clear of the combo %s frame %d" % [size, i])
			assert_lte(popped.end.x, bar.end.x + 0.01, "not past the bar's end")
			for pair in f.overlay_rects(i) + f.spark_rects(i):
				var g := Rect2(pair[0].position + f.global_position, pair[0].size)
				assert_false(g.intersects(combo), "effect clear of the combo %s frame %d" % [size, i])
				assert_lte(g.end.y, bar.end.y + 0.01)
				assert_true(g.position.x >= bar.position.x - 0.01 and g.end.x <= bar.end.x + 0.01)
				assert_gte(g.position.y, bar.position.y - LevelUpFlash.MAX_UP - 0.01)
