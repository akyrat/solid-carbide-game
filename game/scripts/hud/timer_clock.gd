class_name TimerClock
extends PanelContainer
## The run timer as a digital clock (T-335): a dark panel at the bottom left with
## glowing digits that go green, yellow, orange and red as the time nears 0:00.
## The switch points and the layout come from res://data/hud.json (timer_clock).
## It only shows: `label` holds the M:SS text, set by the HUD; `set_time_left()`
## picks the colour. Placeholder look drawn in code until the clock art (T-339).

const DIGIT_FONT_SIZE := 52
const PANEL_COLOR := Color(0.04, 0.05, 0.08, 0.92)
const PANEL_BORDER := Color(0.25, 0.28, 0.36)

var label: Label
var color_name := ""
var _steps: Array = []
var _layout: Dictionary = {}


func _init() -> void:
	var r := GameData.load_file("hud")
	var cfg: Dictionary = r.data["timer_clock"] if r.ok else {}
	_layout = cfg.get("layout", {"x": 16, "y": 560, "w": 200, "h": 72, "reference_w": 1152, "reference_h": 648})
	_steps = cfg.get("steps", [])
	name = "TimerClock"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL_COLOR
	box.border_color = PANEL_BORDER
	box.set_border_width_all(3)
	box.set_corner_radius_all(2)
	add_theme_stylebox_override("panel", box)
	# Anchored to the bottom-left corner, keeping its margins at other window sizes.
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	var ref_h: float = float(_layout["reference_h"])
	offset_left = float(_layout["x"])
	offset_right = offset_left + float(_layout["w"])
	offset_top = float(_layout["y"]) - ref_h
	offset_bottom = offset_top + float(_layout["h"])
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	label = Label.new()
	label.name = "Timer"
	label.text = "8:00"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", DIGIT_FONT_SIZE)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	label.add_theme_constant_override("outline_size", 6)
	add_child(label)
	set_time_left(480.0)


## The step for a time left: the first whose `above_seconds` the time is above;
## the last one (red) when none is.
func step_for(seconds_left: float) -> Dictionary:
	for s: Dictionary in _steps:
		if seconds_left > float(s["above_seconds"]):
			return s
	return _steps[_steps.size() - 1] if not _steps.is_empty() else {"name": "", "color": "#ffffff"}


func color_for(seconds_left: float) -> Color:
	return Color(String(step_for(seconds_left)["color"]))


func set_time_left(seconds_left: float) -> void:
	var s := step_for(seconds_left)
	color_name = String(s["name"])
	label.add_theme_color_override("font_color", Color(String(s["color"])))
