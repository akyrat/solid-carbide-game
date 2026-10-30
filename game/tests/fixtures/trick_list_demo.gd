extends Node
## Screenshot fixture for the trick list (task T-383): the list with its illustration folder set to the script-drawn
## set in art-archive/T-383/script, or to the folder in the environment variable TRICK_ILLUSTRATION_FOLDER (an
## absolute folder, or res://...). The pictures are loaded straight from disk.
## bash game/tools/screenshot.sh res://tests/fixtures/trick_list_demo.tscn out.png 10

const SET_FOLDER := "../art-archive/T-383/script"


func _ready() -> void:
	var list: TrickList = preload("res://scenes/menu/trick_list.tscn").instantiate()
	var folder := OS.get_environment("TRICK_ILLUSTRATION_FOLDER")
	if folder == "":
		folder = ProjectSettings.globalize_path("res://").path_join(SET_FOLDER).simplify_path()
	list.illustration_folder = folder
	add_child(list)
