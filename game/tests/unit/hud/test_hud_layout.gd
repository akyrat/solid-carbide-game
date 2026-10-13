extends GutTest
## Task T-113: the car's health bar and the likes bar stand upright, side by
## side at the top left, and no HUD element overlaps another, the pause
## strip's content or the middle of the screen (where the car and its trick
## popups are).

const RUN := preload("res://scenes/run/run.tscn")
const GAME := preload("res://scenes/game/game.tscn")
const HUD_SCENE := preload("res://scenes/hud/hud.tscn")
const TEST_SETTINGS := "user://test_settings_t113.cfg"


func before_each() -> void:
	GameSettings.path = TEST_SETTINGS
	DirAccess.remove_absolute(TEST_SETTINGS)


func after_each() -> void:
	get_tree().paused = false
	DirAccess.remove_absolute(TEST_SETTINGS)
	GameSettings.path = GameSettings.DEFAULT_PATH


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


func _assert_no_overlaps(hud: Hud, where: String) -> void:
	var parts := _parts(hud)
	var names: Array = parts.keys()
	for i in names.size():
		var a: Rect2 = parts[names[i]]
		assert_gt(a.size.x, 0.0, "%s: %s has a size" % [where, names[i]])
		for j in range(i + 1, names.size()):
			# The heart sits inside the likes row with "Likes": the row is one line.
			if [names[i], names[j]] == ["heart", "Likes"]:
				assert_false(a.intersects(parts["Likes"]), "%s: heart beside Likes" % where)
				continue
			assert_false(a.intersects(parts[names[j]]),
				"%s: %s and %s do not overlap" % [where, names[i], names[j]])


func test_bars_are_upright_and_fill_bottom_up() -> void:
	var r := _run()
	await get_tree().process_frame
	var hud: Hud = r.hud
	for bar: ProgressBar in [hud.health_bar, hud.likes_bar]:
		assert_eq(bar.fill_mode, ProgressBar.FILL_BOTTOM_TO_TOP, "%s fills bottom up" % bar.name)
		var rect := bar.get_global_rect()
		assert_gt(rect.size.y, rect.size.x * 4.0, "%s stands upright" % bar.name)
	assert_eq(hud.health_bar.size, hud.likes_bar.size, "same size")


func test_bars_side_by_side_at_the_top_left() -> void:
	var r := _run()
	await get_tree().process_frame
	var hud: Hud = r.hud
	var view := hud.get_viewport().get_visible_rect().size
	var h := hud.health_bar.get_global_rect()
	var l := hud.likes_bar.get_global_rect()
	assert_lt(h.end.x, l.position.x, "health bar left of the likes bar")
	assert_lt(l.position.x - h.end.x, 20.0, "a small gap only")
	assert_eq(h.position.y, l.position.y, "tops level")
	for rect: Rect2 in [h, l]:
		assert_lt(rect.end.x, view.x * 0.25, "in the left quarter")
		assert_lt(rect.position.y, view.y * 0.1, "starts at the top")
		assert_lt(rect.end.y, view.y * 0.5, "in the top half")
	assert_almost_eq(h.position.x, float(Hud.MARGIN), 0.5, "on the far left")


func test_labels_sit_under_their_bars() -> void:
	var r := _run()
	await get_tree().process_frame
	var hud: Hud = r.hud
	var h := hud.health_bar.get_global_rect()
	var l := hud.likes_bar.get_global_rect()
	var health := hud.health_label.get_global_rect()
	var row := hud.likes_row.get_global_rect()
	var level := hud.level_label.get_global_rect()
	assert_gte(health.position.y, h.end.y, "Car Health under the bars")
	assert_almost_eq(health.position.x, h.position.x, 0.5, "starts at the health bar")
	assert_almost_eq(row.position.x, l.position.x, 0.5, "heart and Likes start at the likes bar")
	assert_almost_eq(level.position.x, l.position.x, 0.5, "Hype Lv starts at the likes bar")
	assert_gte(row.position.y, health.end.y, "Likes line under Car Health")
	assert_gte(level.position.y, row.end.y, "Hype Lv line under Likes")


func test_nothing_overlaps_in_a_run() -> void:
	var r := _run()
	r.state.add_xp(r.state.xp_needed() * 1.4)
	for i in 30:
		r.state.add_trick("alternate_drift")
	r.state.add_coins(999)
	await get_tree().process_frame
	_assert_no_overlaps(r.hud, "game window")


func test_left_area_is_clear_of_the_middle() -> void:
	# The car is drawn at the middle of the screen; its trick popups go just above it.
	var r := _run()
	for i in 30:
		r.state.add_trick("alternate_drift")
	await get_tree().process_frame
	var view: Vector2 = r.hud.get_viewport().get_visible_rect().size
	var middle := Rect2(view * 0.5 - Vector2(250, 150), Vector2(500, 250))
	for n: String in ["health bar", "likes bar", "Car Health", "heart", "Likes", "Hype Lv", "combo"]:
		assert_false(_parts(r.hud)[n].intersects(middle), "%s clear of the car and popups" % n)


func test_window_sizes() -> void:
	for size: Vector2i in [Vector2i(1152, 648), Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(1024, 576)]:
		var sv := _screen(size)
		var hud: Hud = HUD_SCENE.instantiate()
		sv.add_child(hud)
		hud.level_label.text = Hud.TEXT_LEVEL.format({"level": 99})
		hud.combo_label.text = Hud.combo_text(5.75)
		hud.coins_value_label.text = "99999"
		await get_tree().process_frame
		_assert_no_overlaps(hud, "%dx%d" % [size.x, size.y])


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
