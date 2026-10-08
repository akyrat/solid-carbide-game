extends Node
## Test fixture for screenshots of the drift prototype (task T-012): runs the
## prototype with a scripted drive (W, then W + A) instead of the keyboard.

@export var view := "flat"
@export var show_panel := false
## Physics steps of W alone before A is added.
@export var straight_steps := 10

var prototype: Node2D
var _steps := 0


func _ready() -> void:
	prototype = preload("res://scenes/drift_prototype/drift_prototype.tscn").instantiate()
	add_child(prototype)
	prototype.car.use_keyboard = false
	prototype.car.scripted_input = [true, false, 0.0]
	prototype.car.stepped.connect(_on_stepped)
	prototype.set_view(view)
	prototype.panel.visible = show_panel


func _on_stepped() -> void:
	_steps += 1
	if _steps == straight_steps:
		prototype.car.scripted_input = [true, false, 1.0]
