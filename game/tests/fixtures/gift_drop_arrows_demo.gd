extends Node
## Test fixture for screenshots of every gift pack having its own arrow (task
## T-314): starts a run, levels the car up three times and sets the packages far
## off screen: two to the right (one landed, one still falling, so their arrows
## are slid apart) and one to the left.


func _ready() -> void:
	GameFlow.tutorial_enabled = false  # Start goes straight to the run (T-442)
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var run: Node2D = game.run
	run.minions.enabled = false
	run.car.model.rotation = deg_to_rad(-90.0)
	run.car._sync_from_model()
	run.sync_view(true)
	await get_tree().process_frame
	var state: RunState = run.state
	for i in 3:
		state.add_xp(state.xp_needed())
	run.gift_drops.land_all()
	var offsets := [Vector2(2000, -300), Vector2(2000, -250), Vector2(-2200, 100)]
	for i in 3:
		var pkg: GiftPackage = run.gift_drops.packages[i]
		pkg.drawn_ground += offsets[i]
		pkg.ground_px = GiftDrops.ISO_TRANSFORM.affine_inverse() * pkg.drawn_ground
		pkg.position = pkg.drawn_ground
	var falling: GiftPackage = run.gift_drops.packages[1]
	falling.phase = GiftPackage.FALLING
	falling.fall_seconds = 1000.0
	falling.fall_t = 0.0
	falling.drop_height = 0.0
