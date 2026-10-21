extends Node2D
## The health pickup's drawing (placeholder from T-220, final art from T-221), in the
## isometric view's screen pixels: a small red gas canister with a white cross lying
## on the ground, a 14 x 10 sprite (art/effects/health_canister.png, about a coin's
## size) built by tools/build_health_canister.py from the board-approved PixelLab
## sample. The red is a canister red, not Redgull's red.

const CANISTER_TEXTURE := preload("res://art/effects/health_canister.png")
const SHADOW_COLOR := Color(0.02, 0.02, 0.05, 0.55)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _draw() -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var t := TAU * i / 16.0
		pts.append(Vector2(cos(t) * 6.0, sin(t) * 3.0))
	draw_colored_polygon(pts, SHADOW_COLOR)
	# Lying on the ground: the sprite's bottom edge is a pixel above the shadow's centre.
	draw_texture(CANISTER_TEXTURE, Vector2(-7, -10))
