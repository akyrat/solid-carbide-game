extends Node
## Screenshot fixture (task T-103): a run started from the main menu
## (game.tscn, Start), with the car moved to a chosen spot and standing still,
## to see the ground art there. Environment variables (all optional):
##   GROUND_X, GROUND_Y: the car's position in units from the map's centre
##     (default 0, 0: the gravel centre, where a run starts);
##   GROUND_HEADING_DEG: the car's heading (0 = nose along +x; default -90);
##   GROUND_ZOOM: the camera zoom as an orthographic size in units (default:
##     the game's setting).
## Example, from the repo root:
##   GROUND_X=-54 GROUND_Y=-54 bash game/tools/screenshot.sh res://tests/fixtures/ground_from_menu_demo.tscn screenshots/t103_junction.png 30


func _env(name: String, fallback: float) -> float:
	return float(OS.get_environment(name)) if OS.has_environment(name) else fallback


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	var run: Node2D = game.run
	run.car.use_keyboard = false
	run.car.model.x = _env("GROUND_X", 0.0)
	run.car.model.y = _env("GROUND_Y", 0.0)
	run.car.model.rotation = deg_to_rad(_env("GROUND_HEADING_DEG", -90.0))
	run.car._sync_from_model()
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()
	if OS.has_environment("GROUND_ZOOM"):
		run.set_zoom(_env("GROUND_ZOOM", 14.4))
	run.car.scripted_input = [false, false, 0.0]
	print("T-103 demo: car at %s units, ground art drawn: %s" % [
		Vector2(run.car.model.x, run.car.model.y), run.map.uses_ground_art()])
