class_name MissionData
extends RefCounted
## The run's missions from res://data/missions.json: the 5 fixed ones and the generator's rules
## for missions 6 to 12 (all proposals for the playtest). Same style as WeaponData.

var _data: Dictionary = {}
var error: String = ""


func _init(file: String = "missions") -> void:
	var r := GameData.load_file(file)
	if r.ok:
		_data = r.data
	else:
		error = r.error


func is_ok() -> bool:
	return error == ""


## Missions in a run (12, T-521).
func total() -> int:
	return int(_data["total"])


## The trick ids a goal may use.
func known_tricks() -> Array:
	return _data["known_tricks"]


## The fixed missions, in order; each {"number", "goals": [{"trick", "kind", "amount"}]}.
func fixed() -> Array:
	return _data["fixed"]


## The generator's trick rules: {"trick", "kind", "base", "growth_per_mission", "max", ...}.
func trick_rules() -> Array:
	return _data["generator"]["tricks"]


## How many goals mission `number` (6 to total) has.
func goals_for(number: int) -> int:
	for r in _data["generator"]["goals_per_mission"]["ranges"]:
		if number >= int(r["from"]) and number <= int(r["to"]):
			return int(r["goals"])
	return 1


## A rule's amount at mission `number`: base grown per mission since the first generated
## one, capped at max. Counts round to a whole number; seconds round to 0.5.
func amount_for(rule: Dictionary, number: int) -> float:
	var first := int(_data["generator"]["first_mission"])
	var raw := float(rule["base"]) + float(rule["growth_per_mission"]) * float(maxi(number - first, 0))
	raw = minf(raw, float(rule["max"]))
	if String(rule["kind"]) == "seconds":
		return snappedf(raw, 0.5)
	return float(roundi(raw))


## Mission `number` (1 to total) as a list of goals. Fixed missions come from the file; later
## ones pick goals_for(number) different tricks with `rng`.
func mission(number: int, rng: RandomNumberGenerator) -> Array:
	if number <= fixed().size():
		return fixed()[number - 1]["goals"]
	var rules: Array = trick_rules().duplicate()
	var goals: Array = []
	for i in goals_for(number):
		var idx := rng.randi_range(0, rules.size() - 1)
		var rule: Dictionary = rules[idx]
		rules.remove_at(idx)
		goals.append({"trick": rule["trick"], "kind": rule["kind"], "amount": amount_for(rule, number)})
	return goals
