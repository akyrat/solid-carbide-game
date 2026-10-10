extends Node2D
## Screenshot fixture (task T-035): a meteor challenge with its green arrow,
## created during the run next to the preset challenge-1 with its blue arrow.
## bash game/tools/screenshot.sh res://tests/fixtures/meteor_challenge_demo.tscn screenshots/meteor_challenge.png 10

const MapScene := preload("res://scenes/level/mvp_map.tscn")

@export var iso := false

var map: Node2D
var meteor_id := ""


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.03, 0.03, 0.06))
	map = MapScene.instantiate()
	add_child(map)
	map.set_view("iso" if iso else "flat")
	# The same design as challenge-1 (around -18, -18), in the gravel beside it.
	var centre := Vector2(-6.0, -6.0)
	if map.can_place_meteor_challenge("single-boulder/arrow-1", centre, 0.0):
		meteor_id = map.add_meteor_challenge("single-boulder/arrow-1", centre, 0.0)
	var camera := Camera2D.new()
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	add_child(camera)
	camera.make_current()
	var focus: Vector2 = Vector2(-12.0, -12.0) * map.PX_PER_UNIT
	var size: Vector2 = Vector2(26.0, 26.0) * map.PX_PER_UNIT
	if iso:
		focus = map.ISO_TRANSFORM * focus
		size = Vector2(size.x * 2.0, size.y)
	camera.position = focus
	var win := get_viewport().get_visible_rect().size
	var z := minf(win.x / size.x, win.y / size.y)
	camera.zoom = Vector2(z, z)
