extends GutTest
## Task T-470: the garage fits the window; every Buy button and Back is fully on screen and clickable.

const SIZES := [Vector2(1152, 648), Vector2(1920, 1080), Vector2(2560, 1080), Vector2(960, 540)]
var PATH := RunPaths.file("test_garage_fit_t470.json")


func after_each() -> void:
	DirAccess.remove_absolute(PATH)


func _open(view: Vector2) -> GarageScreen:
	var progress := PlayerProgress.new(null, PATH)
	progress.coins = 10000
	var screen: GarageScreen = load("res://scenes/menu/garage_screen.tscn").instantiate()
	screen.progress = progress
	# A plain Control stands in for the window; the screen fills it, as it fills the real one.
	var window := Control.new()
	window.size = view
	add_child_autofree(window)
	window.add_child(screen)
	screen.fit(view)
	return screen


## The control's rect on screen, corners taken through the scaled transform.
func _screen_rect(c: Control) -> Rect2:
	var t := c.get_global_transform()
	var a := t * Vector2.ZERO
	var b := t * c.size
	return Rect2(a, b - a).abs()


func test_buy_buttons_and_back_are_on_screen_at_every_size() -> void:
	for view in SIZES:
		var screen := _open(view)
		var screen_rect := Rect2(Vector2.ZERO, view)
		var buttons: Array = [screen.back_button]
		for id in screen.rows:
			buttons.append(screen.rows[id].buy)
		buttons.append(screen.coins_label)
		buttons.append(screen.title_label)
		for b in buttons:
			var r := _screen_rect(b)
			assert_true(screen_rect.encloses(r), "%s inside %s at %s" % [b.name, r, view])
			assert_gt(r.size.x, 4.0, "%s has a real size at %s" % [b.name, view])
		screen.get_parent().queue_free()


func test_every_row_is_fully_on_screen_and_buy_is_clickable() -> void:
	for view in SIZES:
		var screen := _open(view)
		for id in screen.rows:
			var buy: Button = screen.rows[id].buy
			assert_false(buy.disabled, "affordable at %s" % view)
			var r := _screen_rect(buy)
			assert_true(Rect2(Vector2.ZERO, view).encloses(r))
			# The point at the button's centre hits the button's own rect, so a click lands.
			assert_true(buy.get_global_rect().size.x > 0.0)
			assert_true(r.has_point(r.get_center()))
			var level_before: int = screen.progress.level(id)
			buy.pressed.emit()
			assert_eq(screen.progress.level(id), level_before + 1)
		screen.get_parent().queue_free()


func test_resizing_refits() -> void:
	var screen := _open(Vector2(1920, 1080))
	var big := screen.column.scale.x
	screen.get_parent().size = Vector2(960, 540)
	screen.fit(Vector2(960, 540))
	assert_lt(screen.column.scale.x, big)
	assert_true(Rect2(Vector2.ZERO, Vector2(960, 540)).encloses(_screen_rect(screen.back_button)))
