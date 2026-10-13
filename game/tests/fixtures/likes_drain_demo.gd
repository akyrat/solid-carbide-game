extends Node
## Test fixture for screenshots of the likes drain (task T-115): opens the
## game, presses Start, gives the run enough likes to reach level 2 with a
## fifth of level 2's bar, then does nothing: no tricks, so the likes bar
## empties and stops at empty with the level unchanged. Prints the time, XP
## and level every half second, so each screenshot can be matched to them.

var _state: RunState
var _since_print := 0.0
var _elapsed := 0.0


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_state = game.run.state
	_state.add_xp(_state.xp_needed() + RunData.new().xp_needed(2) * 0.2)
	print("likes_drain_demo: start xp=%.2f/%.0f level=%d" % [_state.xp, _state.xp_needed(), _state.level])


func _process(delta: float) -> void:
	if _state == null:
		return
	_elapsed += delta
	_since_print += delta
	if _since_print >= 0.5:
		_since_print = 0.0
		print("likes_drain_demo: t=%.1fs xp=%.2f/%.0f level=%d combo=%.2f" % [
				_elapsed, _state.xp, _state.xp_needed(), _state.level, _state.combo])
