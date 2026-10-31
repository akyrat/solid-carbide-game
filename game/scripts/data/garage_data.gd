class_name GarageData
extends RefCounted
## The garage's upgrades from res://data/garage.json: price and effect for every level.

const UPGRADES := ["acceleration", "car_health", "damage_bonus", "pickup_magnet", "air_turn"]

## Upgrades whose base lives in run.json, not here (T-415): the garage adds a bonus to it.
## Level n stores only "bonus"; value() is the run's base plus that bonus.
const RUN_BASES := ["car_health", "pickup_magnet"]

var _data: Dictionary = {}
var _run: RunData = null
var error: String = ""


func _init(file: String = "garage", run_data: RunData = null) -> void:
	_run = run_data
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


## The run.json base of an upgrade in RUN_BASES (starting hearts, magnet radius).
func run_base(upgrade: String) -> float:
	if _run == null:
		_run = RunData.new()
	if upgrade == "car_health":
		return _run.starting_hearts()
	return _run.pickup_magnet_radius_units()


## What `level` adds to the run's base, for an upgrade in RUN_BASES (0 at level 0).
func bonus(upgrade: String, level: int) -> float:
	if level <= 0:
		return 0.0
	return float(_row(upgrade, level)["bonus"])


## The stat's value once `level` is bought; level 0 is the base value. For the upgrades in
## RUN_BASES it is run.json's base plus the level's bonus.
func value(upgrade: String, level: int) -> float:
	if upgrade in RUN_BASES:
		return run_base(upgrade) + bonus(upgrade, level)
	if level <= 0:
		return float(_data["upgrades"][upgrade]["base_value"])
	return float(_row(upgrade, level)["value"])
