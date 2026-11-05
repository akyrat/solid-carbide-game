class_name SubsFlight
extends Control
## A few glowing dots flying from the car to the sub goal's gift when a trick pays subs
## (T-534; HUD and menus, Decisions, "Tricks fly to the gift icon"). A placeholder drawn in
## code. It is a child of the HUD's scaled area, so it works in HUD pixels and scales with
## the HUD; `to_point` is asked every frame, so it follows the gift when the player has moved
## it with the layout editor. It frees itself on arrival. Pausable.

signal arrived

var from := Vector2.ZERO
## Returns where to land (HUD pixels).
var to_point: Callable
var seconds := 0.4
var arc := 60.0
var dots := 5
var radius := 4.0
var color := Color(1, 0.9, 0.3)
var age := 0.0
var done := false
## Where the head of the flight is now (HUD pixels).
var head := Vector2.ZERO
## How far behind the head each following dot lags, in share of the flight.
const LAG := 0.06


func _init() -> void:
	name = "SubsFlight"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_PAUSABLE


func setup(start: Vector2, target: Callable, cfg: Dictionary) -> void:
	from = start
	head = start
	to_point = target
	seconds = maxf(float(cfg.get("seconds", seconds)), 0.01)
	arc = float(cfg.get("arc", arc))
	dots = maxi(int(cfg.get("dots", dots)), 1)
	radius = float(cfg.get("radius", radius))
	color = Color.html(str(cfg.get("color", "#ffe23a")))
	z_index = 20
	size = Vector2.ZERO


func point_at(t: float) -> Vector2:
	var to: Vector2 = to_point.call() if to_point.is_valid() else from
	var e := clampf(t, 0.0, 1.0)
	e = e * e * (3.0 - 2.0 * e)
	var mid := (from + to) / 2.0 + Vector2(0, -arc)
	return from.lerp(mid, e).lerp(mid.lerp(to, e), e)


func advance(dt: float) -> void:
	if done:
		return
	age += dt
	head = point_at(age / seconds)
	queue_redraw()
	if age >= seconds:
		done = true
		arrived.emit()
		queue_free()


func _draw() -> void:
	var t := age / seconds
	for i in dots:
		var p := point_at(t - LAG * i)
		var k := 1.0 - float(i) / dots
		var r := radius * (0.5 + 0.5 * k)
		draw_circle(p, r * 2.0, Color(color, 0.25 * k))
		draw_circle(p, r, Color(color, k))


func _process(dt: float) -> void:
	advance(dt)
