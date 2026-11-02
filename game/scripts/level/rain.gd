extends CanvasLayer
## Rain over the map (task T-507; Level design, Decisions, "Rain over the map", and Content,
## "Rain"). Steady light rain for the whole run: slanted drops over the visible map and small
## splashes where drops land, on the ground and on rooftops alike (a splash lands on whatever
## is drawn under it). It changes nothing in driving or enemies: it only draws.
##
## - Layer: a CanvasLayer at LAYER (5), so it draws over the whole world (the map, the car and
##   the enemies, all on the default canvas, layer 0) and under the HUD (layer 10) and every
##   screen above it.
## - Screen space, anchored to the world: drops live in a field the size of the screen that
##   wraps round, shifted by the camera's offset (the main canvas transform), so the rain moves
##   with the map as the car drives and never runs out at the screen's edges. One art pixel is
##   drawn as round(zoom * 16 / 32) screen pixels (at least 1), the size the map's art is drawn
##   at, so the rain sits on the same pixel grid as the art.
## - Placeholder look drawn in code (T-509 swaps in PixelLab art): an opaque streak of pixels
##   and a small three-frame splash, made once as textures (make_drop_image, make_splash_image),
##   so a frame draws one texture per drop and per splash, which the renderer batches. No
##   shaders, no particles: it works the same in the web export. T-509's swap: set
##   "drop_texture" and "splash_texture" (a strip of "splash_frames" frames) in data/rain.json.
## - Numbers: data/rain.json (load_config(); RainData defaults when a key is missing).
## - The setting: GameSettings.load_rain_enabled() on ready, and every save of it
##   (GameSettings.notifier) shows or hides the rain at once. While hidden it neither moves
##   nor draws (processing off).
## - Pausable (the default process mode): the pause screen freezes it with the run.

const LAYER := 5
const DATA_PATH := "res://data/rain.json"
## World pixels per unit (car.gd) and art pixels per unit (Visual style).
const PX_PER_UNIT := 16.0
const ART_PX_PER_UNIT := 32.0
## The screen size drops_per_screen and max_splashes are given for.
const REFERENCE_AREA := 1920.0 * 1080.0
## Extra field round the screen, in art pixels, so drops slide in from beyond the edges.
const MARGIN := 24.0

const DEFAULTS := {
	"drops_per_screen": 220,
	"fall_speed": 900.0,
	"angle_deg": 18.0,
	"drop_length": 10,
	"drop_life_min": 0.25,
	"drop_life_max": 0.9,
	"splash_chance": 0.35,
	"max_splashes": 60,
	"splash_life": 0.24,
	"drop_colour": [170, 190, 220],
	"drop_highlight_colour": [215, 228, 245],
	"splash_colour": [190, 206, 232],
	"drop_texture": "",
	"splash_texture": "",
	"splash_frames": 3,
}

## The look's numbers (DEFAULTS overlaid with data/rain.json).
var config: Dictionary = DEFAULTS.duplicate(true)
## Whether the rain shows (the saved setting, or set_enabled()).
var enabled := true
## Drops: {p: Vector2 (field position, art px), life: float (seconds left)}.
var drops: Array = []
## Splashes: {p: Vector2 (field position, art px), age: float}.
var splashes: Array = []
## How many times _draw ran (tests: no drawing while disabled).
var draw_count := 0
## Seconds of the last _process and _draw (the bench and the perf note).
var last_process_usec := 0
var last_draw_usec := 0
## Test hook: a fixed screen size in place of the viewport's (Vector2.ZERO = the viewport's).
var screen_size_override := Vector2.ZERO
## Test hook: a fixed canvas transform in place of the viewport's.
var canvas_override: Variant = null

var drop_texture: Texture2D
var splash_texture: Texture2D
var _canvas: Node2D
var _rng := RandomNumberGenerator.new()
var _field := Vector2.ONE
var _velocity := Vector2.ZERO


func _init() -> void:
	name = "Rain"
	layer = LAYER


func _ready() -> void:
	load_config()
	_canvas = Node2D.new()
	_canvas.name = "Drops"
	_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_canvas.draw.connect(_on_draw)
	add_child(_canvas)
	GameSettings.notifier.rain_enabled_changed.connect(set_enabled)
	set_enabled(GameSettings.load_rain_enabled())


## Reads data/rain.json (or `path`) over DEFAULTS and rebuilds the textures and the drops.
func load_config(path: String = DATA_PATH) -> void:
	config = DEFAULTS.duplicate(true)
	var data = GameData.unwrap(GameData.load_file(path)) if FileAccess.file_exists(path) else null
	if data is Dictionary:
		for k in DEFAULTS:
			if data.has(k) and typeof(data[k]) in [TYPE_INT, TYPE_FLOAT, TYPE_ARRAY, TYPE_STRING]:
				config[k] = data[k]
	var a := deg_to_rad(float(config.angle_deg))
	# Falling down the screen, leaning toward the left at the bottom (wind from the right),
	# which follows the isometric view's slanting edges (a proposal for the playtest).
	_velocity = Vector2(-sin(a), cos(a)) * float(config.fall_speed)
	drop_texture = _load_texture(str(config.drop_texture))
	if drop_texture == null:
		drop_texture = ImageTexture.create_from_image(make_drop_image(
			int(config.drop_length), float(config.angle_deg),
			_colour(config.drop_colour), _colour(config.drop_highlight_colour)))
	splash_texture = _load_texture(str(config.splash_texture))
	if splash_texture == null:
		splash_texture = ImageTexture.create_from_image(make_splash_image(_colour(config.splash_colour)))
		config.splash_frames = 3
	drops.clear()
	splashes.clear()


## Shows or hides the rain at once (the setting's saves call it through GameSettings.notifier).
func set_enabled(on: bool) -> void:
	enabled = on
	visible = on
	set_process(on)
	if not on:
		drops.clear()
		splashes.clear()
	if _canvas != null:
		_canvas.queue_redraw()


## The screen pixels one art pixel is drawn at: the map's art scale under the camera's zoom.
func pixel_size() -> float:
	var s: float = _canvas_transform().get_scale().x * PX_PER_UNIT / ART_PX_PER_UNIT
	return maxf(1.0, roundf(s))


func screen_size() -> Vector2:
	if screen_size_override != Vector2.ZERO:
		return screen_size_override
	return get_viewport().get_visible_rect().size


## How many drops the current screen holds (drops_per_screen scaled by the screen's area).
func target_drop_count() -> int:
	var s := screen_size()
	return int(round(float(config.drops_per_screen) * s.x * s.y / REFERENCE_AREA))


func max_splash_count() -> int:
	var s := screen_size()
	return maxi(1, int(round(float(config.max_splashes) * s.x * s.y / REFERENCE_AREA)))


func _process(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	step(delta)
	_canvas.queue_redraw()
	last_process_usec = Time.get_ticks_usec() - t0


## Moves the rain on by `delta` seconds: drops fall along the slant; a drop at the end of its
## life may leave a splash where it is, and starts again somewhere else on the screen.
func step(delta: float) -> void:
	var px := pixel_size()
	_field = screen_size() / px + Vector2(MARGIN, MARGIN) * 2.0
	var want := target_drop_count()
	while drops.size() < want:
		drops.append(_new_drop(true))
	if drops.size() > want:
		drops.resize(want)
	var splash_life := float(config.splash_life)
	var kept: Array = []
	for s in splashes:
		s.age += delta
		if s.age < splash_life:
			kept.append(s)
	splashes = kept
	var cap := max_splash_count()
	var chance := float(config.splash_chance)
	var move := _velocity * delta
	for d in drops:
		d.life -= delta
		if d.life <= 0.0:
			if splashes.size() < cap and _rng.randf() < chance:
				splashes.append({"p": d.p + Vector2(0.0, drop_texture.get_height()), "age": 0.0})
			var n := _new_drop(false)
			d.p = n.p
			d.life = n.life
		else:
			d.p += move


func _new_drop(spread_life: bool) -> Dictionary:
	var life := _rng.randf_range(float(config.drop_life_min), float(config.drop_life_max))
	return {
		"p": Vector2(_rng.randf() * _field.x, _rng.randf() * _field.y),
		"life": _rng.randf() * life if spread_life else life,
	}


func _canvas_transform() -> Transform2D:
	if canvas_override != null:
		return canvas_override
	return get_viewport().get_canvas_transform()


## Where a field position is on the screen, in art pixels: the field wraps round and moves
## with the camera, so the rain stays put on the map while the camera follows the car.
func to_screen_art(p: Vector2, px: float) -> Vector2:
	var shift := _canvas_transform().origin / px
	var q := Vector2(fposmod(p.x + shift.x, _field.x), fposmod(p.y + shift.y, _field.y))
	return (q - Vector2(MARGIN, MARGIN)).floor()


func _on_draw() -> void:
	if not enabled:
		return
	var t0 := Time.get_ticks_usec()
	draw_count += 1
	var px := pixel_size()
	_canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2(px, px))
	for d in drops:
		_canvas.draw_texture(drop_texture, to_screen_art(d.p, px))
	var frames: int = maxi(1, int(config.splash_frames))
	var fw := float(splash_texture.get_width()) / frames
	var fh := float(splash_texture.get_height())
	var life := float(config.splash_life)
	for s in splashes:
		var f := mini(frames - 1, int(s.age / life * frames))
		var at := to_screen_art(s.p, px) - Vector2(floorf(fw / 2.0), fh - 1.0)
		_canvas.draw_texture_rect_region(splash_texture, Rect2(at, Vector2(fw, fh)), Rect2(f * fw, 0, fw, fh))
	last_draw_usec = Time.get_ticks_usec() - t0


## The placeholder drop: a 1-pixel streak `length` pixels long, leaning by `angle_deg` the way
## the drops fall (its top to the right), in `colour` with its lowest pixel in `highlight`.
static func make_drop_image(length: int, angle_deg: float, colour: Color, highlight: Color) -> Image:
	length = maxi(2, length)
	var lean := tan(deg_to_rad(angle_deg))
	var w := int(ceil((length - 1) * lean)) + 1
	var img := Image.create(w, length, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in length:
		var x := int(round((length - 1 - y) * lean))
		img.set_pixel(x, y, highlight if y == length - 1 else colour)
	return img


## The placeholder splash: three 7 x 4 frames side by side, a drop's hit, its crown opening,
## and its last two droplets.
static func make_splash_image(colour: Color) -> Image:
	var frames := [
		[".......", ".......", "..x.x..", "...x..."],
		[".......", ".x...x.", "..x.x..", "......."],
		["x.....x", ".......", ".......", "......."],
	]
	var img := Image.create(7 * frames.size(), 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for f in frames.size():
		for y in 4:
			var row: String = frames[f][y]
			for x in 7:
				if row[x] == "x":
					img.set_pixel(f * 7 + x, y, colour)
	return img


static func _colour(v: Variant) -> Color:
	if v is Array and v.size() >= 3:
		return Color8(int(v[0]), int(v[1]), int(v[2]))
	return Color.WHITE


static func _load_texture(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
