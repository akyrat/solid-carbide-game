extends GutTest
## Task T-431: the HUD scales with the window. At every window size each HUD piece keeps its
## corner or edge, has a size in proportion to the window, overlaps no other piece and is fully
## on screen; the pixel art keeps nearest filtering; the world camera's zoom is not touched.

const HUD_SCENE := preload("res://scenes/hud/hud.tscn")
const RUN := preload("res://scenes/run/run.tscn")
const WeaponsScript := preload("res://scripts/weapons/weapons.gd")
var TEST_SETTINGS := RunPaths.file("test_settings_t431_hud.cfg")
## The five window sizes of the ticket: the layout page, full HD, 1440p, ultrawide, small.
const SIZES: Array[Vector2i] = [
	Vector2i(1152, 648), Vector2i(1920, 1080), Vector2i(2560, 1440),
	Vector2i(3440, 1440), Vector2i(960, 540)]
## Which corner or edge each piece keeps: "tl", "bl", "br", or "r" (the right edge at a share
## of the height, the sub goal).
const ANCHORS := {
	"hearts": "tl", "weapon icons": "tl", "coins": "bl", "clock": "bl",
	"viewers": "br", "sub goal": "r"}
## Screen pixels of slack (the pieces round to whole pixels).
const EPS := 1.5


func before_each() -> void:
	GameSettings.path = TEST_SETTINGS
	DirAccess.remove_absolute(TEST_SETTINGS)


func after_each() -> void:
	get_tree().paused = false
	DirAccess.remove_absolute(TEST_SETTINGS)
	TestSave.restore_settings()


## A HUD in a window of `size` with the longest texts and all five weapons (the tallest column).
func _hud_at(size: Vector2i, hud_size := 100.0) -> Hud:
	var sv := SubViewport.new()
	sv.size = size
	add_child_autofree(sv)
	var hud: Hud = HUD_SCENE.instantiate()
	sv.add_child(hud)
	hud.set_hud_size(hud_size)
	hud.sub_goal.set_numbers(9999, 9999)
	hud._on_combo_changed(5.75)
	hud.coins_value_label.text = "99999"
	var rack: Node = WeaponsScript.new()
	add_child_autofree(rack)
	var tiers := [1, 2, 8, 3, 5]
	for i in tiers.size():
		rack.get_weapon(rack.weapons.keys()[i]).set_tier(tiers[i])
	hud.bind_weapons(rack)
	return hud


func _parts(hud: Hud) -> Dictionary:
	return {
		"hearts": hud.heart_row.get_global_rect(),
		"sub goal": hud.sub_goal.get_global_rect().merge(hud.sub_goal.label_row.get_global_rect()),
		"weapon icons": hud.weapon_icons.get_global_rect(),
		"viewers": hud.viewers_counter.get_global_rect(),
		"clock": hud.timer_clock.get_global_rect(),
		"coins": hud.coins_label.get_parent().get_global_rect(),
	}


func test_scale_follows_the_smaller_side() -> void:
	assert_almost_eq(Hud.scale_for(Vector2(1152, 648), 100.0), 1.0, 0.0001, "1 on the layout page")
	assert_almost_eq(Hud.scale_for(Vector2(1920, 1080), 100.0), 1080.0 / 648.0, 0.0001, "full HD")
	assert_almost_eq(Hud.scale_for(Vector2(3440, 1440), 100.0), 1440.0 / 648.0, 0.0001,
		"ultrawide: the height decides")
	assert_almost_eq(Hud.scale_for(Vector2(960, 540), 100.0), 960.0 / 1152.0, 0.0001, "small")
	assert_almost_eq(Hud.scale_for(Vector2(1152, 648), 50.0), 0.5, 0.0001, "the slider's 50")
	assert_almost_eq(Hud.scale_for(Vector2(1152, 648), 999.0),
		GameSettings.MAX_HUD_SIZE / 100.0, 0.0001, "clamped to the slider's top")


func test_every_piece_keeps_its_corner_and_proportion() -> void:
	var ref_hud := _hud_at(Vector2i(1152, 648))
	await get_tree().process_frame
	var ref := _parts(ref_hud)
	for size in SIZES:
		var hud := _hud_at(size)
		await get_tree().process_frame
		var view := Vector2(size)
		var s := minf(view.x / 1152.0, view.y / 648.0)
		var where := "%dx%d" % [size.x, size.y]
		assert_almost_eq(hud.hud_scale(), s, 0.0001, "%s: the HUD's scale" % where)
		var parts := _parts(hud)
		for n: String in ANCHORS:
			var a: Rect2 = ref[n]
			var b: Rect2 = parts[n]
			assert_almost_eq(b.size, a.size * s, Vector2(EPS, EPS), "%s: %s in proportion" % [where, n])
			match ANCHORS[n]:
				"tl":
					assert_almost_eq(b.position, a.position * s, Vector2(EPS, EPS), "%s: %s top left" % [where, n])
				"bl":
					assert_almost_eq(b.position.x, a.position.x * s, EPS, "%s: %s left" % [where, n])
					assert_almost_eq(view.y - b.end.y, (648.0 - a.end.y) * s, EPS, "%s: %s bottom" % [where, n])
				"br":
					assert_almost_eq(view.x - b.end.x, (1152.0 - a.end.x) * s, EPS, "%s: %s right" % [where, n])
					assert_almost_eq(view.y - b.end.y, (648.0 - a.end.y) * s, EPS, "%s: %s bottom" % [where, n])
				"r":
					assert_almost_eq(view.x - b.end.x, (1152.0 - a.end.x) * s, EPS, "%s: %s right" % [where, n])
					assert_almost_eq(b.position.y / view.y, a.position.y / 648.0, 0.003,
						"%s: %s at its share of the height" % [where, n])


func _assert_fits(hud: Hud, view: Vector2, where: String) -> void:
	var parts := _parts(hud)
	var names: Array = parts.keys()
	var screen := Rect2(Vector2.ZERO, view).grow(0.01)
	for i in names.size():
		var a: Rect2 = parts[names[i]]
		assert_true(screen.encloses(a), "%s: %s fully on screen (%s)" % [where, names[i], a])
		for j in range(i + 1, names.size()):
			assert_false(a.intersects(parts[names[j]]),
				"%s: %s and %s do not overlap" % [where, names[i], names[j]])


func test_no_overlaps_and_on_screen_at_every_size() -> void:
	for size in SIZES:
		var hud := _hud_at(size)
		await get_tree().process_frame
		_assert_fits(hud, Vector2(size), "%dx%d" % [size.x, size.y])


func test_no_overlaps_at_the_slider_ends() -> void:
	for size in SIZES:
		for pct in [GameSettings.MIN_HUD_SIZE, GameSettings.MAX_HUD_SIZE]:
			var hud := _hud_at(size, pct)
			await get_tree().process_frame
			_assert_fits(hud, Vector2(size), "%dx%d at %d" % [size.x, size.y, int(pct)])


func test_follows_a_window_resize() -> void:
	var hud := _hud_at(Vector2i(1152, 648))
	await get_tree().process_frame
	(hud.get_parent() as SubViewport).size = Vector2i(3440, 1440)
	await get_tree().process_frame
	assert_almost_eq(hud.hud_scale(), 1440.0 / 648.0, 0.0001, "rescaled on resize")
	_assert_fits(hud, Vector2(3440, 1440), "resized to 3440x1440")


func test_sub_goal_moves_up_clear_of_the_viewers_when_big() -> void:
	var hud := _hud_at(Vector2i(1152, 648), GameSettings.MAX_HUD_SIZE)
	await get_tree().process_frame
	var sg := hud.sub_goal.get_global_rect()
	var vc := hud.viewers_counter.get_global_rect()
	assert_lt(sg.end.y, vc.position.y, "the sub goal stays above the viewers counter")
	var normal := _hud_at(Vector2i(1152, 648))
	await get_tree().process_frame
	assert_eq(normal.sub_goal.offset_top, 0.0, "at 100 the sub goal is not moved")


## Every CanvasItem under the HUD resolves to nearest filtering (set, or inherited from the
## scaled root, which is nearest).
func test_textures_use_nearest_filtering() -> void:
	var hud := _hud_at(Vector2i(1920, 1080))
	await get_tree().process_frame
	assert_ne(fmod(hud.hud_scale(), 1.0), 0.0, "1920 x 1080 is not a whole-number scale")
	assert_eq(hud.root.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "the scaled root is nearest")
	var checked := 0
	var stack: Array = [hud.root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if not (n is CanvasItem):
			continue
		var f := _resolved_filter(n as CanvasItem, hud.root)
		assert_eq(f, CanvasItem.TEXTURE_FILTER_NEAREST, "%s is drawn nearest" % hud.root.get_path_to(n))
		checked += 1
	assert_gt(checked, 20, "the pieces were walked")


func _resolved_filter(c: CanvasItem, stop: CanvasItem) -> int:
	var n: Node = c
	while n is CanvasItem:
		var f := (n as CanvasItem).texture_filter
		if f != CanvasItem.TEXTURE_FILTER_PARENT_NODE:
			return f
		if n == stop:
			break
		n = n.get_parent()
	return CanvasItem.TEXTURE_FILTER_PARENT_NODE


## The world camera's zoom is the same with the HUD at any scale (it is never touched).
func test_world_camera_zoom_untouched() -> void:
	var sv := SubViewport.new()
	sv.size = Vector2i(1920, 1080)
	add_child_autofree(sv)
	var r: Node2D = RUN.instantiate()
	sv.add_child(r)
	await get_tree().process_frame
	r.set_zoom(14.4)
	var before: Vector2 = r.camera.zoom
	r.hud.set_hud_size(GameSettings.MIN_HUD_SIZE)
	await get_tree().process_frame
	assert_eq(r.camera.zoom, before, "zoom unchanged at the slider's bottom")
	r.hud.set_hud_size(GameSettings.MAX_HUD_SIZE)
	await get_tree().process_frame
	assert_eq(r.camera.zoom, before, "zoom unchanged at the slider's top")
	sv.size = Vector2i(3440, 1440)
	await get_tree().process_frame
	var after_resize: Vector2 = r.camera.zoom
	r.hud.set_hud_size(100.0)
	await get_tree().process_frame
	assert_eq(r.camera.zoom, after_resize, "zoom unchanged by the HUD on the ultrawide")
	assert_almost_eq(r.hud.hud_scale(), 1440.0 / 648.0, 0.0001, "the HUD did scale")


## Reactions bursts and viewer flights land in the scaled HUD's own pixels.
func test_bursts_and_flights_follow_the_scale() -> void:
	var hud := _hud_at(Vector2i(1920, 1080))
	await get_tree().process_frame
	var centre := hud.sub_goal.get_global_rect().get_center()
	var local := hud.to_layout(centre)
	assert_almost_eq(local * hud.hud_scale(), centre, Vector2(0.01, 0.01), "screen to layout pixels")
	var f := hud.viewers_counter.fly_in("+1K", 10.0, Vector2(960, 540))
	assert_almost_eq(f.base_scale, hud.hud_scale(), 0.0001, "the flight is drawn at the HUD's scale")
