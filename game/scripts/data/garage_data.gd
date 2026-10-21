class_name GarageData
extends RefCounted
## The garage's upgrades from res://data/garage.json: price and effect for every level.

const UPGRADES := ["acceleration", "car_health", "damage_bonus", "pickup_magnet"]

var _data: Dictionary = {}
var error: String = ""


func _init(file: String = "garage") -> void:
	var r := GameData.load_file(file)
	if r.ok:
		_data = r.data
	else:
		error = r.error


func is_ok() -> bool:
	return error == ""


func max_level() -> int:
	return int(_data["max_level"])


func upgrade_ids() -> Array:
	return _data["upgrades"].keys()


func _row(upgrade: String, level: int) -> Dictionary:
	for row in _data["upgrades"][upgrade]["levels"]:
		if int(row["level"]) == level:
			return row
	push_error("Game data value missing: no level %d for %s in garage.json" % [level, upgrade])
	return {}


## Coins to buy `level` (1 to max_level).
func price(upgrade: String, level: int) -> int:
	return int(_row(upgrade, level)["price"])


## The stat's value once `level` is bought; level 0 is the base value.
func value(upgrade: String, level: int) -> float:
	if level <= 0:
		return float(_data["upgrades"][upgrade]["base_value"])
	return float(_row(upgrade, level)["value"])
