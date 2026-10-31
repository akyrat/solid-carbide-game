extends GutTest
## Task T-337: the sub goal square replaces the likes bar and its row. A black
## square (T-339's frame) that fills green from the bottom with the subs share
## of the goal, the gift pack inside it at 80% (grey and dimmed until the goal,
## full colour at it), "{subs} / {goal} SUBS" (T-331) with the subs icon under
## it, on the right edge at the board's layout (x988 y340, 128 x 180 at
## 1152 x 648). At the goal it celebrates (the gift bounces, the square glows),
## the level-up goes on, then it starts again from empty.

const RUN := preload("res://scenes/run/run.tscn")
const HUD_SCENE := preload("res://scenes/hud/hud.tscn")
const GREENBULL := [Color8(104, 220, 96), Color8(247, 208, 52), Color8(12, 76, 44)]


func after_each() -> void:
	get_tree().paused = false


func _run(size := Vector2i(1152, 648)) -> Node2D:
	var sv := SubViewport.new()
	sv.size = size
	add_child_autofree(sv)
	var r: Node2D = RUN.instantiate()
	sv.add_child(r)
	return r


func _goal() -> SubGoal:
	var sg := SubGoal.new()
	add_child_autofree(sg)
	return sg


func test_at_the_boards_layout_anchored_to_the_right_edge() -> void:
	var r := _run()
	await get_tree().process_frame
	var sg: SubGoal = r.hud.sub_goal
	assert_eq(sg.anchor_left, 1.0, "anchored to the right edge")
	assert_eq(sg.anchor_right, 1.0)
	assert_almost_eq(sg.anchor_top, 340.0 / 648.0, 0.0001, "about two thirds down")
	var rect := sg.get_global_rect()
	assert_almost_eq(rect.position, Vector2(988, 340), Vector2(0.5, 0.5), "x988 y340 at 1152 x 648")
	assert_almost_eq(rect.size, Vector2(128, 180), Vector2(0.5, 0.5), "128 x 180")


func test_keeps_its_right_margin_at_other_sizes() -> void:
	for size: Vector2i in [Vector2i(1920, 1080), Vector2i(1024, 576)]:
		var r := _run(size)
		await get_tree().process_frame
		var rect: Rect2 = r.hud.sub_goal.get_global_rect()
		# T-431: the margin is in the layout page's pixels, times the HUD's scale.
		assert_almost_eq(size.x - rect.end.x, 36.0 * r.hud.hud_scale(), 0.5, "%s: 36 px from the right edge" % size)
		assert_almost_eq(rect.position.y, size.y * 340.0 / 648.0, 1.0, "%s" % size)


func test_the_frame_and_icon_are_t339s_art_at_2x() -> void:
	var sg := _goal()
	assert_eq(sg.square_size, Vector2(128, 128))
	assert_eq(sg.icon.texture.resource_path, SubGoal.ICON_PATH)
	assert_eq(sg.icon.custom_minimum_size, sg.icon.texture.get_size() * 2)
	assert_eq(sg.icon.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	assert_true(SubGoal.FRAME_PATH.ends_with("subgoal_frame.png"))


func test_the_inside_is_the_frames_black_from_4_to_59() -> void:
	var sg := _goal()
	assert_eq(sg.inside_row_count(), 56, "art rows 4 to 59")
	var rows := SubGoal.inside_rows((load(SubGoal.FRAME_PATH) as Texture2D).get_image())
	assert_eq(rows[0].x, 4)
	assert_eq(rows[rows.size() - 1].x, 59)
	var mid: Vector3i = rows[28]
	assert_eq(Vector2i(mid.y, mid.z), Vector2i(4, 59), "full width in the middle")
	assert_gt(rows[0].y, 4, "rounded inner corners: the top row starts further in")


func test_fill_is_the_share_of_the_goal_in_whole_art_rows() -> void:
	var sg := _goal()
	sg.fill = 0.0
	assert_eq(sg.filled_rows(), 0)
	sg.fill = 0.5
	assert_eq(sg.filled_rows(), 28)
	sg.fill = 1.0
	assert_eq(sg.filled_rows(), 56)
	sg.fill = 1.3
	assert_eq(sg.fill, 1.0, "never past full")
	assert_eq(sg.filled_rows(), 56)


func test_the_fill_follows_the_run_with_the_spring() -> void:
	var r := _run()
	var hud: Hud = r.hud
	var need: float = r.state.xp_needed()
	r.state.add_xp(need * 0.4)
	assert_eq(hud.sub_goal.fill, 0.0, "springs, no jump")
	assert_true(hud.likes_spring.active)
	hud.likes_spring.advance(LikesSpring.DURATION * 0.6)
	assert_gt(hud.sub_goal.fill, 0.4, "overshoots on the way")
	hud.settle_likes()
	assert_almost_eq(hud.sub_goal.fill, r.state.xp / need, 0.001)
	assert_false(hud.sub_goal.lit, "grey until the goal")


func test_the_drain_empties_it_slowly() -> void:
	var r := _run()
	var hud: Hud = r.hud
	r.state.add_xp(r.state.xp_needed() * 0.5)
	hud.settle_likes()
	var before := hud.sub_goal.fill
	r.state.xp -= 3.0
	r.state.xp_changed.emit(r.state.xp, r.state.xp_needed(), r.state.level)
	assert_lt(hud.sub_goal.fill, before)
	assert_almost_eq(hud.sub_goal.fill, r.state.xp / r.state.xp_needed(), 0.001, "follows the drain")
	assert_false(hud.likes_spring.active, "no spring going down")


func test_gift_is_centred_at_80_percent_of_the_square() -> void:
	var sg := _goal()
	assert_eq(sg.gift.size, Vector2(102, 102), "80% of 128, rounded")
	assert_almost_eq(sg.gift.position + sg.gift.size / 2.0, sg.square_size / 2.0, Vector2(0.5, 0.5), "centred")
	var drawn := sg.gift_drawn_rect()
	assert_almost_eq(maxf(drawn.size.x, drawn.size.y), 102.0, 0.5, "its long side fills the 80%")
	assert_almost_eq(drawn.get_center(), sg.square_size / 2.0, Vector2(0.5, 0.5))
	assert_gte(drawn.position.x, 12.8 - 0.5, "a 10% margin")
	assert_gte(drawn.position.y, 12.8 - 0.5)
	assert_eq(sg.gift.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)


func test_gift_is_the_package_cropped_to_its_box() -> void:
	var sg := _goal()
	var img := (load(SubGoal.GIFT_PATH) as Texture2D).get_image()
	var used := img.get_used_rect()
	sg.lit = true
	assert_eq(Vector2i(sg.gift.texture.get_size()), used.size, "cropped to the art's box")
	var shown := sg.gift.texture.get_image()
	img.convert(Image.FORMAT_RGBA8)
	for p: Vector2i in [used.size / 2, Vector2i(3, used.size.y - 3)]:
		assert_eq(shown.get_pixelv(p), img.get_pixelv(used.position + p), "full colour when lit")


func test_gift_is_grey_and_dimmed_until_the_goal() -> void:
	var sg := _goal()
	assert_false(sg.lit)
	var grey := sg.gift.texture.get_image()
	var opaque := 0
	for y in grey.get_height():
		for x in grey.get_width():
			var c := grey.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			opaque += 1
			assert_almost_eq(c.r, c.g, 0.01, "grey")
			assert_almost_eq(c.g, c.b, 0.01, "grey")
			assert_lte(c.r, SubGoal.GREY_DIM + 0.01, "dimmed")
	assert_gt(opaque, 100, "the gift's pixels are there")
	sg.lit = true
	assert_ne(sg.gift.texture, null)
	var col := sg.gift.texture.get_image()
	var c := col.get_pixelv(col.get_size() / 2)
	assert_false(is_equal_approx(c.r, c.g) and is_equal_approx(c.g, c.b), "in colour once lit")
	sg.lit = false
	assert_lte(sg.gift.texture.get_image().get_pixelv(col.get_size() / 2).r, SubGoal.GREY_DIM + 0.01, "grey again")


func test_label_under_the_square_from_t331s_text() -> void:
	var r := _run()
	var hud: Hud = r.hud
	await get_tree().process_frame
	var need := int(ceilf(r.state.xp_needed()))
	assert_eq(hud.sub_goal.label.text, "0 / %d SUBS" % need)
	r.state.add_xp(20.4)  # T-328: under level 1's 30, was 42.4 under the old 100
	assert_eq(hud.sub_goal.label.text, Hud.TEXT_SUB_GOAL.format({"subs": 20, "goal": need}))
	assert_eq(SubGoal.label_text(42, 156), "42 / 156 SUBS")
	var label := hud.sub_goal.label_row.get_global_rect()
	var square := Rect2(hud.sub_goal.get_global_rect().position, hud.sub_goal.square_size)
	assert_gte(label.position.y, square.end.y, "under the square")
	assert_almost_eq(label.get_center().x, square.get_center().x, 1.0, "centred under it")
	assert_eq(hud.sub_goal.icon.get_parent(), hud.sub_goal.label_row, "the subs icon beside the text")
	assert_lt(hud.sub_goal.icon.get_global_rect().end.x, hud.sub_goal.label.get_global_rect().position.x + 0.5)


func test_sub_numbers() -> void:
	assert_eq(Hud.sub_numbers(42.7, 156.0), [42, 156])
	assert_eq(Hud.sub_numbers(-1.0, 10.0), [0, 10])
	assert_eq(Hud.sub_numbers(500.0, 0.0), [500, 500], "top level: reads full")


func test_reaching_the_goal_lights_the_gift_and_celebrates() -> void:
	var r := _run()
	var hud: Hud = r.hud
	r.state.pause_on_level_up = false
	var need: float = r.state.xp_needed()
	r.state.add_xp(need * 0.8)
	hud.settle_likes()
	assert_false(hud.sub_goal.lit)
	assert_eq(hud.sub_goal.celebrations, 0)
	r.state.add_xp(need * 0.3)
	assert_eq(r.state.level, 2, "the level-up goes on as before")
	assert_true(hud.sub_goal.lit, "lit at the goal")
	assert_true(hud.sub_goal.celebrating)
	assert_eq(hud.sub_goal.celebrations, 1)


func test_the_celebration_bounces_glows_and_ends() -> void:
	var sg := _goal()
	sg.celebrate()
	assert_eq(sg.process_mode, Node.PROCESS_MODE_ALWAYS, "plays whether the run pauses or not")
	var scales: Array[float] = []
	var glows := 0
	for f in SubGoal.CELEBRATE_FRAMES:
		sg.advance(ComboHeat.FLICKER_FRAME if f > 0 else 0.0001)
		assert_true(sg.celebrating)
		scales.append(sg.gift.scale.x)
		if sg.glow_color().a > 0.0:
			glows += 1
	assert_gt(scales.max(), 1.1, "the gift bounces up")
	assert_lt(scales.min(), 1.0, "and back past rest")
	assert_gt(glows, 4, "the square glows")
	sg.advance(ComboHeat.FLICKER_FRAME)
	assert_false(sg.celebrating, "ends after %d frames" % SubGoal.CELEBRATE_FRAMES)
	assert_eq(sg.gift.scale, Vector2.ONE, "the gift back at rest")
	assert_eq(sg.glow_color().a, 0.0)
	assert_almost_eq(SubGoal.celebrate_length(), 1.0, 0.001)


func test_glow_and_fill_colours_are_not_greenbulls_or_the_heart_red() -> void:
	var cols: Array = SubGoal.GLOW_COLORS.duplicate()
	cols.append(SubGoal.FILL_COLOR)
	cols.append(SubGoal.FILL_TOP_COLOR)
	for c: Color in cols:
		for gb: Color in GREENBULL:
			assert_gt(Vector3(c.r, c.g, c.b).distance_to(Vector3(gb.r, gb.g, gb.b)), 0.1, "%s not Greenbull's %s" % [c, gb])
		assert_false(c.s > 0.3 and (c.h < 0.04 or c.h > 0.96), "%s not red" % c)
	assert_gt(SubGoal.FILL_COLOR.g, SubGoal.FILL_COLOR.r, "the fill is green")


func test_a_new_run_stops_it_and_starts_empty() -> void:
	var r := _run()
	var hud: Hud = r.hud
	r.state.pause_on_level_up = false
	r.state.add_xp(r.state.xp_needed() * 1.2)
	assert_true(hud.sub_goal.celebrating)
	r.start_run()
	assert_false(hud.sub_goal.celebrating)
	assert_eq(hud.sub_goal.fill, 0.0)
	assert_false(hud.sub_goal.lit)
	assert_eq(hud.sub_goal.gift.scale, Vector2.ONE)


func test_in_a_run_started_from_the_main_menu() -> void:
	var sv := SubViewport.new()
	sv.size = Vector2i(1152, 648)
	add_child_autofree(sv)
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	game.quit_game = func(): pass
	sv.add_child(game)
	game.menu.start_button.pressed.emit()
	await wait_process_frames(2)
	var hud: Hud = game.run.hud
	assert_true(hud.sub_goal.is_visible_in_tree())
	assert_true(hud.sub_goal.gift.is_visible_in_tree())
	assert_false(hud.sub_goal.lit)
