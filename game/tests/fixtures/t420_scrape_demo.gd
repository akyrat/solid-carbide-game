extends Node
## Screenshot fixture (task T-420): two long barriers paired as a thread-the-needle gate (a 3-unit
## gap at y -40). The car scrapes along the west barrier's east face and crosses the gap line while
## still touching it: no THREAD THE NEEDLE! is paid. With T420_MODE=clean the car drives the middle
## of the gap without touching: the pass pays and the popup shows.
## Saves three PNGs into the folder named by the T420_OUT environment variable (absolute path):
## <mode>_1_before.png, <mode>_2_crossing.png, <mode>_3_after.png.
## bash game/tools/screenshot.sh res://tests/fixtures/t420_scrape_demo.tscn out.png 300

const RunScene := preload("res://scenes/run/run.tscn")

const STEP_LIMIT := 400

var run: Node2D
var mode := "scrape"
var out_dir := ""
var _steps := 0
var _frame := 0
var _crossed_step := -1
var _shots := 0
var _paid := 0
var _prev_y := 0.0


func _layout() -> Dictionary:
	var d := LevelDocument.new_level_data("T-420 barriers")
	d["props"] = [
		{"id": "prop-1", "asset": "prop-barrier", "rotation": "north", "x": -2.5, "y": -60.0, "w": 1.0, "h": 40.0},
		{"id": "prop-2", "asset": "prop-barrier", "rotation": "north", "x": 1.5, "y": -60.0, "w": 1.0, "h": 40.0},
	]
	d["pairs"] = [{"id": "pair-1", "a": "prop-1", "b": "prop-2"}]
	return d


func _ready() -> void:
	if OS.get_environment("T420_MODE") != "":
		mode = OS.get_environment("T420_MODE")
	out_dir = OS.get_environment("T420_OUT")
	var path := "user://t420_demo_level.json"
	LevelStore.save_level(path, _layout())
	run = RunScene.instantiate()
	run.layout_path = path
	add_child(run)
	run.minions.enabled = false
	run.minions.clear()
	run.kaiju_boss.enabled = false
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	run.camera_follow.dynamic = false
	run.set_zoom(7.0)
	run.state.combo_trick.connect(func(id, added, _m):
		_paid += 1
		print("t420_scrape_demo: PAID ", id, " +", added))
	var car = run.car
	car.tuning.wall_bounce = 0.0
	var x := -0.75 if mode == "scrape" else 0.0
	car.model.set_position(Vector2(x, -2.0))
	car.model.rotation = -PI / 2.0 - (0.01 if mode == "scrape" else 0.0)
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	run.needle.last_position = null
	car.scripted_input = [true, false, 0.0]
	run.car.stepped.connect(_on_stepped)
	car.input_enabled = true
	car.set_physics_process(false)  # stepped by hand in _process, a few steps a frame, so the demo is short
	run.sync_view(true)
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()
	print("t420_scrape_demo: mode ", mode)


func _on_stepped() -> void:
	_steps += 1
	var p: Vector2 = run.car.model.get_position()
	if _prev_y > -40.0 and p.y <= -40.0 and _crossed_step < 0:
		_crossed_step = _steps
		print("t420_scrape_demo: crossed the gap line at x ", p.x, ", held contacts ", run.car.held_contacts().size())
	_prev_y = p.y
	if _crossed_step >= 0 and _steps == _crossed_step + 40:
		print("t420_scrape_demo: after crossing, passes paid: ", _paid)


func _process(_delta: float) -> void:
	if run == null or out_dir == "":
		return
	if _steps < STEP_LIMIT:
		for i in 3:
			run.car.physics_step()
	run.state.health = run.state.max_health
	_frame += 1
	var p: Vector2 = run.car.model.get_position()
	if _shots == 0 and p.y < -28.0:
		_save("1_before")
	elif _shots == 1 and _crossed_step >= 0 and _steps >= _crossed_step:
		_save("2_crossing")
	elif _shots == 2 and _crossed_step >= 0 and _steps >= _crossed_step + 30:
		_save("3_after")


func _save(label: String) -> void:
	_shots += 1
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("%s_%s.png" % [mode, label]))
