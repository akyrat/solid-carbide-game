extends Node
## Screenshot and GIF fixture for T-478 (Drifting, Content, "The Jump clears obstacles"), in the real
## run (game.tscn, the Kaiju City map): Jump at tier 1, three scenes one after the other with the
## real map's obstacles: a hop over a boulder, a hop over a barrier, and a hop that lands on top of a
## boulder and drives off its far edge. Frame N is physics step N; with `record_dir` set (relative to
## the repo root) every `record_every`th frame is saved there.

@export var record_dir := ""
@export var record_every := 2
@export var record_frames := 0

var game: Node
var car: CharacterBody2D
var _step := 0
var _scene := 0
var _t := 0
var _pressed := false
var _tp := Vector2.ZERO
var _half := 1.5
var _scenes: Array = []


func _ready() -> void:
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.start_run()
	game.run.state.grant_power_up("jump")
	game.run.minions.enabled = false
	game.run.kaiju_boss.enabled = false
	car = game.run.car
	car.use_keyboard = false
	car.set_physics_process(false)
	var map = game.run.map
	var boulder = map.boulder_bodies[1]
	var barrier = null
	for b in map.prop_bodies:
		if b.name == "Prop_prop_47":
			barrier = b
	# [body, half width along x, start distance, start speed, press lead (nose to near edge), W held]
	_scenes = [[boulder, 1.5, 30.0, 0.0, 0.0, true], [barrier, 0.5, 30.0, 0.0, 0.0, true],
		[boulder, 1.5, 3.95, 4.0, 99.0, false]]
	_begin()
	if record_dir != "":
		if record_dir.is_relative_path():
			record_dir = ProjectSettings.globalize_path("res://").path_join("..").path_join(record_dir).simplify_path()
		DirAccess.make_dir_recursive_absolute(record_dir)


func _begin() -> void:
	var s: Array = _scenes[_scene]
	var cs: CollisionShape2D = s[0].get_child(0)
	_tp = cs.global_position / 16.0
	_half = s[1] if cs.shape is CircleShape2D else (cs.shape as RectangleShape2D).size.x / 32.0
	var at: Vector2 = _tp + Vector2(-float(s[2]), 0.0)
	car.model.set_position(at)
	car.model.rotation = 0.0
	car.model.set_velocity(Vector2(float(s[3]), 0.0))
	car.height_model.reset(at)
	car._sync_from_model()
	_pressed = false
	_t = 0


func _process(_delta: float) -> void:
	if car == null or not is_instance_valid(car) or _scene >= _scenes.size():
		return
	var s: Array = _scenes[_scene]
	if not _pressed and car.model.x + 1.5 >= _tp.x - _half - float(s[4]) - (0.0 if float(s[3]) == 0.0 else 0.0):
		car.press_jump()
		_pressed = true
	car.scripted_input = [bool(s[5]) or (_t > 70), false, 0.0]
	car.model.rotation = 0.0
	car.physics_step()
	_step += 1
	_t += 1
	if car.model.x > _tp.x + _half + 5.0 and not car.airborne or _t > 260:
		_scene += 1
		if _scene < _scenes.size():
			_begin()
	if record_dir != "" and _step <= record_frames and _step % record_every == 0:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(record_dir.path_join("frame_%04d.png" % _step))
