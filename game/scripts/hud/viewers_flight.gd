class_name ViewersFlight
extends Control
## A trick's "+12K" with the viewers' eye, flying from its popup into the live viewers
## counter (T-336). It leaves the popup at `from` (HUD pixels), flies on an arc over
## `seconds`, speeding up as it goes and shrinking a little, and sends `arrived` when
## it reaches the counter's number, then frees itself. Pausable.

signal arrived

const FONT_SIZE := 30
const EYE_PATH := "res://art/hud/eye_icon.png"
const EYE_GAP := 3
## The scale at the end of the flight.
const END_SCALE := 0.85

var gain := 0.0
var from := Vector2.ZERO
## Returns where to land (HUD pixels); asked every frame, so it follows the counter.
var to_point: Callable
var seconds := 0.55
var arc := 90.0
var age := 0.0
var done := false
var label: Label
var eye: TextureRect


func _init() -> void:
	name = "ViewersFlight"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_PAUSABLE
	top_level = true


func setup(text: String, color: Color, start: Vector2, target: Callable, flight_seconds: float, flight_arc: float) -> void:
	from = start
	to_point = target
	seconds = maxf(flight_seconds, 0.01)
	arc = flight_arc
	label = Label.new()
	label.name = "Amount"
	label.text = text
	label.add_theme_font_override("font", Hud.comic_font())
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", ViewersCounter.DARK)
	label.add_theme_constant_override("outline_size", 6)
	label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(label)
	var ls := label.get_combined_minimum_size()
	label.size = ls
	var tex: Texture2D = load(EYE_PATH)
	eye = TextureRect.new()
	eye.name = "Eye"
	eye.texture = tex
	eye.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	eye.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	eye.stretch_mode = TextureRect.STRETCH_SCALE
	eye.mouse_filter = Control.MOUSE_FILTER_IGNORE
	eye.size = tex.get_size() * 2  # 2x, like the counter's eye: about the letters' height
	eye.position = Vector2(ls.x + EYE_GAP, floorf((ls.y - eye.size.y) / 2.0))
	add_child(eye)
	size = Vector2(eye.position.x + eye.size.x, ls.y)
	pivot_offset = size / 2.0
	_place()


## Where the flight is at `t` (0 to 1): an arc from `from` to the counter, rising
## by `arc` pixels at its middle, eased in so it speeds up into the counter.
func point_at(t: float) -> Vector2:
	var to: Vector2 = to_point.call() if to_point.is_valid() else from
	var e := t * t
	var mid := (from + to) / 2.0 + Vector2(0, -arc)
	var a := from.lerp(mid, e)
	var b := mid.lerp(to, e)
	return a.lerp(b, e)


func _place() -> void:
	var t := clampf(age / seconds, 0.0, 1.0)
	var s := lerpf(1.0, END_SCALE, t)
	scale = Vector2(s, s)
	position = (point_at(t) - size / 2.0).round()


func advance(dt: float) -> void:
	if done:
		return
	age += dt
	_place()
	if age >= seconds:
		done = true
		arrived.emit()
		queue_free()


func _process(dt: float) -> void:
	advance(dt)
