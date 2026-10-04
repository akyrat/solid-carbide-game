extends SceneTree
## Checks that every audio file (.wav, .ogg, .mp3) under a folder was imported by
## Godot and loads as a playable AudioStream with a length above zero.
##
## Usage (normally called through tools/check_audio.sh or tools/check_audio.ps1,
## which run the import first):
##   godot --headless --path game -s res://tools/check_audio.gd -- --dir=res://audio/sfx
##
## Prints one OK/FAIL line per file. Exit codes: 0 = all files load,
## 1 = bad arguments or no audio files found, 2 = at least one file failed.

const AUDIO_EXTENSIONS := ["wav", "ogg", "mp3"]


func _initialize() -> void:
	var dir_path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--dir="):
			dir_path = arg.substr(6)
	if dir_path == "":
		printerr("check_audio.gd: need --dir=<res://folder>")
		quit(1)
		return
	var files := find_audio_files(dir_path)
	if files.is_empty():
		printerr("check_audio.gd: no audio files under '%s'" % dir_path)
		quit(1)
		return
	var failed := 0
	for path in files:
		var problem := check_file(path)
		if problem == "":
			print("OK    %s" % path)
		else:
			print("FAIL  %s: %s" % [path, problem])
			failed += 1
	print("%d of %d audio files load correctly" % [files.size() - failed, files.size()])
	quit(2 if failed > 0 else 0)


## Every audio file under dir_path, recursively, sorted.
static func find_audio_files(dir_path: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for sub in dir.get_directories():
		out.append_array(find_audio_files(dir_path.path_join(sub)))
	for f in dir.get_files():
		if f.get_extension().to_lower() in AUDIO_EXTENSIONS:
			out.append(dir_path.path_join(f))
	out.sort()
	return out


## Empty string if the file imported and loads as a non-empty AudioStream, else the reason.
static func check_file(path: String) -> String:
	if not FileAccess.file_exists(path + ".import"):
		return "not imported (no .import file)"
	if not ResourceLoader.exists(path):
		return "import failed (no imported resource)"
	var stream := load(path) as AudioStream
	if stream == null:
		return "does not load as an AudioStream"
	if stream.get_length() <= 0.0:
		return "length is zero"
	return ""
