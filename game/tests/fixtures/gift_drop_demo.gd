extends Node
## Test fixture for screenshots of the gift pack drop (task T-144): opens the
## game, presses Start and levels the car up, so the helicopter flies across
## the screen and drops the package ahead of the car. With `off_screen` the
## package is moved far to the right once landed, so the edge arrow shows.
## `default_zoom` and `heading_deg` pick the camera and the car's heading.

@export var off_screen := false
## Use the run's default zoom instead of the saved camera options.
@export var default_zoom := false
## The car's heading in degrees before the level-up (-90: up the screen's right, the start).
@export var heading_deg := -90.0


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var run: Node2D = game.run
	run.minions.enabled = false
	if default_zoom:
		run.camera_follow.dynamic = false
		run.set_zoom(run.ZOOM)
	run.car.model.rotation = deg_to_rad(heading_deg)
	run.car._sync_from_model()
	run.sync_view(true)
	await get_tree().process_frame
	var state: RunState = run.state
	state.add_xp(state.xp_needed())
	if off_screen:
		run.gift_drops.land_all()
		var pkg: GiftPackage = run.gift_drops.packages[0]
		pkg.drawn_ground += Vector2(2000, -300)
		pkg.ground_px = GiftDrops.ISO_TRANSFORM.affine_inverse() * pkg.drawn_ground
		pkg.position = pkg.drawn_ground
