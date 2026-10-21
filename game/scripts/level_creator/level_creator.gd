class_name LevelCreator
extends Control
## The level creator's main scene (task T-234): the level list, and the editor opened from it.
## A separate app: opened by tools/level_creator.ps1 / .sh, never from the game's menus.
##
## Play on a listed level (task T-239) starts a full run on that level's file: the game's own run
## (8 minutes, minions, the kaiju), set up as the game's flow sets it up (GameFlow.add_run: garage
## upgrades, pause screen, zoom and camera options, coins banked). When the run ends, win or loss,
## the creator shows its level list again (a proposal for the board).
##
## Only one screen exists at a time, as a child of this node: `list_screen`, `editor` or `run`.

## Emitted when Play is pressed on a listed level, just before its run starts.
signal play_requested(path: String)
## Emitted after a level's run has started (T-239).
signal run_shown
## Emitted after the level list is shown (at launch, back from the editor, after a run).
signal list_shown

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")

var levels_dir: String = LevelStore.LEVELS_DIR
var list_screen: LevelListScreen
var editor: LevelCreatorEditor
## The run on a level while one is on screen, otherwise null (T-239).
var run: Node2D
## The run's pause screen, while a run is on screen.
var pause_screen: CanvasLayer
## The player's saved coins and upgrade levels, as in the game (GameFlow.progress).
var progress: PlayerProgress


func _ready() -> void:
	progress = PlayerProgress.new()
	show_list()


func show_list() -> void:
	_clear()
	list_screen = LevelListScreen.new()
	list_screen.levels_dir = levels_dir
	list_screen.new_pressed.connect(open_editor_new)
	list_screen.edit_pressed.connect(open_editor_with)
	list_screen.play_pressed.connect(play_level)
	add_child(list_screen)
	list_shown.emit()


func open_editor_new() -> void:
	_open_editor("")


func open_editor_with(path: String) -> void:
	_open_editor(path)


## Starts a full run on the level file at `path` (T-239).
func play_level(path: String) -> void:
	play_requested.emit(path)
	_clear()
	run = GameFlow.add_run(self, progress, path)
	pause_screen = run.get_node("PauseScreenLayer")
	run.state.run_ended.connect(_on_run_ended)
	run_shown.emit()


func _on_run_ended(_result: String, _coins: int) -> void:
	# The run ends from inside its own processing; swap screens afterwards.
	show_list.call_deferred()


func _open_editor(path: String) -> void:
	_clear()
	editor = EDITOR_SCENE.instantiate()
	editor.levels_dir = levels_dir
	if path == "":
		editor.open_new()
	else:
		editor.open_level(path)
	editor.back_pressed.connect(show_list)
	add_child(editor)


func _clear() -> void:
	get_tree().paused = false
	for node in [list_screen, editor, run]:
		if is_instance_valid(node):
			remove_child(node)
			node.queue_free()
	list_screen = null
	editor = null
	run = null
	pause_screen = null
