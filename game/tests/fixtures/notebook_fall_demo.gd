extends Node
## GIF fixture (task T-563): in a run, with mission 2 ("Alt drifts 0/10") on the notebook page,
## the car does alt drifts: one alone, then three quick ones in a row, then a trick that does
## not count (a rail grind: nothing falls). The box with the trick's name falls into the page,
## splashes, and the count goes up. Record it with record_notebook_fall_gif.sh.

var game: Node
var run: Node2D


func _ready() -> void:
	PlayerProgress.path = "user://notebook_fall_progress.json"
	RunHistory.path = "user://notebook_fall_history.json"
	GameSettings.path = "user://notebook_fall_settings.cfg"
	GameFlow.tutorial_enabled = false
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await _wait(0.8)
	run = game.run
	run.minions.enabled = false
	run.camera_follow.dynamic = false
	var m: RunMissions = run.state.missions
	m.start(7)
	m.on_drift_step(true, 5.0)  # mission 1 done: mission 2 is "Alt drifts 0/10"
	await get_tree().process_frame
	run.power_up_screen.visible = false
	get_tree().paused = false  # the power-up overlay paused the run; the recording goes on
	game.pause_screen.visible = false
	run.hud.mission_page.finish_falls()
	await _wait(0.5)
	run.state.add_trick("alternate_drift")
	await _wait(1.6)
	for i in 3:
		run.state.add_trick("alternate_drift")
		await _wait(0.1)
	await _wait(1.6)
	run.state.add_trick("rail_grind")
	await _wait(1.0)
	get_tree().quit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
