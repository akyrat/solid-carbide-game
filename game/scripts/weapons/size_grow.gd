class_name SizeGrow
extends RefCounted
## The grow of a weapon that gets bigger (task T-286; Weapons, Decisions, "Size
## upgrades grow on screen"): the size the weapon is drawn at, and hit with,
## runs from its old size to the new one in DURATION seconds with a small
## overshoot, then settles exactly on the new size (an ease-out-back, like the
## likes bar's spring, LikesSpring, T-273). All the timing is here: tune
## DURATION and OVERSHOOT.
##
## The weapon owns one of these, calls `advance(dt)` from its physics step (so
## it stands still while the game is paused, as the weapon does) and reads
## `value` wherever it draws or hits. A weapon with no grow running reads the
## data's size exactly.

## Seconds from the old size to the new one (the settle ends here too). Long
## enough to read as growing, short enough not to wait for (proposal, T-286).
const DURATION := 0.4
## The ease-out-back's strength. 3.0 passes the new size by about 20 percent of
## the step (a step is 20 to 30 percent of the size, so about 5 percent of the
## size) and settles: a small pop, no wobble (proposal, T-286).
const OVERSHOOT := 3.0

## The size now: what is drawn and what hits.
var value := 0.0
## The size it is heading for (the data's).
var target := 0.0
## True while it grows.
var active := false
var _from := 0.0
var _t := 0.0


## The ease-out-back curve: 0 at 0, 1 at 1, above 1 in between.
static func ease_back(t: float) -> float:
	var x := clampf(t, 0.0, 1.0) - 1.0
	return 1.0 + (OVERSHOOT + 1.0) * x * x * x + OVERSHOOT * x * x


## The size `t` seconds into a grow from `from` to `to`.
static func value_at(from: float, to: float, t: float) -> float:
	return from + (to - from) * ease_back(t / DURATION)


## Goes to `size` at once (a new run, a tier that does not change the size).
func snap(size: float) -> void:
	value = size
	target = size
	active = false


## Grows from the size shown now to `size`.
func grow_to(size: float) -> void:
	if is_equal_approx(size, value):
		snap(size)
		return
	_from = value
	target = size
	_t = 0.0
	active = true


## Moves on by `dt` seconds; settles exactly on the target at the end.
func advance(dt: float) -> void:
	if not active:
		return
	_t += dt
	if _t >= DURATION:
		snap(target)
	else:
		value = value_at(_from, target, _t)
