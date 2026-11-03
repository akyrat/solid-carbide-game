class_name TrickList
extends Control
## The trick list (tasks T-382, T-491): the seven tricks as a list (illustration and name), and the
## selected one large on the right: its name, rule, clip with the live key pad (KeyPad), and keycap
## recipe. The pause screen's trick list panel holds it. Names, rules, notes and badges come from
## res://data/tutorial_text.json; the recipe's structure (which keys per step, which get a /D tag)
## and each trick's clip from res://data/trick_recipes.json; the illustrations are loaded from one
## fixed path per trick, <illustration_folder>/<trick id>.png (a missing file shows an empty
## picture and an error). Only the selected trick's clip is loaded, and only while the list is on
## screen (ClipPlayer frees it when hidden, T-485's web memory rule). How it is built:
## game/docs/hud-and-menus/tutorial-slides.md and pause-screen.md.

signal selected_changed(id: String)

const TEXT_PATH := "res://data/tutorial_text.json"
const RECIPES_PATH := "res://data/trick_recipes.json"
const DEFAULT_FOLDER := "res://art/tutorial/tricks"
const PIXEL_FONT_PATH := "res://fonts/press_start_2p/PressStart2P-Regular.ttf"
## The trick ids (game/docs/driving/tricks.md), in the order they are listed.
const TRICK_IDS: Array[String] = [
	"extended_drift", "three_sixty", "alternate_drift", "air_one_eighty",
	"air_three_sixty", "airtime", "thread_the_needle",
]
## One illustration is this many pixels; the list shows it at LIST_SCALE times that, nearest filtering.
const ILLUSTRATION_SIZE := Vector2i(64, 48)
const LIST_SCALE := 1
## The selected trick's clip box (the clips are 3:2), the detail pane's width and the list rows' width.
const CLIP_BOX := Vector2(372, 248)
const COMIC_FONT_PATH := "res://fonts/bangers/Bangers-Regular.ttf"
const DETAIL_WIDTH := 600.0
const ROW_WIDTH := 300.0
const KEY_PX := 44.0
const STEP_WIDTH := 172.0
const KEY_FACE := Color("e9e8f2")
const KEY_EDGE := Color("8f93ab")
const KEY_HI := Color("f6c9de")
const INK := Color("0d0d1b")
const MUTED := Color("a3a6c2")
const PINK := Color("ff5fae")

static var _texts: Dictionary = {}
static var _recipes: Dictionary = {}

## Where the illustrations are loaded from; the art tickets point it at their own sets.
@export var illustration_folder: String = DEFAULT_FOLDER:
	set(value):
		illustration_folder = value
		if is_inside_tree():
			rebuild()
@export var name_font_size: int = 22

## Trick id to the TextureRect and the Label of its list row, and to the row (a toggle button).
var pictures: Dictionary = {}
var labels: Dictionary = {}
var rows: Dictionary = {}
var selected := ""
var detail_name: Label
var rule_label: Label
var clip_player: ClipPlayer
var key_pad: KeyPad
var recipe_box: HBoxContainer
var _loaded: Dictionary = {}
var _font: Font


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


## The recipe file's tricks (res://data/trick_recipes.json), read once: {id: {clip, steps}}.
static func recipes() -> Dictionary:
	if _recipes.is_empty():
		var f := FileAccess.open(RECIPES_PATH, FileAccess.READ)
		var parsed: Variant = JSON.parse_string(f.get_as_text()) if f != null else null
		if typeof(parsed) == TYPE_DICTIONARY and parsed.has("tricks"):
			_recipes = parsed["tricks"]
		else:
			push_error("Could not read the trick recipes %s" % RECIPES_PATH)
	return _recipes


## The clip a trick shows.
static func clip_for(id: String) -> String:
	return String(recipes().get(id, {}).get("clip", ""))


## A trick's recipe steps (none for THREAD THE NEEDLE!).
static func steps_for(id: String) -> Array:
	return recipes().get(id, {}).get("steps", [])


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rebuild()


## (Re)builds the list and the detail pane from the current illustration folder.
func rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	pictures.clear()
	labels.clear()
	rows.clear()
	_loaded.clear()
	_font = load(PIXEL_FONT_PATH)
	var layout := HBoxContainer.new()
	layout.name = "Layout"
	layout.add_theme_constant_override("separation", 20)
	add_child(layout)
	var list := VBoxContainer.new()
	list.name = "List"
	list.add_theme_constant_override("separation", 4)
	layout.add_child(list)
	for id in TRICK_IDS:
		list.add_child(_make_row(id))
	var detail := VBoxContainer.new()
	detail.name = "Detail"
	detail.custom_minimum_size.x = DETAIL_WIDTH
	detail.add_theme_constant_override("separation", 8)
	layout.add_child(detail)
	detail_name = Label.new()
	detail_name.name = "TrickName"
	detail_name.add_theme_font_override("font", load(COMIC_FONT_PATH))
	detail_name.add_theme_font_size_override("font_size", 40)
	detail_name.add_theme_color_override("font_color", Color("ecebf5"))
	detail_name.add_theme_color_override("font_shadow_color", PINK)
	detail_name.add_theme_constant_override("shadow_offset_x", 3)
	detail_name.add_theme_constant_override("shadow_offset_y", 3)
	detail.add_child(detail_name)
	rule_label = Label.new()
	rule_label.name = "Rule"
	rule_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule_label.custom_minimum_size = Vector2(DETAIL_WIDTH - CLIP_BOX.x - 16.0, 0)
	rule_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	rule_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule_label.add_theme_font_size_override("font_size", name_font_size)
	var middle := HBoxContainer.new()
	middle.name = "Middle"
	middle.add_theme_constant_override("separation", 16)
	detail.add_child(middle)
	middle.add_child(_make_clip_box())
	middle.add_child(rule_label)
	recipe_box = HBoxContainer.new()
	recipe_box.name = "Recipe"
	recipe_box.add_theme_constant_override("separation", 6)
	recipe_box.custom_minimum_size.y = 80
	detail.add_child(recipe_box)
	custom_minimum_size = layout.get_combined_minimum_size()
	select(selected if selected in TRICK_IDS else TRICK_IDS[0])


## A list entry that selects a trick (not a Button: the shared button style is for buttons).
## Focusable; a click, Enter or Space presses it; it draws its own selected, hover and focus looks.
class TrickRow extends Control:
	signal pressed
	var button_pressed := false
	var _hover := false

	func _init() -> void:
		focus_mode = Control.FOCUS_ALL
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_entered.connect(func(): _hover = true; queue_redraw())
		mouse_exited.connect(func(): _hover = false; queue_redraw())
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)

	func set_pressed_no_signal(value: bool) -> void:
		button_pressed = value
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit()
			accept_event()
		elif event.is_action_pressed("ui_accept"):
			pressed.emit()
			accept_event()

	func _draw() -> void:
		var box := StyleBoxFlat.new()
		box.set_corner_radius_all(4)
		box.bg_color = Color("2a2f47") if button_pressed else (Color("22263d") if _hover else Color("171a2c"))
		if button_pressed:
			box.set_border_width_all(2)
			box.border_color = Color("ff5fae")
		draw_style_box(box, Rect2(Vector2.ZERO, size))
		if has_focus():
			var f := StyleBoxFlat.new()
			f.set_corner_radius_all(4)
			f.draw_center = false
			f.set_border_width_all(2)
			f.border_color = Color("f6c9de")
			draw_style_box(f, Rect2(Vector2.ZERO, size))


func _make_row(id: String) -> Control:
	var row := TrickRow.new()
	row.name = "Row_" + id
	row.custom_minimum_size = Vector2(ROW_WIDTH, ILLUSTRATION_SIZE.y * LIST_SCALE + 6)
	var inner := HBoxContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 4
	inner.offset_right = -4
	inner.add_theme_constant_override("separation", 10)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(inner)
	var pic := TextureRect.new()
	pic.name = "Picture"
	pic.custom_minimum_size = Vector2(ILLUSTRATION_SIZE * LIST_SCALE)
	pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_SCALE
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex := _load_illustration(id)
	_loaded[id] = tex != null
	if tex == null:
		push_warning("Missing trick illustration %s" % illustration_path(id))
	pic.texture = tex
	inner.add_child(pic)
	var label := Label.new()
	label.name = "Name"
	label.text = text("trick." + id)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.add_theme_font_size_override("font_size", name_font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(label)
	pictures[id] = pic
	labels[id] = label
	rows[id] = row
	row.pressed.connect(func(): select(id))
	row.focus_entered.connect(func(): select(id))
	return row


func _make_clip_box() -> Control:
	var box := Panel.new()
	box.name = "ClipBox"
	box.custom_minimum_size = CLIP_BOX
	box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var style := StyleBoxFlat.new()
	style.bg_color = Color("15172a")
	style.set_corner_radius_all(4)
	style.set_border_width_all(3)
	style.border_color = Color("3f4659")
	box.add_theme_stylebox_override("panel", style)
	clip_player = ClipPlayer.new()
	clip_player.name = "Player"
	clip_player.position = Vector2(3, 3)
	clip_player.size = CLIP_BOX - Vector2(6, 6)
	box.add_child(clip_player)
	key_pad = KeyPad.attach(clip_player, 30.0)
	return box


## Shows a trick in the detail pane: its name, rule, clip with the key pad and keycap recipe.
## Only this one clip is loaded, and only while the list is on screen.
func select(id: String) -> void:
	if not id in TRICK_IDS:
		return
	var changed := id != selected
	selected = id
	for k in rows:
		rows[k].set_pressed_no_signal(k == id)
	detail_name.text = text("trick." + id)
	rule_label.text = text("trick_rule." + id)
	if changed or clip_player.clip == "":
		clip_player.set_clip(clip_for(id))
		if is_visible_in_tree():
			clip_player.ensure_loaded()
	_build_recipe(id)
	if changed:
		selected_changed.emit(id)


func _build_recipe(id: String) -> void:
	for c in recipe_box.get_children():
		recipe_box.remove_child(c)
		c.queue_free()
	var steps := steps_for(id)
	for i in range(steps.size()):
		if i > 0:
			recipe_box.add_child(_make_arrow(i))
		recipe_box.add_child(_make_step(id, i + 1, steps[i]))


func _make_arrow(n: int) -> Control:
	var a := Control.new()
	a.name = "Arrow%d" % n
	a.custom_minimum_size = Vector2(22, KEY_PX)
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	a.draw.connect(func():
		var cy := KEY_PX / 2.0
		a.draw_colored_polygon(PackedVector2Array([Vector2(3, cy - 9), Vector2(19, cy), Vector2(3, cy + 9)]), KEY_HI))
	return a


func _make_step(id: String, n: int, step: Dictionary) -> Control:
	var col := VBoxContainer.new()
	col.name = "Step%d" % n
	var wide: bool = step.has("keys") and step["keys"].size() > 1
	col.custom_minimum_size.x = STEP_WIDTH + (14.0 if wide else 0.0)
	col.add_theme_constant_override("separation", 6)
	var top := HBoxContainer.new()
	top.name = "Keys"
	top.add_theme_constant_override("separation", 4)
	top.custom_minimum_size.y = KEY_PX
	col.add_child(top)
	if step.has("keys"):
		var either: Array = step.get("either", [])
		for i in range(step["keys"].size()):
			if i > 0:
				var plus := Label.new()
				plus.name = "Plus"
				plus.text = "+"
				plus.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				plus.add_theme_font_size_override("font_size", 18)
				top.add_child(plus)
			top.add_child(_make_keycap(step["keys"][i], step["keys"][i] in either))
	else:
		top.add_child(_make_badge(text("trick_recipe.%s.step%d_badge" % [id, n]).to_upper()))
	var note := Label.new()
	note.name = "Note"
	note.text = text("trick_recipe.%s.step%d_note" % [id, n])
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.x = col.custom_minimum_size.x
	note.add_theme_font_override("font", _font)
	note.add_theme_font_size_override("font_size", 10)
	note.add_theme_color_override("font_color", MUTED)
	col.add_child(note)
	return col


func _make_keycap(letter: String, either: bool) -> Control:
	var cap := PanelContainer.new()
	cap.name = "Key" + letter
	cap.custom_minimum_size = Vector2(KEY_PX, KEY_PX)
	var box := StyleBoxFlat.new()
	box.bg_color = KEY_FACE
	box.set_corner_radius_all(5)
	box.border_width_bottom = 5
	box.border_color = KEY_EDGE
	box.content_margin_left = 4
	box.content_margin_right = 4
	cap.add_theme_stylebox_override("panel", box)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 1)
	cap.add_child(row)
	var l := Label.new()
	l.name = "Letter"
	l.text = letter
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", INK)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(l)
	if either:
		var tag := Label.new()
		tag.name = "EitherTag"
		tag.text = "/D"
		tag.add_theme_font_override("font", _font)
		tag.add_theme_font_size_override("font_size", 8)
		tag.add_theme_color_override("font_color", Color("b0457f"))
		tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(tag)
		cap.custom_minimum_size.x = KEY_PX + 22.0
	return cap


func _make_badge(word: String) -> Control:
	var cap := PanelContainer.new()
	cap.name = "Badge"
	cap.custom_minimum_size = Vector2(0, KEY_PX)
	var box := StyleBoxFlat.new()
	box.bg_color = Color("2a2f47")
	box.set_corner_radius_all(5)
	box.set_border_width_all(2)
	box.border_color = KEY_HI
	box.content_margin_left = 8
	box.content_margin_right = 8
	cap.add_theme_stylebox_override("panel", box)
	var l := Label.new()
	l.name = "Word"
	l.text = word
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", KEY_HI)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cap.add_child(l)
	return cap


func illustration_path(id: String) -> String:
	return "%s/%s.png" % [illustration_folder.trim_suffix("/"), id]


## True when the trick's texture was loaded from its PNG.
func is_loaded(id: String) -> bool:
	return _loaded.get(id, false)


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
