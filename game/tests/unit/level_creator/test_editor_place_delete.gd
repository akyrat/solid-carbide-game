extends GutTest
## Task T-235: the level creator's editor draws the level with the run's own scripts (mvp_map.gd and
## elevation_layer.gd), its side panel lists the whole catalogue by kind, and pieces of every kind
## can be placed and deleted, in the level data and in the drawing.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const MvpMapScript := preload("res://scripts/level/mvp_map.gd")
const ElevationLayerScript := preload("res://scripts/level/elevation_layer.gd")
const BuildingTowers := preload("res://scripts/level/building_towers.gd")

const KIND_KEYS := {
	"ground": "category_ground", "road": "category_roads", "building": "category_buildings",
	"boulder": "category_boulders", "rooftop": "category_rooftops", "ramp": "category_ramps", "prop": "category_props",
}


func _editor() -> LevelCreatorEditor:
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.open_new()
	add_child_autofree(e)
	return e


func _first_of(kind: String) -> String:
	for e in LevelDocument.entries():
		if str(e.kind) == kind:
			return str(e.id)
	return ""


# ---- The run's scripts draw the level -------------------------------------------------------------

func test_the_editor_draws_with_mvp_map_and_the_elevation_layer() -> void:
	var e := _editor()
	assert_not_null(e.map)
	assert_eq(e.map.get_script(), MvpMapScript, "the map is mvp_map.gd itself")
	assert_not_null(e.elevation)
	assert_eq(e.elevation.get_script(), ElevationLayerScript, "the elevation is elevation_layer.gd itself")
	assert_eq(e.map.elevation, e.elevation)
	assert_eq(e.map.view, "iso")
	assert_true(e.map.uses_ground_art(), "the ground is drawn with the ground tiles")


func test_a_new_level_is_an_empty_map_of_todays_size_all_plain_ground() -> void:
	var e := _editor()
	var sample := LevelStore.load_level("res://data/level/elevation_sample_map.json")
	assert_eq(e.document.map_rect(), Rect2(float(sample.map.rect.x), float(sample.map.rect.y),
		float(sample.map.rect.w), float(sample.map.rect.h)))
	assert_eq(e.level_data.buildings, [])
	assert_eq(e.level_data.pattern_copies, [])
	assert_eq(e.level_data.platforms, [])
	assert_eq(e.level_data.ramps, [])
	assert_eq(e.level_data.ground.tiles, [LevelDocument.BASE_GROUND])
	assert_eq(e.level_data.ground_rows.size(), 240)
	assert_eq(e.level_data.ground_rows[0], "G".repeat(240))
	assert_eq(e.level_data.name, CreatorTexts.get_text("default_level_name"))


# ---- The side panel -----------------------------------------------------------------------------

func test_the_panel_lists_one_button_per_family_in_six_groups() -> void:
	# T-262: the groups of the catalogue's families, from the ground up, one button per family.
	var e := _editor()
	var expected := {}
	var order: Array = []
	for g in ["roads", "ground", "levels", "buildings", "obstacles", "decoration"]:
		var label := CreatorTexts.get_text("group_" + g)
		assert_ne(label, "")
		expected[label] = []
		order.append(label)
		for f in CreatorFamilies.in_group(g):
			expected[label].append(str(f.id))
	var shown := e.panel.entries_by_category()
	assert_eq(shown, expected)
	assert_eq(shown.keys(), order, "groups in the panel's order")
	assert_eq(e.panel.buttons.size(), CreatorFamilies.families().size())
	for id in e.panel.buttons:
		assert_not_null(e.panel.buttons[id].icon, id + " shows its art")


func test_the_platform_and_ramp_heights_show_on_the_top_bar() -> void:
	# T-262: one Platform and one Ramp button; H steps the height, the top bar names it.
	var e := _editor()
	e.panel.pick("platform")
	assert_eq(e.height_label.text, CreatorTexts.get_text("rooftop_height_3"))
	e.height_pick()
	assert_eq(e.panel.picked, "rooftop-6")
	assert_eq(e.height_label.text, CreatorTexts.get_text("rooftop_height_6"))
	e.panel.pick("ramp")
	assert_eq(e.height_label.text, CreatorTexts.get_text("ramp_height_0_3"))
	e.height_pick()
	assert_eq(e.height_label.text, CreatorTexts.get_text("ramp_height_3_6"))
	e.height_pick()
	assert_eq(e.height_label.text, CreatorTexts.get_text("ramp_height_0_6"))


func test_the_editor_labels_come_from_the_texts() -> void:
	var e := _editor()
	assert_eq(e.delete_button.text, CreatorTexts.get_text("delete_label"))
	assert_eq(e.back_button.text, CreatorTexts.get_text("back_button"))
	# T-262: the reworked creator's hint (T-261's line) replaces T-251's.
	assert_eq(e.hint_label.text, CreatorTexts.get_text("controls_hint_rework"))


func test_picking_in_the_panel_and_clicking_places() -> void:
	var e := _editor()
	e.panel.pick("boulder-b")
	assert_eq(e.panel.picked, "boulder-b")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = e.units_to_screen(Vector2(10.5, -7.0))
	e._on_map_input(click)
	assert_eq(e.level_data.pattern_copies.size(), 1)
	var b: Dictionary = e.level_data.pattern_copies[0].boulders[0]
	assert_almost_eq(Vector2(b.x, b.y), Vector2(11.5, -6.5), Vector2(0.001, 0.001), "on the clicked tile")
	assert_eq(b.variant, "b")


# ---- Placing and deleting one of each kind ------------------------------------------------------

func test_place_one_of_each_kind_then_delete_them() -> void:
	var e := _editor()
	var ground := _first_of("ground")
	var road := "road-x_zebra_g4"
	# Ground tile: a gravel other than the plain one, so the change shows.
	ground = "ground-gravel2"
	var g := e.place_asset(ground, Vector2(-30.5, -30.5))
	var r := e.place_asset(road, Vector2(-20.0, -30.0))
	var bld := e.place_asset("skyscraper-3", Vector2(40.0, 40.0))
	var bo := e.place_asset("boulder-a", Vector2(-50.0, 20.0))
	var roof := e.place_asset("rooftop-3", Vector2(-100.0, -100.0), Vector2(84, 30))
	var ramp := e.place_asset("ramp-0-3", Vector2(-90.0, -70.0))
	for p in [g, r, bld, bo, roof, ramp]:
		assert_false(p.is_empty())

	# The data holds each.
	var gd: Dictionary = e.level_data.ground
	assert_eq(gd.tiles[gd.cells[g.cell.y][g.cell.x]], ground)
	assert_eq(gd.tiles[gd.cells[r.cell.y][r.cell.x]], road)
	assert_eq(g.cell, Vector2i(44, 44))
	assert_eq(e.level_data.ground_rows[-30 + 120][-20 + 120], "R", "ground_rows marks the road")
	assert_eq(e.level_data.buildings.size(), 1)
	assert_eq(e.level_data.buildings[0], {"x": 40.0, "y": 40.0, "w": 12.0, "h": 12.0, "asset": "skyscraper-3", "look": 0, "banner": false})
	assert_eq(e.level_data.ground_rows[45 + 120][45 + 120], "B", "ground_rows marks the building")
	assert_eq(e.level_data.pattern_copies.size(), 1)
	assert_eq(e.level_data.platforms.size(), 1)
	assert_eq(e.level_data.platforms[0].height, 3)
	assert_eq(Rect2(e.level_data.platforms[0].x, e.level_data.platforms[0].y, e.level_data.platforms[0].w,
		e.level_data.platforms[0].h), Rect2(-100, -100, 84, 30))
	assert_eq(e.level_data.ramps.size(), 1)
	assert_eq(e.level_data.ramps[0].bottom_height, 0)
	assert_eq(e.level_data.ramps[0].top_height, 3)

	# The drawing holds each.
	var layout: Dictionary = e.map.ground_layout
	assert_eq(layout.cells[g.cell.y][g.cell.x], int(LevelDocument.entry(ground).atlas_index))
	assert_eq(layout.cells[r.cell.y][r.cell.x], int(LevelDocument.entry(road).atlas_index))
	assert_eq(e.map.buildings.size(), 1)
	assert_eq(e.map.slots.size(), 1, "one tower, the one placed")
	assert_eq(e.map.slots[0].footprint, Rect2(40, 40, 12, 12))
	assert_eq(e.map.slots[0].towers.get_node("Sprite").texture.resource_path, "res://art/buildings/nobanner/skyscraper_3_0.png")  # T-265: banner off by default
	assert_eq(e.map.all_boulders().size(), 1)
	assert_eq(e.map.boulder_sprites.size(), 1)
	assert_eq(e.map.boulder_sprites[0].variant, "a")
	assert_eq(e.elevation.areas.size(), 2)
	assert_eq(e.elevation.ground_height.height_at(Vector2(-60, -90)), 3.0, "the rooftop raises the ground")

	# Delete each: gone from the data and the drawing.
	assert_true(e.delete_piece(e.document.piece_at(Vector2(46, 46))))
	assert_eq(e.level_data.buildings.size(), 0)
	assert_eq(e.map.buildings.size(), 0)
	assert_eq(e.map.slots.size(), 0)
	assert_eq(e.level_data.ground_rows[45 + 120][45 + 120], "G")

	assert_true(e.delete_piece(e.document.piece_at(Vector2(-48.5, 21.5))))
	assert_eq(e.level_data.pattern_copies.size(), 0)
	assert_eq(e.map.all_boulders().size(), 0)
	assert_eq(e.map.boulder_sprites.size(), 0)

	var on_ramp := e.document.piece_at(Vector2(-85, -65))
	assert_eq(on_ramp.kind, "ramp")
	assert_true(e.delete_piece(on_ramp))
	assert_eq(e.level_data.ramps.size(), 0)
	assert_eq(e.elevation.areas.size(), 1)

	var on_roof := e.document.piece_at(Vector2(-60, -90))
	assert_eq(on_roof.kind, "rooftop")
	assert_true(e.delete_piece(on_roof))
	assert_eq(e.level_data.platforms.size(), 0)
	assert_eq(e.elevation.areas.size(), 0)
	assert_eq(e.elevation.ground_height.height_at(Vector2(-60, -90)), 0.0)

	var on_road := e.document.piece_at(Vector2(-19.0, -29.0))
	assert_eq(on_road.kind, "road")
	assert_true(e.delete_piece(on_road))
	gd = e.level_data.ground
	assert_eq(gd.tiles[gd.cells[r.cell.y][r.cell.x]], LevelDocument.BASE_GROUND)
	assert_eq(e.map.ground_layout.cells[r.cell.y][r.cell.x], int(LevelDocument.entry(LevelDocument.BASE_GROUND).atlas_index))
	assert_eq(e.level_data.ground_rows[-30 + 120][-20 + 120], "G")

	assert_true(e.delete_piece(e.document.piece_at(Vector2(-30.5, -30.5))))
	gd = e.level_data.ground
	assert_eq(gd.tiles[gd.cells[g.cell.y][g.cell.x]], LevelDocument.BASE_GROUND)
	assert_false(e.delete_piece(e.document.piece_at(Vector2(-30.5, -30.5))), "plain ground has nothing to delete")


func test_select_then_delete_button_removes_the_selected_piece() -> void:
	var e := _editor()
	e.place_asset("short-1", Vector2(0, 0))
	e.place_asset("boulder-a", Vector2(30, 30))
	e.select_at(Vector2(5, 5))
	assert_eq(e.selected.kind, "building")
	e.delete_button.pressed.emit()
	assert_eq(e.level_data.buildings.size(), 0)
	assert_eq(e.level_data.pattern_copies.size(), 1, "the other piece stays")
	assert_true(e.selected.is_empty())


func test_the_road_tile_outside_the_atlas_is_drawn_as_an_extra() -> void:
	var e := _editor()
	var p := e.place_asset("road-road_tile", Vector2(2, 2))
	var v: int = e.map.ground_layout.cells[p.cell.y][p.cell.x]
	assert_gte(v, LevelDocument.EXTRA_BASE)
	assert_eq(e.map.ground_layout.extra[v - LevelDocument.EXTRA_BASE], "res://art/ground/road_tile.png")


func test_ids_stay_unique_after_a_delete() -> void:
	var doc := LevelDocument.new(LevelDocument.new_level_data("x"))
	var a := doc.place("rooftop-6", Vector2(0, 0))
	var b := doc.place("rooftop-6", Vector2(40, 0))
	assert_eq([a.item.id, b.item.id], ["roof-1", "roof-2"])
	doc.delete(a)
	var c := doc.place("rooftop-6", Vector2(80, 0))
	assert_eq(c.item.id, "roof-1")
	assert_ne(c.item.id, b.item.id)


func test_outside_the_map_places_nothing() -> void:
	var doc := LevelDocument.new(LevelDocument.new_level_data("x"))
	assert_eq(doc.place("boulder-a", Vector2(500, 0)), {})
	assert_eq(doc.place("no-such-asset", Vector2(0, 0)), {})
	assert_eq(doc.data.pattern_copies, [])


# ---- An opened level ----------------------------------------------------------------------------

func test_opening_the_sample_map_draws_it_and_leaves_its_data_alone() -> void:
	var path := "res://data/level/elevation_sample_map.json"
	var original := LevelStore.load_level(path)
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.open_level(path)
	add_child_autofree(e)
	assert_eq(e.level_data, original, "opening changes nothing")
	assert_eq(e.map.buildings.size(), original.buildings.size())
	assert_eq(e.elevation.areas.size(), original.platforms.size() + original.ramps.size())
	# The game's own ground tiles.
	var game_ground := LevelDocument.game_ground()
	assert_eq(e.map.ground_layout.cells[10][10], int(game_ground.cells[10][10]))


func test_single_of_names_the_tower() -> void:
	assert_eq(BuildingTowers.single_of({"asset": "skyscraper-1"}), {"short": false, "index": 0, "banner": false})
	assert_eq(BuildingTowers.single_of({"asset": "skyscraper-6", "look": 1}), {"short": false, "index": 11, "banner": false})
	assert_eq(BuildingTowers.single_of({"asset": "short-2", "look": 1}), {"short": true, "index": 5})
	assert_eq(BuildingTowers.single_of({}), {})
	assert_eq(BuildingTowers.single_of({"asset": "skyscraper-9"}), {})


# ---- Camera -------------------------------------------------------------------------------------

func test_pan_and_zoom_move_the_view() -> void:
	var e := _editor()
	await get_tree().process_frame
	var at := Vector2(200, 150)
	var before := e.screen_to_units(at)
	e.zoom_by(2.0, at)
	assert_almost_eq(e.zoom, LevelCreatorEditor.START_ZOOM * 2.0, 0.0001)
	assert_almost_eq(e.screen_to_units(at), before, Vector2(0.01, 0.01), "the point under the mouse stays")
	var p := e.units_to_screen(Vector2(10, 10))
	e.pan_by(Vector2(40, 0))
	assert_almost_eq(e.units_to_screen(Vector2(10, 10)), p + Vector2(40, 0), Vector2(0.001, 0.001), "the map follows the drag")
	e.zoom_by(1000.0, at)
	assert_eq(e.zoom, LevelCreatorEditor.MAX_ZOOM)
