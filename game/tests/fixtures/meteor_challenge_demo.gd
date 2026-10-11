extends Node2D
## Screenshot fixture (task T-035): a meteor challenge with its green arrow,
## created during the run next to a preset challenge (PRESET_ID) with its blue arrow.
## bash game/tools/screenshot.sh res://tests/fixtures/meteor_challenge_demo.tscn screenshots/meteor_challenge.png 10

const MapScene := preload("res://scenes/level/mvp_map.tscn")
## The preset challenge shown: a Two Boulders on the crossing at -45, -45, at the
## gravel's corner (task T-094's 242 by 242 map).
const PRESET_ID := "challenge-8"

@export var iso := false

var map: Node2D
var meteor_id := ""


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.03, 0.03, 0.06))
	map = MapScene.instantiate()
	add_child(map)
	map.set_view("iso" if iso else "flat")
	# The same design as the preset challenge, in the gravel beside it.
	var preset: Dictionary = map.get_challenge(PRESET_ID)
	var design: String = preset.pattern + "/" + preset.arrow
	var centre := Vector2(-33.0, -33.0)
	if map.can_place_meteor_challenge(design, centre, 0.0):
		meteor_id = map.add_meteor_challenge(design, centre, 0.0)
	var camera := Camera2D.new()
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	add_child(camera)
	camera.make_current()
	var focus: Vector2 = Vector2(-39.0, -39.0) * map.PX_PER_UNIT
	var size: Vector2 = Vector2(36.0, 36.0) * map.PX_PER_UNIT
	if iso:
		focus = map.ISO_TRANSFORM * focus
		size = Vector2(size.x * 2.0, size.y)
	camera.position = focus
	var win := get_viewport().get_visible_rect().size
	var z := minf(win.x / size.x, win.y / size.y)
	camera.zoom = Vector2(z, z)
