class_name LevelCreator
extends Control
## The level creator's main scene (task T-234): the level list, and the editor opened from it.
## A separate app: opened by tools/level_creator.ps1 / .sh, never from the game's menus.

## The play ticket wires this to a full run on the level.
signal play_requested(path: String)

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")

var levels_dir: String = LevelStore.LEVELS_DIR
var list_screen: LevelListScreen
var editor: LevelCreatorEditor


func _ready() -> void:
	show_list()


func show_list() -> void:
	_clear()
	list_screen = LevelListScreen.new()
	list_screen.levels_dir = levels_dir
	list_screen.new_pressed.connect(open_editor_new)
	list_screen.edit_pressed.connect(open_editor_with)
	list_screen.play_pressed.connect(func(path: String): play_requested.emit(path))
	add_child(list_screen)


func open_editor_new() -> void:
	_open_editor("")


func open_editor_with(path: String) -> void:
	_open_editor(path)


func _open_editor(path: String) -> void:
	_clear()
	editor = EDITOR_SCENE.instantiate()
	if path == "":
		editor.open_new()
	else:
		editor.open_level(path)
	editor.back_pressed.connect(show_list)
	add_child(editor)


func _clear() -> void:
	for node in [list_screen, editor]:
		if is_instance_valid(node):
			remove_child(node)
			node.queue_free()
	list_screen = null
	editor = null
