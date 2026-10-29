class_name TrickList
extends Control
## The trick list (task T-382): the seven tricks, each with a still illustration and its name.
## Slide 2 of the tutorial slides uses it, and the pause screen's trick list panel reuses it.
## Names come from res://data/tutorial_text.json (trick.<id>); the illustrations are loaded from
## one fixed path per trick, <illustration_folder>/<trick id>.png. While a file is missing, a
## code-made placeholder is drawn. How it is built: game/docs/hud-and-menus/tutorial-slides.md.

const TEXT_PATH := "res://data/tutorial_text.json"
const DEFAULT_FOLDER := "res://art/tutorial/tricks"
## The trick ids (game/docs/driving/tricks.md), in the order they are listed.
const TRICK_IDS: Array[String] = [
	"extended_drift", "three_sixty", "alternate_drift", "air_one_eighty",
	"air_three_sixty", "airtime", "thread_the_needle",
]
## One illustration is this many pixels; it is drawn at SCALE times that, nearest filtering.
const ILLUSTRATION_SIZE := Vector2i(64, 48)
const SCALE := 3
const COLUMNS := 4
## Placeholder colours: a dusk blue and a pale pink, never Greenbull's light green or yellow.
const PLACEHOLDER_BG := Color(0.18, 0.22, 0.36)
const PLACEHOLDER_FG := Color(0.95, 0.75, 0.85)

static var _texts: Dictionary = {}

## Where the illustrations are loaded from; the art tickets point it at their own sets.
@export var illustration_folder: String = DEFAULT_FOLDER:
	set(value):
		illustration_folder = value
		if is_inside_tree():
			rebuild()
@export var name_font_size: int = 22

## Trick id to the TextureRect and the Label showing it.
var pictures: Dictionary = {}
var labels: Dictionary = {}
var _placeholder: Dictionary = {}


## The tutorial text file, read once.
static func texts() -> Dictionary:
	if _texts.is_empty():
		var f := FileAccess.open(TEXT_PATH, FileAccess.READ)
		var parsed: Variant = JSON.parse_string(f.get_as_text()) if f != null else null
		if typeof(parsed) == TYPE_DICTIONARY:
			_texts = parsed
		else:
			push_error("Could not read the tutorial texts %s" % TEXT_PATH)
	return _texts


## The text at a dotted key ("trick.airtime", "button.start"); "" when missing.
static func text(key: String) -> String:
	var node: Variant = texts()
	for part in key.split("."):
		if typeof(node) != TYPE_DICTIONARY or not node.has(part):
			return ""
		node = node[part]
	return node if typeof(node) == TYPE_STRING else ""


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rebuild()


## (Re)builds the grid from the current illustration folder.
func rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	pictures.clear()
	labels.clear()
	_placeholder.clear()
	var grid := GridContainer.new()
	grid.name = "Grid"
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 12)
	add_child(grid)
	custom_minimum_size = Vector2.ZERO
	for id in TRICK_IDS:
		var cell := VBoxContainer.new()
		cell.name = "Cell_" + id
		cell.add_theme_constant_override("separation", 4)
		grid.add_child(cell)
		var pic := TextureRect.new()
		pic.name = "Picture"
		pic.custom_minimum_size = Vector2(ILLUSTRATION_SIZE * SCALE)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_SCALE
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var tex := _load_illustration(id)
		_placeholder[id] = tex == null
		pic.texture = tex if tex != null else _make_placeholder(id)
		cell.add_child(pic)
		var label := Label.new()
		label.name = "Name"
		label.text = text("trick." + id)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", name_font_size)
		cell.add_child(label)
		pictures[id] = pic
		labels[id] = label
	custom_minimum_size = grid.get_combined_minimum_size()


func illustration_path(id: String) -> String:
	return "%s/%s.png" % [illustration_folder.trim_suffix("/"), id]


## True while the trick shows the code-made placeholder (its PNG is missing).
func is_placeholder(id: String) -> bool:
	return _placeholder.get(id, true)


func _load_illustration(id: String) -> Texture2D:
	var p := illustration_path(id)
	if ResourceLoader.exists(p):
		var res: Variant = load(p)
		if res is Texture2D:
			return res
	if FileAccess.file_exists(p):
		var img := Image.load_from_file(p)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null


## A flat dusk-blue picture with a pale arrow, the same size as the real art.
func _make_placeholder(id: String) -> Texture2D:
	var w := ILLUSTRATION_SIZE.x
	var h := ILLUSTRATION_SIZE.y
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(PLACEHOLDER_BG)
	for x in range(w):
		img.set_pixel(x, 0, PLACEHOLDER_FG)
		img.set_pixel(x, h - 1, PLACEHOLDER_FG)
	for y in range(h):
		img.set_pixel(0, y, PLACEHOLDER_FG)
		img.set_pixel(w - 1, y, PLACEHOLDER_FG)
	# A shaft and an arrow head pointing right; the shaft's height differs per trick so the
	# seven placeholders can be told apart.
	var shaft_y := h / 2 + (TRICK_IDS.find(id) % 3 - 1) * 6
	for x in range(10, w - 18):
		img.set_pixel(x, shaft_y, PLACEHOLDER_FG)
		img.set_pixel(x, shaft_y + 1, PLACEHOLDER_FG)
	for i in range(8):
		for y in range(shaft_y - i, shaft_y + 2 + i):
			img.set_pixel(w - 18 + i, y, PLACEHOLDER_FG)
	return ImageTexture.create_from_image(img)
