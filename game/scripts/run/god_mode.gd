class_name GodMode
extends Node
## God mode (task T-504; HUD and menus, Decisions, "A secret God mode"). Pressing N
## (input action "god_mode_unlock") during a run unlocks God mode for the rest of the
## session: `unlocked` is a static flag, so it stays across runs and screens, is never
## saved, and is false again at the next start of the game. T-505's settings page reads
## `GodMode.unlocked` / `unlocked_changed` and calls the API below; it draws nothing here.
##
## The API (run.god_mode, a child "GodMode" of the run):
##   entries()                  every weapon and driving power-up: an Array of
##                              {kind: "weapon"|"power_up", id, tier, last_tier, min_tier}
##   current_tier(kind, id)     its tier in this run (0 = not owned); -1 for an unknown id
##   last_tier(kind, id)        its last tier; -1 for an unknown id
##   set_tier(kind, id, tier)   sets it at once, as if levelled up; returns the tier now
##                              (clamped to min_tier..last_tier), -1 for an unknown id
##   step(kind, id, delta)      set_tier(current + delta), for the - and + buttons
## The weapons come from the rack (run.weapons.weapons) and the power-ups from
## PowerUpData.ids(), so a new power-up needs no change here. The gun's min_tier is 1,
## everything else 0. Setting a weapon replays its tiers: reset, then upgrade() once per
## tier (the level-up's own call), so the stats equal levelling it up from tier 1. A
## power-up goes through RunState.set_power_up_tier, which the car follows. The level-up
## and the gifts read the live tiers, so they then offer only what is left. A new run
## starts as usual (the chosen tiers are not kept).

## Sent when God mode is unlocked (not when N is pressed again).
signal unlocked_changed
## A weapon or power-up tier was set by set_tier().
signal tier_set(kind: String, id: String, tier: int)

const KIND_WEAPON := "weapon"
const KIND_POWER_UP := "power_up"
const UNLOCK_ACTION := "god_mode_unlock"

## True for the rest of the session once N was pressed. Never saved.
static var unlocked := false

var run: Node = null
var _power_up_data: PowerUpData = null


func bind(the_run: Node) -> void:
	run = the_run
	process_mode = Node.PROCESS_MODE_ALWAYS  # N works behind a paused screen too


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(UNLOCK_ACTION) and not event.is_echo():
		unlock()


## Unlocks God mode for the session.
func unlock() -> void:
	if unlocked:
		return
	unlocked = true
	unlocked_changed.emit()


func _power_ups() -> PowerUpData:
	if _power_up_data == null:
		_power_up_data = PowerUpData.new()
	return _power_up_data


func _weapon(id: String) -> Node:
	return run.weapons.get_weapon(id) if run != null and run.weapons != null else null


func _known(kind: String, id: String) -> bool:
	if kind == KIND_WEAPON:
		return _weapon(id) != null
	if kind == KIND_POWER_UP:
		return _power_ups().is_ok() and _power_ups().ids().has(id)
	return false


func current_tier(kind: String, id: String) -> int:
	if not _known(kind, id):
		return -1
	if kind == KIND_WEAPON:
		return _weapon(id).tier
	return run.state.power_up_tier(id)


func last_tier(kind: String, id: String) -> int:
	if not _known(kind, id):
		return -1
	if kind == KIND_WEAPON:
		return _weapon(id).max_tier()
	return _power_ups().max_tier(id)


## The lowest tier the entry can be set to: 1 for the gun, else 0.
func min_tier(kind: String, id: String) -> int:
	return 1 if kind == KIND_WEAPON and id == "gun" else 0


## Every weapon (rack order) then every power-up (data order).
func entries() -> Array:
	var out := []
	if run == null:
		return out
	for id in run.weapons.weapons:
		out.append(_entry(KIND_WEAPON, String(id)))
	if _power_ups().is_ok():
		for id in _power_ups().ids():
			out.append(_entry(KIND_POWER_UP, String(id)))
	return out


func _entry(kind: String, id: String) -> Dictionary:
	return {"kind": kind, "id": id, "tier": current_tier(kind, id),
			"last_tier": last_tier(kind, id), "min_tier": min_tier(kind, id)}


## Sets the tier at once. Returns the tier now; -1, changing nothing, for an unknown id.
func set_tier(kind: String, id: String, tier: int) -> int:
	if not _known(kind, id):
		return -1
	var t := clampi(tier, min_tier(kind, id), last_tier(kind, id))
	if kind == KIND_WEAPON:
		var w: Node = _weapon(id)
		if t != w.tier:
			if t < w.tier or t == 0:
				w.reset_for_run()  # the gun back to 1, the others to 0
				if t == 0:
					w.set_tier(0)
			while w.tier < t and w.upgrade():
				pass
	else:
		run.state.set_power_up_tier(id, t)
	tier_set.emit(kind, id, t)
	return t


func step(kind: String, id: String, delta: int) -> int:
	var now := current_tier(kind, id)
	if now < 0:
		return -1
	return set_tier(kind, id, now + delta)
