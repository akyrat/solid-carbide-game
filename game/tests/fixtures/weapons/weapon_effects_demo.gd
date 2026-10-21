extends Node
## Screenshot and recording fixture (task T-071): a run with the gun (tier 3), the exhaust flamethrower and the
## molotovs, the car drifting in a circle, minions coming in, so the final bullets, exhaust flames and burning
## enemies show. When the environment variable T071_FRAMES is set to a folder, it saves a PNG of the view every
## 4th frame there (frame_000.png ...), which tools can turn into a GIF.
## T071_FRAMES=C:/tmp/frames bash game/tools/screenshot.sh res://tests/fixtures/weapons/weapon_effects_demo.tscn out.png 400

const SAVE_EVERY := 4
const RECORD_FRAMES := 130


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	var run: Node2D = game.run
	run.minions.rng.seed = 42
	run.weapons.upgrade("flamethrower")
	run.weapons.upgrade("molotov")
	run.weapons.upgrade("gun")
	run.weapons.upgrade("gun")
	run.weapons.molotov.rng.seed = 7
	var c: Vector2 = run.car.model.get_position()
	for i in 16:
		run.minions.spawn_minion_at(c + Vector2.from_angle(TAU * i / 16.0) * (3.0 + (i % 4) * 2.0))
	run.car.use_keyboard = false
	run.car.scripted_input = [true, false, 1.0]
	var dir := OS.get_environment("T071_FRAMES")
	if dir != "":
		DirAccess.make_dir_recursive_absolute(dir)
	var n := 0
	for i in RECORD_FRAMES * SAVE_EVERY:
		await get_tree().process_frame
		if i % 30 == 0:  # fresh minions: some in the flames behind the car, some out for the gun
			var at: Vector2 = run.car.model.get_position()
			var rot: float = run.car.model.rotation
			var back := -Vector2(cos(rot), sin(rot))
			for k in 3:
				run.minions.spawn_minion_at(at + back * randf_range(1.2, 2.8) + Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)))
			for k in 3:
				run.minions.spawn_minion_at(at + Vector2.from_angle(randf() * TAU) * randf_range(4.0, 8.0))
		if i == 120 or i == 220:
			run.weapons.molotov.throw_volley()
		if dir != "" and i % SAVE_EVERY == 0:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("%s/frame_%03d.png" % [dir, n])
			n += 1
