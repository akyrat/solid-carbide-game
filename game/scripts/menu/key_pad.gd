class_name KeyPad
extends Control
## The live key pad (task T-491): a small W A S D pad in a clip's bottom-right corner. Each key is
## lit while the clip's key timeline (ClipPlayer.held_keys, T-490's keys_per_frame) says it is held,
## in step with the clip's frame; a lit key is drawn in the blush colour and pressed down a little.
## `KeyPad.attach(player, key_size)` adds one to a ClipPlayer. Look: the HUD style's keycaps (the
## tutorial slides' KEY_FACE / KEY_EDGE / BLUSH colours).

const FACE := Color("e9e8f2")
const EDGE := Color("8f93ab")
const LIT_FACE := Color("f6c9de")
const LIT_EDGE := Color("b77b98")
const INK := Color("0d0d1b")
const FONT_PATH := "res://fonts/press_start_2p/PressStart2P-Regular.ttf"
## The pad's keys: the letter and its cell (column, row) in the 3 x 2 grid.
const KEYS := {"W": Vector2i(1, 0), "A": Vector2i(0, 1), "S": Vector2i(1, 1), "D": Vector2i(2, 1)}

var key_size := 24.0
var margin := 8.0
var player: ClipPlayer
var held := ""


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
	for k in KEYS:
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
	return Vector2(key_size * 3 + gap * 2, key_size * 2 + gap)


func _place() -> void:
	size = pad_size()
	if player != null:
		position = player.size - size - Vector2(margin, margin)
	queue_redraw()


func _draw() -> void:
	var gap := maxf(2.0, key_size / 8.0)
	var depth := maxf(2.0, key_size / 8.0)
	var font: Font = load(FONT_PATH)
	var fs := int(key_size * 0.45)
	for letter in KEYS:
		var cell: Vector2i = KEYS[letter]
		var lit := held.contains(letter)
		var origin := Vector2(cell.x * (key_size + gap), cell.y * (key_size + gap))
		var rect := Rect2(origin, Vector2(key_size, key_size))
		# The key's solid edge (its drop), then the face; a lit key sits down onto its edge.
		draw_rect(rect, LIT_EDGE if lit else EDGE)
		var down := depth * 0.7 if lit else 0.0
		var face := Rect2(origin + Vector2(0, down), Vector2(key_size, key_size - depth))
		draw_rect(face, LIT_FACE if lit else FACE)
		var ts := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_string(font, face.position + Vector2((key_size - ts.x) / 2.0, (face.size.y + ts.y * 0.7) / 2.0),
			letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
