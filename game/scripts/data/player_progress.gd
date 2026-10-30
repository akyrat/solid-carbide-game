class_name PlayerProgress
extends RefCounted
## The player's saved progress (task T-057): coins and the garage upgrade levels,
## kept between game sessions in a JSON file under user://. Garage design,
## Decisions; banking a run's coins: Game loop architecture, Decisions.
##
## A missing (or unreadable) file means a new player: 0 coins, every upgrade at
## level 0. Prices, effects and the last level come from GarageData (garage.json).

const DEFAULT_PATH := "user://progress.json"
## The save file. Tests point this at RunPaths.file(...) (task T-137).
static var path: String = DEFAULT_PATH

## Renamed upgrade ids (T-417): save version -> {old id: new id}. A save written at that
## version or earlier has its levels moved to the new id when it loads. Empty: no
## upgrade has been renamed yet; when one is, bump SafeSave.CURRENT_VERSION and add it here.
const ID_RENAMES := {}

## Why buy() refused (OK means it did not).
const OK := ""
const NOT_ENOUGH_COINS := "not_enough_coins"
const MAXED := "maxed"
const UNKNOWN_UPGRADE := "unknown_upgrade"

## Emitted after coins or levels change (and were saved).
signal changed

var coins: int = 0
var levels: Dictionary = {}  # upgrade id -> level
var garage: GarageData
## Where the last load came from: "main", "backup" or "none" (a new player), and the
## save's version (a file without one is version 1). T-417.
var loaded_from: String = "none"
var loaded_version: int = 1
var _path: String


func _init(garage_data: GarageData = null, save_path: String = "") -> void:
	garage = garage_data if garage_data != null else GarageData.new()
	_path = save_path if save_path != "" else path
	load_from_disk()


func _reset() -> void:
	coins = 0
	levels = {}
	for id in GarageData.UPGRADES:
		levels[id] = 0


## Reads the save file (SafeSave: a broken file is kept aside and the backup is loaded;
## neither: a new player). Returns true if a save was read.
func load_from_disk() -> bool:
	_reset()
	var res := SafeSave.read(_path, "coins")
	loaded_from = res["source"]
	loaded_version = res["version"]
	if loaded_from == "none":
		return false
	var parsed: Dictionary = res["data"]
	coins = maxi(0, int(parsed.get("coins", 0)))
	var saved: Variant = parsed.get("levels", {})
	if typeof(saved) != TYPE_DICTIONARY:
		saved = {}
	saved = _map_old_ids(saved, loaded_version)
	for id in GarageData.UPGRADES:
		levels[id] = clampi(int(saved.get(id, 0)), 0, garage.max_level())
	return true


## Maps the ids of an older save to today's: ID_RENAMES[version] is {old id: new id} for
## a save written at that version or earlier. Levels already under the new id win.
static func _map_old_ids(saved: Dictionary, version: int, renames: Dictionary = ID_RENAMES) -> Dictionary:
	var out := saved.duplicate()
	for v in renames:
		if version > int(v):
			continue
		for old_id in renames[v]:
			if out.has(old_id):
				var new_id: String = renames[v][old_id]
				if not out.has(new_id):
					out[new_id] = out[old_id]
				out.erase(old_id)
	return out


## Writes the save file safely (temp file, rename, backup; SafeSave). Returns true on success.
func save() -> bool:
	return SafeSave.write(_path, {"coins": coins, "levels": levels}, "coins")


## The coin total.
func get_coins() -> int:
	return coins


## The upgrade's current level (0 = not bought).
func level(upgrade: String) -> int:
	return int(levels.get(upgrade, 0))


func is_maxed(upgrade: String) -> bool:
	return level(upgrade) >= garage.max_level()


## The price of the next level, or -1 when maxed.
func next_price(upgrade: String) -> int:
	if is_maxed(upgrade):
		return -1
	return garage.price(upgrade, level(upgrade) + 1)


## The effect (stat value) at the current level; level 0 is the base value.
func current_value(upgrade: String) -> float:
	return garage.value(upgrade, level(upgrade))


## The effect (stat value) once the next level is bought, or -1.0 when maxed.
func next_value(upgrade: String) -> float:
	if is_maxed(upgrade):
		return -1.0
	return garage.value(upgrade, level(upgrade) + 1)


## Everything the garage screen shows for one upgrade.
func info(upgrade: String) -> Dictionary:
	return {
		"id": upgrade,
		"level": level(upgrade),
		"max_level": garage.max_level(),
		"maxed": is_maxed(upgrade),
		"next_price": next_price(upgrade),
		"current_value": current_value(upgrade),
		"next_value": next_value(upgrade),
		"can_buy": can_buy(upgrade) == OK,
	}


## OK ("") if the upgrade can be bought now, else the reason: MAXED, NOT_ENOUGH_COINS
## or UNKNOWN_UPGRADE.
func can_buy(upgrade: String) -> String:
	if not levels.has(upgrade):
		return UNKNOWN_UPGRADE
	if is_maxed(upgrade):
		return MAXED
	if coins < next_price(upgrade):
		return NOT_ENOUGH_COINS
	return OK


## Buys the upgrade's next level: spends the price, raises the level, saves.
## Returns {"ok": bool, "reason": OK or a refusal reason}. A refusal changes nothing.
func buy(upgrade: String) -> Dictionary:
	var reason := can_buy(upgrade)
	if reason != OK:
		return {"ok": false, "reason": reason}
	coins -= next_price(upgrade)
	levels[upgrade] = level(upgrade) + 1
	save()
	changed.emit()
	return {"ok": true, "reason": OK}


## Adds a finished run's coins (win or loss) to the total and saves.
## This is the handler for RunState.run_ended(result, coins); see connect_run().
func bank_run(_result: String, run_coins: int) -> void:
	coins += maxi(0, run_coins)
	save()
	changed.emit()


## Banks the run's coins when its state emits run_ended.
func connect_run(state: Object) -> void:
	state.run_ended.connect(bank_run)
