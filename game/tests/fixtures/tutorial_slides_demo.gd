extends Node
## Screenshot fixture for the tutorial slides (task T-382). `slide` (0 to 2) picks the slide:
## tutorial_slides_demo.tscn is slide 1, tutorial_slides_demo_2.tscn and _3.tscn the others.
## Take it with about 10 frames.

@export var slide := 0


func _ready() -> void:
	var slides: TutorialSlides = preload("res://scenes/menu/tutorial_slides.tscn").instantiate()
	add_child(slides)
	slides.show_slide(slide)
