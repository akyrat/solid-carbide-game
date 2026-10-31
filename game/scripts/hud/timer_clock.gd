class_name TimerClock
extends PanelContainer
## The run timer as a digital clock (T-335): a dark panel at the bottom left with
## glowing digits that go green, yellow, orange and red as the time nears 0:00.
## The switch points and the layout come from res://data/hud.json (timer_clock).
## It only shows: `label` holds the M:SS text, set by the HUD; `set_time_left()`
## picks the colour.
##
## The look follows the HUD style sheet (T-429; Visual style, Decisions, "The HUD
## style sheet", rules 1, 4 and 6): the panel is the clock panel art
## (`clock_panel.png`, 100 x 36 at 2x, exactly the layout's 200 x 72), and the
## digits are the drawn seven-segment frames (`clock_digits.png` cut into
## `clock_digit_*.png`, 16 x 26 at 2x), tinted with the step's colour over the
## dim unlit 8. `label` stays (the HUD and the tests read its text and colour)
## but draws nothing: `digits` draws its text.

## The look is HudStyle's (T-428, T-429): "clock_digits" and the clock art.
const DIGIT_FONT_SIZE := HudStyle.CLOCK_FONT_SIZE

var label: Label
## The control that draws `label`'s text in the digit art.
var digits: ClockDigits
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
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_theme_stylebox_override("panel", HudStyle.clock_panel_box())
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
	HudStyle.apply(label, "clock_digits")
	# Visible (so it is in the tree's layout) but drawn by `digits` instead.
	label.self_modulate = Color(1, 1, 1, 0)
	add_child(label)
	digits = ClockDigits.new()
	digits.name = "Digits"
	digits.source = label
	add_child(digits)
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
	# The colour is data (hud.json timer_clock.steps), not style.
	label.add_theme_color_override("font_color", color_for(seconds_left))
	if digits != null:
		digits.refresh()
