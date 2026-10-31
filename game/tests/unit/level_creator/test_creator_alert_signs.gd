extends GutTest
## Task T-441 (Level design, Decisions, "Kaiju alert signs are level creator pieces"): the standing kaiju
## alert sign and the alert banner are level creator pieces, each in both designs (head, body). A sign stands
## on the ground, a rooftop or a short building at that height; a banner hangs on a skyscraper's south or
## east wall at a chosen height, never on a platform or a short building. Both are saved, reopened and drawn
## in a run exactly as in the editor (kaiju_signs.gd), with no collisions. The fixed sign list of T-130
## (data/level/kaiju_signs.json) is retired: a map shows only the signs its level places.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const RunScene := preload("res://scenes/run/run.tscn")
const MapScene := preload("res://scenes/level/mvp_map.tscn")
const KaijuSigns := preload("res://scripts/level/kaiju_signs.gd")
const ISO := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
const NOSE_UP := -PI / 2.0

## The fixture level's pieces (units): a skyscraper, a second one, a height 3 rooftop, a short building
## (a platform at 3) and a small building.
const SKY_A := Vector2(20, 20)
const SKY_B := Vector2(60, -40)
const ROOF := Vector2(-30, -60)
const SHORT := Vector2(-60, 20)
const SMALL := Vector2(-60, 60)
## Where the standing signs go (units, on the cell under them): the street, the rooftop, the short building.
const SIGN_STREET := Vector2(40.5, -20.5)
const SIGN_ROOF := Vector2(-24.5, -54.5)
const SIGN_SHORT := Vector2(-56.5, 24.5)


func _editor() -> LevelCreatorEditor:
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.open_new()
	e.level_data["spawn"] = {"x": 111.0, "y": 111.0, "heading": 270}
	e.levels_dir = RunPaths.file("t441_levels")
	add_child_autofree(e)
	return e


## The fixture's buildings and rooftop, placed in the document (no snapping), then drawn.
func _with_buildings(e: LevelCreatorEditor) -> void:
	var d := e.document
	assert_false(d.place("skyscraper-1", SKY_A + Vector2(1, 1)).is_empty())
	assert_false(d.place("skyscraper-3", SKY_B + Vector2(1, 1)).is_empty())
	assert_false(d.place("rooftop-3", ROOF + Vector2(1, 1), "", false, Vector2(16, 16)).is_empty())
	assert_false(d.place("short-0", SHORT + Vector2(1, 1)).is_empty())
	assert_false(d.place("building-small", SMALL + Vector2(1, 1)).is_empty())
	e._rebuild_map()


## The ground point (units) under a screen point (map pixels), as the editor's mouse gives it.
func _units_of(screen: Vector2) -> Vector2:
	return ISO.affine_inverse() * screen / 16.0


## A point on a wall of the skyscraper at `corner` (12 x 12), `up` units above the ground, as the mouse.
func _on_wall(corner: Vector2, wall: String, up: float) -> Vector2:
	var g := corner + (Vector2(6, 12) if wall == "south" else Vector2(12, 6))
	return _units_of(ISO * (g * 16.0) - Vector2(0, up * 16.0))


func _pick(e: LevelCreatorEditor, asset: String, view: String = "", mirror: bool = false, height: String = "") -> void:
	e.panel.pick(asset)
	for i in 4:
		if view == "" or e.pick_view == view:
			break
		e.rotate_pick()
	if mirror != e.pick_mirror:
		e.mirror_pick()
	for i in 6:
		if height == "" or str(e.panel.member.get("height", "")) == height:
			break
		e.height_pick()


func _skyscraper_at(doc: LevelDocument, corner: Vector2) -> Dictionary:
	for b in doc.data.buildings:
		if Vector2(float(b.x), float(b.y)) == corner:
			return b
	return {}


func _count_collision(n: Node) -> int:
	var c := 1 if (n is CollisionObject2D or n is CollisionShape2D or n is CollisionPolygon2D) else 0
	for k in n.get_children():
		c += _count_collision(k)
	return c


func _run_on(path: String) -> Node2D:
	var run: Node2D = RunScene.instantiate()
	run.layout_path = path
	add_child_autofree(run)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	return run


func _check_level(path: String) -> Array:
	var output: Array = []
	var code := OS.execute("python", [ProjectSettings.globalize_path("res://tools/check_level.py"),
		ProjectSettings.globalize_path(path)], output, true)
	return [code, "\n".join(output)]


## The fixture: signs on the street (head), the rooftop (body, mirrored) and the short building (head), and
## banners on skyscraper A's south wall (head, at 3) and skyscraper B's east wall (body, at 9).
func _place_all(e: LevelCreatorEditor) -> Dictionary:
	_with_buildings(e)
	var out := {}
	_pick(e, "alert-sign-head")
	out.street = e.place_asset("alert-sign-head", SIGN_STREET)
	_pick(e, "alert-sign-body", "", true)
	out.roof = e.place_asset("alert-sign-body", SIGN_ROOF)
	_pick(e, "alert-sign-head")
	out.short = e.place_asset("alert-sign-head", SIGN_SHORT)
	_pick(e, "alert-banner-head", "south", false, "3")
	out.banner_a = e.place_asset("alert-banner-head", _on_wall(SKY_A, "south", 5.0))
	_pick(e, "alert-banner-body", "east", false, "9")
	out.banner_b = e.place_asset("alert-banner-body", _on_wall(SKY_B, "east", 10.0))
	e.panel.pick("")
	for k in out:
		assert_false(out[k].is_empty(), "%s is placed" % k)
	return out


# ---- The panel ------------------------------------------------------------------------------------

func test_both_pieces_are_in_the_side_panel_with_the_text_tickets_labels() -> void:
	var e := _editor()
	var deco: Array = e.panel.entries_by_category()[CreatorTexts.get_text("group_decoration")]
	assert_true("alert-sign" in deco and "alert-banner" in deco, str(deco))
	assert_eq(e.panel.buttons["alert-sign"].text, CreatorTexts.get_text("piece_alert_sign"))
	assert_eq(e.panel.buttons["alert-banner"].text, CreatorTexts.get_text("piece_alert_banner"))
	assert_eq(CreatorTexts.get_text("piece_alert_sign"), "Alert sign")
	assert_eq(CreatorTexts.get_text("piece_alert_banner"), "Alert banner")


func test_the_two_designs_are_chosen_in_the_strip_with_their_names() -> void:
	var e := _editor()
	for fid in ["alert-sign", "alert-banner"]:
		e.panel.pick(fid)
		assert_true(e.panel.looks_strip.visible, fid)
		assert_eq(e.panel.look_buttons.size(), 2, "%s: two designs" % fid)
		assert_eq(e.panel.look_buttons[0].tooltip_text, CreatorTexts.get_text("alert_design_head"))
		assert_eq(e.panel.look_buttons[1].tooltip_text, CreatorTexts.get_text("alert_design_body"))
		assert_true(e.panel.look_notes.text.begins_with(CreatorTexts.get_text("alert_design_head")), e.panel.look_notes.text)
		assert_true(KaijuSigns.design_of_asset(e.panel.picked) == "head", e.panel.picked)
		# Clicking the second look picks the body design; V steps back to the head.
		e.panel.look_buttons[1].pressed.emit()
		assert_eq(KaijuSigns.design_of_asset(e.panel.picked), "body", fid)
		assert_true(e.panel.look_notes.text.begins_with(CreatorTexts.get_text("alert_design_body")))
		e.look_pick()
		assert_eq(KaijuSigns.design_of_asset(e.panel.picked), "head", fid)
	# The banner's strip shows its wall and height keys.
	e.panel.pick("alert-banner")
	assert_true(CreatorTexts.get_text("banner_wall_hint") in e.panel.look_notes.text)
	assert_true(CreatorTexts.get_text("banner_height_hint") in e.panel.look_notes.text)
	e.panel.pick("alert-sign")
	assert_false(CreatorTexts.get_text("banner_wall_hint") in e.panel.look_notes.text)


func test_r_turns_the_banners_wall_h_its_height_and_m_mirrors_the_sign() -> void:
	var e := _editor()
	e.panel.pick("alert-banner")
	assert_eq(e.pick_view, "south")
	assert_eq(e.alert_height(), 3.0)
	assert_eq(e.rotate_pick(), "east")
	assert_eq(e.rotate_pick(), "south")
	var heights: Array = []
	for i in 5:
		heights.append(e.alert_height())
		e.height_pick()
	assert_eq(heights, [3.0, 6.0, 9.0, 12.0, 15.0])
	assert_eq(e.alert_height(), 3.0, "back to the first")
	e.panel.pick("alert-sign")
	assert_false(e.pick_mirror)
	assert_true(e.mirror_pick())
	assert_eq(e.alert_height(), -1.0, "a sign has no height of its own")


# ---- Placing ------------------------------------------------------------------------------------

func test_signs_and_banners_are_placed_with_their_design_wall_height_and_position() -> void:
	var e := _editor()
	var p := _place_all(e)
	var street: Dictionary = p.street.item
	assert_eq(street.asset, "alert-sign-head")
	assert_eq(KaijuSigns.sign_ground_point(street), Vector2(41, -21), "the post on the cell's middle")
	assert_eq(bool(p.roof.item.mirror), true)
	var a: Dictionary = p.banner_a.item
	assert_eq(a.asset, "alert-banner-head")
	assert_eq(a.building, [SKY_A.x, SKY_A.y])
	assert_eq(a.wall, "south")
	assert_eq(float(a.bottom_units), 3.0)
	assert_eq(float(a.along), 4.5, "centred on the mouse along the wall")
	var b: Dictionary = p.banner_b.item
	assert_eq([b.asset, b.wall, float(b.bottom_units), float(b.along)], ["alert-banner-body", "east", 9.0, 4.5])
	assert_eq(e.document.data.alert_signs.size(), 5)
	# The editor draws them as the run will: banners on their skyscrapers, signs at their heights.
	assert_eq(e.map.alert_signs.size(), 5)


func test_a_banner_cant_be_placed_on_a_platform_a_short_or_small_building_or_the_street() -> void:
	var e := _editor()
	_with_buildings(e)
	_pick(e, "alert-banner-head")
	var roof_wall := _units_of(ISO * ((ROOF + Vector2(8, 16)) * 16.0) - Vector2(0, 16))
	assert_true(e.place_asset("alert-banner-head", roof_wall).is_empty(), "not on a platform")
	assert_true(e.place_asset("alert-banner-head", SHORT + Vector2(6, 11.5)).is_empty(), "not on a short building")
	assert_true(e.place_asset("alert-banner-head", _units_of(ISO * ((SHORT + Vector2(6, 12)) * 16.0) - Vector2(0, 32))).is_empty())
	assert_true(e.place_asset("alert-banner-head", SMALL + Vector2(3, 3)).is_empty(), "not on a small building")
	assert_true(e.place_asset("alert-banner-head", Vector2(100, 100)).is_empty(), "not on the street")
	assert_false(e.document.data.has("alert_signs") and not e.document.data.alert_signs.is_empty())
	# Nor through the document directly.
	var short_entry: Dictionary = {}
	for b in e.document.data.buildings:
		if str(b.asset) == "short-0":
			short_entry = b
	assert_true(e.document.place_banner("alert-banner-head", short_entry, "south", 4.5, 3.0).is_empty())
	assert_true(e.document.place_banner("alert-banner-head", {"x": ROOF.x, "y": ROOF.y, "w": 16, "h": 16, "height": 3}, "south", 0, 3).is_empty())


func test_a_sign_is_not_placed_inside_a_skyscraper_or_off_the_map() -> void:
	var e := _editor()
	_with_buildings(e)
	_pick(e, "alert-sign-head")
	assert_true(e.place_asset("alert-sign-head", SKY_A + Vector2(5, 5)).is_empty())
	assert_eq(e.message_label.text, CreatorTexts.get_text("overlap_message"))
	assert_true(e.document.place_alert("alert-sign-head", Vector2(500, 0)).is_empty())


func test_the_banner_stays_on_its_wall() -> void:
	var e := _editor()
	_with_buildings(e)
	_pick(e, "alert-banner-head", "south")
	var far_left := _units_of(ISO * ((SKY_A + Vector2(0.2, 12)) * 16.0) - Vector2(0, 80))
	var p := e.place_asset("alert-banner-head", far_left)
	assert_false(p.is_empty())
	assert_eq(float(p.item.along), 0.0)
	_pick(e, "alert-banner-head", "east")
	var far_back := _units_of(ISO * ((SKY_A + Vector2(12, 0.2)) * 16.0) - Vector2(0, 80))
	var q := e.place_asset("alert-banner-head", far_back)
	assert_eq(float(q.item.along), 9.0, "the banner ends at the wall's back corner")


func test_signs_and_banners_are_selected_by_their_picture_and_deleted() -> void:
	var e := _editor()
	var p := _place_all(e)
	var a: Dictionary = p.banner_a.item
	var sel := e.select_at(_on_wall(SKY_A, "south", 4.5))
	assert_eq(str(sel.get("kind", "")), "alert")
	assert_true(is_same(sel.item, a), "the banner, not its skyscraper")
	e.delete_selected()
	assert_eq(e.document.data.alert_signs.size(), 4)
	assert_eq(e.map.alert_signs.size(), 4)
	# A standing sign: a click on its picture (a unit above its foot).
	var g := KaijuSigns.sign_ground_point(p.street.item)
	sel = e.select_at(_units_of(ISO * (g * 16.0) - Vector2(0, 24)))
	assert_true(is_same(sel.get("item"), p.street.item))
	e.delete_selected()
	assert_eq(e.document.data.alert_signs.size(), 3)
	# Deleting a skyscraper takes its banner with it.
	assert_true(e.delete_piece({"kind": "building", "item": _skyscraper_at(e.document, SKY_B)}))
	assert_eq(e.document.data.alert_signs.size(), 2)
	assert_false(e.document.data.alert_signs.any(func(it): return KaijuSigns.kind_of(it) == "banner"))
	# Placed again elsewhere: "moving" a piece is deleting it and placing it again, as for any piece.
	_pick(e, "alert-sign-head")
	assert_false(e.place_asset("alert-sign-head", Vector2(80.5, 80.5)).is_empty())
	assert_eq(e.document.data.alert_signs.size(), 3)


func test_the_preview_shows_the_picture_where_it_will_be_drawn() -> void:
	var e := _editor()
	_with_buildings(e)
	_pick(e, "alert-banner-body", "east", false, "6")
	e.hover_units = _on_wall(SKY_A, "east", 7.0)
	e.hover_cell = e.document.cell_at(e.hover_units)
	var pv := e.alert_preview()
	assert_false(pv.is_empty())
	assert_true(pv.flip, "the east wall's banner is flipped")
	var placed := e.place_asset("alert-banner-body", e.hover_units)
	var tex := KaijuSigns.texture_of(placed.item)
	var foot := Rect2(SKY_A, Vector2(12, 12))
	assert_eq(pv.rect.position, KaijuSigns.banner_sprite_position(foot, "east", float(placed.item.along), 6.0, tex))
	e.hover_units = Vector2(100, 100)
	e.hover_cell = e.document.cell_at(e.hover_units)
	assert_true(e.alert_preview().is_empty(), "no skyscraper under the mouse: no banner preview")


# ---- Saved, reopened, played ---------------------------------------------------------------------

func test_saved_reopened_and_drawn_in_a_run_at_their_heights_and_walls() -> void:
	var e := _editor()
	var p := _place_all(e)
	e.name_field.text = "T-441 alert signs"
	assert_eq(e.save(), OK)
	var path := e.level_path
	var saved := LevelStore.load_level(path)
	assert_eq(saved.alert_signs.size(), 5)
	var res := _check_level(path)
	assert_eq(res[0], 0, res[1])
	# Reopened: the same signs, with their design and position, drawn again.
	var e2: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e2.levels_dir = e.levels_dir
	e2.open_level(path)
	add_child_autofree(e2)
	assert_eq(e2.level_data.alert_signs, saved.alert_signs)
	assert_eq(e2.document.placed_pieces().filter(func(q): return q.kind == "alert").size(), 5)
	var designs := {}
	for it in e2.level_data.alert_signs:
		designs[str(it.asset)] = true
	assert_eq(designs.size(), 4, "both designs of both pieces")
	assert_eq(e2.map.alert_signs.size(), 5)
	# The run draws them where the editor shows them.
	var run := _run_on(path)
	var editor_at := {}
	for sp in e2.map.alert_signs:
		editor_at[str(sp.name)] = [sp.position, sp.flip_h, str(sp.get_parent().name)]
	assert_eq(run.map.alert_signs.size(), 5)
	for sp in run.map.alert_signs:
		assert_eq([sp.position, sp.flip_h, str(sp.get_parent().name)], editor_at[str(sp.name)], str(sp.name))
	# Standing signs at the height of what they stand on: the street 0, the rooftop 3, the short building 3.
	var want := {str(p.street.item.id): 0.0, str(p.roof.item.id): 3.0, str(p.short.item.id): 3.0}
	for sp in run.map.alert_signs:
		if sp.get_meta("alert_kind") != "sign":
			continue
		var g: Vector2 = sp.get_meta("ground")
		var h: float = want[str(sp.name)]
		assert_almost_eq(float(sp.get_meta("ground_height")), h, 0.001, str(sp.name))
		var tex: Texture2D = sp.texture
		assert_eq(sp.position, ISO * (g * 16.0) - Vector2(tex.get_width() * 0.5, tex.get_height()) * 0.5 - Vector2(0, h * 16.0), str(sp.name))
		assert_eq(sp.get_parent(), run.map.alert_signs_root)
		assert_true(sp in run.map.depth_sprites(), "in the depth order like a prop")
	assert_true(run.map.alert_signs.filter(func(s): return s.get_meta("alert_kind") == "sign" and s.flip_h).size() == 1, "the mirrored one")


func test_a_banner_is_drawn_as_a_child_of_its_skyscrapers_art_on_its_wall_and_fades_with_it() -> void:
	var e := _editor()
	var p := _place_all(e)
	var path := RunPaths.file("t441_banner_run.json")
	assert_eq(LevelStore.save_level(path, e.document.file_data("T-441 banner")), OK)
	var run := _run_on(path)
	var found := 0
	for sp in run.map.alert_signs:
		if sp.get_meta("alert_kind") != "banner":
			continue
		found += 1
		var it: Dictionary = p.banner_a.item if str(sp.name) == str(p.banner_a.item.id) else p.banner_b.item
		var corner := SKY_A if it == p.banner_a.item else SKY_B
		var slot: Node2D = sp.get_parent().get_parent()
		assert_true(slot in run.map.slots, "a child of a skyscraper's art")
		assert_eq(sp.get_parent(), slot.towers)
		assert_eq(slot.footprint, Rect2(corner, Vector2(12, 12)), "its own skyscraper")
		var tex: Texture2D = sp.texture
		assert_eq(sp.position, KaijuSigns.banner_sprite_position(slot.footprint, str(it.wall), float(it.along), float(it.bottom_units), tex))
		assert_eq(sp.flip_h, str(it.wall) == "east")
		assert_eq(tex.resource_path if tex.resource_path != "" else KaijuSigns.texture_path(KaijuSigns.design_of(it), "banner"),
			KaijuSigns.texture_path(KaijuSigns.design_of(it), "banner"))
		assert_eq(sp.z_index, 0, "the skyscraper's depth")
	assert_eq(found, 2)
	# The car behind skyscraper A: it fades, and the banner with it (its child).
	var slot_a: Node2D = null
	for s in run.map.slots:
		if s.footprint.position == SKY_A:
			slot_a = s
	run.map.update_see_through(SKY_A + Vector2(6, -3), NOSE_UP, 1.0)
	assert_true(slot_a in run.map.covering_buildings())
	assert_almost_eq(slot_a.alpha(), 0.15, 0.001)
	var on_a: Array = run.map.alert_signs.filter(func(s): return s.get_parent().get_parent() == slot_a)
	assert_eq(on_a.size(), 1)


func test_signs_and_banners_have_no_collisions() -> void:
	var e := _editor()
	_place_all(e)
	var with_signs: Dictionary = e.document.map_layout()
	var without: Dictionary = with_signs.duplicate(true)
	without.erase("alert_signs")
	var m1: Node2D = MapScene.instantiate()
	m1.layout = with_signs
	add_child_autofree(m1)
	var m2: Node2D = MapScene.instantiate()
	m2.layout = without
	add_child_autofree(m2)
	assert_eq(m1.alert_signs.size(), 5)
	assert_eq(m2.alert_signs.size(), 0)
	assert_eq(_count_collision(m1), _count_collision(m2), "the same collision objects as without them")
	for s in m1.alert_signs:
		assert_eq(s.get_child_count(), 0)
		assert_false(s is CollisionObject2D)


# ---- The retired list ------------------------------------------------------------------------------

func test_the_fixed_list_is_retired_a_level_without_signs_draws_none() -> void:
	assert_false(FileAccess.file_exists("res://data/level/kaiju_signs.json"), "the list is gone")
	assert_false(KaijuSigns.new().has_method("load_data"), "no code reads it")
	var e := _editor()
	_with_buildings(e)
	var path := RunPaths.file("t441_no_signs.json")
	assert_eq(LevelStore.save_level(path, e.document.file_data("T-441 none")), OK)
	var run := _run_on(path)
	assert_eq(run.map.alert_signs.size(), 0)
	assert_null(run.map.alert_signs_root)
	assert_eq(e.map.alert_signs.size(), 0, "nor the editor")
	# The old MVP map (the T-130 blocks) has none either.
	var m: Node2D = MapScene.instantiate()
	add_child_autofree(m)
	assert_eq(m.alert_signs.size(), 0)
	# The game's map, Kaiju City, has none until the board places them.
	var city := LevelStore.load_level("res://data/level/kaiju_city_map.json")
	assert_false(city.has("alert_signs") and not city.alert_signs.is_empty())
