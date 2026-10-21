extends Node2D
## The exhaust flame's drawing (task T-071, the final art; it replaced T-042's particle placeholder).
##
## The flamethrower (exhaust_flamethrower.gd) puts this node on the car's exhaust, sets `position`, `rotation`
## (the screen angle the flame points at: back from the car) and `scale` (the flame's size) every step, and
## `emitting` (whether the flame is on). The node draws the matching cell of the flame sheet (game/art/effects/
## exhaust_flame_sheet.png, made by game/tools/build_weapon_effects.py): 32 screen directions in two flicker
## frames, the flame's base at each cell's centre. It counters its own rotation, so the pixels are never
## rotated by the engine; the nearest of the 32 pre-turned flames is drawn. Only `scale` stretches it.

const SHEET := preload("res://art/effects/exhaust_flame_sheet.png")
const CELL := 224
const COLUMNS := 8
const DIRECTIONS := 32
const FRAMES := 2
## The art is drawn at 32 art pixels per unit, shown at 0.5.
const ART_SCALE := 0.5
## How often the flicker changes, in seconds.
const FLICKER_SECONDS := 0.08

## Whether the flame is on (the flamethrower sets it).
var emitting := false:
	set(value):
		if value != emitting:
			emitting = value
			queue_redraw()
var _frame := 0
var _clock := 0.0
var _drawn_cell := -1


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visible = false


## Index (0 to 31) of the pre-turned flame nearest to a screen angle in radians.
static func direction_index(angle: float) -> int:
	return posmod(roundi(angle / (TAU / DIRECTIONS)), DIRECTIONS)


## Cell of the sheet for a direction and a flicker frame.
static func cell_index(direction: int, frame: int) -> int:
	return frame * DIRECTIONS + direction


func _process(delta: float) -> void:
	visible = emitting
	if not emitting:
		return
	_clock += delta
	if _clock >= FLICKER_SECONDS:
		_clock = 0.0
		_frame = (_frame + 1) % FRAMES
	var cell := cell_index(direction_index(rotation), _frame)
	if cell != _drawn_cell:
		_drawn_cell = cell
		queue_redraw()


func current_cell() -> int:
	return cell_index(direction_index(rotation), _frame)


func _draw() -> void:
	if not emitting:
		return
	var cell := current_cell()
	var src := Rect2(Vector2((cell % COLUMNS) * CELL, (cell / COLUMNS) * CELL), Vector2(CELL, CELL))
	# Undo this node's own rotation (the cell is already turned), then draw the cell centred on the base.
	draw_set_transform(Vector2.ZERO, -rotation, Vector2(ART_SCALE, ART_SCALE))
	draw_texture_rect_region(SHEET, Rect2(Vector2(-CELL / 2.0, -CELL / 2.0), Vector2(CELL, CELL)), src)
