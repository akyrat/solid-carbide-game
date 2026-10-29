extends Node
## Fixture for the reaction icons' screenshots and GIFs (task T-351): a run started
## from the main menu. REACTIONS_MODE picks:
##   burst_still - a moment into the sub goal's burst (a screenshot)
##   float_still - the floaters at a high viewer count (a screenshot)
##   burst_gif   - the goal is reached 0.5 s in (record with --write-movie)
##   float_gif   - the viewer count steps up; floaters appear more often
##   bad_still   - a moment into the bad reactions after a crash cuts the combo (T-356)
##   bad_gif     - a trick, then a crash 0.5 s in (record with --write-movie)
## Record them with game/tools/record_reactions.sh.

var _mode := "burst_still"
var _t := 0.0
var _fired := false
var _state: RunState
var _hud: Hud
var _step := 0


func _ready() -> void:
	var m := OS.get_environment("REACTIONS_MODE")
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
	_hud.reactions.rng.seed = 5
	match _mode:
		"burst_still":
			_state.add_xp(_state.xp_needed() * 1.1)
			_hud.reactions.set_process(false)
			for i in 36:
				_hud.reactions.advance(1.0 / 60.0)
		"float_still":
			_hud.reactions.step_source = func() -> int: return 3
			_hud.reactions.set_process(false)
			for i in 260:
				_hud.reactions.advance(0.05)
		"bad_still":
			_state.add_trick("alternate_drift")
			_hud.reactions.set_process(false)
			_state.collision()
			for i in 70:
				_hud.reactions.advance(1.0 / 60.0)
		"float_gif":
			_hud.reactions.step_source = func() -> int: return _step
	set_process(_mode.ends_with("gif"))


func _process(delta: float) -> void:
	_t += delta
	if _mode == "burst_gif" and not _fired and _t >= 0.5:
		_fired = true
		_state.add_xp(_state.xp_needed() * 1.1)
	elif _mode == "bad_gif" and not _fired and _t >= 0.5:
		_fired = true
		_state.add_trick("alternate_drift")
		_state.collision()
	elif _mode == "float_gif":
		# Steps up as the stream grows: none, 20K, 84K, 236K, fire.
		_step = clampi(int(_t / 3.0), 0, 4)

