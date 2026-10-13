extends GutTest
## Task T-124: the pause screen's camera checkboxes and the min/max buttons.

const SCENE := preload("res://scenes/drift_prototype/drift_prototype.tscn")
const TEST_PATH := "user://test_settings_t124.cfg"


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
