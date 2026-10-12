extends Node
## Screenshot fixture (task T-101): a run started from the main menu
## (game.tscn, Start), with the car turned to a chosen heading and driving
## straight ahead (W held), to see the final car art in each direction.
## The heading in degrees (world heading: 0 = nose along +x, clockwise on
## screen, so frame = heading / 22.5) comes from the environment variable
## CAR_HEADING_DEG, default 0. Example, from the repo root:
##   CAR_HEADING_DEG=90 bash game/tools/screenshot.sh res://tests/fixtures/car_art_from_menu_demo.tscn screenshots/car_090.png 40


func _ready() -> void:
	var heading := 0.0
	if OS.has_environment("CAR_HEADING_DEG"):
		heading = float(OS.get_environment("CAR_HEADING_DEG"))
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	var run: Node2D = game.run
	run.car.use_keyboard = false
	run.car.model.rotation = deg_to_rad(heading)
	run.car._sync_from_model()
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()
	run.car.scripted_input = [true, false, 0.0]
	print("T-101 demo: heading %.1f deg, frame %d, sprite scale %s, texture %s" % [
		heading, run.car_sprite.frame, run.car_sprite.scale, run.car_sprite.texture.resource_path])
