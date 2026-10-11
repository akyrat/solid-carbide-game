extends Node
## Screenshot fixture (task T-097): a run started from the main menu, with the
## car moved up to the crossing at 0, -54 where preset challenge-6 used to be,
## and one meteor boulder placed beside it. Challenges are off in the MVP, so it
## shows boulders and no arrows.
## bash game/tools/screenshot.sh res://tests/fixtures/map_from_menu_demo.tscn screenshots/map_from_menu.png 30

## Where the car is put, in units from the map's centre (nose up, -y).
const CAR_AT := Vector2(4.0, -46.0)
## Where the meteor boulder lands.
const METEOR_BOULDER_AT := Vector2(-4.0, -47.0)


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	var run: Node2D = game.run
	run.car.use_keyboard = false
	run.set_zoom(20.0)  # the pause slider's widest view, to show more of the map
	run.car.model.x = CAR_AT.x
	run.car.model.y = CAR_AT.y
	run.car._sync_from_model()
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()
	if run.map.can_place_meteor_boulder(METEOR_BOULDER_AT):
		run.map.add_meteor_boulder(METEOR_BOULDER_AT)
	print("T-097 demo: challenges=%d arrows=%d meteor boulders=%d car=%s" % [
		run.map.challenge_ids().size(), run.map.arrows.size(),
		run.map.meteor_boulders.size(), run.car.position / 16.0])
