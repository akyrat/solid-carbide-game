extends Node
## Test fixture for screenshots of the drift prototype (task T-012): runs the
## prototype with a scripted drive (W, then W + A) instead of the keyboard.
## The test room fixtures (task T-033) start the car below the test boulder and
## drive it straight into it, zoomed out to show the walls.

@export var view := "flat"
@export var show_panel := false
## Physics steps of W alone before A is added.
@export var straight_steps := 10
## Where the car starts, in units (task T-033's test room fixtures move it).
@export var start_units := Vector2.ZERO
## Camera zoom (orthographic size); 0 keeps the prototype's default.
@export var zoom := 0.0

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
	if start_units != Vector2.ZERO:
		prototype.car.model.set_position(start_units)
		prototype.car.position = start_units * prototype.car.PX_PER_UNIT
		prototype.sync_view()
	if zoom > 0.0:
		prototype.set_zoom(zoom)


func _on_stepped() -> void:
	_steps += 1
	if _steps == straight_steps:
		prototype.car.scripted_input = [true, false, 1.0]
