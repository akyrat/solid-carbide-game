extends Node
## Screenshot fixture (task T-372): a run started from the main menu's Start, on the game's map
## (the board's level, data/level/kaiju_city_map.json). `shot` picks what is shown:
##   "start"   the car on its spawn point with minions coming (the run's default zoom);
##   "wide"    the same from the widest zoom, to show more of the map;
##   "rooftop" the car parked on roof-1 with minions coming up its ramps;
##   "kaiju"   the kaiju arrived at boss time, walking to the car;
##   "gift"    a gift pack landed ahead of the car.
## bash game/tools/screenshot.sh res://tests/fixtures/game_map_run_start.tscn art-archive/T-372/screenshots/start.png 90

@export var shot := "start"

const ROOF_1_AT := Vector2(-32.0, 36.0)
## T-547: parked beside the board's rails (rail-1 and rail-2 near the spawn) and its ramps up to roof-1.
const AT := {"rails": Vector2(20.0, -30.0), "rails_far": Vector2(-46.0, -96.0), "ramps": Vector2(-84.0, -100.0), "ramp13": Vector2(-24.0, -112.0)}
const ZOOMS := {"ramps": 14.0, "ramp13": 14.0, "rails_far": 14.0}
var game: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameFlow.tutorial_enabled = false  # Start goes straight to the run
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	var run: Node2D = game.run
	run.car.use_keyboard = false
	run.car.set_physics_process(false)  # parked, so the picture stays on its spot
	run.kaiju_boss.enabled = shot == "kaiju"
	var spawner: Node = run.minions
	spawner.rng.seed = 372
	if shot == "wide":
		run.camera_follow.dynamic = false
		run.set_zoom(20.0)
	if ZOOMS.has(shot):
		run.camera_follow.dynamic = false
		run.set_zoom(ZOOMS[shot])
	if AT.has(shot):
		run.car.model.set_position(AT[shot])
		run.car.model.set_velocity(Vector2.ZERO)
		run.car._sync_from_model()
	if shot == "rooftop":
		run.car.model.set_position(ROOF_1_AT)
		run.car.model.set_velocity(Vector2.ZERO)
		run.car._sync_from_model()
	run.sync_view(true)
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()
	for i in 3:  # the camera catches up with the car before minions spawn round the screen
		await get_tree().process_frame
	if shot in ["start", "wide", "rooftop"]:  # (the T-547 shots show the rails and ramps without minions)
		for i in 300:  # 15 s of the run's minions, as in a run
			run.state.health = run.state.max_health
			run.state.advance(0.05)
			spawner.step(0.05)
	if shot == "kaiju":
		spawner.enabled = false
		run.state.advance(RunState.RUN_SECONDS - RunState.BOSS_TIME_LEFT + 0.5)
		for i in 60:
			if run.kaiju_boss.has_appeared():
				break
			run.kaiju_boss.step(1.0 / 60.0)
		for i in 240:
			run.state.health = run.state.max_health
			run.kaiju_boss.step(1.0 / 60.0)
	if shot == "gift":
		spawner.enabled = false
		run.state.add_xp(run.state.xp_needed())
		run.gift_drops.land_all()
		get_tree().paused = false
		var ls = run.get_node_or_null("LevelUpScreenLayer")
		if ls != null:
			ls.visible = false
	print("T-372 demo %s: map=%s car=%s minions=%d kaiju=%s packages=%d" % [shot,
		run.map.layout_path, run.car.position / 16.0, spawner.minions.size(),
		run.kaiju_boss.has_appeared(), run.gift_drops.landed_packages().size()])


## A headless screenshot window has no focus, so the game pauses the run (T-416); the pictures
## are of the map, so the pause screen is closed again.
func _process(_dt: float) -> void:
	if game != null and game.pause_screen != null and game.pause_screen.is_paused():
		game.pause_screen.toggle()
