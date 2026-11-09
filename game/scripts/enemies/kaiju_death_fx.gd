extends RefCounted
## The end of the kaiju's death, drawn in code (task T-612, quick tuning 1; Enemies, Decisions,
## "The kaiju's death is longer and more dramatic"). After the death animation the kaiju lies in
## its last frame; kaiju_sprite.gd then calls these to draw, over that frame:
##
## - draw_cracks(): neon green cracks of energy spreading over the body from scattered points,
##   while a green glow fills its silhouette, until the green has consumed it (progress 0 to 1).
## - draw_explosion(): a big explosion from the body's middle in the kaiju's theme: a white and
##   pale cyan flash, a neon purple and a magenta shock ring, purple, magenta and cyan fireballs,
##   chunks of the kaiju's dark teal hide and the meteors' navy flying out and falling, cyan and
##   white sparks, navy smoke (progress 0 to 1).
##
## The greens are the minions' spill greens (minion_spill.gd) and a near-white core; none is
## Greenbull's (Visual style, Content, "Rules", rule 6; the tests check the distance). Everything
## is whole-pixel squares, lines and rings in screen pixels, from a fixed seed, so it looks the
## same every time. The cracks follow the frame's own pixels, so the final art (T-613) gets them
## with no change.

const ART_SCALE := 0.5

## The cracks: the minions' spill greens (minion_spill.gd COLOR_BODY, COLOR_LIGHT), a near-white core.
const CRACK_GREEN := Color8(140, 224, 26)
const CRACK_LIGHT := Color8(204, 250, 89)
const CRACK_CORE := Color8(232, 255, 176)
## The explosion: the kaiju's pale cyan plates, the HUD's neon purple for the kaiju (its health
## bar), the meteors' magenta glow and navy, the kaiju's dark teal hide, and a white flash.
const FLASH := Color8(235, 255, 255)
const PLATE_CYAN := Color8(140, 235, 235)
const NEON_PURPLE := Color8(184, 46, 255)
const MAGENTA := Color8(217, 77, 230)
const NAVY := Color8(51, 36, 82)
const HIDE := Color8(51, 77, 71)
const CRACK_COLOURS := [CRACK_GREEN, CRACK_LIGHT, CRACK_CORE]
const EXPLOSION_COLOURS := [FLASH, PLATE_CYAN, NEON_PURPLE, MAGENTA, NAVY, HIDE]

const CRACKS := 9
const CRACK_STEPS := 10
const SEED := 612

## Per frame of a sheet: {silhouette: ImageTexture, cracks: Array of PackedVector2Array (art
## pixels), centre: Vector2 (art pixels)}.
static var _cache := {}


## The frame's silhouette, cracks and middle, made once from its pixels; empty when the
## texture's pixels cannot be read.
static func frame_info(tex: Texture2D, frame: int, fs: int) -> Dictionary:
	var key := "%s#%d#%d" % [tex.resource_path if tex.resource_path != "" else str(tex.get_instance_id()), frame, fs]
	if _cache.has(key):
		return _cache[key]
	var info := {}
	var img := tex.get_image()
	if img != null:
		if img.is_compressed():
			img.decompress()
		var fr := img.get_region(Rect2i(frame * fs, 0, fs, fs))
		fr.convert(Image.FORMAT_RGBA8)
		var sil := Image.create(fs, fs, false, Image.FORMAT_RGBA8)
		for y in fs:
			for x in fs:
				if fr.get_pixel(x, y).a > 0.5:
					sil.set_pixel(x, y, Color.WHITE)
		var used := fr.get_used_rect()
		info = {"silhouette": ImageTexture.create_from_image(sil), "cracks": _cracks(fr, used),
				"centre": Vector2(used.get_center())}
	_cache[key] = info
	return info


## Jagged crack lines over the opaque pixels, from scattered starting points.
static func _cracks(fr: Image, used: Rect2i) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var out: Array = []
	if used.size.x <= 0 or used.size.y <= 0:
		return out
	for i in CRACKS:
		var start := Vector2(-1, -1)
		for _t in 60:
			var p := Vector2(rng.randi_range(used.position.x, used.end.x - 1), rng.randi_range(used.position.y, used.end.y - 1))
			if fr.get_pixelv(Vector2i(p)).a > 0.5:
				start = p
				break
		if start.x < 0:
			continue
		var pts := PackedVector2Array([start])
		var dir := Vector2.RIGHT.rotated(rng.randf() * TAU)
		for _s in CRACK_STEPS:
			dir = dir.rotated(rng.randf_range(-0.8, 0.8))
			var q := (pts[pts.size() - 1] + dir * rng.randf_range(5.0, 9.0)).round()
			if q.x < 0 or q.y < 0 or q.x >= fr.get_width() or q.y >= fr.get_height() or fr.get_pixelv(Vector2i(q)).a <= 0.5:
				break
			pts.append(q)
		if pts.size() >= 2:
			out.append(pts)
	return out


## An art pixel of the frame in the sprite's drawing (feet at 0, half size, mirrored or not).
static func to_draw(art: Vector2, feet: Vector2, mirrored: bool) -> Vector2:
	var d := (art - feet) * ART_SCALE
	return Vector2(-d.x if mirrored else d.x, d.y)


## How much of crack `i` (of `n`) shows at `progress`: they start one after another over the
## first half and each grows to its full length.
static func crack_reveal(i: int, n: int, progress: float) -> float:
	var start := 0.5 * float(i) / float(maxi(n, 1))
	return clampf((progress - start) / (1.0 - start) * 1.4, 0.0, 1.0)


## The green taking the body over: 0 at the start, 1 (all green) at the end.
static func consume_alpha(progress: float) -> float:
	return clampf(pow(clampf(progress, 0.0, 1.0), 1.6), 0.0, 1.0)


static func draw_cracks(ci: CanvasItem, info: Dictionary, progress: float, feet: Vector2, mirrored: bool, fs: int, time: float) -> void:
	if info.is_empty():
		return
	var size := fs * ART_SCALE
	var fx := (fs - feet.x) if mirrored else feet.x
	var rect := Rect2(Vector2(-fx * ART_SCALE, -feet.y * ART_SCALE), Vector2(-size if mirrored else size, size))
	var fill := CRACK_GREEN
	fill.a = consume_alpha(progress) * 0.95
	if fill.a > 0.0:
		ci.draw_texture_rect(info.silhouette, rect, false, fill)
	var flicker := 0.85 + 0.15 * sin(time * 40.0)
	var cracks: Array = info.cracks
	for i in cracks.size():
		var pts: PackedVector2Array = cracks[i]
		var r := crack_reveal(i, cracks.size(), progress)
		if r <= 0.0:
			continue
		var reach := r * float(pts.size() - 1)
		var line := PackedVector2Array()
		for k in pts.size():
			if float(k) <= reach:
				line.append(to_draw(pts[k], feet, mirrored).round())
			else:
				var a := to_draw(pts[k - 1], feet, mirrored)
				var b := to_draw(pts[k], feet, mirrored)
				line.append(a.lerp(b, reach - float(k - 1)).round())
				break
		if line.size() < 2:
			continue
		var light := CRACK_LIGHT
		light.a = flicker
		ci.draw_polyline(line, light, 3.0)
		ci.draw_polyline(line, CRACK_CORE, 1.0)
		var tip: Vector2 = line[line.size() - 1]
		ci.draw_rect(Rect2(tip - Vector2(2, 2), Vector2(4, 4)), CRACK_CORE)


## The body's last flash as the explosion starts: its silhouette in white and green, gone after
## the first FLASH_PART of the explosion.
const FLASH_PART := 0.12


static func draw_flash_body(ci: CanvasItem, info: Dictionary, progress: float, feet: Vector2, mirrored: bool, fs: int) -> void:
	if info.is_empty() or progress >= FLASH_PART:
		return
	var size := fs * ART_SCALE
	var fx := (fs - feet.x) if mirrored else feet.x
	var rect := Rect2(Vector2(-fx * ART_SCALE, -feet.y * ART_SCALE), Vector2(-size if mirrored else size, size))
	var c := CRACK_CORE.lerp(FLASH, progress / FLASH_PART)
	c.a = 1.0 - progress / FLASH_PART
	ci.draw_texture_rect(info.silhouette, rect, false, c)


static func _ease_out(t: float) -> float:
	return 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), 3.0)


static func _sq(ci: CanvasItem, at: Vector2, size: float, c: Color) -> void:
	var s := maxf(roundf(size), 1.0)
	ci.draw_rect(Rect2((at - Vector2(s, s) * 0.5).round(), Vector2(s, s)), c)


static func _ring(ci: CanvasItem, centre: Vector2, radius: float, width: float, c: Color) -> void:
	# An ellipse on the ground (half as tall as wide, as the isometric view sees a circle).
	ci.draw_set_transform(centre, 0.0, Vector2(1.0, 0.5))
	ci.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, c, width)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The explosion at `progress` (0 to 1), `radius` screen pixels at its widest, from `centre`.
static func draw_explosion(ci: CanvasItem, centre: Vector2, progress: float, radius: float) -> void:
	var p := clampf(progress, 0.0, 1.0)
	if p >= 1.0:
		return
	var e := _ease_out(p)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var ground := centre + Vector2(0.0, radius * 0.12)
	# Smoke, late and low.
	for i in 10:
		var a := rng.randf() * TAU
		var d := rng.randf_range(0.2, 0.7) * radius * e
		var c := NAVY
		c.a = 0.55 * clampf((p - 0.25) * 2.0, 0.0, 1.0) * (1.0 - p)
		if c.a > 0.0:
			ci.draw_circle(centre + Vector2(cos(a) * d, sin(a) * d * 0.6 - p * 18.0), rng.randf_range(10.0, 20.0) * (0.6 + p), c)
	# Shock rings on the ground: neon purple, then magenta behind it.
	var ring := NEON_PURPLE
	ring.a = 1.0 - p
	_ring(ci, ground, radius * e, maxf(1.0, 10.0 * (1.0 - p)), ring)
	var ring2 := MAGENTA
	ring2.a = (1.0 - p) * 0.9
	_ring(ci, ground, radius * 0.72 * _ease_out(p * 1.2), maxf(1.0, 6.0 * (1.0 - p)), ring2)
	# Fireballs: bright first, then purple and magenta, shrinking away.
	var fire := [FLASH, PLATE_CYAN, MAGENTA, NEON_PURPLE]
	for i in 16:
		var a := rng.randf() * TAU
		var d := rng.randf_range(0.0, 0.5) * radius * e
		var size := rng.randf_range(12.0, 26.0) * (1.0 - p) * (0.6 + 0.8 * minf(p * 6.0, 1.0))
		var k := clampi(int(p * 4.0 + float(i % 2)), 0, fire.size() - 1)
		_sq(ci, centre + Vector2(cos(a) * d, sin(a) * d * 0.7), size, fire[k])
	# The core flash.
	if p < 0.25:
		var core := FLASH
		core.a = 1.0 - p / 0.25
		ci.draw_circle(centre, radius * 0.38 * minf(p / 0.08, 1.0), core)
	# Chunks of hide and navy, thrown up and falling.
	var chunks := [HIDE, NAVY, HIDE, PLATE_CYAN]
	for i in 18:
		var a := rng.randf_range(PI * 1.05, PI * 1.95) if i % 3 != 0 else rng.randf() * TAU
		var speed := rng.randf_range(0.5, 1.1) * radius
		var pos := centre + Vector2(cos(a), sin(a) * 0.8) * speed * p + Vector2(0.0, 1.6 * radius * p * p)
		var c: Color = chunks[i % chunks.size()]
		c.a = clampf((1.0 - p) * 3.0, 0.0, 1.0)
		_sq(ci, pos, rng.randf_range(4.0, 7.0), c)
	# Sparks, fast and small.
	for i in 26:
		var a := rng.randf() * TAU
		var pos := centre + Vector2(cos(a), sin(a) * 0.6) * rng.randf_range(0.7, 1.3) * radius * e
		var c: Color = FLASH if i % 2 == 0 else PLATE_CYAN
		c.a = clampf((1.0 - p) * 2.0, 0.0, 1.0)
		_sq(ci, pos, 2.0 + (1.0 - p) * 2.0, c)
