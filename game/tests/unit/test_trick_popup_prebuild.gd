extends GutTest
## Task T-480: the popup pictures are built ahead of drawing, look exactly as before, and the caches stay bounded.

const Art := preload("res://scripts/hud/trick_popup_art.gd")
const BrokenArt := preload("res://scripts/hud/combo_broken_art.gd")
const Popups := preload("res://scripts/hud/trick_popups.gd")

## [text, style, heat, frame, viewers, hide_amount, width, height, hash of the pixels] as built before T-480.
const TRICK_GOLDEN := [
	["FULL 360! +226K", "normal", 3, 2, true, false, 261, 87, 2772041644],
	["FULL 360! +5,938", "normal", 2, 0, true, true, 249, 48, 3314372398],
	["THREAD THE NEEDLE! +12.0K", "normal", 0, 0, true, false, 339, 37, 4204024030],
	["ALT DRIFT! +0.5", "normal", 1, 0, false, false, 183, 41, 1120496484],
	["LONG DRIFT!", "small", 0, 0, false, false, 99, 27, 3115531473],
	["LONG DRIFT! +12.0K", "small", 3, 5, true, false, 192, 77, 4239615401],
	["TRENDING! +120 SUBS!", "normal", 3, 1, false, false, 280, 87, 1449751886],
	["AIR 180!", "normal", 2, 0, false, false, 119, 45, 4051785811],
]
## [text, style, in_gap, width, height, hash left, hash right]
const BROKEN_GOLDEN := [
	["COMBO BROKEN!", "normal", false, 197, 37, 4051289101, 75715313],
	["COMBO BROKEN!", "normal", true, 197, 37, 2601950617, 1163224719],
	["TIME'S UP!", "small", true, 85, 28, 799601627, 1959282843],
]


func before_each() -> void:
	Art.clear_cache()
	BrokenArt.clear_cache()


func test_trick_popup_pixels_are_as_before() -> void:
	for g in TRICK_GOLDEN:
		var img: Image = Art.bake(g[0], g[1], g[2], g[3], g[4], g[5])
		assert_eq([img.get_width(), img.get_height(), hash(img.get_data())], [g[6], g[7], g[8]], "baked %s" % g[0])


func test_requested_textures_are_the_same_pixels() -> void:
	for g in TRICK_GOLDEN:
		Art.request(g[0], g[1], g[2], g[3], g[4], g[5])
	Art.finish_requests()
	for g in TRICK_GOLDEN:
		var key := Art.texture_key(g[0], g[1], g[2], g[3], g[4], g[5])
		assert_true(Art.is_cached(key), "ahead: %s" % g[0])
		var img: Image = Art.texture(g[0], g[1], g[2], g[3], g[4], g[5]).get_image()
		assert_eq([img.get_width(), img.get_height(), hash(img.get_data())], [g[6], g[7], g[8]], "texture %s" % g[0])


func test_broken_popup_pixels_are_as_before() -> void:
	for g in BROKEN_GOLDEN:
		var imgs: Array = BrokenArt.bake(g[0], g[1], g[2])
		assert_eq([imgs[0].get_width(), imgs[0].get_height(), hash(imgs[0].get_data()), hash(imgs[1].get_data())], [g[3], g[4], g[5], g[6]], "broken %s" % g[0])
	BrokenArt.request("COMBO BROKEN!", "normal")
	BrokenArt.finish_requests()
	assert_true(BrokenArt.is_cached(BrokenArt.texture_key("COMBO BROKEN!", "normal")))
	var halves := BrokenArt.textures("COMBO BROKEN!", "normal")
	assert_eq(hash(halves[0].get_image().get_data()), 4051289101)
	assert_eq(hash(halves[1].get_image().get_data()), 75715313)


func test_plain_size_is_the_plain_textures_size() -> void:
	for g in TRICK_GOLDEN:
		var with_eye: bool = g[4]
		var want := Art.texture(g[0], g[1], 0, 0, with_eye).get_size()
		assert_eq(Vector2(Art.plain_size(g[0], g[1], with_eye)), want, "size of %s" % g[0])


func test_round_rect_spans_match_the_pixel_test() -> void:
	for dims in [Vector2i(120, 40), Vector2i(30, 30), Vector2i(9, 9), Vector2i(261, 87)]:
		for inset in [1, 2, 3, 6]:
			for r in [0, 3, 5, 7, 10]:
				if 2 * (r + inset) > mini(dims.x, dims.y):
					continue  # a corner bigger than the box never happens
				var bad := 0
				for y in dims.y:
					var span := Art.round_rect_span(y, dims.x, dims.y, inset, r)
					for x in dims.x:
						var inside: bool = Art._in_round_rect(x, y, dims.x, dims.y, inset, r)
						if inside != (x >= span.x and x < span.y):
							bad += 1
				assert_eq(bad, 0, "%s inset %d r %d" % [dims, inset, r])


func test_trick_cache_stays_bounded() -> void:
	for i in 400:
		Art.texture("FULL 360! +%d" % (1000 + i), "normal", i % 3, 0, true)
	assert_lte(Art._cache.size(), Art.CACHE_MAX)
	for i in 400:
		Art.request("ALT DRIFT! +%d" % (5000 + i), "small", 0, 0, false)
	Art.finish_requests()
	assert_lte(Art._cache.size(), Art.CACHE_MAX)
	assert_lte(Art._plain_sizes.size(), Art.CACHE_MAX)
	for i in 100:
		Art.plain_size("LONG DRIFT! +%d" % i, "small")
	assert_lte(Art._plain_sizes.size(), Art.CACHE_MAX)


func test_broken_cache_stays_bounded() -> void:
	for i in 60:
		BrokenArt.textures("HEADLINE %d" % i, "small", i % 2 == 0)
	assert_lte(BrokenArt._cache.size(), BrokenArt.CACHE_MAX)


func test_a_shown_popup_has_every_picture_before_it_draws() -> void:
	var popups: Node2D = autofree(Popups.new())
	add_child(popups)
	var p: Node2D = popups.show_popup("FULL 360! +12.0K", Vector2.ZERO, Popups.SIZE_NORMAL, Callable(), 3, false, true)
	Art.finish_requests()
	var style := Art.style_for(Popups.SIZE_NORMAL)
	assert_true(Art.is_cached(Art.texture_key(p.text, style, 3, 0, true, false)), "the born picture is made when the popup is shown")
	for f in Art.FLAME_FRAMES:
		for hide in [false, true]:
			assert_true(Art.is_cached(Art.texture_key(p.text, style, 3, f, true, hide)), "frame %d hide %s" % [f, hide])
	var before := Art._cache.size()
	for f in Art.FLAME_FRAMES:
		p.frame = f
		p.amount_gone = f % 2 == 1
		assert_not_null(p.texture())
	assert_eq(Art._cache.size(), before, "drawing built nothing")


func test_a_broken_popup_has_its_halves_before_it_draws() -> void:
	var popups: Node2D = autofree(Popups.new())
	add_child(popups)
	BrokenArt.clear_cache()
	popups.show_popup(Popups.BROKEN_TEXT, Vector2.ZERO, Popups.SIZE_NORMAL, Callable(), 0, true)
	BrokenArt.finish_requests()
	assert_true(BrokenArt.is_cached(BrokenArt.texture_key(Popups.BROKEN_TEXT, "normal")))


func test_prewarm_covers_each_trick_name_at_every_heat() -> void:
	Popups._prewarmed = false
	Popups.prewarm()
	Art.finish_requests()
	BrokenArt.finish_requests()
	for id in Popups.TEXTS:
		var style := Art.style_for(Popups.SIZES[id])
		for heat in Art.HEAT_STEPS:
			for f in (Art.FLAME_FRAMES if heat >= Art.FLAME_STEP else 1):
				assert_true(Art.is_cached(Art.texture_key(Popups.TEXTS[id], style, heat, f)), "%s heat %d frame %d" % [id, heat, f])
	assert_true(BrokenArt.is_cached(BrokenArt.texture_key(Popups.BROKEN_TEXT, "normal")))
