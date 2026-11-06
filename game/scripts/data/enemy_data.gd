class_name EnemyData
extends RefCounted
## The enemy numbers from res://data/enemies.json: the minion, minion spawning, coin drops,
## the kaiju, its coins when defeated and its meteor attack. Enemy stats never change over a run; only how
## often minions spawn grows (spawn_interval, T-443).

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
		if not String(k).begins_with("_") and not (sec[k] is Dictionary):
			out[k] = float(sec[k])
	return out


## health, move_speed, contact_damage (hearts, 1), knockback.
func minion() -> Dictionary:
	return _section("minion")


## T-531 (Enemies, Decisions, "Minion deaths"): the minion's death, corpse and green spill
## numbers (enemies.json, minion > death), all floats; empty when the block is missing.
func minion_death() -> Dictionary:
	var sec = _data.get("minion", {}).get("death", {})
	var out := {}
	if sec is Dictionary:
		for k in sec:
			if not String(k).begins_with("_"):
				out[k] = float(sec[k])
	return out


## spawn_interval_at_start_seconds, spawn_interval_at_boss_time_seconds, growth_until_seconds,
## max_minions_alive, spawn_margin_units (T-443).
func spawning() -> Dictionary:
	return _section("spawning")


## drop_chance (0 to 1), coins_per_drop.
func coins() -> Dictionary:
	return _section("coins")


## Health pickups a killed minion drops (T-220): drop_chance (0 to 1), restore_hearts
## (how many hearts one pickup restores, 1).
func health_drops() -> Dictionary:
	return _section("health_drops")


## health, move_speed, contact_damage (hearts, 2), knockback.
func kaiju() -> Dictionary:
	return _section("kaiju")


## The kaiju's coins when defeated (T-119): drop_chance (1, always), coins_per_drop.
func kaiju_coins() -> Dictionary:
	return _section("kaiju_coins")


## Coins the defeated kaiju adds to the run's coins: coins_per_drop when its drop chance is 1
## (the board's decision: always). Below 1 it is the average, rounded to the nearest coin.
func kaiju_coins_on_defeat() -> int:
	var c := kaiju_coins()
	return roundi(c["drop_chance"] * c["coins_per_drop"])


## first_attack_after_seconds, seconds_between_attacks, windup_seconds, meteors_per_attack,
## warning_seconds, land_within_units_of_car, impact_radius_units, impact_damage (hearts, 1), minion_damage (a minion's health points lost, T-418), knockback.
## T-539: pair_distance_units, pair_damage_to_kaiju (the paired meteors).
func meteor_attack() -> Dictionary:
	return _section("meteor_attack")


## Seconds between minion spawns `run_seconds` after the run started (T-443): the spawn rate
## (1 / interval) grows in a straight line from 1 / spawn_interval_at_start_seconds at second 0 to
## 1 / spawn_interval_at_boss_time_seconds at growth_until_seconds, then is held. `spawn_multiplier`
## is the combo's (ComboData.spawn_multiplier), 1.0 for none: it multiplies the rate, so it divides
## the interval. Returns 0 when the data's intervals or the multiplier are not above 0 (the caller
## falls back to its default).
func spawn_interval(run_seconds: float, spawn_multiplier: float = 1.0) -> float:
	return interval_from(spawning(), run_seconds, spawn_multiplier)


## spawn_interval() from a spawning section `s` (the spawner passes its own copy, so tests can swap it).
static func interval_from(s: Dictionary, run_seconds: float, spawn_multiplier: float = 1.0) -> float:
	var a: float = s.get("spawn_interval_at_start_seconds", 0.0)
	var b: float = s.get("spawn_interval_at_boss_time_seconds", 0.0)
	var until: float = s.get("growth_until_seconds", 0.0)
	if a <= 0.0 or b <= 0.0 or spawn_multiplier <= 0.0:
		return 0.0
	var t := clampf(run_seconds / until, 0.0, 1.0) if until > 0.0 else 1.0
	var rate := lerpf(1.0 / a, 1.0 / b, t) * spawn_multiplier
	return 1.0 / rate


## The safety ceiling on minions alive at once (T-443): while this many are alive, no new one spawns.
## 0 when the data has none (no ceiling).
func max_minions_alive() -> int:
	return int(spawning().get("max_minions_alive", 0.0))


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
	var gap: float = m["seconds_between_attacks"]
	if gap <= 0.0:
		# T-418: a gap of 0 or less would loop forever. Report it and count the one first attack.
		push_error("enemies.json meteor_attack.seconds_between_attacks must be above 0 (got %s): only the first attack is counted" % gap)
		if t < fight_seconds:
			times.append(t)
		return times
	while t < fight_seconds:
		times.append(t)
		t += gap
	return times
