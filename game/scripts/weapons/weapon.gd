extends Node
## The base of every weapon on the car (task T-041; Weapons, Decisions).
## A weapon fires on its own; the player only drives. The run's weapon rack
## (weapons.gd, `run.weapons`) owns one node of each weapon, steps the owned
## ones once per physics step and resets them at the start of every run.
##
## A weapon's tier is 0 (not owned), 1 (just got it) up to the data's
## max_tier (8): tiers 2 to 8 are its upgrades, from res://data/weapons.json
## through WeaponData. Change tiers from code with set_tier() or upgrade();
## offering them at a level-up is the level-up task's (T-043).
##
## To add a weapon: extend this script, set `weapon_id` and `starts_owned`,
## override apply_tier() (read the tier's values), reset_for_run() if it keeps
## more state, and step(dt) (what it does each physics step while owned and
## the run is going). Then list the script in weapons.gd's WEAPON_SCRIPTS.

## Emitted when the tier changes (set_tier, upgrade, a new run).
signal tier_changed(weapon_id: String, tier: int)

## The weapon's id, as in res://data/weapons.json ("gun", "flamethrower").
var weapon_id := ""
## True for the weapon every run starts with (the starting gun).
var starts_owned := false
## 0 = not owned; 1 to max_tier.
var tier := 0
## The rack this weapon belongs to (set by weapons.gd): its car, state,
## enemies and projectiles.
var rack: Node = null
var data: WeaponData = WeaponData.new()


## True while the car has this weapon.
func is_owned() -> bool:
	return tier >= 1


func max_tier() -> int:
	return data.max_tier()


func is_max_tier() -> bool:
	return tier >= max_tier()


## Sets the tier (clamped to 0..max_tier) and applies that tier's values.
func set_tier(new_tier: int) -> void:
	var t := clampi(new_tier, 0, max_tier())
	tier = t
	apply_tier()
	tier_changed.emit(weapon_id, tier)


## Gets the weapon (tier 0 to 1) or applies its next upgrade. Returns false,
## changing nothing, when it is already at its last tier.
func upgrade() -> bool:
	if is_max_tier():
		return false
	set_tier(tier + 1)
	return true


## A new run: back to tier 1 for the starting weapon, not owned for the rest.
func reset_for_run() -> void:
	set_tier(1 if starts_owned else 0)


## Reads the values of the current tier. Overridden by each weapon.
func apply_tier() -> void:
	pass


## One physics step of `dt` seconds. Called by the rack only while the weapon
## is owned and the run is going (and not while the tree is paused).
func step(_dt: float) -> void:
	pass


## The garage's damage bonus (T-062) applied to a tier's damage: `base` times
## the rack's damage multiplier (1.0 with no bonus).
func boosted_damage(base: float) -> float:
	return base * (rack.damage_multiplier() if rack != null else 1.0)
