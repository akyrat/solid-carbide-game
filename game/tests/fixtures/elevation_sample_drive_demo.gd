extends Node
## Test fixture for screenshots of the scripted elevation drive (task T-195,
## tools/drive_elevation_sample.gd): runs the same drive in the elevation sample
## map scene, then either stops the car after `steps` physics steps so the
## screenshot shows that moment of the drive, or (plot = true) shows the drive's
## plot of height over time instead of the map.

const Drive := preload("res://tools/drive_elevation_sample.gd")

## Physics steps of the drive before the car stops (50 per second); 0 = the whole drive.
@export var steps := 0
## Show the height-over-time plot instead of the map.
@export var plot := false
## The plot on a light background.
@export var light := false
## Camera zoom (orthographic size); 0 keeps the saved zoom.
@export var zoom := 0.0

var scene: Node2D


func _ready() -> void:
	scene = preload("res://scenes/elevation_sample/elevation_sample_map.tscn").instantiate()
	add_child(scene)
	Drive.prepare(scene)
	if zoom > 0.0:
		scene.camera_follow.set_base_size(zoom)
	# The map's buildings and boulders join the physics space on the next physics frame.
	await get_tree().physics_frame
	await get_tree().physics_frame
	var result: Dictionary = Drive.drive(scene, Drive.plan(scene.ground_height),
		steps if steps > 0 else Drive.MAX_STEPS)
	scene.sync_view()
	for line in Drive.log_lines(result):
		print(line)
	if plot:
		scene.visible = false
		var layer := CanvasLayer.new()
		add_child(layer)
		var bg := ColorRect.new()
		bg.color = Color8(240, 240, 236) if light else Color8(24, 26, 32)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		layer.add_child(bg)
		var rect := TextureRect.new()
		rect.texture = ImageTexture.create_from_image(Drive.plot_image(result, light))
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		rect.set_anchors_preset(Control.PRESET_CENTER)
		rect.position = -Vector2(Drive.PLOT_W, Drive.PLOT_H) / 2.0
		layer.add_child(rect)
		rect.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
