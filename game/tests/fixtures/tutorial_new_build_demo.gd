extends Node
## Test fixture for T-572's screenshots: "Don't show again" was ticked on build `ticked_on`, then
## the game starts on build `running` and the main menu's Start is pressed. With a different
## build the slides come back; with the same build the run starts straight away. Uses its own
## settings and build id files under user://, never the player's save or res://build_id.txt.
## A small caption in the corner (fixture only, not game text) names the two build ids.

@export var ticked_on := "aaaaaaa"
@export var running := "bbbbbbb"

var game: Node


func _ready() -> void:
	GameSettings.path = "user://t572_screenshot_settings.cfg"
	GameSettings.build_id_path = "user://t572_screenshot_build_id.txt"
	DirAccess.remove_absolute(GameSettings.path)
	_write_build_id(ticked_on)
	GameSettings.save_tutorial_hidden(true)  # ticked on the first build
	_write_build_id(running)  # as after the board pushed a new build
	GameFlow.tutorial_enabled = true
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var caption := Label.new()
	caption.text = "fixture: ticked on build %s, running build %s -> %s" % [
		ticked_on, running, "slides shown" if game.tutorial != null else "straight into the run"]
	caption.position = Vector2(8, 4)
	caption.add_theme_color_override("font_color", Color.YELLOW)
	caption.add_theme_color_override("font_outline_color", Color.BLACK)
	caption.add_theme_constant_override("outline_size", 4)
	layer.add_child(caption)


func _write_build_id(id: String) -> void:
	var f := FileAccess.open(GameSettings.build_id_path, FileAccess.WRITE)
	f.store_string(id)
	f.close()
