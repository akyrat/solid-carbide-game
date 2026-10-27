extends Node
## GIF fixture (task T-278): drifts ending, in the drift prototype or (in_run)
## in a run started from the main menu, with a scripted drive. Three drifts:
## one with the side slip off (how a drift ended before T-278), one with the
## slip left alone, and one with the slip caught by a touch of counter-steer.
## A caption (a recording aid, not game text) names each part and shows the
## slip's size. After the last part the scene quits.
##   "$GODOT_BIN" --path game --fixed-fps 50 --write-movie C:/abs/dir/f.png res://tests/fixtures/drift_exit_slip_gif.tscn
## then: python game/tools/make_turn_gif.py C:/abs/dir out.gif --glob "f*.png" --every 2 --size 640 420 --scale 1 --ms 40

@export var in_run := false
## Run only: where the car starts (flat units) and its heading.
@export var start_units := Vector2(-81, -50)
@export var start_rotation := -PI / 2.0
## Camera zoom (orthographic size); 0 keeps the scene's.
@export var zoom := 0.0

## [physics steps, W, steer, slip on, caption]. A = +1, D = -1.
const PARTS := [
	[30, true, 0.0, true, "W"],
	[60, true, 1.0, false, "Slip OFF (before T-278): W + A drift"],
	[45, true, 0.0, false, "Slip OFF: A let go, the turn stops dead"],
	[60, true, -1.0, true, "Slip ON: W + D drift"],
	[45, true, 0.0, true, "Slip ON: D let go, left alone"],
	[60, true, 1.0, true, "Slip ON: W + A drift"],
	[6, true, -1.0, true, "Slip ON: A let go, caught with a touch of D"],
	[45, true, 0.0, true, "Slip ON: A let go, caught with a touch of D"],
]

var car: CharacterBody2D
var _part := -1
var _left := 0
var _caption: Label
var _slip_default := 0.35


func _ready() -> void:
	# For trying start spots: DRIFT_SLIP_START="x,y,heading in radians".
	var env := OS.get_environment("DRIFT_SLIP_START").split(",")
	if env.size() == 3:
		start_units = Vector2(float(env[0]), float(env[1]))
		start_rotation = float(env[2])
	if in_run:
		var game: Node = preload("res://scenes/game/game.tscn").instantiate()
		add_child(game)
		game.menu.start_button.pressed.emit()
		await get_tree().process_frame
		var run: Node2D = game.run
		car = run.car
		car.use_keyboard = false
		car.detect_tricks = true
		car.model.set_position(start_units)
		car.model.rotation = start_rotation
		car.model.set_velocity(Vector2.ZERO)
		car._sync_from_model()
		car.ground = run.elevation.ground_height
		if zoom > 0.0:
			run.camera_follow.dynamic = false
			run.set_zoom(zoom)
		run.sync_view()
		run.car_sprite.reset_physics_interpolation()
		run.camera.reset_physics_interpolation()
		run.state.health = run.state.max_health
		set_process(true)
		_keep_alive = run
	else:
		var p: Node2D = preload("res://scenes/drift_prototype/drift_prototype.tscn").instantiate()
		add_child(p)
		p.set_view("iso")
		p.panel.visible = false
		if zoom > 0.0:
			p.camera_follow.dynamic = false
			p.set_zoom(zoom)
		car = p.car
		car.use_keyboard = false
	_slip_default = float(car.tuning.exit_slip_turn)
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	_caption = Label.new()
	_caption.position = Vector2(262, 100)
	_caption.add_theme_font_size_override("font_size", 18)
	_caption.add_theme_color_override("font_color", Color(1, 1, 1))
	_caption.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_caption.add_theme_constant_override("outline_size", 6)
	layer.add_child(_caption)
	_next_part()
	car.stepped.connect(_on_stepped)
	car.hit_obstacle.connect(func(_c, _i, _n, speed: float) -> void:
		print("drift_exit_slip_gif_demo: hit an obstacle in part %d at %.1f units/s" % [_part, speed]))


var _keep_alive: Node = null


func _process(_delta: float) -> void:
	if _keep_alive != null and _keep_alive.state != null:
		_keep_alive.state.health = _keep_alive.state.max_health
	if _caption != null and car != null and _part >= 0 and _part < PARTS.size():
		_caption.text = "%s\nside slip %.0f deg/s   drift angle %.0f deg" % [
			PARTS[_part][4], absf(car.model.exit_slip), absf(car.model.drift_angle_deg())]


func _next_part() -> void:
	_part += 1
	if _part >= PARTS.size():
		get_tree().quit()
		return
	var p: Array = PARTS[_part]
	_left = p[0]
	car.tuning.exit_slip_turn = _slip_default if p[3] else 0.0
	car.scripted_input = [p[1], false, p[2]]
	print("drift_exit_slip_gif_demo: part %d '%s' at %s, heading %.1f deg" % [
		_part, p[4], car.model.get_position(), rad_to_deg(car.model.rotation)])


func _on_stepped() -> void:
	_left -= 1
	if _left <= 0:
		_next_part()
