class_name RunHistory
extends RefCounted
## Every finished run's recap stats, kept on this computer (task T-363): one JSON
## file under user://, one entry per run, for the runs list screen (T-364).
## Game loop architecture, Decisions, "The runs list"; fields: game/docs/data/game-data.md.
##
## A missing file is an empty history; a broken one is kept aside and the backup loads (T-417). The history keeps the newest MAX_RUNS
## runs (a proposal, for the board to change).

const DEFAULT_PATH := "user://run_history.json"
## The save file. Tests point this at RunPaths.file(...) (see TestSave).
static var path: String = DEFAULT_PATH

## The most runs kept; the oldest are dropped past it.
const MAX_RUNS := 200

## Emitted after a run was added (and saved).
signal changed

var _runs: Array = []  # oldest first, as saved
## Where the last load came from: "main", "backup" or "none"; and the save's version (T-417).
var loaded_from: String = "none"
var loaded_version: int = 1
var _path: String


func _init(save_path: String = "") -> void:
	_path = save_path if save_path != "" else path
	load_from_disk()


## Reads the file (SafeSave: a broken file is kept aside and the backup is loaded;
## neither: an empty history). Returns true if a save was read.
func load_from_disk() -> bool:
	_runs = []
	var res := SafeSave.read(_path, "runs")
	loaded_from = res["source"]
	loaded_version = res["version"]
	var parsed: Dictionary = res["data"]
	if loaded_from == "none" or typeof(parsed.get("runs", null)) != TYPE_ARRAY:
		return false
	for entry in parsed["runs"]:
		if typeof(entry) == TYPE_DICTIONARY:
			_runs.append(entry)
	return true


## Writes the file safely (temp file, rename, backup; SafeSave). Returns true on success.
func save() -> bool:
	return SafeSave.write(_path, {"runs": _runs}, "runs")


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
