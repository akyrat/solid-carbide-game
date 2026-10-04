extends GutTest
## Checks every PixelLab-generated image in res://art/: each PNG with a
## record JSON next to it (written by tools/pixellab_client.py)
## must load as a texture in Godot with the size its record gives.
## The client script's own tests are Python: see game/README.md.

const ART_ROOT := "res://art"


func _find_records(dir_path: String, out: Array) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_find_records(dir_path.path_join(sub), out)
	for file in dir.get_files():
		if file.get_extension() == "json":
			var png := dir_path.path_join(file.get_basename() + ".png")
			if FileAccess.file_exists(png):
				out.append(dir_path.path_join(file))


func _read_json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func test_generated_pngs_load_with_recorded_size() -> void:
	var records: Array = []
	_find_records(ART_ROOT, records)
	if records.is_empty():
		pass_test("No PixelLab-generated images yet.")
		return
	for record_path in records:
		var record: Variant = _read_json(record_path)
		if not (record is Dictionary and record.has("endpoint") and record.has("image")):
			continue  # not a PixelLab record
		var png_path: String = record_path.get_base_dir().path_join(record["file"])
		var tex: Texture2D = load(png_path)
		assert_not_null(tex, "Godot loads %s" % png_path)
		if tex != null:
			assert_eq(tex.get_width(), int(record["image"]["width"]), "width of %s" % png_path)
			assert_eq(tex.get_height(), int(record["image"]["height"]), "height of %s" % png_path)
