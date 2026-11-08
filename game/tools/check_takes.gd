extends SceneTree
## T-604: replays every tutorial take (data/tutorial_takes/<trick>.json) on the practice playground
## as it is now and prints, per trick, whether it does its trick: the successes counted, whether the
## slide's goal is done, and how far the replay strayed from the take's checkpoints. Changes nothing.
##
## Run, from the repo root:
##   "<godot>" --headless --path game -s res://tools/check_takes.gd -- [--tricks=alt_drift,grind]
## Exit code 0 when every take does its trick, 1 otherwise.

const SessionScene := preload("res://scenes/run/practice_session.tscn")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var tricks: Array = PracticeSession.TRICKS.duplicate()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tricks="):
			tricks = Array(a.trim_prefix("--tricks=").split(","))
	var code := 0
	for trick in tricks:
		var r := check(String(trick), root)
		print("%s: %s" % [trick, r])
		if not r.get("did_trick", false):
			code = 1
	quit(code)


## Replays `trick`'s saved take on a fresh practice session under `parent`; returns
## {has_take, seconds, successes, completed, did_trick, drift}.
static func check(trick: String, parent: Node, dir := PracticeTake.TAKES_DIR) -> Dictionary:
	var session: PracticeSession = SessionScene.instantiate()
	parent.add_child(session)
	session.takes_dir = dir
	session.setup(trick)
	session.start()
	session.set_focused(true)
	var out := {"has_take": false}
	var t := session.saved_take()
	if t != null and session.play_take(t):
		out.has_take = true
		var guard := 0
		while session.is_replaying() and guard < 20000:
			session.car.physics_step()
			guard += 1
		out.seconds = snappedf(t.seconds(), 0.01)
		out.successes = session.successes
		out.completed = session.is_completed()
		out.did_trick = session.is_completed() if trick == "drift" else session.successes >= 1
		out.drift = snappedf(session.replay_drift, 0.01)
	session.free()
	return out
