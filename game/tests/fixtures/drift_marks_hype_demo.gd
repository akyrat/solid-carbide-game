extends Node
## Screenshot and GIF fixture for the hype drift trail (task T-249): a run
## started from the main menu, the car driven in a drift circle by script.
## With `multiplier` > 0 the combo is held at it for the whole drift (the
## screenshots, one per step: 1.0, 2.0, 3.0, 4.0). With `climb` on, the combo
## starts at x1 and climbs one step every `climb_seconds` seconds (the GIF).
## Take a screenshot with about 200 frames.

@export var multiplier := 1.0
@export var climb := false
@export var climb_seconds := 1.5
@export var start_units := Vector2(54, 0)
const STRAIGHT_STEPS := 15

var _run: Node2D
var _steps := 0


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	_run = game.run
	var car: CharacterBody2D = _run.car
	car.use_keyboard = false
	car.model.set_position(start_units)
	car.position = start_units * car.PX_PER_UNIT
	car.scripted_input = [true, false, 0.0]
	_hold(multiplier if not climb else 1.0)


func _hold(m: float) -> void:
	_run.state.combo_idle = 0.0
	_run.state._set_combo(m)


func _physics_process(_delta: float) -> void:
	if _run == null:
		return
	_steps += 1
	if _steps == STRAIGHT_STEPS:
		_run.car.scripted_input = [true, false, -1.0]
	if climb:
		var s := int(float(_steps) / 50.0 / climb_seconds)
		_hold([1.0, 2.0, 3.0, 4.0][mini(s, 3)])
	else:
		_hold(multiplier)
