extends Node
## Screenshot fixture for the recap screen (task T-320): opens the game, presses
## Start, scripts a run (kills, tricks, weapons taken), ends it as `ending` says
## ("win": the kaiju killed; "wreck": the last heart, then the wreck's wait;
## "time_up": the clock runs out) and shows the recap with its pop-in finished.
## The saves point at test files (TestSave.isolate()), so the real run history
## and progress are never touched.

@export var ending := "win"

var game: Node
var _frames := 0


func _ready() -> void:
	TestSave.isolate()
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()


func _process(_delta: float) -> void:
	_frames += 1
	if _frames == 20:
		_script_run(game.run)
	elif _frames == 30:
		var s: RunState = game.run.state
		match ending:
			"wreck":
				s.damage_car(s.max_health)
				s.advance(s.wreck_seconds)
			"time_up":
				s.advance(RunState.RUN_SECONDS + 1.0)
			_:
				s.kaiju_killed()
	elif _frames > 32 and game.recap != null:
		game.recap.finish_animation()


func _script_run(run: Node) -> void:
	var s: RunState = run.state
	var take := ["gun", "gun", "gun", "wiper", "wiper", "molotov", "underglow"]
	if ending == "win":
		take += ["flamethrower", "bricks", "gun"]
	for id in take:
		run.weapons.upgrade(id)
	for i in 47:
		s.enemy_slain("minion", "gun")
	if ending == "win":
		s.enemy_slain("kaiju", "wiper")
	for i in 4:
		s.add_trick("three_sixty")
	for i in 3:
		s.add_trick("alternate_drift")
	s.add_needle_trick()
	if ending == "win":
		s.add_airtime_trick(1.2)
		s.add_trick("air_one_eighty")
		s.add_trick("air_three_sixty")
		for i in 6:
			s.add_trick("extended_drift", 2.0)
