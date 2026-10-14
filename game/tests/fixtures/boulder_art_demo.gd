extends Node
## Screenshot fixture (task T-065): a run started from the main menu with the
## boulder art, the car put beside the obstacle pattern at the crossing
## 27, -54 (two boulders), and one meteor boulder landed nearby.
## bash game/tools/screenshot.sh res://tests/fixtures/boulder_art_behind.tscn screenshots/T-065_boulders_behind.png 30
## bash game/tools/screenshot.sh res://tests/fixtures/boulder_art_front.tscn screenshots/T-065_boulders_front.png 30

## Where the car is put (units from the map's centre) and its heading (radians).
@export var car_at := Vector2(28.5, -56.0)
@export var heading := 0.0
## Camera zoom as Unity's orthographic size (20 = the pause slider's widest).
@export var zoom := 20.0
## Where the meteor boulder lands.
@export var meteor_boulder_at := Vector2(10.0, -45.0)


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	var run: Node2D = game.run
	run.car.use_keyboard = false
	run.set_zoom(zoom)
	run.car.model.x = car_at.x
	run.car.model.y = car_at.y
	run.car.model.rotation = heading
	run.car._sync_from_model()
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()
	if run.map.can_place_meteor_boulder(meteor_boulder_at):
		run.map.add_meteor_boulder(meteor_boulder_at)
	var variants := {}
	for s in run.map.boulder_sprites:
		variants[s.variant] = int(variants.get(s.variant, 0)) + 1
	print("T-065 demo: boulders=%d sprites=%d variants=%s car=%s car_z=%d top_z=%d" % [
		run.map.all_boulders().size(), run.map.boulder_sprites.size(), variants,
		run.car.position / 16.0, run.view_root.z_index, run.map.top_z_index()])
