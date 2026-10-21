extends Node2D
## The health pickup's placeholder drawing (task T-220), in the isometric view's
## screen pixels: a small red canister with a white cross, standing on the
## ground with a dark outline. Drawn in code; T-221 swaps in the final art. The
## red is a canister red, not Redgull's red.

const CANISTER_COLOR := Color(0.88, 0.38, 0.14)
const CANISTER_SHADE := Color(0.66, 0.25, 0.10)
const CROSS_COLOR := Color(1.0, 1.0, 1.0)
const CAP_COLOR := Color(0.62, 0.66, 0.72)
const OUTLINE_COLOR := Color(0.05, 0.07, 0.12)
const SHADOW_COLOR := Color(0.02, 0.02, 0.05, 0.55)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _draw() -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var t := TAU * i / 16.0
		pts.append(Vector2(cos(t) * 6.0, sin(t) * 3.0))
	draw_colored_polygon(pts, SHADOW_COLOR)
	# Outline, body, shaded right side, cap.
	draw_rect(Rect2(-6, -15, 12, 14), OUTLINE_COLOR)
	draw_rect(Rect2(-5, -14, 10, 12), CANISTER_COLOR)
	draw_rect(Rect2(2, -14, 3, 12), CANISTER_SHADE)
	draw_rect(Rect2(-3, -18, 6, 4), OUTLINE_COLOR)
	draw_rect(Rect2(-2, -17, 4, 3), CAP_COLOR)
	# White cross.
	draw_rect(Rect2(-1, -12, 2, 8), CROSS_COLOR)
	draw_rect(Rect2(-3, -9, 6, 2), CROSS_COLOR)
