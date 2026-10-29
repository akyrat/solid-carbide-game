class_name RunHistory
extends RefCounted
## Every finished run's recap stats, kept on this computer (task T-363): one JSON
## file under user://, one entry per run, for the runs list screen (T-364).
## Game loop architecture, Decisions, "The runs list"; fields: game/docs/data/game-data.md.
##
## A missing or broken file is an empty history. The history keeps the newest MAX_RUNS
## runs (a proposal, for the board to change).

const DEFAULT_PATH := "user://run_history.json"
## The save file. Tests point this at RunPaths.file(...) (see TestSave).
static var path: String = DEFAULT_PATH

## The most runs kept; the oldest are dropped past it.
const MAX_RUNS := 200

## Emitted after a run was added (and saved).
signal changed

var _runs: Array = []  # oldest first, as saved
var _path: String


func _init(save_path: String = "") -> void:
	_path = save_path if save_path != "" else path
	load_from_disk()


## Reads the file. Missing or broken: an empty history. Returns true if a file was read.
func load_from_disk() -> bool:
	_runs = []
	if not FileAccess.file_exists(_path):
		return false
	var f := FileAccess.open(_path, FileAccess.READ)
	if f == null:
		return false
	var json := JSON.new()
	if json.parse(f.get_as_text()) != Error.OK:
		return false
	var parsed: Variant = json.data
	if typeof(parsed) != TYPE_DICTIONARY or typeof(parsed.get("runs", null)) != TYPE_ARRAY:
		return false
	for entry in parsed["runs"]:
		if typeof(entry) == TYPE_DICTIONARY:
			_runs.append(entry)
	return true


## Writes the file. Returns true on success.
func save() -> bool:
	var f := FileAccess.open(_path, FileAccess.WRITE)
	if f == null:
		push_error("Could not write the run history %s" % _path)
		return false
	f.store_string(JSON.stringify({"runs": _runs}, "\t"))
	return true


## Adds a finished run: its recap (RunState.recap()) plus "ended_at" (the local date
## and time, "YYYY-MM-DDTHH:MM:SS", and "ended_unix" in seconds). Saves.
## A recap of a run still going (empty result) is ignored.
func add_run(recap: Dictionary, ended_unix: int = -1) -> void:
	if str(recap.get("result", "")) == "":
		return
	var t := ended_unix if ended_unix >= 0 else int(Time.get_unix_time_from_system())
	var entry := recap.duplicate(true)
	entry["ended_unix"] = t
	entry["ended_at"] = Time.get_datetime_string_from_unix_time(t + _utc_offset_seconds())
	_runs.append(entry)
	while _runs.size() > MAX_RUNS:
		_runs.pop_front()
	save()
	changed.emit()


static func _utc_offset_seconds() -> int:
	return int(Time.get_time_zone_from_system().get("bias", 0)) * 60


## Every saved run, newest first, as copies (read-only). Each entry is the recap
## (result, loss_reason, time_survived, coins, likes, level, enemies_slain, tricks,
## highest_combo, weapons) plus ended_at and ended_unix.
func runs() -> Array:
	var out: Array = _runs.duplicate(true)
	out.reverse()
	return out


func count() -> int:
	return _runs.size()


## The run's state emits run_ended: save its final recap, once.
func connect_run(state: Object) -> void:
	state.run_ended.connect(func(_result: String, _coins: int) -> void: add_run(state.recap()))
