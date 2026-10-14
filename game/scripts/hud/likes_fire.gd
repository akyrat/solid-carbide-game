class_name LikesFire
extends Control
## Pixel flames along the HUD's likes bar (task T-131), shown at the combo's
## top heat step (ComboHeat.FIRE_STEP, from x4). Drawn in code, in hard-edged
## pixels: each column of the flame is a stack of square pixels (white-hot at
## the bottom, then yellow, then orange at the tip) whose height flickers in
## pixel-art frames. Never Redgull red.
##
## The Hud places this node over the likes bar and the space just above it,
## and tells it how full the bar is (`fill_ratio`) and where the "Likes" and
## "Hype Lv" texts are (`low_spans`): the flames rise tallest over the filled
## part of the bar and in the gap between the two texts, stay low over the
## empty part, and only lick the bottom of the texts, which are drawn on top,
## so the fill and the texts stay readable. Pausable: it stops moving while
## the game is paused.

## One flame pixel is this many screen pixels.
const PIXEL := 2
## How far down into the bar the flames reach (screen pixels from the bar's
## top edge), leaving the rest of the bar's fill clear.
const INTO_BAR := 4
## Tallest flames, in screen pixels above the bar's top edge: over the filled
## part in the open, under the texts, and over the empty part.
const MAX_HEIGHT := 26
const TEXT_HEIGHT := 8
const EMPTY_HEIGHT := 4
## Flames only; index 0 is the hottest (bottom), the last the tip.
const PALETTE: Array[Color] = [
	Color(1.0, 0.98, 0.82),  # white-hot
	Color(1.0, 0.88, 0.3),   # yellow
	Color(1.0, 0.72, 0.16),  # orange-yellow
	Color(1.0, 0.6, 0.08),   # orange
]

var burning := false:
	set(value):
		if burning == value:
			return
		burning = value
		visible = value
		queue_redraw()
## How full the likes bar is, 0 to 1.
var fill_ratio := 0.0:
	set(value):
		fill_ratio = clampf(value, 0.0, 1.0)
		queue_redraw()
## Horizontal spans (x from, x to, in this node's coordinates) under the texts
## where the flames stay low.
var low_spans: Array[Vector2] = []
## Seconds of animation; stands still while the game is paused.
var time := 0.0
## The animation frame last drawn (ComboHeat.FLICKER_FRAME long each).
var frame := 0


func _init() -> void:
	name = "LikesFire"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_PAUSABLE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visible = false


## Places the fire over a bar (its rectangle in the parent's coordinates).
func place(bar_rect: Rect2) -> void:
	position = Vector2(bar_rect.position.x, bar_rect.position.y - MAX_HEIGHT)
	size = Vector2(bar_rect.size.x, MAX_HEIGHT + INTO_BAR)
	queue_redraw()


func _process(delta: float) -> void:
	time += delta
	var f := int(floorf(time / ComboHeat.FLICKER_FRAME))
	if f != frame:
		frame = f
		if burning:
			queue_redraw()


## The flame's height in screen pixels above the bar for column `i`.
func column_height(i: int) -> int:
	var x := (i + 0.5) * PIXEL
	var top := MAX_HEIGHT
	if x > fill_ratio * size.x:
		top = EMPTY_HEIGHT
	for s in low_spans:
		if x >= s.x and x <= s.y:
			top = mini(top, TEXT_HEIGHT)
	var t := frame * ComboHeat.FLICKER_FRAME
	# Broad tongues that sway along the bar, each with a ragged tip that
	# jumps from frame to frame.
	var tongue := 0.5 + 0.5 * sin(i * 0.42 + t * 6.0 + sin(i * 0.13 - t * 2.3) * 2.0)
	var n := 0.15 + 0.7 * pow(tongue, 1.6) + 0.15 * _hash(i * 13 + frame * 101)
	var h := top * (0.25 + 0.75 * clampf(n, 0.0, 1.0))
	return int(roundf(h / PIXEL)) * PIXEL


## A spark (one orange pixel) floats above column `i` in this frame.
func has_spark(i: int) -> bool:
	return _hash(i * 31 + frame * 7) < 0.06


func _draw() -> void:
	if not burning:
		return
	var columns := int(size.x / PIXEL)
	var base := MAX_HEIGHT + INTO_BAR  # the flames' bottom, in this node's y
	for i in columns:
		var h := column_height(i) + INTO_BAR
		var rows := h / PIXEL
		for j in rows:
			var frac := float(j) / maxf(rows, 1)
			var c := PALETTE[mini(int(frac * PALETTE.size()), PALETTE.size() - 1)]
			draw_rect(Rect2(i * PIXEL, base - (j + 1) * PIXEL, PIXEL, PIXEL), c)
		if has_spark(i):
			var y := base - h - PIXEL * (2 + int(_hash(i + frame) * 3.0))
			if y >= 0:
				draw_rect(Rect2(i * PIXEL, y, PIXEL, PIXEL), PALETTE[PALETTE.size() - 1])


## Every colour the fire draws (for the not-red tests).
static func all_colors() -> Array[Color]:
	return PALETTE.duplicate()


static func _hash(n: int) -> float:
	return fposmod(sin(n * 12.9898 + 78.233) * 43758.5453, 1.0)
