class_name SlotGrid
extends Control
## One column of equally framed slots (T-523; HUD and menus, Decisions, "Weapon and power-up
## slots"): the weapon grid and the power-up grid are two of these. It draws, in code and in
## the HUD style sheet's look (steel bezel lit from the top left, screen black inside, the
## (8, 8, 15) outline), SLOTS empty frames and, under each slot's icon, a row of tier pips:
## one pip per tier the item can reach, the tiers reached filled. No text. The icons are the
## owner's children, placed at `icon_pos(slot)`; this node only draws.

const SLOTS := 3
const PAD := 4
const ICON := 48
const PIP_H := 6
## A pip is at most this wide; more pips than fit in the icon's width get narrower.
const PIP_W := 8
const PIP_GAP := 2
const PIP_TOP := 3
const SLOT_GAP := 4
const OUTLINE := 2
const BEZEL := 3
const SLOT_SIZE := Vector2(ICON + PAD * 2, PAD + ICON + PIP_TOP + PIP_H + PAD)

const STEEL_LIGHT := Color8(150, 164, 190)
const STEEL := Color8(96, 108, 132)
const STEEL_DARK := Color8(58, 66, 84)
const SCREEN := Color8(10, 12, 17)
const PIP_ON := Color8(235, 242, 255)
const PIP_OFF := Color8(40, 46, 60)

## Per slot: {} for an empty frame, else {"tier": int, "max": int}.
var slots: Array = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in SLOTS:
		slots.append({})
	custom_minimum_size = grid_size()
	size = custom_minimum_size


static func grid_size() -> Vector2:
	return Vector2(SLOT_SIZE.x, SLOTS * SLOT_SIZE.y + (SLOTS - 1) * SLOT_GAP)


## The top left of slot `i`'s icon, in this node's own coordinates.
static func icon_pos(i: int) -> Vector2:
	return Vector2(PAD, i * (SLOT_SIZE.y + SLOT_GAP) + PAD)


## Fills slot `i` (an item with `tier` of `max_tier`), or empties it (tier < 1).
func set_slot(i: int, tier: int, max_tier: int) -> void:
	if i < 0 or i >= SLOTS:
		return
	slots[i] = {} if tier < 1 else {"tier": tier, "max": max_tier}
	queue_redraw()


## The pip count and filled count of slot `i`: [max, filled]; [0, 0] when empty.
func pips(i: int) -> Array:
	var s: Dictionary = slots[i]
	if s.is_empty():
		return [0, 0]
	return [int(s.max), clampi(int(s.tier), 0, int(s.max))]


func _draw() -> void:
	for i in SLOTS:
		var top := i * (SLOT_SIZE.y + SLOT_GAP)
		_draw_frame(Rect2(0, top, SLOT_SIZE.x, SLOT_SIZE.y))
		var p := pips(i)
		if p[0] > 0:
			var w := minf(PIP_W, float(ICON - (p[0] - 1) * PIP_GAP) / p[0])
			var row_w: float = p[0] * w + (p[0] - 1) * PIP_GAP
			var x0 := (SLOT_SIZE.x - row_w) / 2.0
			var y := top + PAD + ICON + PIP_TOP
			for k in p[0]:
				var r := Rect2(x0 + k * (w + PIP_GAP), y, w, PIP_H)
				draw_rect(r, HudStyle.OUTLINE_COLOR)
				draw_rect(r.grow(-1), PIP_ON if k < p[1] else PIP_OFF)


## A stepped-corner steel plate with a black screen inside (style sheet rule 4).
func _draw_frame(r: Rect2) -> void:
	_plate(r, HudStyle.OUTLINE_COLOR)
	var steel := r.grow(-OUTLINE)
	_plate(steel, STEEL)
	draw_rect(Rect2(steel.position.x + 2, steel.position.y, steel.size.x - 2, 2), STEEL_LIGHT)
	draw_rect(Rect2(steel.position.x, steel.position.y + 2, 2, steel.size.y - 2), STEEL_LIGHT)
	draw_rect(Rect2(steel.position.x + 2, steel.end.y - 2, steel.size.x - 2, 2), STEEL_DARK)
	draw_rect(Rect2(steel.end.x - 2, steel.position.y + 2, 2, steel.size.y - 4), STEEL_DARK)
	draw_rect(steel.grow(-BEZEL), SCREEN)


## A rectangle with its corner pixels (radius 2 steps) cut.
func _plate(r: Rect2, c: Color) -> void:
	draw_rect(Rect2(r.position.x + 4, r.position.y, r.size.x - 8, r.size.y), c)
	draw_rect(Rect2(r.position.x + 2, r.position.y + 2, r.size.x - 4, r.size.y - 4), c)
	draw_rect(Rect2(r.position.x, r.position.y + 4, r.size.x, r.size.y - 8), c)
