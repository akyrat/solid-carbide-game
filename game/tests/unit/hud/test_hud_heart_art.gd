extends GutTest
## Task T-086: the likes heart is a script-drawn pixel-art icon (tools/build_heart_icon.py),
## flat Redgull red with a dark outline like the comic text's, and the HUD shows it.

const RUN := preload("res://scenes/run/run.tscn")


func _pixels() -> Array[Color]:
	var img: Image = (load(Hud.HEART_PATH) as Texture2D).get_image()
	var out: Array[Color] = []
	for y in img.get_height():
		for x in img.get_width():
			out.append(img.get_pixel(x, y))
	return out


func test_transparent_background_and_no_semi_transparent_pixels() -> void:
	var img: Image = (load(Hud.HEART_PATH) as Texture2D).get_image()
	for corner: Vector2i in [Vector2i(0, 0), Vector2i(img.get_width() - 1, 0),
			Vector2i(0, img.get_height() - 1), Vector2i(img.get_width() - 1, img.get_height() - 1)]:
		assert_eq(img.get_pixelv(corner).a, 0.0, "corner %s clear" % corner)
	for c: Color in _pixels():
		assert_true(c.a == 0.0 or c.a == 1.0, "alpha %s" % c.a)


func test_two_colours_redgull_red_and_the_text_outline() -> void:
	var seen := {}
	for c: Color in _pixels():
		if c.a > 0.0:
			seen[c.to_html(false)] = c
	assert_eq(seen.size(), 2, "few colours: %s" % [seen.keys()])
	assert_true(seen.has(Hud.HEART_COLOR.to_html(false)), "uses the HUD's Redgull red")
	assert_true(seen.has(Hud.OUTLINE_COLOR.to_html(false)), "uses the text outline colour")


func test_hud_shows_the_art_crisp_and_about_text_height() -> void:
	var r: Node2D = RUN.instantiate()
	add_child_autofree(r)
	var hud: Hud = r.hud
	assert_eq(hud.heart.texture.resource_path, Hud.HEART_PATH)
	assert_eq(hud.heart.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	assert_eq(hud.heart.custom_minimum_size, hud.heart.texture.get_size() * Hud.HEART_SCALE)
	var likes_h := hud.likes_label.get_combined_minimum_size().y
	assert_almost_eq(hud.heart.custom_minimum_size.y, likes_h, 8.0, "about the height of Likes")
