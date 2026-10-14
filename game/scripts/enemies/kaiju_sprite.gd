extends Node2D
## The kaiju's placeholder drawing (task T-045), in the isometric view's
## screen pixels (16 per unit, like the map): a large, Godzilla-style shape
## seen from the side, standing on its ground circle (4 units across) and
## 7 units tall, several times the car's size (Visual style, Decisions,
## "The kaiju"). It faces left or right, the way it walks on screen, and
## stomps as it walks. Dark slate green with a lighter belly, pale cyan back
## plates and yellow eyes; no Redgull red. The final kaiju art comes from a
## separate art task and replaces this node's drawing.

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
	if absf(d.x) > 0.001:
		facing_x = signf(d.x)


## The drawing's height above its feet, in screen pixels.
static func drawn_height_px() -> float:
	return HEIGHT_UNITS * PX


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


func _ground_shadow(rx: float) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var t := TAU * i / 24.0
		pts.append(Vector2(cos(t) * rx, sin(t) * rx * 0.5))
	draw_colored_polygon(pts, SHADOW_COLOR)
