class_name ViewersData
extends RefCounted
## The combo shown as live viewers (task T-332; res://data/viewers.json, Game loop
## architecture, Decisions, "The combo shows as live viewers"). The combo multiplier is
## unchanged (ComboData); this turns it into the number the counter shows: the curve from
## multiplier to viewers, the heat steps in viewers, how the shown number moves, what a
## trick brought or a crash lost, and how a number is written.

var _data: Dictionary = {}
var error: String = ""


func _init(file: String = "viewers") -> void:
	var r := GameData.load_file(file)
	if r.ok:
		_data = r.data
	else:
		error = r.error


func is_ok() -> bool:
	return error == ""


## The target viewers for a combo multiplier: a power law between neighbouring anchors,
## flat below the first and above the last, rounded to whole viewers.
func viewers_for(multiplier: float) -> float:
	var a: Array = _data["curve"]["anchors"]
	var m := clampf(multiplier, float(a[0]["multiplier"]), float(a[a.size() - 1]["multiplier"]))
	for i in range(a.size() - 1):
		var m0 := float(a[i]["multiplier"])
		var m1 := float(a[i + 1]["multiplier"])
		if m <= m1:
			var v0 := float(a[i]["viewers"])
			var v1 := float(a[i + 1]["viewers"])
			var t := log(m / m0) / log(m1 / m0)
			return roundf(v0 * pow(v1 / v0, t))
	return float(a[a.size() - 1]["viewers"])


## The viewers of "no combo" (x1).
func base_viewers() -> float:
	return viewers_for(float(_data["curve"]["anchors"][0]["multiplier"]))


## The viewers where heat steps 1, 2 and 3 start (the same steps as ComboHeat.THRESHOLDS).
func heat_thresholds() -> Array:
	return (_data["heat_steps"]["thresholds_viewers"] as Array).duplicate()


## The viewers from which the counter is on fire (the board's: over a million).
func fire_viewers() -> float:
	return float(_data["heat_steps"]["fire_viewers"])


## The look step for a number of viewers: 0 below the first threshold, 1 to 3 at each
## threshold, 4 (fire) from fire_viewers. Pass the target, not the wobbling shown number.
func step_for_viewers(viewers: float) -> int:
	var s := 0
	for t in heat_thresholds():
		if viewers >= float(t):
			s += 1
	if viewers >= fire_viewers():
		s += 1
	return s


func step_for_multiplier(multiplier: float) -> int:
	return step_for_viewers(viewers_for(multiplier))


func is_fire(viewers: float) -> bool:
	return viewers >= fire_viewers()


## The shown number after `dt` seconds of counting toward `target`: an ease at the up or
## down rate, landing on the target within snap_viewers.
func count_toward(shown: float, target: float, dt: float) -> float:
	var m: Dictionary = _data["motion"]
	var snap := float(m["snap_viewers"])
	var gap := target - shown
	if absf(gap) <= snap:
		return target
	var rate := float(m["up_rate_per_second"]) if gap > 0.0 else float(m["down_rate_per_second"])
	var next := shown + gap * (1.0 - exp(-rate * maxf(dt, 0.0)))
	if absf(target - next) <= snap:
		return target
	return next


## The wobble as a multiplier near 1.0 at time `t` seconds: a pseudo-random offset in
## [-wobble_fraction, +wobble_fraction] for each wobble interval, eased between them.
func wobble_factor(t: float) -> float:
	var m: Dictionary = _data["motion"]
	var pos := maxf(t, 0.0) / float(m["wobble_interval_seconds"])
	var i := floori(pos)
	var f := smoothstep(0.0, 1.0, pos - i)
	var o := lerpf(_offset(i), _offset(i + 1), f)
	return 1.0 + float(m["wobble_fraction"]) * o


## The number the counter draws: the shown number with the wobble on it, whole viewers.
func with_wobble(shown: float, t: float) -> float:
	return roundf(shown * wobble_factor(t))


static func _offset(i: int) -> float:
	var x := sin(float(i) * 12.9898) * 43758.5453
	return (x - floorf(x)) * 2.0 - 1.0


## The viewers a trick brought: the target after the multiplier change minus before (0 or more).
func trick_gain(multiplier_before: float, multiplier_after: float) -> float:
	return maxf(viewers_for(multiplier_after) - viewers_for(multiplier_before), 0.0)


## The viewers a crash lost: the target before the multiplier change minus after (0 or more).
func crash_loss(multiplier_before: float, multiplier_after: float) -> float:
	return maxf(viewers_for(multiplier_before) - viewers_for(multiplier_after), 0.0)


## Writes a viewers number short: 850, 2,500, 20.4K, 236K, 1.02M.
func format(viewers: float) -> String:
	var f: Dictionary = _data["format"]
	var v := int(roundf(maxf(viewers, 0.0)))
	if v < 1000:
		return str(v)
	if v < int(f["comma_below"]):
		return "%d,%03d" % [v / 1000, v % 1000]
	if v < int(f["one_decimal_k_below"]):
		var k := snappedf(v / 1000.0, 0.1)
		return "%.1fK" % k if k < 100.0 else "100K"
	elif v < int(f["million_from"]):
		var k2 := roundi(v / 1000.0)
		if k2 < 1000:
			return "%dK" % k2
	return "%.2fM" % (v / 1000000.0)
