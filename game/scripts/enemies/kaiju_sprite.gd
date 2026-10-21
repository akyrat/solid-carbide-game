extends Node2D
## The kaiju's placeholder drawing (task T-045), in the isometric view's
## screen pixels (16 per unit, like the map): a large, Godzilla-style shape
## seen from the side, standing on its ground circle (4 units across) and
## 7 units tall, several times the car's size (Visual style, Decisions,
## "The kaiju"). It faces left or right, the way it walks on screen, and
## stomps as it walks. Dark slate green with a lighter belly, pale cyan back
## plates and yellow eyes; no Redgull red. The final kaiju art comes from a
## separate art task and replaces this node's drawing.
##
## Final art (task T-069): 6-frame walk sheets of 224 x 224 pixels in
## `art/kaiju/` (`kaiju_s/se/e/ne/n.png`; south-west, west and north-west mirror
## south-east, east and north-east), drawn at scale 0.5 (16 screen pixels per
## unit, so the 224-pixel canvas is the kaiju's 7 units), the direction chosen
## from the way it walks and a frame from the same walk cycle as the stomp.
## The feet stand on the ground point. If a sheet is missing, the placeholder
## shape below is drawn instead.

const BODY_COLOR := Color(0.20, 0.30, 0.28)
const BELLY_COLOR := Color(0.38, 0.47, 0.40)
const PLATE_COLOR := Color(0.55, 0.92, 0.92)
const OUTLINE_COLOR := Color(0.05, 0.07, 0.12)
const EYE_COLOR := Color(1.0, 0.88, 0.30)
const SHADOW_COLOR := Color(0.02, 0.02, 0.05, 0.55)

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

static var _textures := {}

## Screen direction it faces (normalized), set by face().
var facing := Vector2.RIGHT
## 1 = facing right on screen, -1 = facing left. Set by face().
var facing_x := -1.0
## Walk cycle, 0..1, for the stomp.
var _walk := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(delta: float) -> void:
	_walk = fmod(_walk + delta * 0.9, 1.0)
	queue_redraw()


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


static func _sheet(sheet_name: String) -> Texture2D:
	if not _textures.has(sheet_name):
		var path := SHEET_DIR % sheet_name
		_textures[sheet_name] = load(path) if ResourceLoader.exists(path) else null
	return _textures[sheet_name]


## True when the final art is in the project.
static func has_art() -> bool:
	return _sheet("e") != null


## The drawing's height above its feet, in screen pixels.
static func drawn_height_px() -> float:
	if has_art():
		return (ART_FEET_Y - ART_TOP_Y) * ART_SCALE
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
	var gr := RADIUS_UNITS * PX * sqrt(2.0)
	_ground_shadow(gr)
	var entry: Array = SHEETS[compass_index(facing)]
	var tex := _sheet(entry[0])
	if tex != null:
		_draw_art(tex, entry[1])
		return
	var sc := HEIGHT_UNITS * PX / DESIGN_HEIGHT_PX
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(sc, sc))
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


func _draw_art(tex: Texture2D, mirrored: bool) -> void:
	var src := Rect2(frame_for(_walk) * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
	var size := FRAME_SIZE * ART_SCALE
	var w := -size if mirrored else size
	draw_texture_rect_region(tex, Rect2(Vector2(-w / 2.0, -ART_FEET_Y * ART_SCALE), Vector2(w, size)), src)


func _ground_shadow(rx: float) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var t := TAU * i / 24.0
		pts.append(Vector2(cos(t) * rx, sin(t) * rx * 0.5))
	draw_colored_polygon(pts, SHADOW_COLOR)
