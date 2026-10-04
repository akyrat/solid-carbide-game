extends SceneTree
## Runs a scene for a set number of frames, then saves a screenshot of the
## main viewport as a PNG and quits.
##
## Usage (normally called through tools/screenshot.sh or tools/screenshot.ps1):
##   godot --path game -s res://tools/screenshot.gd -- --scene=res://path/to/scene.tscn --frames=60 --out=C:/abs/path/shot.png
##
## Exit codes: 0 = PNG written, 1 = bad arguments, 2 = scene failed to load,
## 3 = no image (e.g. run with --headless, which has no renderer), 4 = save failed.

var _frames_left := 0
var _out_path := ""


func _initialize() -> void:
	var args := _parse_args(OS.get_cmdline_user_args())
	var scene_path: String = args.get("scene", "")
	_out_path = args.get("out", "")
	_frames_left = int(args.get("frames", "60"))

	if scene_path == "" or _out_path == "" or _frames_left < 1:
		printerr("screenshot.gd: need --scene=<res://...tscn> --out=<file.png> [--frames=N>=1]")
		quit(1)
		return

	var packed := load(scene_path) as PackedScene
	if packed == null:
		printerr("screenshot.gd: could not load scene '%s'" % scene_path)
		quit(2)
		return

	root.add_child(packed.instantiate())
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	_frames_left -= 1
	if _frames_left > 0:
		return
	process_frame.disconnect(_on_process_frame)
	# Wait for the frame to finish drawing so the texture holds this frame.
	await RenderingServer.frame_post_draw
	_save()


func _save() -> void:
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		printerr("screenshot.gd: viewport gave no image (do not use --headless for screenshots)")
		quit(3)
		return

	var dir := _out_path.get_base_dir()
	if dir != "" and not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)

	var err := image.save_png(_out_path)
	if err != OK:
		printerr("screenshot.gd: failed to save '%s' (error %d)" % [_out_path, err])
		quit(4)
		return

	print("screenshot.gd: saved %dx%d PNG to %s" % [image.get_width(), image.get_height(), _out_path])
	quit(0)


func _parse_args(user_args: PackedStringArray) -> Dictionary:
	var result := {}
	for arg in user_args:
		if arg.begins_with("--") and arg.contains("="):
			var key := arg.substr(2, arg.find("=") - 2)
			result[key] = arg.substr(arg.find("=") + 1)
	return result
