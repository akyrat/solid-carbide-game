extends SceneTree
## Screenshots of the minion deaths (task T-531): the game's own run, car parked on the street, then
##  1. a ring of minions killed, shot 0.2 s later (the death animation with the spill in the air);
##  2. 0.9 s later (pools and corpses lying), then the car driven into the corpses and shot 0.3 s after (knocked);
##  3. a field of 40 killed at once and shot 1.9 s later and 2.2 s later (whole, then fading).
## Needs a window. Usage: godot --path game -s res://tools/death_shots.gd -- --out=C:/abs/folder

const GameScene := preload("res://scenes/game/game.tscn")

var out_dir := ""
var game: Node
var run: Node2D
var spawner: Node


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.get_slice("=", 1)
	if out_dir == "":
		printerr("death_shots: need --out=<folder>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(out_dir)
	PlayerProgress.path = "user://death_shots_progress.json"
	RunHistory.path = "user://death_shots_history.json"
	GameSettings.path = "user://death_shots_settings.cfg"
	GameFlow.tutorial_enabled = false
	_main.call_deferred()


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [out_dir, name])
	print("death_shots: ", name)


func _kill_ring(n: int, radius: float, centre: Vector2) -> void:
	for i in n:
		var p := centre + Vector2.from_angle(TAU * i / n + 0.3) * radius
		var m = spawner.spawn_minion_at(p)
		m.heading = (centre - p).normalized()
		m.take_damage(100000.0)


func _main() -> void:
	game = GameScene.instantiate()
	game.set("tutorial_enabled", false)
	root.add_child(game)
	game.start_run()
	await _wait(1.0)
	run = game.run
	spawner = run.minions
	spawner.enabled = false
	spawner.clear()
	run.kaiju_boss.enabled = false
	var car = run.car
	car.use_keyboard = false
	car.set("detect_tricks", false)
	car.set_physics_process(false)
	run.state.max_health = 100000.0
	run.state.health = 100000.0
	var c: Vector2 = car.position / 16.0
	# Re-enable the spawner's step for the corpses only (no spawning, no walking).
	spawner.enabled = true
	spawner._spawning["max_minions_alive"] = 0.0
	spawner._spawn_clock = -INF
	# 1. a ring of 7 killed 5 units in front of the car.
	var centre := c + Vector2(7, 0)
	_kill_ring(7, 2.2, centre)
	await _wait(0.18)
	await _shot("1_death_mid_animation_with_spill")
	await _wait(0.9)
	await _shot("2a_corpses_lying_with_pools")
	# The car drives into them.
	car.model.set_velocity(Vector2(14, 0))
	car._sync_from_model()
	var t := 0.0
	while t < 0.35:
		car.model.set_position(car.model.get_position() + Vector2(14, 0) * 0.016)
		car._sync_from_model()
		run.sync_view()
		await process_frame
		t += 0.016
	await _shot("2b_corpses_knocked_by_the_car")
	# 3. a field of 40 at once, 5 to 9 units out.
	spawner.corpses.clear()
	car.model.set_velocity(Vector2.ZERO)
	var field_centre: Vector2 = car.position / 16.0 + Vector2(0, 0)
	for k in 40:
		var a := randf() * TAU
		var p := field_centre + Vector2.from_angle(a) * randf_range(3.0, 9.0)
		var m = spawner.spawn_minion_at(p)
		m.take_damage(100000.0)
	await _wait(1.6)
	await _shot("3a_a_field_of_corpses")
	await _wait(0.65)
	await _shot("3b_the_field_fading")
	quit(0)
