class_name TrickPopupArt
extends RefCounted
## Bakes the comic-style trick popups (task T-084): one hard-edged pixel image
## per text and size, a jagged comic burst sized to fit the lettering, the text
## in Bangers (res://fonts/bangers/, SIL OFL 1.1) with smoothing off.
##
## Look (the board's playtest, 2026-10-13): a real comic popup. A white jagged
## burst with a black border, every letter black (trick name and amount alike) in
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

## Per size: font pixel size, text outline and shadow thickness, spike length
## range, spike spacing along the edge and how flat the burst is. No text
## outline or shadow: black letters on white need none.
const STYLES := {
	"normal": {"font_px": 32, "outline": 0, "shadow": 0, "spike_min": 8.0, "spike_max": 13.0, "spacing": 24.0, "flat": 1.0},
	"small": {"font_px": 20, "outline": 0, "shadow": 0, "spike_min": 5.0, "spike_max": 8.0, "spacing": 22.0, "flat": 0.8},
}
const SUPERELLIPSE_N := 4.0  # how boxy the burst's base shape is (2 = oval)
const EDGE := 3              # room the burst border needs around the text, in pixels
const BASE_SAMPLES := 720    # points on the base curve before the spikes go on
## Spikes pointing sideways (left and right tips) are this much shorter.
const SIDE_SPIKE := 0.5
const SEED := 84

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
	var poly := _burst_polygon(tw, th, style)
	var max_x := 0.0
	var max_y := 0.0
	for p in poly:
		max_x = maxf(max_x, absf(p.x))
		max_y = maxf(max_y, absf(p.y))
	var w := 2 * int(ceil(max_x)) + 5
	var h := 2 * int(ceil(max_y)) + 5
	var fill := _fill_polygon(poly, w, h)
	var outer := _dilate_cross(fill, w, h)
	var e1 := _erode_cross(fill, w, h)
	var idx := PackedByteArray()
	idx.resize(w * h)
	for i in w * h:
		if e1[i] != 0:
			idx[i] = BURST_FILL
		elif outer[i] != 0 or fill[i] != 0:
			idx[i] = BURST_BORDER  # the border is 2 popup pixels wide
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
	var poly := _burst_polygon(letters.w, letters.h, style)
	var max_x := 0.0
	var max_y := 0.0
	for p in poly:
		max_x = maxf(max_x, absf(p.x))
		max_y = maxf(max_y, absf(p.y))
	var w := 2 * int(ceil(max_x)) + 5
	var h := 2 * int(ceil(max_y)) + 5
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


static func _dilate_square(m: PackedByteArray, w: int, h: int, r: int) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(w * h)
	for y in h:
		for x in w:
			if m[y * w + x] != 0:
				for yy in range(maxi(0, y - r), mini(h, y + r + 1)):
					for xx in range(maxi(0, x - r), mini(w, x + r + 1)):
						out[yy * w + xx] = 1
	return out


static func _dilate_cross(m: PackedByteArray, w: int, h: int) -> PackedByteArray:
	var out := m.duplicate()
	for y in h:
		for x in w:
			if m[y * w + x] != 0:
				if x > 0:
					out[y * w + x - 1] = 1
				if x < w - 1:
					out[y * w + x + 1] = 1
				if y > 0:
					out[(y - 1) * w + x] = 1
				if y < h - 1:
					out[(y + 1) * w + x] = 1
	return out


static func _erode_cross(m: PackedByteArray, w: int, h: int) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(w * h)
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var o := y * w + x
			if m[o] != 0 and m[o - w] != 0 and m[o + w] != 0 and m[o - 1] != 0 and m[o + 1] != 0:
				out[o] = 1
	return out


## The burst's jagged outline around a text box centred on (0, 0).
static func _burst_polygon(text_w: int, text_h: int, style: String) -> PackedVector2Array:
	var st: Dictionary = STYLES[style]
	var k := pow(2.0, 1.0 / SUPERELLIPSE_N)
	var a := (text_w / 2.0) * k + EDGE + 1
	var b := (text_h / 2.0) * k * float(st.flat) + EDGE + 1
	b = maxf(b, text_h / 2.0 + EDGE + 1)
	# Sample the base curve densely, then place points evenly by arc length.
	var e := 2.0 / SUPERELLIPSE_N
	var base := PackedVector2Array()
	for j in BASE_SAMPLES:
		var t := TAU * j / BASE_SAMPLES
		var c := cos(t)
		var s := sin(t)
		base.append(Vector2(a * signf(c) * pow(absf(c), e), b * signf(s) * pow(absf(s), e)))
	var cum := PackedFloat64Array([0.0])
	for j in range(1, BASE_SAMPLES + 1):
		cum.append(cum[-1] + base[j - 1].distance_to(base[j % BASE_SAMPLES]))
	var perimeter: float = cum[-1]
	var spikes := maxi(8, int(round(perimeter / float(st.spacing))))
	var rnd := RandomNumberGenerator.new()
	rnd.seed = ("%d|%d|%d|%s" % [SEED, text_w, text_h, style]).hash()
	var pts := PackedVector2Array()
	var j := 0
	for i in 2 * spikes:
		var target := fposmod(perimeter * (i + rnd.randf_range(-0.15, 0.15)) / (2 * spikes), perimeter)
		while not (cum[j] <= target and target < cum[j + 1]):
			j = (j + 1) % BASE_SAMPLES
		var bp := base[j]
		if i % 2 == 0:
			var p0 := base[(j - 1 + BASE_SAMPLES) % BASE_SAMPLES]
			var p1 := base[(j + 1) % BASE_SAMPLES]
			var nrm := Vector2(p1.y - p0.y, -(p1.x - p0.x)).normalized()
			var rad := bp.normalized()
			var dir := (nrm + rad).normalized()
			var out := rnd.randf_range(st.spike_min, st.spike_max)
			out *= lerpf(1.0, SIDE_SPIKE, pow(absf(dir.x), 4.0))
			pts.append(bp + dir * out)
		else:
			pts.append(bp)
	return pts


## Pixels whose centre is inside the polygon (scanline, even-odd), as a mask.
static func _fill_polygon(poly: PackedVector2Array, w: int, h: int) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(w * h)
	var cx := w / 2.0
	var cy := h / 2.0
	var n := poly.size()
	for y in h:
		var py := y + 0.5 - cy
		var xs: Array[float] = []
		for i in n:
			var p1 := poly[i]
			var p2 := poly[(i + 1) % n]
			if (p1.y > py) != (p2.y > py):
				xs.append(p1.x + (py - p1.y) * (p2.x - p1.x) / (p2.y - p1.y))
		xs.sort()
		for q in range(0, xs.size() - 1, 2):
			var x0 := int(ceil(xs[q] + cx - 0.5))
			var x1 := int(ceil(xs[q + 1] + cx - 0.5)) - 1
			for x in range(maxi(x0, 0), mini(x1, w - 1) + 1):
				out[y * w + x] = 1
	return out
