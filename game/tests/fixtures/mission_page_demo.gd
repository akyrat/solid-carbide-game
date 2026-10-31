extends Node
## Fixture for the mission notebook page's screenshots (task T-458): a run from the main
## menu. `mode` picks what it shows: half (a quantity goal half done), ticked (a goal
## ticked and crossed off beside one still open), next (the next mission after a completed one).

@export var mode := "half"


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.start_run()  # no tutorial slides
	await get_tree().process_frame
	await get_tree().process_frame
	var m: RunMissions = game.run.state.missions
	m.start(7)
	match mode:
		"half":
			_finish(m)  # mission 1 (the drift) done: mission 2 is "Alt drifts 0/10"
			for i in 5:
				m.on_trick("alternate_drift")
		"ticked":
			while m.current_goals().size() < 2:
				_finish(m)
			_do(m, m.current_goals()[0])
			_half(m, m.current_goals()[1])
		"next":
			_finish(m)
			_finish(m)


	# The power-up overlay opens on each completed mission: hide it so the page shows.
	await get_tree().process_frame
	game.run.power_up_screen.visible = false


func _finish(m: RunMissions) -> void:
	for g in m.current_goals():
		_do(m, g)


func _do(m: RunMissions, g: Dictionary) -> void:
	if String(g["kind"]) == "seconds":
		m.on_trick(String(g["trick"]), float(g["amount"]))
	else:
		for i in int(g["amount"]):
			m.on_trick(String(g["trick"]))


func _half(m: RunMissions, g: Dictionary) -> void:
	if String(g["kind"]) == "count":
		for i in int(g["amount"]) / 2:
			m.on_trick(String(g["trick"]))
