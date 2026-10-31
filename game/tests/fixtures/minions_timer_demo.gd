extends Node
## Screenshot fixture (task T-443): a run started from the main menu, its clock moved to
## `run_seconds`, then the spawner's timer run by hand for `simulate_seconds` with the car
## standing still and nobody shooting, so the screen shows how many the timer has brought in
## from the screen's edges by then. Prints the count and the interval.
## bash game/tools/screenshot.sh res://tests/fixtures/minions_timer_demo.tscn screenshots/late.png 20
## bash game/tools/screenshot.sh res://tests/fixtures/minions_timer_early_demo.tscn screenshots/early.png 20

@export var run_seconds := 400.0
@export var simulate_seconds := 15.0
## For the GIF (record_minions_timer_gif.sh): keep the parked car at full health while the run plays live.
@export var hold_health := false

var _run: Node2D = null


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.start_run()  # skips the tutorial slides (T-389)
	await get_tree().process_frame
	var run: Node2D = game.run
	_run = run
	run.car.use_keyboard = false
	var spawner: Node = run.minions
	spawner.rng.seed = 443
	run.state.advance(run_seconds)
	var t := 0.0
	while t < simulate_seconds:
		spawner.step(0.02)
		run.state.health = run.state.max_health
		t += 0.02
	spawner.update_drawing()
	for m in spawner.minions:
		m.sprite.reset_physics_interpolation()
	print("T-443 demo: run_seconds=%.0f simulated=%.0f spawned=%d alive=%d interval=%.3f" % [
		run.state.time_elapsed(), simulate_seconds, spawner.spawned_total, spawner.minions.size(), spawner.spawn_interval()])


func _physics_process(_delta: float) -> void:
	if hold_health and _run != null:
		_run.state.health = _run.state.max_health
