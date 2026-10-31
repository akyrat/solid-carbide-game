class_name GiftCardClick
extends Button
## A gift menu card that is clicked directly (T-474; HUD and menus, Decisions,
## "Gift menu cards are clicked directly", board, 2026-10-31). It is a see-through
## button laid over a whole card, so a click anywhere on the card takes it, with no
## "Take it" button. It gives the card the shared button's feel (T-446): a hover
## brightens the card's frame (HudStyle.BUTTON_HOVER_TINT) and a click presses the
## card down (HudStyle.BUTTON_PRESS_DROP pixels). Keyboard selection is the screen's
## own highlight frame. Built to be reused by every gift menu (T-475 applies it to
## the driving power-up overlay): call `GiftCardClick.attach(...)`.

## The card's body (what moves down when pressed) and the frame that is tinted.
var body: Control
var frame: CanvasItem
var hovered := false
var held := false


## Lays a click area over `panel` (the whole card). `on_take` is called when the
## card is clicked. `body` is the part of the card pressed down, `frame` the part
## tinted on hover.
static func attach(panel: Control, card_body: Control, card_frame: CanvasItem, on_take: Callable) -> GiftCardClick:
	var c := GiftCardClick.new()
	c.name = "ClickArea"
	c.body = card_body
	c.frame = card_frame
	c.focus_mode = Control.FOCUS_NONE
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		c.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	c.pressed.connect(on_take)
	c.mouse_entered.connect(c._on_enter)
	c.mouse_exited.connect(c._on_exit)
	c.button_down.connect(c._on_down)
	c.button_up.connect(c._on_up)
	panel.add_child(c)
	return c


## Whether the card takes the mouse (off while a screen builds up).
func set_active(on: bool) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
	if not on:
		_on_exit()
		_on_up()


func _on_enter() -> void:
	hovered = true
	_refresh()


func _on_exit() -> void:
	hovered = false
	_refresh()


func _on_down() -> void:
	held = true
	_refresh()


func _on_up() -> void:
	held = false
	_refresh()


func _refresh() -> void:
	frame.modulate = HudStyle.BUTTON_HOVER_TINT if hovered else Color.WHITE
	body.position.y = HudStyle.BUTTON_PRESS_DROP if held else 0.0
