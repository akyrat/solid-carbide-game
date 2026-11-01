class_name TrickPopupArt
extends RefCounted
## Bakes the comic-style trick popups (task T-084): one hard-edged pixel image
## per text and size, a white rounded rectangle sized to fit the lettering, the text
## in Bangers (res://fonts/bangers/, SIL OFL 1.1) with smoothing off.
##
## Look (the board's playtest, 2026-10-13): a real comic popup. A white rounded
## rectangle (stepped corners) with a black border, every letter black (trick name and amount alike) in
## Bangers on one straight baseline, hard pixel edges, no semi-transparent
## pixels, not the heart's red. Black on white reads on the dark asphalt and on the
## dusty gravel alike, since the black border separates the burst from both.
## One popup pixel is shown as 2 art pixels (TrickPopups.PIXEL_SCALE). Baked
## once per text and size and cached.
##
## Heat (task T-133): the popups follow the combo's heat steps (ComboHeat,
## task T-131). `heat` 0 (below x2) is the look above, unchanged. From step 1
## the black border becomes a thin black outline round coloured rings, and the
## image grows by the rings' extra width (the white fill, the padding and the
## letters stay as they are): step 1 (x2) a yellow ring; step 2 (x3)
## a wider orange ring with a yellow inner ring, and the "+amount" in orange
## with a black outline; step 3 (x4 up) step 2's look plus a flaming edge of
## pixel flames in the likes bar fire's colours and style (LikesFire), baked
## in FLAME_FRAMES frames that the popup flips through so it flickers. The fill
## stays white and the trick names black at every step. Oranges and yellows
## only, never the heart's red; opaque or fully transparent pixels only.
##
## Viewers (task T-336): a trick's amount is the viewers it brought ("+12.0K"):
## with `viewers` the amount is lettered in the viewers colour (the live viewers
## counter's, ViewersCounter) with a black outline at every heat step, and the
## viewers' eye (T-339's eye_icon.png) follows it. With `hide_amount` the bubble
## keeps its size but the amount and the eye are gone: they have flown off to the
## counter.

## The font, the palette and the lettering sizes are HudStyle's (T-428).
const FONT_PATH := HudStyle.COMIC_FONT_PATH

## Palette entries; index 0 is transparent.
const NONE := 0
const TEXT := 1
const BURST_FILL := 2
const BURST_BORDER := 3
const RING_WARM := 4
const RING_HOT := 5
const RING_INNER := 6
const AMOUNT_HOT := 7
## FLAME_0 to FLAME_0 + 3: the hottest flame pixels (next to the popup) to the tips.
const FLAME_0 := 8
## The "+amount" glyphs while lettering, before they are coloured (black at heat 0 and 1).
const AMOUNT := 12
## The viewers amount (T-336): the viewers colour.
const AMOUNT_VIEWERS := 13
const PALETTE := HudStyle.POPUP_PALETTE
## The viewers' eye after a viewers amount (T-336): T-339's art, at EYE_SCALE popup
## pixels per art pixel per size style, EYE_GAP popup pixels after the amount.
const EYE_PATH := "res://art/hud/eye_icon.png"
const EYE_SCALE := {"normal": 2, "small": 1}
const EYE_GAP := 3
## The heat steps (0 to 3, ComboHeat.step_for).
const HEAT_STEPS := 4
## The rings round the white fill per heat step, from the outside in:
## [palette index, width in popup pixels]. Heat 0 is the plain black border.
const HEAT_RINGS := [
	[[BURST_BORDER, 2]],
	[[BURST_BORDER, 1], [RING_WARM, 3]],
	[[BURST_BORDER, 1], [RING_HOT, 3], [RING_INNER, 2]],
	[[BURST_BORDER, 1], [RING_HOT, 3], [RING_INNER, 2]],
]
## From this step the "+amount" is orange with a black outline.
const AMOUNT_HOT_STEP := 2
## From this step the popup has a flaming edge (ComboHeat.FIRE_STEP).
const FLAME_STEP := 3
## Flames: one flame pixel is FLAME_PX popup pixels (about 2 screen pixels at
## the default zoom, like LikesFire.PIXEL). They rise up to FLAME_UP above the
## popup, lick out up to FLAME_SIDE at the sides and FLAME_DOWN below (popup
## pixels). The image keeps the bubble at its centre, so it grows by FLAME_UP
## at the top and at the bottom.
const FLAME_PX := 3
const FLAME_UP := 21
const FLAME_SIDE := 9
const FLAME_DOWN := 3
## Baked flame frames; the popup shows each for ComboHeat.FLICKER_FRAME.
const FLAME_FRAMES := 6

## Per size: font pixel size, text outline and shadow thickness. No text
## outline or shadow: black letters on white need none.
const STYLES := HudStyle.POPUP_TEXT
## Rounded rectangle (board, 2026-10-14): space between the text and the image
## edge (a 1 pixel transparent rim, the 2 pixel border, then padding), the
## border width and the corner radius, all in popup pixels.
const MARGIN_X := 8
const MARGIN_Y := 6
const BORDER := 2
const CORNER := 5

static var _font: FontFile = null
static var _cache := {}


## The style name for a font size from TrickPopups (small is the extended drift's).
static func style_for(font_size: int) -> String:
	return "small" if font_size <= 16 else "normal"


## The baked texture for `text` at a size style ("normal" or "small"), a heat
## step (0 to 3) and, at the flaming step, a flame frame; cached.
## `viewers` letters the amount as viewers with the eye (T-336); `hide_amount`
## leaves the amount and the eye out (flown to the counter).
static func texture(text: String, style: String, heat := 0, frame := 0, viewers := false, hide_amount := false) -> ImageTexture:
	heat = clampi(heat, 0, HEAT_STEPS - 1)
	frame = posmod(frame, FLAME_FRAMES) if heat >= FLAME_STEP else 0
	var key := "%s|%d|%d|%s|%s|%s" % [style, heat, frame, viewers, hide_amount, text]
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(bake(text, style, heat, frame, viewers, hide_amount))
	return _cache[key]


## How far a heat step's rings reach past the plain border (popup pixels).
static func ring_extra(heat: int) -> int:
	var w := 0
	for r in HEAT_RINGS[heat]:
		w += r[1]
	return w - BORDER


## Splits "FULL 360! +0.25" into ["FULL 360!", "+0.25"]; the amount is "" when there is none.
static func split_text(text: String) -> Array:
	var i := text.rfind(" +")
	if i < 0:
		return [text, ""]
	return [text.substr(0, i), text.substr(i + 1)]


## One popup as an RGBA image: opaque pixels or fully transparent ones only,
## with a transparent border. `heat` is the combo heat step (0 to 3, task
## T-133) and `frame` the flame frame at the flaming step.
static func bake(text: String, style: String, heat := 0, frame := 0, viewers := false, hide_amount := false) -> Image:
	heat = clampi(heat, 0, HEAT_STEPS - 1)
	var parts := split_text(text)
	var amount_at := -1
	if parts[1] != "":
		amount_at = (parts[0] as String).length() + 1
	viewers = viewers and amount_at >= 0
	var letters := _letter(text, style, amount_at)  # {"idx": PackedByteArray, "w", "h"}
	var eye_rect := Rect2i()
	if viewers:
		var with_eye := _add_eye(letters, style)
		letters = with_eye.letters
		eye_rect = with_eye.eye
	var tw: int = letters.w
	var th: int = letters.h
	var extra := ring_extra(heat)
	var flames := heat >= FLAME_STEP
	var fx := FLAME_SIDE if flames else 0
	var fy := FLAME_UP if flames else 0
	var w := tw + 2 * (MARGIN_X + extra + fx)
	var h := th + 2 * (MARGIN_Y + extra + fy)
	var idx := PackedByteArray()
	idx.resize(w * h)
	# The bubble: the rings from the outside in, then the white fill, whose
	# corner radius is the plain look's (CORNER - BORDER) at every step.
	var bw := w - 2 * fx
	var bh := h - 2 * fy
	var inset := 1
	var radius := CORNER + extra
	for ring in HEAT_RINGS[heat]:
		_fill_round_rect(idx, w, fx, fy, bw, bh, inset, radius, ring[0])
		inset += ring[1]
		radius -= ring[1]
	_fill_round_rect(idx, w, fx, fy, bw, bh, inset, radius, BURST_FILL)
	var ox := (w - tw) / 2
	var oy := (h - th) / 2
	var li: PackedByteArray = letters.idx
	var hot_amount := heat >= AMOUNT_HOT_STEP and not viewers
	for y in th:
		for x in tw:
			var c := li[y * tw + x]
			if c == AMOUNT:
				if hide_amount:
					c = NONE
				elif viewers:
					c = AMOUNT_VIEWERS
				else:
					c = AMOUNT_HOT if hot_amount else TEXT
			if c != NONE:
				idx[(oy + y) * w + ox + x] = c
	if hot_amount and not hide_amount:
		_outline(idx, w, h, AMOUNT_HOT, TEXT)
	if viewers and not hide_amount:
		_outline(idx, w, h, AMOUNT_VIEWERS, TEXT)
	if flames:
		_flames(idx, w, h, frame)
	var data := PackedByteArray()
	data.resize(w * h * 4)  # zero: transparent
	var packed := _packed_palette()
	for i in w * h:
		var c := idx[i]
		if c != NONE:
			data.encode_u32(i * 4, packed[c])
	var img := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)
	if viewers and not hide_amount:
		_draw_eye(img, Rect2i(eye_rect.position + Vector2i(ox, oy), eye_rect.size), style)
	return img


## The letters widened to hold the viewers' eye after the amount, vertically centred
## on the letters: {"letters": {"idx", "w", "h"}, "eye": Rect2i in the letters' box}.
## The eye's place is left empty in `idx` (drawn after, from the art).
static func _add_eye(letters: Dictionary, style: String) -> Dictionary:
	var esz := eye_size(style)
	var tw: int = letters.w
	var th: int = letters.h
	var nw := tw + EYE_GAP + esz.x
	var nh := maxi(th, esz.y)
	var ly := (nh - th) / 2
	var out := PackedByteArray()
	out.resize(nw * nh)
	var li: PackedByteArray = letters.idx
	for y in th:
		for x in tw:
			out[(ly + y) * nw + x] = li[y * tw + x]
	var eye := Rect2i(tw + EYE_GAP, (nh - esz.y) / 2, esz.x, esz.y)
	return {"letters": {"idx": out, "w": nw, "h": nh}, "eye": eye}


## The eye's size in popup pixels for a size style.
static func eye_size(style: String) -> Vector2i:
	var img := _eye_image()
	var k: int = EYE_SCALE.get(style, 1)
	return Vector2i(img.get_width() * k, img.get_height() * k)


static var _eye: Image = null


static func _eye_image() -> Image:
	if _eye == null:
		_eye = (load(EYE_PATH) as Texture2D).get_image()
		_eye.convert(Image.FORMAT_RGBA8)
	return _eye


## Draws the eye's opaque pixels into `rect` (popup pixels), scaled up, hard-edged.
static func _draw_eye(img: Image, rect: Rect2i, style: String) -> void:
	var src := _eye_image()
	var k: int = EYE_SCALE.get(style, 1)
	for y in rect.size.y:
		for x in rect.size.x:
			var c := src.get_pixel(x / k, y / k)
			if c.a > 0.5:
				img.set_pixel(rect.position.x + x, rect.position.y + y, Color(c.r, c.g, c.b, 1.0))


## Where the amount (and the eye) sits in a baked viewers popup, in popup pixels:
## the part that flies off to the counter (T-336). Empty when there is no amount.
static func amount_box(text: String, style: String, heat := 0) -> Rect2i:
	heat = clampi(heat, 0, HEAT_STEPS - 1)
	var parts := split_text(text)
	if parts[1] == "":
		return Rect2i()
	var full := text_box(text, style, heat, true)
	var amount := _letter(parts[1], style)
	var w: int = amount.w + EYE_GAP + eye_size(style).x
	return Rect2i(full.position.x + full.size.x - w, full.position.y, w, full.size.y)


## The text box of a baked popup (x, y, w, h in popup pixels) at a heat step.
static func text_box(text: String, style: String, heat := 0, viewers := false) -> Rect2i:
	heat = clampi(heat, 0, HEAT_STEPS - 1)
	var letters := _letter(text, style)
	if viewers and split_text(text)[1] != "":
		letters = _add_eye(letters, style).letters
	var grow := ring_extra(heat)
	if heat >= FLAME_STEP:
		return Rect2i(MARGIN_X + grow + FLAME_SIDE, MARGIN_Y + grow + FLAME_UP, letters.w, letters.h)
	return Rect2i(MARGIN_X + grow, MARGIN_Y + grow, letters.w, letters.h)


static func _get_font() -> FontFile:
	# Its own copy of HudStyle's comic font, as before T-428: the baking keeps its glyph cache apart.
	if _font == null:
		_font = HudStyle.new_comic_font()
	return _font


## The lettering: palette indices cropped tight, {"idx", "w", "h"}. Glyphs
## from character `amount_at` on (the "+amount") are AMOUNT, the rest TEXT.
static func _letter(text: String, style: String, amount_at := -1) -> Dictionary:
	# Cached (T-481): the same lettering serves every heat step and flame frame of a text,
	# and the popup's size. The result is only ever read.
	var key := "%s|%d|%s" % [style, amount_at, text]
	if not _letter_cache.has(key):
		_letter_cache[key] = _letter_uncached(text, style, amount_at)
	return _letter_cache[key]


static var _letter_cache := {}


## Letters every text of `texts` with a sample amount and loads the eye (T-481), so the
## font's glyphs and the eye are ready before the first popup of a run.
static func warm(texts: Array, style: String) -> void:
	for t in texts:
		var text := str(t) + " +0.123456789KM"
		plain_size(text, style, true)
		plain_size(str(t), style, false)


## A popup's plain (heat 0) size in popup pixels, as texture(text, style, 0, 0, viewers).get_size()
## would give, without baking it (T-481): the lettering's size and the margins.
static func plain_size(text: String, style: String, viewers := false) -> Vector2i:
	var amount_at := -1
	var parts := split_text(text)
	if parts[1] != "":
		amount_at = (parts[0] as String).length() + 1
	var letters := _letter(text, style, amount_at)
	var tw: int = letters.w
	var th: int = letters.h
	if viewers and amount_at >= 0:
		var esz := eye_size(style)
		tw += EYE_GAP + esz.x
		th = maxi(th, esz.y)
	var extra := ring_extra(0)
	return Vector2i(tw + 2 * (MARGIN_X + extra), th + 2 * (MARGIN_Y + extra))


static func _letter_uncached(text: String, style: String, amount_at := -1) -> Dictionary:
	var st: Dictionary = STYLES[style]
	var px: int = st.font_px
	var font := _get_font()
	var ts := TextServerManager.get_primary_interface()
	var rid: RID = font.get_rids()[0]
	var size := Vector2i(px, 0)
	# Pass 1: glyph indices and rendering.
	var glyphs: Array[int] = []
	for i in text.length():
		var g := ts.font_get_glyph_index(rid, px, text.unicode_at(i), 0)
		glyphs.append(g)
		ts.font_render_glyph(rid, size, g)
	var images := {}
	var ascent := int(ceil(font.get_ascent(px)))
	var descent := int(ceil(font.get_descent(px)))
	var pad: int = st.outline + st.shadow + 2
	var total := 0.0
	for i in glyphs.size():
		total += ts.font_get_glyph_advance(rid, px, glyphs[i]).x
		if i > 0:
			total += ts.font_get_kerning(rid, px, Vector2i(glyphs[i - 1], glyphs[i])).x
	var w := int(ceil(total)) + 2 * pad + 4
	var h := ascent + descent + 2 * pad
	var full := PackedByteArray()
	full.resize(w * h)
	var pen := 0.0
	for i in glyphs.size():
		var g := glyphs[i]
		if i > 0:
			pen += ts.font_get_kerning(rid, px, Vector2i(glyphs[i - 1], g)).x
		var gs := ts.font_get_glyph_size(rid, size, g)
		if gs.x > 0 and gs.y > 0:
			var tex_idx := ts.font_get_glyph_texture_idx(rid, size, g)
			if not images.has(tex_idx):
				images[tex_idx] = ts.font_get_texture_image(rid, size, tex_idx)
			var timg: Image = images[tex_idx]
			var tdata := timg.get_data()
			var tw := timg.get_width()
			# The glyph atlas is L8 (1 byte per pixel) or LA8 (2); the last byte of a pixel is the coverage.
			var bpp := 2 if timg.get_format() == Image.FORMAT_LA8 else 1
			var uv := ts.font_get_glyph_uv_rect(rid, size, g)
			var off := ts.font_get_glyph_offset(rid, size, g)
			var gx := int(round(pen)) + int(off.x) + pad
			var gy := pad + ascent + int(off.y)
			var mark := AMOUNT if amount_at >= 0 and i >= amount_at else TEXT
			for j in int(gs.y):
				for k in int(gs.x):
					if tdata[((int(uv.position.y) + j) * tw + int(uv.position.x) + k) * bpp + bpp - 1] > 127:
						var o := (gy + j) * w + gx + k
						full[o] = mark
		pen += ts.font_get_glyph_advance(rid, px, g).x
	return _crop(full, w, h)


static func _crop(idx: PackedByteArray, w: int, h: int) -> Dictionary:
	# Rows are scanned with native searches and copied as slices (T-481): same result as
	# looking at every pixel, a fraction of the time.
	var x0 := w
	var x1 := -1
	var y0 := h
	var y1 := -1
	for y in h:
		var row := idx.slice(y * w, (y + 1) * w)
		if row.count(0) == w:
			continue
		if y0 == h:
			y0 = y
		y1 = y
		# first and last non-zero pixel of the row
		var lo := 0
		while row[lo] == 0:
			lo += 1
		var hi := w - 1
		while row[hi] == 0:
			hi -= 1
		x0 = mini(x0, lo)
		x1 = maxi(x1, hi)
	if x1 < 0:  # nothing to show (empty text): one empty pixel
		return {"idx": PackedByteArray([0]), "w": 1, "h": 1}
	var nw := x1 - x0 + 1
	var nh := y1 - y0 + 1
	var out := PackedByteArray()
	for y in nh:
		out.append_array(idx.slice((y0 + y) * w + x0, (y0 + y) * w + x0 + nw))
	return {"idx": out, "w": nw, "h": nh}


## Sets `value` on every pixel of the rounded rectangle that is the bw x bh box
## at (bx, by) in a w wide image, shrunk by `inset`, with corner radius `r`.
static func _fill_round_rect(idx: PackedByteArray, w: int, bx: int, by: int, bw: int, bh: int, inset: int, r: int, value: int) -> void:
	# Row by row (T-481): the pixels of a row inside the shape are one run, found from the
	# row's corner arc and then nudged by the exact test, so the result is _in_round_rect's.
	var spans_ok := 2 * r <= bw - 2 * inset and 2 * r <= bh - 2 * inset and r >= 0
	for y in bh:
		var first := 0
		var last := bw - 1
		if spans_ok:
			var dy := absf((y + 0.5) - clampf(y + 0.5, inset + r, bh - inset - r))
			if dy > r:
				continue
			var d := sqrt(maxf(float(r) * r - dy * dy, 0.0))
			first = clampi(int(ceil(inset + r - d - 0.5)), 0, bw - 1)
			last = clampi(int(floor(bw - inset - r + d - 0.5)), 0, bw - 1)
			while first > 0 and _in_round_rect(first - 1, y, bw, bh, inset, r):
				first -= 1
			while first <= last and not _in_round_rect(first, y, bw, bh, inset, r):
				first += 1
			while last < bw - 1 and _in_round_rect(last + 1, y, bw, bh, inset, r):
				last += 1
			while last >= first and not _in_round_rect(last, y, bw, bh, inset, r):
				last -= 1
			var row := (by + y) * w + bx
			for x in range(first, last + 1):
				idx[row + x] = value
		else:
			for x in bw:
				if _in_round_rect(x, y, bw, bh, inset, r):
					idx[(by + y) * w + bx + x] = value


## The palette as little-endian RGBA8 integers, for writing a pixel in one call (T-481).
static var _packed: PackedInt64Array = PackedInt64Array()


static func _packed_palette() -> PackedInt64Array:
	if _packed.size() != PALETTE.size():
		_packed.resize(PALETTE.size())
		for i in PALETTE.size():
			var col: Color = PALETTE[i]
			var a := 255 if i != NONE else 0
			_packed[i] = int(round(col.r * 255.0)) | (int(round(col.g * 255.0)) << 8) | (int(round(col.b * 255.0)) << 16) | (a << 24)
	return _packed


## A one pixel `value` outline (the four side neighbours, so small digits keep their holes) round every `of` pixel,
## drawn over the white fill only.
static func _outline(idx: PackedByteArray, w: int, h: int, of: int, value: int) -> void:
	var add: Array[int] = []
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			if idx[y * w + x] != BURST_FILL:
				continue
			if idx[y * w + x - 1] == of or idx[y * w + x + 1] == of 					or idx[(y - 1) * w + x] == of or idx[(y + 1) * w + x] == of:
				add.append(y * w + x)
	for i in add:
		idx[i] = value


## The flaming edge (step 3): pixel flames round the bubble in FLAME_PX blocks,
## in the style of the likes bar's fire (LikesFire): broad tongues that sway
## from frame to frame with ragged tips, white-hot next to the popup, then
## yellow, orange-yellow and orange at the tips, and the odd orange spark
## above. Tall over the top edge, short at the sides and below. Never over the
## bubble, and never on the image's outer pixel rim (kept transparent).
static func _flames(idx: PackedByteArray, w: int, h: int, frame: int) -> void:
	# The bubble's top and bottom per column, and its left and right per row.
	var top := PackedInt32Array()
	var bottom := PackedInt32Array()
	top.resize(w)
	bottom.resize(w)
	for x in w:
		top[x] = -1
		bottom[x] = -1
		for y in h:
			if idx[y * w + x] != NONE:
				if top[x] < 0:
					top[x] = y
				bottom[x] = y
	var left := PackedInt32Array()
	var right := PackedInt32Array()
	left.resize(h)
	right.resize(h)
	for y in h:
		left[y] = -1
		right[y] = -1
		for x in w:
			if idx[y * w + x] != NONE:
				if left[y] < 0:
					left[y] = x
				right[y] = x
	var cols := w / FLAME_PX + 1
	var rows := h / FLAME_PX + 1
	var out := idx.duplicate()
	for by in rows:
		for bx in cols:
			var cx := mini(bx * FLAME_PX + FLAME_PX / 2, w - 1)
			var cy := mini(by * FLAME_PX + FLAME_PX / 2, h - 1)
			if idx[cy * w + cx] != NONE:
				continue
			# How far into the flame's reach the block is (0 at the popup, 1 at
			# the tip), the least over the four sides.
			var best := 2.0
			var tongue := _tongue(bx, frame)
			if top[cx] >= 0 and cy < top[cx]:
				best = minf(best, (top[cx] - cy) / (FLAME_UP * (0.15 + 0.85 * tongue)))
			if bottom[cx] >= 0 and cy > bottom[cx]:
				best = minf(best, (cy - bottom[cx]) / (FLAME_DOWN * (0.5 + 0.5 * tongue)))
			var side := FLAME_SIDE * (0.4 + 0.6 * _tongue(by + 17, frame))
			if left[cy] >= 0 and cx < left[cy]:
				best = minf(best, (left[cy] - cx) / side)
			if right[cy] >= 0 and cx > right[cy]:
				best = minf(best, (cx - right[cy]) / side)
			var c := NONE
			if best <= 1.0:
				c = FLAME_0 + mini(int(best * 4.0), 3)
			elif top[cx] >= 0 and cy < top[cx] and best <= 1.7 and _hash(bx * 31 + by * 5 + frame * 7) < 0.1:
				c = FLAME_0 + 3  # a spark
			if c == NONE:
				continue
			for y in range(maxi(by * FLAME_PX, 1), mini(by * FLAME_PX + FLAME_PX, h - 1)):
				for x in range(maxi(bx * FLAME_PX, 1), mini(bx * FLAME_PX + FLAME_PX, w - 1)):
					if idx[y * w + x] == NONE:
						out[y * w + x] = c
	for i in idx.size():
		idx[i] = out[i]


## A flame tongue's strength (0 to 1) for column (or row) `i` in flame frame
## `frame`: LikesFire's swaying tongues with a ragged tip that jumps each frame.
static func _tongue(i: int, frame: int) -> float:
	var t := frame * ComboHeat.FLICKER_FRAME
	var tongue := 0.5 + 0.5 * sin(i * 0.75 + t * 9.0 + sin(i * 0.23 - t * 3.1) * 2.5)
	return clampf(0.1 + 0.75 * pow(tongue, 2.0) + 0.15 * _hash(i * 13 + frame * 101), 0.0, 1.0)


static func _hash(n: int) -> float:
	return fposmod(sin(n * 12.9898 + 78.233) * 43758.5453, 1.0)


## True when the pixel (x, y) is inside the rounded rectangle that is the
## w x h image shrunk by `inset` on every side, with corner radius `r`. Pixel
## centres are tested, so the corners are stepped pixels with no smoothing.
static func _in_round_rect(x: int, y: int, w: int, h: int, inset: int, r: int) -> bool:
	var x0 := inset
	var y0 := inset
	var x1 := w - inset
	var y1 := h - inset
	var px := x + 0.5
	var py := y + 0.5
	if px < x0 or px > x1 or py < y0 or py > y1:
		return false
	var cx := clampf(px, x0 + r, x1 - r)
	var cy := clampf(py, y0 + r, y1 - r)
	return (px - cx) * (px - cx) + (py - cy) * (py - cy) <= r * r
