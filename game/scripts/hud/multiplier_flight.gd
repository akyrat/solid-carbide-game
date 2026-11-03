class_name MultiplierFlight
extends Control
## A trick's "+x0.5", flying from its popup into the multiplier beside the car (T-336, T-514). It leaves the popup at `from` (HUD pixels), flies on an arc over
## `seconds`, speeding up as it goes and shrinking a little, and sends `arrived` when
## it reaches the counter's number, then frees itself. Pausable.

signal arrived

const FONT_SIZE := HudStyle.MULTIPLIER_FLIGHT_SIZE
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
## The HUD's scale (T-431): the flight is top level, in screen pixels, so it is drawn at the
## HUD's scale itself, and its arc grows with it.
var base_scale := 1.0
var label: Label


func _init() -> void:
	name = "MultiplierFlight"
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
	HudStyle.apply(label, "multiplier_flight", color)
	label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(label)
	var ls := label.get_combined_minimum_size()
	label.size = ls
	size = ls
	pivot_offset = size / 2.0
	_place()


## Where the flight is at `t` (0 to 1): an arc from `from` to the counter, rising
## by `arc` pixels at its middle, eased in so it speeds up into the counter.
func point_at(t: float) -> Vector2:
	var to: Vector2 = to_point.call() if to_point.is_valid() else from
	var e := t * t
	var mid := (from + to) / 2.0 + Vector2(0, -arc * base_scale)
	var a := from.lerp(mid, e)
	var b := mid.lerp(to, e)
	return a.lerp(b, e)


func _place() -> void:
	var t := clampf(age / seconds, 0.0, 1.0)
	var s := lerpf(1.0, END_SCALE, t) * base_scale
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
	if Perf.on: Perf.each_begin(&"hud.multiplier_flight")
	advance(dt)
	if Perf.on: Perf.each_end(&"hud.multiplier_flight")
