extends Node2D
## The minion's placeholder drawing (task T-044), in the isometric view's
## screen pixels: a light green four-legged lizard shape seen from above at
## the map's scale (16 pixels per unit), facing the way it walks. The final
## minion art comes from a separate art task and replaces this node's drawing.
## Colours follow Visual style (the minion is light green, not too bright);
## no Redgull red.

const BODY_COLOR := Color(0.55, 0.80, 0.45)
const BELLY_COLOR := Color(0.70, 0.90, 0.55)
const LEG_COLOR := Color(0.30, 0.52, 0.28)
const OUTLINE_COLOR := Color(0.05, 0.07, 0.12)
const EYE_COLOR := Color(0.40, 0.95, 0.95)
const SHADOW_COLOR := Color(0.02, 0.02, 0.05, 0.55)

## Screen direction it faces (normalized); set by the spawner from heading.
var facing := Vector2.RIGHT
## Walk cycle, 0..1, for the legs.
var _walk := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(delta: float) -> void:
	_walk = fmod(_walk + delta * 4.0, 1.0)
	queue_redraw()


## Sets the facing from a flat-world direction (projected to the screen).
func face(flat_dir: Vector2) -> void:
	var iso := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
	var d: Vector2 = iso.basis_xform(flat_dir)
	if d.length() > 0.001:
		facing = d.normalized()


func _draw() -> void:
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
