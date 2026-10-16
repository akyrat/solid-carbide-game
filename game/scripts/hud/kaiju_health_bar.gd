class_name KaijuHealthBar
extends Node2D
## The kaiju's health bar (task T-050; HUD and menus, Decisions, board
## 2026-10-15): a bar on top of the kaiju, in the world, following it. About as
## wide as the kaiju's drawing (the width is read from the kaiju's sprite, so
## the final art keeps working), a neon purple fill on white with a black
## outline and thin black dividers at every 10% of its health, in a subtle
## version of the trick popups' comic look (stepped pixel corners, hard pixel
## edges). No text. Hidden until the kaiju appears and after it dies.
##
## It is a child of the run's world view (like the trick popups) and is fed by
## the boss's signals (kaiju_boss.gd): kaiju_appeared, kaiju_health_changed and
## kaiju_defeated. Its absolute depth is at the top of Godot's drawing range
## (as the popups', T-132), so no building hides it. Drawn in code, never
## Redgull red.

const FILL_COLOR := Color(0.72, 0.18, 1.0)  # neon purple
const BACK_COLOR := Color.WHITE
const LINE_COLOR := Color.BLACK
## Bar height inside the outline, and the outline's thickness (view pixels).
const BAR_HEIGHT := 8.0
const OUTLINE := 2.0
## Space between the top of the kaiju's drawing and the bar's bottom.
const GAP := 8.0
## Dividers: one every 10% of the health.
const DIVISIONS := 10
## Width used when the sprite cannot say how wide it is (view pixels).
const FALLBACK_WIDTH := 64.0
const BAR_Z := RenderingServer.CANVAS_ITEM_Z_MAX

## The health shown, 0..1.
var fraction := 1.0
## The inner width of the bar now (view pixels, whole).
var bar_width := FALLBACK_WIDTH

var _boss: Node = null


func _init() -> void:
	name = "KaijuHealthBar"
	visible = false
	z_as_relative = false
	z_index = BAR_Z
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# After the boss has placed the sprite this step, so the bar never lags it.
	process_physics_priority = 100


func bind(boss: Node) -> void:
	_boss = boss
	boss.kaiju_appeared.connect(_on_appeared)
	boss.kaiju_health_changed.connect(_on_health_changed)
	boss.kaiju_defeated.connect(_on_defeated)


func _on_appeared(_k: Node) -> void:
	visible = true
	_follow()


func _on_health_changed(health: float, max_health: float) -> void:
	fraction = clampf(health / maxf(max_health, 0.001), 0.0, 1.0)
	queue_redraw()


func _on_defeated(_coins: int) -> void:
	visible = false


func _physics_process(_dt: float) -> void:
	_follow()


## Sits above the kaiju's drawing, as wide as it is. Hides when there is no
## kaiju (a new run took it away).
func _follow() -> void:
	var k = _boss.get("kaiju") if _boss != null else null
	if k == null or not is_instance_valid(k) or k.sprite == null or not is_instance_valid(k.sprite):
		visible = false
		return
	visible = true
	var s: Node2D = k.sprite
	var w := FALLBACK_WIDTH
	var h := 0.0
	if s.has_method("drawn_width_px"):
		w = s.drawn_width_px()
	if s.has_method("drawn_height_px"):
		h = s.drawn_height_px()
	w = roundf(w)
	if w != bar_width:
		bar_width = w
		queue_redraw()
	position = (s.position + Vector2(0.0, -(h + GAP + OUTLINE))).round()


## The x of the divider after `i` tenths, from the bar's left edge (whole pixels).
func divider_x(i: int) -> float:
	return roundf(bar_width * float(i) / DIVISIONS)


func _draw() -> void:
	var w := bar_width
	var left := -w / 2.0
	var top := -BAR_HEIGHT
	# Black outline with stepped corners (a rect, minus the four corner pixels).
	var o := OUTLINE
	draw_rect(Rect2(left - o, top, w + 2.0 * o, BAR_HEIGHT), LINE_COLOR)
	draw_rect(Rect2(left, top - o, w, BAR_HEIGHT + 2.0 * o), LINE_COLOR)
	# White back, then the neon purple fill from the left.
	draw_rect(Rect2(left, top, w, BAR_HEIGHT), BACK_COLOR)
	var fill_w := roundf(w * fraction)
	if fill_w > 0.0:
		draw_rect(Rect2(left, top, fill_w, BAR_HEIGHT), FILL_COLOR)
	# Thin black dividers at every 10%.
	for i in range(1, DIVISIONS):
		draw_rect(Rect2(left + divider_x(i) - 0.5, top, 1.0, BAR_HEIGHT), LINE_COLOR)
