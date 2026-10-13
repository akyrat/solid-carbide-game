class_name TrickPopups
extends Node2D
## Comic-style text popups that pop out from the car (task T-091). A trick's
## name appears at the car, rises a little and fades. The challenge popup
## (task T-092) reuses this: call show_popup() with any text.
##
## The comic look (task T-084) is baked by trick_popup_art.gd: a jagged burst
## around the text lettered in Bangers, one pixel image per text and size. The
## node is a child of the world view, so it draws in the same (isometric)
## drawn space as the car sprite.

const TrickDetector := preload("res://scripts/driving/trick_detector.gd")
const Art := preload("res://scripts/hud/trick_popup_art.gd")

## Texts approved in task T-082.
const TEXTS := {
	"extended_drift": "LONG DRIFT!",
	"three_sixty": "FULL 360!",
	"alternate_drift": "ALT DRIFT!",
}
## Combo amount text approved in task T-082 (combo.added); {amount} is what the trick added.
const ADDED_TEXT := "+{amount}"
## Challenge popup text approved in task T-048 (hud.score_flash); {likes} is the likes gained.
const SCORE_TEXT := "Trending! +{likes} Likes"
## Sizes: SIZE_SMALL or less bakes the small popup, anything more the normal one
## (the numbers are the old drawn font sizes). Extended drift comes every
## second, so it is smaller.
const SIZE_NORMAL := 28
const SIZE_SMALL := 16
const SIZES := {
	"extended_drift": SIZE_SMALL,
	"three_sixty": SIZE_NORMAL,
	"alternate_drift": SIZE_NORMAL,
}
## Drawn pixels per popup image pixel: one popup pixel is 2 art pixels (0.4 drawn px each).
const PIXEL_SCALE := 0.8
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

	func _ready() -> void:
		# Hard pixel edges, never smoothed (Visual style).
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _draw() -> void:
		if text == "":
			return
		var tex := Art.texture(text, Art.style_for(font_size))
		var size := Vector2(tex.get_size()) * PIXEL_SCALE
		draw_texture_rect(tex, Rect2(-size / 2.0, size), false)


var _car: Node = null
## Returns the car's drawn position (set by bind()).
var _car_position: Callable
## Returns the car's drawn position for the challenge popup (set by bind_score()).
var _score_car_position: Callable
## Returns the car's drawn position for the combo popups (set by bind_combo()).
var _combo_car_position: Callable
## True once bind_combo() is used: the run state's combo_trick then shows the
## trick popups (with the amount added), not the car's trick signal.
var _from_combo := false


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


## Shows the trick popups from a run state's `combo_trick` signal (task T-083):
## the trick's name and what it added to the combo. Once used, the car's own
## `trick` signal no longer shows a popup (the run state hears it too).
func bind_combo(run_state: Node, car_position: Callable) -> void:
	_combo_car_position = car_position
	_from_combo = true
	if not run_state.combo_trick.is_connected(_on_combo_trick):
		run_state.combo_trick.connect(_on_combo_trick)


## The popup text for a trick: its name and, when it added something, "+{amount}".
## At the cap the trick adds nothing and only the name shows.
static func trick_text(trick_id: String, added: float) -> String:
	var text: String = TEXTS.get(trick_id, "")
	if text != "" and added > 0.0:
		text += " " + ADDED_TEXT.format({"amount": String.num(added, 2)})
	return text


func _on_combo_trick(trick_id: String, added: float, _multiplier: float) -> void:
	if not TEXTS.has(trick_id):
		return
	show_popup(trick_text(trick_id, added), _combo_car_position.call(), SIZES[trick_id])


func _on_score(amount: float, _challenge_id: String) -> void:
	show_popup(SCORE_TEXT.format({"likes": int(roundf(amount))}), _score_car_position.call(), SIZE_NORMAL)


func _on_trick(trick_id: String) -> void:
	if _from_combo or not TEXTS.has(trick_id):
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
