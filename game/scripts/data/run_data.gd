class_name RunData
extends RefCounted
## The run's numbers from res://data/run.json: XP per challenge, XP per level, drift XP, starting health.

var _data: Dictionary = {}
var error: String = ""


func _init(file: String = "run") -> void:
	var r := GameData.load_file(file)
	if r.ok:
		_data = r.data
	else:
		error = r.error


func is_ok() -> bool:
	return error == ""


func max_level() -> int:
	return int(_data["max_level"])


func starting_health() -> float:
	return float(_data["car"]["starting_health"])


func drift_xp_per_second() -> float:
	return float(_data["drift_xp_per_second"])


func carries_over() -> bool:
	return bool(_data["carry_over_xp"])


func _row(level: int) -> Dictionary:
	for row in _data["levels"]:
		if int(row["level"]) == level:
			return row
	push_error("Game data value missing: no row for level %d in run.json" % level)
	return {}


## XP needed to go from `level` to the next level (0 at max level).
func xp_needed(level: int) -> float:
	return 0.0 if level >= max_level() else float(_row(level)["xp_needed"])


## XP one completed challenge gives at `level`.
func challenge_xp(level: int) -> float:
	return float(_row(level)["challenge_xp"])
