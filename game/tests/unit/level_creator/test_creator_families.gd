extends GutTest
## Task T-262: the level creator's side panel is one button per kind of piece (a family of the
## catalogue, creator_families.gd), in six groups; V, R, M and H step a piece's look, turn, mirror
## and height, and the looks strip under it shows and picks its looks. Every pose the old panel
## offered (each catalogue entry in each of its views and mirrors) is still a member and places
## exactly what it did, so levels saved before open, place and play as before.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
## A level the board saved with the creator before T-262 (its level_01.json, copied unchanged).
const OLD_LEVEL := "res://tests/fixtures/t262_level_saved_before.json"
const GROUPS := ["roads", "ground", "levels", "buildings", "obstacles", "decoration"]

var dir: String


func before_each() -> void:
	dir = RunPaths.file("t262_levels_" + str(randi()))


func _editor(path: String = "") -> LevelCreatorEditor:
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.levels_dir = dir
	if path == "":
		e.open_new()
	else:
		e.open_level(path)
	add_child_autofree(e)
	return e


func _key(e: LevelCreatorEditor, code: Key) -> void:
	var k := InputEventKey.new()
	k.keycode = code
	k.pressed = true
	e._unhandled_key_input(k)


func _check_level(path: String) -> Array:
	var output: Array = []
	var code := OS.execute("python", [ProjectSettings.globalize_path("res://tools/check_level.py"),
		ProjectSettings.globalize_path(path)], output, true)
	return [code, "\n".join(output)]


# ---- The panel ----------------------------------------------------------------------------------

func test_six_groups_one_button_per_kind_with_labels_from_the_texts() -> void:
	var e := _editor()
	assert_eq(CreatorFamilies.groups(), GROUPS)
	var shown := e.panel.entries_by_category()
	assert_eq(shown.keys(), GROUPS.map(func(g): return CreatorTexts.get_text("group_" + g)))
	assert_eq(shown[CreatorTexts.get_text("group_roads")], ["road", "centre-line", "zebra-crossing", "cracked-road"])
	assert_eq(shown[CreatorTexts.get_text("group_ground")], ["gravel", "sidewalk", "meteor-crater"])  # T-398
	assert_eq(shown[CreatorTexts.get_text("group_levels")], ["platform", "ramp"])
	assert_eq(shown[CreatorTexts.get_text("group_buildings")], ["building-small", "building-long", "lowrise", "skyscraper"])
	assert_eq(shown[CreatorTexts.get_text("group_obstacles")], ["boulder", "barrier", "cones", "crates", "parked-car", "broken-car"])  # T-398
	assert_eq(shown[CreatorTexts.get_text("group_decoration")], ["street-lamp", "ac-unit", "water-tank", "roof-vent", "roof-sign"])
	assert_eq(e.panel.buttons.size(), 24, "one button per kind (T-398: sidewalk, meteor crater, parked car, broken car) (Pavement left out: no ground tile art)")
	for fid in e.panel.buttons:
		var f := CreatorFamilies.family(fid)
		var b: Button = e.panel.buttons[fid]
		assert_true(str(f.label).begins_with("piece_"), fid)
		assert_eq(b.text, CreatorTexts.get_text(str(f.label)), fid)
		assert_ne(b.text, "", fid)
		assert_not_null(b.icon, fid + " shows its first look")
	assert_eq(e.hint_label.text, CreatorTexts.get_text("controls_hint_spawn"))  # T-280: the line with moving the start.


func test_picking_a_button_picks_its_first_look_and_shows_the_strip() -> void:
	var e := _editor()
	assert_false(e.panel.looks_strip.visible, "no strip with nothing picked")
	e.panel.buttons["skyscraper"].button_pressed = true
	assert_eq(e.panel.picked_family, "skyscraper")
	assert_eq(e.panel.picked, "skyscraper-1")
	assert_true(e.panel.looks_strip.visible)
	assert_eq(e.panel.looks_heading.text, CreatorTexts.get_text("looks_heading"))
	assert_eq(e.panel.look_buttons.size(), 12, "6 towers x 2 bodies")
	assert_eq(e.panel.look_counter.text, CreatorTexts.get_text("look_counter").format({"n": 1, "count": 12}))
	# The strip sits right under the Buildings group's buttons.
	var grid: Node = e.panel.groups[GROUPS.find("buildings")].grid
	assert_eq(e.panel.looks_strip.get_index(), grid.get_index() + 1)
	e.panel.buttons["skyscraper"].button_pressed = false
	assert_eq(e.panel.picked, "")
	assert_false(e.panel.looks_strip.visible)


func test_the_hint_line_fits_the_map_view() -> void:
	var e := _editor()
	await wait_process_frames(2)
	e._fit_hint()
	var fs := e.hint_label.get_theme_font_size("font_size")
	assert_gte(fs, LevelCreatorEditor.HINT_MIN_FONT)
	var w := e.hint_label.get_theme_font("font").get_string_size(e.hint_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	assert_true(w <= e.map_view.size.x or fs == LevelCreatorEditor.HINT_MIN_FONT, "the line fits (%d px in %d)" % [w, e.map_view.size.x])


# ---- The keys -----------------------------------------------------------------------------------

func test_v_steps_the_looks_and_the_strip_follows() -> void:
	var e := _editor()
	e.panel.pick("skyscraper")
	_key(e, KEY_V)
	assert_eq(e.panel.picked, "skyscraper-1")
	assert_eq(e.pick_variant, "1", "a tower's second body")
	assert_eq(e.panel.look_counter.text, CreatorTexts.get_text("look_counter").format({"n": 2, "count": 12}))
	assert_true(e.panel.look_buttons[1].button_pressed)
	_key(e, KEY_V)
	assert_eq(e.panel.picked, "skyscraper-2")
	for i in 10:
		_key(e, KEY_V)
	assert_eq(e.panel.picked, "skyscraper-1", "round to the first after the last")
	assert_eq(e.pick_variant, "0")


func test_r_turns_m_mirrors_and_h_changes_height() -> void:
	var e := _editor()
	e.panel.pick("barrier")
	assert_eq(e.pick_view, "north")
	_key(e, KEY_R)
	assert_eq(e.pick_view, "east")
	assert_true(e.mirror_button.disabled, "a barrier has no mirror")
	e.panel.pick("road")
	assert_eq(e.panel.picked, "road-y_plain_a0")
	# T-263: a road is painted with the brush, which turns it itself: R does nothing, M is a0m.
	assert_true(e.rotate_button.disabled, "the road brush has no turns")
	_key(e, KEY_R)
	assert_eq(e.panel.picked, "road-y_plain_a0")
	_key(e, KEY_M)
	assert_eq(e.panel.picked, "road-y_plain_a0m", "M mirrors the asphalt to a0m")
	assert_eq(e.brush_asphalt(), "a0m")
	e.panel.pick("boulder")
	_key(e, KEY_M)
	assert_eq(e.panel.picked, "boulder-a")
	assert_true(e.pick_mirror)
	_key(e, KEY_V)
	assert_eq(e.panel.picked, "boulder-b")
	assert_true(e.pick_mirror, "V keeps the mirror")
	e.panel.pick("ramp")
	_key(e, KEY_R)
	assert_eq(e.pick_view, "east")
	_key(e, KEY_H)
	assert_eq(e.panel.picked, "ramp-3-6")
	assert_eq(e.pick_view, "east", "H keeps the direction")
	_key(e, KEY_H)
	assert_eq(e.panel.picked, "ramp-0-6")
	# T-400: then the small jump ramps, 0 to 2, 3 to 5 and 6 to 8, before going round.
	for small in ["ramp-0-2", "ramp-3-5", "ramp-6-8"]:
		_key(e, KEY_H)
		assert_eq(e.panel.picked, small)
		assert_eq(e.pick_view, "east", "H keeps the direction")
	_key(e, KEY_H)
	assert_eq(e.panel.picked, "ramp-0-3")
	e.panel.pick("platform")
	_key(e, KEY_H)
	assert_eq(e.panel.picked, "rooftop-6")
	e.panel.pick("cones")
	_key(e, KEY_H)
	assert_eq(e.panel.picked, "prop-cones", "H does nothing without heights")


func test_clicking_a_look_in_the_strip_picks_it() -> void:
	var e := _editor()
	e.panel.pick("boulder")
	assert_eq(e.panel.look_buttons.size(), 2)
	e.panel.look_buttons[1].pressed.emit()
	assert_eq(e.panel.picked, "boulder-b")
	assert_eq(e.panel.look_counter.text, CreatorTexts.get_text("look_counter").format({"n": 2, "count": 2}))
	var placed := e.place_asset(e.panel.picked, Vector2(10.5, 10.5))
	assert_eq(str(placed.item.variant), "b")


func test_a_skyscraper_second_body_is_written_as_its_look() -> void:
	var e := _editor()
	e.panel.pick("skyscraper")
	for i in 3:
		e.look_pick()
	assert_eq(e.panel.picked, "skyscraper-2")
	assert_eq(e.pick_variant, "1")
	var placed := e.place_asset(e.panel.picked, Vector2(20.5, 20.5))
	assert_eq(placed.item.asset, "skyscraper-2")
	assert_eq(int(placed.item.look), 1)


# ---- Everything the old panel offered -----------------------------------------------------------

func test_every_old_pose_is_in_a_family_and_places_the_same_data() -> void:
	# The old panel: one button per catalogue entry (not the road pieces' single tiles), placed in
	# each view and mirror its art has (texture_of with the first variant).
	var old_doc := LevelDocument.new(LevelDocument.new_level_data("old"))
	var new_doc := LevelDocument.new(LevelDocument.new_level_data("new"))
	var count := 0
	for en in LevelDocument.panel_entries():
		var id := str(en.id)
		if str(en.kind) == "road":
			continue  # T-263: roads are painted with the brush (test_road_brush.gd); the tiles stay in the catalogue
		for v in en.views:
			for mr in en.mirrors:
				if LevelDocument.texture_of(id, str(v), bool(mr)).get("view") != v:
					continue
				var m := CreatorFamilies.member_for(id, str(v), bool(mr))
				assert_false(m.is_empty(), "%s %s %s is in a family" % [id, v, mr])
				if m.is_empty():
					continue
				assert_eq([str(m.asset), str(m.view), bool(m.mirror)], [id, str(v), bool(mr)])
				var fam := CreatorFamilies.family_of_asset(id)
				assert_true(CreatorFamilies.family(fam).members.has(m))
				var at := Vector2(-110.5 + 16.0 * (count % 14), -110.5 + 16.0 * (count / 14))
				var a := old_doc.place(id, at, str(v), bool(mr))
				var b := new_doc.place(str(m.asset), at, str(m.view), bool(m.mirror), Vector2.ZERO, "", "" if id.begins_with("skyscraper-") else str(m.variant))
				assert_eq(str(a.get("item", a.get("cell"))), str(b.get("item", b.get("cell"))), "%s %s %s places the same" % [id, v, mr])
				count += 1
	assert_eq(JSON.stringify(old_doc.file_data("x")), JSON.stringify(new_doc.file_data("x")), "the same level data")
	assert_gt(count, 50, "every pose but the road tiles'")


# ---- Old levels and new saves -------------------------------------------------------------------

func test_a_level_saved_before_opens_takes_new_pieces_and_keeps_its_own() -> void:
	var before: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OLD_LEVEL))
	var e := _editor(OLD_LEVEL)
	assert_eq(e.map.layout.buildings.size(), before.buildings.size(), "its buildings are drawn")
	assert_eq(e.document.placed_pieces().size(), before.buildings.size() + 4 + before.platforms.size() + before.ramps.size())
	for fid in ["skyscraper", "lowrise", "boulder", "barrier", "street-lamp"]:
		e.panel.pick(fid)
		e.look_pick()
		assert_false(e.place_asset(e.panel.picked, Vector2(60.5, 90.5) + Vector2(14.0 * ["skyscraper", "lowrise", "boulder", "barrier", "street-lamp"].find(fid), 0)).is_empty(), fid)
	e.panel.pick("")
	assert_eq(e.save(), OK)
	var after: Dictionary = LevelStore.load_level(e.level_path)
	assert_eq(after.buildings.slice(0, before.buildings.size()), before.buildings, "its buildings unchanged")
	assert_eq(after.platforms, before.platforms)
	assert_eq(after.ramps, before.ramps)
	assert_eq(after.pattern_copies.slice(0, before.pattern_copies.size()), before.pattern_copies)
	# check_level.py finds no new problem (the board's level has four ramps not yet on a rooftop).
	var res_before := _check_level(OLD_LEVEL)
	var res_after := _check_level(e.level_path)
	var before_lines: Array = Array(str(res_before[1]).split("\n")).filter(func(l): return not l.begins_with("spawn:"))  # T-280: an old file has none
	assert_eq(str(res_after[1]), "\n".join(before_lines), "the same report as before")


func test_a_new_level_with_every_kind_passes_check_level() -> void:
	var e := _editor()
	var x := -110.5
	var y := -110.5
	for fid in e.panel.buttons:
		if fid in ["platform", "ramp"]:
			continue
		e.panel.pick(fid)
		e.look_pick()
		e.rotate_pick()
		var placed := e.place_asset(e.panel.picked, Vector2(x, y))
		assert_false(placed.is_empty(), fid + " placed")
		x += 40.0
		if x > 100.0:
			x = -110.5
			y += 40.0
	# A platform at 6 (H) and a ramp 0 to 6 (H twice) climbing north up its south side.
	e.panel.pick("platform")
	e.height_pick()
	assert_false(e.place_asset(e.panel.picked, Vector2(0.5, 40.5), Vector2(16, 16)).is_empty(), "platform placed")
	e.panel.pick("ramp")
	e.height_pick()
	e.height_pick()
	assert_eq(e.panel.picked, "ramp-0-6")
	assert_eq(e.pick_view, "north")
	assert_false(e.place_asset(e.panel.picked, Vector2(2.5, 56.5), Vector2(10, 0)).is_empty(), "ramp placed")
	assert_eq(str(e.level_data.ramps[0].platform), str(e.level_data.platforms[0].id), "the ramp climbs the platform")
	e.panel.pick("")
	assert_eq(e.save(), OK)
	var res := _check_level(e.level_path)
	assert_eq(res[0], 0, "check_level.py: " + res[1])


func test_a_level_saved_before_plays() -> void:
	TestSave.isolate()
	var run := GameFlow.add_run(self, PlayerProgress.new(), OLD_LEVEL)
	await wait_process_frames(2)
	assert_eq(run.map.layout_path, OLD_LEVEL)
	assert_true(run.state.is_running())
	assert_eq(run.state.time_left_text(), "8:00")
	run.queue_free()
	await wait_process_frames(1)
	get_tree().paused = false
	TestSave.restore()
