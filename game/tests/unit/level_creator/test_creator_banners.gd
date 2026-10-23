extends GutTest
## Task T-265: in the level creator a skyscraper's banner (the vertical sign painted into the body art)
## is on or off per building: off by default, key B (or the top bar's Banner on / Banner off) turns it,
## it is saved with the building, reopened and drawn in a run. The game's own map keeps its banners.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const MapScene := preload("res://scenes/level/mvp_map.tscn")
const BuildingTowers := preload("res://scripts/level/building_towers.gd")
const PLAIN_DIR := "res://art/buildings/nobanner/"
const ART_DIR := "res://art/buildings/"

var dir: String


func before_each() -> void:
	dir = RunPaths.file("t265_levels_" + str(randi()))


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
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.pressed = true
	e._unhandled_key_input(ev)


## The picture as bytes, comparable with another's: RGBA8, colour premultiplied (an imported texture may keep
## other colours under alpha 0).
func _bytes_of(img: Image) -> PackedByteArray:
	var c: Image = img.duplicate()
	c.decompress() if c.is_compressed() else null
	c.convert(Image.FORMAT_RGBA8)
	c.premultiply_alpha()
	return c.get_data()


func _image_of(tex: Texture2D) -> Image:
	return tex.get_image()


func _file_image(path: String) -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(path))


## True when the sprite of `slot` shows the picture in `path`.
func _shows(slot, path: String) -> bool:
	var sp: Sprite2D = slot.towers.get_node("Sprite")
	return _bytes_of(_image_of(sp.texture)) == _bytes_of(_file_image(path))


func _skyscraper_slots(map) -> Array:
	return map.slots.duplicate()


# ---- The art -------------------------------------------------------------------------------------

func test_the_twelve_plain_bodies_exist_and_differ_from_the_signed_ones_only_in_the_sign() -> void:
	for n in range(1, 7):
		for k in 2:
			var name := "skyscraper_%d_%d.png" % [n, k]
			var signed := _file_image(ART_DIR + name)
			var plain := _file_image(PLAIN_DIR + name)
			assert_not_null(plain, name + " has a copy without the banner")
			assert_eq(plain.get_size(), signed.get_size(), name + " same size")
			var changed := 0
			var outside := 0
			for y in signed.get_height():
				for x in signed.get_width():
					if signed.get_pixel(x, y) != plain.get_pixel(x, y):
						changed += 1
						# the sign stands on one wall, left of the corner at the most
						if x < 100 or x > 700:
							outside += 1
			assert_gt(changed, 500, name + ": the banner's pixels are gone")
			assert_eq(outside, 0, name + ": nothing changed away from the banner")


func test_nobanner_path_maps_only_skyscraper_bodies() -> void:
	assert_eq(BuildingTowers.nobanner_path("res://art/buildings/skyscraper_3_1.png"), PLAIN_DIR + "skyscraper_3_1.png")
	assert_eq(BuildingTowers.nobanner_path("res://art/buildings/short_body_1.png"), "")


# ---- Placing, B, saving ----------------------------------------------------------------------------

func test_a_skyscraper_places_with_no_banner_by_default() -> void:
	var e := _editor()
	assert_false(e.pick_banner)
	e.panel.pick("skyscraper-1")
	var piece: Dictionary = e.place_asset("skyscraper-1", Vector2(0.0, 0.0))
	assert_false(piece.is_empty())
	assert_eq(piece.item.get("banner"), false, "written as an explicit off")
	var slots: Array = _skyscraper_slots(e.map)
	assert_eq(slots.size(), 1)
	assert_true(_shows(slots[0], PLAIN_DIR + "skyscraper_1_0.png"), "drawn without the banner")


func test_b_turns_the_next_skyscrapers_banner_on_and_off_and_the_buttons_follow() -> void:
	var e := _editor()
	assert_false(e.banner_buttons.on.visible, "nothing to apply it to yet")
	e.panel.pick("skyscraper-2")
	assert_true(e.banner_buttons.on.visible)
	assert_true(e.banner_buttons.off.button_pressed)
	_key(e, KEY_B)
	assert_true(e.pick_banner)
	assert_true(e.banner_buttons.on.button_pressed)
	var on: Dictionary = e.place_asset("skyscraper-2", Vector2(-40.0, 0.0))
	assert_eq(on.item.banner, true)
	_key(e, KEY_B)
	assert_false(e.pick_banner)
	var off: Dictionary = e.place_asset("skyscraper-2", Vector2(40.0, 0.0))
	assert_eq(off.item.banner, false)
	var shown := {}
	for s in _skyscraper_slots(e.map):
		shown[_shows(s, ART_DIR + "skyscraper_2_0.png")] = true
	assert_eq(shown.size(), 2, "one drawn with its banner, one without")
	e.set_banner(true)  # the top bar's Banner on
	assert_true(e.pick_banner)
	e.set_banner(false)
	assert_false(e.pick_banner)


func test_b_does_nothing_for_other_pieces() -> void:
	var e := _editor()
	e.panel.pick("boulder-a")
	assert_false(e.banner_buttons.on.visible)
	assert_false(e.banner_pick())
	e.panel.pick("short-0")
	var piece: Dictionary = e.place_asset("short-0", Vector2(0.0, 0.0))
	if not piece.is_empty():
		assert_false(piece.item.has("banner"), "only skyscrapers carry the key")


func test_b_on_a_selected_skyscraper_turns_its_banner() -> void:
	var e := _editor()
	e.panel.pick("skyscraper-4")
	var piece: Dictionary = e.place_asset("skyscraper-4", Vector2(0.0, 0.0))
	e.panel.pick("")
	e.select_at(Vector2(6.0, 6.0))
	assert_false(e.selected.is_empty())
	assert_true(e.banner_buttons.off.visible, "the buttons show for a selected skyscraper")
	_key(e, KEY_B)
	var item: Dictionary = e.document.piece_at(Vector2(6.0, 6.0)).item
	assert_eq(item.banner, true)
	assert_true(_shows(_skyscraper_slots(e.map)[0], ART_DIR + "skyscraper_4_0.png"), "redrawn with the banner")
	_key(e, KEY_B)
	assert_eq(e.document.piece_at(Vector2(6.0, 6.0)).item.banner, false)
	assert_true(_shows(_skyscraper_slots(e.map)[0], PLAIN_DIR + "skyscraper_4_0.png"))
	assert_false(piece.is_empty())


func test_the_preview_shows_the_choice() -> void:
	var e := _editor()
	e.panel.pick("skyscraper-5")
	var off: Dictionary = e.preview_of(Vector2(0.0, 0.0))
	assert_eq(_bytes_of(_image_of(off.texture)), _bytes_of(_file_image(PLAIN_DIR + "skyscraper_5_0.png")), "off: no banner")
	_key(e, KEY_B)
	var on: Dictionary = e.preview_of(Vector2(0.0, 0.0))
	assert_eq(_bytes_of(_image_of(on.texture)), _bytes_of(_file_image(ART_DIR + "skyscraper_5_0.png")), "on: the banner")


func test_the_choice_is_saved_reopened_and_drawn_in_a_run() -> void:
	var e := _editor()
	e.panel.pick("skyscraper-3")
	_key(e, KEY_B)
	e.place_asset("skyscraper-3", Vector2(-40.0, 0.0))
	_key(e, KEY_B)
	e.place_asset("skyscraper-3", Vector2(40.0, 0.0))
	e.name_field.text = "Banner Test"
	assert_eq(e.save(), OK)
	var path := dir.path_join("banner_test.json")
	var saved: Dictionary = LevelStore.load_level(path)
	var banners: Array = saved.buildings.map(func(b): return b.banner)
	banners.sort()
	assert_eq(banners, [false, true], "saved with each building")
	var again := _editor(path)
	var flags := []
	for b in again.document.data.buildings:
		flags.append(LevelDocument.banner_of(b))
	flags.sort()
	assert_eq(flags, [false, true], "reopened")
	# The run builds the map from the same file.
	var map = MapScene.instantiate()
	map.layout_path = path
	map.alert_signs_enabled = false
	add_child_autofree(map)
	var with_banner := 0
	var without := 0
	for s in _skyscraper_slots(map):
		if _shows(s, ART_DIR + "skyscraper_3_0.png"):
			with_banner += 1
		elif _shows(s, PLAIN_DIR + "skyscraper_3_0.png"):
			without += 1
	assert_eq([with_banner, without], [1, 1], "one tower with its banner, one without, as in the run")


func test_an_earlier_level_without_the_key_opens_with_banners_off() -> void:
	var e := _editor()
	e.panel.pick("skyscraper-6")
	e.place_asset("skyscraper-6", Vector2(0.0, 0.0))
	for b in e.document.data.buildings:
		b.erase("banner")
	e.name_field.text = "Old Level"
	assert_eq(e.save(), OK)
	var again := _editor(dir.path_join("old_level.json"))
	assert_false(LevelDocument.banner_of(again.document.data.buildings[0]))
	assert_true(_shows(_skyscraper_slots(again.map)[0], PLAIN_DIR + "skyscraper_6_0.png"))


# ---- The game's own map ----------------------------------------------------------------------------

func test_the_games_own_map_keeps_its_banners() -> void:
	var map = MapScene.instantiate()
	add_child_autofree(map)
	var slots: Array = _skyscraper_slots(map)
	assert_gt(slots.size(), 0)
	for s in slots:
		var sp: Sprite2D = s.towers.get_node("Sprite")
		var bytes := _bytes_of(_image_of(sp.texture))
		var plain := false
		for n in range(1, 7):
			for k in 2:
				if bytes == _bytes_of(_file_image(PLAIN_DIR + "skyscraper_%d_%d.png" % [n, k])):
					plain = true
		assert_false(plain, "a map skyscraper is the art with its sign")
	var banners := 0
	var pavement_signs := 0
	for sp in map.alert_signs:
		if sp.get_meta("alert_kind") == "banner":
			banners += 1
		else:
			pavement_signs += 1
	assert_eq(banners, 4, "the four kaiju banners hang on the map's skyscrapers")
	assert_eq(pavement_signs, 2)
