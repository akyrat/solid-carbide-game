extends Node
## Test fixture for a screenshot of the pause screen (task T-015): drives the
## prototype for a few steps, then pauses it.

## When above 0, the slider is set to this value right after pausing (T-093).
@export var slider_value := 0.0

## When true, the dynamic camera is switched on before pausing (T-124).
@export var dynamic_camera := false

var prototype: Node2D
var _steps := 0


func _ready() -> void:
	prototype = preload("res://scenes/drift_prototype/drift_prototype.tscn").instantiate()
	add_child(prototype)
	prototype.car.use_keyboard = false
	prototype.car.scripted_input = [true, false, 0.5]
	prototype.car.stepped.connect(_on_stepped)


func _on_stepped() -> void:
	_steps += 1
	if _steps == 30:
		if dynamic_camera:
			prototype.camera_follow.set_dynamic(true)
		prototype.pause_screen.pause()
		if slider_value > 0.0:
			prototype.pause_screen.zoom_slider.value = slider_value
