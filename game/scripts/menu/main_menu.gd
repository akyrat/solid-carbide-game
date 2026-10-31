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

## The splash cover slot (T-432): when this file exists it fills the screen behind
## the menu, cropped not stretched, with hard pixel edges.
const SPLASH_PATH := "res://art/menu/splash.png"
const TITLE_FONT := preload("res://fonts/press_start_2p/PressStart2P-Regular.ttf")
const PLACEHOLDER_COLOR := Color(0.05, 0.05, 0.12)
const TITLE_COLOR := Color(0.3, 0.9, 1.0)
const OUTLINE_COLOR := Color(0.03, 0.03, 0.06)
## Darkens the splash so the buttons stay readable over any image.
const SCRIM_COLOR := Color(0, 0, 0, 0.35)

## Set before the menu enters the tree to use another image (tests).
var splash_path: String = SPLASH_PATH

var start_button: Button
var garage_button: Button
var exit_button: Button
var title_label: Label
var subtitle_label: Label
var background: ColorRect
## The splash image; null when there is none and the placeholder shows.
var splash_rect: TextureRect


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	background =ColorRect.new()
	background.name = "Background"
	background.color = PLACEHOLDER_COLOR
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var texture := _load_splash(splash_path)
	if texture != null:
		splash_rect = TextureRect.new()
		splash_rect.name = "Splash"
		splash_rect.texture = texture
		splash_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		splash_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		splash_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		splash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		splash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(splash_rect)
		var scrim := ColorRect.new()
		scrim.name = "Scrim"
		scrim.color = SCRIM_COLOR
		scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(scrim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	center.add_child(column)

	title_label = Label.new()
	title_label.name = "Title"
	title_label.text = TITLE
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_pixel_label(title_label, 56, TITLE_COLOR, 10)
	column.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.name = "Subtitle"
	subtitle_label.text = SUBTITLE
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_pixel_label(subtitle_label, 16, Color(0.75, 0.85, 0.9), 4)
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


func _style_pixel_label(label: Label, size: int, color: Color, outline: int) -> void:
	label.add_theme_font_override("font", TITLE_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", outline)
	label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## The image at `path`, or null when there is none.
func _load_splash(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	if FileAccess.file_exists(path):
		var image := Image.load_from_file(path)
		if image != null:
			return ImageTexture.create_from_image(image)
	return null


func _make_button(node_name: String, text: String, parent: Node) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = Vector2(280, 56)
	HudStyle.style_button(button)  # the shared button (T-446)
	parent.add_child(button)
	return button
