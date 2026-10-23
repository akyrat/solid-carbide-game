extends GutTest
## Task T-264: in the level creator, every ramp is a closed block (a wall at its tall end), its
## arrows point up or down the slope as chosen (key A, saved with the ramp, up by default), and a
## platform at height 3 or 6 places in one click at S 8 x 8, M 16 x 16 or L 32 x 32 units.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const DrawingScript := preload("res://scripts/level/elevation_platform_drawing.gd")
const MvpMapScript := preload("res://scripts/level/mvp_map.gd")
const STYLE_PATH := "res://art/creator_pieces/piece_style.tres"
const RAMPS := ["ramp-0-3", "ramp-3-6", "ramp-0-6"]
const SIDES := ["north", "east", "south", "west"]


func _editor() -> LevelCreatorEditor:
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.open_new()
	add_child_autofree(e)
	return e


func _pick(e: LevelCreatorEditor, id: String, view: String) -> void:
	e.panel.pick(id)
	for i in 4:
		if e.pick_view == view:
			return
		e.rotate_pick()


## A drawing of a ramp of `id` climbing `side`, in the office style.
func _drawing(id: String, side: String, arrows: String = "up") -> Node2D:
	var heights: Array = LevelDocument.entry(id).heights
	var d: Node2D = DrawingScript.new()
	d.setup("ramp", {"id": "r", "rect": Rect2(0, 0, 10, 12), "side": side, "bottom_height": float(heights[0]),
		"top_height": float(heights[1]), "arrows": arrows}, MvpMapScript.ISO_TRANSFORM)
	d.use_style(load(STYLE_PATH), float(heights[0]))
	add_child_autofree(d)
	return d


# ---- Closed ramps -------------------------------------------------------------------------------

func test_every_ramp_draws_a_wall_at_its_tall_end_in_every_direction_and_height() -> void:
	var style = load(STYLE_PATH)
	for id in RAMPS:
		for side in SIDES:
			var d := _drawing(id, side)
			var tall: String = d.join_edge()
			assert_ne(tall, "", "%s %s: a top end" % [id, side])
			var walls: Array = d.textured_faces().filter(func(f): return f.name == tall)
			assert_eq(walls.size(), 1, "%s %s: a wall at its tall end (%s)" % [id, side, tall])
			if walls.size() == 1:
				assert_eq(walls[0].texture, style.ramp_side, "in the ramp side's texture")
				assert_gt(walls[0].points.size(), 2)


func test_the_tall_end_wall_reaches_down_to_the_base() -> void:
	# A ramp climbing north: its south end is the tall one, a full 3 units tall on the street.
	var d := _drawing("ramp-0-3", "north")
	var wall: Dictionary = d.textured_faces().filter(func(f): return f.name == "south")[0]
	for corner in [Vector2(0, 12), Vector2(10, 12)]:
		assert_true(wall.points.has(d.drawn(corner, 3.0)), "the wall's top corner %s" % corner)
		assert_true(wall.points.has(d.drawn(corner, 0.0)), "the wall's bottom corner %s, on the street" % corner)


# ---- Arrows up or down --------------------------------------------------------------------------

## The way the top face's texture arrow points in the flat map: the texture's v axis (arrows point
## towards smaller v) mapped back to the flat direction through the face's uvs.
func _arrow_flat_direction(d: Node2D) -> Vector2:
	var top: Dictionary = d.textured_faces().filter(func(f): return f.name == "top")[0]
	var r: Rect2 = d.block.rect
	# The corners are NW, NE, SE, SW: the v change from NW to NE is along x, from NW to SW along y.
	var uv: PackedVector2Array = top.uvs
	var vx: float = uv[1].y - uv[0].y
	var vy: float = uv[3].y - uv[0].y
	if absf(vx) > absf(vy):
		return Vector2(-signf(vx), 0)
	return Vector2(0, -signf(vy))


func test_arrows_point_up_or_down_the_slope_in_every_direction_and_height() -> void:
	var up := {"east": Vector2(-1, 0), "west": Vector2(1, 0), "south": Vector2(0, -1), "north": Vector2(0, 1)}
	for id in RAMPS:
		for side in SIDES:
			var a := _drawing(id, side, "up")
			var b := _drawing(id, side, "down")
			assert_eq(a.arrow_direction(), up[side], "%s %s: up the slope" % [id, side])
			assert_eq(b.arrow_direction(), -up[side], "%s %s: down the slope" % [id, side])
			assert_eq(_arrow_flat_direction(a), up[side], "%s %s: the up texture" % [id, side])
			assert_eq(_arrow_flat_direction(b), -up[side], "%s %s: the down texture" % [id, side])


func test_a_ramp_without_arrows_is_up() -> void:
	var d := DrawingScript.new()
	d.setup("ramp", {"rect": Rect2(0, 0, 10, 12), "side": "west", "top_height": 3.0}, Transform2D.IDENTITY)
	assert_eq(d.arrows(), "up")
	d.free()


func test_the_a_key_turns_the_arrows_and_a_new_ramp_saves_them() -> void:
	var e := _editor()
	_pick(e, "ramp-0-3", "north")
	assert_eq(e.pick_arrows, "up", "up by default")
	var first := e.place_asset("ramp-0-3", Vector2(-60, -60), Vector2(10, 12))
	assert_eq(first.item.arrows, "up")
	var key := InputEventKey.new()
	key.keycode = KEY_A
	key.pressed = true
	e._unhandled_key_input(key)
	assert_eq(e.pick_arrows, "down")
	assert_true(e.arrows_buttons.down.button_pressed)
	var second := e.place_asset("ramp-0-3", Vector2(-20, -60), Vector2(10, 12))
	assert_eq(second.item.arrows, "down")
	assert_eq(first.item.arrows, "up", "the first keeps its own")
	e._unhandled_key_input(key)
	assert_eq(e.pick_arrows, "up")
	var ramps: Array = e.elevation.areas.filter(func(a): return a.kind == "ramp")
	assert_eq(ramps[0].arrows(), "up")
	assert_eq(ramps[1].arrows(), "down")


func test_the_arrows_choice_is_saved_and_reopened() -> void:
	var e := _editor()
	e.levels_dir = RunPaths.file("t264_levels")
	_pick(e, "ramp-3-6", "east")
	e.set_arrows("down")
	e.place_asset("ramp-3-6", Vector2(-60, -60), Vector2(12, 10))
	e.name_field.text = "arrows"
	e.save()
	var back := LevelStore.load_level(e.save_path())
	assert_eq(back.ramps[0].arrows, "down")
	var gh := GroundHeight.new()
	gh.load_data(back)
	assert_eq(gh.ramps[0].arrows, "down")
	var e2 := _editor()
	e2.open_level(e.save_path())
	assert_eq(e2.elevation.areas[0].arrows(), "down")


func test_a_selected_ramp_turns_with_a_when_no_ramp_is_picked() -> void:
	var e := _editor()
	_pick(e, "ramp-0-3", "north")
	var r := e.place_asset("ramp-0-3", Vector2(-60, -60), Vector2(10, 12))
	e.panel.pick("")
	e.selected = r
	e.arrows_pick()
	assert_eq(r.item.arrows, "down")
	assert_eq(e.elevation.areas[0].arrows(), "down")


# ---- Platform sizes -----------------------------------------------------------------------------

func test_s_m_and_l_platforms_place_in_one_click_at_both_heights() -> void:
	var sizes := {"s": 8.0, "m": 16.0, "l": 32.0}
	for id in ["rooftop-3", "rooftop-6"]:
		var e := _editor()
		e.panel.pick(id)
		var x := -100.0
		for key in sizes:
			e.set_platform_size(key)
			assert_true(e.size_buttons[key].button_pressed)
			var p := e.place_asset(id, Vector2(x, -40), Vector2.ZERO)
			assert_false(p.is_empty(), "%s %s placed" % [id, key])
			assert_eq(Vector2(float(p.item.w), float(p.item.h)), Vector2(sizes[key], sizes[key]), "%s %s" % [id, key])
			x += 50.0


func test_the_plain_click_defaults_to_m_and_dragging_sizes_freely() -> void:
	var e := _editor()
	e.panel.pick("rooftop-3")
	assert_eq(e.pick_platform_size, "m")
	assert_eq(float(e.place_asset("rooftop-3", Vector2(-100, -40)).item.w), 16.0)
	e.set_platform_size("s")
	var p := e.place_asset("rooftop-3", Vector2(-40, -40), Vector2(20, 6))
	assert_eq(Vector2(float(p.item.w), float(p.item.h)), Vector2(20, 6), "a drag keeps its own size")
	e.set_platform_size("any")
	assert_eq(float(e.place_asset("rooftop-3", Vector2(20, -40)).item.w), 16.0, "any size: the click is M's")


func test_the_preview_shows_the_chosen_size() -> void:
	var e := _editor()
	e.panel.pick("rooftop-3")
	e.set_platform_size("l")
	e.hover_cell = e.document.cell_at(Vector2(-100, -40))
	var at := e.current_placement()
	assert_eq(at.rect.size, Vector2(32, 32))


func test_a_click_on_an_overlapping_spot_is_still_refused() -> void:
	var e := _editor()
	e.panel.pick("rooftop-3")
	e.set_platform_size("l")
	assert_false(e.place_asset("rooftop-3", Vector2(-100, -40)).is_empty())
	assert_true(e.place_asset("rooftop-3", Vector2(-90, -30)).is_empty(), "an overlapping 3 is refused")


func test_the_size_and_arrow_buttons_show_with_their_piece() -> void:
	var e := _editor()
	e.panel.pick("rooftop-3")
	assert_true(e.size_buttons.s.visible)
	assert_false(e.arrows_buttons.up.visible)
	e.panel.pick("ramp-0-3")
	assert_false(e.size_buttons.s.visible)
	assert_true(e.arrows_buttons.up.visible)
	assert_eq(e.size_buttons.any.text, "Any size (drag)")
	assert_eq(e.arrows_buttons.down.text, "Arrows down")
