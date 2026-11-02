extends GutTest
## Task T-113 (round 2): the car's health bar stands upright at the top left
## (T-276: 72 x 320, the heart under it, weapon icons beside it); since T-337
## the sub goal square sits on the right edge at the board's layout (x988 y340,
## 128 x 180 at 1152 x 648) in place of the likes bar and its row, and the combo
## counter is centred at the bottom. No HUD element overlaps another, the
## pause strip's content or the middle of the screen (the car and its trick
## popups).

const RUN := preload("res://scenes/run/run.tscn")
const GAME := preload("res://scenes/game/game.tscn")
const HUD_SCENE := preload("res://scenes/hud/hud.tscn")
const WeaponsScript := preload("res://scripts/weapons/weapons.gd")
var TEST_SETTINGS := RunPaths.file("test_settings_t113.cfg")
const SIZES: Array[Vector2i] = [
	Vector2i(1152, 648), Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(1024, 576)]
## How far a label may sit from its bar: "directly above" means within this.
const NEAR := 10.0


func before_each() -> void:
	GameSettings.path = TEST_SETTINGS
	DirAccess.remove_absolute(TEST_SETTINGS)


func after_each() -> void:
	get_tree().paused = false
	DirAccess.remove_absolute(TEST_SETTINGS)
	TestSave.restore_settings()


## A viewport the size of the game window: headless, the root viewport is
## only 64x64, so screen positions are checked inside one of these.
func _screen(size := Vector2i.ZERO) -> SubViewport:
	if size == Vector2i.ZERO:
		size = Vector2i(
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height"))
	var sv := SubViewport.new()
	sv.size = size
	add_child_autofree(sv)
	return sv


func _run() -> Node2D:
	var r: Node2D = RUN.instantiate()
	_screen().add_child(r)
	return r


## A bare HUD in a window of the given size, with the longest texts it shows.
func _hud_at(size: Vector2i) -> Hud:
	var hud: Hud = HUD_SCENE.instantiate()
	_screen(size).add_child(hud)
	hud.sub_goal.set_numbers(9999, 9999)
	hud._on_combo_changed(5.75)
	hud.coins_value_label.text = "99999"
	# All five weapons at mixed tiers (T-276), the tallest the icon column gets.
	var rack: Node = WeaponsScript.new()
	add_child_autofree(rack)
	for tier in [1, 2, 8, 3, 5]:
		rack.get_weapon(rack.weapons.keys()[[1, 2, 8, 3, 5].find(tier)]).set_tier(tier)
	hud.bind_weapons(rack)
	return hud


## Every HUD element with a rectangle on screen, by name.
func _parts(hud: Hud) -> Dictionary:
	return {
		"hearts": hud.heart_row.get_global_rect(),
		"sub goal": hud.sub_goal.get_global_rect().merge(hud.sub_goal.label_row.get_global_rect()),
		"weapon icons": hud.weapon_icons.get_global_rect(),
		"clock": hud.timer_clock.get_global_rect(),
		"coins": hud.coins_label.get_parent().get_global_rect(),
	}


func _font_size(l: Label) -> int:
	return l.get_theme_font_size("font_size")


func _assert_health(hud: Hud, where: String) -> void:
	# T-431: the layout page's pixels times the HUD's scale (1 at 1152 x 648).
	var s := hud.hud_scale()
	var row := hud.heart_row.get_global_rect()
	assert_almost_eq(row.position, Vector2(36, 24) * s, Vector2(0.5, 0.5), "%s: the hearts at x36 y24" % where)
	assert_almost_eq(row.size, Vector2(220, 40) * s, Vector2(0.5, 0.5), "%s: the hearts 220 x 40" % where)
	var icons := hud.weapon_icons.get_global_rect()
	assert_almost_eq(icons.position, Vector2(12, 88) * s, Vector2(0.5, 0.5), "%s: weapon icons at x12 y88" % where)
	assert_true(hud.get_node_or_null("Left/HealthLabel") == null, "%s: no Car Health label" % where)
	assert_null(hud.get("health_bar"), "%s: the health bar is gone" % where)


func _assert_sub_goal(hud: Hud, where: String) -> void:
	var view := hud.get_viewport().get_visible_rect().size
	var sg := hud.sub_goal
	var s := hud.hud_scale()
	var r := sg.get_global_rect()
	assert_almost_eq(r.size, Vector2(128, 180) * s, Vector2(0.5, 0.5), "%s: the sub goal is 128 x 180" % where)
	assert_almost_eq(view.x - r.end.x, (1152.0 - 988.0 - 128.0) * s, 0.5, "%s: anchored to the right edge" % where)
	assert_almost_eq(r.position.y, roundf(view.y * 340.0 / 648.0), 1.0, "%s: about two thirds down" % where)
	var square := Rect2(r.position, sg.square_size * s)
	assert_almost_eq(sg.square_size, Vector2(128, 128), Vector2(0.5, 0.5), "%s: the square is 128 x 128" % where)
	var label := sg.label_row.get_global_rect()
	assert_gte(label.position.y, square.end.y, "%s: the label is under the square" % where)
	assert_lte(label.end.y, r.end.y + 0.5, "%s: the label fits in the 180" % where)
	assert_almost_eq(label.get_center().x, square.get_center().x, 1.0, "%s: the label centred under it" % where)
	assert_true(Rect2(Vector2.ZERO, view).encloses(label), "%s: the label on screen" % where)
	var tag := hud.multiplier_tag.get_global_rect()
	assert_true(Rect2(Vector2.ZERO, view).encloses(tag), "%s: the multiplier is on screen" % where)
	assert_almost_eq(tag.get_center().x, view.x / 2.0 + hud.multiplier_tag.offset.x * hud.hud_scale(), 2.0, "%s: left of the car" % where)


func _assert_no_overlaps(hud: Hud, where: String) -> void:
	var parts := _parts(hud)
	var names: Array = parts.keys()
	for i in names.size():
		var a: Rect2 = parts[names[i]]
		assert_gt(a.size.x, 0.0, "%s: %s has a size" % [where, names[i]])
		for j in range(i + 1, names.size()):
			assert_false(a.intersects(parts[names[j]]),
				"%s: %s and %s do not overlap" % [where, names[i], names[j]])


func test_layout_in_a_run() -> void:
	var r := _run()
	r.state.add_xp(r.state.xp_needed() * 1.4)
	for i in 30:
		r.state.add_trick("alternate_drift")
	r.state.add_coins(999)
	r.hud.sub_goal.stop()
	await get_tree().process_frame
	_assert_health(r.hud, "run")
	_assert_sub_goal(r.hud, "run")
	_assert_no_overlaps(r.hud, "run")


func test_layout_at_every_window_size() -> void:
	for size in SIZES:
		var hud := _hud_at(size)
		await get_tree().process_frame
		var where := "%dx%d" % [size.x, size.y]
		_assert_health(hud, where)
		_assert_sub_goal(hud, where)
		_assert_no_overlaps(hud, where)


func test_layout_follows_a_window_resize() -> void:
	var hud := _hud_at(Vector2i(1152, 648))
	await get_tree().process_frame
	(hud.get_parent() as SubViewport).size = Vector2i(1920, 1080)
	await get_tree().process_frame
	_assert_sub_goal(hud, "resized to 1920x1080")
	_assert_no_overlaps(hud, "resized to 1920x1080")


func test_layout_follows_longer_texts() -> void:
	var r := _run()
	await get_tree().process_frame
	r.state.add_xp(r.state.xp_needed() * 1.4)
	for i in 30:
		r.state.add_trick("alternate_drift")
	# The square's celebration bounces the gift for a moment (T-337,
	# test_hud_sub_goal.gd); this test is about the layout, so it ends.
	r.hud.sub_goal.stop()
	r.hud.settle_likes()
	await get_tree().process_frame
	_assert_sub_goal(r.hud, "after a level-up and a combo")


func test_label_font_size() -> void:
	var hud := _hud_at(Vector2i(1152, 648))
	await get_tree().process_frame
	assert_eq(_font_size(hud.sub_goal.label), SubGoal.LABEL_FONT_SIZE, "the sub goal label")


func test_clear_of_the_middle() -> void:
	# The car is drawn at the middle of the screen; its trick popups go just above it.
	for size in SIZES:
		var hud := _hud_at(size)
		await get_tree().process_frame
		var view := Vector2(size)
		var middle := Rect2(view * 0.5 - Vector2(250, 150), Vector2(500, 250))
		for n: String in ["hearts", "sub goal", "weapon icons"]:
			assert_false(_parts(hud)[n].intersects(middle),
				"%dx%d: %s clear of the car and popups" % [size.x, size.y, n])


func test_clear_of_the_pause_strip_content() -> void:
	var game: Node = GAME.instantiate()
	_screen().add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var hud: Hud = game.run.hud
	var pause: CanvasLayer = game.pause_screen
	pause.toggle()
	await get_tree().process_frame
	assert_true(pause.visible, "paused")
	var content: Rect2 = pause.title_label.get_parent().get_global_rect()
	for n: String in ["hearts", "sub goal", "weapon icons", "clock", "coins"]:
		assert_false(_parts(hud)[n].intersects(content), "%s clear of the pause strip's text and slider" % n)
	pause.toggle()
