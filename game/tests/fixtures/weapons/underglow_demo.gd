extends Node
## Screenshot and play fixture (task T-168): a run started from the main menu
## with the neon underglow given (rack.upgrade("underglow")), the car driving
## slowly, minions coming in and getting hurt by the placeholder ring.
## Screenshot: bash game/tools/screenshot.sh res://tests/fixtures/weapons/underglow_demo.tscn screenshots/underglow.png 90
## To play it yourself: open this scene in the editor and press F6; the
## keyboard drives the car once the scripted part is over (2 seconds).

func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	var run: Node2D = game.run
	run.minions.rng.seed = 42
	var glow = run.weapons.underglow
	if not glow.is_owned():  # whatever the playtest switch says
		run.weapons.upgrade("underglow")
	glow.enemy_hit.connect(func(e: Node, amount: float) -> void:
		print("T-168 demo: hit %s for %.2f" % [e.name, amount]))
	# Four minions just inside the ring, so the screenshot shows hits at once.
	var c: Vector2 = run.car.model.get_position()
	var r: float = glow.radius() * 0.8
	for d in [Vector2(r, 0), Vector2(-r, 0), Vector2(0, r), Vector2(0, -r)]:
		run.minions.spawn_minion_at(c + d)
	run.car.use_keyboard = false
	run.car.scripted_input = [false, false, 0.0]
	for i in 100:
		await get_tree().physics_frame
	print("T-168 demo: underglow tier=%d radius=%.2f hits=%d" % [glow.tier, glow.radius(), glow.hits])
	run.car.use_keyboard = true
