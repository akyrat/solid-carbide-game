class_name ViewersDrop
extends Label
## A crash's "-{viewers lost}" (T-336): it appears on the live viewers counter in the
## warning red and drops away from it, falling faster as it goes and fading, then
## frees itself. Pausable.

const FONT_SIZE := 24

var age := 0.0
var seconds := 0.9
var fall := 70.0
var start := Vector2.ZERO


func _init() -> void:
	name = "ViewersDrop"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_PAUSABLE


## `at` is the drop's top centre at the start, in the counter's pixels.
func setup(t: String, color: Color, at: Vector2, drop_seconds: float, drop_px: float) -> void:
	text = t
	seconds = maxf(drop_seconds, 0.01)
	fall = drop_px
	add_theme_font_override("font", Hud.comic_font())
	add_theme_font_size_override("font_size", FONT_SIZE)
	add_theme_color_override("font_color", color)
	add_theme_color_override("font_outline_color", ViewersCounter.DARK)
	add_theme_constant_override("outline_size", 6)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	size = get_combined_minimum_size()
	start = Vector2(at.x - size.x / 2.0, at.y - size.y)
	_place()


## How far it has fallen (pixels) at its age: gravity, slow at first.
func fallen() -> float:
	var t := clampf(age / seconds, 0.0, 1.0)
	return fall * t * t


func _place() -> void:
	var t := clampf(age / seconds, 0.0, 1.0)
	position = (start + Vector2(0, fallen())).round()
	modulate.a = 1.0 if t < 0.35 else 1.0 - (t - 0.35) / 0.65


func advance(dt: float) -> void:
	age += dt
	_place()
	if age >= seconds:
		queue_free()


func _process(dt: float) -> void:
	advance(dt)
