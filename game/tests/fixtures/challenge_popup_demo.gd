extends Node
## Test fixture for a screenshot of the challenge popup (task T-092): opens the
## game, presses Start, then completes a challenge.

var game: Node
var _frames := 0


func _ready() -> void:
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()


func _process(_delta: float) -> void:
	_frames += 1
	if _frames == 20:
		var run: Node = get_tree().get_first_node_in_group("run_state").get_parent()
		run.map.challenge_completed.emit(run.map.challenge_ids()[0])
