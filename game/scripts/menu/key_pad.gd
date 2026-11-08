class_name KeyPad
extends Control
## The live key pad (task T-491): a small W A S D pad in a clip's bottom-right corner. Each key is
## lit while the clip's key timeline (ClipPlayer.held_keys, T-490's keys_per_frame) says it is held,
## in step with the clip's frame; a lit key is drawn in the blush colour and pressed down a little.
## `KeyPad.attach(player, key_size)` adds one to a ClipPlayer. Look: the HUD style's keycaps (the
## tutorial slides' KEY_FACE / KEY_EDGE / BLUSH colours).

const FACE := Color("33384f")
const DIM_INK := Color("8a8eaa")
const EDGE := Color("1f2336")
const LIT_FACE := Color("f6c9de")
const LIT_EDGE := Color("b77b98")
const INK := Color("0d0d1b")
const FONT_PATH := "res://fonts/press_start_2p/PressStart2P-Regular.ttf"
## The pad's keys: the letter and its cell (column, row) in the 3 x 2 grid.
const KEYS := {"W": Vector2i(1, 0), "A": Vector2i(0, 1), "S": Vector2i(1, 1), "D": Vector2i(2, 1)}
## T-574 tweak 9 (the practice windows' live keys): the same pad with a Space bar under the three,
## as on a keyboard. SPACE ("_") in `held` lights it. No R keycap (T-597).
const SPACE := "_"

var key_size := 24.0
var margin := 8.0
var player: ClipPlayer
var held := ""
## The keys drawn (KEYS) and whether a Space bar is drawn under them (T-574).
var keys: Dictionary = KEYS
var space_bar := false
## A font to draw the letters in instead of the pixel font (the practice pad uses the HUD's comic
## font: in the practice window's viewport the pixel font drew its glyphs as solid boxes, T-574).
var font_override: Font


## A pad that is not tied to a clip (T-574): W, A, S, D and Space, lit by set_held().
static func full(key_px := 24.0) -> KeyPad:
	var pad := KeyPad.new()
	pad.name = "KeyPad"
	pad.key_size = key_px
	pad.space_bar = true
	pad.font_override = HudStyle.comic_font()
	pad.size = pad.pad_size()
	return pad


## Lights the keys in `now` ("WA", "_" for Space), for a pad with no clip.
func set_held(now: String) -> void:
	if now != held:
		held = now
		queue_redraw()


func set_key_size(px: float) -> void:
	key_size = px
	size = pad_size()
	queue_redraw()


## Adds a pad to the bottom-right corner of `clip_player` and returns it.
static func attach(clip_player: ClipPlayer, key_px := 24.0) -> KeyPad:
	var pad := KeyPad.new()
	pad.name = "KeyPad"
	pad.key_size = key_px
	pad.margin = maxf(4.0, key_px / 3.0)
	clip_player.add_child(pad)
	pad.bind(clip_player)
	return pad


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func bind(clip_player: ClipPlayer) -> void:
	player = clip_player
	player.frame_changed.connect(refresh)
	player.resized.connect(_place)
	_place()
	refresh()


## The keys lit now, as a sorted string ("AS").
func lit_keys() -> String:
	var letters: Array = []
	for k in keys:
		if held.contains(k):
			letters.append(k)
	letters.sort()
	return "".join(letters)


func is_lit(letter: String) -> bool:
	return held.contains(letter)


func refresh() -> void:
	var now := player.held_keys() if player != null else ""
	if now != held:
		held = now
		queue_redraw()


func pad_size() -> Vector2:
	var gap := maxf(2.0, key_size / 8.0)
	var rows := 3 if space_bar else 2
	return Vector2(key_size * 3 + gap * 2, key_size * rows + gap * (rows - 1))


func _place() -> void:
	size = pad_size()
	if player != null:
		position = player.size - size - Vector2(margin, margin)
	queue_redraw()


func _draw() -> void:
	var gap := maxf(2.0, key_size / 8.0)
	var depth := maxf(2.0, key_size / 8.0)
	var font: Font = font_override if font_override != null else load(FONT_PATH)
	var fs := int(key_size * (0.62 if font_override != null else 0.45))
	var caps: Array = []
	for letter in keys:
		var cell: Vector2i = keys[letter]
		caps.append([letter, Vector2(cell.x * (key_size + gap), cell.y * (key_size + gap)), key_size, letter])
	if space_bar:  # T-574: the Space bar, the pad's width, on a third row
		caps.append([SPACE, Vector2(0, 2 * (key_size + gap)), key_size * 3 + gap * 2, "SPACE"])
	for cap in caps:
		var letter: String = cap[0]
		var origin: Vector2 = cap[1]
		var w: float = cap[2]
		var lit := held.contains(letter)
		var rect := Rect2(origin, Vector2(w, key_size))
		# The key's solid edge (its drop), then the face; a lit key sits down onto its edge.
		draw_rect(rect, LIT_EDGE if lit else EDGE)
		var down := 2.0 if lit else 0.0
		var face := Rect2(origin + Vector2(0, down), Vector2(w, key_size - depth))
		draw_rect(face, LIT_FACE if lit else FACE)
		var shown: String = cap[3]
		var ts := font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_string(font, face.position + Vector2((w - ts.x) / 2.0, (face.size.y + ts.y * 0.7) / 2.0),
			shown, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK if lit else DIM_INK)
