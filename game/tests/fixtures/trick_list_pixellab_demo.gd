extends Node
## Screenshot fixture for the trick list (task T-384): the list with its illustration folder set to the PixelLab set
## in art-archive/T-384/pixellab. The pictures are loaded straight from disk.
## bash game/tools/screenshot.sh res://tests/fixtures/trick_list_pixellab_demo.tscn out.png 10

const SET_FOLDER := "../art-archive/T-384/pixellab"


func _ready() -> void:
	var list: TrickList = preload("res://scenes/menu/trick_list.tscn").instantiate()
	list.illustration_folder = ProjectSettings.globalize_path("res://").path_join(SET_FOLDER).simplify_path()
	add_child(list)
