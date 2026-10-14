class_name RunState
extends Node
## The run's state (task T-036): the 8-minute clock, the car's health, the
## coins collected this run, and win and loss (Game loop architecture,
## Decisions). Task T-037 adds likes (XP) and levels: from completed
## challenges and from drifting, with level-ups and the level-up pause switch.
## Task T-081 adds the combo: tricks raise a multiplier on all XP gained,
## collisions (and damage to the car) cut it, and it drains when no trick
## follows in time (numbers: res://data/combo.json, ComboData). Task T-115
## adds the likes drain: once the combo is back at "no combo", the XP in the
## current level slowly goes down, never below 0, so the level never goes
## down (numbers: res://data/run.json's likes_drain, RunData). Other agents'
## work plugs in through the signals and public
## functions below; game/README.md, "The run", lists them.
##
## The clock counts down in _process, so it stops whenever the scene tree is
## paused (this node uses the default, pausable process mode). advance() moves
## it by hand, for tests.
##
## The run's length and the boss's arrival are Game loop architecture,
## Decisions ("A run lasts 8 minutes", "At the 7-minute mark the kaiju
## spawns"), not balancing numbers, so they are constants here. The car's
## starting health and the XP numbers come from res://data/run.json (RunData).

## The run lasts 8 minutes.
const RUN_SECONDS := 480.0
## The kaiju arrives when 7 minutes have passed (1:00 left).
const BOSS_TIME_LEFT := 60.0

## Clock comparisons allow this much rounding error from summing frame times.
const EPSILON := 0.000001

const RESULT_WIN := "win"
const RESULT_LOSS := "loss"

const TrickDetector := preload("res://scripts/driving/trick_detector.gd")

## A fresh run has started (start_run). Every value is back at its start.
signal run_started
## 7 minutes have passed: the Enemy Behavior Agent spawns the kaiju on this.
## Fires once per run.
signal boss_time
## The run is over. `result` is "win" or "loss"; `coins` is this run's total,
## kept either way. Fires once per run.
signal run_ended(result: String, coins: int)
## The time left changed to a different whole second (what a clock shows).
## `seconds_left` is the exact time left; time_left_text() formats it.
signal time_left_changed(seconds_left: float)
## The car took damage (T-072: the car damage effect plays on it).
signal car_damaged(amount: float)
## The car's health changed (damage, or a new run).
signal health_changed(health: float, max_health: float)
## The coins collected this run changed.
signal coins_changed(coins: int)
## XP or the level changed (XP gained, a level-up, or a new run). For the
## HUD's likes bar: `xp` out of `xp_needed` (0 at the top level), at `level`.
signal xp_changed(xp: float, xp_needed: float, level: int)
## A challenge (preset or meteor) was completed: `amount` is the XP (likes)
## it gave, for the challenge popup (T-092).
signal score(amount: float, challenge_id: String)
## The player reached `new_level`. Fires once per level, even when one gain
## gives several level-ups.
signal level_up(new_level: int)
## The switch is on and the run is now paused for the weapon choice of
## `new_level` (T-052 opens its screen on this). With several level-ups at
## once, it fires again for the next level after each choice_made().
signal level_up_choice_started(new_level: int)
## The weapon choice for `new_level` was made (choice_made()).
signal level_up_choice_made(new_level: int)
## A trick raised the combo (T-081): `trick_id` is the car's trick, `added`
## how much the multiplier went up (the data's amount, less if the cap was
## reached), `multiplier` the new value. For the trick popups (T-083).
signal combo_trick(trick_id: String, added: float, multiplier: float)
## The combo multiplier changed (a trick, a collision, the drain, or a new
## run). For the HUD's combo counter (T-083) and enemy spawning (T-085).
signal combo_changed(multiplier: float)

## Seconds left on the clock (RUN_SECONDS at the start, 0 at the end).
var time_left := RUN_SECONDS
var health := 0.0
var max_health := 0.0
## Coins collected this run.
var coins := 0
## XP (shown to players as likes) toward the next level, after leftovers.
var xp := 0.0
## The level now, 1 at the start of a run.
var level := 1
## The level-up pause switch (T-052 turns it on). Off: a level-up just raises
## the level and the run carries on. On: a level-up pauses the run (the scene
## tree, so the clock and the car stop) until choice_made() is called.
var pause_on_level_up := false
## Seconds the current unbroken drift has lasted (0 when not drifting).
var drift_seconds := 0.0
## Full drift seconds of the current drift already turned into XP.
var drift_seconds_paid := 0
## Levels reached whose weapon choice has not been made yet, oldest first.
## The first one is the choice on show. Only used while the switch is on.
var pending_choices: Array[int] = []
## True from start_run() until the run ends.
var running := false
## "" while the run is going (or before the first one), then "win" or "loss".
var result := ""
var boss_time_sent := false
## The combo multiplier now (T-081): multiplies all XP gained. combo.json's
## start_multiplier (1.0, no combo) at the start of a run.
var combo := 1.0
## Seconds since the last trick (or since the run started). The combo drains
## once this passes combo.json's drain_wait_seconds.
var combo_idle := 0.0
## Seconds the combo has been back at "no combo" (T-115). The likes drain runs
## once this passes run.json's likes_drain extra_wait_seconds; a trick resets it.
var likes_drain_idle := 0.0

var _run_data: RunData
var _combo_data: ComboData


func _init(run_data: RunData = null, combo_data: ComboData = null) -> void:
	_run_data = run_data
	_combo_data = combo_data


## Starts a fresh run from the start: full health, 8:00, 0 coins.
func start_run() -> void:
	if _run_data == null:
		_run_data = RunData.new()
	if _combo_data == null:
		_combo_data = ComboData.new()
	max_health = _run_data.starting_health()
	health = max_health
	time_left = RUN_SECONDS
	coins = 0
	result = ""
	boss_time_sent = false
	xp = 0.0
	level = 1
	drift_seconds = 0.0
	drift_seconds_paid = 0
	combo = _combo_data.start_multiplier()
	combo_idle = 0.0
	likes_drain_idle = 0.0
	var was_waiting := not pending_choices.is_empty()
	pending_choices.clear()
	if was_waiting:
		_set_paused(false)
	running = true
	run_started.emit()
	time_left_changed.emit(time_left)
	health_changed.emit(health, max_health)
	coins_changed.emit(coins)
	xp_changed.emit(xp, xp_needed(), level)
	combo_changed.emit(combo)


func _process(delta: float) -> void:
	advance(delta)


## Moves the clock forward by `seconds`. Does nothing once the run has ended.
func advance(seconds: float) -> void:
	if not running or seconds <= 0.0:
		return
	var shown_before := shown_seconds()
	time_left -= seconds
	if time_left <= EPSILON:
		time_left = 0.0
	if shown_seconds() != shown_before:
		time_left_changed.emit(time_left)
	_drain_combo(seconds)
	_drain_likes(seconds)
	if not boss_time_sent and time_left <= BOSS_TIME_LEFT + EPSILON:
		boss_time_sent = true
		boss_time.emit()
	if time_left <= 0.0 and running:
		# The clock ran out: the kaiju is still alive, or the run would have
		# ended already when it was killed.
		_end(RESULT_LOSS)


## Seconds into the run.
func time_elapsed() -> float:
	return RUN_SECONDS - time_left


## The time left in whole seconds, rounded up, as a clock shows it
## (8:00 at the start, 0:01 in the last second).
func shown_seconds() -> int:
	return int(ceil(time_left - EPSILON)) if time_left > 0.0 else 0


## The time left as M:SS, for example "8:00" or "0:59".
func time_left_text() -> String:
	var s := shown_seconds()
	return "%d:%02d" % [s / 60, s % 60]


## Damages the car by `amount` (enemies call this). At 0 health the run ends
## as a loss. Ignored when the run is not going or `amount` is not positive.
func damage_car(amount: float) -> void:
	if not running or amount <= 0.0:
		return
	# Enemies and meteors damage the car by hitting it: any damage counts as
	# a collision and cuts the combo (Game loop architecture, Decisions).
	collision()
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	car_damaged.emit(amount)
	if health <= 0.0:
		_end(RESULT_LOSS)


## Adds coins collected this run. Ignored when the run is not going or
## `amount` is not positive.
func add_coins(amount: int) -> void:
	if not running or amount <= 0:
		return
	coins += amount
	coins_changed.emit(coins)


## The kaiju was killed: the run ends at once, as a win. Ignored when the run
## is not going.
func kaiju_killed() -> void:
	if not running:
		return
	_end(RESULT_WIN)


func is_running() -> bool:
	return running


## XP needed to go from the current level to the next (0 at the top level).
func xp_needed() -> float:
	return _run_data.xp_needed(level) if _run_data != null else 0.0


## True at the top level (run.json's max_level): the bar stops filling.
func is_max_level() -> bool:
	return _run_data != null and level >= _run_data.max_level()


## A challenge was completed (the map's challenge_completed or
## meteor_challenge_completed; the run scene connects both). Gives the current
## level's challenge XP and sends `score` with it. Ignored when the run is
## not going.
func challenge_completed(challenge_id: String = "") -> void:
	if not running:
		return
	var amount := _run_data.challenge_xp(level) * combo
	score.emit(amount, challenge_id)
	_gain_xp(amount)


## Feeds the car's drift state for one physics step of `delta` seconds (the
## run scene calls it after every car step). Once an unbroken drift reaches
## 1 second, it gives the drift XP for that first second, then for each
## further full second (a 3-second drift gives 3 seconds' worth; 0.9 s gives
## none). A step without drifting ends the drift.
func drift_step(drifting: bool, delta: float) -> void:
	if not running:
		return
	if not drifting:
		drift_seconds = 0.0
		drift_seconds_paid = 0
		return
	drift_seconds += delta
	var full := int(floor(drift_seconds + EPSILON))
	if full > drift_seconds_paid:
		var seconds := full - drift_seconds_paid
		drift_seconds_paid = full
		add_xp(_run_data.drift_xp_per_second() * seconds)


## The car did a trick (the run scene connects the car's `trick` signal): the
## combo goes up by the trick's amount in combo.json, held at the cap, and the
## drain wait starts again. Sends combo_trick, then combo_changed. Ignored
## when the run is not going, and for an id that is not one of the car's
## tricks (TrickDetector.TRICK_IDS).
func add_trick(trick_id: String) -> void:
	if not running or not TrickDetector.TRICK_IDS.has(trick_id):
		return
	var before := combo
	combo = _combo_data.after_trick(combo, trick_id)
	combo_idle = 0.0
	likes_drain_idle = 0.0
	combo_trick.emit(trick_id, combo - before, combo)
	if combo != before:
		combo_changed.emit(combo)


## The car collided with something (the run scene connects the car's
## `hit_obstacle`; damage_car() calls it too): the combo is cut as combo.json
## says (80% of the part above the start value). Ignored when the run is not
## going.
func collision() -> void:
	if not running:
		return
	_set_combo(_combo_data.after_collision(combo))


## How much the minion spawn rate is multiplied at the current combo
## (combo.json's spawning; 1.0 with no combo). For enemy spawning (T-085).
func combo_spawn_multiplier() -> float:
	return _combo_data.spawn_multiplier(combo) if _combo_data != null else 1.0


func _drain_combo(seconds: float) -> void:
	var before_idle := combo_idle
	combo_idle += seconds
	var wait := _combo_data.drain_wait_seconds()
	var draining := maxf(combo_idle - wait, 0.0) - maxf(before_idle - wait, 0.0)
	if draining > 0.0:
		_set_combo(maxf(combo - draining * _combo_data.drain_per_second(),
				_combo_data.start_multiplier()))


## True when the combo is at "no combo" (combo.json's start_multiplier).
func has_no_combo() -> bool:
	return combo <= _combo_data.start_multiplier() + EPSILON


## True while the likes drain is taking XP away: the combo is at "no combo",
## the extra wait has passed, there is XP in the current level to lose, and
## no weapon choice is waiting. Not at the top level (its bar is always empty).
func is_likes_draining() -> bool:
	if not running or not has_no_combo() or is_waiting_for_choice() or is_max_level():
		return false
	if xp <= 0.0 or _run_data.likes_drain_xp_per_second(level) <= 0.0:
		return false
	return likes_drain_idle >= _run_data.likes_drain_extra_wait_seconds() - EPSILON


## The likes drain (T-115; Game loop architecture, Decisions, "Likes drain"):
## while the combo is at "no combo", after run.json's extra wait, XP in the
## current level goes down at RunData.likes_drain_xp_per_second(level),
## stopping at 0: the level never goes down. A trick raises the combo, which
## stops it. advance() runs only while the run is going and the tree is not
## paused, so there is no drain while paused or after the run ends; it also
## skips while a level-up's weapon choice is waiting. Sends xp_changed for
## the HUD's likes bar whenever XP goes down.
func _drain_likes(seconds: float) -> void:
	if not has_no_combo():
		likes_drain_idle = 0.0
		return
	var before_idle := likes_drain_idle
	likes_drain_idle += seconds
	if not running or is_waiting_for_choice() or is_max_level() or xp <= 0.0:
		return
	var wait := _run_data.likes_drain_extra_wait_seconds()
	var draining := maxf(likes_drain_idle - wait, 0.0) - maxf(before_idle - wait, 0.0)
	var rate := _run_data.likes_drain_xp_per_second(level)
	if draining <= 0.0 or rate <= 0.0:
		return
	xp = maxf(xp - draining * rate, 0.0)
	if xp < EPSILON:
		xp = 0.0
	xp_changed.emit(xp, xp_needed(), level)


func _set_combo(value: float) -> void:
	if value == combo:
		return
	combo = value
	combo_changed.emit(combo)


## Adds `amount` XP gained by driving, multiplied by the combo (Game loop
## architecture, Decisions: the multiplier multiplies all XP gained).
## Ignored when the run is not going or `amount` is not positive.
func add_xp(amount: float) -> void:
	_gain_xp(amount * combo)


## Adds `amount` XP, already multiplied by the combo. Each time it reaches
## the level's threshold the player levels up (level_up fires per level); leftover XP carries over if run.json
## says so. At the top level XP no longer adds up. Ignored when the run is
## not going or `amount` is not positive.
func _gain_xp(amount: float) -> void:
	if not running or amount <= 0.0 or is_max_level():
		return
	xp += amount
	var reached: Array[int] = []
	while not is_max_level() and xp >= xp_needed() - EPSILON:
		xp = maxf(xp - xp_needed(), 0.0) if _run_data.carries_over() else 0.0
		level += 1
		reached.append(level)
	if is_max_level():
		xp = 0.0
	xp_changed.emit(xp, xp_needed(), level)
	for l in reached:
		level_up.emit(l)
		if pause_on_level_up:
			pending_choices.append(l)
			if pending_choices.size() == 1:
				_start_choice()


## True while the run is paused waiting for a level-up's weapon choice.
func is_waiting_for_choice() -> bool:
	return not pending_choices.is_empty()


## The level whose weapon choice is on show, or 0 when none is.
func choice_level() -> int:
	return pending_choices[0] if not pending_choices.is_empty() else 0


## The player made the weapon choice on show (T-052 calls it). The next
## waiting level-up's choice starts, or, if none is left, the run resumes.
## Ignored when no choice is waiting.
func choice_made() -> void:
	if pending_choices.is_empty():
		return
	var done: int = pending_choices.pop_front()
	level_up_choice_made.emit(done)
	if pending_choices.is_empty():
		_set_paused(false)
	else:
		_start_choice()


func _start_choice() -> void:
	_set_paused(true)
	level_up_choice_started.emit(pending_choices[0])


func _set_paused(paused: bool) -> void:
	if is_inside_tree():
		get_tree().paused = paused


func _end(r: String) -> void:
	running = false
	result = r
	run_ended.emit(r, coins)
