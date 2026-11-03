class_name SlotRules
extends RefCounted
## The 4-minute run's caps from res://data/slots.json (T-521): how many weapons and
## driving power-ups the car can own, the tier a weapon arrives at when first picked, and
## the hearts a full sub goal heals once every owned weapon is at its last tier.
## The max tiers are not here: they come from weapons.json and power_ups.json.

var _data: Dictionary = {}
var error: String = ""


func _init(file: String = "slots") -> void:
	var r := GameData.load_file(file)
	if r.ok:
		_data = r.data
	else:
		error = r.error


func is_ok() -> bool:
	return error == ""


## Most weapons the car owns (the gun counts).
func max_weapons() -> int:
	return int(_data.get("max_weapons", 3))


## Most driving power-ups the car owns.
func max_power_ups() -> int:
	return int(_data.get("max_power_ups", 3))


## The tier a weapon has right after its first pick (tiers 1 to this one applied in order).
func first_pick_tier() -> int:
	return maxi(int(_data.get("first_pick_tier", 2)), 1)


## Hearts a full sub goal heals when every owned weapon is at its last tier.
func heal_hearts() -> float:
	return float(_data.get("heal_hearts", 2.0))
