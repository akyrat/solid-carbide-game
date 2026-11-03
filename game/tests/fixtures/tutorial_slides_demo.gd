extends Node
## Screenshot fixture for the tutorial slides (tasks T-382, T-485). `slide` (0 to 3) picks the
## slide: tutorial_slides_demo.tscn is slide 1, tutorial_slides_demo_2.tscn to _4.tscn the
## others. `window_size` sets the window (the stage scales to it). Take it with about 30 frames.

@export var slide := 0
@export var window_size := Vector2i(1280, 720)


func _ready() -> void:
	if window_size.x > 0:
		get_window().size = window_size
	var slides: TutorialSlides = preload("res://scenes/menu/tutorial_slides.tscn").instantiate()
	add_child(slides)
	slides.show_slide(slide)
