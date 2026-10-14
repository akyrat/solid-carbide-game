extends Node
## Screenshot fixture (task T-129): a run from the main menu with the car put next to the first short
## building found. mode "behind": on the road just behind a side-slot short building (it fades when it covers the
## car); "beside": on the road in front of a front-slot short building, a skyscraper beside it; "wide": the
## widest zoom over the same spot.
## bash game/tools/screenshot.sh res://tests/fixtures/short_building_beside.tscn screenshots/x.png 60

@export var mode := "beside"
@export var zoom := 14.4
@export var gap := 1.5


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	var run: Node2D = game.run
	var car_at := Vector2.ZERO
	for s in run.map.slots:
		if s.height_units > 10.0:
			continue
		for b in run.map.buildings:
			if not b.footprint.encloses(s.footprint):
				continue
			var si := roundi((s.footprint.position.x - b.footprint.position.x - 1.5) / 15.0)
			var sj := roundi((s.footprint.position.y - b.footprint.position.y - 1.5) / 15.0)
			if mode == "behind" and si == 1 and sj == 0:
				car_at = Vector2(s.footprint.position.x + 6.0, b.footprint.position.y - gap)
			elif mode != "behind" and si == 1 and sj == 1:
				car_at = Vector2(s.footprint.position.x + 6.0, b.footprint.end.y + 4.0)
		if car_at != Vector2.ZERO:
			break
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
	print("T-129 demo: mode=%s car=%s covering=%s" % [mode, car_at, faded])
