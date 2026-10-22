class_name AirtimeCounter
extends Control
## The HUD's live airtime counter (task T-243; HUD and menus, Decisions,
## "Airtime counter"): while the car is airborne, a plain number with two
## decimals (seconds, no unit) counts the airtime up next to a small wing icon.
## It appears when the car leaves the ground and disappears on landing.
##
## It only shows: the car's airborne state (car_height.gd, as the aerial tricks
## read it, T-219) is fed in by Hud.bind_car(), one physics step at a time. The
## airtime is the sum of the steps spent in the air, which is what the airtime
## trick (T-242) pays out for.
##
## The icon is a placeholder drawn in code: white, black outline, never Redgull
## red. The number is in the comic font (Bangers). Its size, place and look are
## proposals for the playtest.

const FONT_SIZE := 30
const NUMBER_COLOR := Color(1.0, 1.0, 1.0)
const OUTLINE_COLOR := Color(0.0, 0.0, 0.0)
const ICON_SIZE := Vector2(30, 22)
const ICON_GAP := 6
## The wing's outline in a 30 x 22 box: feathers fanning up and to the right.
const WING_POINTS := [
	Vector2(1, 21), Vector2(3, 11), Vector2(9, 4), Vector2(18, 1), Vector2(16, 6),
	Vector2(25, 6), Vector2(20, 11), Vector2(29, 12), Vector2(21, 16), Vector2(13, 21),
]

## Seconds in the air so far in this jump.
var airtime := 0.0
var number_label: Label
var icon: Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon = _make_icon()
	icon.name = "Icon"
	icon.custom_minimum_size = ICON_SIZE
	icon.size = ICON_SIZE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)
	number_label = Label.new()
	number_label.name = "Number"
	number_label.text = airtime_text(0.0)
	number_label.add_theme_font_override("font", Hud.comic_font())
	number_label.add_theme_font_size_override("font_size", FONT_SIZE)
	number_label.add_theme_color_override("font_color", NUMBER_COLOR)
	number_label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	number_label.add_theme_constant_override("outline_size", 8)
	add_child(number_label)
	_layout()
	visible = false


## The placeholder icon; DriftCounter (T-247) overrides it with its own.
func _make_icon() -> Control:
	return _WingIcon.new()


## "1.25": two decimals, no unit.
static func airtime_text(seconds: float) -> String:
	return "%.2f" % seconds


## One physics step of `dt` seconds, ending airborne or not. Shows from the
## first airborne step, counts while it lasts, hides (and resets) on landing.
func step(airborne: bool, dt: float) -> void:
	if not airborne:
		stop()
		return
	airtime += dt
	number_label.text = airtime_text(airtime)
	visible = true
	_layout()


## Hides the counter and resets it (landing, a new run).
func stop() -> void:
	airtime = 0.0
	if number_label != null:
		number_label.text = airtime_text(0.0)
	visible = false


func _layout() -> void:
	var num := number_label.get_combined_minimum_size()
	number_label.size = num
	var h := maxf(num.y, ICON_SIZE.y)
	icon.position = Vector2(0, roundf((h - ICON_SIZE.y) / 2.0))
	number_label.position = Vector2(ICON_SIZE.x + ICON_GAP, roundf((h - num.y) / 2.0))
	size = Vector2(ICON_SIZE.x + ICON_GAP + num.x, h)


## The placeholder wing: a white shape with a black outline.
class _WingIcon extends Control:
	func _draw() -> void:
		var pts := PackedVector2Array(AirtimeCounter.WING_POINTS)
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, AirtimeCounter.OUTLINE_COLOR, 5.0)
		draw_colored_polygon(pts, AirtimeCounter.NUMBER_COLOR)
		draw_polyline(closed, AirtimeCounter.OUTLINE_COLOR, 2.0)
