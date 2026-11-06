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


## Seconds after a collision cut the combo during which another collision does not cut it
## again (T-415; a proposal for the playtest).
func collision_window_seconds() -> float:
	return float(_data.get("collision_window_seconds", 0.0))


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


## The subs one trick pays straight away (T-513; combo.json, "trick_subs"): 0 for a
## trick not in the table.
func trick_subs(trick: String) -> float:
	return float(_data.get("trick_subs", {}).get(trick, 0.0))


## Whether the trick's subs are multiplied by the combo multiplier (trick_subs.multiplied_by_combo).
func trick_subs_multiplied() -> bool:
	return bool(_data.get("trick_subs", {}).get("multiplied_by_combo", true))


## What the airtime trick adds for an airtime of `seconds` (task T-242; combo.json,
## "airtime"): nothing under min_seconds, else per_second times the seconds
## (taken to hundredths), held at max_add. Rounded to hundredths, as the popup shows it.
func airtime_add(seconds: float) -> float:
	var a: Dictionary = _data["airtime"]
	var s := snappedf(seconds, 0.01)
	if s < float(a["min_seconds"]) - 0.000001:
		return 0.0
	return snappedf(minf(s * float(a["per_second"]), float(a["max_add"])), 0.01)

## Shortest airtime that pays, in seconds (airtime.min_seconds; task T-315 reads it).
func airtime_min_seconds() -> float:
	return float(_data["airtime"]["min_seconds"])


## Task T-536 (combo.json, "reverse_drift"): seconds a reverse drift must last to pay.
func reverse_drift_min_seconds() -> float:
	return float(_data.get("reverse_drift", {}).get("min_seconds", 1.0))


## Task T-536 (combo.json, "aura"): the speed (units/s) at or under which the car is still.
func aura_still_speed() -> float:
	return float(_data.get("aura", {}).get("still_speed", 0.5))


## Task T-536 (combo.json, "aura"): seconds still before the aura starts paying.
func aura_wait_seconds() -> float:
	return float(_data.get("aura", {}).get("wait_seconds", 5.0))


## Task T-536 (combo.json, "aura"): seconds per aura trick once it pays.
func aura_every_seconds() -> float:
	return float(_data.get("aura", {}).get("every_seconds", 1.0))


## Whether a crash pays the trick in progress before it cuts the combo (task
## T-315; combo.json, crash_pays_trick_first). true (the default): the trick's
## popup shows, then COMBO BROKEN!; false: the cut comes first, then the trick
## is added to the cut combo.
func crash_pays_trick_first() -> bool:
	return bool(_data.get("crash_pays_trick_first", true))


## The thread the needle trick's rules (task T-272; combo.json, "thread_the_needle"):
## {repeat_seconds, counts_in_air, touch_window_seconds, clear_seconds}. Its worth is
## trick_add("thread_the_needle").
func needle_rules() -> Dictionary:
	var n: Dictionary = _data.get("thread_the_needle", {})
	return {
		"repeat_seconds": float(n.get("repeat_seconds", 3.0)),
		"counts_in_air": bool(n.get("counts_in_air", true)),
		"touch_window_seconds": float(n.get("touch_window_seconds", 0.5)),
		"clear_seconds": float(n.get("clear_seconds", 0.25)),
	}


## The rail grind (task T-541; combo.json, "rail_grind"): its numbers, with defaults.
func _grind() -> Dictionary:
	return _data.get("rail_grind", {})


## Shortest grind that pays, in seconds (rail_grind.min_seconds).
func grind_min_seconds() -> float:
	return float(_grind().get("min_seconds", 0.3))


## What a whole grind of `seconds` adds to the multiplier, paid once when it ends: seconds times
## rail_grind.add_per_second, at most rail_grind.max_add, nothing under min_seconds. Rounded to
## hundredths, as the popup shows it.
func grind_add(seconds: float) -> float:
	if seconds < grind_min_seconds() - 1e-6:
		return 0.0
	var g := _grind()
	return snappedf(minf(seconds * float(g.get("add_per_second", 0.25)), float(g.get("max_add", 1.0))), 0.01)


## The subs a whole grind of `seconds` pays (before the combo multiplier): seconds times
## rail_grind.subs_per_second, at most rail_grind.max_subs, nothing under min_seconds.
func grind_subs(seconds: float) -> float:
	if seconds < grind_min_seconds() - 1e-6:
		return 0.0
	var g := _grind()
	return minf(seconds * float(g.get("subs_per_second", 5.0)), float(g.get("max_subs", 20.0)))


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


## How much above the base the car's top speed is at a combo heat step (task
## T-275; combo.json, hype_speed): 0 at step 0, else bonus_per_step[step - 1]
## (a step past the list takes the last).
func hype_speed_bonus(step: int) -> float:
	var amounts: Array = _data["hype_speed"]["bonus_per_step"]
	if step <= 0 or amounts.is_empty():
		return 0.0
	return float(amounts[mini(step, amounts.size()) - 1])


## How fast the car's hype speed bonus eases to the step's amount, per second.
func hype_speed_ease_per_second() -> float:
	return float(_data["hype_speed"]["ease_per_second"])


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
