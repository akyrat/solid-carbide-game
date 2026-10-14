extends GutTest
## Task T-133: the trick popups heat up with the combo, on T-131's heat steps
## (ComboHeat). Below x2 the plain black and white popup; step 1 (x2), step 2
## (x3) and step 3 (x4 up, flaming) each add oranges and yellows. The fill
## stays white and the names black; no Redgull red and no semi-transparent
## pixels at any step; the drift prototype keeps the plain popup.

const RunScene := preload("res://scenes/run/run.tscn")
const PrototypeScene := preload("res://scenes/drift_prototype/drift_prototype.tscn")
const GameScene := preload("res://scenes/game/game.tscn")
const Popups := preload("res://scripts/hud/trick_popups.gd")
const Art := preload("res://scripts/hud/trick_popup_art.gd")
const Hud := preload("res://scripts/hud/hud.gd")

const CASES := [
	["LONG DRIFT! +0.05", "small"],
	["FULL 360! +0.25", "normal"],
	["ALT DRIFT! +0.5", "normal"],
	["ALT DRIFT!", "normal"],
	["Trending! +120 Likes", "normal"],
]


func _is_warm(p: Color) -> bool:
	# Orange or yellow: red full, green between, little blue.
	return p.a > 0.0 and p.r > 0.95 and p.g > 0.5 and p.g < 0.95 and p.b < 0.4


func _warm_count(img: Image) -> int:
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			if _is_warm(img.get_pixel(x, y)):
				n += 1
	return n


func _all_steps_and_frames() -> Array:
	var out := []
	for c in CASES:
		for heat in Art.HEAT_STEPS:
			var frames: int = Art.FLAME_FRAMES if heat >= Art.FLAME_STEP else 1
			for f in frames:
				out.append([c[0], c[1], heat, f])
	return out


func test_step_comes_from_the_multiplier_after_the_trick() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.start_run()
	var expect := {1.5: 0, 2.0: 1, 3.0: 2, 4.5: 3}
	for m in expect:
		run.state.combo_trick.emit("alternate_drift", 0.5, m)
		var shown: Array = run.trick_popups.popups()
		var p = shown[shown.size() - 1]
		assert_eq(p.text, "ALT DRIFT! +0.5")
		assert_eq(p.heat, expect[m], "a trick to x%s shows step %d" % [m, expect[m]])
		assert_eq(p.heat, ComboHeat.step_for(m), "the same step as the HUD counter")


func test_popup_and_hud_counter_share_the_thresholds() -> void:
	# One source: the popups ask ComboHeat.step_for, the HUD counter's step.
	for t in ComboHeat.THRESHOLDS:
		for m in [t - 0.01, t, t + 0.01]:
			assert_eq(Popups.heat_for(m), ComboHeat.step_for(m), "x%s" % m)
	var src := FileAccess.get_file_as_string("res://scripts/hud/trick_popups.gd")
	assert_true(src.contains("ComboHeat.step_for"), "trick_popups.gd uses ComboHeat.step_for")
	assert_false(src.contains("THRESHOLDS"), "no thresholds of its own")
	var art := FileAccess.get_file_as_string("res://scripts/hud/trick_popup_art.gd")
	assert_false(art.contains("THRESHOLDS"), "the art has no thresholds of its own")


func test_real_combo_chain_matches_the_hud_counter() -> void:
	# A run from the main menu: chain alternate drifts; each popup's step is
	# the HUD counter's step after that trick.
	var game: Node = GameScene.instantiate()
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var state = game.run.state
	var seen := {}
	for i in 8:
		state.add_trick("alternate_drift")
		var shown: Array = game.run.trick_popups.popups()
		var p = shown[shown.size() - 1]
		assert_eq(p.heat, game.run.hud.combo_heat.step, "trick %d at x%.2f: popup step = HUD step" % [i, state.combo])
		seen[p.heat] = true
	assert_eq(seen.keys().size(), 4, "the chain passes through all four steps")


func test_challenge_popup_follows_the_combo() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.start_run()
	run.state.combo = 1.4
	run.state.score.emit(100.0, "test")
	run.state.combo = 3.2
	run.state.score.emit(100.0, "test")
	var shown: Array = run.trick_popups.popups()
	assert_eq(shown[0].heat, 0, "below x2 the challenge popup is plain")
	assert_eq(shown[1].heat, 2, "at x3.2 it is step 2")


func test_drift_prototype_shows_plain_popups() -> void:
	var proto: Node2D = PrototypeScene.instantiate()
	add_child_autofree(proto)
	proto.car.trick.emit("three_sixty")
	proto.car.trick.emit("alternate_drift")
	assert_gt(proto.trick_popups.popups().size(), 0)
	for p in proto.trick_popups.popups():
		assert_eq(p.heat, 0, "no combo, plain popup")


func test_below_x2_is_the_plain_look() -> void:
	for c in CASES:
		var plain: Image = Art.bake(c[0], c[1])
		var step0: Image = Art.bake(c[0], c[1], 0)
		assert_eq(step0.get_data(), plain.get_data(), "%s: step 0 is the plain popup" % c[0])
		var other := 0
		for y in step0.get_height():
			for x in step0.get_width():
				var p := step0.get_pixel(x, y)
				if p.a > 0.0 and p != Color.WHITE and p != Color.BLACK:
					other += 1
		assert_eq(other, 0, "%s: step 0 is black, white and transparent only" % c[0])
	assert_same(Art.texture("FULL 360!", "normal", 0), Art.texture("FULL 360!", "normal"), "same cached texture")


func test_each_step_adds_its_own_warm_accent() -> void:
	for c in CASES:
		var imgs := []
		for heat in Art.HEAT_STEPS:
			imgs.append(Art.bake(c[0], c[1], heat))
		assert_eq(_warm_count(imgs[0]), 0, "%s: no warm colour below x2" % c[0])
		var prev := 0
		for heat in range(1, Art.HEAT_STEPS):
			var n := _warm_count(imgs[heat])
			assert_gt(n, prev, "%s: step %d has more orange and yellow than step %d" % [c[0], heat, heat - 1])
			prev = n
		for a in Art.HEAT_STEPS:
			for b in range(a + 1, Art.HEAT_STEPS):
				var same: bool = imgs[a].get_size() == imgs[b].get_size() and imgs[a].get_data() == imgs[b].get_data()
				assert_false(same, "%s: step %d and step %d differ" % [c[0], a, b])


func test_no_redgull_red_and_no_semi_transparent_pixels_at_any_step() -> void:
	var heart: Color = Hud.HEART_COLOR
	var heart_v := Vector3(heart.r, heart.g, heart.b)
	for i in range(1, Art.PALETTE.size()):
		var col: Color = Art.PALETTE[i]
		assert_gt(Vector3(col.r, col.g, col.b).distance_to(heart_v), 0.5, "palette colour %d is clear of the heart red" % i)
	for k in _all_steps_and_frames():
		var img: Image = Art.bake(k[0], k[1], k[2], k[3])
		var bad_alpha := 0
		var red := 0
		var rim := 0.0
		for y in img.get_height():
			for x in img.get_width():
				var p := img.get_pixel(x, y)
				if p.a != 0.0 and p.a != 1.0:
					bad_alpha += 1
				if p.a > 0.0 and Vector3(p.r, p.g, p.b).distance_to(heart_v) <= 0.5:
					red += 1
				if x == 0 or y == 0 or x == img.get_width() - 1 or y == img.get_height() - 1:
					rim += p.a
		assert_eq(bad_alpha, 0, "%s step %d frame %d: no semi-transparent pixels" % [k[0], k[2], k[3]])
		assert_eq(red, 0, "%s step %d frame %d: no Redgull red" % [k[0], k[2], k[3]])
		assert_eq(rim, 0.0, "%s step %d frame %d: transparent rim" % [k[0], k[2], k[3]])


func test_fill_stays_white_and_names_stay_black() -> void:
	for c in CASES:
		var name: String = Art.split_text(c[0])[0]
		var name_box: Rect2i = Art.text_box(name, c[1])
		for heat in Art.HEAT_STEPS:
			var img: Image = Art.bake(c[0], c[1], heat)
			var box: Rect2i = Art.text_box(c[0], c[1], heat)
			# The fill: left of the letters and above them, in the padding.
			var mid := box.position.y + box.size.y / 2
			assert_eq(img.get_pixel(box.position.x - 2, mid), Color.WHITE, "%s step %d: white fill left of the text" % [c[0], heat])
			assert_eq(img.get_pixel(box.position.x + box.size.x / 2, box.position.y - 2), Color.WHITE, "%s step %d: white fill above the text" % [c[0], heat])
			# The name: the part of the lettering as wide as the name alone is black and white only.
			var black := 0
			var other := 0
			for y in box.size.y:
				for x in name_box.size.x - 1:
					var p := img.get_pixel(box.position.x + x, box.position.y + y)
					if p == Color.BLACK:
						black += 1
					elif p != Color.WHITE:
						other += 1
			assert_eq(other, 0, "%s step %d: the name is black on white" % [c[0], heat])
			assert_gt(black, 40, "%s step %d: black name letters" % [c[0], heat])


func test_amount_is_orange_from_step_2() -> void:
	for heat in Art.HEAT_STEPS:
		var img: Image = Art.bake("FULL 360! +0.25", "normal", heat)
		var box: Rect2i = Art.text_box("FULL 360! +0.25", "normal", heat)
		var orange := 0
		for y in box.size.y:
			for x in range(int(box.size.x * 0.75), box.size.x):
				if img.get_pixel(box.position.x + x, box.position.y + y) == Art.PALETTE[Art.AMOUNT_HOT]:
					orange += 1
		if heat >= Art.AMOUNT_HOT_STEP:
			assert_gt(orange, 30, "step %d: orange amount" % heat)
		else:
			assert_eq(orange, 0, "step %d: black amount" % heat)


func test_flaming_step_flickers_through_frames() -> void:
	var tp: Node2D = Popups.new()
	add_child_autofree(tp)
	var p = tp.show_popup("ALT DRIFT! +0.5", Vector2.ZERO, Popups.SIZE_NORMAL, Callable(), 3)
	var first: ImageTexture = p.texture()
	p.advance(ComboHeat.FLICKER_FRAME * 1.5)
	assert_ne(p.texture(), first, "a new flame frame")
	var a: Image = Art.bake("ALT DRIFT! +0.5", "normal", 3, 0)
	var b: Image = Art.bake("ALT DRIFT! +0.5", "normal", 3, 1)
	assert_ne(a.get_data(), b.get_data(), "frames differ")
	# Flames rise over the top: flame pixels above the bubble's top edge.
	var box: Rect2i = Art.text_box("ALT DRIFT! +0.5", "normal", 3)
	var above := 0
	for y in box.position.y - Art.MARGIN_Y - 4:
		for x in a.get_width():
			var px := a.get_pixel(x, y)
			if _is_warm(px) or px == Art.PALETTE[Art.FLAME_0]:
				above += 1
	assert_gt(above, 100, "flames above the popup")
	# A plain popup never changes texture.
	var q = tp.show_popup("FULL 360!", Vector2.ZERO)
	var t0: ImageTexture = q.texture()
	q.advance(0.5)
	assert_same(q.texture(), t0)


func test_stacking_size_is_the_plain_bubble_at_every_step() -> void:
	var tp: Node2D = Popups.new()
	add_child_autofree(tp)
	var plain = tp.show_popup("ALT DRIFT! +0.5", Vector2.ZERO)
	var hot = tp.show_popup("ALT DRIFT! +0.5", Vector2.ZERO, Popups.SIZE_NORMAL, Callable(), 3)
	assert_eq(hot.size(), plain.size())
	assert_eq(hot.z_index, Popups.POPUP_Z, "still above the buildings")
	assert_false(hot.z_as_relative)
