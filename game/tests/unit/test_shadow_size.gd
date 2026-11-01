extends GutTest
## Task T-454 (Visual style, Decisions, "Shadows shrink with height"): the one
## shared size curve for every shadow of an object in the air (shadow_size.gd).

const ShadowSizeScript := preload("res://scripts/driving/shadow_size.gd")


func test_full_size_at_the_surface() -> void:
	assert_eq(ShadowSizeScript.scale_for_height(0.0), 1.0)
	assert_eq(ShadowSizeScript.size_for_height(24.0, 0.0), 24.0, "the sprite's own size at height 0")


func test_smaller_as_the_height_grows() -> void:
	var prev := ShadowSizeScript.size_for_height(24.0, 0.0)
	var h := 0.25
	while h <= 30.0:
		var s := ShadowSizeScript.size_for_height(24.0, h)
		assert_true(s <= prev + 1e-9, "not larger at height %s" % h)
		if ShadowSizeScript.scale_for_height(h) > ShadowSizeScript.MIN_SCALE:
			assert_lt(s, prev, "strictly smaller at height %s" % h)
		prev = s
		h += 0.25
	assert_lt(ShadowSizeScript.size_for_height(24.0, 1.0), 24.0, "a small hop already shows")
	assert_almost_eq(ShadowSizeScript.scale_for_height(ShadowSizeScript.HALF_SIZE_HEIGHT_UNITS), 0.5, 1e-6)


func test_never_larger_than_the_sprite_nor_below_the_smallest_size() -> void:
	for h in [-5.0, -0.01, 0.0, 0.1, 1.0, 3.0, 6.0, 12.0, 100.0, 1e6, NAN]:
		var k := ShadowSizeScript.scale_for_height(h)
		assert_true(k <= 1.0, "never larger than the sprite at %s" % h)
		assert_true(k >= ShadowSizeScript.MIN_SCALE, "never below the smallest size at %s" % h)
	assert_eq(ShadowSizeScript.scale_for_height(-3.0), 1.0, "below the surface counts as on it")
	assert_almost_eq(ShadowSizeScript.scale_for_height(1e6), ShadowSizeScript.MIN_SCALE, 1e-9)
	assert_gt(ShadowSizeScript.MIN_SCALE, 0.0)
	assert_lt(ShadowSizeScript.MIN_SCALE, 1.0)


func test_height_above_the_surface_under_it() -> void:
	assert_eq(ShadowSizeScript.height_above(8.0, 6.0), 2.0, "above a rooftop of 6")
	assert_eq(ShadowSizeScript.height_above(6.0, 6.0), 0.0)
	assert_eq(ShadowSizeScript.height_above(5.0, 6.0), 0.0, "never below 0")


func test_screen_width_to_ground_diameter() -> void:
	assert_almost_eq(ShadowSizeScript.diameter_for_screen_width(16.0 * sqrt(2.0)), 1.0, 1e-6)
