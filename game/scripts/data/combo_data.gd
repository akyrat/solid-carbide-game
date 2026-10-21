class_name ComboData
extends RefCounted
## The combo's numbers from res://data/combo.json: what each trick adds, the cap, the collision cut,
## the drain, and how the combo raises minion spawning.

var _data: Dictionary = {}
var error: String = ""


func _init(file: String = "combo") -> void:
	var r := GameData.load_file(file)
	if r.ok:
		_data = r.data
	else:
		error = r.error


func is_ok() -> bool:
	return error == ""


func start_multiplier() -> float:
	return float(_data["start_multiplier"])


func max_multiplier() -> float:
	return float(_data["max_multiplier"])


## What one trick adds to the multiplier: "extended_drift", "three_sixty", "alternate_drift",
## "air_one_eighty" or "air_three_sixty" (TrickDetector.TRICK_IDS).
func trick_add(trick: String) -> float:
	var tricks: Dictionary = _data["trick_add"]
	if not tricks.has(trick):
		push_error("Game data value missing: trick_add.%s in combo.json" % trick)
		return 0.0
	return float(tricks[trick])


func collision_cut() -> float:
	return float(_data["collision_cut"])


func drain_wait_seconds() -> float:
	return float(_data["drain_wait_seconds"])


func drain_per_second() -> float:
	return float(_data["drain_per_second"])


## The multiplier after a collision: the cut applies to the part above the start value.
func after_collision(multiplier: float) -> float:
	var s := start_multiplier()
	return s + maxf(multiplier - s, 0.0) * (1.0 - collision_cut())


## The multiplier after one trick, held at the maximum.
func after_trick(multiplier: float, trick: String) -> float:
	return minf(multiplier + trick_add(trick), max_multiplier())


## The multiplier after `seconds` with no trick: nothing for the wait, then the drain, down to the start value.
func after_idle(multiplier: float, seconds: float) -> float:
	var draining := maxf(seconds - drain_wait_seconds(), 0.0)
	return maxf(multiplier - draining * drain_per_second(), start_multiplier())


## How much the minion spawn rate is multiplied at this combo (1.0 when switched off or no combo).
func spawn_multiplier(multiplier: float) -> float:
	var sp: Dictionary = _data["spawning"]
	if not bool(sp["enabled"]):
		return 1.0
	var extra := maxf(multiplier - start_multiplier(), 0.0) * float(sp["extra_spawn_per_multiplier_point"])
	return minf(1.0 + extra, float(sp["max_spawn_multiplier"]))
