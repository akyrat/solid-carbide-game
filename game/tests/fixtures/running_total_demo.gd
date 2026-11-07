extends Node
## GIF fixture (task T-565): (1) the tutorial's drift slide window (the practice session, as
## practice_session_demo.gd embeds it): the real car drifts, stops drifting, drifts again, and the
## notebook's total grows live to 3 s, where the goal is ticked; (2) a run with an airtime mission
## (3 s in total) on the HUD's notebook page: three landings add their airtime, each dropping its
## HANG TIME! box, and the line's total grows to 2.7 s (stopped short of 3 s, where the mission's
## power-up gift would cover the page). Record it with record_running_total_gif.sh.
##
## The texts are the game's own (T-564's).

const SessionScene := preload("res://scenes/run/practice_session.tscn")
const WINDOW_POS := Vector2(224, 104)
const WINDOW_SIZE := Vector2i(704, 440)

var session: PracticeSession
var game: Node


func _ready() -> void:
	await _drift_part()
	await _airtime_part()
	get_tree().quit()


func _drift_part() -> void:
	var page := Control.new()
	add_child(page)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.09)
	bg.size = Vector2(1152, 648)
	page.add_child(bg)
	var frame := ColorRect.new()
	frame.color = Color(0.85, 0.35, 0.65)
	frame.position = WINDOW_POS - Vector2(4, 4)
	frame.size = Vector2(WINDOW_SIZE) + Vector2(8, 8)
	page.add_child(frame)
	var box := SubViewportContainer.new()
	box.position = WINDOW_POS
	box.size = Vector2(WINDOW_SIZE)
	box.stretch = true
	page.add_child(box)
	var vp := SubViewport.new()
	vp.size = WINDOW_SIZE
	box.add_child(vp)
	session = SessionScene.instantiate()
	session.trick = "drift"
	vp.add_child(session)
	session.start()
	session.set_focused(true)
	var car = session.car
	car.use_keyboard = false
	await _wait(0.5)
	car.scripted_input = [true, false, 1.0]  # W + A: the first drift
	while session.drift_seconds < 1.6:
		await get_tree().physics_frame
	car.scripted_input = [true, false, 0.0]  # straighten up: the total stays
	await _wait(1.0)
	car.scripted_input = [true, false, -1.0]  # W + D: the second drift tops it up
	var guard := 0
	while not session.is_completed() and guard < 600:
		await get_tree().physics_frame
		guard += 1
	car.scripted_input = [false, false, 0.0]
	await _wait(1.5)
	page.queue_free()
	await get_tree().process_frame


func _airtime_part() -> void:
	PlayerProgress.path = "user://running_total_progress.json"
	RunHistory.path = "user://running_total_history.json"
	GameSettings.path = "user://running_total_settings.cfg"
	GameFlow.tutorial_enabled = false
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await _wait(0.8)
	var run = game.run
	run.minions.enabled = false
	run.camera_follow.dynamic = false
	run.state.missions.start_with([[{"trick": "airtime", "kind": "seconds", "amount": 3.0}]])
	await get_tree().process_frame
	run.power_up_screen.visible = false
	get_tree().paused = false
	game.pause_screen.visible = false
	await _wait(0.6)
	for s in [0.9, 1.3, 0.5]:  # 2.7 s of 3: the gift overlay would cover the end
		run.state.add_airtime_trick(s)
		await _wait(1.4)
	await _wait(0.6)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
