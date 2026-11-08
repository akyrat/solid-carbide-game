extends Control
## Task T-597: the practice window's keycaps (KeyPad.full()) on a dark ground, W and Space lit, for the screenshot tool.


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("1c1c2e")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var pad := KeyPad.full(96.0)
	pad.position = Vector2(400, 150)
	add_child(pad)
	pad.set_held("W_")
