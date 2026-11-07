extends Control
## T-570: shows the Settings texts for a screenshot. SHOT_MODE=menu: the main menu with a
## Settings button before Exit; SHOT_MODE=screen: a title and a Back button in the same styles.

const TEXTS := "res://data/pause_text.json"


func _ready() -> void:
	var t: Dictionary = JSON.parse_string(FileAccess.open(TEXTS, FileAccess.READ).get_as_text())
	if OS.get_environment("SHOT_MODE") == "screen":
		var bg := ColorRect.new()
		bg.color = Color(0.05, 0.05, 0.12)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(bg)
		var box := VBoxContainer.new()
		box.set_anchors_preset(Control.PRESET_CENTER)
		box.grow_horizontal = Control.GROW_DIRECTION_BOTH
		box.grow_vertical = Control.GROW_DIRECTION_BOTH
		box.add_theme_constant_override("separation", 40)
		add_child(box)
		var title := Label.new()
		title.text = t["settings_title"]
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_override("font", preload("res://fonts/press_start_2p/PressStart2P-Regular.ttf"))
		title.add_theme_font_size_override("font_size", 40)
		title.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
		box.add_child(title)
		var back := Button.new()
		back.text = t["settings_back"]
		back.custom_minimum_size = Vector2(280, 56)
		HudStyle.style_button(back)
		box.add_child(back)
	else:
		var menu: Control = load("res://scenes/menu/main_menu.tscn").instantiate()
		add_child(menu)
		await get_tree().process_frame
		var exit_b: Button = menu.exit_button
		var b := Button.new()
		b.text = t["settings_button"]
		b.custom_minimum_size = Vector2(280, 56)
		HudStyle.style_button(b)
		var col := exit_b.get_parent()
		col.add_child(b)
		col.move_child(b, exit_b.get_index())
