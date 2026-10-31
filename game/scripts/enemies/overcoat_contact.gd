class_name OvercoatContact
extends RefCounted
## Rusty Overcoat (T-463; Drifting, Decisions, "Driving power-ups"; numbers in
## res://data/power_ups.json): with the power-up owned, an enemy the car touches takes the
## owned tier's contact_damage, then not again for repeat_cooldown_seconds (per enemy).
## The kaiju only takes it when the tier's hits_kaiju is true. The enemy still hits the car
## as before. Shared by minion.gd and kaiju.gd.

const POWER_UP_ID := "rusty_overcoat"

static var _data: PowerUpData = null


## The tier's numbers ({contact_damage, repeat_cooldown_seconds, hits_kaiju, ...}), or {}
## when `state` does not own the power-up.
static func numbers(state: Node) -> Dictionary:
	if state == null or not state.has_method("power_up_tier"):
		return {}
	var tier: int = state.power_up_tier(POWER_UP_ID)
	if tier <= 0:
		return {}
	if _data == null:
		_data = PowerUpData.new()
	if not _data.is_ok():
		return {}
	return _data.at(POWER_UP_ID, tier)


## Called by an enemy that touches the car at its level, once per physics step, with its own
## cooldown in seconds (already counted down). Returns the cooldown now: unchanged when it
## did not hit, the tier's repeat cooldown when it did.
static func hit(enemy: Node, state: Node, cooldown: float, is_kaiju: bool) -> float:
	if cooldown > 0.0:
		return cooldown
	var n := numbers(state)
	if n.is_empty():
		return cooldown
	if is_kaiju and not bool(n.get("hits_kaiju", false)):
		return cooldown
	enemy.take_damage(float(n["contact_damage"]), POWER_UP_ID)
	return float(n["repeat_cooldown_seconds"])
