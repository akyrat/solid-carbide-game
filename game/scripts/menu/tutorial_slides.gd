class_name TutorialSlides
extends Control
## The tutorial slides (task T-382): three slides shown before the first run. A left and a right
## arrow move between them (slide 1 has no left arrow, slide 3 no right arrow); slide 3 has the
## Start button and the "Don't show again" checkbox. It only shows the screen and sends
## start_pressed(dont_show_again); starting the run is the screen flow's job. Every text comes
## from res://data/tutorial_text.json (TrickList.text). Keys and focus order, and how it is built:
## game/docs/hud-and-menus/tutorial-slides.md.

signal start_pressed(dont_show_again: bool)

const SLIDE_COUNT := 3
const BG := Color(0.05, 0.05, 0.12)
const TEXT_COLOR := Color(0.92, 0.92, 0.96)
const ARROW_COLOR := Color(0.95, 0.75, 0.85)
const DOT_ON := Color(0.95, 0.75, 0.85)
const DOT_OFF := Color(0.3, 0.3, 0.42)

var current := 0
var slides: Array[Control] = []
var left_arrow: Button
var right_arrow: Button
var start_button: Button
var dont_show_checkbox: CheckBox
var trick_list: TrickList
## Every label that shows text from the file, key to Label (tests check each against the file).
var text_labels: Dictionary = {}
var _dots: Array[ColorRect] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var background := ColorRect.new()
	background.color = BG
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 16)
	column.add_child(row)

	left_arrow = _make_arrow("LeftArrow", -1, "arrow.left")
	row.add_child(left_arrow)

	var stack := Control.new()
	stack.name = "Slides"
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(stack)
	stack.add_child(_build_slide1())
	stack.add_child(_build_slide2())
	stack.add_child(_build_slide3())

	right_arrow = _make_arrow("RightArrow", 1, "arrow.right")
	row.add_child(right_arrow)

	var dots := HBoxContainer.new()
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.add_theme_constant_override("separation", 12)
	column.add_child(dots)
	for i in range(SLIDE_COUNT):
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(14, 14)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dots.add_child(dot)
		_dots.append(dot)

	left_arrow.pressed.connect(previous_slide)
	right_arrow.pressed.connect(next_slide)
	start_button.pressed.connect(func(): start_pressed.emit(dont_show_checkbox.button_pressed))
	show_slide(0)


## Shows slide `index` (0 to 2), shows or hides the arrows and puts the focus where it belongs.
func show_slide(index: int) -> void:
	current = clampi(index, 0, SLIDE_COUNT - 1)
	for i in range(slides.size()):
		slides[i].visible = i == current
	for i in range(_dots.size()):
		_dots[i].color = DOT_ON if i == current else DOT_OFF
	left_arrow.visible = current > 0
	right_arrow.visible = current < SLIDE_COUNT - 1
	if is_inside_tree():
		if current == SLIDE_COUNT - 1:
			start_button.grab_focus()
		else:
			right_arrow.grab_focus()


func next_slide() -> void:
	if current < SLIDE_COUNT - 1:
		show_slide(current + 1)


func previous_slide() -> void:
	if current > 0:
		show_slide(current - 1)


## Keys: Left or A go back, Right or D go forward (the arrows do nothing at the ends). Enter and
## Space press the focused control; Tab and Shift+Tab move the focus.
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key := event as InputEventKey
	var code := key.keycode
	if code == KEY_LEFT or code == KEY_A:
		previous_slide()
		get_viewport().set_input_as_handled()
	elif code == KEY_RIGHT or code == KEY_D:
		next_slide()
		get_viewport().set_input_as_handled()


func _build_slide1() -> Control:
	var s := _slide("Slide1")
	var box := _centered_column(s)
	box.add_child(_text_label("slide1.controls", 40))
	box.add_child(_text_label("slide1.drift", 30))
	return s


func _build_slide2() -> Control:
	var s := _slide("Slide2")
	var box := _centered_column(s)
	trick_list = (load("res://scenes/menu/trick_list.tscn") as PackedScene).instantiate()
	trick_list.name = "TrickList"
	trick_list.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(trick_list)
	box.add_child(_text_label("slide2.chain", 28))
	box.add_child(_text_label("slide2.gift", 24))
	return s


func _build_slide3() -> Control:
	var s := _slide("Slide3")
	var box := _centered_column(s)
	box.add_child(_text_label("slide3.goal", 36))
	dont_show_checkbox = CheckBox.new()
	dont_show_checkbox.name = "DontShowCheckbox"
	dont_show_checkbox.text = TrickList.text("checkbox.dont_show")
	dont_show_checkbox.add_theme_font_size_override("font_size", 26)
	dont_show_checkbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for icon_name in ["unchecked", "checked"]:
		dont_show_checkbox.add_theme_icon_override(icon_name, _box_icon(icon_name == "checked"))
	text_labels["checkbox.dont_show"] = dont_show_checkbox
	box.add_child(dont_show_checkbox)
	start_button = Button.new()
	start_button.name = "StartButton"
	start_button.text = TrickList.text("button.start")
	start_button.custom_minimum_size = Vector2(280, 64)
	start_button.add_theme_font_size_override("font_size", 32)
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	text_labels["button.start"] = start_button
	box.add_child(start_button)
	return s


## A 28 px checkbox square in the arrow colour, filled when checked, drawn in code.
func _box_icon(checked: bool) -> Texture2D:
	var n := 28
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for x in range(n):
		for y in range(n):
			var edge := x < 3 or y < 3 or x >= n - 3 or y >= n - 3
			var inner := x >= 8 and y >= 8 and x < n - 8 and y < n - 8
			if edge or (checked and inner):
				img.set_pixel(x, y, ARROW_COLOR)
	return ImageTexture.create_from_image(img)


func _slide(slide_name: String) -> Control:
	var s := Control.new()
	s.name = slide_name
	s.set_anchors_preset(Control.PRESET_FULL_RECT)
	slides.append(s)
	return s


func _centered_column(parent: Control) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(760, 0)
	box.add_theme_constant_override("separation", 20)
	center.add_child(box)
	return box


func _text_label(key: String, size: int) -> Label:
	var l := Label.new()
	l.name = key.replace(".", "_")
	l.text = TrickList.text(key)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", TEXT_COLOR)
	text_labels[key] = l
	return l


## An arrow button with no text: a triangle drawn in code; its tooltip is the label from the file.
func _make_arrow(node_name: String, direction: int, key: String) -> Button:
	var b := Button.new()
	b.name = node_name
	b.custom_minimum_size = Vector2(88, 140)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.tooltip_text = TrickList.text(key)
	text_labels[key] = b
	b.draw.connect(func():
		var c := b.size / 2.0
		var d := float(direction)
		b.draw_colored_polygon(PackedVector2Array([
			c + Vector2(18 * d, 0), c + Vector2(-18 * d, -32), c + Vector2(-18 * d, 32)]),
			ARROW_COLOR))
	return b
