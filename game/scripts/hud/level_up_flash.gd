class_name LevelUpFlash
extends Control
## The likes bar's level-up animation (task T-139): when the run state says
## `level_up` the bar flashes white-hot as it "fills to the end", a burst of
## pixel sparks flies up off it, and "Hype Lv" pops bigger, goes white-hot,
## then settles back. Drawn in code, hard pixel edges, in the fire's whites,
## yellows and oranges (LikesFire.PALETTE), never Redgull red, no text of its
## own. It plays in pixel-art frames (ComboHeat.FLICKER_FRAME, twelve a
## second) and lasts FRAME_COUNT frames, 0.75 s.
##
## It runs while the game is paused (PROCESS_MODE_ALWAYS), so it plays the
## same whether the level-up pauses the run at once or the run keeps going.
## It only changes the bar's look on top (an overlay) and the level label's
## scale and colour; when it ends both are exactly as before, and the bar's
## value and the label's text are never touched (the Hud owns them).
##
## The Hud places this node over the likes bar and the space just above it
## (`place`), under the texts, so the new level number stays readable.

## One pixel of the effect is this many screen pixels.
const PIXEL := 2
## Frames in the animation; FRAME_COUNT * ComboHeat.FLICKER_FRAME seconds.
const FRAME_COUNT := 9
## How far above the bar's top edge the sparks reach, at most.
const MAX_UP := 24
const SPARKS := 16
## The bar's overlay per frame: [share of the width covered from the left
## (the bar "fills"), colour index in LikesFire.PALETTE (0 white-hot, 1
## yellow, 2 orange-yellow, 3 orange), optional stripe step: 1 or more means
## every n-th 4 px column is covered]. An empty entry shows no overlay.
const OVERLAY: Array = [
	[0.34, 0], [0.67, 0], [1.0, 0], [1.0, 0], [1.0, 1],
	[1.0, 1, 2], [1.0, 2, 4], [], [],
]
## "Hype Lv" scale per frame (it pops up and settles); white-hot before
## WHITE_UNTIL, yellow before YELLOW_UNTIL, then its normal colour.
const LABEL_SCALE: Array[float] = [1.15, 1.3, 1.3, 1.25, 1.2, 1.12, 1.06, 1.0, 1.0]
const WHITE_UNTIL := 4
const YELLOW_UNTIL := 7
## How far a spark has risen, as a share of its own reach, at each age.
const RISE: Array[float] = [0.25, 0.5, 0.7, 0.87, 1.0]

## True while the animation plays.
var playing := false
## The frame now showing (0 to FRAME_COUNT - 1) while playing.
var frame := 0
## Seconds into the animation.
var time := 0.0
## How many times it has started (tests count starts with it).
var plays := 0
var _level_label: Label


func _init() -> void:
	name = "LevelUpFlash"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visible = false
	set_process(false)


## The "Hype Lv" label it pops.
func setup(level_label: Label) -> void:
	_level_label = level_label


## Places the effect over a bar (its rectangle in the parent's coordinates).
func place(bar_rect: Rect2) -> void:
	position = Vector2(bar_rect.position.x, bar_rect.position.y - MAX_UP)
	size = Vector2(bar_rect.size.x, MAX_UP + bar_rect.size.y)
	queue_redraw()


## Total length in seconds.
static func length() -> float:
	return FRAME_COUNT * ComboHeat.FLICKER_FRAME


## Starts (or restarts, when levels come in a row) the animation.
func start() -> void:
	playing = true
	time = 0.0
	frame = 0
	plays += 1
	visible = true
	set_process(true)
	_apply()
	queue_redraw()


## Stops it at once and leaves the label as it always is.
func stop() -> void:
	playing = false
	visible = false
	set_process(false)
	_restore_label()
	queue_redraw()


func _process(delta: float) -> void:
	advance(delta)


## Moves the animation on by `delta` seconds (tests call it directly).
func advance(delta: float) -> void:
	if not playing:
		return
	time += delta
	var f := int(floorf(time / ComboHeat.FLICKER_FRAME))
	if f >= FRAME_COUNT:
		stop()
		return
	if f != frame:
		frame = f
		_apply()
		queue_redraw()


func _apply() -> void:
	if _level_label == null:
		return
	var s := LABEL_SCALE[frame]
	_level_label.scale = Vector2(s, s)
	if frame < WHITE_UNTIL:
		_level_label.add_theme_color_override("font_color", LikesFire.PALETTE[0])
	elif frame < YELLOW_UNTIL:
		_level_label.add_theme_color_override("font_color", LikesFire.PALETTE[1])
	else:
		_level_label.add_theme_color_override("font_color", Hud.LABEL_COLOR)


func _restore_label() -> void:
	if _level_label == null:
		return
	_level_label.scale = Vector2.ONE
	_level_label.add_theme_color_override("font_color", Hud.LABEL_COLOR)


## The bar overlay's [Rect2, Color] pairs (this node's coordinates) at a
## frame: a partial or full cover, or stripes.
func overlay_rects(f: int) -> Array:
	var out: Array = []
	var spec: Array = OVERLAY[f]
	if spec.is_empty():
		return out
	var bar := Rect2(0, MAX_UP, size.x, size.y - MAX_UP)
	var w := floorf(bar.size.x * float(spec[0]) / PIXEL) * PIXEL
	var colour: Color = LikesFire.PALETTE[int(spec[1])]
	if spec.size() == 2:
		out.append([Rect2(bar.position, Vector2(w, bar.size.y)), colour])
		return out
	var step: int = int(spec[2])
	var half := 2 * PIXEL
	var x := 0.0
	var i := 0
	while x < w:
		if i % step == 0:
			out.append([Rect2(x, bar.position.y, minf(half, w - x), bar.size.y), colour])
		x += half
		i += 1
	return out


## The sparks showing at a frame: [Rect2, Color] pairs, all above the bar's
## top edge and within MAX_UP of it.
func spark_rects(f: int) -> Array:
	var out: Array = []
	var top := float(MAX_UP)
	for k in SPARKS:
		var born := 1 + int(_hash(k * 3 + 1) * 3.0)
		var age := f - born
		if age < 0 or age >= RISE.size():
			continue
		var reach := (0.6 + 0.4 * _hash(k * 3 + 2)) * MAX_UP
		var rise := int(roundf(reach * RISE[age] / PIXEL)) * PIXEL
		var px := PIXEL * 3 if age < 3 else PIXEL * 2
		var x := floorf(_hash(k * 3 + 3) * (size.x - px) / PIXEL) * PIXEL
		var y := maxf(top - rise - px, 0.0)
		var c: Color = LikesFire.PALETTE[mini(age, 3)]
		out.append([Rect2(x, y, px, px), c])
	return out


func _draw() -> void:
	if not playing:
		return
	for r in overlay_rects(frame):
		draw_rect(r[0], r[1])
	for r in spark_rects(frame):
		draw_rect(r[0], r[1])


## Every colour the effect draws (for the not-red tests).
static func all_colors() -> Array[Color]:
	var cs: Array[Color] = LikesFire.all_colors()
	cs.append(Hud.LABEL_COLOR)
	return cs


static func _hash(n: int) -> float:
	return fposmod(sin(n * 12.9898 + 78.233) * 43758.5453, 1.0)
