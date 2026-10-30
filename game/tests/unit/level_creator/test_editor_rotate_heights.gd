extends GutTest
## Task T-236: in the level creator, rotate and mirror step the picked asset through exactly the
## views and mirrors its catalogue entry lists (creator_assets.json), and rooftops at 3 and 6 with
## ramps 0 to 3 and 3 to 6 write height data that passes game/tools/check_height_data.py.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")


func _editor() -> LevelCreatorEditor:
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.open_new()
	add_child_autofree(e)
	return e


func _ids_of(kind: String) -> Array:
	var out: Array = []
	for en in LevelDocument.panel_entries():
		if str(en.kind) == kind:
			out.append(str(en.id))
	return out


## Picks each asset of `kind`, steps Rotate and Mirror round twice, and checks that the views and
## mirrors offered are exactly those its catalogue entry lists, in its order, and nothing else.
func _check_kind(kind: String) -> void:
	var e := _editor()
	var ids := _ids_of(kind)
	assert_gt(ids.size(), 0, kind + " has assets")
	for id in ids:
		var en := LevelDocument.entry(id)
		var views: Array = en.views
		var mirrors: Array = en.mirrors
		e.panel.pick(id)
		assert_eq(e.panel.picked, id)
		assert_eq(e.pick_view, str(views[0]), id + " starts in its first view")
		assert_eq(e.pick_mirror, bool(mirrors[0]), id + " starts in its first mirror")
		var seen_views: Array = [e.pick_view]
		for i in views.size() * 2 - 1:
			seen_views.append(e.rotate_pick())
		var expected_views: Array = views + views
		assert_eq(seen_views, expected_views, id + ": rotate offers its views, in order, round again")
		var seen_mirrors: Array = [e.pick_mirror]
		for i in mirrors.size() * 2 - 1:
			seen_mirrors.append(e.mirror_pick())
		assert_eq(seen_mirrors, mirrors + mirrors, id + ": mirror offers its mirrors, round again")
		# Every pose offered has its own texture of that view and mirror.
		for v in views:
			for m in mirrors:
				var t := LevelDocument.texture_of(id, str(v), bool(m))
				assert_eq(str(t.view), str(v), id)
		# T-262: Rotate and Mirror step the asset's family (a road tile turns to the tile along the
		# other axis, and its a0m tile is its mirror), so they are on when the family has a turn or
		# a mirror to step to.
		e.panel.pick(id)
		var fid := e.panel.picked_family
		assert_eq(e.rotate_button.disabled, not CreatorFamilies.can_step(fid, e.panel.member, "turn"), id + ": Rotate on only with turns")
		assert_eq(e.mirror_button.disabled, not CreatorFamilies.can_step(fid, e.panel.member, "flip"), id + ": Mirror on only with mirrors")
		if views.size() > 1:
			assert_false(e.rotate_button.disabled, id + ": an asset with several views turns")
		if mirrors.size() > 1:
			assert_false(e.mirror_button.disabled, id + ": an asset with a mirror mirrors")
	e.panel.pick("")


func test_rotate_and_mirror_ground() -> void:
	_check_kind("ground")


func test_rotate_and_mirror_roads() -> void:
	# T-263: road tiles are no longer picked from the panel: the road brushes lay them and turn
	# them themselves (road_brush.gd), so Rotate is off; Mirror steps a0 to its mirror a0m.
	var e := _editor()
	for fid in ["road", "centre-line", "cracked-road", "zebra-crossing"]:
		e.panel.pick(fid)
		assert_ne(e.brush_mode(), "", fid)
		assert_true(e.rotate_button.disabled, fid + ": the brush turns roads itself")
		assert_eq(e.mirror_button.disabled, fid in ["cracked-road", "zebra-crossing"], fid + ": a0's mirror a0m")
	e.panel.pick("")


func test_rotate_and_mirror_buildings() -> void:
	_check_kind("building")


func test_rotate_and_mirror_boulders() -> void:
	_check_kind("boulder")


func test_rotate_and_mirror_rooftops() -> void:
	_check_kind("rooftop")


func test_rotate_and_mirror_ramps() -> void:
	_check_kind("ramp")


func test_an_asset_with_one_view_and_mirror_stays_put() -> void:
	var e := _editor()
	e.panel.pick("ground-gravel1")
	assert_eq(e.rotate_pick(), "iso")
	assert_eq(e.mirror_pick(), false)


# ---- What the pose places ---------------------------------------------------------------------

func _click(e: LevelCreatorEditor, units: Vector2) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = e.units_to_screen(units)
	e._on_map_input(click)


func test_the_mirror_places_the_mirrored_art() -> void:
	var e := _editor()
	e.panel.pick("boulder-a")
	e.mirror_pick()
	_click(e, Vector2(10.5, 10.5))
	assert_eq(e.level_data.pattern_copies[0].boulders[0].variant, "a_mirror")
	assert_eq(e.map.boulder_sprites[0].variant, "a_mirror")
	e.panel.pick("short-2")
	e.mirror_pick()
	_click(e, Vector2(-40.5, -40.5))
	assert_eq(e.level_data.buildings[0].look, 1, "a short building's mirror is its look 1")
	# T-405: a low-rise is a platform drawn from its platform art (of the mirrored body, short_body_5).
	var area: Node2D = null
	for a in e.elevation.areas:
		if bool(a.block.get("short", false)):
			area = a
	assert_eq(area.building_art.full.resource_path, "res://art/buildings/platforms/short_body_5.png",
		"the mirrored art of the catalogue")


## Picks `id` and rotates it to `view` (T-251: a ramp's view is the direction it climbs).
func _pick(e: LevelCreatorEditor, id: String, view: String = "") -> void:
	e.panel.pick(id)
	for i in 4:
		if view == "" or e.pick_view == view:
			return
		e.rotate_pick()
	assert_eq(e.pick_view, view, "%s has the view %s" % [id, view])


func test_rotate_steps_a_ramp_through_the_four_directions_and_their_sides() -> void:
	var e := _editor()
	for id in ["ramp-0-3", "ramp-3-6", "ramp-0-6"]:
		e.panel.pick(id)
		var seen: Array = []
		for i in 4:
			seen.append([e.pick_view, str(e.pick_texture().side), e.direction_label.text])
			e.rotate_pick()
		assert_eq(seen, [
			["north", "south", CreatorTexts.get_text("ramp_dir_north")],
			["east", "west", CreatorTexts.get_text("ramp_dir_east")],
			["south", "north", CreatorTexts.get_text("ramp_dir_south")],
			["west", "east", CreatorTexts.get_text("ramp_dir_west")]], id)
		assert_eq(e.pick_view, "north", id + ": round again")


func test_a_placed_rooftop_or_ramp_of_any_size_writes_no_art_and_is_drawn_in_the_engine() -> void:
	var e := _editor()
	_pick(e, "ramp-0-3", "south")
	var r := e.place_asset("ramp-0-3", Vector2(20.5, 20.5))
	assert_eq(r.item.side, "north")
	assert_false(r.item.has("art"))
	assert_false(r.item.has("view"))
	e.panel.pick("rooftop-3")
	var p := e.place_asset("rooftop-3", Vector2(-100.5, 40.5), Vector2(16, 8))
	assert_eq([p.item.w, p.item.h], [16.0, 8.0])
	assert_false(p.item.has("art"))
	for item in [p.item, r.item]:
		var area = e.elevation.areas.filter(func(a): return a.block.id == item.id)[0]
		assert_null(area.art_sprite, "no art piece")
		assert_true(area.is_textured(), "drawn from the piece style")


func test_the_preview_shows_the_current_view() -> void:
	var e := _editor()
	e.panel.pick("rooftop-6")
	assert_eq(e.preview_of(Vector2(0, 0)), {}, "a piece of any size: no art preview")
	e.hover_cell = e.document.cell_at(Vector2(0.5, 0.5))
	var b := e.preview_block()
	assert_eq(b.kind, "platform")
	assert_eq(b.rect, Rect2(0, 0, 16, 16), "T-264: a click is M")
	_pick(e, "ramp-0-6", "west")
	b = e.preview_block()
	assert_eq([b.kind, b.side, b.rect.size], ["ramp", "east", Vector2(24, 10)])
	e._sync_preview()
	assert_not_null(e.preview_drawing)
	assert_true(e.preview_drawing.is_textured())
	e.panel.pick("boulder-b")
	e.mirror_pick()
	assert_eq(e.preview_of(Vector2(0, 0)).texture.resource_path, "res://art/boulders/boulder_b_mirror.png")
	e.panel.pick("")
	assert_eq(e.preview_of(Vector2(0, 0)), {})


# ---- Heights 3 and 6 --------------------------------------------------------------------------

## The elevation sample map's north-west corner, built in the editor: a 3, a 6 on it, a ramp 0 to 3
## climbing its south side and a ramp 3 to 6 climbing the 6's west side.
func _build_nw(e: LevelCreatorEditor) -> Dictionary:
	e.panel.pick("rooftop-3")
	var r3 := e.place_asset("rooftop-3", Vector2(-95.5, -95.5), Vector2(84, 30))
	e.panel.pick("rooftop-6")
	var r6 := e.place_asset("rooftop-6", Vector2(-41.5, -95.5), Vector2(30, 30))
	_pick(e, "ramp-0-3", "north")
	var a := e.place_asset("ramp-0-3", Vector2(-85.5, -65.5))
	_pick(e, "ramp-3-6", "east")
	var b := e.place_asset("ramp-3-6", Vector2(-53.5, -85.5))
	return {"r3": r3.item, "r6": r6.item, "ramp03": a.item, "ramp36": b.item}


func _run_checker(script: String, data: Dictionary, file_name: String) -> Array:
	var path := RunPaths.file(file_name)
	assert_eq(LevelStore.save_level(path, data), OK)
	var output: Array = []
	var code := OS.execute("python", [ProjectSettings.globalize_path(script), ProjectSettings.globalize_path(path)],
		output, true)
	return [code, "\n".join(output)]


func test_rooftops_at_3_and_6_with_their_ramps_pass_the_height_check() -> void:
	var e := _editor()
	var p := _build_nw(e)
	assert_eq(p.r3.height, 3)
	assert_false(p.r3.has("on"), "the 3 stands on the street")
	assert_eq(p.r6.height, 6)
	assert_eq(p.r6.on, p.r3.id, "the 6 stands on the 3")
	assert_eq([p.ramp03.bottom_height, p.ramp03.top_height], [0, 3])
	assert_eq(p.ramp03.side, "south")
	assert_eq(p.ramp03.platform, p.r3.id)
	assert_eq([p.ramp36.bottom_height, p.ramp36.top_height], [3, 6])
	assert_eq(p.ramp36.side, "west")
	assert_eq(p.ramp36.platform, p.r6.id)
	# The drawing has them, and the ground rises.
	assert_eq(e.elevation.areas.size(), 4)
	assert_eq(e.elevation.ground_height.height_at(Vector2(-80, -80)), 3.0)
	assert_eq(e.elevation.ground_height.height_at(Vector2(-30, -80)), 6.0)
	var res := _run_checker("res://tools/check_height_data.py", e.level_data, "t236_heights.json")
	assert_eq(res[0], 0, "check_height_data.py: " + res[1])
	assert_string_contains(res[1], "OK")
	var lvl := _run_checker("res://tools/check_level.py", e.level_data, "t236_level.json")
	assert_eq(lvl[0], 0, "check_level.py: " + lvl[1])


func test_the_south_east_views_pass_the_height_check_too() -> void:
	var e := _editor()
	for step in [["rooftop-3", Vector2(12.5, 66.5), ""], ["rooftop-6", Vector2(12.5, 66.5), ""],
			["ramp-0-3", Vector2(76.5, 54.5), "south"], ["ramp-3-6", Vector2(42.5, 76.5), "west"]]:
		_pick(e, step[0], step[2])
		assert_false(e.place_asset(step[0], step[1], {"rooftop-3": Vector2(84, 30), "rooftop-6": Vector2(30, 30)}.get(step[0], Vector2.ZERO)).is_empty())
	var ramps: Array = e.level_data.ramps
	assert_eq([ramps[0].side, ramps[1].side], ["north", "east"])
	assert_eq(ramps[0].platform, e.level_data.platforms[0].id)
	assert_eq(ramps[1].platform, e.level_data.platforms[1].id)
	assert_eq(e.level_data.platforms[1].on, e.level_data.platforms[0].id)
	var res := _run_checker("res://tools/check_height_data.py", e.level_data, "t236_heights_se.json")
	assert_eq(res[0], 0, "check_height_data.py: " + res[1])


func test_the_links_follow_places_and_deletes() -> void:
	var doc := LevelDocument.new(LevelDocument.new_level_data("x"))
	# A ramp first, then its rooftop: the ramp is linked once the rooftop is there.
	var ramp := doc.place("ramp-0-3", Vector2(-85.5, -65.5), "north")
	assert_eq(ramp.item.platform, "")
	var r3 := doc.place("rooftop-3", Vector2(-95.5, -95.5))
	assert_eq(ramp.item.platform, r3.item.id)
	var r6 := doc.place("rooftop-6", Vector2(-41.5, -95.5))
	assert_eq(r6.item.on, r3.item.id)
	# A 6 off any 3 stands on the street.
	var lone := doc.place("rooftop-6", Vector2(40.5, 40.5))
	assert_false(lone.item.has("on"))
	# Deleting the 3: the 6 no longer stands on it, the ramp climbs nothing.
	doc.delete(r3)
	assert_false(r6.item.has("on"))
	assert_eq(ramp.item.platform, "")


func test_the_controls_labels_come_from_the_texts() -> void:
	var e := _editor()
	assert_eq(e.rotate_button.text, CreatorTexts.get_text("rotate_label"))
	assert_eq(e.mirror_button.text, CreatorTexts.get_text("mirror_label"))
	assert_eq(e.height_label.text, "")
	e.panel.pick("rooftop-6")
	assert_eq(e.height_label.text, CreatorTexts.get_text("rooftop_height_6"))
	e.panel.pick("ramp-0-3")
	assert_eq(e.height_label.text, CreatorTexts.get_text("ramp_height_0_3"))
	e.panel.pick("boulder-a")
	assert_eq(e.height_label.text, "")


func test_r_and_m_keys_rotate_and_mirror() -> void:
	var e := _editor()
	e.panel.pick("ramp-3-6")
	var k := InputEventKey.new()
	k.keycode = KEY_R
	k.pressed = true
	e._unhandled_key_input(k)
	assert_eq(e.pick_view, "east")
	e.panel.pick("boulder-b")
	k.keycode = KEY_M
	e._unhandled_key_input(k)
	assert_eq(e.pick_mirror, true)
