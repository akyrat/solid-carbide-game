extends Node
## GIF fixture (task T-398): a level built in the creator's editor (a road, a sidewalk 8 units wide
## beside it with its curbs added by themselves, a second road beyond, a meteor crater on it) saved
## and played as a run. The car is driven by script (W held) east: off the road, up over the curb
## onto the sidewalk, down over the far curb, over the crater, with no crash. Recorded with Godot's
## movie maker and tools/frames_to_gif.py:
##   "$GODOT_BIN" --path game --fixed-fps 50 --write-movie C:/abs/m/f.png res://tests/fixtures/t398_curb_drive.tscn --quit-after 160
##   python game/tools/frames_to_gif.py C:/abs/m art-archive/T-398/screenshots/curb_drive.gif --skip 3 --fps 15 --shared --colors 96

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const RunScene := preload("res://scenes/run/run.tscn")

var run: Node2D


func _ready() -> void:
	var editor: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	editor.open_new()
	editor.level_data["spawn"] = {"x": -14.0, "y": 1.0, "heading": 0}
	add_child(editor)
	editor.panel.pick("centre-line")
	editor.paint_road([Vector2(1, -40), Vector2(1, 40)])
	editor.paint_road([Vector2(13, -40), Vector2(13, 40)])
	editor.panel.pick("sidewalk")
	for x in [5, 7, 9, 11]:
		editor.paint_sidewalk([Vector2(x, -30), Vector2(x, 30)])
	editor.panel.pick("crater-1")
	editor.place_asset("crater-1", Vector2(14.1, 0.1))
	var path := "user://t398_curb_level.json"
	LevelStore.save_level(path, editor.document.file_data("T-398 curb"))
	remove_child(editor)
	editor.free()
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
	run.car.hit_obstacle.connect(func(_c, _i, _n, _s): print("t398_curb_drive: crashed"))
	var car = run.car
	car.model.set_position(Vector2(-14, 1))
	car.model.rotation = 0.0
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.scripted_input = [true, false, 0.0]
	run.sync_view()
	run.car_sprite.reset_physics_interpolation()
	run.camera.reset_physics_interpolation()


func _process(_delta: float) -> void:
	if run != null and run.state != null:
		run.state.health = run.state.max_health
	if run != null and run.car.model.get_position().x > 22.0:
		run.car.scripted_input = [false, true, 0.0]
