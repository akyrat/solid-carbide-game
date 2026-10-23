extends Node2D
## The neon underglow's zone drawn in code (task T-274): the damage circle seen
## through the isometric view as neon on the ground, built pixel by pixel into a
## small image (opaque pixels or nothing: no blur, bloom or semi-transparent
## smoothing). From the edge out: a bright pink ring just inside the damage
## circle's edge, a stepped purple halo outside it (a solid band, then a
## dithered one) and a half-dithered purple floor glow inside it. The halo and
## floor glow breathe out and in in steps (the pulse) while a brighter arc
## travels round the ring (the shimmer). Every colour and width is in
## UnderglowLook (scenes/weapons/neon_underglow_look.tres).
##
## The animation advances in _process, so it stops while the game is paused. The
## images are built once per radius and animation frame, then reused. With the
## look's `use_sprite` on, the generated sprite of T-175 is drawn instead.

## The run's isometric projection (run.gd ISO_TRANSFORM).
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
const LOOK := preload("res://scenes/weapons/neon_underglow_look.tres")
## The generated sprite (T-175): a 224 x 112 art-pixel ring drawn at scale 0.5 for
## the radius it was made for (2.5 units, the first tier's).
const ART_TEXTURE := preload("res://art/weapons/underglow.png")
const ART_SCALE := 0.5
const ART_RADIUS_UNITS := 2.5
const PX_PER_UNIT := 16.0

var look: Resource = LOOK
var radius_px := 0.0
## Seconds of animation so far (advances only while the node processes).
var time := 0.0

var _frame := -1
var _cache: Dictionary = {}  # frame -> ImageTexture, for the current radius
var _texel_o := PackedFloat32Array()  # per candidate texel: flat distance from the edge
var _texel_a := PackedFloat32Array()  # its angle round the circle
var _texel_i := PackedInt32Array()  # its x, y in the image, packed (y * width + x)
var _w := 0
var _h := 0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(delta: float) -> void:
	if not visible:
		return
	set_time(time + delta)


func set_time(t: float) -> void:
	time = t
	var f := frame_at(t)
	if f != _frame:
		_frame = f
		queue_redraw()


func frame_at(t: float) -> int:
	return int(floor(t * float(look.frames_per_second))) % maxi(int(look.cycle_frames), 1)


func set_radius_px(r: float) -> void:
	if not is_equal_approx(r, radius_px):
		radius_px = r
		_cache.clear()
		_texel_i = PackedInt32Array()
		queue_redraw()


## Switches the look's colours and widths (the editor's resource, or a test's).
func set_look(l: Resource) -> void:
	look = l
	_cache.clear()
	_texel_i = PackedInt32Array()
	queue_redraw()


## The sprite's scale: 0.5 at the first tier's radius, growing with the circle.
func art_scale() -> float:
	return ART_SCALE * radius_px / (ART_RADIUS_UNITS * PX_PER_UNIT)


## Pulse step now, 0 to 2: how far the halo and floor glow have breathed out.
func pulse_level(frame: int) -> int:
	var phase := fmod(float(frame) * float(look.pulse_cycles) / float(look.cycle_frames), 1.0)
	return int(round(2.0 * (0.5 - 0.5 * cos(TAU * phase))))


## The shimmer arc's centre angle (flat circle) at `frame`.
func shimmer_angle(frame: int) -> float:
	return TAU * float(frame) * float(look.shimmer_laps) / float(look.cycle_frames)


## How far out the image reaches from the edge, in flat px.
func _out_px() -> float:
	return float(look.halo_near_px) + float(look.halo_far_px) + 2.0 * float(look.pulse_extra_px)


func _in_px() -> float:
	return float(look.ring_core_px) + float(look.ring_mid_px) + float(look.floor_near_px) \
		+ float(look.floor_far_px) + 2.0 * float(look.pulse_extra_px)


## The candidate texels for the current radius: every one near enough the edge to be coloured.
func _prepare() -> void:
	if _texel_i.size() > 0:
		return
	var out_r := radius_px + _out_px() + 1.0
	var hw := int(ceil(out_r * sqrt(2.0))) + 1
	var hh := int(ceil(out_r * sqrt(2.0) / 2.0)) + 1
	_w = hw * 2
	_h = hh * 2
	var lo := -_in_px() - 1.0
	var hi := _out_px() + 1.0
	var os := PackedFloat32Array()
	var an := PackedFloat32Array()
	var idx := PackedInt32Array()
	for j in _h:
		var sy := float(j - hh) + 0.5
		for i in _w:
			var sx := float(i - hw) + 0.5
			# Inverse of the isometric basis: screen pixel -> flat world.
			var fx := sx / 2.0 + sy
			var fy := sy - sx / 2.0
			var o := sqrt(fx * fx + fy * fy) - radius_px
			if o < lo or o > hi:
				continue
			os.append(o)
			an.append(atan2(fy, fx))
			idx.append(j * _w + i)
	_texel_o = os
	_texel_a = an
	_texel_i = idx


## The zone's image at animation `frame` for the current radius: opaque pixels or nothing.
func build_image(frame: int) -> Image:
	_prepare()
	var level := pulse_level(frame)
	var extra := float(level) * float(look.pulse_extra_px)
	var arc_c := shimmer_angle(frame)
	var half_arc := float(look.shimmer_arc) / 2.0
	var core_w := float(look.ring_core_px)
	var mid_w := core_w + float(look.ring_mid_px)
	var fnear_w := mid_w + float(look.floor_near_px) + extra
	var ffar_w := fnear_w + float(look.floor_far_px)
	var hnear_w := float(look.halo_near_px)
	var hfar_w := hnear_w + float(look.halo_far_px) + extra
	var bytes := PackedByteArray()
	bytes.resize(_w * _h * 4)
	var shimmer: Color = look.shimmer_colour
	var core: Color = look.ring_core_colour
	var mid: Color = look.ring_mid_colour
	var hnear: Color = look.halo_near_colour
	var hfar: Color = look.halo_far_colour
	var fnear: Color = look.floor_near_colour
	var ffar: Color = look.floor_far_colour
	for n in _texel_i.size():
		var o := _texel_o[n]
		var pos := _texel_i[n]
		var x := pos % _w
		var y := pos / _w
		var in_arc := absf(wrapf(_texel_a[n] - arc_c, -PI, PI)) <= half_arc
		var c := Color(0, 0, 0, 0)
		if o > 0.0:
			if o <= hnear_w:
				c = mid if in_arc else hnear
			elif o <= hfar_w and (x + y) % 2 == 0:
				c = hnear if in_arc else hfar
		else:
			var q := -o
			if q <= core_w:
				c = shimmer if in_arc else core
			elif q <= mid_w:
				c = core if in_arc else mid
			elif q <= fnear_w:
				if (x + y) % 2 == 0:
					c = fnear
			elif q <= ffar_w:
				if x % 2 == 0 and y % 2 == 0:
					c = ffar
		if c.a > 0.0:
			var p := pos * 4
			bytes[p] = int(round(c.r * 255.0))
			bytes[p + 1] = int(round(c.g * 255.0))
			bytes[p + 2] = int(round(c.b * 255.0))
			bytes[p + 3] = 255
	return Image.create_from_data(_w, _h, false, Image.FORMAT_RGBA8, bytes)


func _draw() -> void:
	if radius_px <= 0.0:
		return
	if look.use_sprite:
		var tex: Texture2D = ART_TEXTURE
		var size := tex.get_size() * art_scale()
		draw_texture_rect(tex, Rect2(-size / 2.0, size), false)
		return
	var f := maxi(_frame, 0)
	if not _cache.has(f):
		_cache[f] = ImageTexture.create_from_image(build_image(f))
	var t: ImageTexture = _cache[f]
	draw_texture(t, -t.get_size() / 2.0)
