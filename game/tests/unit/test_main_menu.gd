extends GutTest

var menu: MainMenu


func before_each() -> void:
	menu = load("res://scenes/menu/main_menu.tscn").instantiate()
	add_child_autofree(menu)


func test_title_and_subtitle() -> void:
	assert_eq(menu.title_label.text, "SOLID CARBIDE")
	assert_eq(menu.subtitle_label.text, "(work in progress)")


func test_title_uses_the_pixel_font() -> void:
	var font: Font = menu.title_label.get_theme_font("font")
	assert_eq(font.resource_path, "res://fonts/press_start_2p/PressStart2P-Regular.ttf")
	assert_eq(menu.subtitle_label.get_theme_font("font"), font)
	assert_true(FileAccess.file_exists("res://fonts/press_start_2p/OFL.txt"))
	assert_true(FileAccess.file_exists("res://fonts/press_start_2p/press_start_2p.json"))


func test_placeholder_when_there_is_no_splash() -> void:
	for size in [Vector2(1152, 648), Vector2(3440, 1440)]:
		var bare := _menu_on_screen(size, "res://art/menu/does_not_exist.png")
		await wait_process_frames(2)
		assert_null(bare.splash_rect)
		assert_eq(bare.background.color, MainMenu.PLACEHOLDER_COLOR)
		assert_almost_eq(bare.background.get_global_rect().size, size, Vector2(0.5, 0.5), "fills the screen at its scale (T-494)")


## A menu inside a parent of the given screen size, using another image path.
func _menu_on_screen(size: Vector2, path: String) -> MainMenu:
	var screen := Control.new()
	screen.size = size
	add_child_autofree(screen)
	var m := MainMenu.new()
	m.splash_path = path
	screen.add_child(m)
	return m


func test_splash_fills_the_screen_cropped_with_nearest_filtering() -> void:
	var path := "user://test_splash.png"
	var image := Image.create(64, 36, false, Image.FORMAT_RGBA8)
	image.fill(Color.RED)
	image.save_png(path)
	for size in [Vector2(1152, 648), Vector2(3440, 1440)]:
		var with_splash := _menu_on_screen(size, path)
		await wait_process_frames(2)
		assert_not_null(with_splash.splash_rect)
		assert_eq(with_splash.splash_rect.texture.get_width(), 64)
		assert_eq(with_splash.splash_rect.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_COVERED)
		assert_eq(with_splash.splash_rect.expand_mode, TextureRect.EXPAND_IGNORE_SIZE)
		assert_eq(with_splash.splash_rect.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
		assert_almost_eq(with_splash.splash_rect.get_global_rect().size, size, Vector2(0.5, 0.5), "fills the screen at its scale (T-494)")
	DirAccess.remove_absolute(path)


func test_focus_starts_on_start() -> void:
	assert_true(menu.start_button.has_focus())


func test_button_labels_are_the_approved_text() -> void:
	assert_eq(menu.start_button.text, "Start")
	assert_eq(menu.garage_button.text, "Garage")
	assert_eq(menu.exit_button.text, "Exit")


func test_start_button_signal() -> void:
	watch_signals(menu)
	menu.start_button.pressed.emit()
	assert_signal_emitted(menu, "start_pressed")
	assert_signal_not_emitted(menu, "garage_pressed")
	assert_signal_not_emitted(menu, "exit_pressed")


func test_garage_button_signal() -> void:
	watch_signals(menu)
	menu.garage_button.pressed.emit()
	assert_signal_emitted(menu, "garage_pressed")
	assert_signal_not_emitted(menu, "start_pressed")


func test_exit_button_signal() -> void:
	watch_signals(menu)
	menu.exit_button.pressed.emit()
	assert_signal_emitted(menu, "exit_pressed")
	assert_signal_not_emitted(menu, "start_pressed")
