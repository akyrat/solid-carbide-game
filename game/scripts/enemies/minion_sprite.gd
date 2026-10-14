extends Node2D
## The minion's drawing (task T-044 placeholder, task T-068 final art), in the
## isometric view's screen pixels: the light green four-legged lizard walking,
## facing the way it walks. The art is 48 x 48 pixel frames, 8 walk frames per
## direction, drawn at the map's scale (32 art pixels per unit shown at 0.5, so
## 16 screen pixels per unit). Five directions are drawn (south, south-east,
## east, north-east, north); south-west, west and north-west are the south-east,
## east and north-east sheets mirrored. If a sheet is missing, the T-044
## placeholder shape is drawn instead. No Redgull red.

const BODY_COLOR := Color(0.55, 0.80, 0.45)
const BELLY_COLOR := Color(0.70, 0.90, 0.55)
const LEG_COLOR := Color(0.30, 0.52, 0.28)
const OUTLINE_COLOR := Color(0.05, 0.07, 0.12)
const EYE_COLOR := Color(0.40, 0.95, 0.95)
const SHADOW_COLOR := Color(0.02, 0.02, 0.05, 0.55)

const FRAME_SIZE := 48
const FRAME_COUNT := 8
## Walk frames per second.
const WALK_FPS := 10.0
const ART_SCALE := 0.5
## The art's centre sits this many screen pixels above the minion's ground point.
const LIFT := 5.0
## Sheet per compass index (0 = east, then clockwise on screen: 1 south-east,
## 2 south, 3 south-west, 4 west, 5 north-west, 6 north, 7 north-east), as
## [sheet name, mirrored].
const SHEETS := [["e", false], ["se", false], ["s", false], ["se", true],
	["e", true], ["ne", true], ["n", false], ["ne", false]]
const SHEET_DIR := "res://art/minion/minion_%s.png"

static var _textures := {}

## Screen direction it faces (normalized); set by the spawner from heading.
var facing := Vector2.RIGHT
## Walk cycle, 0..1, for the legs (and the frame).
var _walk := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_walk = randf()  # so a crowd does not step in unison


func _process(delta: float) -> void:
	_walk = fmod(_walk + delta * (WALK_FPS / FRAME_COUNT), 1.0)
	queue_redraw()


## Sets the facing from a flat-world direction (projected to the screen).
func face(flat_dir: Vector2) -> void:
	var iso := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
	var d: Vector2 = iso.basis_xform(flat_dir)
	if d.length() > 0.001:
		facing = d.normalized()


## Index into SHEETS for a screen direction.
static func compass_index(dir: Vector2) -> int:
	return posmod(roundi(dir.angle() / (PI / 4.0)), 8)


## Walk frame (0 to FRAME_COUNT - 1) for a walk phase of 0 to 1.
static func frame_for(walk: float) -> int:
	return clampi(int(walk * FRAME_COUNT), 0, FRAME_COUNT - 1)


static func _sheet(name: String) -> Texture2D:
	if not _textures.has(name):
		var path := SHEET_DIR % name
		_textures[name] = load(path) if ResourceLoader.exists(path) else null
	return _textures[name]


func _draw() -> void:
	var entry: Array = SHEETS[compass_index(facing)]
	var tex := _sheet(entry[0])
	if tex != null:
		_draw_art(tex, entry[1])
		return
	_draw_placeholder()


func _draw_art(tex: Texture2D, mirrored: bool) -> void:
	_ellipse(Vector2.ZERO, 8.0, 3.5, SHADOW_COLOR)
	var src := Rect2(frame_for(_walk) * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
	var size := FRAME_SIZE * ART_SCALE
	var w := -size if mirrored else size
	draw_texture_rect_region(tex, Rect2(Vector2(-w / 2.0, -size / 2.0 - LIFT), Vector2(w, size)), src)


func _draw_placeholder() -> void:
	var f := facing
	var side := f.orthogonal()
	var lift := Vector2(0, -5)
	# Shadow on the ground.
	_ellipse(Vector2.ZERO, 9.0, 4.0, SHADOW_COLOR)
	# Legs: four short stubs, front pair and back pair swinging opposite.
	var swing := 2.0 if _walk < 0.5 else -2.0
	for k in [[1.0, 1.0], [1.0, -1.0], [-1.0, 1.0], [-1.0, -1.0]]:
		var along: float = k[0] * 4.5 + swing * k[0] * k[1] * 0.5
		var foot: Vector2 = lift * 0.3 + f * along + side * k[1] * 6.0
		var hip: Vector2 = lift + f * k[0] * 4.0 + side * k[1] * 3.0
		draw_line(hip, foot, OUTLINE_COLOR, 3.0)
		draw_line(hip, foot, LEG_COLOR, 1.5)
	# Tail.
	draw_line(lift - f * 6.0, lift - f * 11.0 + side * swing, OUTLINE_COLOR, 3.0)
	draw_line(lift - f * 6.0, lift - f * 11.0 + side * swing, BODY_COLOR, 1.5)
	# Body and head.
	_ellipse(lift, 8.0, 5.0, OUTLINE_COLOR, f)
	_ellipse(lift, 7.0, 4.0, BODY_COLOR, f)
	_ellipse(lift + Vector2(0, 1), 4.0, 2.0, BELLY_COLOR, f)
	var head := lift + f * 8.0
	draw_circle(head, 3.5, OUTLINE_COLOR)
	draw_circle(head, 2.5, BODY_COLOR)
	draw_rect(Rect2(head + f * 1.0 + side * 1.0 - Vector2(0.5, 0.5), Vector2(1, 1)), EYE_COLOR)
	draw_rect(Rect2(head + f * 1.0 - side * 1.0 - Vector2(0.5, 0.5), Vector2(1, 1)), EYE_COLOR)


func _ellipse(c: Vector2, rx: float, ry: float, color: Color, axis: Vector2 = Vector2.RIGHT) -> void:
	var pts := PackedVector2Array()
	var a := axis.normalized()
	var b := a.orthogonal()
	for i in 16:
		var t := TAU * i / 16.0
		pts.append(c + a * cos(t) * rx + b * sin(t) * ry)
	draw_colored_polygon(pts, color)
