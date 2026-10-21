extends Node
## Screenshot and recording fixture (task T-069): a run started from the main
## menu, the car parked, the final-art kaiju walking in towards it (the boss
## switched on, minions off). Saves a PNG every REC_EVERY frames into the folder
## in the environment variable KAIJU_REC_DIR (when set), for a GIF.
## KAIJU_REC_DIR=C:/path bash game/tools/screenshot.sh res://tests/fixtures/kaiju_walk_demo.tscn out.png 150

const REC_EVERY := 4
const REC_FRAMES := 200
const START_OFFSET := Vector2(-9.0, 7.0)

var _frame := 0
var _dir := ""
var _run: Node2D


func _ready() -> void:
	var game: Node = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await get_tree().process_frame
	_run = game.run
	_run.car.use_keyboard = false
	_run.minions.enabled = false
	var car_units: Vector2 = _run.car.position / 16.0
	var k: Node = _run.kaiju_boss.appear_at(car_units + START_OFFSET)
	k.heading = (-START_OFFSET).normalized()
	_dir = OS.get_environment("KAIJU_REC_DIR")
	if _dir != "":
		DirAccess.make_dir_recursive_absolute(_dir)


func _process(_delta: float) -> void:
	_frame += 1
	if _dir != "" and _frame <= REC_FRAMES and _frame % REC_EVERY == 0:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/f_%03d.png" % [_dir, _frame / REC_EVERY])
