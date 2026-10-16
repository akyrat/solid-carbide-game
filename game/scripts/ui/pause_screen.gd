extends CanvasLayer
## The pause screen (task T-015): a title, a hint that Escape resumes and one
## setting, the camera zoom slider. Escape (the "pause" action) pauses and
## resumes. It only shows the screen and collects input; the zoom itself is set
## by the scene it belongs to (set_zoom) and saved by GameSettings.
## Texts are from task T-047.

const GameSettingsScript := preload("res://scripts/ui/game_settings.gd")

## The strip starts this far from the top of the screen, just below the HUD
## run timer, so the two never overlap (T-093, T-095).
const STRIP_TOP := 92.0
const ACTION_PAUSE := "pause"
const TEXT_TITLE := "Paused"
const TEXT_HINT := "Press Escape to get back to the stream."
const TEXT_ZOOM_LABEL := "Camera zoom level"
## The sound effects volume slider (T-077; the board's name, board 2026-10-16).
const TEXT_SFX_LABEL := "SFX volume"
## The camera checkboxes use the board's own names (T-124). The two tuning
## buttons are a temporary tool for the board, not game text.
const TEXT_SMOOTHING := "Camera smoothing"
const TEXT_DYNAMIC := "Dynamic camera"
const TEXT_SET_MIN := "Set min zoom"
const TEXT_SET_MAX := "Set max zoom"
## The strip's background. Nearly opaque, so the controls read over any ground,
## the run's bright asphalt included (T-124, QA round 1).
const STRIP_COLOR := Color(0, 0, 0, 0.85)
## Placeholder look for the checkboxes and buttons (T-124): a light frame on a
## dark fill, so they show on the strip whatever the ground behind it.
const CONTROL_FRAME := Color(0.85, 0.85, 0.85)
const CONTROL_FILL := Color(0.16, 0.16, 0.16)
const CONTROL_FILL_HOVER := Color(0.28, 0.28, 0.28)
const CONTROL_FILL_PRESSED := Color(0.08, 0.08, 0.08)
const CHECK_ICON_SIZE := 16

## The scene whose camera zoom this slider sets (needs `zoom` and set_zoom()).
var target: Node
var zoom_slider: HSlider
var title_label: Label
var hint_label: Label
var zoom_label: Label
var sfx_slider: HSlider
var sfx_label: Label
var _sfx_value_label: Label
var _value_label: Label
var smoothing_check: CheckBox
var dynamic_check: CheckBox
## The temporary tuning row: shown only while the dynamic camera is on.
var tuning_row: HBoxContainer
var set_min_button: Button
var set_max_button: Button
var min_label: Label
var max_label: Label
var _root: Control
var strip: PanelContainer
var _saved_cam: Array = []


func setup(t: Node) -> void:
	target = t
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.name = "PauseScreen"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.2)  # light, so the zoom shows behind it
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	# The panel sits at the top, over a dark strip, so the map behind stays clear.
	strip = PanelContainer.new()
	strip.set_anchors_preset(Control.PRESET_TOP_WIDE)
	strip.offset_top = STRIP_TOP
	strip.offset_bottom = STRIP_TOP  # grows down to fit its content only
	var style := StyleBoxFlat.new()
	style.bg_color = STRIP_COLOR
	style.content_margin_top = 8.0
	style.content_margin_bottom = 10.0
	strip.add_theme_stylebox_override("panel", style)
	_root.add_child(strip)
	var center := CenterContainer.new()
	strip.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 520.0
	box.add_theme_constant_override("separation", 4)
	center.add_child(box)

	title_label = Label.new()
	title_label.text = TEXT_TITLE
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	box.add_child(title_label)
	hint_label = Label.new()
	hint_label.text = TEXT_HINT
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 16)
	box.add_child(hint_label)
	zoom_label = Label.new()
	zoom_label.text = TEXT_ZOOM_LABEL
	zoom_label.add_theme_font_size_override("font_size", 16)
	var row := HBoxContainer.new()
	box.add_child(row)
	row.add_child(zoom_label)
	zoom_slider = HSlider.new()
	zoom_slider.name = "ZoomSlider"
	zoom_slider.min_value = GameSettingsScript.MIN_ZOOM
	zoom_slider.max_value = GameSettingsScript.MAX_ZOOM
	zoom_slider.step = 0.1
	zoom_slider.value = target.zoom
	zoom_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zoom_slider.focus_mode = Control.FOCUS_NONE
	zoom_slider.value_changed.connect(_on_zoom_changed)
	row.add_child(zoom_slider)
	_value_label = Label.new()
	_value_label.custom_minimum_size.x = 50.0
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_value_label)
	_update_value_label()
	_build_camera_controls(box)
	visible = false


## The "SFX volume" slider (T-077): 0 to 100, saved, applied to the SFX bus at once.
## It shares the row of the camera checkboxes, so the strip stays a thin band (T-095).
func _build_sfx_slider(row: HBoxContainer) -> void:
	sfx_label = Label.new()
	sfx_label.text = TEXT_SFX_LABEL
	sfx_label.add_theme_font_size_override("font_size", 16)
	row.add_child(sfx_label)
	sfx_slider = HSlider.new()
	sfx_slider.name = "SfxSlider"
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 100.0
	sfx_slider.step = 1.0
	sfx_slider.value = GameSettingsScript.load_sfx_volume()
	sfx_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sfx_slider.focus_mode = Control.FOCUS_NONE
	sfx_slider.value_changed.connect(_on_sfx_changed)
	row.add_child(sfx_slider)
	_sfx_value_label = Label.new()
	_sfx_value_label.custom_minimum_size.x = 50.0
	_sfx_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_sfx_value_label)
	_sfx_value_label.text = "%d" % int(sfx_slider.value)
	GameSettingsScript.apply_sfx_volume(sfx_slider.value)


func _on_sfx_changed(v: float) -> void:
	GameSettingsScript.save_sfx_volume(v)
	GameSettingsScript.apply_sfx_volume(v)
	_sfx_value_label.text = "%d" % int(v)


func _cam():
	return target.get("camera_follow") if target != null else null


func _build_camera_controls(box: VBoxContainer) -> void:
	var checks := HBoxContainer.new()
	checks.add_theme_constant_override("separation", 24)
	box.add_child(checks)
	smoothing_check = _make_check("SmoothingCheck", TEXT_SMOOTHING)
	smoothing_check.toggled.connect(_on_smoothing_toggled)
	checks.add_child(smoothing_check)
	dynamic_check = _make_check("DynamicCheck", TEXT_DYNAMIC)
	dynamic_check.toggled.connect(_on_dynamic_toggled)
	checks.add_child(dynamic_check)
	_build_sfx_slider(checks)
	tuning_row = HBoxContainer.new()
	tuning_row.name = "TuningRow"
	tuning_row.add_theme_constant_override("separation", 8)
	box.add_child(tuning_row)
	set_min_button = _make_button("SetMinButton", TEXT_SET_MIN)
	set_min_button.pressed.connect(_on_set_min)
	tuning_row.add_child(set_min_button)
	min_label = _make_value_label("MinValue")
	tuning_row.add_child(min_label)
	set_max_button = _make_button("SetMaxButton", TEXT_SET_MAX)
	set_max_button.pressed.connect(_on_set_max)
	tuning_row.add_child(set_max_button)
	max_label = _make_value_label("MaxValue")
	tuning_row.add_child(max_label)
	refresh_camera_controls()
	var cam = _cam()
	if cam != null:
		cam.changed.connect(refresh_camera_controls)  # also when the saved options load


func _make_check(node_name: String, text: String) -> CheckBox:
	var c := CheckBox.new()
	c.name = node_name
	c.text = text
	c.add_theme_font_size_override("font_size", 16)
	c.add_theme_icon_override("unchecked", check_icon(false))
	c.add_theme_icon_override("checked", check_icon(true))
	c.add_theme_icon_override("unchecked_disabled", check_icon(false))
	c.add_theme_icon_override("checked_disabled", check_icon(true))
	return c


## A placeholder checkbox icon: a light square frame on a dark fill, with a
## light square inside when checked.
static func check_icon(checked: bool) -> ImageTexture:
	var n := CHECK_ICON_SIZE
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(CONTROL_FILL)
	for i in n:
		for j in [0, 1, n - 2, n - 1]:
			img.set_pixel(i, j, CONTROL_FRAME)
			img.set_pixel(j, i, CONTROL_FRAME)
	if checked:
		img.fill_rect(Rect2i(4, 4, n - 8, n - 8), CONTROL_FRAME)
	return ImageTexture.create_from_image(img)


## A placeholder button frame: a light border round a dark fill.
static func button_style(fill: Color, border: int = 2) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = fill
	st.border_color = CONTROL_FRAME
	st.set_border_width_all(border)
	st.content_margin_left = 10.0
	st.content_margin_right = 10.0
	st.content_margin_top = 2.0
	st.content_margin_bottom = 2.0
	return st


func _make_button(node_name: String, text: String) -> Button:
	var b := Button.new()
	b.name = node_name
	b.text = text
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_stylebox_override("normal", button_style(CONTROL_FILL))
	b.add_theme_stylebox_override("hover", button_style(CONTROL_FILL_HOVER))
	b.add_theme_stylebox_override("pressed", button_style(CONTROL_FILL_PRESSED))
	b.add_theme_stylebox_override("hover_pressed", button_style(CONTROL_FILL_PRESSED))
	var focus := button_style(Color(0, 0, 0, 0), 3)
	focus.draw_center = false
	focus.border_color = Color(1, 1, 1)
	b.add_theme_stylebox_override("focus", focus)
	return b


func _make_value_label(node_name: String) -> Label:
	var l := Label.new()
	l.name = node_name
	l.custom_minimum_size.x = 50.0
	l.add_theme_font_size_override("font_size", 16)
	return l


## Reads the saved options into the checkboxes and the stored min and max into
## the numbers, without applying anything.
func refresh_camera_controls() -> void:
	var cam = _cam()
	if cam == null:
		return
	smoothing_check.set_pressed_no_signal(cam.is_smoothing())
	dynamic_check.set_pressed_no_signal(cam.is_dynamic())
	tuning_row.visible = cam.is_dynamic()
	min_label.text = "%.1f" % cam.get_dynamic_min()
	max_label.text = "%.1f" % cam.get_dynamic_max()


func _on_smoothing_toggled(on: bool) -> void:
	_cam().set_smoothing(on)


func _on_dynamic_toggled(on: bool) -> void:
	_cam().set_dynamic(on)
	refresh_camera_controls()


func _on_set_min() -> void:
	_cam().set_dynamic_min_from_current()
	refresh_camera_controls()


func _on_set_max() -> void:
	_cam().set_dynamic_max_from_current()
	refresh_camera_controls()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION_PAUSE):
		toggle()
		get_viewport().set_input_as_handled()


func is_paused() -> bool:
	return get_tree().paused


## True while the level-up screen's choice is open (T-052): the pause is the
## level-up pause, and Escape must not end it.
func _choice_open() -> bool:
	var st = target.get("state") if target != null else null
	return st != null and st.has_method("is_waiting_for_choice") and st.is_waiting_for_choice()


func toggle() -> void:
	if _choice_open():
		return
	if get_tree().paused:
		resume()
	else:
		pause()


func pause() -> void:
	zoom_slider.set_value_no_signal(target.zoom)
	_update_value_label()
	refresh_camera_controls()
	get_tree().paused = true
	visible = true
	_camera_follows_while_paused(true)


func resume() -> void:
	_camera_follows_while_paused(false)
	get_tree().paused = false
	visible = false


## The camera normally updates in the physics step, which does not run while
## paused, so a zoom change would not show. While paused it updates every
## frame instead (T-093); resuming puts it back.
func _camera_follows_while_paused(on: bool) -> void:
	var cam = target.get("camera")
	if not (cam is Camera2D):
		return
	if on:
		_saved_cam = [cam.process_mode, cam.process_callback, cam.physics_interpolation_mode]
		cam.process_mode = Node.PROCESS_MODE_ALWAYS
		cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		cam.process_callback = Camera2D.CAMERA2D_PROCESS_IDLE
	elif not _saved_cam.is_empty():
		cam.process_mode = _saved_cam[0]
		cam.process_callback = _saved_cam[1]
		cam.physics_interpolation_mode = _saved_cam[2]
		_saved_cam = []


func _on_zoom_changed(v: float) -> void:
	target.set_zoom(v)
	GameSettingsScript.save_zoom(v)
	_update_value_label()
	if target.panel != null:
		target.panel.refresh()


func _update_value_label() -> void:
	_value_label.text = "%.1f" % zoom_slider.value


func _exit_tree() -> void:
	# Never leave the whole tree paused behind a removed screen.
	if get_tree() != null and get_tree().paused:
		get_tree().paused = false
