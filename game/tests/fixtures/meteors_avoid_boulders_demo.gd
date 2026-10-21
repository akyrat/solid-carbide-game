extends Node
## Screenshot fixture (task T-147): a meteor boulder stands beside the car and
## several rounds of warning circles are shown together; none touches the
## boulder, they keep boulder_clearance_units of free ground from it.
## bash game/tools/screenshot.sh res://tests/fixtures/meteors_avoid_boulders_demo.tscn screenshots/T-147_avoid.png 20


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	var run: Node2D = game.run
	run.car.use_keyboard = false
	run.minions.enabled = false
	var c: Vector2 = run.car.position / 16.0
	var boss: Node = run.kaiju_boss
	boss.enabled = false
	var met: Node = boss.meteors
	met.enabled = false
	met.set_physics_process(false)
	met.rng.seed = 147
	var boulder_at := c + Vector2(4.0, -2.0)
	if met.is_good_spot(boulder_at):
		var body: Node = run.map.add_meteor_boulder(boulder_at)
		met.standing_boulders.append({"body": body, "age": 0.0})
	for i in 7:
		var p = met.pick_spot()
		if p != null:
			var w: Dictionary = met.add_warning(p)
			w.time_left = 1.9
	print("T-147 demo: boulders %d, warnings %d" % [run.map.meteor_boulders.size(), met.warnings.size()])
