class_name GiftArrows
extends CanvasLayer
## The gift pack's off-screen arrows (task T-144; the board's answer 5,
## 2026-10-16): while a landed package is off screen, an arrow at the screen's
## edge points to it, one arrow per package. Placeholder look: a pale cyan
## triangle with a dark outline, no Redgull red. Each arrow sits on a track
## MARGIN inside the screen's edges, where the line from the screen's centre to
## the package crosses it, slid along the track when that spot would touch a
## HUD part (the timer, the health column, the coins, the likes bar with its
## row, fire and combo counter), so it stays clear of them.
##
## A CanvasLayer over the HUD (layer 10) and under the level-up screen (15)
## and the pause screen (20). It only draws; gift_drops.gd owns the packages.

const LAYER := 11
## Arrow's length and width, in screen pixels.
const ARROW_SIZE := Vector2(30, 24)
## The track's distance from the screen's edges.
const MARGIN := 12.0
## The space kept between an arrow and any HUD part.
const GAP := 8.0
## How far along the track each try moves when sliding clear of the HUD.
const STEP := 4.0
const FILL := Color8(140, 235, 255)
const OUTLINE := Color8(14, 16, 26)

var drops: Node
var _hud_node: Node = null
## The arrows drawn this frame: {package, position, angle}, angle in radians
## (0 points right, as Vector2.angle()).
var shown: Array = []
var _canvas: Control


func bind(the_drops: Node, the_hud: Node) -> void:
	drops = the_drops
	_hud_node = the_hud
	layer = LAYER
	_canvas = Control.new()
	_canvas.name = "Arrows"
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.draw.connect(_draw_arrows)
	add_child(_canvas)


func _process(_delta: float) -> void:
	refresh()


## Works out the arrows for the landed packages now and redraws them.
func refresh() -> void:
	shown = []
	if drops == null:
		return
	var screen := screen_size()
	var avoid := hud_rects()
	for pkg in drops.landed_packages():
		var at: Vector2 = pkg.get_global_transform_with_canvas().origin
		var placed := place(screen, at, avoid)
		if not placed.is_empty():
			placed["package"] = pkg
			shown.append(placed)
	if _canvas != null:
		_canvas.queue_redraw()


func screen_size() -> Vector2:
	return get_viewport().get_visible_rect().size


## The HUD's parts the arrows keep clear of, in screen pixels.
func hud_rects() -> Array:
	var out: Array = []
	var h := _hud_node
	if h == null or not is_instance_valid(h):
		return out
	for group in [["timer_label"], ["health_label", "health_bar", "left_column"],
			["coins_label"], ["likes_bar", "likes_row", "level_label", "combo_label", "likes_fire"]]:
		var r := Rect2()
		var any := false
		for key in group:
			var c = h.get(key)
			if c == null or not (c is Control):
				continue
			var cr: Rect2 = (c as Control).get_global_rect()
			if key == "coins_label" and c.get_parent() is Control:
				cr = (c.get_parent() as Control).get_global_rect()  # the coins' whole row
			if cr.size.x <= 0.0 and cr.size.y <= 0.0:
				continue
			r = cr if not any else r.merge(cr)
			any = true
		if any:
			out.append(r)
	return out


## Where the arrow for a package at screen point `target` goes on a screen of
## `screen` size, keeping clear of the `avoid` rectangles: {position, angle},
## or {} when the package is on screen (no arrow).
static func place(screen: Vector2, target: Vector2, avoid: Array) -> Dictionary:
	if Rect2(Vector2.ZERO, screen).has_point(target):
		return {}
	var inset := MARGIN + ARROW_SIZE.x / 2.0
	var track := Rect2(Vector2(inset, inset), screen - Vector2(inset, inset) * 2.0)
	var centre := screen / 2.0
	var d := target - centre
	var t := INF
	if absf(d.x) > 0.0001:
		t = minf(t, (track.size.x / 2.0) / absf(d.x))
	if absf(d.y) > 0.0001:
		t = minf(t, (track.size.y / 2.0) / absf(d.y))
	var start := centre + d * t
	var s0 := _track_s(track, start)
	var per := 2.0 * (track.size.x + track.size.y)
	var tries := int(ceil(per / STEP / 2.0))
	for k in tries + 1:
		for dir_sign in ([1.0] if k == 0 else [1.0, -1.0]):
			var p := _track_point(track, s0 + dir_sign * k * STEP)
			if _clear(p, avoid):
				return {"position": p, "angle": (target - p).angle()}
	return {"position": start, "angle": (target - start).angle()}


## The arrow's box on screen when centred on `p` (a square as long as the
## arrow, so it holds the arrow at any angle).
static func arrow_rect(p: Vector2) -> Rect2:
	var side := ARROW_SIZE.x
	return Rect2(p - Vector2(side, side) / 2.0, Vector2(side, side))


static func _clear(p: Vector2, avoid: Array) -> bool:
	var box := arrow_rect(p)
	for r in avoid:
		if (r as Rect2).grow(GAP).intersects(box):
			return false
	return true


## The point `s` pixels along the track's edge, clockwise from its top-left corner.
static func _track_point(r: Rect2, s: float) -> Vector2:
	var w := r.size.x
	var h := r.size.y
	s = fposmod(s, 2.0 * (w + h))
	if s < w:
		return r.position + Vector2(s, 0)
	s -= w
	if s < h:
		return Vector2(r.end.x, r.position.y + s)
	s -= h
	if s < w:
		return Vector2(r.end.x - s, r.end.y)
	s -= w
	return Vector2(r.position.x, r.end.y - s)


## How far along the track (as _track_point) the edge point `p` is.
static func _track_s(r: Rect2, p: Vector2) -> float:
	var w := r.size.x
	var h := r.size.y
	if absf(p.y - r.position.y) < 0.5:
		return p.x - r.position.x
	if absf(p.x - r.end.x) < 0.5:
		return w + p.y - r.position.y
	if absf(p.y - r.end.y) < 0.5:
		return w + h + r.end.x - p.x
	return 2.0 * w + h + r.end.y - p.y


## The arrow's triangle around `p`, pointing along `angle`.
static func arrow_points(p: Vector2, angle: float) -> PackedVector2Array:
	var l := ARROW_SIZE.x / 2.0
	var w := ARROW_SIZE.y / 2.0
	var pts := PackedVector2Array([Vector2(l, 0), Vector2(-l, -w), Vector2(-l * 0.4, 0), Vector2(-l, w)])
	for i in pts.size():
		pts[i] = p + pts[i].rotated(angle)
	return pts


func _draw_arrows() -> void:
	for a in shown:
		var pts := arrow_points(a.position, a.angle)
		_canvas.draw_colored_polygon(pts, FILL)
		var ring := pts.duplicate()
		ring.append(pts[0])
		_canvas.draw_polyline(ring, OUTLINE, 3.0, false)
