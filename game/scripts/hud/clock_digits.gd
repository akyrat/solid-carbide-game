class_name ClockDigits
extends Control
## The run clock's digits in the drawn seven-segment art (T-429; Visual style,
## Decisions, "The HUD style sheet", rule 6): it shows its `source` label's text
## ("7:42") one frame per character, `clock_digit_<n>.png` and
## `clock_digit_colon.png` at 2x, tinted with the label's font colour (the time
## step's, data/hud.json timer_clock.steps), each digit over the unlit 8 in a
## darker shade of the same colour, like an LCD. Centred in its rect, whole
## screen pixels only. It only shows; the text and colour come from the label.
## Each frame is a TextureRect child (`glyphs`, in drawing order).

## The label whose text and font colour it shows.
var source: Label
## The frames shown now, back to front: per character the unlit 8 (digits only), then the character.
var glyphs: Array[TextureRect] = []
var _shown_text := ""
var _shown_color := Color(0, 0, 0, 0)
var _shown_size := Vector2.ZERO


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(_delta: float) -> void:
	refresh()


## The tint: the source label's font colour.
func digit_color() -> Color:
	if source == null:
		return HudStyle.WHITE
	return source.get_theme_color("font_color")


## The frame texture for one character, or null for one with no frame.
static func frame_for(ch: String) -> Texture2D:
	var key := ""
	if ch == ":":
		key = "colon"
	elif ch.length() == 1 and ch >= "0" and ch <= "9":
		key = ch
	else:
		return null
	return load(HudStyle.CLOCK_DIGIT_ART % key) as Texture2D


## The screen size of a text in the digit art: every character one frame wide.
static func text_size(text: String) -> Vector2:
	var f := Vector2(HudStyle.CLOCK_DIGIT_FRAME) * HudStyle.HUD_ART_SCALE
	return Vector2(f.x * text.length(), f.y)


## Where the text's top-left corner goes: centred, in whole pixels.
func text_origin(text: String) -> Vector2:
	return ((size - text_size(text)) / 2.0).floor()


## The unlit 8's shade of a tint: the same hue, darker, fully opaque.
static func off_color(c: Color) -> Color:
	var k := HudStyle.CLOCK_DIGIT_OFF_SHADE
	return Color(c.r * k, c.g * k, c.b * k, 1.0)


## Rebuilds the frames when the label's text, its colour or this rect's size changed.
func refresh() -> void:
	if source == null:
		return
	var c := digit_color()
	if source.text == _shown_text and c == _shown_color and size == _shown_size:
		return
	_shown_text = source.text
	_shown_color = c
	_shown_size = size
	for g in glyphs:
		g.queue_free()
	glyphs.clear()
	var frame := Vector2(HudStyle.CLOCK_DIGIT_FRAME) * HudStyle.HUD_ART_SCALE
	var at := text_origin(_shown_text)
	var off := load(HudStyle.CLOCK_DIGIT_ART % "off") as Texture2D
	for i in _shown_text.length():
		var ch := _shown_text[i]
		var pos := at + Vector2(frame.x * i, 0.0)
		if ch != ":" and off != null:
			_add_glyph(off, pos, frame, off_color(c))
		var tex := frame_for(ch)
		if tex != null:
			_add_glyph(tex, pos, frame, c)


func _add_glyph(tex: Texture2D, pos: Vector2, frame: Vector2, tint: Color) -> void:
	var g := TextureRect.new()
	g.texture = tex
	g.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g.stretch_mode = TextureRect.STRETCH_SCALE
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.position = pos
	g.size = frame
	g.self_modulate = tint
	add_child(g)
	glyphs.append(g)
