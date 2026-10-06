extends SceneTree
## Writes the placeholder car sprite sheets (task T-013) and their JSON layout/record
## files. Drawn by tools/car_sheet_generator.gd; no PixelLab.
## Run from the repo root with the wrapper:
##   bash game/tools/generate_car_sheets.sh
## or directly:
##   <GODOT_BIN> --headless --path game --script res://tools/generate_car_sheets.gd
## Output (overwritten on every run, byte-identical each time):
##   res://art/placeholders/car/car_flat.png + car_flat.json
##   res://art/placeholders/car/car_iso.png  + car_iso.json

const Generator := preload("res://tools/car_sheet_generator.gd")
const OUT_DIR := "res://art/placeholders/car"
const COMMAND := "bash game/tools/generate_car_sheets.sh (or powershell -ExecutionPolicy Bypass -File game/tools/generate_car_sheets.ps1)"


func _init() -> void:
	var code := 0
	var err := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	if err != OK:
		push_error("Could not create %s (error %d)" % [OUT_DIR, err])
		quit(1)
		return
	for view in Generator.VIEWS:
		var png_name := "car_%s.png" % view
		var png_path := OUT_DIR.path_join(png_name)
		var json_path := OUT_DIR.path_join("car_%s.json" % view)
		err = Generator.build_sheet(view).save_png(png_path)
		if err != OK:
			push_error("Could not write %s (error %d)" % [png_path, err])
			code = 1
			continue
		var file := FileAccess.open(json_path, FileAccess.WRITE)
		if file == null:
			push_error("Could not write %s" % json_path)
			code = 1
			continue
		file.store_string(Generator.describe_json(view, png_name, COMMAND))
		file.close()
		print("Wrote ", png_path, " and ", json_path)
	quit(code)
