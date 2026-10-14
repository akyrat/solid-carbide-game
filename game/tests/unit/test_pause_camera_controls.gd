extends GutTest
## Task T-124: the pause screen's camera checkboxes and the min/max buttons.

const SCENE := preload("res://scenes/drift_prototype/drift_prototype.tscn")
var TEST_PATH := RunPaths.file("test_settings_t124.cfg")


func before_each() -> void:
	GameSettings.path = TEST_PATH
	DirAccess.remove_absolute(TEST_PATH)


func after_each() -> void:
	get_tree().paused = false
	DirAccess.remove_absolute(TEST_PATH)
	GameSettings.path = GameSettings.DEFAULT_PATH


func _scene() -> Node2D:
	var p: Node2D = SCENE.instantiate()
	add_child_autofree(p)
	p.car.use_keyboard = false
	return p


func test_checkboxes_exist_with_the_boards_names_and_start_off() -> void:
	var ps = _scene().pause_screen
	assert_eq(ps.smoothing_check.text, "Camera smoothing")
	assert_eq(ps.dynamic_check.text, "Dynamic camera")
	assert_false(ps.smoothing_check.button_pressed)
	assert_false(ps.dynamic_check.button_pressed)
	assert_true(ps.smoothing_check.is_visible_in_tree() or not ps.visible)


func test_checkboxes_start_from_the_saved_settings() -> void:
	GameSettings.save_camera_smoothing(true)
	GameSettings.save_dynamic_camera(true)
	var p := _scene()
	assert_true(p.pause_screen.smoothing_check.button_pressed)
	assert_true(p.pause_screen.dynamic_check.button_pressed)
	assert_true(p.pause_screen.tuning_row.visible)


func test_checkboxes_switch_the_options_at_once_and_save() -> void:
	var p := _scene()
	var ps = p.pause_screen
	ps.pause()
	ps.smoothing_check.button_pressed = true
	assert_true(p.camera_follow.is_smoothing())
	assert_true(GameSettings.load_camera_smoothing())
	ps.dynamic_check.button_pressed = true
	assert_true(p.camera_follow.is_dynamic())
	assert_true(GameSettings.load_dynamic_camera())
	ps.smoothing_check.button_pressed = false
	ps.dynamic_check.button_pressed = false
	assert_false(p.camera_follow.is_smoothing())
	assert_false(p.camera_follow.is_dynamic())


func test_tuning_buttons_show_only_while_dynamic_is_on() -> void:
	var p := _scene()
	var ps = p.pause_screen
	assert_false(ps.tuning_row.visible)
	ps.dynamic_check.button_pressed = true
	assert_true(ps.tuning_row.visible)
	assert_eq(ps.set_min_button.text, "Set min zoom")
	assert_eq(ps.set_max_button.text, "Set max zoom")
	ps.dynamic_check.button_pressed = false
	assert_false(ps.tuning_row.visible)


func test_buttons_store_the_sliders_value_and_the_numbers_update() -> void:
	var p := _scene()
	var ps = p.pause_screen
	ps.pause()
	ps.dynamic_check.button_pressed = true
	ps.zoom_slider.value = 9.0
	ps.set_min_button.pressed.emit()
	assert_almost_eq(p.camera_follow.get_dynamic_min(), 9.0, 1e-6)
	assert_eq(ps.min_label.text, "9.0")
	ps.zoom_slider.value = 18.5
	ps.set_max_button.pressed.emit()
	assert_almost_eq(p.camera_follow.get_dynamic_max(), 18.5, 1e-6)
	assert_eq(ps.max_label.text, "18.5")
	assert_almost_eq(GameSettings.load_dynamic_zoom_min(), 9.0, 1e-6)
	assert_almost_eq(GameSettings.load_dynamic_zoom_max(), 18.5, 1e-6)


func test_numbers_show_the_stored_values_when_pausing() -> void:
	var p := _scene()
	p.camera_follow.set_dynamic(true)
	p.pause_screen.pause()
	assert_eq(p.pause_screen.min_label.text, "%.1f" % GameSettings.DEFAULT_DYNAMIC_ZOOM_MIN)
	assert_eq(p.pause_screen.max_label.text, "%.1f" % GameSettings.DEFAULT_DYNAMIC_ZOOM_MAX)
	assert_true(p.pause_screen.tuning_row.visible)


func test_strip_stays_below_the_hud_timer() -> void:
	var p := _scene()
	var ps = p.pause_screen
	ps.dynamic_check.button_pressed = true
	ps.pause()
	await wait_frames(3)
	assert_gte(ps.strip.get_global_rect().position.y, ps.STRIP_TOP - 0.5)
	assert_lt(ps.strip.get_global_rect().end.y, 300.0, "compact: stays in the top of the screen")


## QA round 1: over the run's bright asphalt the unchecked box and the buttons
## did not show. They now have their own visible look on a nearly opaque strip.
func _opaque_pixels(tex: Texture2D) -> int:
	var img := tex.get_image()
	var n := 0
	for x in img.get_width():
		for y in img.get_height():
			if img.get_pixel(x, y).a > 0.9:
				n += 1
	return n


func test_checkbox_icons_are_visible_checked_and_unchecked() -> void:
	var ps = _scene().pause_screen
	for c in [ps.smoothing_check, ps.dynamic_check]:
		var off: Texture2D = c.get_theme_icon("unchecked")
		var on: Texture2D = c.get_theme_icon("checked")
		assert_not_null(off)
		assert_not_null(on)
		var area: int = off.get_width() * off.get_height()
		assert_eq(_opaque_pixels(off), area, "unchecked box is fully opaque")
		assert_eq(_opaque_pixels(on), area, "checked box is fully opaque")
		# The frame is light, the fill dark: the box stands out on the strip.
		var img: Image = off.get_image()
		assert_gt(img.get_pixel(0, 0).get_luminance(), 0.6, "light frame")
		assert_lt(img.get_pixel(off.get_width() / 2, off.get_height() / 2).get_luminance(), 0.3, "dark fill")
		# Checked differs from unchecked in the middle.
		var mid := Vector2i(on.get_width() / 2, on.get_height() / 2)
		assert_gt(on.get_image().get_pixelv(mid).get_luminance(), 0.6, "checked has a light mark")


func test_buttons_have_a_visible_frame_in_every_state() -> void:
	var ps = _scene().pause_screen
	for b in [ps.set_min_button, ps.set_max_button]:
		for state in ["normal", "hover", "pressed", "focus"]:
			var st = b.get_theme_stylebox(state)
			assert_true(st is StyleBoxFlat, "%s has its own %s style" % [b.name, state])
			assert_gt(st.border_width_left, 0, "%s %s has a frame" % [b.name, state])
			assert_gt(st.border_color.a, 0.9)
			assert_gt(st.border_color.get_luminance(), 0.6)
		var normal: StyleBoxFlat = b.get_theme_stylebox("normal")
		assert_gt(normal.bg_color.a, 0.9, "the button has an opaque fill")


func test_strip_is_nearly_opaque() -> void:
	var ps = _scene().pause_screen
	var st: StyleBoxFlat = ps.strip.get_theme_stylebox("panel")
	assert_gte(st.bg_color.a, 0.85)
