class_name WebAudioLog
extends RefCounted
## One console line per sound start in the browser build (T-476), so a scripted browser run
## (game/tools/web_audio_check.mjs) can tell that the music and the engine really started.
## It prints on the web only; on the desktop it does nothing.

const PREFIX := "[audio] "


## The line printed for `what`.
static func line(what: String) -> String:
	return PREFIX + what


static func say(what: String) -> void:
	if OS.has_feature("web"):
		print(line(what))
