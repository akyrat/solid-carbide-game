extends GutTest
## Task T-084: the baked comic look of the trick popups. Hard pixels only (no
## semi-transparent ones), no Redgull red, a burst that fits each text, the
## same texture for the same text.

const Art := preload("res://scripts/hud/trick_popup_art.gd")
const Hud := preload("res://scripts/hud/hud.gd")
const Popups := preload("res://scripts/hud/trick_popups.gd")

## Every text the popups show (T-082 and T-048), with the size the game uses for it.
const CASES := [
	["LONG DRIFT!", "small"],
	["LONG DRIFT! +0.05", "small"],
	["FULL 360!", "normal"],
	["FULL 360! +0.25", "normal"],
	["ALT DRIFT!", "normal"],
	["ALT DRIFT! +0.5", "normal"],
	["Trending! +1 Likes", "normal"],
	["Trending! +120 Likes", "normal"],
]


func test_no_semi_transparent_pixels() -> void:
	for c in CASES:
		var img: Image = Art.bake(c[0], c[1])
		assert_eq(img.get_format(), Image.FORMAT_RGBA8)
		var bad := 0
		for y in img.get_height():
			for x in img.get_width():
				var a := img.get_pixel(x, y).a
				if a != 0.0 and a != 1.0:
					bad += 1
		assert_eq(bad, 0, "%s: no semi-transparent pixels" % c[0])


func test_transparent_border() -> void:
	for c in CASES:
		var img: Image = Art.bake(c[0], c[1])
		for x in img.get_width():
			assert_eq(img.get_pixel(x, 0).a, 0.0, c[0])
			assert_eq(img.get_pixel(x, img.get_height() - 1).a, 0.0, c[0])
		for y in img.get_height():
			assert_eq(img.get_pixel(0, y).a, 0.0, c[0])
			assert_eq(img.get_pixel(img.get_width() - 1, y).a, 0.0, c[0])


func test_no_colour_near_redgull_red() -> void:
	var heart: Color = Hud.HEART_COLOR
	var heart_v := Vector3(heart.r, heart.g, heart.b)
	for i in Art.PALETTE.size():
		var col: Color = Art.PALETTE[i]
		if i == 0:
			continue
		assert_gt(Vector3(col.r, col.g, col.b).distance_to(heart_v), 0.5, "palette colour %d is clear of the heart red" % i)
	for c in CASES:
		var img: Image = Art.bake(c[0], c[1])
		for y in img.get_height():
			for x in img.get_width():
				var p := img.get_pixel(x, y)
				if p.a > 0.0:
					assert_gt(Vector3(p.r, p.g, p.b).distance_to(heart_v), 0.5, "%s: pixel colour clear of the heart red" % c[0])


	pass


func test_few_colours() -> void:
	for c in CASES:
		var img: Image = Art.bake(c[0], c[1])
		var seen := {}
		for y in img.get_height():
			for x in img.get_width():
				var p := img.get_pixel(x, y)
				if p.a > 0.0:
					seen[p.to_html(false)] = true
		assert_lt(seen.size(), 30, "%s: under 30 colours" % c[0])


func test_burst_fits_the_text() -> void:
	for c in CASES:
		var img: Image = Art.bake(c[0], c[1])
		var box: Rect2i = Art.text_box(c[0], c[1])
		assert_gt(box.position.x, 4, "%s: room left of the text" % c[0])
		assert_gt(box.position.y, 4, "%s: room above the text" % c[0])
		assert_gt(img.get_width() - box.end.x, 4, "%s: room right of the text" % c[0])
		assert_gt(img.get_height() - box.end.y, 4, "%s: room below the text" % c[0])
		# The four corners just outside the text box are burst, not transparent.
		for corner in [Vector2i(box.position.x - 1, box.position.y - 1), Vector2i(box.end.x, box.position.y - 1),
				Vector2i(box.position.x - 1, box.end.y), Vector2i(box.end.x, box.end.y)]:
			assert_gt(img.get_pixelv(corner).a, 0.0, "%s: burst covers the text box corners" % c[0])


func test_longer_text_gets_a_wider_burst() -> void:
	assert_gt(Art.bake("Trending! +120 Likes", "normal").get_width(), Art.bake("FULL 360! +0.25", "normal").get_width())
	assert_lt(Art.bake("LONG DRIFT! +0.05", "small").get_height(), Art.bake("FULL 360! +0.25", "normal").get_height())


func test_same_text_gives_the_same_texture_and_image() -> void:
	assert_same(Art.texture("FULL 360! +0.25", "normal"), Art.texture("FULL 360! +0.25", "normal"), "cached")
	assert_ne(Art.texture("FULL 360! +0.25", "normal"), Art.texture("FULL 360! +0.25", "small"), "per size")
	assert_eq(Art.bake("ALT DRIFT! +0.5", "normal").get_data(), Art.bake("ALT DRIFT! +0.5", "normal").get_data(), "deterministic")


func test_name_is_pink_and_amount_is_cyan() -> void:
	var img: Image = Art.bake("FULL 360! +0.25", "normal")
	var box: Rect2i = Art.text_box("FULL 360! +0.25", "normal")
	var pink: Color = Art.PALETTE[Art.NAME]
	var cyan: Color = Art.PALETTE[Art.AMOUNT]
	var left_pink := 0
	var right_cyan := 0
	for y in box.size.y:
		for x in box.size.x:
			var p := img.get_pixel(box.position.x + x, box.position.y + y)
			if p == pink and x < box.size.x / 2:
				left_pink += 1
			if p == cyan and x > box.size.x * 0.7:
				right_cyan += 1
	assert_gt(left_pink, 50, "the name is pink")
	assert_gt(right_cyan, 20, "the amount is cyan")


func test_popup_uses_the_baked_texture_with_nearest_filtering() -> void:
	var tp: Node2D = Popups.new()
	add_child_autofree(tp)
	var p = tp.show_popup("FULL 360!", Vector2.ZERO)
	await get_tree().process_frame
	assert_eq(p.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	assert_eq(Art.style_for(Popups.SIZE_SMALL), "small")
	assert_eq(Art.style_for(Popups.SIZE_NORMAL), "normal")


func test_empty_text_does_not_break() -> void:
	var img: Image = Art.bake("", "normal")
	assert_gt(img.get_width(), 0)
