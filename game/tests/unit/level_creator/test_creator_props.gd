extends GutTest
## Task T-253: the level creator's props (barrier, cones, crates, AC unit, water tank, roof vent,
## street lamp, rooftop sign): each placed in four rotations on the ground and on a rooftop, saved
## and reopened, passing check_level.py; each a solid obstacle for the car (it crashes, the combo is
## cut) and for the enemies (they path round it); everything about a prop in data/level/props.json,
## labels from creator_texts.json, no Redgull red.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const RunScene := preload("res://scenes/run/run.tscn")
const NavScript := preload("res://scripts/enemies/enemy_navigation.gd")
const PROP_IDS := ["prop-barrier", "prop-cones", "prop-crates", "prop-ac-unit", "prop-water-tank",
	"prop-roof-vent", "prop-street-lamp", "prop-roof-sign"]
const ROTATIONS := ["north", "east", "south", "west"]
const LABELS := {"prop-barrier": "prop_barrier", "prop-cones": "prop_cones", "prop-crates": "prop_crates",
	"prop-ac-unit": "prop_ac_unit", "prop-water-tank": "prop_water_tank", "prop-roof-vent": "prop_roof_vent",
	"prop-street-lamp": "prop_street_lamp", "prop-roof-sign": "prop_roof_sign"}


func _editor() -> LevelCreatorEditor:
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.open_new()
	e.levels_dir = RunPaths.file("t253_levels")
	add_child_autofree(e)
	return e


func _pick(e: LevelCreatorEditor, id: String, view: String) -> void:
	e.panel.pick(id)
	for i in 4:
		if e.pick_view == view:
			return
		e.rotate_pick()


func _r(item: Dictionary) -> Rect2:
	return Rect2(float(item.x), float(item.y), float(item.w), float(item.h))


func _check_level(path: String) -> Array:
	var output: Array = []
	var code := OS.execute("python", [ProjectSettings.globalize_path("res://tools/check_level.py"),
		ProjectSettings.globalize_path(path)], output, true)
	return [code, "\n".join(output)]


## A level with a 3 high rooftop (x -30..30, y -30..30) for the props to stand on.
func _with_rooftop(e: LevelCreatorEditor) -> void:
	e.panel.pick("rooftop-3")
	var p := e.place_asset("rooftop-3", Vector2(-29, -29), Vector2(60, 60))
	assert_false(p.is_empty(), "the rooftop is placed")
	e.panel.pick("")


# ---- The set and its data -----------------------------------------------------------------------

func test_the_catalogue_has_the_eight_props_in_four_rotations() -> void:
	var ids: Array = []
	for en in LevelDocument.entries():
		if str(en.kind) == "prop":
			ids.append(str(en.id))
			assert_eq(LevelDocument.views_of(str(en.id)), ROTATIONS, str(en.id))
	assert_eq(ids, PROP_IDS)


func test_each_prop_is_described_in_one_data_file_with_art_per_rotation() -> void:
	for id in PROP_IDS:
		var p := LevelProps.prop(id)
		assert_false(p.is_empty(), id)
		assert_true(p.has("footprint_units") and p.has("collision") and p.has("height_units"), id)
		for rot in ROTATIONS:
			var s := LevelProps.sprite_of(id, rot)
			assert_false(s.is_empty(), "%s %s has a sprite" % [id, rot])
			var anchor: Vector2 = s.anchor_px
			var size: Vector2 = (s.texture as Texture2D).get_size()
			assert_true(anchor.x >= 0 and anchor.y >= 0 and anchor.x < size.x and anchor.y < size.y, "%s %s anchor" % [id, rot])


func test_the_panel_lists_the_props_under_obstacles_and_decoration_with_creator_texts_labels() -> void:
	# T-262: the props are families under Obstacles and Decoration, one button each, named piece_*.
	var e := _editor()
	var by_cat := e.panel.entries_by_category()
	assert_eq(by_cat[CreatorTexts.get_text("group_obstacles")], ["boulder", "barrier", "cones", "crates"])
	assert_eq(by_cat[CreatorTexts.get_text("group_decoration")],
		["street-lamp", "ac-unit", "water-tank", "roof-vent", "roof-sign"])
	for id in PROP_IDS:
		var fid := CreatorFamilies.family_of_asset(id)
		var b: Button = e.panel.buttons[fid]
		assert_eq(b.text, CreatorTexts.get_text("piece_" + str(LABELS[id]).trim_prefix("prop_")), id)
		assert_ne(b.text, "", id)


func test_the_footprint_turns_with_the_rotation() -> void:
	assert_eq(LevelProps.footprint("prop-barrier", "north"), Vector2(4, 1))
	assert_eq(LevelProps.footprint("prop-barrier", "south"), Vector2(4, 1))
	assert_eq(LevelProps.footprint("prop-barrier", "east"), Vector2(1, 4))
	assert_eq(LevelProps.footprint("prop-barrier", "west"), Vector2(1, 4))
	assert_eq(LevelDocument.piece_size("prop-barrier", "east"), Vector2(1, 4))
	assert_eq(LevelProps.footprint("prop-water-tank", "east"), Vector2(4, 4))


func test_no_sprite_has_redgull_red() -> void:
	for id in PROP_IDS:
		for rot in ROTATIONS:
			var img := (LevelProps.sprite_of(id, rot).texture as Texture2D).get_image()
			var red := 0
			for y in img.get_height():
				for x in img.get_width():
					var c := img.get_pixel(x, y)
					if c.a > 0.5 and c.r8 >= 150 and c.g8 <= 100 and c.b8 <= 100 and c.r8 - maxi(c.g8, c.b8) >= 70:
						red += 1
			assert_eq(red, 0, "%s %s has no red" % [id, rot])


# ---- Placing, saving, checking ------------------------------------------------------------------

func test_every_prop_places_in_four_rotations_on_the_ground_and_on_a_rooftop() -> void:
	var e := _editor()
	_with_rooftop(e)
	var n := 0
	for id in PROP_IDS:
		for rot in ROTATIONS:
			# On the ground (south of the rooftop), then on the rooftop.
			for spot in [Vector2(-100 + 5 * n, 50), Vector2(-20 + 6 * (n % 7), -20 + 6 * (n / 7))]:
				_pick(e, id, rot)
				var piece := e.place_asset(id, spot + Vector2(0.1, 0.1))
				assert_false(piece.is_empty(), "%s %s placed at %s" % [id, rot, spot])
				assert_eq(piece.kind, "prop")
				assert_eq(piece.item.asset, id)
				assert_eq(piece.item.rotation, rot)
				assert_eq(_r(piece.item).size, LevelProps.footprint(id, rot), "%s %s footprint" % [id, rot])
			n += 1
	assert_eq(e.level_data.props.size(), 64)
	# On the street they stand at 0, on the rooftop at its height.
	var on_roof := 0
	for it in e.level_data.props:
		var h := e.document.height_at(_r(it).get_center())
		assert_true(is_equal_approx(h, 3.0) or is_equal_approx(h, 0.0))
		on_roof += 1 if is_equal_approx(h, 3.0) else 0
	assert_eq(on_roof, 32)


func test_props_are_saved_reopened_and_pass_check_level() -> void:
	var e := _editor()
	_with_rooftop(e)
	var n := 0
	for id in PROP_IDS:
		for rot in ROTATIONS:
			_pick(e, id, rot)
			assert_false(e.place_asset(id, Vector2(-100 + 6 * (n % 30), 60 + 6 * (n / 30)) + Vector2(0.1, 0.1)).is_empty())
			_pick(e, id, rot)
			assert_false(e.place_asset(id, Vector2(-26 + 6 * (n % 8), -26 + 6 * (n / 8)) + Vector2(0.1, 0.1)).is_empty())
			n += 1
	e.name_field.text = "T-253 props"
	assert_eq(e.save(), OK)
	var path := e.level_path
	var saved := LevelStore.load_level(path)
	assert_eq(saved.props.size(), 64)
	var res := _check_level(path)
	assert_eq(res[0], 0, res[1])
	# Reopened: the same props, drawn again.
	var e2: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e2.levels_dir = e.levels_dir
	e2.open_level(path)
	add_child_autofree(e2)
	assert_eq(e2.level_data.props, saved.props)
	assert_eq(e2.map.prop_sprites.size(), 64)
	assert_eq(e2.map.prop_bodies.size(), 64)
	assert_eq(e2.document.placed_pieces().filter(func(p): return p.kind == "prop").size(), 64)


func test_a_prop_that_would_leave_the_map_is_not_placed() -> void:
	var e := _editor()
	_pick(e, "prop-barrier", "north")
	assert_true(e.place_asset("prop-barrier", Vector2(118.5, 0.5)).is_empty(), "4 wide at the east edge")
	_pick(e, "prop-barrier", "east")
	assert_true(e.place_asset("prop-barrier", Vector2(0.5, 118.5)).is_empty(), "4 deep at the south edge")
	assert_false(e.level_data.has("props") and not e.level_data.props.is_empty())


func test_a_prop_is_selected_and_deleted() -> void:
	var e := _editor()
	_with_rooftop(e)
	_pick(e, "prop-crates", "north")
	var piece := e.place_asset("prop-crates", Vector2(0.1, 0.1))
	assert_false(piece.is_empty())
	e.panel.pick("")
	var sel := e.select_at(Vector2(1, 1))
	assert_eq(sel.kind, "prop", "the prop is on top of the rooftop")
	e.delete_selected()
	assert_eq(e.level_data.props.size(), 0)
	assert_eq(e.map.prop_sprites.size(), 0)
	assert_eq(e.select_at(Vector2(1, 1)).kind, "rooftop")


func test_the_preview_shows_the_picked_rotation() -> void:
	var e := _editor()
	_pick(e, "prop-barrier", "north")
	var north := e.preview_of(Vector2(0, 0))
	_pick(e, "prop-barrier", "east")
	var east := e.preview_of(Vector2(0, 0))
	assert_false(north.is_empty())
	assert_ne(north.texture, east.texture, "another sprite for another rotation")
	assert_eq(e.placement_at(Vector2(0.5, 0.5)).rect.size, Vector2(1, 4))


func test_a_prop_stands_at_the_height_under_it() -> void:
	var e := _editor()
	_with_rooftop(e)
	_pick(e, "prop-ac-unit", "north")
	e.place_asset("prop-ac-unit", Vector2(0.1, 0.1))
	_pick(e, "prop-ac-unit", "north")
	e.place_asset("prop-ac-unit", Vector2(0.1, 80.1))
	var roof: Node2D = e.map.prop_sprites[0]
	var street: Node2D = e.map.prop_sprites[1]
	# The same sprite and anchor: the rooftop's drawn 3 units (48 px) higher, less its position.
	var iso_delta: Vector2 = LevelProps.MvpMapScript.ISO_TRANSFORM * (Vector2(0, -80) * 16.0)
	assert_almost_eq(roof.position.y - street.position.y, iso_delta.y - 48.0, 0.01)
	assert_almost_eq(roof.position.x - street.position.x, iso_delta.x, 0.01)


# ---- Crashes, the combo, the enemies ------------------------------------------------------------

## A level with one prop standing alone, saved, and a run on it with the car 12 units south of it
## heading north.
func _run_with_prop(asset: String, rotation: String, spot: Vector2) -> Node2D:
	var e := _editor()
	_pick(e, asset, rotation)
	var piece := e.place_asset(asset, spot)
	assert_false(piece.is_empty())
	var path := RunPaths.file("t253_run_level.json")
	assert_eq(LevelStore.save_level(path, e.document.file_data("T-253 run")), OK)
	var run: Node2D = RunScene.instantiate()
	run.layout_path = path
	add_child_autofree(run)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	return run


func _drive_north_into(run: Node2D, start: Vector2) -> Array:
	var car = run.car
	car.model.set_position(start)
	car.model.rotation = -PI / 2.0
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	var hits: Array = []
	car.hit_obstacle.connect(func(c, _i, _n, _s): hits.append(c))
	car.scripted_input = [true, false, 0.0]
	for i in 400:
		car.physics_step()
		if not hits.is_empty():
			break
	return hits


func test_the_car_crashes_into_a_barrier_and_the_combo_is_cut() -> void:
	var run := _run_with_prop("prop-barrier", "north", Vector2(0.1, -39.9))  # (-0.. 4 x 1 at x 0..4, y -40..-39)
	run.state.add_trick("alternate_drift")
	run.state.add_trick("alternate_drift")
	var before: float = run.state.combo
	assert_gt(before, 1.0)
	var hits := _drive_north_into(run, Vector2(2, -25))
	assert_eq(hits.size(), 1, "one crash")
	assert_true(hits[0].has_meta("prop_id"), "into the prop's body")
	assert_lt(run.state.combo, before, "the combo is cut")
	assert_almost_eq(run.state.combo, ComboData.new().after_collision(before), 0.000001, "as with a boulder")
	assert_gt(run.car.model.get_position().y, -39.0, "stopped south of the barrier")


func test_the_car_crashes_into_a_round_prop() -> void:
	var run := _run_with_prop("prop-cones", "north", Vector2(0.1, -39.9))  # a circle of 0.9 at (1, -39)
	var hits := _drive_north_into(run, Vector2(1, -25))
	assert_eq(hits.size(), 1)
	assert_true(hits[0].has_meta("prop_id"))
	assert_gt(run.car.model.get_position().y, -39.0)


func test_every_prop_stops_the_car() -> void:
	for id in PROP_IDS:
		var run := _run_with_prop(id, "north", Vector2(0.1, -39.9))
		var f := LevelProps.footprint(id, "north")
		var hits := _drive_north_into(run, Vector2(f.x / 2.0, -25))
		assert_eq(hits.size(), 1, id)
		assert_gt(run.car.model.get_position().y, -39.9, id + ": stopped south of it")
		run.queue_free()


func test_enemies_path_round_a_prop() -> void:
	var e := _editor()
	# A barrier across the way (1 x 4 at x 0..1, y -2..2 facing east), nothing else.
	_pick(e, "prop-barrier", "east")
	assert_false(e.place_asset("prop-barrier", Vector2(0.1, -1.9)).is_empty())
	var nav = NavScript.build_for_map(e.map)
	var barrier := Rect2(0, -2, 1, 4)
	var path: PackedVector2Array = nav.find_path(Vector2(-7, 0), Vector2(8, 0))
	assert_gt(path.size(), 2, "a path exists")
	for p in path:
		assert_false(barrier.grow(0.5).has_point(p), "the path point %s is clear of the prop" % p)
	# The straight line would have crossed it; so the path bends.
	var bent := false
	for p in path:
		bent = bent or absf(p.y) > 1.9
	assert_true(bent, "it goes round")
	# A round prop closes its cells too.
	var e2 := _editor()
	_pick(e2, "prop-water-tank", "north")
	assert_false(e2.place_asset("prop-water-tank", Vector2(0.1, 0.1)).is_empty())
	var nav2 = NavScript.build_for_map(e2.map)
	assert_eq(nav2.open[nav2.cell_at(Vector2(1, 1))], 0, "the tank's cell is closed")
	assert_eq(nav2.open[nav2.cell_at(Vector2(21, 21))], 1, "a cell away from it is open")


func test_spawn_spots_inside_a_prop_are_refused() -> void:
	var e := _editor()
	_pick(e, "prop-crates", "north")
	e.place_asset("prop-crates", Vector2(0.1, 0.1))  # 2 x 2 at 0..2
	assert_true(e.map.prop_blocks_spot(Vector2(1, 1), 0.5))
	assert_true(e.map.prop_blocks_spot(Vector2(2.3, 1), 0.5), "within a radius of its edge")
	assert_false(e.map.prop_blocks_spot(Vector2(6, 6), 0.5))
	assert_false(e.map.is_open_spot(Vector2(1, 1), 0.5))
	assert_true(e.map.is_open_spot(Vector2(10, 10), 0.5))
