extends Node
## Screenshot fixture for the likes bar's level-up animation (task T-139): a run
## started from the main menu with a combo showing, then a level-up, with the
## animation held at one frame (`at_frame`; -1 shows the bar just before the
## level-up). The run is not paused here, so the level-up screen stays out of
## the picture. game/tools/level_up_flash_shots.sh takes the key frames and
## puts them one under the other.

@export var at_frame := 0


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var state: RunState = game.run.state
	state.pause_on_level_up = false
	state.add_trick("alternate_drift")
	state.add_trick("alternate_drift")
	state.add_coins(37)
	var hud: Hud = game.run.hud
	if at_frame < 0:
		state.add_xp(state.xp_needed() * 0.97 / state.combo)
		return
	state.add_xp(state.xp_needed() * 1.2 / state.combo)
	hud.level_up_flash.set_process(false)
	hud.level_up_flash.advance(at_frame * ComboHeat.FLICKER_FRAME + 0.001)
