extends Control
## Screenshot fixture for T-446: the shared button in its five states side by side
## (normal, hovered, keyboard-selected, pressed, disabled), a small pause-size one and
## the shared checkbox, on the main menu's dark background and on a light strip.
## Hovered is drawn with the hovered box and text colour (a still can't hover).

const STATES := ["normal", "hover", "focus", "pressed", "disabled"]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.12)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var light := ColorRect.new()
	light.color = Color(0.93, 0.93, 0.9)
	light.position = Vector2(0, 330)
	light.size = Vector2(1920, 300)
	add_child(light)
	for row in 2:
		var y := 90 + row * 330
		for i in STATES.size():
			var s: String = STATES[i]
			var b := Button.new()
			b.text = s.capitalize()
			b.position = Vector2(40 + i * 220, y)
			b.custom_minimum_size = Vector2(200, 56)
			add_child(b)
			HudStyle.style_button(b)
			match s:
				"hover":
					b.add_theme_stylebox_override("normal", b.get_theme_stylebox("hover"))
					b.add_theme_color_override("font_color", b.get_theme_color("font_hover_color"))
				"focus":
					if row == 0:
						b.grab_focus.call_deferred()
					else:
						b.add_theme_stylebox_override("normal", _with_ring(b))
						b.add_theme_color_override("font_color", b.get_theme_color("font_focus_color"))
				"pressed":
					b.toggle_mode = true
					b.button_pressed = true
				"disabled":
					b.disabled = true
		var small := Button.new()
		small.text = "Restart"
		small.position = Vector2(40, y + 90)
		add_child(small)
		HudStyle.style_button(small, true)
		var check := CheckBox.new()
		check.text = "Don't show again"
		check.button_pressed = row == 0
		check.position = Vector2(260, y + 90)
		add_child(check)
		HudStyle.style_checkbox(check, 28)


## A still of the focus look away from the real focus: the plate with the ring drawn round it.
func _with_ring(b: Button) -> StyleBox:
	b.draw.connect(func():
		var ring := b.get_theme_stylebox("focus")
		ring.draw(b.get_canvas_item(), Rect2(Vector2.ZERO, b.size)))
	return b.get_theme_stylebox("normal")
