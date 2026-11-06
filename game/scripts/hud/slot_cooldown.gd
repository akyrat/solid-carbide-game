class_name SlotCooldown
extends Control
## A cooldown drawn over a slot's icon like a loading bar (T-528; HUD and menus, Decisions,
## "Weapon and power-up slots"; first user: the Polarized Steering Wheel, Drifting, Decisions,
## "A cooldown for the Polarized Steering Wheel"). Drawn in code, hard pixel edges, no text.
##
## `fraction_left` is 1 right after the power-up fired (the whole slot veiled, spent) and 0 when
## it is ready (nothing drawn). The veil shrinks from the bottom up in `STEP`-pixel steps, so
## the icon "fills" from the bottom, with a thin light edge on the line. When the source says
## it is ready again, the slot flashes white for `FLASH_SECONDS` in `FLASH_STEPS` steps.
##
## Any power-up with a cooldown can use it: give it a source that has
## `cooldown_fraction_left() -> float` and, optionally, `signal ready_again`. A source without
## the method counts as no cooldown (always ready).

const SIDE := 48
const STEP := 2
const VEIL := Color(0.031, 0.047, 0.059, 0.74)
const EDGE := Color8(235, 242, 255)
const EDGE_H := 2
const FLASH := Color(1.0, 1.0, 1.0)
const FLASH_ALPHA := 0.6
const FLASH_SECONDS := 0.3
const FLASH_STEPS := 4

var fraction_left := 0.0
## Seconds of the ready flash left; 0 = none.
var flash_left := 0.0
var _source: Object = null


func _init() -> void:
	name = "SlotCooldown"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(SIDE, SIDE)
	size = custom_minimum_size


## Follows `source` (polled every frame) and flashes on its `ready_again`.
func bind_source(source: Object) -> void:
	if _source != null and is_instance_valid(_source) and _source.has_signal("ready_again") \
			and _source.is_connected("ready_again", flash_ready):
		_source.disconnect("ready_again", flash_ready)
	_source = source
	if _source != null and _source.has_signal("ready_again"):
		_source.connect("ready_again", flash_ready)
	_poll()


func set_fraction(f: float) -> void:
	f = clampf(f, 0.0, 1.0)
	if f != fraction_left:
		fraction_left = f
		queue_redraw()


func flash_ready() -> void:
	flash_left = FLASH_SECONDS
	queue_redraw()


## The veiled part, in this node's coordinates: the top `fraction_left` of the slot, in steps.
func veil_rect() -> Rect2:
	var h := ceili(fraction_left * SIDE / STEP) * STEP
	return Rect2(0, 0, SIDE, mini(h, SIDE))


## The flash's alpha now, in `FLASH_STEPS` steps from FLASH_ALPHA down to 0.
func flash_alpha() -> float:
	if flash_left <= 0.0:
		return 0.0
	var step := ceili(flash_left / FLASH_SECONDS * FLASH_STEPS)
	return FLASH_ALPHA * step / FLASH_STEPS


func _process(delta: float) -> void:
	_poll()
	if flash_left > 0.0:
		flash_left = maxf(0.0, flash_left - delta)
		queue_redraw()


func _poll() -> void:
	if _source != null and is_instance_valid(_source) and _source.has_method("cooldown_fraction_left"):
		set_fraction(float(_source.call("cooldown_fraction_left")))
	else:
		set_fraction(0.0)


func _draw() -> void:
	var v := veil_rect()
	if v.size.y > 0.0:
		draw_rect(v, VEIL)
		if v.size.y < SIDE:
			draw_rect(Rect2(0, maxf(0.0, v.size.y - EDGE_H), SIDE, EDGE_H), EDGE)
	var a := flash_alpha()
	if a > 0.0:
		draw_rect(Rect2(0, 0, SIDE, SIDE), Color(FLASH, a))
