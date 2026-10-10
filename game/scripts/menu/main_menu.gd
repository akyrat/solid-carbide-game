class_name MainMenu
extends Control
## The main menu (task T-054): the title, a "(work in progress)" line and three
## buttons. It only shows the screen and sends signals; what happens next is
## the screen flow (T-055).

signal start_pressed
signal garage_pressed
signal exit_pressed

const TITLE := "SOLID CARBIDE"
const SUBTITLE := "(work in progress)"
## Button text approved in T-053 (menu.start, menu.garage, menu.quit).
const START_TEXT := "Start"
const GARAGE_TEXT := "Garage"
const EXIT_TEXT := "Exit"

var start_button: Button
var garage_button: Button
var exit_button: Button
var title_label: Label
var subtitle_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.color = Color(0.05, 0.05, 0.12)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	center.add_child(column)

	title_label = Label.new()
	title_label.name = "Title"
	title_label.text = TITLE
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 96)
	title_label.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	column.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.name = "Subtitle"
	subtitle_label.text = SUBTITLE
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 16)
	subtitle_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	column.add_child(subtitle_label)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 40)
	column.add_child(gap)

	start_button = _make_button("StartButton", START_TEXT, column)
	garage_button = _make_button("GarageButton", GARAGE_TEXT, column)
	exit_button = _make_button("ExitButton", EXIT_TEXT, column)
	start_button.pressed.connect(func(): start_pressed.emit())
	garage_button.pressed.connect(func(): garage_pressed.emit())
	exit_button.pressed.connect(func(): exit_pressed.emit())
	start_button.grab_focus()


func _make_button(node_name: String, text: String, parent: Node) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = Vector2(280, 56)
	button.add_theme_font_size_override("font_size", 28)
	parent.add_child(button)
	return button
