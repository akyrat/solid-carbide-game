extends Node
## Fixture for T-534's GIF: a run from the main menu in which tricks pay subs at set times
## (a single one, then three at once, then a burst of ten on one frame); dots fly from the car
## to the gift. Record: see game/docs/hud-and-menus/hud.md, "Tricks fly to the gift icon".

const PAYS := [[0.5, 1], [1.5, 3], [2.5, 10], [3.5, 1]]

var _t := 0.0
var _next := 0
var _state: RunState
var _hud: Hud


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.start_run()  # straight into a run, past the tutorial slides
	await get_tree().process_frame
	await get_tree().process_frame
	_state = game.run.state
	_hud = game.run.hud
	_state.pause_on_level_up = false


func _process(delta: float) -> void:
	if _state == null:
		return
	_t += delta
	while _next < PAYS.size() and _t >= PAYS[_next][0]:
		for i in int(PAYS[_next][1]):
			_state.add_xp(_state.xp_needed() * 0.04)
			_state.trick_subs_paid.emit("drift", 5.0)
		_next += 1
	if _t > 4.6:
		get_tree().quit()
