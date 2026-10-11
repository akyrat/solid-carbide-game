class_name TrickPopups
extends Node2D
## Comic-style text popups that pop out from the car (task T-091). A trick's
## name appears at the car, rises a little and fades. The challenge popup
## (task T-092) reuses this: call show_popup() with any text.
##
## Placeholder look: a bold outlined text on a dark navy shape; the
## final comic look is task T-084. The node is a child of the world view, so
## it draws in the same (isometric) drawn space as the car sprite.

const TrickDetector := preload("res://scripts/driving/trick_detector.gd")

## Texts approved in task T-082.
const TEXTS := {
	"extended_drift": "LONG DRIFT!",
	"three_sixty": "FULL 360!",
	"alternate_drift": "ALT DRIFT!",
}
## Challenge popup text approved in task T-048 (hud.score_flash); {likes} is the likes gained.
const SCORE_TEXT := "Trending! +{likes} Likes"
## Font sizes in drawn pixels. Extended drift comes every second, so it is smaller.
const SIZE_NORMAL := 28
const SIZE_SMALL := 16
const SIZES := {
	"extended_drift": SIZE_SMALL,
	"three_sixty": SIZE_NORMAL,
	"alternate_drift": SIZE_NORMAL,
}
## Seconds a popup lasts, and how far it rises (drawn pixels).
const LIFETIME := 1.0
const RISE := 40.0
## Start offset above the car's drawn centre, clear of the car and the HUD timer.
const START_OFFSET := Vector2(0, -50)
## PopupText scale at birth, growing to 1 for a quick "pop".
const POP_FROM := 0.5
const POP_TIME := 0.12


## One popup: draws itself and removes itself when its time is up.
class PopupText extends Node2D:
	var text := ""
	var font_size := SIZE_NORMAL
	var age := 0.0
	var start := Vector2.ZERO

	func advance(dt: float) -> void:
		age += dt
		var t := clampf(age / LIFETIME, 0.0, 1.0)
		position = start + Vector2(0, -RISE * (1.0 - pow(1.0 - t, 2.0)))
		var s := lerpf(POP_FROM, 1.0, clampf(age / POP_TIME, 0.0, 1.0))
		scale = Vector2(s, s)
		modulate.a = 1.0 if t < 0.5 else 1.0 - (t - 0.5) * 2.0
		if age >= LIFETIME:
			queue_free()

	func _process(dt: float) -> void:
		advance(dt)

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var half := size / 2.0 + Vector2(10, 4)
		var shape := PackedVector2Array()
		# A simple burst: a hexagon-like shape with pointed sides.
		shape.append(Vector2(-half.x - 8, 0))
		shape.append(Vector2(-half.x, -half.y))
		shape.append(Vector2(half.x, -half.y))
		shape.append(Vector2(half.x + 8, 0))
		shape.append(Vector2(half.x, half.y))
		shape.append(Vector2(-half.x, half.y))
		draw_colored_polygon(shape, Color(0.12, 0.08, 0.30))
		var closed := shape.duplicate()
		closed.append(shape[0])
		draw_polyline(closed, Color(0.0, 0.9, 1.0), 3.0)
		var origin := Vector2(-size.x / 2.0, size.y / 4.0)
		draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, Color(0.04, 0.02, 0.12))
		draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 0.25, 0.75))


var _car: Node = null
## Returns the car's drawn position (set by bind()).
var _car_position: Callable
## Returns the car's drawn position for the challenge popup (set by bind_score()).
var _score_car_position: Callable


## Shows the popups for a car's `trick` signal. `car_position` is a Callable
## returning where the car is drawn. Call again after the car is rebuilt.
func bind(car: Node, car_position: Callable) -> void:
	if _car != null and is_instance_valid(_car) and _car.trick.is_connected(_on_trick):
		_car.trick.disconnect(_on_trick)
	_car = car
	_car_position = car_position
	car.trick.connect(_on_trick)


## Shows the challenge popup for a run state's `score` signal (task T-092).
## `car_position` returns where the car is drawn.
func bind_score(run_state: Node, car_position: Callable) -> void:
	_score_car_position = car_position
	if not run_state.score.is_connected(_on_score):
		run_state.score.connect(_on_score)


func _on_score(amount: float, _challenge_id: String) -> void:
	show_popup(SCORE_TEXT.format({"likes": int(roundf(amount))}), _score_car_position.call(), SIZE_NORMAL)


func _on_trick(trick_id: String) -> void:
	if not TEXTS.has(trick_id):
		return
	show_popup(TEXTS[trick_id], _car_position.call(), SIZES[trick_id])


## Pops `text` out at `at` (drawn position of the car). Any text works.
func show_popup(text: String, at: Vector2, font_size: int = SIZE_NORMAL) -> PopupText:
	var p := PopupText.new()
	p.text = text
	p.font_size = font_size
	p.start = at + START_OFFSET
	p.z_index = 100
	add_child(p)
	p.advance(0.0)
	return p


func popups() -> Array:
	return get_children().filter(func(c: Node) -> bool: return c is PopupText and not c.is_queued_for_deletion())
