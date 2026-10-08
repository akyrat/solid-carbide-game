extends GutTest
## Checks the drift prototype scene: project settings, the default values, the
## tuning panel, the flat / isometric view switch, the camera and the car sprite.

const SCENE := preload("res://scenes/drift_prototype/drift_prototype.tscn")
const CarTuning := preload("res://scripts/driving/car_tuning.gd")

## The "Value in project files (used)" column of the Unity prototype report, section 5.
const UNITY_VALUES := {
	"forward_speed": 11.0,
	"turn_speed": 202.0,
	"top_speed_multiplier": 2.5,
	"time_to_top_speed": 2.3,
	"coast_decel_multiplier": 0.3,
	"steer_sensitivity": 0.95,
	"drift_factor": 0.98,
	"drift_grip_low_speed": 0.98,
	"drift_grip_high_speed": 0.98,
	"drift_speed_reference": 20.0,
	"drift_enter_rate": 12.0,
	"drift_exit_rate": 3.0,
}

## The report's section 8 slider ranges (off-road damping and physics rate left out).
const SECTION_8_RANGES := {
	"forward_speed": [4.0, 25.0],
	"top_speed_multiplier": [1.0, 4.0],
	"time_to_top_speed": [0.5, 5.0],
	"coast_decel_multiplier": [0.0, 1.5],
	"turn_speed": [60.0, 360.0],
	"steer_sensitivity": [0.5, 1.5],
	"drift_factor": [0.8, 1.0],
	"drift_grip_low_speed": [0.8, 1.0],
	"drift_grip_high_speed": [0.8, 1.0],
	"drift_speed_reference": [5.0, 40.0],
	"drift_enter_rate": [1.0, 30.0],
	"drift_exit_rate": [1.0, 30.0],
	"camera_zoom": [6.0, 20.0],
}


func _scene() -> Node2D:
	var p: Node2D = SCENE.instantiate()
	add_child_autofree(p)
	p.car.set_physics_process(false)
	p.car.use_keyboard = false
	return p


func _drive(p: Node2D, steps: int, w: bool, s: bool, steer: float) -> void:
	p.car.scripted_input = [w, s, steer]
	for i in steps:
		p.car.physics_step()


func _has_key(action: String, keycode: Key) -> bool:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey and (e.physical_keycode == keycode or e.keycode == keycode):
			return true
	return false


# --- Project settings -------------------------------------------------------------------

func test_project_runs_physics_at_50_ticks() -> void:
	assert_eq(ProjectSettings.get_setting("physics/common/physics_ticks_per_second"), 50)
	assert_false(ProjectSettings.get_setting("physics/common/physics_interpolation"), "interpolation off by default")


func test_input_map_binds_wasd_and_tab() -> void:
	assert_true(_has_key("car_accelerate", KEY_W), "W accelerates")
	assert_true(_has_key("car_reverse", KEY_S), "S brakes and reverses")
	assert_true(_has_key("car_steer_left", KEY_A), "A steers left")
	assert_true(_has_key("car_steer_right", KEY_D), "D steers right")
	assert_true(_has_key("toggle_tuning_panel", KEY_TAB), "Tab opens the panel")
	assert_true(_has_key("toggle_view", KEY_V), "V switches the view")
	for action in ["car_accelerate", "car_reverse", "car_steer_left", "car_steer_right", "toggle_tuning_panel", "toggle_view"]:
		assert_false(_has_key(action, KEY_ESCAPE), "%s does not use Escape (pause is T-015)" % action)


# --- Defaults and sliders ---------------------------------------------------------------

func test_defaults_equal_unity_values() -> void:
	var t = CarTuning.new()
	for key in UNITY_VALUES:
		assert_almost_eq(float(t.get(key)), UNITY_VALUES[key], 1e-12, key)
	assert_almost_eq(t.top_speed(), 27.5, 1e-12)
	assert_almost_eq(t.turn_rate(), 191.9, 1e-9)


func test_every_section_8_setting_has_a_slider_starting_at_unity_value() -> void:
	var p := _scene()
	var sliders: Dictionary = p.panel.sliders
	assert_eq(sliders.size(), SECTION_8_RANGES.size(), "one slider per setting, no extras")
	for key in SECTION_8_RANGES:
		assert_true(sliders.has(key), "slider for %s" % key)
		if not sliders.has(key):
			continue
		var sl: HSlider = sliders[key]
		assert_almost_eq(sl.min_value, SECTION_8_RANGES[key][0], 1e-9, "%s min" % key)
		assert_almost_eq(sl.max_value, SECTION_8_RANGES[key][1], 1e-9, "%s max" % key)
		var expected: float = 14.4 if key == "camera_zoom" else UNITY_VALUES[key]
		assert_almost_eq(sl.value, expected, 1e-6, "%s starts at the Unity value" % key)
		assert_ne(sl.tooltip_text, "", "%s has a tooltip" % key)
	for key in UNITY_VALUES:
		assert_almost_eq(float(p.car.tuning.get(key)), UNITY_VALUES[key], 1e-12, "car uses Unity %s" % key)


func test_slider_labels_are_the_section_8_labels() -> void:
	var labels := []
	for s in CarTuning.SETTINGS:
		labels.append(s.label)
	assert_has(labels, "Speed you jump to when you press W")
	assert_has(labels, "How fast normal grip comes back when you stop")
	assert_has(labels, "Slide kept per step while drifting fast")


func test_changing_a_slider_changes_the_movement() -> void:
	var p := _scene()
	p.panel.sliders["forward_speed"].value = 15.0
	assert_almost_eq(p.car.tuning.forward_speed, 15.0, 1e-9)
	_drive(p, 1, true, false, 0.0)
	assert_almost_eq(p.car.model.forward_speed(), 15.0, 1e-6, "W now snaps to 15")

	p.panel.sliders["turn_speed"].value = 100.0
	var before: float = p.car.rotation
	_drive(p, 50, false, false, 1.0)
	assert_almost_eq(rad_to_deg(before - p.car.rotation), 100.0 * 0.95, 1e-4, "turns at the new rate")

	p.panel.sliders["camera_zoom"].value = 8.0
	assert_almost_eq(p.zoom, 8.0, 1e-9)


func test_reset_restores_every_unity_value() -> void:
	var p := _scene()
	for key in p.panel.sliders:
		var sl: HSlider = p.panel.sliders[key]
		sl.value = sl.max_value
	p.set_physics_interpolation(true)
	assert_almost_eq(p.car.tuning.forward_speed, 25.0, 1e-9)
	p.panel.reset_button.pressed.emit()
	for key in UNITY_VALUES:
		assert_almost_eq(float(p.car.tuning.get(key)), UNITY_VALUES[key], 1e-12, "%s reset" % key)
		assert_almost_eq(p.panel.sliders[key].value, UNITY_VALUES[key], 1e-6, "%s slider reset" % key)
	assert_almost_eq(p.zoom, 14.4, 1e-12)
	assert_almost_eq(p.panel.sliders["camera_zoom"].value, 14.4, 1e-6)
	assert_false(p.physics_interpolation, "interpolation back off")
	assert_false(p.panel.interpolation_toggle.button_pressed)


func test_interpolation_toggle() -> void:
	var p := _scene()
	assert_false(get_tree().physics_interpolation)
	p.panel.interpolation_toggle.button_pressed = true
	assert_true(get_tree().physics_interpolation)
	p.panel.interpolation_toggle.button_pressed = false
	assert_false(get_tree().physics_interpolation)


# --- View switch ------------------------------------------------------------------------

## A fixed drive: W, W + A drift, coast, S reverse, W + D.
const ROUTE := [[30, true, false, 0.0], [60, true, false, 1.0], [20, false, false, 0.0],
	[40, false, true, -1.0], [50, true, false, -1.0]]


func _run_route(p: Node2D, switch_every: int) -> void:
	var n := 0
	for leg in ROUTE:
		p.car.scripted_input = [leg[1], leg[2], leg[3]]
		for i in leg[0]:
			p.car.physics_step()
			n += 1
			if switch_every > 0 and n % switch_every == 0:
				p.set_view("flat" if p.view == "iso" else "iso")


func test_view_switch_mid_drive_leaves_the_car_unchanged() -> void:
	var plain := _scene()
	_run_route(plain, 0)
	var switched := _scene()
	_run_route(switched, 17)
	var a = plain.car.model
	var b = switched.car.model
	assert_eq(b.x, a.x, "x")
	assert_eq(b.y, a.y, "y")
	assert_eq(b.vx, a.vx, "vx")
	assert_eq(b.vy, a.vy, "vy")
	assert_eq(b.rotation, a.rotation, "rotation")
	assert_eq(b.drift_amount, a.drift_amount, "drift amount")
	assert_eq(switched.car.position, plain.car.position, "body position")
	assert_eq(switched.car.rotation, plain.car.rotation, "body rotation")
	assert_true(a.total_speed() > 1.0, "the car was moving")


func test_view_switch_changes_only_the_drawing() -> void:
	var p := _scene()
	_drive(p, 40, true, false, 1.0)
	assert_eq(p.view, "flat")
	assert_eq(p.car_sprite.texture.resource_path, "res://art/placeholders/car/car_flat.png")
	assert_eq(p.ground.transform, Transform2D.IDENTITY)
	p.panel.view_toggle.button_pressed = true
	assert_eq(p.view, "iso")
	assert_eq(p.car_sprite.texture.resource_path, "res://art/placeholders/car/car_iso.png")
	var c: Vector2 = p.car.position
	assert_eq(p.car_sprite.position, Vector2(c.x - c.y, (c.x + c.y) / 2.0), "2:1 isometric projection")
	p.set_view("flat")
	assert_false(p.panel.view_toggle.button_pressed, "panel toggle follows the key")


# --- Camera -----------------------------------------------------------------------------

func test_camera_stays_on_the_car_and_never_rotates() -> void:
	var p := _scene()
	assert_true(p.camera.is_current())
	assert_true(p.camera.ignore_rotation)
	assert_false(p.camera.position_smoothing_enabled)
	assert_eq(p.camera.offset, Vector2.ZERO)
	for v in ["flat", "iso"]:
		p.set_view(v)
		var rotations := []
		for k in 3:
			_drive(p, 13, true, false, 1.0)
			rotations.append(p.car.rotation)
			var drawn: Vector2 = p.view_transform() * p.car.position
			assert_eq(p.camera.position, drawn, "%s: camera on the car" % v)
			assert_eq(p.car_sprite.position, drawn, "%s: sprite on the car" % v)
			assert_eq(p.camera.global_rotation, 0.0, "%s: camera never rotates" % v)
			p.camera.force_update_scroll()
			assert_almost_eq(p.camera.get_screen_center_position(), p.camera.global_position, Vector2(0.001, 0.001), "%s: no drag or smoothing" % v)
		assert_ne(rotations[0], rotations[2], "the car turned")


func test_zoom_slider_range_and_default() -> void:
	var p := _scene()
	var sl: HSlider = p.panel.sliders["camera_zoom"]
	assert_eq(sl.min_value, 6.0)
	assert_eq(sl.max_value, 20.0)
	assert_almost_eq(sl.value, 14.4, 1e-6)
	var h := p.get_viewport().get_visible_rect().size.y
	assert_almost_eq(p.camera.zoom.y, h / (2.0 * 14.4 * 16.0), 1e-5, "shows 28.8 units top to bottom")


# --- Car sprite -------------------------------------------------------------------------

func test_sprite_frame_follows_heading() -> void:
	var p := _scene()
	var sp = p.car_sprite
	assert_eq(sp.hframes, 16)
	assert_eq(sp.frame, 12, "starts nose up: heading 270 degrees, frame 12")
	assert_eq(sp.frame_for_rotation(0.0), 0)
	assert_eq(sp.frame_for_rotation(deg_to_rad(22.5)), 1)
	assert_eq(sp.frame_for_rotation(deg_to_rad(-22.5)), 15)
	assert_eq(sp.frame_for_rotation(deg_to_rad(11.0)), 0)
	assert_eq(sp.frame_for_rotation(deg_to_rad(12.0)), 1)
	assert_eq(sp.frame_for_rotation(deg_to_rad(360.0 + 90.0)), 4)
	_drive(p, 30, false, false, -1.0)
	assert_eq(sp.frame, sp.frame_for_rotation(p.car.rotation), "frame updated after steering")
	assert_eq(sp.scale, Vector2.ONE, "16 px per unit sheet in a 16 px per unit world")
	assert_eq(sp.offset, Vector2.ZERO, "centre pixel is the frame middle")


func test_physics_body_is_1_by_1_unit() -> void:
	var p := _scene()
	var shape: RectangleShape2D = p.car.get_node("Body1x1").shape
	assert_eq(shape.size, Vector2(16.0, 16.0))
