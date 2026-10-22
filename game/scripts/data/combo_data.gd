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


## What one trick adds to the multiplier: "three_sixty", "alternate_drift",
## "air_one_eighty" or "air_three_sixty" (TrickDetector.TRICK_IDS). The extended
## drift is scaled by its length instead: drift_amount().
func trick_add(trick: String) -> float:
	var tricks: Dictionary = _data["trick_add"]
	if not tricks.has(trick):
		push_error("Game data value missing: trick_add.%s in combo.json" % trick)
		return 0.0
	return float(tricks[trick])


## What the airtime trick adds for an airtime of `seconds` (task T-242; combo.json,
## "airtime"): nothing under min_seconds, else per_second times the seconds
## (taken to hundredths), held at max_add. Rounded to hundredths, as the popup shows it.
func airtime_add(seconds: float) -> float:
	var a: Dictionary = _data["airtime"]
	var s := snappedf(seconds, 0.01)
	if s < float(a["min_seconds"]) - 0.000001:
		return 0.0
	return snappedf(minf(s * float(a["per_second"]), float(a["max_add"])), 0.01)

## Shortest drift that pays, in seconds (drift_pay.min_seconds, task T-246).
func drift_min_seconds() -> float:
	return float(_data["drift_pay"]["min_seconds"])


## What a whole drift of `seconds` adds to the multiplier, paid once when it
## ends: seconds times drift_pay.per_second, nothing under min_seconds, at most
## drift_pay.max (task T-246).
func drift_amount(seconds: float) -> float:
	var d: Dictionary = _data["drift_pay"]
	if seconds < float(d["min_seconds"]) - 1e-6:
		return 0.0
	return minf(seconds * float(d["per_second"]), float(d["max"]))


## What a trick adds: the data's amount, or for the extended drift the scaled
## amount for its `seconds`.
func trick_amount(trick: String, seconds := 0.0) -> float:
	if trick == "extended_drift":
		return drift_amount(seconds)
	return trick_add(trick)


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
func after_trick(multiplier: float, trick: String, seconds := 0.0) -> float:
	return minf(multiplier + trick_amount(trick, seconds), max_multiplier())


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
