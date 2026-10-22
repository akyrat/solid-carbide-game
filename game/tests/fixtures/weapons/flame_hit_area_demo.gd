extends Node
## Screenshot and GIF fixture (task T-267): the exhaust flamethrower at tier 1 on the street,
## with its hit area outlined in green (debug draw, this fixture only) and the minions' ground
## circles in yellow.
##
## mode "shot": the car stands still with the drift held, a minion stands over the flame (drawn
## behind it) and one just clear of it.
## mode "gif": the car drifts in a circle through still minions, tier 1.
##
## bash game/tools/screenshot.sh res://tests/fixtures/weapons/flame_hit_area_shot.tscn <out.png> 90
## and, for the GIF, game/tools/record_flame_hit_area.sh (needs a window).

@export_enum("shot", "gif") var mode := "shot"
@export var zoom := 4.0
@export var tier := 1
## Hide the outlines (the plain look of the same moment).
@export var outlines := true

const START := Vector2(-62, -30)
## Back from the car, in the flat world (the car heads -45 degrees).
const BACK := Vector2(-0.7071, 0.7071)

var run: Node2D
var flame
var minions_in_play: Array = []
var outline: Node2D


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	run = game.run
	run.minions.enabled = false
	var car: CharacterBody2D = run.car
	car.use_keyboard = false
	car.detect_tricks = false
	car.model.set_position(START)
	car.model.rotation = -PI / 4.0  # nose to the screen's right, the flame goes left
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = run.elevation.ground_height
	run.weapons.gun.set_tier(0)
	run.weapons.flamethrower.set_tier(tier)
	flame = run.weapons.flamethrower
	run.camera_follow.dynamic = false
	run.set_zoom(zoom)
	if mode == "shot":
		car.scripted_input = [false, false, 0.0]
		car.set_physics_process(false)
		# One over the flame, one just clear of its side.
		_minion(START + BACK * 1.9)
		_minion(START + BACK * 1.9 + Vector2(0.707, 0.707) * 2.0)
	else:
		car.scripted_input = [true, false, 1.0]
		# Still minions on a ring around the car's drift (it circles about (-64, -38.5)).
		for k in 9:
			var a := TAU * k / 9.0
			_minion(Vector2(-64.0, -38.5) + Vector2(cos(a), sin(a)) * 5.5)
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()
	if outlines:
		outline = _Outline.new()
		outline.fixture = self
		outline.z_index = 200
		run.view_root.add_child(outline)


func _minion(units: Vector2) -> void:
	var m: Node = run.minions.spawn_minion_at(units)
	m.max_health = 1000.0
	m.health = 1000.0
	m.set_physics_process(false)
	minions_in_play.append(m)


func _physics_process(_delta: float) -> void:
	if run == null:
		return
	run.state.health = run.state.max_health
	if mode == "shot":
		run.car.model.is_drifting = true  # the car is frozen: hold the drift by hand
		run.car.model.vx = 5.0
		run.car.model.vy = 0.0


class _Outline extends Node2D:
	var fixture: Node

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var f = fixture.flame
		if not f.active:
			return
		var iso: Transform2D = f.ISO_TRANSFORM
		var poly := PackedVector2Array()
		for p in f.hit_polygon():
			poly.append(iso * (p * 16.0))
		if poly.size() >= 3:
			var closed := poly.duplicate()
			closed.append(poly[0])
			draw_polyline(closed, Color(0.2, 1.0, 0.3), 1.0)
		for m in fixture.minions_in_play:
			if not is_instance_valid(m):
				continue
			var pts := PackedVector2Array()
			for i in 25:
				var a := TAU * i / 24.0
				pts.append(iso * ((m.position_units() + Vector2(cos(a), sin(a)) * 0.5) * 16.0))
			draw_polyline(pts, Color(1.0, 0.9, 0.2), 1.0)
