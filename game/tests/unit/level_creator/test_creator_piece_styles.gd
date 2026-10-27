extends GutTest
## Task T-255: the creator's rooftops and ramps are drawn from one of three piece styles (office,
## car park, T-198's), chosen with the Style button (T key) and saved on each piece as "style".

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const ElevationLayerScript := preload("res://scripts/level/elevation_layer.gd")


func _editor() -> LevelCreatorEditor:
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.open_new()
	add_child_autofree(e)
	return e


func test_the_three_styles_exist_and_differ_in_their_textures() -> void:
	var seen := {}
	for name in ElevationLayerScript.PIECE_STYLES:
		var s = ElevationLayerScript.piece_style_named(name)
		assert_not_null(s, name)
		for tex in [s.roof_top, s.wall, s.ramp_top, s.ramp_side, s.parapet]:
			assert_not_null(tex, name)
		seen[s.roof_top.resource_path] = true
	assert_eq(seen.size(), 3, "three different rooftop textures")
	assert_eq(ElevationLayerScript.piece_style_named("").roof_top, ElevationLayerScript.piece_style().roof_top)
	assert_eq(ElevationLayerScript.piece_style_named("nope").roof_top, ElevationLayerScript.piece_style().roof_top)


func test_the_default_style_is_t255s_office_and_the_first_set_is_selectable() -> void:
	assert_true(ElevationLayerScript.piece_style_named("office").roof_top.resource_path.contains("/t255/"))
	assert_false(ElevationLayerScript.piece_style_named("t198").roof_top.resource_path.contains("/t255/"))
	assert_true(ElevationLayerScript.piece_style_named("carpark").wall.resource_path.contains("wall_garage"))


func test_the_style_button_steps_through_the_styles() -> void:
	var e := _editor()
	assert_eq(e.pick_style, "office")
	assert_eq(e.style_pick(), "carpark")
	assert_eq(e.style_pick(), "t198")
	assert_eq(e.style_pick(), "office")
	assert_true(e.style_button.text.contains("Office"))


func test_a_placed_piece_keeps_the_style_it_was_placed_in_and_is_drawn_with_it() -> void:
	var e := _editor()
	e.panel.pick("rooftop-3")
	e.style_pick()
	var a := e.place_asset("rooftop-3", Vector2(-40, -40), Vector2(8, 8))
	assert_eq(str(a.item.get("style", "")), "carpark")
	e.style_pick()
	var b := e.place_asset("rooftop-3", Vector2(20, 20), Vector2(8, 8))
	assert_eq(str(b.item.get("style", "")), "t198")
	var drawn: Array = e.elevation.areas
	assert_eq(drawn.size(), 2)
	assert_ne(drawn[0].style.roof_top, drawn[1].style.roof_top)
	assert_eq(drawn[0].style, ElevationLayerScript.piece_style_named("carpark"))
	assert_eq(drawn[1].style, ElevationLayerScript.piece_style_named("t198"))


func test_a_piece_without_a_style_key_is_drawn_in_the_default_style() -> void:
	var layer = ElevationLayerScript.new()
	assert_eq(ElevationLayerScript.piece_style_named(""), ElevationLayerScript.piece_style())
	layer.free()


func test_ramps_tile_plainly_in_the_new_styles_so_the_chevrons_keep_pointing_one_way() -> void:
	assert_true(ElevationLayerScript.piece_style_named("office").ramp_plain_repeat)
	assert_true(ElevationLayerScript.piece_style_named("carpark").ramp_plain_repeat)
	assert_false(ElevationLayerScript.piece_style_named("t198").ramp_plain_repeat)
	var e := _editor()
	e.panel.pick("ramp-0-3")
	var r := e.place_asset("ramp-0-3", Vector2(0, 0), Vector2(10, 0))
	assert_false(r.is_empty())
	var ramp_drawing = e.elevation.areas[0]
	assert_eq(ramp_drawing.texture_repeat, CanvasItem.TEXTURE_REPEAT_ENABLED)
