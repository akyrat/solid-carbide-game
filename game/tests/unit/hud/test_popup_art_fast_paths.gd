extends GutTest
## Task T-481: the popup baking's faster loops (row spans for the rounded rectangle, a
## row-slice crop) give exactly what the pixel-by-pixel versions gave.

const Art := preload("res://scripts/hud/trick_popup_art.gd")


func test_round_rect_spans_match_the_per_pixel_test() -> void:
	for size in [Vector2i(40, 30), Vector2i(237, 37), Vector2i(12, 12), Vector2i(9, 40), Vector2i(60, 8)]:
		for inset in [0, 1, 3]:
			for r in [0, 2, 5, 10, 40]:
				var fast := PackedByteArray()
				fast.resize(size.x * size.y)
				Art._fill_round_rect(fast, size.x, 0, 0, size.x, size.y, inset, r, 7)
				var slow := PackedByteArray()
				slow.resize(size.x * size.y)
				for y in size.y:
					for x in size.x:
						if Art._in_round_rect(x, y, size.x, size.y, inset, r):
							slow[y * size.x + x] = 7
				assert_eq(fast, slow, "%s inset %d radius %d" % [size, inset, r])


func test_crop_matches_the_pixel_scan() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 481
	for n in 20:
		var w := rng.randi_range(1, 30)
		var h := rng.randi_range(1, 20)
		var idx := PackedByteArray()
		idx.resize(w * h)
		for i in rng.randi_range(0, 12):
			idx[rng.randi_range(0, w * h - 1)] = rng.randi_range(1, 5)
		var x0 := w
		var x1 := -1
		var y0 := h
		var y1 := -1
		for y in h:
			for x in w:
				if idx[y * w + x] != 0:
					x0 = mini(x0, x)
					x1 = maxi(x1, x)
					y0 = mini(y0, y)
					y1 = maxi(y1, y)
		var got: Dictionary = Art._crop(idx, w, h)
		if x1 < 0:
			assert_eq(got.w, 1)
			assert_eq(got.h, 1)
			continue
		assert_eq(got.w, x1 - x0 + 1)
		assert_eq(got.h, y1 - y0 + 1)
		for y in got.h:
			for x in got.w:
				assert_eq(got.idx[y * got.w + x], idx[(y0 + y) * w + x0 + x])
