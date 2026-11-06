extends Control
## Task T-542: a scene for the screenshot tool (game/docs/setup/screenshots.md) that shows the rail piece
## in the level creator and the same level in a run. The mode comes from the environment variable
## T542_MODE: "creator" (rails placed, one selected), "laying" (the Rail piece picked, a rail being
## dragged), "run" (the level played, the car grinding the jump pair's first rail).
## The test level is written to the user folder, never to game/data/levels/.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const RunScene := preload("res://scenes/run/run.tscn")
const ISO := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
const LEVEL_PATH := "user://t542_shots_level.json"

var _editor: LevelCreatorEditor


func _ready() -> void:
	var mode := OS.get_environment("T542_MODE")
	if mode == "" or mode == "creator" or mode == "laying":
		_creator(mode == "laying")
	elif mode == "run":
		_run()


## The level: a few buildings and rooftops for context, and rails laid through the editor's own calls.
func _build_level(e: LevelCreatorEditor) -> Dictionary:
	var d := e.document
	d.place("skyscraper-1", Vector2(21, 21))
	d.place("skyscraper-3", Vector2(61, -39))
	d.place("rooftop-3", Vector2(-29, -59), "", false, Vector2(16, 16))
	d.place("rooftop-6", Vector2(-13, -59), "", false, Vector2(16, 16))
	d.place("short-0", Vector2(-59, 21))
	e._rebuild_map()
	var out := {}
	e.panel.pick("rail")
	out.climb = e.lay_rail(Vector2(-40, -52), Vector2(-22, -52))  # auto: street to the rooftop
	out.roof = e.lay_rail(Vector2(-24, -58), Vector2(-4, -50))  # auto: from the 3 rooftop onto the 6 one
	e.height_pick()  # 1
	out.pair_a = e.lay_rail(Vector2(5, -6), Vector2(5, -50))
	out.pair_b = e.lay_rail(Vector2(8.5, -14), Vector2(8.5, -58))
	e.height_pick()  # 3.1
	e.height_pick()  # 6.1
	out.high = e.lay_rail(Vector2(30, 30), Vector2(48, 12))
	e.panel.pick("")
	return out


func _creator(laying: bool) -> void:
	_editor = EDITOR_SCENE.instantiate()
	_editor.open_new()
	_editor.level_data["spawn"] = {"x": 111.0, "y": 111.0, "heading": 270}
	_editor.levels_dir = "user://t542_shots_levels"
	add_child(_editor)
	var pieces := _build_level(_editor)
	await get_tree().process_frame
	await get_tree().process_frame
	_editor.zoom = 0.5
	_editor.view_origin = _editor.map_view.size / 2.0 - ISO * (Vector2(6, -30) * 16.0) * _editor.zoom
	_editor._apply_view()
	if laying:
		_editor.panel.pick("rail")
		_editor.begin_rail_drag(_editor.units_to_screen(Vector2(14, -42)) - Vector2(0, 16.0 * _editor.zoom))
		_editor.update_rail_drag(_editor.units_to_screen(Vector2(34, -18)) - Vector2(0, 16.0 * _editor.zoom))
	else:
		_editor.selected = {"kind": "rail", "item": pieces.pair_b.item}
		_editor._update_pose_controls()
	_editor._overlay.queue_redraw()


func _run() -> void:
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.open_new()
	e.level_data["spawn"] = {"x": 1.0, "y": 1.0, "heading": 270}
	add_child(e)
	_build_level(e)
	LevelStore.save_level(LEVEL_PATH, e.document.file_data("T-542 shots"))
	e.queue_free()
	var run: Node2D = RunScene.instantiate()
	run.layout_path = LEVEL_PATH
	add_child(run)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.car.use_keyboard = false
	await get_tree().process_frame
	var rail: Dictionary = run.car.grind.rails[2]  # the jump pair's first rail (laid third)
	run.car.model.set_position(Vector2(rail.a.x, rail.a.y - 8.0))
	run.car.model.rotation = -PI / 2.0
	run.car.model.set_velocity(Vector2(0, -12))
	run.car.height_model.height = 1.5
	run.car.height_model.leave_rail(0.0)
