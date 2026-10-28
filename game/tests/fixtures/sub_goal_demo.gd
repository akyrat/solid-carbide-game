extends Node
## Fixture for the sub goal square's screenshots and GIF (task T-337): a run
## started from the main menu. SUB_GOAL_MODE picks what it shows:
##   part - the square part-filled (about 60%), the gift grey (a screenshot)
##   lit  - the goal just reached: full, the gift lit, glowing (a screenshot)
##   gif  - subs come in at set times and reach the goal, the square
##          celebrates and starts again (record it with
##          game/tools/record_sub_goal.sh)

## Seconds into the gif at which subs come in, as a share of the goal.
const GAINS := [[0.5, 0.3], [1.2, 0.25], [1.9, 0.3], [2.6, 0.3], [4.2, 0.25]]

var _mode := "part"
var _t := 0.0
var _next := 0
var _state: RunState
var _hud: Hud


func _ready() -> void:
	var m := OS.get_environment("SUB_GOAL_MODE")
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
	match _mode:
		"part":
			_state.add_xp(_state.xp_needed() * 0.6)
			_hud.settle_likes()
		"lit":
			_state.add_xp(_state.xp_needed() * 0.9)
			_hud.settle_likes()
			_state.add_xp(_state.xp_needed() * 0.2)
			# Into the hold at full, on a glowing frame of the celebration.
			_hud.likes_spring.advance(LikesSpring.DURATION + 0.01)
			_hud.sub_goal.set_process(false)
			_hud.sub_goal.advance(2.0 * ComboHeat.FLICKER_FRAME + 0.001)
			_hud.likes_spring.set_process(false)
	set_process(_mode == "gif")


func _process(delta: float) -> void:
	_t += delta
	while _next < GAINS.size() and _t >= GAINS[_next][0]:
		_state.add_xp(_state.xp_needed() * GAINS[_next][1])
		_next += 1
