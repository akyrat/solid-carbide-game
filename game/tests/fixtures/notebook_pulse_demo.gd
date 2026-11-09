extends Node
## GIF fixture (task T-606): in a run, with mission 2 ("Alt drifts 0/10") on the notebook page,
## the car does alt drifts spaced out: each box falls, the count goes up and the page pulses.
## Record it with record_notebook_pulse_gif.sh.

var game: Node
var run: Node2D


func _ready() -> void:
	PlayerProgress.path = "user://notebook_pulse_progress.json"
	RunHistory.path = "user://notebook_pulse_history.json"
	GameSettings.path = "user://notebook_pulse_settings.cfg"
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
	await _wait(0.8)
	for i in 4:
		run.state.add_trick("alternate_drift")
		await _wait(1.0)
	await _wait(0.4)
	get_tree().quit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
