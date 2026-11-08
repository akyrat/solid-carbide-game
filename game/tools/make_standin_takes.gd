extends SceneTree
## T-574 tweak 10, step 2: records the stand-in demo takes (data/tutorial_takes/<trick>.json) by
## driving the practice tests' scripted routes (test_practice_session.gd's AIR_ROUTE and GRIND_ROUTE,
## the alt drift's legs, a W + A drift) through the practice session's own recorder (PracticeTake),
## so each is a real take that replays on the real car. Each is marked as a stand-in in its
## "_comment"; the board's own recordings (F6, F7 in the slides) replace them.
##
## Run, from the repo root:
##   "<godot>" --headless --path game -s res://tools/make_standin_takes.gd -- [--tricks=alt_drift,grind] [--dir=res://...] [--force]
## A take that is already there and is not a stand-in (no stand-in comment: the board's own) is
## left alone unless --force. tests/unit/run/test_standin_takes.gd checks that each one does its trick.

const Recorder := preload("res://tools/standin_recorder.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var tricks := ["drift", "alt_drift", "air_spin", "grind"]
	var dir := PracticeTake.TAKES_DIR
	var force := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tricks="):
			tricks = Array(a.trim_prefix("--tricks=").split(","))
		elif a.begins_with("--dir="):
			dir = a.trim_prefix("--dir=")
		elif a == "--force":
			force = true
	var code := 0
	for t in tricks:
		var existing := PracticeTake.load_take(t, dir)
		if existing != null and not Recorder.is_standin(existing) and not force:
			print("%s: kept (a take that is not a stand-in is there; --force to replace it)" % t)
			continue
		var r := Recorder.new().record(t, dir, root)
		print("%s: %s" % [t, r])
		if not r.get("saved", false):
			code = 1
	quit(code)
