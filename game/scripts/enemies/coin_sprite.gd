extends Node2D
## The coin's placeholder drawing (task T-044), in the isometric view's screen
## pixels: a small gold coin standing on the ground with a dark outline and a
## pale shine, bobbing slightly. The final coin art comes from a separate art
## task. No Redgull red.

const FACE_COLOR := Color(1.0, 0.80, 0.25)
const EDGE_COLOR := Color(0.75, 0.52, 0.12)
const SHINE_COLOR := Color(1.0, 0.97, 0.75)
const OUTLINE_COLOR := Color(0.05, 0.07, 0.12)
const SHADOW_COLOR := Color(0.02, 0.02, 0.05, 0.55)

var _t := 0.0


func _process(delta: float) -> void:
	_t = fmod(_t + delta, 1.2)
	queue_redraw()


func _draw() -> void:
	var bob := -6.0 - (1.0 if _t < 0.6 else 0.0)
	_ellipse(Vector2.ZERO, 4.0, 2.0, SHADOW_COLOR)
	var c := Vector2(0, bob)
	_ellipse(c, 4.5, 5.5, OUTLINE_COLOR)
	_ellipse(c, 3.5, 4.5, EDGE_COLOR)
	_ellipse(c + Vector2(-0.5, 0), 2.5, 3.5, FACE_COLOR)
	draw_rect(Rect2(c + Vector2(-2, -3), Vector2(1, 2)), SHINE_COLOR)


func _ellipse(c: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var t := TAU * i / 16.0
		pts.append(c + Vector2(cos(t) * rx, sin(t) * ry))
	draw_colored_polygon(pts, color)
