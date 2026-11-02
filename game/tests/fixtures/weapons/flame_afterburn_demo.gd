extends Node
## Screenshot fixture (task T-497): the exhaust flamethrower's afterburn. The car
## stands with the drift held (the flame on). A row of minions stands in the flame
## for `in_flame_frames` physics frames, then is moved clear of it, in front of the
## car; they keep burning there (orange tint and burn flames, and their hits) for
## the burn time (`burn_seconds`, set in the stats directly). A second row is
## always clear of the flame and never burns, for comparison. The minions have 1000
## health so they stay to be seen.
##
## bash game/tools/screenshot.sh res://tests/fixtures/weapons/flame_afterburn_shot.tscn <out.png> 90

@export var zoom := 7.0
@export var tier := 6
@export var burn_seconds := 2.38
@export var in_flame_frames := 15

var run: Node2D
var flame
var burnt: Array = []
var frames := 0
var start := Vector2.ZERO


func _ready() -> void:
	run = preload("res://scenes/run/run.tscn").instantiate()
	add_child(run)
	run.minions.enabled = false
	# No mission overlay over the picture (a mission done pauses the run, T-459).
	run.state.missions.mission_completed.disconnect(run.power_up_offers._on_mission_completed)
	var car: CharacterBody2D = run.car
	car.use_keyboard = false
	car.detect_tricks = false
	car.scripted_input = [false, false, 0.0]
	await get_tree().physics_frame
	car.set_physics_process(false)
	start = car.model.get_position()
	run.weapons.gun.set_tier(0)
	run.weapons.upgrade("flamethrower")
	run.weapons.flamethrower.set_tier(tier)
	flame = run.weapons.flamethrower
	flame.stats["burn_flash_seconds"] = burn_seconds
	run.set_zoom(zoom)
	var back := -Vector2(cos(car.model.rotation), sin(car.model.rotation))
	var side := back.orthogonal()
	for k in 3:
		burnt.append(_minion(start + back * (1.7 + 0.5 * k) + side * (0.4 * (k - 1))))
	for k in 3:
		_minion(start - back * 4.0 + side * (3.0 + 2.5 * k))  # never in the flame


func _minion(units: Vector2) -> Node:
	var m: Node = run.minions.spawn_minion_at(units)
	m.max_health = 1000.0
	m.health = 1000.0
	m.set_physics_process(false)
	return m


func _physics_process(_delta: float) -> void:
	if run == null or flame == null:
		return
	run.state.health = run.state.max_health
	run.car.model.is_drifting = true  # the car is frozen: hold the drift by hand
	run.car.model.vx = 5.0
	run.car.model.vy = 0.0
	frames += 1
	if frames == in_flame_frames:
		# Out of the flame: a row in front of the car, on the other side.
		var back := -Vector2(cos(run.car.model.rotation), sin(run.car.model.rotation))
		var side := back.orthogonal()
		for k in burnt.size():
			burnt[k].set_position_units(start - back * 2.5 - side * (1.0 + 2.2 * k))
		run.minions.update_drawing()  # the spawner is off: place the moved sprites by hand
