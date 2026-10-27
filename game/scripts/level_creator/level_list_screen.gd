class_name LevelListScreen
extends Control
## The level creator's list screen (task T-234): a title, one row per saved level (its name, a Play
## and an Edit button) and the New level button, which is all there is when there are no levels.
## It only shows the list and sends signals. Placeholder look, plain colours.

signal new_pressed
signal play_pressed(path: String)
signal edit_pressed(path: String)

var levels_dir: String = LevelStore.LEVELS_DIR
var new_button: Button
## One entry per listed level: { "name", "path", "row", "play", "edit" }.
var rows: Array = []

var _column: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.12, 0.12, 0.14)
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", 10)
	center.add_child(_column)
	refresh()


## Rebuilds the list from the levels folder.
func refresh() -> void:
	for c in _column.get_children():
		_column.remove_child(c)
		c.queue_free()
	rows.clear()
	var title := Label.new()
	title.name = "Title"
	title.text = CreatorTexts.get_text("list_title")
	title.add_theme_font_size_override("font_size", 40)
	_column.add_child(title)
	for lv in LevelStore.list_levels(levels_dir):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var label := Label.new()
		label.text = str(lv.name)
		label.custom_minimum_size = Vector2(300, 0)
		row.add_child(label)
		var play := _make_button("Play", CreatorTexts.get_text("play_action"), row)
		var edit := _make_button("Edit", CreatorTexts.get_text("edit_action"), row)
		var path: String = lv.path
		play.pressed.connect(func(): play_pressed.emit(path))
		edit.pressed.connect(func(): edit_pressed.emit(path))
		_column.add_child(row)
		rows.append({"name": lv.name, "path": path, "row": row, "play": play, "edit": edit})
	new_button = _make_button("NewLevel", CreatorTexts.get_text("new_level_button"), _column)
	new_button.pressed.connect(func(): new_pressed.emit())


func _make_button(node_name: String, label_text: String, parent: Node) -> Button:
	var b := Button.new()
	b.name = node_name
	b.text = label_text
	b.custom_minimum_size = Vector2(120, 36)
	parent.add_child(b)
	return b
