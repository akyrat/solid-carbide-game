extends RefCounted
## Grinding Wheels (task T-586; Drifting, Decisions, "Grinding Wheels, a driving power-up"; how it
## behaves: Drifting, Content, "Grinding Wheels (task T-586)"). A driving power-up, one tier. With
## it owned (tier > 0), a grind builds stacks, one for each full `stack_seconds` of the grind, up to
## `max_stacks`; the grind's sparks heat from yellow to orange to red with the stacks
## (rail_sparks.gd reads spark_colours()), and the launch off the rail (Space let go) leaves at the
## launch speed times launch_multiplier() (rail_grind.gd launch_speed()): 1 + max_launch_boost x
## stacks / max_stacks, so 1, 1.33, 1.67 and 2 at the board's numbers. The stacks come from the
## grind's own seconds (rail_grind.gd `seconds`, 0 at every new grind, joints included), so they
## start again at 0 on each new grind with nothing kept here.
##
## At tier 0 it does nothing: launch_multiplier() is 1 and spark_colours() is empty (the sparks
## keep their own colours).
##
## Its numbers are the tier's in data/power_ups.json, its spark colours the power-up's own
## spark_colours there (proposals; reasons there).

const PowerUpDataScript := preload("res://scripts/data/power_up_data.gd")

const ID := "grinding_wheels"

## Owned tier, 0 = not owned.
var tier := 0
## The tier's numbers (power_ups.json; the defaults are tier 1's).
var stack_seconds := 1.0
var max_stacks := 3
var max_launch_boost := 1.0
var colour_fade_seconds := 0.25
## The spark colours of each heat (yellow, orange, red): an Array of Arrays of Color, one per heat.
var heat_colours: Array = []

var _data = null


## Sets the owned tier (0 = not owned) and reads its numbers.
func set_tier(new_tier: int, data = null) -> void:
	tier = maxi(new_tier, 0)
	if tier == 0:
		return
	if data != null:
		_data = data
	if _data == null:
		_data = PowerUpDataScript.new()
	var t: Dictionary = _data.at(ID, tier)
	stack_seconds = maxf(float(t.get("stack_seconds", 1.0)), 0.01)
	max_stacks = maxi(int(t.get("max_stacks", 3)), 1)
	max_launch_boost = maxf(float(t.get("max_launch_boost", 1.0)), 0.0)
	colour_fade_seconds = clampf(float(t.get("colour_fade_seconds", 0.25)), 0.0, stack_seconds)
	heat_colours = []
	var colours: Dictionary = _data.entry_value(ID, "spark_colours", {})
	for key in ["yellow", "orange", "red"]:
		var shades: Array = []
		for c in colours.get(key, []):
			shades.append(Color8(int(c[0]), int(c[1]), int(c[2])))
		heat_colours.append(shades)


func is_owned() -> bool:
	return tier > 0


## The stacks after `grind_seconds` of a grind: one per full stack_seconds, up to max_stacks
## (0 when not owned). A hair of slack so 50 steps of 0.02 s count as a full second.
func stacks(grind_seconds: float) -> int:
	if not is_owned():
		return 0
	return mini(int(floor(grind_seconds / stack_seconds + 1e-6)), max_stacks)


## The launch's speed multiplier after `grind_seconds`: 1 + max_launch_boost x stacks / max_stacks
## (1.0 when not owned).
func launch_multiplier(grind_seconds: float) -> float:
	if not is_owned():
		return 1.0
	return 1.0 + max_launch_boost * float(stacks(grind_seconds)) / float(max_stacks)


## The heat after `grind_seconds`, 0 (yellow) to heat_colours.size() - 1 (red), fractional while it
## fades: each heat holds from its stack on, and the step to the next stack's heat fades over the
## first colour_fade_seconds of that stack (yellow until 1 s, yellow to orange over 1 to 1.25 s,
## orange until 2 s, orange to red over 2 to 2.25 s, red after).
func heat(grind_seconds: float) -> float:
	var top := float(heat_colours.size() - 1)
	if top <= 0.0:
		return 0.0
	var t := maxf(grind_seconds, 0.0) / stack_seconds
	var whole := floorf(t + 1e-6)
	if whole > top:
		return top
	var into := (t - whole) * stack_seconds  # seconds into this stack
	var fade := 1.0 if colour_fade_seconds <= 0.0 else clampf(into / colour_fade_seconds, 0.0, 1.0)
	return clampf(whole - 1.0 + fade, 0.0, top) if whole >= 1.0 else 0.0


## The spark shades after `grind_seconds` (the heat's, blended shade by shade while it fades), or []
## when not owned (the sparks keep their own colours).
func spark_colours(grind_seconds: float) -> Array:
	if not is_owned() or heat_colours.is_empty():
		return []
	var h := heat(grind_seconds)
	var lo := int(floor(h))
	var hi := mini(lo + 1, heat_colours.size() - 1)
	var f := h - float(lo)
	var a: Array = heat_colours[lo]
	var b: Array = heat_colours[hi]
	var out: Array = []
	for i in a.size():
		var cb: Color = b[mini(i, b.size() - 1)] if not b.is_empty() else a[i]
		out.append((a[i] as Color).lerp(cb, f))
	return out
