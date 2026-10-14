extends Node
## Screenshot fixture for the popups' combo heat steps (task T-133): the run
## with one row of popups per heat step, from the top: below x2 (plain), step 1
## (x2), step 2 (x3) and step 3 (x4 up, flaming). Each row shows a normal trick
## popup, a small extended-drift popup and the challenge popup. The flames
## flicker through frames: `frame_age` picks the moment shown.
## Run: bash game/tools/screenshot.sh res://tests/fixtures/popups_heat_demo.tscn screenshots/T-133_popups_heat.png 10

## The popups' age in seconds when frozen (also picks the flame frame).
@export var frame_age := 0.3

const ROW_GAP := 70.0


func _ready() -> void:
	var run: Node2D = preload("res://scenes/run/run.tscn").instantiate()
	add_child(run)
	var tp: Node2D = run.trick_popups
	var at: Vector2 = run.car_sprite.position
	for heat in 4:
		var y := -120.0 + heat * ROW_GAP
		_show(tp, "ALT DRIFT! +0.5", at + Vector2(-210, y), tp.SIZE_NORMAL, heat)
		_show(tp, "LONG DRIFT! +0.05", at + Vector2(-50, y), tp.SIZE_SMALL, heat)
		_show(tp, "Trending! +120 Likes", at + Vector2(140, y), tp.SIZE_NORMAL, heat)


func _show(tp: Node2D, text: String, at: Vector2, size: int, heat: int) -> void:
	# More than TrickPopups.MAX_POPUPS show here, so they are added by hand
	# rather than through show_popup (which keeps three at most).
	var p = tp.PopupText.new()
	p.text = text
	p.font_size = size
	p.anchor = at
	p.heat = heat
	p.z_as_relative = false
	p.z_index = tp.POPUP_Z
	tp.add_child(p)
	p.advance(frame_age)
	p.set_process(false)
	p.set_physics_process(false)
