extends Node2D
## The coin's drawing (placeholder from T-044, final art from T-072), in the isometric view's screen
## pixels: a small gold coin standing on the ground with a dark outline and a
## pale shine, bobbing slightly. The final coin art comes from a separate art
## task. No Redgull red.

const COIN_TEXTURE := preload("res://art/effects/coin.png")
const FACE_COLOR := Color(1.0, 0.80, 0.25)
const EDGE_COLOR := Color(0.75, 0.52, 0.12)
const SHINE_COLOR := Color(1.0, 0.97, 0.75)
const OUTLINE_COLOR := Color(0.05, 0.07, 0.12)
const SHADOW_COLOR := Color(0.02, 0.02, 0.05, 0.55)

var _t := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(delta: float) -> void:
	_t = fmod(_t + delta, 1.2)
	queue_redraw()


func _draw() -> void:
	var bob := -6.0 - (1.0 if _t < 0.6 else 0.0)
	_ellipse(Vector2.ZERO, 4.0, 2.0, SHADOW_COLOR)
	# T-072: the final 10 x 12 coin art (art/effects/coin.png), bobbing like the placeholder.
	draw_texture(COIN_TEXTURE, Vector2(-5, bob - 6))


func _ellipse(c: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var t := TAU * i / 16.0
		pts.append(c + Vector2(cos(t) * rx, sin(t) * ry))
	draw_colored_polygon(pts, color)
