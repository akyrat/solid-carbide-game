extends Node
## Screenshot fixture (task T-132): a run started from the main menu with the car
## put behind a skyscraper block (it drives under the building, which fades), and
## trick popups shown at the car; they must draw over the building.
## bash game/tools/screenshot.sh res://tests/fixtures/popup_over_building_demo.tscn screenshots/T-132_popups_over_building.png 30

## Among the skyscraper blocks south of the gravel centre (units from the map's centre), nose up.
@export var car_at := Vector2(20.0, 70.0)
@export var heading := -PI / 2.0

var run: Node2D
var _frames := 0


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	run = game.run
	run.car.use_keyboard = false
	run.car.model.x = car_at.x
	run.car.model.y = car_at.y
	run.car.model.rotation = heading
	run.car._sync_from_model()
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()


func _process(_delta: float) -> void:
	_frames += 1
	if _frames == 12 and run != null:
		var at: Vector2 = run.car_sprite.position
		var f := func() -> Vector2: return run.car_sprite.position
		run.trick_popups.show_popup("LONG DRIFT! +0.05", at, 16, f)
		run.trick_popups.show_popup("FULL 360! +0.25", at, 28, f)
		print("T-132 demo: car_z=%d top_z=%d popups=%d" % [run.view_root.z_index, run.map.top_z_index(), run.trick_popups.popups().size()])
