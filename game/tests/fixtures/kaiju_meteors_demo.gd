extends Node
## Screenshot fixture (task T-046): a run started from the main menu with the
## placeholder kaiju beside the car, three warning circles of its meteor attack
## on the ground (one meteor falling) and two boulders left by meteors that
## just landed (with their dust), all held still for the picture.
## bash game/tools/screenshot.sh res://tests/fixtures/kaiju_meteors_demo.tscn screenshots/T-046_meteors.png 20


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
	boss.enabled = false  # stands still for the picture
	var k: Node = boss.appear_at(c + Vector2(-6.0, 5.0))
	k.heading = Vector2(1.0, -1.0).normalized()
	boss.update_drawing()
	var met: Node = boss.meteors
	met.enabled = false  # no new attack during the picture
	met.set_physics_process(false)  # the warnings, the falling meteor and the dust hold still
	met.rng.seed = 46
	var landed := 0
	for p in [Vector2(5.0, -3.0), Vector2(-3.0, -6.0), Vector2(6.0, 4.0), Vector2(-5.5, 0.5), Vector2(2.0, 7.0)]:
		var u: Vector2 = c + p
		if not met.is_good_spot(u):
			continue
		if landed < 2:
			met.land(u)
			landed += 1
		else:
			var w: Dictionary = met.add_warning(u)
			w.time_left = 0.25 if met.warnings.size() == 1 else 1.6
	print("T-046 demo: kaiju %s, warnings %d, meteor boulders %d, car %s" % [
		k.position_units(), met.warnings.size(), run.map.meteor_boulders.size(), c])
