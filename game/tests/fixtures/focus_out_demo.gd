extends Node
## T-416 screenshot: the game, a run started, then the window loses focus (the pause screen opens).
var _frame := 0
var _game: Node


func _ready() -> void:
	GameSettings.path = RunPaths.file("focus_demo_settings.cfg")
	PlayerProgress.path = RunPaths.file("focus_demo_progress.json")
	RunHistory.path = RunPaths.file("focus_demo_history.json")
	GameFlow.tutorial_enabled = false
	_game = load("res://scenes/game/game.tscn").instantiate()
	add_child(_game)


func _process(_d: float) -> void:
	_frame += 1
	if _frame == 5:
		_game.menu.start_pressed.emit()
	elif _frame == 40:
		_game.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
