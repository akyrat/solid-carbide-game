extends GutTest
## T-429: the clock art the HUD now shows loads as RGBA with a clear background,
## so the tinted digits show segments, not solid blocks.


func test_digit_frames_load_with_a_clear_background() -> void:
	for key in ["0", "8", "colon", "off"]:
		var t := load(HudStyle.CLOCK_DIGIT_ART % key) as Texture2D
		assert_not_null(t, key)
		var img := t.get_image()
		assert_eq(img.get_format(), Image.FORMAT_RGBA8, key)
		assert_eq(img.get_pixel(0, 0).a, 0.0, "%s: clear corner" % key)


func test_panel_art_loads() -> void:
	var p := load(HudStyle.CLOCK_PANEL_ART) as Texture2D
	assert_eq(Vector2i(p.get_size()), Vector2i(100, 36))
