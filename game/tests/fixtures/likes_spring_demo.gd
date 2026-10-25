extends Node
## Fixture for the screenshots and GIF of the likes bar (task T-273): a run
## started from the main menu. LIKES_SPRING_MODE picks what it shows:
##   plain  - a combo showing and the bar half full, settled (a screenshot)
##   burning - a combo of x4 (six tricks), so the bar burns (a screenshot)
##   gif    - likes come in at set times with a level-up in the middle, played
##            in real time (record it with game/tools/record_likes_spring.sh)
## game/tools/record_likes_spring.sh runs all three.

## Seconds into the gif at which likes come in, as a share of the level's bar.
const GAINS := [[0.5, 0.35], [1.3, 0.3], [2.1, 0.35], [2.9, 0.45], [4.0, 0.35]]

var _mode := "plain"
var _t := 0.0
var _next := 0
var _state: RunState
var _hud: Hud


func _ready() -> void:
	var m := OS.get_environment("LIKES_SPRING_MODE")
	if m != "":
		_mode = m
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_state = game.run.state
	_hud = game.run.hud
	_state.pause_on_level_up = false
	_state.add_coins(37)
	match _mode:
		"plain":
			_state.add_trick("alternate_drift")
			_state.add_xp(_state.xp_needed() * 0.5 / _state.combo)
			_hud.settle_likes()
		"burning":
			for i in 6:
				_state.add_trick("alternate_drift")
			_state.add_xp(_state.xp_needed() * 0.55 / _state.combo)
			_hud.settle_likes()
		_:
			set_process(true)
	set_process(_mode == "gif")


func _process(delta: float) -> void:
	_t += delta
	while _next < GAINS.size() and _t >= GAINS[_next][0]:
		_state.add_xp(_state.xp_needed() * GAINS[_next][1] / maxf(_state.combo, 1.0))
		_next += 1
