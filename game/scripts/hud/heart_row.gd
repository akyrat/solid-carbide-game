class_name HeartRow
extends Control
## The car's hearts in a row at the top left (T-338; HUD and menus, Decisions, "The HUD
## looks like a livestream"; Game loop architecture, Decisions, "Hearts instead of
## health points"). One heart per heart the car can have: full ones for the hearts
## left, empty ones for the hearts lost, no half hearts. T-339's art (heart_full.png and
## heart_empty.png, 18 x 16 shown at 2x). The board's layout page: x36 y24, 220 x 40 at
## 1152 x 648 for the first row; each heart gets a 44 x 40 cell. Past ROW_LENGTH hearts
## (a proposal: 10) a second row starts under the first. A heart lost flashes white and
## shakes down to its empty picture; a heart healed pops back in. The row only shows what
## the run state holds (`set_hearts`); it never changes health.

const FULL_PATH := "res://art/hud/heart_full.png"
const EMPTY_PATH := "res://art/hud/heart_empty.png"
const ART_SCALE := 2
const CELL := Vector2(44, 40)
const ROW_LENGTH := 10
## Never more than this many hearts drawn (three rows).
const MAX_SHOWN := 30
## The layout page's box for the first row: the row is at least this big.
const MIN_SIZE := Vector2(220, 40)
## Seconds the loss flash and the heal pop last.
const LOSS_SECONDS := 0.4
const HEAL_SECONDS := 0.3

## The hearts, left to right, top row first.
var hearts: Array = []
var max_hearts := 0
var full_count := 0
var _full_tex: Texture2D
var _empty_tex: Texture2D
## Per heart index: [kind, seconds left] while it animates.
var _anims: Dictionary = {}


func _init() -> void:
	name = "HeartRow"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_full_tex = load(FULL_PATH)
	_empty_tex = load(EMPTY_PATH)
	custom_minimum_size = MIN_SIZE
	size = MIN_SIZE


## Cell origin of heart `i` inside the row.
static func cell_position(i: int) -> Vector2:
	return Vector2((i % ROW_LENGTH) * CELL.x, (i / ROW_LENGTH) * CELL.y + (i / ROW_LENGTH) * 4)


## Shows `full` full hearts out of `total`. `animate` is false for a first show or a new run.
func set_hearts(full: int, total: int, animate: bool = true) -> void:
	total = clampi(total, 0, MAX_SHOWN)
	full = clampi(full, 0, total)
	if total != hearts.size():
		_rebuild(total)
	var old := full_count
	full_count = full
	max_hearts = total
	for i in total:
		var is_full := i < full
		(hearts[i] as TextureRect).texture = _full_tex if is_full else _empty_tex
	_anims.clear()
	for h: TextureRect in hearts:
		_reset(h)
	if animate:
		for i in range(full, old):
			if i < total:
				_anims[i] = ["loss", LOSS_SECONDS]
		for i in range(old, full):
			_anims[i] = ["heal", HEAL_SECONDS]
	set_process(not _anims.is_empty())
	custom_minimum_size = size_for(total).max(MIN_SIZE)
	size = custom_minimum_size


static func size_for(total: int) -> Vector2:
	if total <= 0:
		return Vector2.ZERO
	var rows := (total - 1) / ROW_LENGTH + 1
	return Vector2(minf(total, ROW_LENGTH) * CELL.x, CELL.y + (rows - 1) * (CELL.y + 4))


func is_full(i: int) -> bool:
	return i < full_count


func is_animating() -> bool:
	return not _anims.is_empty()


func _rebuild(total: int) -> void:
	for h in hearts:
		(h as Node).queue_free()
		remove_child(h)
	hearts.clear()
	for i in total:
		var h := TextureRect.new()
		h.name = "Heart%d" % i
		h.texture = _empty_tex
		h.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h.stretch_mode = TextureRect.STRETCH_SCALE
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.size = _empty_tex.get_size() * ART_SCALE
		h.pivot_offset = h.size / 2.0
		h.position = cell_position(i) + ((CELL - h.size) / 2.0).floor()
		add_child(h)
		hearts.append(h)


func _reset(h: TextureRect) -> void:
	h.scale = Vector2.ONE
	h.modulate = Color.WHITE
	h.rotation = 0.0


func _process(delta: float) -> void:
	Perf.begin(&"hud.hearts")
	advance(delta)
	Perf.end(&"hud.hearts")


## Moves the animations on (called by _process, and by tests).
func advance(delta: float) -> void:
	for i in _anims.keys():
		var a: Array = _anims[i]
		a[1] = maxf(a[1] - delta, 0.0)
		var h: TextureRect = hearts[i]
		if a[0] == "loss":
			var t: float = 1.0 - a[1] / LOSS_SECONDS
			var flash := 1.0 - t
			h.modulate = Color(1.0 + flash * 2.0, 1.0 + flash * 2.0, 1.0 + flash * 2.0)
			h.scale = Vector2.ONE * (1.0 + 0.3 * flash)
			h.rotation = sin(t * TAU * 3.0) * 0.25 * flash
		else:
			var t: float = 1.0 - a[1] / HEAL_SECONDS
			h.scale = Vector2.ONE * (0.4 + 0.6 * t + 0.3 * sin(t * PI))
		if a[1] <= 0.0:
			_reset(h)
			_anims.erase(i)
	set_process(not _anims.is_empty())
