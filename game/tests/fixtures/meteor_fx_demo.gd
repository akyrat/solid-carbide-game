extends Node
## Recording fixture (task T-070): a run from the main menu with the car standing
## still and the placeholder kaiju beside it, and meteors that start falling at
## once and keep falling (three more every 1.5 seconds), so the comet tails and
## the impact animations can be recorded without waiting for the kaiju's real
## attack late in the run. The version comes from METEOR_FX or data/meteor_fx.json.
## Record: bash game/tools/record_meteor_fx.sh <version> <out.gif>

var met: Node
var run: Node2D
var _next := 0.2
var _clock := 0.0
var _round := 0


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	run = game.run
	run.car.use_keyboard = false
	run.minions.enabled = false
	var c: Vector2 = run.car.position / 16.0
	var boss: Node = run.kaiju_boss
	boss.enabled = false
	var k: Node = boss.appear_at(c + Vector2(-9.0, 7.0))
	k.heading = Vector2(1.0, -1.0).normalized()
	boss.update_drawing()
	met = boss.meteors
	met.enabled = false  # the scheduled attack stays off; this fixture drops its own
	met.rng.seed = 70
	print("meteor fx demo: version ", MeteorFx.version())


func _process(delta: float) -> void:
	if met == null:
		return
	_clock += delta
	if _clock < _next:
		return
	_next = _clock + 1.5
	_round += 1
	var c: Vector2 = run.car.position / 16.0
	var placed := 0
	for i in 40:
		var u := c + Vector2(met.rng.randf_range(-4.5, 4.5), met.rng.randf_range(-3.5, 3.5))
		if placed < 3 and met.is_good_spot(u):
			var w: Dictionary = met.add_warning(u)
			w.time_left = 0.5 + 0.25 * placed + 0.35
			placed += 1
