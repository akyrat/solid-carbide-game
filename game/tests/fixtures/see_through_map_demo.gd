extends Node
## Screenshot fixture (task T-034): a run started from the main menu with the
## car put at `car_at` and standing still. "behind": on the road just north of
## the block south of the gravel centre, so that block covers it and fades to
## 15% visible. "open": the car on the road just south of the same block, in
## front of it, so the block stays solid. Both use the pause slider's widest
## zoom, to show the whole block.
## Take it with about 60 frames (the fade takes 0.15 s):
## bash game/tools/screenshot.sh res://tests/fixtures/see_through_map_behind.tscn screenshots/see_through_behind.png 60

## Where the car is put, in units from the map's centre (nose up, -y).
@export var car_at := Vector2(27, 60)
## The camera size (orthographic, half the visible height in units).
@export var zoom := 20.0


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	var run: Node2D = game.run
	run.set_zoom(zoom)
	run.car.use_keyboard = false
	run.car.scripted_input = [false, false, 0.0]
	run.car.model.x = car_at.x
	run.car.model.y = car_at.y
	run.car._sync_from_model()
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()
	await get_tree().create_timer(0.5).timeout
	var faded := []
	for b in run.map.covering_buildings():
		faded.append("%s alpha %.2f" % [b.name, b.alpha()])
	print("T-034 demo: car=%s covering=%s car z=%d" % [car_at, faded, run.view_root.z_index])
