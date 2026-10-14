extends GutTest
## Task T-084: the baked comic look (white rounded rectangle, black border, black letters) of the trick popups. Hard pixels only (no
## semi-transparent ones), no Redgull red, a rounded rectangle that fits each text, the
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


func test_bubble_fits_the_text() -> void:
	for c in CASES:
		var img: Image = Art.bake(c[0], c[1])
		var box: Rect2i = Art.text_box(c[0], c[1])
		assert_gt(box.position.x, 4, "%s: room left of the text" % c[0])
		assert_gt(box.position.y, 4, "%s: room above the text" % c[0])
		assert_gt(img.get_width() - box.end.x, 4, "%s: room right of the text" % c[0])
		assert_gt(img.get_height() - box.end.y, 4, "%s: room below the text" % c[0])
		# The four corners just outside the text box are bubble, not transparent.
		for corner in [Vector2i(box.position.x - 1, box.position.y - 1), Vector2i(box.end.x, box.position.y - 1),
				Vector2i(box.position.x - 1, box.end.y), Vector2i(box.end.x, box.end.y)]:
			assert_gt(img.get_pixelv(corner).a, 0.0, "%s: bubble covers the text box corners" % c[0])


func test_longer_text_gets_a_wider_bubble() -> void:
	assert_gt(Art.bake("Trending! +120 Likes", "normal").get_width(), Art.bake("FULL 360! +0.25", "normal").get_width())
	assert_lt(Art.bake("LONG DRIFT! +0.05", "small").get_height(), Art.bake("FULL 360! +0.25", "normal").get_height())


func test_same_text_gives_the_same_texture_and_image() -> void:
	assert_same(Art.texture("FULL 360! +0.25", "normal"), Art.texture("FULL 360! +0.25", "normal"), "cached")
	assert_ne(Art.texture("FULL 360! +0.25", "normal"), Art.texture("FULL 360! +0.25", "small"), "per size")
	assert_eq(Art.bake("ALT DRIFT! +0.5", "normal").get_data(), Art.bake("ALT DRIFT! +0.5", "normal").get_data(), "deterministic")


func test_white_bubble_black_border_black_letters() -> void:
	# Only three colours: white, black and nothing. Names and amounts alike are black.
	for c in CASES:
		var img: Image = Art.bake(c[0], c[1])
		var white := 0
		var black := 0
		var other := 0
		for y in img.get_height():
			for x in img.get_width():
				var p := img.get_pixel(x, y)
				if p.a == 0.0:
					continue
				if p == Color.WHITE:
					white += 1
				elif p == Color.BLACK:
					black += 1
				else:
					other += 1
		assert_eq(other, 0, "%s: only white and black" % c[0])
		assert_gt(white, black / 3, "%s: the bubble is mostly white" % c[0])
		assert_gt(black, 100, "%s: black letters and border" % c[0])
		# The outermost opaque pixel of the middle row is the black border.
		var row := img.get_height() / 2
		var first := -1
		for x in img.get_width():
			if img.get_pixel(x, row).a > 0.0:
				first = x
				break
		assert_eq(img.get_pixel(first, row), Color.BLACK, "%s: black border" % c[0])


func test_name_and_amount_letters_are_both_black() -> void:
	var img: Image = Art.bake("FULL 360! +0.25", "normal")
	var box: Rect2i = Art.text_box("FULL 360! +0.25", "normal")
	var left_black := 0
	var right_black := 0
	for y in box.size.y:
		for x in box.size.x:
			var p := img.get_pixel(box.position.x + x, box.position.y + y)
			if p == Color.BLACK and x < box.size.x / 2:
				left_black += 1
			if p == Color.BLACK and x > box.size.x * 0.7:
				right_black += 1
	assert_gt(left_black, 50, "the name is black")
	assert_gt(right_black, 20, "the amount is black")


func test_letters_sit_on_one_baseline() -> void:
	# Every glyph of "ALT DRIFT!" that has no descender ends on the same row.
	var img: Image = Art.bake("ALT DRIFT! +0.5", "normal")
	var box: Rect2i = Art.text_box("ALT DRIFT! +0.5", "normal")
	var bottoms := {}
	for x in range(box.position.x, box.end.x):
		var last := -1
		for y in range(box.position.y, box.end.y):
			if img.get_pixel(x, y) == Color.BLACK:
				last = y
		if last >= 0:
			bottoms[last] = bottoms.get(last, 0) + 1
	# The densest 3-row band (rounded glyph bottoms overshoot by a pixel) holds most columns.
	var best := 0
	for k in bottoms:
		var n := 0
		for d in [-1, 0, 1]:
			n += bottoms.get(k + d, 0)
		best = maxi(best, n)
	assert_gt(best, box.size.x * 0.5, "most columns of letters end on the same baseline")


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


func test_corners_are_rounded_in_stepped_pixels() -> void:
	for c in CASES:
		var img: Image = Art.bake(c[0], c[1])
		var w := img.get_width()
		var h := img.get_height()
		# The very corner of the shape is cut off; the middle of each edge is not.
		assert_eq(img.get_pixel(1, 1).a, 0.0, "%s: corner pixel cut" % c[0])
		assert_eq(img.get_pixel(w - 2, h - 2).a, 0.0, "%s: corner pixel cut" % c[0])
		assert_eq(img.get_pixel(w / 2, 1), Color.BLACK, "%s: straight black top edge" % c[0])
		assert_eq(img.get_pixel(1, h / 2), Color.BLACK, "%s: straight black left edge" % c[0])
		# Stepped: the first opaque pixel on each of the top rows moves in by whole pixels, never back.
		var prev := w
		for y in range(1, 1 + Art.CORNER):
			var first := -1
			for x in w:
				if img.get_pixel(x, y).a > 0.0:
					first = x
					break
			assert_lte(first, prev, "%s: the outline widens going down the corner" % c[0])
			prev = first
		# Padding around the lettering is small.
		var box: Rect2i = Art.text_box(c[0], c[1])
		assert_lt(box.position.x, 12, "%s: small padding" % c[0])
