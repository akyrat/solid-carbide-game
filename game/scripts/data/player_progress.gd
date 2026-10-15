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


## Reads the save file. Missing or broken file: a new player. Returns true if a file was read.
func load_from_disk() -> bool:
	_reset()
	if not FileAccess.file_exists(_path):
		return false
	var f := FileAccess.open(_path, FileAccess.READ)
	if f == null:
		return false
	var json := JSON.new()
	if json.parse(f.get_as_text()) != Error.OK:
		return false
	var parsed: Variant = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	coins = maxi(0, int(parsed.get("coins", 0)))
	var saved: Variant = parsed.get("levels", {})
	if typeof(saved) != TYPE_DICTIONARY:
		saved = {}
	for id in GarageData.UPGRADES:
		levels[id] = clampi(int(saved.get(id, 0)), 0, garage.max_level())
	return true


## Writes the save file. Returns true on success.
func save() -> bool:
	var f := FileAccess.open(_path, FileAccess.WRITE)
	if f == null:
		push_error("Could not write the save file %s" % _path)
		return false
	f.store_string(JSON.stringify({"coins": coins, "levels": levels}, "\t"))
	return true


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
