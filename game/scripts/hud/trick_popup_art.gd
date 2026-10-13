class_name TrickPopupArt
extends RefCounted
## Bakes the comic-style trick popups (task T-084): one hard-edged pixel image
## per text and size, a white rounded rectangle sized to fit the lettering, the text
## in Bangers (res://fonts/bangers/, SIL OFL 1.1) with smoothing off.
##
## Look (the board's playtest, 2026-10-13): a real comic popup. A white rounded
## rectangle (stepped corners) with a black border, every letter black (trick name and amount alike) in
## Bangers on one straight baseline, hard pixel edges, no semi-transparent
## pixels, no Redgull red. Black on white reads on the dark asphalt and on the
## dusty gravel alike, since the black border separates the burst from both.
## One popup pixel is shown as 2 art pixels (TrickPopups.PIXEL_SCALE). Baked
## once per text and size and cached.

const FONT_PATH := "res://fonts/bangers/Bangers-Regular.ttf"

## Palette entries; index 0 is transparent.
const NONE := 0
const TEXT := 1
const BURST_FILL := 2
const BURST_BORDER := 3
const PALETTE := [
	Color(0, 0, 0, 0),
	Color8(0, 0, 0),        # letters
	Color8(255, 255, 255),  # burst fill
	Color8(0, 0, 0),        # burst border
]

## Per size: font pixel size, text outline and shadow thickness. No text
## outline or shadow: black letters on white need none.
const STYLES := {
	"normal": {"font_px": 32, "outline": 0, "shadow": 0},
	"small": {"font_px": 20, "outline": 0, "shadow": 0},
}
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


## The baked texture for `text` at a size style ("normal" or "small"), cached.
static func texture(text: String, style: String) -> ImageTexture:
	var key := style + "|" + text
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(bake(text, style))
	return _cache[key]


## Splits "FULL 360! +0.25" into ["FULL 360!", "+0.25"]; the amount is "" when there is none.
static func split_text(text: String) -> Array:
	var i := text.rfind(" +")
	if i < 0:
		return [text, ""]
	return [text.substr(0, i), text.substr(i + 1)]


## One popup as an RGBA image: opaque pixels or fully transparent ones only,
## with a transparent border.
static func bake(text: String, style: String) -> Image:
	var letters := _letter(text, style)  # {"idx": PackedByteArray, "w", "h"}
	var tw: int = letters.w
	var th: int = letters.h
	var w := tw + 2 * MARGIN_X
	var h := th + 2 * MARGIN_Y
	var idx := PackedByteArray()
	idx.resize(w * h)
	for y in h:
		for x in w:
			if _in_round_rect(x, y, w, h, 1, CORNER):
				idx[y * w + x] = BURST_BORDER
			if _in_round_rect(x, y, w, h, 1 + BORDER, CORNER - BORDER):
				idx[y * w + x] = BURST_FILL
	var ox := (w - tw) / 2
	var oy := (h - th) / 2
	var li: PackedByteArray = letters.idx
	for y in th:
		for x in tw:
			var c := li[y * tw + x]
			if c != NONE:
				idx[(oy + y) * w + ox + x] = c
	var data := PackedByteArray()
	data.resize(w * h * 4)
	for i in w * h:
		var col: Color = PALETTE[idx[i]]
		data[i * 4] = int(round(col.r * 255.0))
		data[i * 4 + 1] = int(round(col.g * 255.0))
		data[i * 4 + 2] = int(round(col.b * 255.0))
		data[i * 4 + 3] = 255 if idx[i] != NONE else 0
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)


## The text box of a baked popup (x, y, w, h in popup pixels) and its size.
static func text_box(text: String, style: String) -> Rect2i:
	var letters := _letter(text, style)
	var w: int = letters.w + 2 * MARGIN_X
	var h: int = letters.h + 2 * MARGIN_Y
	return Rect2i((w - letters.w) / 2, (h - letters.h) / 2, letters.w, letters.h)


static func _get_font() -> FontFile:
	if _font == null:
		_font = (load(FONT_PATH) as FontFile).duplicate()
		_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		_font.hinting = TextServer.HINTING_NONE
		_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		_font.generate_mipmaps = false
	return _font


## The lettering: palette indices cropped tight, {"idx", "w", "h"}.
static func _letter(text: String, style: String) -> Dictionary:
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
			for j in int(gs.y):
				for k in int(gs.x):
					if tdata[((int(uv.position.y) + j) * tw + int(uv.position.x) + k) * bpp + bpp - 1] > 127:
						var o := (gy + j) * w + gx + k
						full[o] = 1
		pen += ts.font_get_glyph_advance(rid, px, g).x
	var idx := PackedByteArray()
	idx.resize(w * h)
	for i in w * h:
		if full[i] != 0:
			idx[i] = TEXT
	return _crop(idx, w, h)


static func _crop(idx: PackedByteArray, w: int, h: int) -> Dictionary:
	var x0 := w
	var x1 := -1
	var y0 := h
	var y1 := -1
	for y in h:
		for x in w:
			if idx[y * w + x] != 0:
				x0 = mini(x0, x)
				x1 = maxi(x1, x)
				y0 = mini(y0, y)
				y1 = maxi(y1, y)
	if x1 < 0:  # nothing to show (empty text): one empty pixel
		return {"idx": PackedByteArray([0]), "w": 1, "h": 1}
	var nw := x1 - x0 + 1
	var nh := y1 - y0 + 1
	var out := PackedByteArray()
	out.resize(nw * nh)
	for y in nh:
		for x in nw:
			out[y * nw + x] = idx[(y0 + y) * w + x0 + x]
	return {"idx": out, "w": nw, "h": nh}


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
