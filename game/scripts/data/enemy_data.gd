class_name EnemyData
extends RefCounted
## The enemy numbers from res://data/enemies.json: the minion, minion spawning, coin drops,
## the kaiju and its meteor attack. Enemy stats never change over a run; only the number
## of minions the spawner keeps around grows (minions_wanted).

var _data: Dictionary = {}
var error: String = ""


func _init(file: String = "enemies") -> void:
	var r := GameData.load_file(file)
	if r.ok:
		_data = r.data
	else:
		error = r.error


func is_ok() -> bool:
	return error == ""


## A section as floats, without its "_comment".
func _section(name: String) -> Dictionary:
	var out := {}
	if not _data.has(name):
		push_error("Game data value missing: '%s' in enemies.json" % name)
		return out
	var sec: Dictionary = _data[name]
	for k in sec:
		if not String(k).begins_with("_"):
			out[k] = float(sec[k])
	return out


## health, move_speed, contact_damage, contact_damage_interval, knockback.
func minion() -> Dictionary:
	return _section("minion")


## minions_at_start, minions_at_boss_time, growth_until_seconds, spawn_interval_seconds, spawn_margin_units.
func spawning() -> Dictionary:
	return _section("spawning")


## drop_chance (0 to 1), coins_per_drop.
func coins() -> Dictionary:
	return _section("coins")


## health, move_speed, contact_damage, contact_damage_interval, knockback.
func kaiju() -> Dictionary:
	return _section("kaiju")


## first_attack_after_seconds, seconds_between_attacks, windup_seconds, meteors_per_attack,
## warning_seconds, land_within_units_of_car, impact_radius_units, impact_damage, knockback.
func meteor_attack() -> Dictionary:
	return _section("meteor_attack")


## How many minions the spawner keeps around `run_seconds` after the run started: a straight
## line from minions_at_start to minions_at_boss_time, then held. `spawn_multiplier` is the
## combo's (ComboData.spawn_multiplier), 1.0 for none. Rounded to the nearest whole minion.
func minions_wanted(run_seconds: float, spawn_multiplier: float = 1.0) -> int:
	var s := spawning()
	var t := clampf(run_seconds / s["growth_until_seconds"], 0.0, 1.0)
	var count := lerpf(s["minions_at_start"], s["minions_at_boss_time"], t)
	return roundi(count * spawn_multiplier)


## Coins one killed minion drops on average (drop chance times coins per drop).
func expected_coins_per_kill() -> float:
	var c := coins()
	return c["drop_chance"] * c["coins_per_drop"]


## When the meteor attacks start (warning circles appear after the windup), in seconds after
## the kaiju appeared, for attacks that start within `fight_seconds`.
func meteor_attack_times(fight_seconds: float) -> Array:
	var m := meteor_attack()
	var times: Array = []
	var t: float = m["first_attack_after_seconds"]
	while t < fight_seconds:
		times.append(t)
		t += m["seconds_between_attacks"]
	return times
