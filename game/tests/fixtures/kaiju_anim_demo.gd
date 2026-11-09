extends Node
## Recording fixture (task T-612): a run started from the main menu, the car parked, the
## kaiju walking in towards it (minions off), playing one of its animations, chosen by the
## environment variable KAIJU_ANIM ("walk", the default; "windup": a meteor attack starts at
## 0.3 s; "death": it is killed at 0.5 s, and the win screen follows its death).
## Record: bash game/tools/record_kaiju_anim_gif.sh <walk|windup|death> <out.gif> [seconds]

const START_OFFSET := Vector2(-6.0, 6.0)

var _mode := "walk"
var _t := 0.0
var _done := false
var _run: Node2D


func _ready() -> void:
	_mode = OS.get_environment("KAIJU_ANIM")
	if _mode == "":
		_mode = "walk"
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.start_run()  # straight into the run, without the tutorial slides
	await get_tree().process_frame
	_run = game.run
	_run.car.use_keyboard = false
	_run.minions.enabled = false
	var car_units: Vector2 = _run.car.position / 16.0
	var off := START_OFFSET
	var env_off := OS.get_environment("KAIJU_OFFSET")   # T-613: "x,y" in units, to keep it in clear view
	if env_off.contains(","):
		off = Vector2(float(env_off.get_slice(",", 0)), float(env_off.get_slice(",", 1)))
	var k: Node = _run.kaiju_boss.appear_at(car_units + off)
	k.heading = (-off).normalized()


func _physics_process(delta: float) -> void:
	if _run == null or _done:
		return
	_t += delta
	var boss: Node = _run.kaiju_boss
	if _mode == "windup" and _t >= 0.3:
		_done = true
		boss.meteors.start_attack()
	elif _mode == "death" and _t >= 0.5 and boss.kaiju != null:
		_done = true
		if OS.get_environment("KAIJU_FACE") == "e":   # T-613: die facing east (the final death art)
			boss.kaiju.sprite.facing = Vector2.RIGHT
		boss.kaiju.take_damage(1e9)
