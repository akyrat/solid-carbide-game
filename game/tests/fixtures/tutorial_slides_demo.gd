extends Node
## Screenshot fixture for the tutorial slides (tasks T-382, T-485, T-562). `slide` (0 to 5) picks the
## slide: tutorial_slides_demo.tscn is slide 1, tutorial_slides_demo_2.tscn to _6.tscn the others.
## `window_size` sets the window (the stage scales to it). On a trick slide, `drive` drives the
## practice car with scripted W + a turn (a practice in progress), `take_gift` takes the grind's
## Jump gift, and `complete` plays three successes (the success message). Take it with about 30
## frames, or more when driving.

@export var slide := 0
@export var window_size := Vector2i(1280, 720)
@export var drive := false
@export var take_gift := false
@export var complete := false

var slides: TutorialSlides


func _ready() -> void:
	if window_size.x > 0:
		get_window().size = window_size
	slides = preload("res://scenes/menu/tutorial_slides.tscn").instantiate()
	add_child(slides)
	slides.show_slide(slide)
	if not slides.is_trick_slide():
		return
	var session = slides.practices[slide - TutorialSlides.FIRST_TRICK_SLIDE]
	if session == null:
		return
	await get_tree().process_frame
	if take_gift and session.is_gift_open():
		session.gift_screen.skip_animation()
		session.take_gift()
	if drive:
		session.car.use_keyboard = false
		session.car.scripted_input = [true, false, 1.0]
	if complete:
		var ids := {"drift": "extended_drift", "alt_drift": "alternate_drift", "air_spin": "air_three_sixty",
			"grind": "rail_grind"}
		var id: String = ids[session.trick]
		for i in 3:
			if id == "rail_grind":
				session.car.grind.grind_ended.emit("end", 1.0, 6.0)
			else:
				if id == "extended_drift":
					session.car.tricks.last_trick_seconds = 1.2
				session.car.trick.emit(id)
			session.car.stepped.emit()
