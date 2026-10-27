extends "res://tests/fixtures/run_elevation_demo.gd"
## Recording fixture (task T-324): a run from the main menu on the elevation map
## with Bricks at tier 1 (and the gun off, so only the wave hurts). The car
## drives north with W held up ramp-nw-0-3 and jumps off its top onto the
## rooftop roof-nw-3. The moment it takes off, a crowd of minions is placed
## round the spot it lands on (`crowd_centre`): `weak` of them with the minions' own health (the wave kills
## them) and the rest tough, so the push shows. The scene quits
## `after_landing` frames after the landing. Not part of the test suite.
## Record with Godot's movie maker, one physics step per frame:
##   "$GODOT_BIN" --path game --fixed-fps 50 --write-movie C:/abs/dir/f.png res://tests/fixtures/weapons/bricks_landing_gif.tscn
## then assemble the GIF with game/tools/make_turn_gif.py --glob "f*.png".

const CarHeight := preload("res://scripts/driving/car_height.gd")

@export var after_landing := 40
@export var crowd := 12
@export var weak := 6
## Where the crowd stands (flat units); (0, 0) works it out from the takeoff
## instead. The default is where this drive lands (printed by a first run).
@export var crowd_centre := Vector2(-81.0, -77.3)

var _was_airborne := false
var _landed_frame := -1
var _frames := 0


func _ready() -> void:
	drive_steps = -1
	await super._ready()
	run.minions.spawn_multiplier = 0.0  # only the crowd below
	run.minions.combo_raises_spawning = false
	run.weapons.gun.set_tier(0)
	run.weapons.upgrade("bricks")
	run.weapons.bricks.wave_sent.connect(func(at: Vector2, n: int) -> void:
		print("bricks_landing_gif_demo: wave at %s hit %d at frame %d (height %.2f)" % [at, n, _frames, run.car.height]))
	_was_airborne = run.car.airborne


func _on_stepped() -> void:
	var car: CharacterBody2D = run.car
	if car.airborne and not _was_airborne:
		var v: Vector2 = car.model.get_velocity()
		var vz: float = car.vertical_speed
		var t := 2.0 * vz / CarHeight.GRAVITY  # back to the takeoff height
		var spot: Vector2 = car.model.get_position() + v * t
		if crowd_centre != Vector2.ZERO:
			spot = crowd_centre
		print("bricks_landing_gif_demo: took off at %s, speed %.1f, up %.2f, landing near %s" % [
			car.model.get_position(), v.length(), vz, spot])
		# Round the spot, but not in the car's way in from the south (it would hit them).
		for i in crowd:
			var a := -PI / 2.0 + PI * 1.4 * (float(i) / float(maxi(crowd - 1, 1)) - 0.5)
			var d := 1.8 + 1.5 * float(i % 3) / 2.0
			var m: Node = run.minions.spawn_minion_at(spot + Vector2(cos(a), sin(a)) * d)
			if i >= weak:
				m.max_health = 1000.0
				m.health = 1000.0
	if not car.airborne and _was_airborne:
		_landed_frame = _frames
		print("bricks_landing_gif_demo: landed at frame %d at %s" % [_frames, car.model.get_position()])
	_was_airborne = car.airborne


func _process(delta: float) -> void:
	super._process(delta)
	if run == null:
		return
	_frames += 1
	if _landed_frame >= 0 and _frames - _landed_frame >= after_landing:
		get_tree().quit()
	if _frames > 600:
		print("bricks_landing_gif_demo: no landing within 600 frames")
		get_tree().quit()
