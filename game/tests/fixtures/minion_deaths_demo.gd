extends Node
## Video fixture (task T-531): the minion deaths in the run's own map, about 28 s, scripted by time.
##  0 s   a crowd of minions walks at the parked car; its gun and the wiper kill them (the placeholder
##        death animation, the green spill splashing and pooling), one dies on a rooftop;
##  9 s   survivors are finished off;
## 11 s   the car drives east through the corpses, shoving them, and back west;
## 17 s   it stops among them: the wiper pushes corpses; 20 s a bricks wave lands and pushes them;
## 22 s   the car leaves them alone, so they fade 2 s after their last hit.
## Record it with record_minion_deaths_video.sh. The car's health is topped up throughout.

const T_ROOF_DEATH := 1.5
const T_FINISH := 9.0
const T_EAST := 11.0
const T_WEST := 13.6
const T_STOP := 16.2
const T_BRICKS := 20.0
const T_LEAVE := 22.0
const T_LEAVE_END := 23.2

var run: Node2D
var _t := 0.0
var _done := {}
var _roof_minion: Node = null


func _ready() -> void:
	run = preload("res://scenes/run/run.tscn").instantiate()
	add_child(run)
	await get_tree().process_frame
	var sp = run.minions
	sp.enabled = true
	sp._spawning["max_minions_alive"] = 0.0
	sp._spawn_clock = -INF
	sp.rng.seed = 531
	sp.corpses.rng.seed = 531
	run.kaiju_boss.enabled = false
	var car: CharacterBody2D = run.car
	car.use_keyboard = false
	car.detect_tricks = false
	car.model.set_position(Vector2(-50, -57))
	car.model.rotation = 0.0
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = run.elevation.ground_height
	run.camera_follow.dynamic = false
	run.set_zoom(9.0)
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()
	run.weapons.upgrade("wiper")
	run.weapons.bricks.set_tier(1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var c: Vector2 = car.model.get_position()
	var n := 0
	var tries := 0
	while n < 16 and tries < 300:
		tries += 1
		var p := c + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(7.0, 13.0)
		if p.y < -62.0:
			continue  # not onto the rooftop's side by chance
		if sp.is_free_spot(p):
			sp.spawn_minion_at(p)
			n += 1
	_roof_minion = sp.spawn_minion_at(Vector2(-50, -73))
	_roof_minion.move_speed = 0.0


func _physics_process(delta: float) -> void:
	if run == null or run.car == null:
		return
	_t += delta
	var car: CharacterBody2D = run.car
	run.state.health = run.state.max_health
	var heading := 0.0
	var drive := false
	if _t >= T_EAST and _t < T_WEST:
		drive = true
	elif _t >= T_WEST and _t < T_STOP:
		drive = true
		heading = PI
	elif _t >= T_LEAVE and _t < T_LEAVE_END:
		drive = true
	car.model.rotation = heading
	car.scripted_input = [drive, false, 0.0]
	if not drive and _t > T_EAST:
		car.model.set_velocity(car.model.get_velocity() * 0.85)
	if _t >= T_ROOF_DEATH and not _done.has("roof"):
		_done["roof"] = true
		if is_instance_valid(_roof_minion) and not _roof_minion.is_dead():
			_roof_minion.take_damage(100.0, "gun")
	if _t >= T_FINISH and not _done.has("finish"):
		_done["finish"] = true
		for m in run.minions.minions.duplicate():
			if is_instance_valid(m) and not m.is_dead():
				m.take_damage(100.0, "gun")
	if _t >= T_BRICKS and not _done.has("bricks"):
		_done["bricks"] = true
		run.weapons.bricks.send_wave(car.model.get_position())
