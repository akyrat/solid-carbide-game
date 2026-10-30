extends Node
## GIF fixture (task T-408): the car stands still and the gun shoots a swarm of real minions (the
## data's health, so one bullet kills one) at tier 1, then tier 6, then tier 11; each phase starts
## with a fresh swarm. Phases of PHASE_FRAMES frames: tier 1, tier 6, tier 11. Record it with
## record_gun_tiers_gif.sh. Needs a real window. Not in the game.

const PHASE_FRAMES := 150  # 5 s at 30 fps
const TIERS := [1, 6, 11]

var game: Node
var run: Node2D
var n := 0
var phase := -1


func _ready() -> void:
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
	run.set_zoom(11.0)
	run.sync_view()


func _swarm() -> void:
	run.minions.clear()
	run.weapons.clear_projectiles()
	var c: Vector2 = run.car.position / 16.0
	for i in 14:
		var ang := TAU * float(i) / 14.0 + 0.3 * float(i % 2)
		var d := 4.0 + 6.5 * float((i * 5) % 7) / 6.0
		run.minions.spawn_minion_at(c + Vector2(cos(ang), sin(ang)) * d)
	run.minions.update_drawing()


func _process(_delta: float) -> void:
	if run == null:
		return
	run.state.health = run.state.max_health
	var p := n / PHASE_FRAMES
	if p != phase and p < TIERS.size():
		phase = p
		run.weapons.gun.set_tier(TIERS[p])
		run.weapons.gun.fire_clock = 0.0
		_swarm()
	n += 1
	if n >= PHASE_FRAMES * TIERS.size():
		get_tree().quit()
