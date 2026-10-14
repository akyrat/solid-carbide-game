extends GutTest
## Task T-131: the combo heats up in steps (base, x2, x3, x4+) chosen from the
## multiplier as the counter shows it, each step bigger than the one before,
## the likes bar on fire only at the top step, the look following the combo
## down, the comic font with the words unchanged, no Redgull red, the layout
## holding at the top step and the effects standing still while paused.

const RUN := preload("res://scenes/run/run.tscn")
const GAME := preload("res://scenes/game/game.tscn")
const HUD_SCENE := preload("res://scenes/hud/hud.tscn")
const SIZES: Array[Vector2i] = [
	Vector2i(1152, 648), Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(1024, 576)]


func after_each() -> void:
	get_tree().paused = false


func _screen(size := Vector2i(1152, 648)) -> SubViewport:
	var sv := SubViewport.new()
	sv.size = size
	add_child_autofree(sv)
	return sv


func _run() -> Node2D:
	var r: Node2D = RUN.instantiate()
	_screen().add_child(r)
	return r


## Shows a multiplier on a HUD the way the run state does.
func _show(hud: Hud, multiplier: float) -> void:
	hud._on_combo_changed(multiplier)


func _font_size(l: Label) -> int:
	return l.get_theme_font_size("font_size")


func test_step_from_the_multiplier_at_two_decimals() -> void:
	var expect := {1.05: 0, 1.99: 0, 1.994: 0, 1.996: 1, 2.0: 1, 2.99: 1, 3.0: 2,
		3.99: 2, 4.0: 3, 4.5: 3, 6.0: 3}
	for m: float in expect:
		assert_eq(ComboHeat.step_for(m), expect[m], "x%s" % m)
	var r := _run()
	var hud: Hud = r.hud
	for m: float in [1.99, 2.0, 2.99, 3.0, 3.99, 4.0, 6.0]:
		_show(hud, m)
		assert_eq(hud.combo_step(), expect[m], "the HUD reports step %d at x%s" % [expect[m], m])


func test_thresholds_are_named_constants() -> void:
	assert_eq(ComboHeat.THRESHOLDS, [2.0, 3.0, 4.0] as Array[float])
	assert_eq(ComboHeat.FIRE_STEP, 3)


func test_each_step_is_bigger_than_the_one_before() -> void:
	var r := _run()
	var hud: Hud = r.hud
	var sizes: Array[int] = []
	var widths: Array[float] = []
	for m: float in [1.5, 2.0, 3.0, 4.0]:
		_show(hud, m)
		await get_tree().process_frame
		sizes.append(_font_size(hud.combo_label))
		hud.combo_label.text = Hud.combo_text(2.5)  # the same text, to compare sizes
		widths.append(hud.combo_label.get_combined_minimum_size().x)
	assert_eq(sizes[0], Hud.COMBO_FONT_SIZE, "the base look keeps the counter's size")
	for i in range(1, 4):
		assert_gt(sizes[i], sizes[i - 1], "step %d bigger than step %d" % [i, i - 1])
		assert_gt(widths[i], widths[i - 1], "step %d wider on screen than step %d" % [i, i - 1])


func test_each_step_looks_different() -> void:
	var seen := {}
	for st: Dictionary in ComboHeat.STEPS:
		seen[st.color] = true
	assert_eq(seen.size(), 4, "four different colours")
	var pulses: Array = ComboHeat.STEPS.map(func(st): return st.pulse)
	for i in range(1, 4):
		assert_gt(pulses[i], pulses[i - 1], "step %d pulses harder" % i)
	assert_gt(ComboHeat.STEPS[2].glow, 0, "step 2 glows")
	assert_gt(ComboHeat.STEPS[3].glow, ComboHeat.STEPS[2].glow, "step 3 glows more")


func test_fire_only_at_the_top_step() -> void:
	var r := _run()
	var hud: Hud = r.hud
	for m: float in [1.0, 1.5, 1.99, 2.0, 2.99, 3.0, 3.99]:
		_show(hud, m)
		assert_false(hud.fire_on(), "no fire at x%s" % m)
	for m: float in [4.0, 4.5, 6.0]:
		_show(hud, m)
		assert_true(hud.fire_on(), "fire at x%s" % m)
		assert_true(hud.likes_fire.is_visible_in_tree(), "the fire shows at x%s" % m)


func test_the_look_follows_the_combo_down() -> void:
	var r := _run()
	var hud: Hud = r.hud
	var state: RunState = r.state
	for i in 12:
		state.add_trick("alternate_drift")
	assert_almost_eq(state.combo, 6.0, 0.001, "at the cap")
	assert_eq(hud.combo_step(), 3)
	assert_true(hud.fire_on())
	# The drain: a 2 second wait, then 0.5 a second.
	var expect := [[2.0, 6.0, 3, true], [3.5, 4.25, 3, true], [1.0, 3.75, 2, false],
		[1.0, 3.25, 2, false], [1.0, 2.75, 1, false], [1.0, 2.25, 1, false],
		[1.0, 1.75, 0, false]]
	for e: Array in expect:
		state.advance(e[0])
		assert_almost_eq(state.combo, e[1], 0.001)
		assert_eq(hud.combo_step(), e[2], "step at x%s" % e[1])
		assert_eq(hud.fire_on(), e[3], "fire at x%s" % e[1])
		assert_true(hud.combo_label.visible, "shown at x%s" % e[1])
	state.advance(2.0)
	assert_eq(state.combo, ComboData.new().start_multiplier())
	assert_eq(hud.combo_step(), 0)
	assert_false(hud.fire_on())
	assert_false(hud.combo_label.visible, "hidden again at no combo (T-116)")


func test_a_collision_cuts_the_heat() -> void:
	var r := _run()
	var hud: Hud = r.hud
	for i in 12:
		r.state.add_trick("alternate_drift")
	assert_true(hud.fire_on())
	r.state.collision()
	assert_eq(hud.combo_step(), ComboHeat.step_for(r.state.combo))
	assert_lt(hud.combo_step(), 3, "a hit drops the heat")
	assert_false(hud.fire_on(), "and puts the fire out")
	assert_eq(_font_size(hud.combo_label), ComboHeat.STEPS[hud.combo_step()].font_size)


func test_comic_font_with_the_words_unchanged() -> void:
	var r := _run()
	var hud: Hud = r.hud
	for l: Label in [hud.combo_label, hud.likes_label, hud.level_label]:
		var f := l.get_theme_font("font") as FontFile
		assert_not_null(f, "%s has a font file" % l.name)
		assert_eq(f.get_font_name(), "Bangers", "%s in Bangers" % l.name)
		assert_eq(f.antialiasing, TextServer.FONT_ANTIALIASING_NONE, "%s: smoothing off" % l.name)
	# T-048 and T-082 text, unchanged (Bangers shows it in capitals).
	assert_eq(Hud.TEXT_LIKES, "Likes")
	assert_eq(Hud.TEXT_LEVEL, "Hype Lv {level}")
	assert_eq(Hud.TEXT_COMBO, "Combo x{multiplier}")
	assert_eq(hud.likes_label.text, "Likes")
	assert_eq(hud.level_label.text, "Hype Lv 1")
	r.state.add_trick("alternate_drift")
	assert_eq(hud.combo_label.text, "Combo x1.5")


func _assert_not_red(c: Color, what: String) -> void:
	var heart := Vector3(Hud.HEART_COLOR.r, Hud.HEART_COLOR.g, Hud.HEART_COLOR.b)
	assert_gt(Vector3(c.r, c.g, c.b).distance_to(heart), 0.5, "%s %s clear of the heart red" % [what, c])
	assert_false(c.s > 0.3 and (c.h < 0.04 or c.h > 0.96), "%s %s not a red hue" % [what, c])


func test_no_redgull_red() -> void:
	for c in ComboHeat.all_colors():
		_assert_not_red(c, "counter colour")
	for c in LikesFire.all_colors():
		_assert_not_red(c, "fire colour")
	# The colours really used on screen, over many animation frames.
	var r := _run()
	var hud: Hud = r.hud
	for m: float in [1.5, 2.0, 3.0, 6.0]:
		_show(hud, m)
		for f in 30:
			hud.combo_heat.time = f * ComboHeat.FLICKER_FRAME
			hud.combo_heat._animate()
			_assert_not_red(hud.combo_label.get_theme_color("font_color"), "counter at x%s" % m)
			var glow := hud.combo_label.get_theme_color("font_shadow_color")
			if glow.a > 0.0:
				_assert_not_red(glow, "glow at x%s" % m)


func test_flames_drawn_in_pixels_in_the_fire_palette() -> void:
	# The pixels the fire really draws, read back from a rendered screen
	# would need a GPU; instead check every column stays within its limits.
	var r := _run()
	var hud: Hud = r.hud
	r.state.add_xp(r.state.xp_needed() * 0.5)
	_show(hud, 6.0)
	await get_tree().process_frame
	var fire := hud.likes_fire
	assert_almost_eq(fire.fill_ratio, hud.likes_bar.value / hud.likes_bar.max_value, 0.01)
	var columns := int(fire.size.x / LikesFire.PIXEL)
	var tall_filled := 0
	for frame in 20:
		fire.frame = frame
		for i in columns:
			var h := fire.column_height(i)
			var x := (i + 0.5) * LikesFire.PIXEL
			assert_true(h <= LikesFire.MAX_HEIGHT and h >= 0, "column %d within the fire" % i)
			assert_eq(h % LikesFire.PIXEL, 0, "whole flame pixels")
			if x > fire.fill_ratio * fire.size.x:
				assert_lte(h, LikesFire.EMPTY_HEIGHT, "low over the empty part")
			for s in fire.low_spans:
				if x >= s.x and x <= s.y:
					assert_lte(h, LikesFire.TEXT_HEIGHT, "low under the texts")
			if h > LikesFire.TEXT_HEIGHT:
				tall_filled += 1
	assert_gt(tall_filled, 0, "flames rise over the filled part")


func test_layout_holds_at_the_top_step() -> void:
	for size in SIZES:
		var hud: Hud = HUD_SCENE.instantiate()
		_screen(size).add_child(hud)
		hud.level_label.text = Hud.TEXT_LEVEL.format({"level": 99})
		_show(hud, 5.75)
		await get_tree().process_frame
		var where := "%dx%d" % [size.x, size.y]
		var view := Rect2(Vector2.ZERO, Vector2(size))
		var bar := hud.likes_bar.get_global_rect()
		# Over the whole pulse, at its biggest and smallest.
		for f in 12:
			hud.combo_heat.time = f * ComboHeat.FLICKER_FRAME
			hud.combo_heat._animate()
			var combo := hud.combo_label.get_global_rect()
			var row := hud.likes_row.get_global_rect()
			var level := hud.level_label.get_global_rect()
			for n: String in ["combo", "likes row", "Hype Lv"]:
				var rect: Rect2 = {"combo": combo, "likes row": row, "Hype Lv": level}[n]
				assert_true(view.encloses(rect), "%s: %s inside the screen" % [where, n])
			assert_false(combo.intersects(row), "%s: combo clear of Likes" % where)
			assert_false(combo.intersects(level), "%s: combo clear of Hype Lv" % where)
			assert_almost_eq(combo.get_center().x, bar.get_center().x, 1.0, "%s: combo still centred" % where)
			var fire := hud.likes_fire.get_global_rect()
			assert_false(fire.intersects(combo), "%s: the flames stay clear of the counter" % where)
			assert_lte(fire.end.y, bar.position.y + LikesFire.INTO_BAR + 0.5,
				"%s: the flames reach only the top of the bar" % where)


func test_effects_stand_still_while_paused() -> void:
	var r := _run()
	var hud: Hud = r.hud
	_show(hud, 6.0)
	await wait_process_frames(3)
	get_tree().paused = true
	var heat_t := hud.combo_heat.time
	var fire_t := hud.likes_fire.time
	var fire_f := hud.likes_fire.frame
	var scale := hud.combo_label.scale
	await wait_process_frames(20)
	assert_eq(hud.combo_heat.time, heat_t, "the pulse stands still")
	assert_eq(hud.likes_fire.time, fire_t, "the flames stand still")
	assert_eq(hud.likes_fire.frame, fire_f)
	assert_eq(hud.combo_label.scale, scale)
	get_tree().paused = false
	await wait_process_frames(20)
	assert_gt(hud.combo_heat.time, heat_t, "moving again once unpaused")
	assert_gt(hud.likes_fire.time, fire_t)


func test_in_a_run_started_from_the_main_menu() -> void:
	var game: Node = GAME.instantiate()
	game.quit_game = func(): pass
	_screen().add_child(game)
	game.menu.start_button.pressed.emit()
	await wait_process_frames(2)
	var hud: Hud = game.run.hud
	var state: RunState = game.run.state
	assert_eq(hud.combo_step(), 0)
	assert_false(hud.fire_on())
	for i in 2:
		state.add_trick("alternate_drift")
	assert_eq(hud.combo_step(), 1, "x2.0")
	for i in 2:
		state.add_trick("alternate_drift")
	assert_eq(hud.combo_step(), 2, "x3.0")
	for i in 2:
		state.add_trick("alternate_drift")
	assert_eq(hud.combo_step(), 3, "x4.0")
	assert_true(hud.fire_on())
	await wait_process_frames(2)
	assert_true(hud.likes_fire.is_visible_in_tree(), "the fire shows in the game")
	assert_true(hud.combo_label.is_visible_in_tree())
