extends GutTest
## Task T-576 (Level design, Decisions, "Hint pieces in the level creator"): the hint pieces, gas (W keycap),
## brake (S keycap), a straight, a curved and a circular arrow. In the level creator each is placed painted on
## the ground or as a standing roadside sign (the top bar's toggle), R turns it through the 8 headings and M
## mirrors the curved and circular arrows. They are placed, selected and deleted like the other pieces (the
## same placement path), saved in the level file's "hints", checked by check_level.py and opened again. In a
## run (and the practice playground, the same map code) a ground hint is drawn flat on the ground under
## everything with no body; a sign stands sorted with the props and blocks the car like one.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const RunScene := preload("res://scenes/run/run.tscn")
const MapScene := preload("res://scenes/level/mvp_map.tscn")
const NavScript := preload("res://scripts/enemies/enemy_navigation.gd")
const ISO := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
const ICONS := ["gas", "brake", "arrow-straight", "arrow-curved", "arrow-circular"]
const LABELS := {"gas": "piece_hint_gas", "brake": "piece_hint_brake", "arrow-straight": "piece_hint_arrow_straight",
	"arrow-curved": "piece_hint_arrow_curved", "arrow-circular": "piece_hint_arrow_circular"}
const HEADINGS := ["270", "315", "0", "45", "90", "135", "180", "225"]
const ROOF := Vector2(-30, -60)


func _editor() -> LevelCreatorEditor:
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.open_new()
	e.level_data["spawn"] = {"x": 111.0, "y": 111.0, "heading": 270}
	e.levels_dir = RunPaths.file("t576_levels")
	add_child_autofree(e)
	return e


## Picks the hint `icon` in `mode`, turned to `heading`, mirrored or not, as the board does: its button,
## the top bar's mode, R and M.
func _pick(e: LevelCreatorEditor, icon: String, mode: String = "ground", heading: String = "270", mirror: bool = false) -> void:
	e.panel.pick("hint-" + icon)
	e.set_hint_mode(mode)
	for i in 8:
		if e.pick_view == heading:
			break
		e.rotate_pick()
	if mirror != e.pick_mirror:
		e.mirror_pick()


func _count_collision(n: Node) -> int:
	var c := 1 if (n is CollisionObject2D or n is CollisionShape2D or n is CollisionPolygon2D) else 0
	for k in n.get_children():
		c += _count_collision(k)
	return c


func _check_level(path: String) -> Array:
	var output: Array = []
	var code := OS.execute("python", [ProjectSettings.globalize_path("res://tools/check_level.py"),
		ProjectSettings.globalize_path(path)], output, true)
	return [code, "\n".join(output)]


func _run_on(path: String) -> Node2D:
	var run: Node2D = RunScene.instantiate()
	run.layout_path = path
	add_child_autofree(run)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	return run


## Every icon on the street both ways, a sign on a rooftop, in several headings, curved and circular mirrored.
func _place_all(e: LevelCreatorEditor) -> Dictionary:
	assert_false(e.document.place("rooftop-3", ROOF + Vector2(1, 1), "", false, Vector2(16, 16)).is_empty())
	e._rebuild_map()
	var out := {}
	for i in ICONS.size():
		var icon: String = ICONS[i]
		var mirror: bool = icon in ["arrow-curved", "arrow-circular"]
		_pick(e, icon, "ground", HEADINGS[i], mirror)
		out[icon + "/ground"] = e.place_asset(e.panel.picked, Vector2(-60.5 + 8.0 * i, 20.5))
		_pick(e, icon, "sign", HEADINGS[7 - i], false)
		out[icon + "/sign"] = e.place_asset(e.panel.picked, Vector2(-60.5 + 8.0 * i, 40.5))
	_pick(e, "arrow-straight", "sign", "90")
	out["roof/sign"] = e.place_asset(e.panel.picked, ROOF + Vector2(6.5, 6.5))
	return out


# ---- The panel and the pick ---------------------------------------------------------------------

func test_the_panel_has_a_driver_hints_group_with_the_five_hints() -> void:
	var e := _editor()
	var g: Dictionary = e.panel.groups.filter(func(x): return x.group == "hints")[0]
	assert_eq(g.label.text, CreatorTexts.get_text("group_hints"))
	assert_eq(g.ids, ICONS.map(func(i): return "hint-" + i))
	for icon in ICONS:
		var b: Button = e.panel.buttons["hint-" + icon]
		assert_eq(b.text, CreatorTexts.get_text(LABELS[icon]))
		assert_not_null(b.icon, icon + ": its picture")


func test_each_hint_is_a_ground_decal_or_a_sign_with_the_top_bars_toggle() -> void:
	var e := _editor()
	for icon in ICONS:
		e.panel.pick("hint-" + icon)
		assert_eq(e.hint_mode(), "ground", icon + ": painted on the ground first")
		assert_true(e.hint_mode_buttons.ground.visible and e.hint_mode_buttons.sign.visible)
		assert_true(e.hint_mode_buttons.ground.button_pressed)
		assert_eq(e.hint_mode_buttons.ground.text, CreatorTexts.get_text("hint_mode_ground"))
		assert_eq(e.hint_mode_buttons.sign.text, CreatorTexts.get_text("hint_mode_sign"))
		e.rotate_pick()
		var heading := e.pick_view
		e.hint_mode_buttons.sign.emit_signal("pressed")
		assert_eq(e.hint_mode(), "sign")
		assert_eq(e.panel.picked, "hint-%s-sign" % icon)
		assert_eq(e.pick_view, heading, "the heading is kept")
		assert_true(e.hint_mode_buttons.sign.button_pressed)
		e.height_pick()
		assert_eq(e.hint_mode(), "sign", "H does not change it: the top bar does")
		e.set_hint_mode("ground")
		assert_eq(e.panel.picked, "hint-%s-ground" % icon)
	e.panel.pick("prop-cones")
	assert_false(e.hint_mode_buttons.ground.visible, "only with a hint picked")
	assert_eq(e.set_hint_mode("sign"), "")


func test_r_steps_through_the_8_headings_in_both_modes() -> void:
	var e := _editor()
	for mode in ["ground", "sign"]:
		_pick(e, "arrow-straight", mode)
		var seen: Array = [e.pick_view]
		for i in 8:
			e.rotate_pick()
			seen.append(e.pick_view)
		assert_eq(seen.slice(0, 8), HEADINGS, mode + ": clockwise from the run's own heading")
		assert_eq(seen[8], "270", mode + ": round again")
		assert_false(e.rotate_button.disabled)


func test_m_mirrors_only_the_curved_and_circular_arrows() -> void:
	var e := _editor()
	for icon in ICONS:
		for mode in ["ground", "sign"]:
			_pick(e, icon, mode)
			var can: bool = icon in ["arrow-curved", "arrow-circular"]
			assert_eq(not e.mirror_button.disabled, can, icon + " " + mode)
			e.mirror_pick()
			assert_eq(e.pick_mirror, can, icon + " " + mode)


func test_the_strip_shows_the_modes_hint_and_the_mirror_hint() -> void:
	var e := _editor()
	_pick(e, "gas", "ground")
	assert_eq(e.panel.look_notes.text, CreatorTexts.get_text("hint_ground_hint"))
	_pick(e, "gas", "sign")
	assert_eq(e.panel.look_notes.text, CreatorTexts.get_text("hint_sign_hint"))
	_pick(e, "arrow-curved", "ground")
	assert_eq(e.panel.look_notes.text, CreatorTexts.get_text("hint_ground_hint") + "\n" + CreatorTexts.get_text("hint_mirror_hint"))


# ---- Placing, selecting, deleting ----------------------------------------------------------------

func test_every_hint_is_placed_both_ways_with_its_heading_and_mirror() -> void:
	var e := _editor()
	var p := _place_all(e)
	assert_eq(e.level_data.hints.size(), 11)
	for i in ICONS.size():
		var icon: String = ICONS[i]
		var g: Dictionary = p[icon + "/ground"]
		var s: Dictionary = p[icon + "/sign"]
		assert_eq(str(g.kind), "hint")
		assert_eq([g.item.icon, g.item.mode, g.item.heading, g.item.mirror], [icon, "ground", int(HEADINGS[i]), icon in ["arrow-curved", "arrow-circular"]])
		assert_eq([g.item.w, g.item.h], [4.0, 4.0], "a ground hint covers a road's width")
		assert_eq([s.item.icon, s.item.mode, s.item.heading, s.item.mirror], [icon, "sign", int(HEADINGS[7 - i]), false])
		assert_eq([s.item.w, s.item.h], [2.0, 2.0])
	# The same snapped spot as any piece (LevelSnapping.placement): the cell under the click.
	assert_eq(Vector2(p["gas/ground"].item.x, p["gas/ground"].item.y), Vector2(-62, 20))
	assert_false(p["roof/sign"].is_empty(), "a sign stands on a rooftop")


func test_a_ground_hint_goes_on_the_street_and_a_sign_not_into_a_building() -> void:
	var e := _editor()
	assert_false(e.document.place("rooftop-3", ROOF + Vector2(1, 1), "", false, Vector2(16, 16)).is_empty())
	assert_false(e.document.place("skyscraper-1", Vector2(41, 41)).is_empty())
	e._rebuild_map()
	_pick(e, "gas", "ground")
	assert_true(e.place_asset(e.panel.picked, ROOF + Vector2(6.5, 6.5)).is_empty(), "not painted on a rooftop")
	assert_eq(e.message_label.text, CreatorTexts.get_text("overlap_message"))
	assert_true(e.place_asset(e.panel.picked, Vector2(41, 41)).is_empty(), "nor in a building")
	_pick(e, "gas", "sign")
	assert_true(e.place_asset(e.panel.picked, Vector2(41, 41)).is_empty(), "a sign not in a building")
	assert_false(e.level_data.has("hints") and not e.level_data.hints.is_empty())
	# Never over the start.
	var s := LevelSpawn.position_of(e.level_data)
	assert_true(e.place_asset(e.panel.picked, s).is_empty(), "a sign never stands on the start")
	_pick(e, "gas", "ground")
	assert_false(e.place_asset(e.panel.picked, s).is_empty(), "a ground hint may lie under it")


func test_hints_are_selected_and_deleted_like_other_pieces() -> void:
	var e := _editor()
	var p := _place_all(e)
	var g: Dictionary = p["brake/ground"]
	var s: Dictionary = p["brake/sign"]
	e.panel.pick("")
	assert_true(is_same(e.select_at(Vector2(float(g.item.x) + 1.0, float(g.item.y) + 1.0)).item, g.item))
	e.delete_selected()
	assert_false(g.item in e.level_data.hints)
	assert_true(is_same(e.select_at(Vector2(float(s.item.x) + 1.0, float(s.item.y) + 1.0)).item, s.item))
	e.delete_selected()
	assert_false(s.item in e.level_data.hints)
	assert_eq(e.level_data.hints.size(), 9)
	assert_eq(e.document.placed_pieces().filter(func(q): return q.kind == "hint").size(), 9)


func test_the_preview_is_the_hint_as_it_will_be_drawn() -> void:
	var e := _editor()
	_pick(e, "arrow-curved", "sign", "45", true)
	e.hover_units = Vector2(10.5, 10.5)
	e.hover_cell = e.document.cell_at(e.hover_units)
	var at := e.current_placement()
	var pv := e.preview_of(at.corner)
	assert_eq([pv.hint.icon, pv.hint.mode, pv.hint.heading, pv.hint.mirror], ["arrow-curved", "sign", 45, true])
	assert_eq(Vector2(pv.hint.x, pv.hint.y), at.corner)
	e._overlay.queue_redraw()
	await wait_process_frames(2)  # the overlay draws it without an error
	assert_true(true)


# ---- Saved, checked, opened again -----------------------------------------------------------------

func test_saved_checked_and_opened_again() -> void:
	var e := _editor()
	_place_all(e)
	e.name_field.text = "T-576 hints"
	assert_eq(e.save(), OK)
	var path := e.level_path
	var saved := LevelStore.load_level(path)
	assert_eq(saved.hints.size(), 11)
	var res := _check_level(path)
	assert_eq(res[0], 0, res[1])
	var e2: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e2.levels_dir = e.levels_dir
	e2.open_level(path)
	add_child_autofree(e2)
	assert_eq(e2.level_data.hints, saved.hints)
	assert_eq(e2.document.placed_pieces().filter(func(q): return q.kind == "hint").size(), 11)
	assert_not_null(e2.map.hint_decals, "drawn in the creator as in the run")
	# A broken hint is refused by the check.
	saved.hints[0]["heading"] = 30
	saved.hints[1]["icon"] = "horn"
	var bad := RunPaths.file("t576_bad.json")
	assert_eq(LevelStore.save_level(bad, saved), OK)
	res = _check_level(bad)
	assert_eq(res[0], 1)
	assert_string_contains(res[1], "heading must be one of")
	assert_string_contains(res[1], "unknown icon")


# ---- In a run ---------------------------------------------------------------------------------------

func _saved_run_level(e: LevelCreatorEditor) -> String:
	var path := RunPaths.file("t576_run_level.json")
	assert_eq(LevelStore.save_level(path, e.document.file_data("T-576 run")), OK)
	return path


func test_in_a_run_ground_hints_lie_flat_under_everything_with_no_body() -> void:
	var e := _editor()
	var p := _place_all(e)
	var run := _run_on(_saved_run_level(e))
	var map = run.map
	var decals: Node2D = map.hint_decals
	assert_not_null(decals)
	assert_eq(decals.get_parent(), map.view_root, "in the view: the isometric projection lays it flat")
	assert_eq(decals.transform, Transform2D.IDENTITY)
	assert_gt(decals.get_index(), map.ground_tiles.get_index(), "over the ground")
	assert_gt(decals.get_index(), map.ground_draw.get_index())
	assert_lt(decals.get_index(), map.buildings_draw.get_index(), "under the buildings")
	assert_lt(decals.get_index(), map.boulder_sprites_root.get_index())
	assert_lt(decals.get_index(), map.prop_sprites_root.get_index(), "under the props and signs")
	assert_eq(decals.z_index, 0)
	assert_eq(decals.items.size(), 5)
	assert_eq(_count_collision(decals), 0, "no body")
	for b in map.prop_bodies:
		assert_true(str(b.get_meta("prop_id")) != str(p["gas/ground"].item.id), "no body for a ground hint")
	# The car drives straight over a ground hint: no crash.
	var g: Dictionary = p["arrow-straight/ground"]
	var hits := _drive_north_into(run, Vector2(float(g.item.x) + 2.0, float(g.item.y) + 14.0), 60)
	assert_eq(hits.size(), 0, "driven over, no crash")
	assert_lt(run.car.model.get_position().y, float(g.item.y), "past it")


func test_the_ground_hint_is_turned_to_its_heading_and_mirrored() -> void:
	var it := {"icon": "arrow-curved", "mode": "ground", "heading": 0, "mirror": false, "x": 0.0, "y": 0.0, "w": 4.0, "h": 4.0}
	# The picture's up (the arrow's way) on the map: heading 0 is +x.
	var up_on_map: Vector2 = Transform2D(LevelHints.ground_angle(it), Vector2.ZERO).basis_xform(Vector2(0, -1))
	assert_almost_eq(up_on_map, Vector2(1, 0), Vector2(0.001, 0.001), "heading 0 points +x")
	it.heading = 270
	up_on_map = Transform2D(LevelHints.ground_angle(it), Vector2.ZERO).basis_xform(Vector2(0, -1))
	assert_almost_eq(up_on_map, Vector2(0, -1), Vector2(0.001, 0.001), "heading 270 points -y, the run's start")
	it.heading = 45
	up_on_map = Transform2D(LevelHints.ground_angle(it), Vector2.ZERO).basis_xform(Vector2(0, -1))
	assert_almost_eq(up_on_map, Vector2(1, 1).normalized(), Vector2(0.001, 0.001))
	# On a sign the icon points the way the heading shows on screen.
	it.heading = 270
	var screen_up := Transform2D(LevelHints.sign_icon_angle(it), Vector2.ZERO).basis_xform(Vector2(0, -1))
	assert_almost_eq(screen_up, ISO.basis_xform(Vector2(0, -1)).normalized(), Vector2(0.001, 0.001))


func test_in_a_run_signs_stand_with_the_props_and_block_the_car() -> void:
	var e := _editor()
	var p := _place_all(e)
	var run := _run_on(_saved_run_level(e))
	var map = run.map
	var signs: Array = map.prop_sprites.filter(func(sp): return sp.has_meta("hint_id"))
	assert_eq(signs.size(), 6, "five on the street, one on the rooftop")
	var bodies: Array = map.prop_bodies.filter(func(b): return b.has_meta("hint_id"))
	assert_eq(bodies.size(), 6)
	for sp in signs:
		assert_eq(sp.get_parent(), map.prop_sprites_root)
		assert_true(sp in map.depth_sprites(), "sorted with the props")
		var icon: Sprite2D = sp.get_node("Icon")
		assert_not_null(icon.texture, "the icon on its face")
	var s: Dictionary = p["arrow-curved/sign"]
	var sp_s: Sprite2D = signs.filter(func(x): return x.get_meta("hint_id") == s.item.id)[0]
	assert_almost_eq(sp_s.get_node("Icon").rotation, LevelHints.sign_icon_angle(s.item), 0.0001)
	var roof: Dictionary = p["roof/sign"]
	var sp_r = signs.filter(func(x): return x.get_meta("hint_id") == roof.item.id)[0]
	assert_almost_eq(float(sp_r.ground_units), 3.0, 0.001, "on the rooftop, at its height")
	for b in bodies:
		assert_true(b is StaticBody2D)
		assert_true(b.collision_layer & 1 != 0, "collision layer 1, as a prop")
		var sh: CollisionShape2D = b.get_node("Shape")
		assert_true(sh.shape is CircleShape2D)
	# The enemies' paths and spawn spots go round it.
	var c := LevelHints.centre_of(s.item)
	assert_true(LevelProps.blocks_spot(map.layout, c, 0.5))
	assert_true(LevelProps.obstacles(map.layout).circles.any(func(x): return x[0] == c))
	# The car crashes into a sign like a prop.
	var hits := _drive_north_into(run, c + Vector2(0, 14))
	assert_eq(hits.size(), 1, "one crash")
	assert_true(hits[0].has_meta("hint_id"), "into the sign's body")
	assert_gt(run.car.model.get_position().y, c.y, "stopped south of the sign")


func _drive_north_into(run: Node2D, start: Vector2, steps: int = 400) -> Array:
	var car = run.car
	car.model.set_position(start)
	car.model.rotation = -PI / 2.0
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	var hits: Array = []
	car.hit_obstacle.connect(func(c, _i, _n, _s): hits.append(c))
	car.scripted_input = [true, false, 0.0]
	for i in steps:
		car.physics_step()
		if not hits.is_empty():
			break
	return hits


func test_the_practice_playground_draws_hints_with_the_same_map_code() -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/level/practice_playground.json"))
	layout["hints"] = [
		{"id": "hint-1", "icon": "gas", "mode": "ground", "heading": 0, "mirror": false, "x": -50.0, "y": -2.0, "w": 4.0, "h": 4.0},
		{"id": "hint-2", "icon": "arrow-straight", "mode": "sign", "heading": 0, "mirror": false, "x": -50.0, "y": 4.0, "w": 2.0, "h": 2.0}]
	var map = MapScene.instantiate()
	map.layout = layout
	add_child_autofree(map)
	assert_not_null(map.hint_decals)
	assert_eq(map.hint_decals.get_index(), map.ground_tiles.get_index() + 1, "over the grid ground")
	assert_eq(map.prop_bodies.filter(func(b): return b.has_meta("hint_id")).size(), 1)


# ---- Levels from before ---------------------------------------------------------------------------

func test_levels_without_hints_open_and_play_as_before() -> void:
	var e := _editor()
	assert_false(e.document.file_data("Old").has("hints"), "no hints key written for a level without any")
	for path in ["res://data/level/kaiju_city_map.json", "res://data/level/practice_playground.json", "res://data/level/elevation_sample_map.json"]:
		var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		assert_false(layout.has("hints"), path)
		var map = MapScene.instantiate()
		map.layout = layout
		add_child_autofree(map)
		assert_null(map.hint_decals, path)
		assert_eq(map.prop_bodies.filter(func(b): return b.has_meta("hint_id")).size(), 0, path)
		assert_eq(map.view_root.get_children().filter(func(n): return n.name == "HintDecals").size(), 0, path)
	var res := _check_level("res://data/level/kaiju_city_map.json")
	assert_eq(res[0], 0, res[1])
