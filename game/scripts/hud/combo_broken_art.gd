class_name ComboBrokenArt
extends RefCounted
## Bakes the combo broken popup (task T-245): the trick popups' card in a
## warning red, cracked in two along a jagged line. Two images of the same
## size, the left half and the right half, so the popup can shake at birth and
## let the right half fall away (TrickPopups.PopupText, `broken`). Letters are
## white with a black outline; the card has a black border; the crack runs
## through the lettering. Hard pixel edges, opaque or fully transparent pixels
## only, a transparent rim. The red is a warning red-orange, clear of
## the HUD heart's Redgull red (RED_CLEARANCE, tested).

const Art := preload("res://scripts/hud/trick_popup_art.gd")

const NONE := 0
const LETTER := 1
const OUTLINE := 2
const CARD := 3
const BORDER_COLOR := 4
const PALETTE := [
	Color(0, 0, 0, 0),
	Color8(255, 255, 255),  # letters
	Color8(0, 0, 0),        # letter outline
	Color8(255, 80, 16),    # card: warning red-orange
	Color8(0, 0, 0),        # border and crack edges
]
## Least colour distance from the HUD heart's Redgull red.
const RED_CLEARANCE := 0.2
## The card's border width and the crack's gap (popup pixels).
const BORDER := 2
const GAP := 4
## The crack's x offsets from the card's middle, one per CRACK_STEP rows, repeating.
const CRACK := [0, 3, -2, 4, 0, -3, 2, -4]
const CRACK_STEP := 3
## Motion (drawn pixels, seconds): the shake at birth, the right half's fall.
const SHAKE_TIME := 0.3
const SHAKE_PX := 1.5
const FALL_DELAY := 0.08
const FALL_PX := 70.0
const FALL_DRIFT := 6.0

static var _cache := {}


## [left, right] textures for `text` at a size style; cached.
static func textures(text: String, style: String) -> Array:
	var key := "%s|%s" % [style, text]
	if not _cache.has(key):
		var imgs := bake(text, style)
		_cache[key] = [ImageTexture.create_from_image(imgs[0]), ImageTexture.create_from_image(imgs[1])]
	return _cache[key]


## The crack's x (popup pixels) on row `y` of a card `w` wide.
static func crack_x(w: int, y: int) -> int:
	return w / 2 + CRACK[(y / CRACK_STEP) % CRACK.size()]


## [left, right] RGBA images, the same size, opaque or fully transparent pixels only.
static func bake(text: String, style: String) -> Array:
	var letters := Art._letter(text, style)
	var tw: int = letters.w
	var th: int = letters.h
	var w := tw + 2 * Art.MARGIN_X
	var h := th + 2 * Art.MARGIN_Y
	var idx := PackedByteArray()
	idx.resize(w * h)
	# Card: border ring, then the red fill (same stepped corners as the plain popup).
	Art._fill_round_rect(idx, w, 0, 0, w, h, 1, Art.CORNER, BORDER_COLOR)
	Art._fill_round_rect(idx, w, 0, 0, w, h, 1 + BORDER, Art.CORNER - BORDER, CARD)
	var ox := (w - tw) / 2
	var oy := (h - th) / 2
	var li: PackedByteArray = letters.idx
	for y in th:
		for x in tw:
			if li[y * tw + x] != NONE:
				idx[(oy + y) * w + ox + x] = LETTER
	# A black outline round the letters, over the red only.
	var add: Array[int] = []
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			if idx[y * w + x] != CARD:
				continue
			if idx[y * w + x - 1] == LETTER or idx[y * w + x + 1] == LETTER \
					or idx[(y - 1) * w + x] == LETTER or idx[(y + 1) * w + x] == LETTER:
				add.append(y * w + x)
	for i in add:
		idx[i] = OUTLINE
	var left := idx.duplicate()
	var right := idx.duplicate()
	for y in h:
		var cx := crack_x(w, y)
		for x in w:
			var i := y * w + x
			if x >= cx + GAP:
				left[i] = NONE
			elif x < cx:
				right[i] = NONE
			else:  # the gap
				left[i] = NONE
				right[i] = NONE
			# The cut edges get the border colour (over the red only).
			if x < cx and x >= cx - BORDER and left[i] == CARD:
				left[i] = BORDER_COLOR
			if x >= cx + GAP and x < cx + GAP + BORDER and right[i] == CARD:
				right[i] = BORDER_COLOR
	return [_to_image(left, w, h), _to_image(right, w, h)]


static func _to_image(idx: PackedByteArray, w: int, h: int) -> Image:
	var data := PackedByteArray()
	data.resize(w * h * 4)
	for i in w * h:
		var col: Color = PALETTE[idx[i]]
		data[i * 4] = int(round(col.r * 255.0))
		data[i * 4 + 1] = int(round(col.g * 255.0))
		data[i * 4 + 2] = int(round(col.b * 255.0))
		data[i * 4 + 3] = 255 if idx[i] != NONE else 0
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)
