extends Node
## Screenshot fixture (task T-592): a run on a level with an in-order needle route of three boulder
## pairs along a road. Saved into `out_dir` (the T592_OUT environment variable, an absolute path):
## run_before.png as the car comes up to the first gap (its line bright, the other two faint), and
## run_after.png once it has threaded it (the second gap bright now, the first faint).
## T592_OUT="<abs>/art-archive/T-592/screenshots" bash game/tools/screenshot.sh res://tests/fixtures/t592_routes_run_demo.tscn art-archive/T-592/screenshots/run_end.png 700

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const RunScene := preload("res://scenes/run/run.tscn")

const START := Vector2(-0.5, 2)
@export var zoom := 20.0

var run: Node2D
var out_dir := ""
var _before := false
var _after := false
var _paid_frame := -1
var _frame := 0


func _place(editor: LevelCreatorEditor, asset: String, at: Vector2) -> Dictionary:
	editor.panel.pick(asset)
	var p := editor.place_asset(asset, at)
	editor.panel.pick("")
	return p


func _ready() -> void:
	out_dir = OS.get_environment("T592_OUT")
	var editor: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	editor.open_new()
	add_child(editor)
	editor.panel.pick("road")
	editor.paint_road([Vector2(-1, -70), Vector2(-1, 20)])
	editor.panel.pick("")
	var route := ""
	for i in 3:
		var y := -21.0 - 12.0 * i
		var a := _place(editor, "boulder-a", Vector2(-5, y))
		var b := _place(editor, "boulder-b", Vector2(3, y))
		var p := editor.document.make_pair(a, b)
		route = str(editor.document.add_to_route(route, str(p.id)).id)
	var path := "user://t592_routes_level.json"
	LevelStore.save_level(path, editor.document.file_data("T-592 needle routes"))
	var ground: Dictionary = editor.document.ground_layout()
	remove_child(editor)
	editor.free()
	run = RunScene.instantiate()
	run.layout_path = path
	add_child(run)
	run.map.ground_layout = ground
	run.map.ground_tiles.queue_redraw()
	run.minions.enabled = false
	run.minions.clear()
	run.kaiju_boss.enabled = false
	run.car.use_keyboard = false
	run.car.detect_tricks = false
	run.camera_follow.dynamic = false
	run.set_zoom(zoom)
	var car = run.car
	run.needle.threaded.connect(func(id):
		print("t592_routes_run_demo: paid ", id, ", active now ", run.needle.routes.active_of("route-1"))
		if _paid_frame < 0:
			car.scripted_input = [false, true, 0.0]  # stop, so the next gap stays in view
			car.model.set_velocity(Vector2.ZERO)
			_paid_frame = _frame)
	car.model.set_position(START)
	car.model.rotation = -PI / 2.0
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	run.needle.last_position = null
	car.scripted_input = [true, false, 0.0]
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()


func _save(name: String) -> void:
	if out_dir != "":
		get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
		print("t592_routes_run_demo: saved ", name)


func _process(_delta: float) -> void:
	if run == null or run.state == null:
		return
	_frame += 1
	run.state.health = run.state.max_health
	if not _before and run.car.model.get_position().y < -12.0:
		_before = true
		_save("run_before")
	if _paid_frame >= 0 and not _after and _frame > _paid_frame + 100:
		_after = true
		_save("run_after")
