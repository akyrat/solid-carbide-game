class_name RunData
extends RefCounted
## The run's numbers from res://data/run.json: XP per challenge, XP per level, drift XP, starting health, the likes drain.

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


## Whether the likes bar drains once the combo has fully drained (Game loop architecture, Decisions).
func likes_drain_enabled() -> bool:
	return bool(_data["likes_drain"]["enabled"])


## Share of the current level's XP bar (xp_needed) the drain removes per second.
func likes_drain_bar_share_per_second() -> float:
	return float(_data["likes_drain"]["bar_share_per_second"])


## Extra seconds to wait after the combo has fully drained before the likes drain starts (0 = at once).
func likes_drain_extra_wait_seconds() -> float:
	return float(_data["likes_drain"]["extra_wait_seconds"])


## XP the drain removes per second at `level`: the bar share times that level's bar.
## 0 when the drain is off, and at max level (no bar to fill).
func likes_drain_xp_per_second(level: int) -> float:
	if not likes_drain_enabled():
		return 0.0
	return likes_drain_bar_share_per_second() * xp_needed(level)
