extends GutTest
## Task T-015: Escape pauses and resumes, the pause screen's texts and zoom
## slider, and the saved zoom setting.

const SCENE := preload("res://scenes/drift_prototype/drift_prototype.tscn")
const TEST_PATH := "user://test_settings_t015.cfg"


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
	p.car.scripted_input = [true, false, 0.5]
	return p


func _escape(pressed: bool) -> void:
	var e := InputEventAction.new()
	e.action = "pause"
	e.pressed = pressed
	Input.parse_input_event(e)


func test_escape_is_an_action_in_the_input_map() -> void:
	assert_true(InputMap.has_action("pause"))
	var found := false
	for e in InputMap.action_get_events("pause"):
		if e is InputEventKey and e.physical_keycode == KEY_ESCAPE:
			found = true
	assert_true(found, "pause is bound to Escape")


func test_escape_pauses_and_the_car_stops_then_resumes_exactly() -> void:
	var p := _scene()
	await wait_physics_frames(10)
	assert_ne(p.car.position, Vector2.ZERO, "the car moves while running")
	var press := InputEventAction.new()
	press.action = "pause"
	press.pressed = true
	p.pause_screen._input(press)
	assert_true(get_tree().paused, "Escape pauses")
	assert_true(p.pause_screen.visible)
	var pos: Vector2 = p.car.position
	var vel: Vector2 = p.car.velocity
	var rot: float = p.car.rotation
	await wait_physics_frames(8)
	assert_eq(p.car.position, pos, "position unchanged while paused")
	assert_eq(p.car.velocity, vel, "velocity unchanged while paused")
	assert_eq(p.car.rotation, rot, "rotation unchanged while paused")
	p.pause_screen._input(press)
	assert_false(get_tree().paused, "Escape again resumes")
	assert_false(p.pause_screen.visible)
	assert_eq(p.car.position, pos, "resumes from exactly where it was")
	await wait_physics_frames(3)
	assert_ne(p.car.position, pos, "the car moves again")


func test_pause_screen_texts_and_slider_label() -> void:
	var p := _scene()
	assert_eq(p.pause_screen.title_label.text, "Paused")
	assert_eq(p.pause_screen.hint_label.text, "Press Escape to get back to the stream.")
	assert_eq(p.pause_screen.zoom_label.text, "Camera zoom, for the fans")


func test_slider_range_default_and_it_moves_the_camera() -> void:
	var p := _scene()
	var sl: HSlider = p.pause_screen.zoom_slider
	assert_almost_eq(sl.min_value, 6.0, 1e-9)
	assert_almost_eq(sl.max_value, 20.0, 1e-9)
	assert_almost_eq(sl.value, 14.4, 1e-6)
	var before: float = p.camera.zoom.y
	sl.value = 8.0
	assert_almost_eq(p.zoom, 8.0, 1e-9)
	assert_gt(p.camera.zoom.y, before, "smaller size = more magnification")
	var h: float = p.get_viewport().get_visible_rect().size.y
	assert_almost_eq(p.camera.zoom.y, h / (2.0 * 8.0 * 16.0), 1e-5)
	assert_almost_eq(p.panel.sliders["camera_zoom"].value, 8.0, 1e-6, "tuning panel shows the same value")


func test_tuning_panel_change_shows_in_pause_slider() -> void:
	var p := _scene()
	p.panel.sliders["camera_zoom"].value = 10.0
	p.pause_screen.pause()
	assert_almost_eq(p.pause_screen.zoom_slider.value, 10.0, 1e-6)


func test_zoom_is_saved_and_read_back_by_a_new_instance() -> void:
	var p := _scene()
	p.pause_screen.zoom_slider.value = 9.5
	assert_true(FileAccess.file_exists(TEST_PATH))
	var q := _scene()
	assert_almost_eq(q.zoom, 9.5, 1e-6)
	assert_almost_eq(q.pause_screen.zoom_slider.value, 9.5, 1e-6)
	assert_almost_eq(GameSettings.load_zoom(), 9.5, 1e-6)


func test_no_settings_file_gives_default_zoom() -> void:
	assert_false(FileAccess.file_exists(TEST_PATH))
	assert_almost_eq(GameSettings.load_zoom(), 14.4, 1e-12)
	assert_almost_eq(_scene().zoom, 14.4, 1e-12)


func test_bad_saved_values_fall_back_or_clamp() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("camera", "zoom", "wide")
	cfg.save(TEST_PATH)
	assert_almost_eq(GameSettings.load_zoom(), 14.4, 1e-12)
	cfg.set_value("camera", "zoom", 99.0)
	cfg.save(TEST_PATH)
	assert_almost_eq(GameSettings.load_zoom(), 20.0, 1e-12)
