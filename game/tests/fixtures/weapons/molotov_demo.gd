extends Node
## Screenshot and play fixture (task T-169): a run started from the main menu
## with the molotovs given (rack.upgrade("molotov")), minions standing round
## the car, the first throw made at once so bottles and fire areas show early.
## Screenshot: bash game/tools/screenshot.sh res://tests/fixtures/weapons/molotov_demo.tscn screenshots/molotov.png 50
## To play it yourself: open this scene in the editor and press F6; the
## keyboard drives the car once the scripted part is over (2 seconds).

func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	var run: Node2D = game.run
	run.minions.rng.seed = 42
	var mol = run.weapons.molotov
	mol.rng.seed = 7
	if not mol.is_owned():  # whatever the playtest switch says
		run.weapons.upgrade("molotov")
	# The first fires each get two minions in them, so the screenshot shows burning.
	var demo_fires := [0]
	mol.fire_started.connect(func(f: Node) -> void:
		print("T-169 demo: fire at %s radius %.2f" % [f.centre, f.radius])
		f.enemy_hit.connect(func(e: Node, amount: float) -> void:
			print("T-169 demo: burnt %s for %.2f" % [e.name, amount]))
		if demo_fires[0] < 3:
			demo_fires[0] += 1
			run.minions.spawn_minion_at(f.centre + Vector2(0.4, 0.0))
			run.minions.spawn_minion_at(f.centre + Vector2(-0.4, 0.3)))
	# Minions in a ring 10 units round the car, walking in through the fires.
	var c: Vector2 = run.car.model.get_position()
	for i in 12:
		run.minions.spawn_minion_at(c + Vector2.from_angle(TAU * i / 12.0) * 10.0)
	mol.throw_clock = mol.throw_interval()  # the first throw on the first step
	mol.throw_volley()
	mol.throw_volley()
	run.car.use_keyboard = false
	run.car.scripted_input = [false, false, 0.0]
	for i in 100:
		await get_tree().physics_frame
	print("T-169 demo: molotov tier=%d throws=%d fires=%d" % [mol.tier, mol.throws, mol.fires])
	run.car.use_keyboard = true
