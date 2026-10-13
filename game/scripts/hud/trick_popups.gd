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
## Task T-125 round 2: 75% of the old 0.8, for the normal and the small size alike.
const PIXEL_SCALE := 0.6
## Seconds a popup lasts, and how far it rises (drawn pixels).
const LIFETIME := 1.0
const RISE := 40.0
## Start offset above the car's drawn centre, clear of the car and the HUD timer.
const START_OFFSET := Vector2(0, -50)
## PopupText scale at birth, growing to 1 for a quick "pop".
const POP_FROM := 0.5
const POP_TIME := 0.12
## Space kept between popups shown close together, and the step the search for
## free space moves up by (drawn pixels).
const STACK_GAP := 4.0
const STACK_STEP := 4.0
## How far up the screen a popup may reach, as a share of the screen height
## measured from the car (the camera keeps the car at the screen's centre, so
## 0.25 is half way from the car to the top edge). Task T-125, round 2.
const MAX_REACH := 0.25


## One popup: draws itself and removes itself when its time is up. It is placed
## relative to the car's drawn position for its whole life (task T-125): every
## physics step `follow` is asked where the car is drawn, and the popup sits
## START_OFFSET (plus its stack offset) above that, rising RISE relative to it.
## The position is set in the physics step, like the car sprite and the
## camera, so physics interpolation smooths it the same way and it never shakes.
class PopupText extends Node2D:
	var text := ""
	var font_size := SIZE_NORMAL
	var age := 0.0
	## Where the car is drawn when the popup was born, and a Callable returning
	## where it is drawn now (empty: the popup stays at `anchor`).
	var anchor := Vector2.ZERO
	var follow := Callable()
	## Extra offset (zero or negative, upwards) so popups born together don't overlap.
	var stack := 0.0

	func rise() -> float:
		var t := clampf(age / LIFETIME, 0.0, 1.0)
		return RISE * (1.0 - pow(1.0 - t, 2.0))

	## The popup's offset from the car's drawn position now.
	func offset() -> Vector2:
		return START_OFFSET + Vector2(0, stack - rise())

	func size() -> Vector2:
		return Vector2(Art.texture(text, Art.style_for(font_size)).get_size()) * PIXEL_SCALE

	## The car's drawn position now (the last known one if it cannot be asked).
	func anchor_now() -> Vector2:
		if follow.is_valid():
			anchor = follow.call()
		return anchor

	## Puts the popup at the car's drawn position plus its offset.
	func place() -> void:
		position = anchor_now() + offset()
		# Fallback when even an unstacked popup would reach too high (a very
		# close zoom): sit lower, never above the limit.
		var parent := get_parent()
		if parent != null and parent.has_method("top_limit"):
			var limit: float = parent.top_limit()
			if limit < 0.0:
				position.y = maxf(position.y, anchor.y + limit + size().y / 2.0)

	## `with_position` is false in the game's frames: the position is set in
	## the physics step instead (see place()).
	func advance(dt: float, with_position := true) -> void:
		age += dt
		var t := clampf(age / LIFETIME, 0.0, 1.0)
		if with_position:
			place()
		var s := lerpf(POP_FROM, 1.0, clampf(age / POP_TIME, 0.0, 1.0))
		scale = Vector2(s, s)
		modulate.a = 1.0 if t < 0.5 else 1.0 - (t - 0.5) * 2.0
		if age >= LIFETIME:
			queue_free()

	func _process(dt: float) -> void:
		advance(dt, false)

	func _physics_process(_dt: float) -> void:
		place()

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
	show_popup(trick_text(trick_id, added), _combo_car_position.call(), SIZES[trick_id], _combo_car_position)


func _on_score(amount: float, _challenge_id: String) -> void:
	show_popup(SCORE_TEXT.format({"likes": int(roundf(amount))}), _score_car_position.call(), SIZE_NORMAL, _score_car_position)


func _on_trick(trick_id: String) -> void:
	if _from_combo or not TEXTS.has(trick_id):
		return
	show_popup(TEXTS[trick_id], _car_position.call(), SIZES[trick_id], _car_position)


## Pops `text` out above `at` (drawn position of the car). Any text works.
## With `follow` (a Callable returning where the car is drawn) the popup follows
## the car for its whole life (task T-125); without it, it stays at `at`.
## A popup that would overlap one already showing is moved up until it doesn't.
func show_popup(text: String, at: Vector2, font_size: int = SIZE_NORMAL, follow := Callable()) -> PopupText:
	var p := PopupText.new()
	p.text = text
	p.font_size = font_size
	p.anchor = at
	p.follow = follow
	p.stack = _free_stack(p)
	p.z_index = 100
	add_child(p)
	p.advance(0.0)
	p.reset_physics_interpolation()
	return p


## The smallest upward offset (zero or negative) at which `p`, born now, does
## not overlap any popup showing.
func _free_stack(p: PopupText) -> float:
	var others := popups()
	var stack := 0.0
	# The lowest (most upward) stack at which the popup still ends, after its
	# whole rise, at or below top_limit(). When the stack would go higher, the
	# oldest popup makes room (it is removed) until the newcomer fits.
	var limit := top_limit()
	var min_stack := -INF
	if limit < 0.0:
		min_stack = minf(0.0, limit - START_OFFSET.y + RISE + p.size().y / 2.0)
	for _i in 200:
		if stack < min_stack:
			if others.is_empty():
				return min_stack
			var oldest = others[0]
			for o in others:
				if o.age > oldest.age:
					oldest = o
			oldest.queue_free()
			others.erase(oldest)
			stack = 0.0
			continue
		var rect := Rect2(p.anchor + START_OFFSET + Vector2(0, stack) - p.size() / 2.0, p.size())
		var clear := true
		for o in others:
			var orect := Rect2(o.anchor_now() + o.offset() - o.size() / 2.0, o.size()).grow(STACK_GAP / 2.0)
			if rect.grow(STACK_GAP / 2.0).intersects(orect):
				clear = false
				break
		if clear:
			return stack
		stack -= STACK_STEP
	return stack


## The highest a popup's top edge may be, as an offset from the car's drawn
## position (negative, in drawn pixels): MAX_REACH of the screen height, in
## screen space, so it holds at any window size and camera zoom. Zero when
## there is no camera to keep the car at the screen's centre.
func top_limit() -> float:
	if not is_inside_tree() or get_viewport() == null or get_viewport().get_camera_2d() == null:
		return 0.0
	# Screen pixels per drawn pixel: the camera's zoom times the world view's own scale.
	var per_drawn_px := get_viewport().get_camera_2d().zoom.y * get_global_transform().y.length()
	if per_drawn_px <= 0.0:
		return 0.0
	return -get_viewport().get_visible_rect().size.y * MAX_REACH / per_drawn_px


func popups() -> Array:
	return get_children().filter(func(c: Node) -> bool: return c is PopupText and not c.is_queued_for_deletion())
