extends GutTest
## Task T-113 (round 2): the car's health bar stands upright at the top left
## with "Car Health" directly above it; the likes bar lies across the bottom
## centre, half the screen wide, with the likes row (heart and "Likes" at the
## left end, "Hype Lv" at the right end, on one line) directly above it and
## the combo counter centred above that. No HUD element overlaps another, the
## pause strip's content or the middle of the screen (the car and its trick
## popups).

const RUN := preload("res://scenes/run/run.tscn")
const GAME := preload("res://scenes/game/game.tscn")
const HUD_SCENE := preload("res://scenes/hud/hud.tscn")
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
	hud.level_label.text = Hud.TEXT_LEVEL.format({"level": 99})
	hud.combo_label.text = Hud.combo_text(5.75)
	hud.coins_value_label.text = "99999"
	return hud


## Every HUD element with a rectangle on screen, by name.
func _parts(hud: Hud) -> Dictionary:
	return {
		"health bar": hud.health_bar.get_global_rect(),
		"likes bar": hud.likes_bar.get_global_rect(),
		"Car Health": hud.health_label.get_global_rect(),
		"heart": hud.heart.get_global_rect(),
		"Likes": hud.likes_label.get_global_rect(),
		"Hype Lv": hud.level_label.get_global_rect(),
		"combo": hud.combo_label.get_global_rect(),
		"timer": hud.timer_label.get_global_rect(),
		"coins": hud.coins_label.get_parent().get_global_rect(),
	}


func _font_size(l: Label) -> int:
	return l.get_theme_font_size("font_size")


func _assert_health(hud: Hud, where: String) -> void:
	var view := hud.get_viewport().get_visible_rect().size
	var bar := hud.health_bar.get_global_rect()
	var label := hud.health_label.get_global_rect()
	assert_eq(hud.health_bar.fill_mode, ProgressBar.FILL_BOTTOM_TO_TOP, "%s: health fills bottom up" % where)
	assert_gt(bar.size.y, bar.size.x * 4.0, "%s: health bar upright" % where)
	assert_almost_eq(bar.position.x, float(Hud.MARGIN), 0.5, "%s: health bar at the left edge" % where)
	assert_lt(bar.end.x, view.x * 0.25, "%s: health bar in the left quarter" % where)
	assert_lt(bar.end.y, view.y * 0.5, "%s: health bar in the top half" % where)
	assert_almost_eq(label.position.x, bar.position.x, 0.5, "%s: Car Health left-aligned with the bar" % where)
	assert_lte(label.end.y, bar.position.y, "%s: Car Health above the bar" % where)
	assert_lt(bar.position.y - label.end.y, NEAR, "%s: Car Health directly above the bar" % where)
	assert_almost_eq(label.position.y, float(Hud.MARGIN), 0.5, "%s: Car Health at the top" % where)


func _assert_likes(hud: Hud, where: String) -> void:
	var view := hud.get_viewport().get_visible_rect().size
	var bar := hud.likes_bar.get_global_rect()
	assert_eq(hud.likes_bar.fill_mode, ProgressBar.FILL_BEGIN_TO_END, "%s: likes fills left to right" % where)
	assert_gt(bar.size.x, bar.size.y * 5.0, "%s: likes bar horizontal" % where)
	assert_almost_eq(bar.size.x, view.x * 0.5, 1.0, "%s: likes bar half the screen wide" % where)
	assert_almost_eq(bar.get_center().x, view.x * 0.5, 1.0, "%s: likes bar centred" % where)
	assert_almost_eq(view.y - bar.end.y, float(Hud.MARGIN), 0.5, "%s: likes bar near the bottom edge" % where)

	var row := hud.likes_row.get_global_rect()
	var heart := hud.heart.get_global_rect()
	var likes := hud.likes_label.get_global_rect()
	var level := hud.level_label.get_global_rect()
	assert_almost_eq(heart.position.x, bar.position.x, 0.5, "%s: heart at the bar's left end" % where)
	assert_lt(heart.end.x, likes.position.x, "%s: Likes right of the heart" % where)
	assert_almost_eq(level.end.x, bar.end.x, 0.5, "%s: Hype Lv ends at the bar's right end" % where)
	assert_lt(likes.end.x, level.position.x, "%s: Likes left of Hype Lv" % where)
	# Same baseline: same top, same height, same font size.
	assert_almost_eq(likes.position.y, level.position.y, 0.5, "%s: Likes and Hype Lv on one line" % where)
	assert_almost_eq(likes.size.y, level.size.y, 0.5, "%s: Likes and Hype Lv same height" % where)
	assert_lte(row.end.y, bar.position.y, "%s: row above the bar" % where)
	assert_lte(level.end.y, bar.position.y, "%s: Hype Lv above the bar" % where)
	assert_lt(bar.position.y - row.end.y, NEAR, "%s: row directly above the bar" % where)
	assert_lt(bar.position.y - level.end.y, NEAR, "%s: Hype Lv directly above the bar" % where)
	assert_gte(heart.position.y, row.position.y, "%s: heart within the row" % where)
	assert_lte(heart.end.y, row.end.y, "%s: heart within the row" % where)
	assert_almost_eq(heart.get_center().y, likes.get_center().y, 2.0, "%s: heart level with Likes" % where)

	var combo := hud.combo_label.get_global_rect()
	assert_almost_eq(combo.get_center().x, bar.get_center().x, 1.0, "%s: combo centred over the bar" % where)
	assert_lte(combo.end.y, minf(row.position.y, level.position.y), "%s: combo above the row" % where)
	assert_lt(row.position.y - combo.end.y, NEAR, "%s: combo just above the row" % where)


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
	r.hud.level_up_flash.stop()  # the pop of "Hype Lv" is tested in T-139's own tests
	await get_tree().process_frame
	_assert_health(r.hud, "run")
	_assert_likes(r.hud, "run")
	_assert_no_overlaps(r.hud, "run")


func test_layout_at_every_window_size() -> void:
	for size in SIZES:
		var hud := _hud_at(size)
		await get_tree().process_frame
		var where := "%dx%d" % [size.x, size.y]
		_assert_health(hud, where)
		_assert_likes(hud, where)
		_assert_no_overlaps(hud, where)


func test_layout_follows_a_window_resize() -> void:
	var hud := _hud_at(Vector2i(1152, 648))
	await get_tree().process_frame
	(hud.get_parent() as SubViewport).size = Vector2i(1920, 1080)
	await get_tree().process_frame
	_assert_likes(hud, "resized to 1920x1080")
	_assert_no_overlaps(hud, "resized to 1920x1080")


func test_layout_follows_longer_texts() -> void:
	var r := _run()
	await get_tree().process_frame
	r.state.add_xp(r.state.xp_needed() * 1.4)
	for i in 30:
		r.state.add_trick("alternate_drift")
	# The level-up animation pops "Hype Lv" bigger for a moment (T-139,
	# test_hud_level_up_flash.gd); this test is about the layout, so it ends.
	r.hud.level_up_flash.stop()
	await get_tree().process_frame
	_assert_likes(r.hud, "after a level-up and a combo")


func test_same_font_size_within_each_group() -> void:
	var hud := _hud_at(Vector2i(1152, 648))
	await get_tree().process_frame
	assert_eq(_font_size(hud.health_label), Hud.LABEL_FONT_SIZE, "Car Health")
	assert_eq(_font_size(hud.likes_label), _font_size(hud.level_label), "Likes and Hype Lv the same size")
	assert_eq(_font_size(hud.likes_label), Hud.LABEL_FONT_SIZE, "Likes")


func test_clear_of_the_middle() -> void:
	# The car is drawn at the middle of the screen; its trick popups go just above it.
	for size in SIZES:
		var hud := _hud_at(size)
		await get_tree().process_frame
		var view := Vector2(size)
		var middle := Rect2(view * 0.5 - Vector2(250, 150), Vector2(500, 250))
		for n: String in ["health bar", "likes bar", "Car Health", "heart", "Likes", "Hype Lv", "combo"]:
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
	for n: String in ["health bar", "likes bar", "Car Health", "heart", "Likes", "Hype Lv", "combo", "timer"]:
		assert_false(_parts(hud)[n].intersects(content), "%s clear of the pause strip's text and slider" % n)
	pause.toggle()
