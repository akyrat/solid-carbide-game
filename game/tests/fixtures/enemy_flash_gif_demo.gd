extends Node
## GIF and frame-time fixture (task T-404): the car stands still with minions beside it and the
## kaiju further off; they are hit one after another and flash red like the car does (T-403).
## Record it with record_enemy_flash_gif.sh. With the environment variable FLASH_MEASURE=<n> it
## instead places n minions, measures the average frame time with no flashes and with every
## minion flashing (re-hit every 0.3 s), prints both and quits. Needs a real window.

var game: Node
var run: Node2D
var minions: Array = []
var kaiju: Node = null
var n := 0
var measure := 0
var t_idle := 0.0
var t_flash := 0.0


func _ready() -> void:
	measure = int(OS.get_environment("FLASH_MEASURE"))
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	run = game.run
	run.minions.enabled = false
	var car: CharacterBody2D = run.car
	car.use_keyboard = false
	car.detect_tricks = false
	car.scripted_input = [false, false, 0.0]
	run.camera_follow.dynamic = false
	run.set_zoom(9.0)
	run.sync_view()
	var c: Vector2 = car.position / 16.0
	if measure > 0:
		for i in measure:
			var m: Node = run.minions.spawn_minion_at(c + Vector2(2.0 + float(i % 10) * 0.7, -3.0 + float(i / 10) * 0.7))
			m.max_health = 1e9
			m.health = 1e9
			minions.append(m)
	else:
		for i in 6:
			var m: Node = run.minions.spawn_minion_at(c + Vector2(2.5 + 1.2 * float(i % 3), -1.6 + 1.6 * float(i / 3)))
			m.max_health = 1e9
			m.health = 1e9
			minions.append(m)
		run.state.advance(RunState.RUN_SECONDS - RunState.BOSS_TIME_LEFT - run.state.time_elapsed() + 0.01)
		kaiju = run.kaiju_boss.appear_at(c + Vector2(-9.0, -2.0))
	run.minions.update_drawing()


func _process(delta: float) -> void:
	if run == null:
		return
	n += 1
	if measure > 0:
		if n > 30 and n <= 330:
			t_idle += delta
		if n > 330 and n % 18 == 0:
			for m in minions:
				m.take_damage(1.0)
		if n > 360 and n <= 660:
			t_flash += delta
		if n > 660:
			print("FRAME_TIME minions=%d idle_ms=%.3f flashing_ms=%.3f" % [measure, t_idle / 300.0 * 1000.0, t_flash / 300.0 * 1000.0])
			get_tree().quit()
		return
	# gif: hit one minion every 18 frames, the kaiju twice, a couple together
	if n >= 20 and n % 18 == 0:
		var k := (n - 20) / 18
		if k < 6:
			minions[k].take_damage(1.0)
		elif k < 8 and kaiju != null and is_instance_valid(kaiju):
			kaiju.take_damage(1.0)
		elif k == 8:
			for m in minions:
				m.take_damage(1.0)
	if n > 200:
		get_tree().quit()
