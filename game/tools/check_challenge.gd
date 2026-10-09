extends SceneTree
## Checks that challenge drawings can be driven by the car (task T-021).
## The work is done by tools/challenge_checker.gd; this is the command line.
##
## Usage (normally through tools/check_challenge.sh or tools/check_challenge.ps1):
##   godot --headless --path game -s res://tools/check_challenge.gd -- \
##       [--save] [--set=<tuning key>=<value> ...] <drawing.json or folder> ...
##
## A folder is searched recursively for drawings (*.json, except *.driven.json).
## --save writes, next to each passing drawing, <name>.driven.json (the line the
## car drove) and <name>.driven.svg (a picture of it).
## --set overrides a handling value from scripts/driving/car_tuning.gd, for
## example --set=top_speed_multiplier=3.0.
## --attempts=<folder> writes a picture of the furthest attempt for each failing
## drawing into that folder (<pattern>-<name>.attempt.svg). Keep it outside
## docs/ and game/, for example screenshots/ at the repo root.
##
## Prints one PASS or FAIL line per drawing. Exit codes: 0 = all pass,
## 1 = at least one fails, 2 = bad arguments or a drawing could not be read.

const Checker := preload("res://tools/challenge_checker.gd")
const CarTuning := preload("res://scripts/driving/car_tuning.gd")


func _initialize() -> void:
	var save := false
	var attempt_dir := ""
	var overrides := {}
	var targets: Array[String] = []
	for arg in OS.get_cmdline_user_args():
		if arg == "--save":
			save = true
		elif arg.begins_with("--attempts="):
			attempt_dir = arg.substr(11)
		elif arg.begins_with("--set="):
			var kv := arg.substr(6).split("=")
			if kv.size() != 2 or not _is_tuning_key(kv[0]) or not kv[1].is_valid_float():
				printerr("check_challenge.gd: bad --set '%s' (want --set=<tuning key>=<number>)" % arg)
				quit(2)
				return
			overrides[kv[0]] = kv[1].to_float()
		elif arg.begins_with("--"):
			printerr("check_challenge.gd: unknown option '%s'" % arg)
			quit(2)
			return
		else:
			targets.append(arg)
	if targets.is_empty():
		printerr("check_challenge.gd: give at least one drawing (.json) or folder")
		quit(2)
		return
	var files: Array[String] = []
	for t in targets:
		if DirAccess.dir_exists_absolute(t):
			files.append_array(find_drawings(t))
		elif FileAccess.file_exists(t):
			files.append(t)
		else:
			printerr("check_challenge.gd: not found: %s" % t)
			quit(2)
			return
	if files.is_empty():
		printerr("check_challenge.gd: no drawings found")
		quit(2)
		return

	var tuning_line := PackedStringArray()
	var tuning = CarTuning.new()
	for key in overrides:
		tuning.set(key, overrides[key])
	tuning_line.append("cruise %.2f" % tuning.forward_speed)
	tuning_line.append("top speed %.2f (%.2f x cruise)" % [tuning.top_speed(), tuning.top_speed_multiplier])
	tuning_line.append("turn %.1f deg/s" % tuning.turn_rate())
	print("Car handling: %s%s" % [", ".join(tuning_line), "" if overrides.is_empty() else " (overrides: %s)" % JSON.stringify(overrides)])

	var failed := 0
	for path in files:
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not (data is Dictionary):
			printerr("check_challenge.gd: %s is not a drawing (JSON object)" % path)
			quit(2)
			return
		var checker = Checker.new()
		checker.tuning_overrides = overrides
		var problem: String = checker.load_drawing(data)
		if problem != "":
			printerr("check_challenge.gd: %s: %s" % [path, problem])
			quit(2)
			return
		var label := path.get_base_dir().get_file().path_join(path.get_file())
		var result: Dictionary = checker.check()
		print(checker.summary(result, label))
		if not result.passed:
			failed += 1
			if attempt_dir != "":
				DirAccess.make_dir_recursive_absolute(attempt_dir)
				var out := attempt_dir.path_join(path.get_base_dir().get_file() + "-" + path.get_file().get_basename() + ".attempt.svg")
				_write(out, checker.driven_svg(result))
				print("      saved the furthest attempt to %s" % out)
		elif save:
			var base := path.get_basename()
			_write(base + ".driven.json", JSON.stringify(checker.driven_data(result, label), "  ", false) + "\n")
			_write(base + ".driven.svg", checker.driven_svg(result))
			print("      saved %s.driven.json and .driven.svg" % base.get_file())
	print("%d of %d drawings can be driven" % [files.size() - failed, files.size()])
	quit(1 if failed > 0 else 0)


static func _is_tuning_key(key: String) -> bool:
	for s in CarTuning.SETTINGS:
		if s.key == key:
			return true
	return false


static func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


## Every drawing under dir_path, recursively, sorted.
static func find_drawings(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for sub in dir.get_directories():
		out.append_array(find_drawings(dir_path.path_join(sub)))
	for f in dir.get_files():
		if f.get_extension().to_lower() == "json" and not f.ends_with(".driven.json"):
			out.append(dir_path.path_join(f))
	out.sort()
	return out
