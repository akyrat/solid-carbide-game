extends Node
## GIF fixture for the hype speed boost (task T-275): a run from the main menu,
## the car driven in a drift circle by script, the combo held at x1, then
## climbing one heat step every `step_seconds` seconds to x4 and dropping back
## to x1 at the end. A label shows the combo, the car's top speed and its
## real speed, so the boost can be read off the GIF. Record with Godot's movie
## maker (game/README.md, "Hype speed boost").

@export var step_seconds := 2.5
## True: a drift circle (the default); false: straight up the street from the start.
@export var circle := true
@export var debug_print := false
const SEQUENCE := [1.0, 2.0, 3.0, 4.0, 1.0]
const STRAIGHT_STEPS := 15

var _run: Node2D
var _steps := 0
var _label: Label


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	_run = game.run
	var car: CharacterBody2D = _run.car
	car.use_keyboard = false
	if circle:
		var start := Vector2(54, 0)
		car.model.set_position(start)
		car.position = start * car.PX_PER_UNIT
	car.scripted_input = [true, false, 0.0]
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_label = Label.new()
	_label.position = Vector2(110, 80)
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_label.add_theme_constant_override("outline_size", 8)
	layer.add_child(_label)
	_hold(1.0)


func _hold(m: float) -> void:
	_run.state.combo_idle = 0.0
	_run.state._set_combo(m)


func _physics_process(_delta: float) -> void:
	if _run == null:
		return
	_steps += 1
	if circle and _steps == STRAIGHT_STEPS:
		_run.car.scripted_input = [true, false, -1.0]
	var s := mini(int(float(_steps) / 50.0 / step_seconds), SEQUENCE.size() - 1)
	_hold(SEQUENCE[s])
	var t = _run.car.tuning
	_label.text = "combo x%.1f   top speed %.1f   speed %.1f units/s" % [
			_run.state.combo, t.top_speed(), _run.car.model.total_speed()]
	if debug_print and _steps % 50 == 0:
		print("t=%d pos=%s speed=%.1f top=%.1f" % [_steps / 50, _run.car.model.get_position(), _run.car.model.total_speed(), t.top_speed()])
