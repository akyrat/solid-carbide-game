extends Node2D
## The kaiju's placeholder drawing (task T-045), in the isometric view's
## screen pixels (16 per unit, like the map): a large, Godzilla-style shape
## seen from the side, standing on its ground circle (4 units across) and
## 7 units tall, several times the car's size (Visual style, Decisions,
## "The kaiju"). It faces left or right, the way it walks on screen, and
## stomps as it walks. Dark slate green with a lighter belly, pale cyan back
## plates and yellow eyes; not the heart's red. The final kaiju art comes from a
## separate art task and replaces this node's drawing.
##
## Final art (task T-069): 6-frame walk sheets of 224 x 224 pixels in
## `art/kaiju/` (`kaiju_s/se/e/ne/n.png`; south-west, west and north-west mirror
## south-east, east and north-east), drawn at scale 0.5 (16 screen pixels per
## unit, so the 224-pixel canvas is the kaiju's 7 units), the direction chosen
## from the way it walks and a frame from the same walk cycle as the stomp.
## The feet stand on the ground point. If a sheet is missing, the placeholder
## shape below is drawn instead.
##
## Falling (task T-226, a proposal: the kaiju drops off edges too): while it
## falls (set_falling, from the boss controller) it plays the falling
## animation, and a squash for LAND_SECONDS after it lands. Its ground shadow
## stays on the ground under it while it falls (T-454; Visual style, Decisions,
## "Shadows shrink with height"): air_height units below the feet, smaller the
## higher it is (shadow_size.gd), full size again as it lands. The art hook (T-227): falling frames in
## FALL_SHEET_DIR (kaiju_fall_e.png, _se, _s, _ne, _n; the others mirrored),
## FRAME_SIZE square frames in a row, as many as the sheet is wide, played at
## FALL_FPS. Until they exist the placeholder is made by script from the walk
## frames: the stomp at FLAIL_SPEED times its speed and the body tipping back
## and forth about its feet (FALL_TILT radians).
##
## Animations (task T-612; Enemies, Decisions, "The kaiju is animated"): walk,
## windup and death, each one sheet per drawn direction, read from
## res://data/enemies.json, "kaiju_animations" (sheet path, frames, fps, loop;
## frame size, feet and head top shared). The walk loops while it walks; the
## windup plays once while the meteor attack winds up (set_winding_up, from the
## boss controller) and holds its last frame; the death plays once (set_dying)
## and its ground shadow fades with it. Which one plays: death, else the fall,
## else the windup, else the walk (with the landing squash). Everything moves on
## in _process, so the frames stop while the game is paused. The frame format
## for the final art (T-613): game/docs/enemies/kaiju.md, "The kaiju's animations".

const BODY_COLOR := Color(0.20, 0.30, 0.28)
const BELLY_COLOR := Color(0.38, 0.47, 0.40)
const PLATE_COLOR := Color(0.55, 0.92, 0.92)
const OUTLINE_COLOR := Color(0.05, 0.07, 0.12)
const EYE_COLOR := Color(1.0, 0.88, 0.30)
const SHADOW_COLOR := Color(0.02, 0.02, 0.05, 0.55)
const ShadowSizeScript := preload("res://scripts/driving/shadow_size.gd")

## Body radius and height in units (kaiju.gd's RADIUS_UNITS and HEIGHT_UNITS).
const RADIUS_UNITS := 2.0
const HEIGHT_UNITS := 7.0
const PX := 16.0
## The figure below is drawn for a height of DESIGN_HEIGHT_PX and scaled to HEIGHT_UNITS.
const DESIGN_HEIGHT_PX := 160.0

const FRAME_SIZE := 224
const FRAME_COUNT := 6
const ART_SCALE := 0.5
## Where the feet are in the art's frame (y, art pixels), and the top of the head.
const ART_FEET_Y := 203.0
const ART_TOP_Y := 17.0
## Sheet per compass index (0 = east, then clockwise on screen), as [sheet name, mirrored].
const SHEETS := [["e", false], ["se", false], ["s", false], ["se", true],
	["e", true], ["ne", true], ["n", false], ["ne", false]]
const SHEET_DIR := "res://art/kaiju/kaiju_%s.png"
## T-226 / T-227: the falling frames' sheets (see the top).
const FALL_SHEET_DIR := "res://art/kaiju/kaiju_fall_%s.png"
const FALL_FPS := 8.0
const FLAIL_SPEED := 2.5
const FALL_TILT := 0.15
const FALL_WOBBLE_HZ := 1.5
const LAND_SECONDS := 0.25
const LAND_SQUASH := Vector2(1.2, 0.8)

static var _textures := {}
## T-612: the animations' data (EnemyData.kaiju_animations()), read once. Tests
## set config_override (a dictionary in the same format) to use other numbers.
static var config_override := {}
static var _config := {}
## The animations as T-069 drew the walk, for when the data is missing.
const DEFAULT_CONFIG := {
	"frame_size": FRAME_SIZE, "feet": [112, 203], "head_top_y": 17,
	"walk": {"sheet": "res://art/kaiju/kaiju_%s.png", "frames": FRAME_COUNT, "fps": 5.4, "loop": true},
}

## Screen direction it faces (normalized), set by face().
var facing := Vector2.RIGHT
## 1 = facing right on screen, -1 = facing left. Set by face().
var facing_x := -1.0
## Walk cycle, 0..1, for the stomp.
var _walk := 0.0
## T-226: true while the kaiju falls; seconds into the fall; seconds of the
## landing squash left.
var falling := false
var fall_seconds := 0.0
var land_left := 0.0
## T-454: how high the feet are above the ground under it, units (0 standing;
## the boss controller sets it from the fall).
var air_height := 0.0
## T-612: seconds of walking (the walk's frame), true during the meteor
## attack's windup with its seconds, true from the kill with the death's seconds.
var walk_seconds := 0.0
var winding_up := false
var windup_seconds := 0.0
var dying := false
var death_seconds := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(delta: float) -> void:
	Perf.begin(&"kaiju.sprite_anim")
	advance(delta)
	queue_redraw()
	Perf.end(&"kaiju.sprite_anim")


## Moves the animation on `delta` seconds (the walk, the windup, the death, the
## stomp, the fall, the squash).
func advance(delta: float) -> void:
	if dying:
		death_seconds += delta
		return
	_walk = fmod(_walk + delta * 0.9 * (FLAIL_SPEED if falling else 1.0), 1.0)
	walk_seconds += delta
	if winding_up:
		windup_seconds += delta
	if falling:
		fall_seconds += delta
	land_left = maxf(land_left - delta, 0.0)


## T-612: the meteor attack's windup starts (true) or ends (false); the windup
## plays from its first frame each time.
func set_winding_up(on: bool) -> void:
	if on and not winding_up:
		windup_seconds = 0.0
	winding_up = on


## T-612: the kaiju was killed: the death plays once from its first frame.
func set_dying() -> void:
	if dying:
		return
	dying = true
	death_seconds = 0.0
	winding_up = false


## T-612: the animations' data (see the top): config_override when set, else
## res://data/enemies.json's "kaiju_animations", else DEFAULT_CONFIG.
static func config() -> Dictionary:
	if not config_override.is_empty():
		return config_override
	if _config.is_empty():
		var c := EnemyData.new().kaiju_animations()
		_config = c if c.has("walk") else DEFAULT_CONFIG
	return _config


## One animation's data ({sheet, frames, fps, loop}), empty when it has none.
static func anim_data(anim_name: String) -> Dictionary:
	var a = config().get(anim_name, {})
	return a if a is Dictionary else {}


static func frame_size() -> int:
	return int(config().get("frame_size", FRAME_SIZE))


static func feet() -> Vector2:
	var f = config().get("feet", [112, ART_FEET_Y])
	return Vector2(float(f[0]), float(f[1]))


## The sheet of an animation for a drawn direction ("e", "se", "s", "ne", "n"),
## or null when the file is missing.
static func anim_sheet(anim_name: String, dir_name: String) -> Texture2D:
	var a := anim_data(anim_name)
	if not a.has("sheet"):
		return null
	return _sheet_at(String(a.sheet) % dir_name)


## How many frames of `tex` an animation plays: the data's count, at most as
## many as the sheet holds, at least 1.
static func frames_in(anim_name: String, tex: Texture2D) -> int:
	var n := int(anim_data(anim_name).get("frames", 1))
	if tex != null:
		n = mini(n, tex.get_width() / maxi(frame_size(), 1))
	return maxi(n, 1)


## The frame of an animation `seconds` in, out of `count`: looping or held on
## the last one, at the data's fps.
static func frame_at(anim_name: String, seconds: float, count: int) -> int:
	var a := anim_data(anim_name)
	var i := int(floor(maxf(seconds, 0.0) * float(a.get("fps", 1.0)) + 0.0001))
	if bool(a.get("loop", false)):
		return posmod(i, maxi(count, 1))
	return clampi(i, 0, maxi(count, 1) - 1)


## T-612: how long the death plays, seconds (frames / fps).
static func death_length() -> float:
	return EnemyData.animation_seconds(anim_data("death"))


## T-612: what is drawn now: {anim, texture, frame, mirrored}; the texture is
## null when the animation's sheet is missing (the placeholder shape is drawn,
## or for the windup and death, the walk).
func current_frame() -> Dictionary:
	var entry: Array = SHEETS[compass_index(facing)]
	var anim := "walk"
	var seconds := walk_seconds
	if dying:
		anim = "death"
		seconds = death_seconds
	elif winding_up and not falling:
		anim = "windup"
		seconds = windup_seconds
	var tex := anim_sheet(anim, entry[0])
	if tex == null and anim != "walk":
		anim = "walk"
		seconds = walk_seconds
		tex = anim_sheet(anim, entry[0])
	var n := frames_in(anim, tex)
	return {"anim": anim, "texture": tex, "frame": frame_at(anim, seconds, n), "mirrored": entry[1]}


## T-226: the kaiju falls (true) or stands (false), as the minion's sprite.
func set_falling(on: bool) -> void:
	if on and not falling:
		fall_seconds = 0.0
		land_left = 0.0
	elif not on and falling:
		land_left = LAND_SECONDS
	falling = on


## What it plays now: "death" (T-612), "fall", "windup" (T-612), "land" (the
## squash) or "walk".
func animation() -> String:
	if dying:
		return "death"
	if falling:
		return "fall"
	if winding_up:
		return "windup"
	return "land" if land_left > 0.0 else "walk"


## The drawing's transform for the placeholder fall or the squash, about its
## feet (identity while walking).
func anim_transform(placeholder_fall: bool = true) -> Transform2D:
	if falling and placeholder_fall:
		return Transform2D(sin(fall_seconds * TAU * FALL_WOBBLE_HZ) * FALL_TILT, Vector2.ZERO)
	if land_left > 0.0:
		var sc := Vector2.ONE.lerp(LAND_SQUASH, land_left / LAND_SECONDS)
		return Transform2D(0.0, sc, 0.0, Vector2.ZERO)
	return Transform2D.IDENTITY


## The falling frames' sheet for a direction (T-227), or null until it exists.
static func fall_sheet(sheet_name: String) -> Texture2D:
	return _sheet_at(FALL_SHEET_DIR % sheet_name)


## Sets the facing from a flat-world direction (projected to the screen).
func face(flat_dir: Vector2) -> void:
	var iso := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
	var d: Vector2 = iso.basis_xform(flat_dir)
	if d.length() > 0.001:
		facing = d.normalized()
	if absf(d.x) > 0.001:
		facing_x = signf(d.x)


## Index into SHEETS for a screen direction.
static func compass_index(dir: Vector2) -> int:
	return posmod(roundi(dir.angle() / (PI / 4.0)), 8)


## Walk frame (0 to FRAME_COUNT - 1) for a walk phase of 0 to 1.
static func frame_for(walk: float) -> int:
	return clampi(int(walk * FRAME_COUNT), 0, FRAME_COUNT - 1)


## The walk's sheet for a drawn direction (the data's path, T-612).
static func _sheet(sheet_name: String) -> Texture2D:
	return anim_sheet("walk", sheet_name)


static func _sheet_at(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	return _textures[path]


## True when the final art is in the project.
static func has_art() -> bool:
	return _sheet("e") != null


## The drawing's height above its feet, in screen pixels.
static func drawn_height_px() -> float:
	if has_art():
		return (feet().y - float(config().get("head_top_y", ART_TOP_Y))) * ART_SCALE
	return HEIGHT_UNITS * PX


## The drawing's width in screen pixels (its ground circle, as seen in the
## isometric view). The HUD's health bar over the kaiju (T-050) is as wide as
## this; the final art provides the same function.
static func drawn_width_px() -> float:
	return RADIUS_UNITS * PX * sqrt(2.0) * 2.0


## A point of the drawing: x forward (towards the facing), y up from the feet.
func _p(x: float, y: float) -> Vector2:
	return Vector2(x * facing_x, -y)


func _poly(points: Array, color: Color, outline: bool = true) -> void:
	var pts := PackedVector2Array()
	for q in points:
		pts.append(_p(q[0], q[1]))
	if outline:
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, OUTLINE_COLOR, 4.0)
	draw_colored_polygon(pts, color)


func _blob(cx: float, cy: float, rx: float, ry: float, color: Color, outline: bool = true) -> void:
	var pts := []
	for i in 20:
		var t := TAU * i / 20.0
		pts.append([cx + cos(t) * rx, cy + sin(t) * ry])
	_poly(pts, color, outline)


func _draw() -> void:
	if Perf.on: Perf.each_begin(&"draw.kaiju")
	_ground_shadow(RADIUS_UNITS * PX * sqrt(2.0))
	var entry: Array = SHEETS[compass_index(facing)]
	if falling and not dying:
		var fall_tex := fall_sheet(entry[0])
		if fall_tex != null:
			# T-227's frames, as they are.
			var n := maxi(1, fall_tex.get_width() / frame_size())
			_draw_art(fall_tex, entry[1], int(fall_seconds * FALL_FPS) % n)
			if Perf.on: Perf.each_end(&"draw.kaiju")
			return
	var anim := anim_transform()
	var cur := current_frame()
	if cur.texture != null:
		# T-612: the walk, windup or death frame; the fall's placeholder tilt and
		# the landing squash only over the walk.
		draw_set_transform_matrix(anim if cur.anim == "walk" or falling else Transform2D.IDENTITY)
		_draw_art(cur.texture, cur.mirrored, cur.frame)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		if Perf.on: Perf.each_end(&"draw.kaiju")
		return
	if dying:
		# No art at all: the code-drawn placeholder simply goes when it dies.
		if Perf.on: Perf.each_end(&"draw.kaiju")
		return
	var sc := HEIGHT_UNITS * PX / DESIGN_HEIGHT_PX
	draw_set_transform_matrix(anim * Transform2D(0.0, Vector2(sc, sc), 0.0, Vector2.ZERO))
	var stomp := sin(_walk * TAU)
	var lift_a := maxf(stomp, 0.0) * 6.0
	var lift_b := maxf(-stomp, 0.0) * 6.0
	var bob := absf(stomp) * 2.0
	# Tail, sweeping back to the ground.
	_poly([[-20, 56 + bob], [-62, 30], [-96, 6], [-100, 2], [-60, 14], [-16, 34 + bob]], BODY_COLOR)
	# Back leg.
	_poly([[-30, 62 + bob], [-6, 62 + bob], [-4, 8 + lift_b], [-2, lift_b], [-34, lift_b], [-30, 10 + lift_b]], BODY_COLOR)
	# Body, leaning forward.
	_blob(0, 78 + bob, 36, 50, BODY_COLOR)
	_blob(10, 70 + bob, 18, 36, BELLY_COLOR, false)
	# Front leg.
	_poly([[-4, 60 + bob], [22, 60 + bob], [26, 8 + lift_a], [30, lift_a], [-2, lift_a], [0, 10 + lift_a]], BODY_COLOR)
	# Back plates, glowing.
	for k in 5:
		var bx := -30.0 + k * 9.0
		var by := 96.0 + k * 9.0 + bob
		_poly([[bx - 6, by], [bx - 10 - k, by + 16 + k * 2], [bx + 4, by + 2]], PLATE_COLOR)
	# Small arm.
	_poly([[26, 92 + bob], [44, 84 + bob], [48, 74 + bob], [42, 72 + bob], [36, 80 + bob], [24, 84 + bob]], BODY_COLOR)
	# Neck and head with a snout.
	_poly([[8, 112 + bob], [26, 128 + bob], [40, 130 + bob], [24, 104 + bob]], BODY_COLOR, false)
	_blob(30, 132 + bob, 20, 13, BODY_COLOR)
	_poly([[38, 140 + bob], [62, 134 + bob], [64, 124 + bob], [40, 122 + bob]], BODY_COLOR)
	draw_line(_p(46, 127 + bob), _p(62, 128 + bob), OUTLINE_COLOR, 2.0)
	# Eye.
	var eye := _p(36, 138 + bob)
	draw_rect(Rect2(eye - Vector2(3, 2), Vector2(6, 4)), OUTLINE_COLOR)
	draw_rect(Rect2(eye - Vector2(2, 1), Vector2(4, 2)), EYE_COLOR)
	if Perf.on: Perf.each_end(&"draw.kaiju")


func _draw_art(tex: Texture2D, mirrored: bool, frame: int) -> void:
	var fs := frame_size()
	var src := Rect2(frame * fs, 0, fs, fs)
	var size := fs * ART_SCALE
	var w := -size if mirrored else size
	# A negative width flips the frame in place: Godot draws it from the
	# rect's x to x + size (T-226 fix). The feet (T-612: from the data) land on
	# the ground point: mirrored, they are fs - feet.x from the frame's left.
	var f := feet()
	var fx := (fs - f.x) if mirrored else f.x
	draw_texture_rect_region(tex, Rect2(Vector2(-fx * ART_SCALE, -f.y * ART_SCALE), Vector2(w, size)), src)


## T-612: the shadow's alpha: full, fading out with the death.
func shadow_alpha() -> float:
	if not dying:
		return 1.0
	var length := death_length()
	return 0.0 if length <= 0.0 else clampf(1.0 - death_seconds / length, 0.0, 1.0)


func _ground_shadow(full_rx: float) -> void:
	var c := SHADOW_COLOR
	c.a *= shadow_alpha()
	if c.a <= 0.0:
		return
	draw_colored_polygon(shadow_outline(full_rx), c)


## T-454: the ground shadow's outline in the sprite's pixels, for a full
## half-width of `full_rx` pixels: on the ground under the feet (air_height
## units down the screen) and sized by the shared height curve.
func shadow_outline(full_rx: float = RADIUS_UNITS * PX * sqrt(2.0)) -> PackedVector2Array:
	var rx := ShadowSizeScript.size_for_height(full_rx, air_height)
	var c := Vector2(0.0, maxf(air_height, 0.0) * PX)
	var pts := PackedVector2Array()
	for i in 24:
		var t := TAU * i / 24.0
		pts.append(c + Vector2(cos(t) * rx, sin(t) * rx * 0.5))
	return pts
