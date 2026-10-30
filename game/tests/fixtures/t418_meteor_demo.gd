extends Node
## Screenshot fixture (task T-418): a meteor about to land on three minions with a coin and a health
## pickup on its spot ("before": the warning circle), and the moment after ("after": dust, the
## boulder, the minions hurt and flashing, the coin and the pickup pushed out beside it).
## bash game/tools/screenshot.sh res://tests/fixtures/t418_meteor_demo_before.tscn screenshots/before.png 20
## bash game/tools/screenshot.sh res://tests/fixtures/t418_meteor_demo_after.tscn screenshots/after.png 8

@export var after := false


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.start_run()  # skips the tutorial slides (T-389)
	for i in 30:
		await get_tree().process_frame
		if game.run != null:
			break
	var run: Node2D = game.run
	run.car.use_keyboard = false
	run.minions.enabled = false
	var c: Vector2 = run.car.position / 16.0
	var boss: Node = run.kaiju_boss
	boss.enabled = false
	var met: Node = boss.meteors
	met.enabled = false
	met.set_physics_process(false)
	met.rng.seed = 418
	var spot := Vector2.ZERO
	for i in 64:
		var p := c + Vector2.RIGHT.rotated(TAU * i / 64.0) * 6.0
		if met.is_good_spot(p) and run.minions.is_free_spot(p):
			spot = p
			break
	var minions := []
	for o in [Vector2(1.0, 0.3), Vector2(0.3, 1.0), Vector2(-0.4, -0.5)]:
		minions.append(run.minions.spawn_minion_at(spot + o))
	run.minions.spawn_coin_at(spot + Vector2(0.4, 0.4))
	run.minions.spawn_health_pickup_at(spot + Vector2(0.5, -0.1))
	if after:
		met.land(spot)
	else:
		var w: Dictionary = met.add_warning(spot)
		w.time_left = 1.5
	var healths := []
	for m in minions:
		healths.append(m.health)
	print("T-418 demo (after=%s): minion health %s of %s, boulders %d" % [after, healths, run.minions._stats.get("health"), run.map.meteor_boulders.size()])
	for p in run.minions.coins + run.minions.health_pickups:
		print("  pickup %.2f units from the spot (boulder radius %.2f)" % [p.position_units().distance_to(spot), run.map.boulder_diameter() / 2.0])
