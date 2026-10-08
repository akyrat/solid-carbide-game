extends CanvasLayer
## The drift prototype's tuning panel (a playtest tool, not part of the game's
## UI). One slider per setting in CarTuning.SETTINGS plus the camera zoom, an
## isometric view toggle, a physics interpolation toggle, a live readout and a
## button that puts every slider back to its Unity value. Changes apply live.
## Tab opens and closes it (handled by the drift prototype scene).

const CarTuning := preload("res://scripts/driving/car_tuning.gd")

## The camera zoom slider (Unity prototype report, sections 7 and 8).
const ZOOM_SETTING := {"key": "camera_zoom", "name": "Camera zoom (orthographic size)", "unit": "units",
	"label": "How much of the world you see (half the screen height)",
	"tip": "Half the visible height in world units, as in Unity. 14.4 shows 28.8 units from top to bottom. Bigger = more of the world.",
	"min": 6.0, "max": 20.0, "step": 0.1}
const UNITY_ZOOM := 14.4

## The drift prototype scene this panel tunes.
var prototype: Node
## key -> HSlider, for every slider including "camera_zoom".
var sliders := {}
var _value_labels := {}
var view_toggle: CheckButton
var interpolation_toggle: CheckButton
var reset_button: Button
var readout: Label
var _root: PanelContainer


func setup(p: Node) -> void:
	prototype = p
	layer = 10
	_root = PanelContainer.new()
	_root.name = "TuningPanel"
	_root.anchor_left = 1.0
	_root.anchor_right = 1.0
	_root.anchor_bottom = 1.0
	_root.offset_left = -380.0
	_root.offset_right = -8.0
	_root.offset_top = 8.0
	_root.offset_bottom = -8.0
	add_child(_root)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_root.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)

	var title := Label.new()
	title.text = "Drift tuning (Tab to close)"
	box.add_child(title)
	readout = Label.new()
	readout.add_theme_font_size_override("font_size", 12)
	box.add_child(readout)

	reset_button = Button.new()
	reset_button.text = "Reset all to Unity values"
	reset_button.tooltip_text = "Puts every slider back to the value the Unity prototype uses, and turns physics interpolation off."
	reset_button.pressed.connect(reset_to_unity)
	box.add_child(reset_button)

	view_toggle = CheckButton.new()
	view_toggle.text = "Isometric view (V)"
	view_toggle.tooltip_text = "Draws the same flat world in a 2:1 isometric projection. Only the drawing changes: the car's position, speed and rotation stay the same."
	view_toggle.toggled.connect(func(on: bool) -> void: prototype.set_view("iso" if on else "flat"))
	box.add_child(view_toggle)

	interpolation_toggle = CheckButton.new()
	interpolation_toggle.text = "Physics interpolation"
	interpolation_toggle.tooltip_text = "Off (Unity's look): the car moves in 50 steps per second, so on a faster screen the world shifts in small steps. On: smoother motion between steps."
	interpolation_toggle.toggled.connect(func(on: bool) -> void: prototype.set_physics_interpolation(on))
	box.add_child(interpolation_toggle)

	_add_slider(box, ZOOM_SETTING, UNITY_ZOOM)
	for s in CarTuning.SETTINGS:
		_add_slider(box, s, prototype.car.tuning.get(s.key))
	refresh()


func _add_slider(box: VBoxContainer, s: Dictionary, value: float) -> void:
	var label := Label.new()
	label.text = s.label
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 300.0
	label.add_theme_font_size_override("font_size", 13)
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	var tip := "%s (Unity value %s %s).\n%s" % [s.name, _fmt(_unity_value(s.key), s.step), s.unit, s.tip]
	label.tooltip_text = tip
	box.add_child(label)
	var row := HBoxContainer.new()
	var slider := HSlider.new()
	slider.name = "Slider_" + s.key
	slider.min_value = s.min
	slider.max_value = s.max
	slider.step = s.step
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.tooltip_text = tip
	slider.focus_mode = Control.FOCUS_NONE
	var value_label := Label.new()
	value_label.custom_minimum_size.x = 60.0
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(slider)
	row.add_child(value_label)
	box.add_child(row)
	sliders[s.key] = slider
	_value_labels[s.key] = value_label
	slider.value_changed.connect(func(v: float) -> void: _on_slider(s.key, v))
	value_label.text = _fmt(value, s.step)


func _on_slider(key: String, v: float) -> void:
	if key == "camera_zoom":
		prototype.set_zoom(v)
	else:
		prototype.car.tuning.set(key, v)
	_value_labels[key].text = _fmt(v, sliders[key].step)


## Puts every slider and the setting behind it back to its Unity value, and
## turns physics interpolation off (Unity's car is not interpolated).
func reset_to_unity() -> void:
	prototype.car.tuning.reset_to_unity()
	prototype.set_zoom(UNITY_ZOOM)
	prototype.set_physics_interpolation(false)
	refresh()


## Moves every control to match the current values, without re-applying them.
func refresh() -> void:
	for key in sliders:
		var v: float = prototype.zoom if key == "camera_zoom" else prototype.car.tuning.get(key)
		sliders[key].set_value_no_signal(v)
		_value_labels[key].text = _fmt(v, sliders[key].step)
	view_toggle.set_pressed_no_signal(prototype.view == "iso")
	interpolation_toggle.set_pressed_no_signal(prototype.physics_interpolation)


func toggle() -> void:
	visible = not visible


func _process(_delta: float) -> void:
	if not visible or prototype == null:
		return
	var m = prototype.car.model
	readout.text = "Speed %.1f   forward %.1f   sideways %.1f\nDrift angle %.0f deg   drift amount %.2f" % [
		m.total_speed(), m.forward_speed(), m.sideways_speed(), m.drift_angle_deg(), m.drift_amount]


func _unity_value(key: String) -> float:
	if key == "camera_zoom":
		return UNITY_ZOOM
	return CarTuning.unity_values()[key]


static func _fmt(v: float, step: float) -> String:
	var decimals := 0
	var st := step
	while st < 0.999 and decimals < 4:
		st *= 10.0
		decimals += 1
	return String.num(v, decimals)
