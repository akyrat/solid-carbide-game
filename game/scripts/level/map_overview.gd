extends Node2D
## Shows the whole MVP map at once, for the board's review and for screenshots
## (task T-019). Not part of a run: the run puts the map scene under its own
## camera that follows the car.

const MapScene := preload("res://scenes/level/mvp_map.tscn")

## Draw the map in the 2:1 isometric projection instead of flat top-down.
@export var iso := false
## Empty space around the map, as a share of the window.
@export var margin := 0.04

var map: Node2D
var camera: Camera2D


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.03, 0.03, 0.06))
	map = MapScene.instantiate()
	add_child(map)
	map.set_view("iso" if iso else "flat")
	camera = Camera2D.new()
	camera.name = "Camera"
	add_child(camera)
	camera.make_current()
	get_viewport().size_changed.connect(fit_camera)
	fit_camera()


## Zooms the camera so the whole map fits the window.
func fit_camera() -> void:
	var half: float = map.layout.map.width / 2.0 * map.PX_PER_UNIT
	var size := Vector2(2 * half, 2 * half)
	if iso:
		size = Vector2(4 * half, 2 * half)  # screen = (x - y, (x + y) / 2)
	var win := get_viewport().get_visible_rect().size * (1.0 - 2.0 * margin)
	var z := minf(win.x / size.x, win.y / size.y)
	camera.position = Vector2.ZERO
	camera.zoom = Vector2(z, z)
