class_name MeteorFx
extends RefCounted
## The comet tail behind a falling meteor and the impact animation where it
## lands (task T-070; Visual style, Decisions, "The kaiju's meteor attack").
## Drawn by kaiju_meteors.gd's sky drawing; this file only knows how.
##
## Three versions for the board to compare, picked by one setting,
## res://data/meteor_fx.json {"version": ...} (game/README.md, "Meteor effects"):
##   "pixel"     sprite sheets drawn by script (art/effects/meteor_*_pixel.png)
##   "pixellab"  sprite sheets animated by PixelLab (art/effects/meteor_*_pixellab.png)
##   "particles" no sprites: square pixel particles computed here every frame
##   "off"       the earlier placeholder: no tail, the plain dust burst
## The environment variable METEOR_FX overrides the file (for recordings), and
## `override` overrides both (tests). Everything is a pure function of the
## meteor's flight time or the impact's age, so nothing here keeps state.

const VERSIONS := ["pixel", "pixellab", "particles", "off"]
const SETTINGS_PATH := "res://data/meteor_fx.json"
const CELL := 128.0
const DRAW_SCALE := 0.75
const TAIL_HEAD := Vector2(64, 118)
const IMPACT_CENTER := Vector2(64, 76)
const TAIL_FRAMES_PIXEL := 6
const TAIL_FRAMES_PIXELLAB := 8
const IMPACT_FRAMES := 8
const TAIL_FPS := 14.0
## How long the impact animation plays, per version (seconds).
const IMPACT_SECONDS := {"pixel": 0.5, "pixellab": 0.5, "particles": 0.6, "off": 0.5}
## The falling meteor's direction on screen (the same as kaiju_meteors.gd's path).
const FALL_VECTOR := Vector2(-20.0, 220.0)

const WHITE := Color8(255, 244, 255)
const PINK := Color8(255, 190, 245)
const MAGENTA := Color8(240, 104, 236)
const VIOLET := Color8(156, 70, 214)
const DEEP := Color8(92, 46, 150)
const NAVY := Color8(46, 30, 88)
const DARK := Color8(13, 10, 26)
const DUST_LIGHT := Color8(176, 168, 198)
const DUST_MID := Color8(128, 118, 164)
const DUST_DARK := Color8(86, 78, 124)

## Tests set this to a version name to ignore the file and the environment.
static var override := ""
static var _file_version := ""
static var _textures := {}


static func version() -> String:
	if override != "":
		return override
	var env := OS.get_environment("METEOR_FX")
	if env in VERSIONS:
		return env
	if _file_version == "":
		_file_version = "particles"
		var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if f != null:
			var d = JSON.parse_string(f.get_as_text())
			if d is Dictionary and str(d.get("version", "")) in VERSIONS:
				_file_version = str(d["version"])
	return _file_version


static func impact_seconds() -> float:
	return IMPACT_SECONDS[version()]


## True while a meteor with `time_left` seconds to go shows its tail: only
## while it is falling, never before it appears nor once it has landed.
static func tail_active(time_left: float, fall_seconds: float) -> bool:
	return version() != "off" and time_left > 0.0 and time_left <= fall_seconds


static func texture(kind: String, ver: String) -> Texture2D:
	var key := "%s_%s" % [kind, ver]
	if not _textures.has(key):
		_textures[key] = load("res://art/effects/meteor_%s.png" % key)
	return _textures[key]


static func tail_frame(flight: float) -> int:
	var n := TAIL_FRAMES_PIXELLAB if version() == "pixellab" else TAIL_FRAMES_PIXEL
	return int(flight * TAIL_FPS) % n


static func impact_frame(age: float) -> int:
	return clampi(int(age / impact_seconds() * IMPACT_FRAMES), 0, IMPACT_FRAMES - 1)


static func _h(a: int, b: int) -> float:
	var h := (a * 73856093) ^ (b * 19349663)
	h = (h ^ (h >> 13)) & 0x7fffffff
	return float(h % 10007) / 10007.0


static func _sq(c: CanvasItem, p: Vector2, size: float, col: Color) -> void:
	# a square pixel of `size` screen pixels, snapped to a 2-pixel grid
	var q := (p / 2.0).floor() * 2.0
	c.draw_rect(Rect2(q, Vector2(size, size)), col)


## The tail of a meteor whose head is at `head` (screen pixels), `flight`
## seconds into its fall, p = progress 0..1.
static func draw_tail(c: CanvasItem, head: Vector2, flight: float, p: float, seed: int) -> void:
	var ver := version()
	if ver == "pixel" or ver == "pixellab":
		var tex := texture("tail", ver)
		var frames := TAIL_FRAMES_PIXELLAB if ver == "pixellab" else TAIL_FRAMES_PIXEL
		var f := tail_frame(flight)
		c.draw_texture_rect_region(tex, Rect2(head - TAIL_HEAD * DRAW_SCALE, Vector2(CELL, CELL) * DRAW_SCALE),
			Rect2(f * CELL, 0, CELL, CELL))
	elif ver == "particles":
		var up := Vector2(-FALL_VECTOR.x, -FALL_VECTOR.y).normalized()
		# a short solid streak, then embers shed along the path that fall behind and shrink
		for i in 6:
			var s := 8.0 - i
			_sq(c, head + up * (i * 7.0 + 6.0) - Vector2(s, s) * 0.5, s,
				[WHITE, PINK, MAGENTA, MAGENTA, VIOLET, DEEP][i])
		for k in 26:
			var age := k * 0.014 + _h(seed, k) * 0.01
			var q := p - age / 0.5
			if q < 0.0:
				continue
			var at := head
			# the path: the meteor was higher up earlier (up and slightly to the right)
			at = head + Vector2(20.0, -220.0) * (p - q)
			at += Vector2((_h(seed, k + 50) - 0.5) * 22.0 * (1.0 + age * 3.0), age * 30.0)
			var life := age / 0.4
			if life > 1.0:
				continue
			var size := 8.0 - life * 6.0
			var col := WHITE if life < 0.1 else (PINK if life < 0.25 else (MAGENTA if life < 0.5 else (VIOLET if life < 0.75 else DEEP)))
			_sq(c, at - Vector2(size, size) * 0.5, maxf(size, 2.0), col)


## The impact at `center` (the ground point, screen pixels), `age` seconds after landing.
static func draw_impact(c: CanvasItem, center: Vector2, age: float, seed: int) -> void:
	var ver := version()
	if ver == "pixel" or ver == "pixellab":
		var f := impact_frame(age)
		c.draw_texture_rect_region(texture("impact", ver),
			Rect2(center - IMPACT_CENTER * DRAW_SCALE, Vector2(CELL, CELL) * DRAW_SCALE),
			Rect2(f * CELL, 0, CELL, CELL))
	elif ver == "particles":
		_draw_impact_particles(c, center, age, seed)


static func _draw_impact_particles(c: CanvasItem, center: Vector2, age: float, seed: int) -> void:
	var t := clampf(age / IMPACT_SECONDS["particles"], 0.0, 1.0)
	# the flash: a white-hot ellipse that collapses in the first fifth
	if t < 0.2:
		var s := 1.0 - t / 0.2
		var pts := PackedVector2Array()
		for i in 24:
			var a := TAU * i / 24.0
			pts.append(center + Vector2(cos(a) * 30.0, sin(a) * 15.0) * (0.4 + s * 0.6))
		c.draw_colored_polygon(pts, PINK)
		var inner := PackedVector2Array()
		for p in pts:
			inner.append(center + (p - center) * 0.55)
		c.draw_colored_polygon(inner, WHITE)
	# the shockwave: a ring of square pixels running out along the ground
	var rr := 14.0 + 46.0 * (1.0 - pow(1.0 - t, 2.0))
	var n := 40
	var ring_col := PINK if t < 0.25 else (MAGENTA if t < 0.55 else (VIOLET if t < 0.8 else DEEP))
	for i in n:
		if t > 0.5 and _h(seed + int(t * 20.0), i) < (t - 0.5) * 1.4:
			continue
		var a := TAU * i / n
		var size := 6.0 - t * 3.0
		_sq(c, center + Vector2(cos(a) * rr, sin(a) * rr * 0.5), maxf(size, 2.0), ring_col)
	# sparks: bright squares flying out and falling with gravity
	for i in 16:
		var a := TAU * _h(seed, i)
		var sp := 50.0 + 70.0 * _h(seed, i + 100)
		var tt := age
		var pos := center + Vector2(cos(a) * sp * tt, sin(a) * sp * tt * 0.5 - 90.0 * tt + 260.0 * tt * tt)
		var life := t
		if life > 0.9:
			continue
		var col := WHITE if life < 0.15 else (PINK if life < 0.35 else (MAGENTA if life < 0.6 else VIOLET))
		_sq(c, pos, 4.0 if life < 0.5 else 2.0, col)
	# rock shards: dark chunks with a glowing crack, thrown up and back down
	for i in 7:
		var a := TAU * _h(seed, i + 200)
		var vx := cos(a) * (40.0 + 40.0 * _h(seed, i + 300))
		var vy := -(150.0 + 90.0 * _h(seed, i + 400))
		var pos := center + Vector2(vx * age, vy * age + 520.0 * age * age) + Vector2(0, sin(a) * 6.0)
		if pos.y > center.y + 14.0 or t > 0.95:
			continue
		_sq(c, pos - Vector2(2, 2), 8.0, DARK)
		_sq(c, pos, 4.0, NAVY)
		_sq(c, pos, 2.0, MAGENTA)
	# dust: grey-violet squares puffing out low and rising, from a quarter in
	if t > 0.25:
		var d := (t - 0.25) / 0.75
		for i in 14:
			var a := TAU * i / 14.0 + _h(seed, i + 500)
			var pos := center + Vector2(cos(a) * (24.0 + 40.0 * d), sin(a) * (12.0 + 20.0 * d) - 14.0 * d)
			var size := 6.0 + 10.0 * d * (0.6 + _h(seed, i + 600))
			if d > 0.5 and _h(seed + int(d * 10.0), i) < d - 0.3:
				continue
			_sq(c, pos - Vector2(size, size) * 0.5, size, DUST_LIGHT if d < 0.4 else (DUST_MID if d < 0.75 else DUST_DARK))
