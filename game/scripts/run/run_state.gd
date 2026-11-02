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
## functions below; game/docs/game-loop/the-run.md, "The run", lists them.
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
## Why a run was lost (the recap's "loss_reason"): the clock ran out, or the last heart went.
const LOSS_TIME := "time"
const LOSS_HEALTH := "health"

const TrickDetector := preload("res://scripts/driving/trick_detector.gd")
const RunMissionsScript := preload("res://scripts/run/missions.gd")

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
## The car took damage (T-072: the car sprite shakes).
signal car_damaged(amount: float)
## The car's health changed (damage, or a new run). In hearts since T-334.
signal health_changed(health: float, max_health: float)
## The car's invulnerability after a hit started (T-334): `seconds` long. For the blink.
signal invulnerability_started(seconds: float)
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
## A crash cut a combo that was going (T-245): a collision or any damage took
## the multiplier down (not the drain, and not when there was no combo to cut).
## For the combo broken popup.
signal combo_broken
## The car crashed (task T-315): a collision or any damage, while the run is
## going, whether or not there was a combo to cut. The run scene pays the
## car's trick in progress on it (car.gd settle_tricks(): a drift so far pays
## its LONG DRIFT!). With combo.json's crash_pays_trick_first (the default) it
## fires before the cut, so the trick's popup comes just before COMBO BROKEN!;
## otherwise just after the cut.
signal crashed
## The car lost its last heart (T-360; Game loop architecture, Decisions,
## "Wrecked: the stream keeps rolling" and, T-413, "The wreck decides the loss at
## its end"): the clock stops and likes, tricks, damage and the gift packs stop
## counting, but the result is not decided yet: during these `seconds` the car
## slides on with dead controls, smoking and burning, coins and health pickups
## still count, a health pickup revives the car (revive()) and a kaiju kill wins.
## When they are over the run is lost (result "loss", loss_reason "health") and
## run_ended follows. The run scene turns the car's input off, drops the trick
## in progress and starts the smoke and flames on it.
signal wreck_started(seconds: float)
## A health pickup revived the wrecked car (T-406): back with 1 heart, the run
## goes on, run_ended does not come. The run scene gives the controls back and
## stops the smoke and flames.
signal revived
## Hearts a revived car comes back with (the board: "one life").
const REVIVE_HEARTS := 1.0
## The timer ran out with the kaiju alive (T-317; Game loop architecture,
## Decisions, "Time's up screen"): the run is lost from this moment (result
## "loss", loss_reason "time", nothing more counts) and frozen (the scene tree
## is paused) while the time's up screen plays for `seconds`; run_ended follows
## when they are over.
signal time_up_started(seconds: float)
## The car's owned driving power-ups changed (T-457): one was granted, or a new run cleared
## them. Read them with power_up_tier() or owned_power_ups().
signal power_ups_changed

## The run's missions (T-457; RunMissions in missions.gd): the same object for every run of
## this state, so connect its signals once (goal_progress, goal_completed, mission_completed,
## mission_started). start_run() gives it a fresh set; the tricks below feed it.
var missions: RunMissions
## The seed for the next run's generated missions; negative (the default) picks a new one
## each run. Tests set it.
var mission_seed := -1
## Owned driving power-ups (T-457): id -> tier (1 to the power-up's last tier).
var _power_ups := {}
var _power_up_data: PowerUpData = null

## Seconds left on the clock (RUN_SECONDS at the start, 0 at the end).
var time_left := RUN_SECONDS
## The car's health in hearts (T-334; Game loop architecture, Decisions, "Hearts
## instead of health points"): run.json's car.starting_hearts, plus the car health
## upgrade's hearts. Kept as a number named health, so everything that read the old
## health (the HUD, the run's end) keeps working; `hearts` and `max_hearts` read it.
var health := 0.0
var max_health := 0.0
## The car's health in whole hearts (the same as health).
var hearts: int:
	get:
		return int(round(health))
var max_hearts: int:
	get:
		return int(round(max_health))
## Seconds of invulnerability left after the last hit (T-334): while above 0,
## damage_car() does nothing at all, and the enemies neither hit nor knock back
## the car. Counts down in advance(), with the clock.
var invulnerable_left := 0.0
## The full length of the current invulnerability (run.json's car.invulnerability_seconds),
## for the blink's phase.
var invulnerable_total := 0.0
## Coins collected this run.
var coins := 0
## The pickup magnet's reach in units (run.json's pickup_magnet; the garage upgrade, T-224, sets it
## when a run starts). Read by pickup_magnet.gd every step; a test can change it.
var pickup_magnet_radius_units := 3.0
## How fast pickups inside the reach fly to the car, units per second (run.json).
var pickup_pull_speed := 30.0
## XP (shown to players as likes) toward the next level, after leftovers.
var xp := 0.0
## The level now, 1 at the start of a run.
var level := 1
## The level-up pause switch. Off: a level-up just raises the level and the
## run carries on; since T-144 the run scene keeps it off and the gift pack
## (gift_drops.gd) calls open_choice() when the car drives over the package.
## On (tests and tools): a level-up pauses the run (the scene tree, so the
## clock and the car stop) at once until choice_made() is called.
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
## "time" or "health" after a loss (LOSS_*), "" otherwise.
var loss_reason := ""
var boss_time_sent := false
## The wreck (T-360): true from the last heart until run_ended (or a revive, or a
## kaiju kill), `wreck_left` seconds still to go. The result stays "" (T-413). `wreck_seconds` is run.json's wreck.seconds, set at
## start_run(); tests may change it (0 ends the run at once, as before T-360).
var wrecked := false
var wreck_left := 0.0
var wreck_seconds := 3.0
## The time's up hold (T-317): true from 0:00 until run_ended, `time_up_left`
## seconds still to go. `time_up_seconds` is run.json's time_up.seconds, set at
## start_run(); tests may change it (0 ends the run at once, as before T-317).
var timed_out := false
var time_up_left := 0.0
var time_up_seconds := 3.0
## The physics and process frame the clock reached 0:00 on (T-413, "A tie goes to
## the player"): a kaiju kill in that same step still wins.
var _time_up_physics_frame := -1
var _time_up_process_frame := -1
## The combo multiplier now (T-081): multiplies all XP gained. combo.json's
## start_multiplier (1.0, no combo) at the start of a run.
var combo := 1.0
## Seconds since the last trick (or since the run started). The combo drains
## once this passes combo.json's drain_wait_seconds.
var combo_idle := 0.0
## Seconds the combo has been back at "no combo" (T-115). The likes drain runs
## once this passes run.json's likes_drain extra_wait_seconds; a trick resets it.
var likes_drain_idle := 0.0

## The player's saved upgrades (T-061), or null (a run on its own): the car's
## starting and maximum health use the car health upgrade's current level.
var progress: PlayerProgress = null

## The run's stats for the recap (T-319); read them through recap().
var _slain := {}  # enemy type -> kills
var _tricks_done := {}  # trick id -> times completed
var _weapon_kills := {}  # weapon id -> kills
var _highest_combo := 1.0
## When the combo was last cut by a collision, in seconds into the run (T-415).
var _last_cut_at := -1000.0
var _likes_total := 0.0
## Set by the weapon rack (weapons.gd bind): returns {weapon id: tier} for the
## weapons the car owns now. Empty Callable when no rack is bound.
var weapons_source := Callable()
## The recap as it stood when the run ended (empty while a run is going).
var _final_recap := {}

var _run_data: RunData
var _combo_data: ComboData


func _init(run_data: RunData = null, combo_data: ComboData = null) -> void:
	_run_data = run_data
	_combo_data = combo_data
	missions = RunMissionsScript.new()


## Starts a fresh run from the start: full health, 8:00, 0 coins.
func start_run() -> void:
	if _run_data == null:
		_run_data = RunData.new()
	if _combo_data == null:
		_combo_data = ComboData.new()
	max_health = _run_data.starting_hearts()
	pickup_magnet_radius_units = _run_data.pickup_magnet_radius_units()
	pickup_pull_speed = _run_data.pickup_pull_speed_units_per_second()
	if progress != null:
		# T-415: the garage adds to run.json's base (read here, not the garage's copy).
		var g: GarageData = progress.garage
		max_health += g.bonus("car_health", progress.level("car_health"))
		pickup_magnet_radius_units += g.bonus("pickup_magnet", progress.level("pickup_magnet"))  # garage upgrade (T-224)
	health = max_health
	_last_cut_at = -1000.0
	invulnerable_left = 0.0
	invulnerable_total = 0.0
	time_left = RUN_SECONDS
	coins = 0
	result = ""
	loss_reason = ""
	wrecked = false
	wreck_left = 0.0
	wreck_seconds = _run_data.wreck_seconds()
	if timed_out:  # a new run during the time's up screen: unfreeze first
		process_mode = Node.PROCESS_MODE_INHERIT
		_set_paused(false)
	timed_out = false
	time_up_left = 0.0
	time_up_seconds = _run_data.time_up_seconds()
	_slain = {}
	_tricks_done = {}
	_weapon_kills = {}
	_final_recap = {}
	_likes_total = 0.0
	boss_time_sent = false
	xp = 0.0
	level = 1
	drift_seconds = 0.0
	drift_seconds_paid = 0
	combo = _combo_data.start_multiplier()
	combo_idle = 0.0
	likes_drain_idle = 0.0
	_highest_combo = combo
	var was_waiting := not pending_choices.is_empty()
	pending_choices.clear()
	if was_waiting:
		_set_paused(false)
	running = true
	missions.start(mission_seed)  # T-457: back to mission 1, a fresh set
	_power_ups = {}
	run_started.emit()
	power_ups_changed.emit()
	time_left_changed.emit(time_left)
	health_changed.emit(health, max_health)
	coins_changed.emit(coins)
	xp_changed.emit(xp, xp_needed(), level)
	combo_changed.emit(combo)


func _process(delta: float) -> void:
	Perf.begin(&"run.clock")
	advance(delta)
	Perf.end(&"run.clock")


## Moves the clock forward by `seconds`. Does nothing once the run has ended.
## During the wreck (T-360) it counts the wreck down instead: the clock is
## stopped at the moment the last heart went, and run_ended follows when the
## wreck's seconds are over. Pausing the tree stops both (_process).
func advance(seconds: float) -> void:
	if wrecked:
		_advance_wreck(seconds)
		return
	if timed_out:
		_advance_time_up(seconds)
		return
	if not running or seconds <= 0.0:
		return
	invulnerable_left = maxf(invulnerable_left - seconds, 0.0)
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
		# ended already when it was killed. The time's up screen plays first (T-317).
		_time_up()


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


## Damages the car by `amount` hearts (enemies call this). At 0 hearts the run
## ends as a loss. Ignored when the run is not going, `amount` is not positive,
## or the car is still invulnerable from the last hit (T-334: a hit inside that
## second takes no hearts and does not cut the combo). A hit that counts starts
## run.json's car.invulnerability_seconds of invulnerability.
func damage_car(amount: float) -> void:
	if not running or amount <= 0.0 or is_invulnerable():
		return
	# Enemies and meteors damage the car by hitting it: any damage counts as
	# a collision and cuts the combo (Game loop architecture, Decisions). The
	# last heart's hit (T-413) cuts it too, but the trick in progress is dropped
	# at the wreck, not paid: no `crashed`.
	if health - amount <= EPSILON:
		_cut_combo()
	else:
		collision()
	if not running:
		return
	health = maxf(health - amount, 0.0)
	invulnerable_total = _run_data.invulnerability_seconds()
	invulnerable_left = invulnerable_total
	health_changed.emit(health, max_health)
	car_damaged.emit(amount)
	if health <= 0.0:
		_wreck()
		return
	if invulnerable_left > 0.0:
		invulnerability_started.emit(invulnerable_left)


## True while the car is invulnerable after a hit (T-334).
func is_invulnerable() -> bool:
	return invulnerable_left > EPSILON


## Whether the drawn car shows now (T-334): during the invulnerability it blinks,
## off and on, each phase run.json's car.blink_interval_seconds long, starting off
## so the hit shows at once; otherwise always shown.
func car_blink_visible() -> bool:
	if not is_invulnerable() or not running:
		return true
	var interval := _run_data.blink_interval_seconds()
	if interval <= 0.0:
		return true
	var elapsed := invulnerable_total - invulnerable_left
	return int(floor(elapsed / interval + EPSILON)) % 2 == 1


## Restores `amount` hearts to the car, never above the maximum (health pickups,
## T-220). Not damage: it does not touch the combo. Ignored when the run is not going or
## `amount` is not positive. Returns the points actually restored.
func heal_car(amount: float) -> float:
	if wrecked and amount > 0.0:
		return revive()  # T-406: a health pickup picked up during the wreck revives the car
	if not running or amount <= 0.0:
		return 0.0
	var before := health
	health = minf(health + amount, max_health)
	if health != before:
		health_changed.emit(health, max_health)
	return health - before


## Adds coins collected this run. They count during the wreck too (T-413), and
## on the step the clock reaches 0:00 (the kaiju's coins in a tie). Ignored
## otherwise when the run is not going, or when `amount` is not positive.
func add_coins(amount: int) -> void:
	if not _counts_pickups() or amount <= 0:
		return
	coins += amount
	coins_changed.emit(coins)


## The kaiju was killed: the run ends at once, as a win. During the wreck too
## (T-413: the wreck ends with no loss), and on the same step the clock reached
## 0:00 (T-413, "A tie goes to the player": the time's up is called off).
## Ignored once the run's result is decided.
func kaiju_killed() -> void:
	if wrecked:
		wrecked = false
		wreck_left = 0.0
	elif _in_tie_step():
		_call_off_time_up()
	elif not running:
		return
	_end(RESULT_WIN)


## True while coins (and the kills that drop them) still count: the run is going,
## the car is wrecked (T-413), or it is the step the clock reached 0:00.
func _counts_pickups() -> bool:
	return running or wrecked or _in_tie_step()


## True on the physics step (and frame) the clock reached 0:00, once the time's
## up hold has started (T-413, "A tie goes to the player").
func _in_tie_step() -> bool:
	return timed_out and Engine.get_physics_frames() == _time_up_physics_frame and Engine.get_process_frames() == _time_up_process_frame


## Calls off the time's up hold (a tie won by a kaiju kill): the tree runs again.
func _call_off_time_up() -> void:
	timed_out = false
	time_up_left = 0.0
	process_mode = Node.PROCESS_MODE_INHERIT
	_set_paused(false)


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
	missions.on_drift_step(drifting, delta)  # T-457: the unbroken-drift goal
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
## tricks (TrickDetector.TRICK_IDS). `seconds` is the length of a whole drift
## for "extended_drift" (task T-246): its amount scales by it.
func add_trick(trick_id: String, seconds := 0.0) -> void:
	if not running or not TrickDetector.TRICK_IDS.has(trick_id):
		return
	missions.on_trick(trick_id, seconds)  # T-457
	var before := combo
	combo = _combo_data.after_trick(combo, trick_id, seconds)
	_record_trick(trick_id)
	combo_idle = 0.0
	likes_drain_idle = 0.0
	combo_trick.emit(trick_id, combo - before, combo)
	if combo != before:
		combo_changed.emit(combo)


## The car landed after `seconds` in the air (task T-242, the airtime trick;
## the run scene connects the car's `airtime_trick`). The combo goes up by
## combo.json's airtime amount for those seconds, like add_trick, and the
## popup gets combo_trick with the id "airtime". Nothing happens when the
## airtime is too short to pay.
func add_airtime_trick(seconds: float) -> void:
	if not running:
		return
	missions.on_airtime(seconds)  # T-457: every landing counts, also one too short to pay
	var amount := _combo_data.airtime_add(seconds)
	if amount <= 0.0:
		return
	var before := combo
	combo = minf(combo + amount, _combo_data.max_multiplier())
	_record_trick(TrickDetector.TRICK_AIRTIME)
	combo_idle = 0.0
	likes_drain_idle = 0.0
	combo_trick.emit(TrickDetector.TRICK_AIRTIME, combo - before, combo)
	if combo != before:
		combo_changed.emit(combo)


## The thread the needle trick's id (task T-272): the popup's key and combo.json's trick_add key.
const TRICK_THREAD_THE_NEEDLE := "thread_the_needle"


## The car threaded a pair of obstacles (task T-272; the run scene connects
## thread_the_needle.gd's `threaded`). The combo goes up by combo.json's
## trick_add.thread_the_needle, like add_trick, and the popup gets combo_trick
## with the id "thread_the_needle".
func add_needle_trick() -> void:
	if not running:
		return
	missions.on_trick(TRICK_THREAD_THE_NEEDLE)  # T-457
	var before := combo
	combo = minf(combo + _combo_data.trick_add(TRICK_THREAD_THE_NEEDLE), _combo_data.max_multiplier())
	_record_trick(TRICK_THREAD_THE_NEEDLE)
	combo_idle = 0.0
	likes_drain_idle = 0.0
	combo_trick.emit(TRICK_THREAD_THE_NEEDLE, combo - before, combo)
	if combo != before:
		combo_changed.emit(combo)


## The car collided with something (the run scene connects the car's
## `hit_obstacle`; damage_car() calls it too): the combo is cut as combo.json
## says (50% of the part above the start value). Ignored when the run is not
## going. Sends `crashed` first (task T-315), so the trick in progress pays
## before the cut; combo.json's crash_pays_trick_first false sends it after.
func collision() -> void:
	if not running:
		return
	# A crash pays the trick in progress (T-315): by default before the cut.
	var pay_first := _combo_data.crash_pays_trick_first()
	if pay_first:
		crashed.emit()
		if not running:
			return
	_cut_combo()
	if not pay_first:
		crashed.emit()
	missions.on_crash()  # T-457: a wall hit ends the drift; the drift goal starts over


## The collision's cut of the combo, without paying the trick in progress.
##
## T-415 (Decisions, "Hits close together cut the combo once"): a collision within
## combo.json's collision_window_seconds of the one that cut the combo does not cut it again
## (the crash still pays its trick). The window runs on the run's clock.
func _cut_combo() -> void:
	if time_elapsed() - _last_cut_at < _combo_data.collision_window_seconds():
		return
	var before := combo
	_set_combo(_combo_data.after_collision(combo))
	if before - combo > EPSILON:
		_last_cut_at = time_elapsed()
		combo_broken.emit()


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


## The car's hype speed bonus for the combo now (task T-275): combo.json's
## amount for the combo heat step (ComboHeat.step_for, its thresholds).
func hype_speed_target() -> float:
	if _combo_data == null:
		_combo_data = ComboData.new()
	return _combo_data.hype_speed_bonus(ComboHeat.step_for(combo))


## Eases `current` towards hype_speed_target() over `dt` seconds, so a step
## up or down isn't a jolt.
func eased_hype_speed(current: float, dt: float) -> float:
	return move_toward(current, hype_speed_target(), _combo_data.hype_speed_ease_per_second() * dt)


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
	_likes_total += amount
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
			open_choice(l)


## Starts the weapon choice for `level_reached` (T-144: the gift pack calls it
## when the car drives over a package; with pause_on_level_up on, every
## level-up calls it at once). The run pauses and level_up_choice_started
## fires, so the level-up screen opens; while a choice is already on show it
## waits its turn and starts after choice_made(). Ignored when the run is not
## going.
func open_choice(level_reached: int) -> void:
	if not running:
		return
	pending_choices.append(level_reached)
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


func _end(r: String, reason := "") -> void:
	_decide(r, reason)
	run_ended.emit(r, coins)


## Decides the run's result: it stops counting anything from here on, and the
## recap's summary is taken now.
func _decide(r: String, reason := "") -> void:
	running = false
	result = r
	loss_reason = reason if r == RESULT_LOSS else ""
	_final_recap = _build_recap()


## The last heart is gone (T-360, T-413): the wreck starts. The clock, likes,
## tricks, damage and gift packs stop (running is false) and the drift in
## progress is forgotten, but the result is not decided yet: coins and kills
## still count, a health pickup revives the car (revive()) and a kaiju kill wins
## (kaiju_killed()). When wreck_seconds are over (at once when 0) the run is lost
## on health and run_ended follows (_finish_wreck()).
func _wreck() -> void:
	running = false
	drift_seconds = 0.0
	drift_seconds_paid = 0
	missions.on_crash()  # T-457: the drift in progress is dropped
	wrecked = true
	wreck_left = maxf(wreck_seconds, 0.0)
	wreck_started.emit(wreck_left)
	if wreck_left <= EPSILON:
		_finish_wreck()


## A health pickup reached the wrecked car (T-406; Game loop architecture,
## Decisions, "A health pickup revives a wrecked car"): the car comes back with
## 1 heart (REVIVE_HEARTS, at most the maximum), the run is going again (the
## result was never decided during the wreck, T-413; the clock runs on from where
## it stopped) and run_ended is not sent. `revived` tells the run scene to give
## the controls and the trick detection back and stop the smoke and flames. The
## usual invulnerability after a hit follows (a proposal). The combo stays cut by
## the fatal hit, and the live viewers follow the combo, as always. Returns the
## hearts given; 0 when the car is not wrecked.
func revive() -> float:
	if not wrecked:
		return 0.0
	wrecked = false
	wreck_left = 0.0
	running = true
	result = ""
	loss_reason = ""
	_final_recap = {}
	health = minf(REVIVE_HEARTS, max_health)
	invulnerable_total = _run_data.invulnerability_seconds()
	invulnerable_left = invulnerable_total
	health_changed.emit(health, max_health)
	revived.emit()
	if invulnerable_left > 0.0:
		invulnerability_started.emit(invulnerable_left)
	return health


func _advance_wreck(seconds: float) -> void:
	if seconds <= 0.0:
		return
	wreck_left = maxf(wreck_left - seconds, 0.0)
	if wreck_left <= EPSILON:
		_finish_wreck()


## The wreck's seconds are over (T-413): only now is the run lost on health.
func _finish_wreck() -> void:
	if not wrecked:
		return
	wrecked = false
	wreck_left = 0.0
	_end(RESULT_LOSS, LOSS_HEALTH)


## The clock ran out (T-317): the run is lost now (nothing more counts) and
## frozen: the scene tree is paused, and this node alone keeps processing so it
## can count the time's up seconds. run_ended follows after time_up_seconds (at
## once when it is 0), with the tree unpaused first.
func _time_up() -> void:
	_decide(RESULT_LOSS, LOSS_TIME)
	timed_out = true
	_time_up_physics_frame = Engine.get_physics_frames()
	_time_up_process_frame = Engine.get_process_frames()
	time_up_left = maxf(time_up_seconds, 0.0)
	if time_up_left <= EPSILON:
		_finish_time_up()
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	_set_paused(true)
	time_up_started.emit(time_up_left)


func _advance_time_up(seconds: float) -> void:
	if seconds <= 0.0:
		return
	time_up_left = maxf(time_up_left - seconds, 0.0)
	if time_up_left <= EPSILON:
		_finish_time_up()


func _finish_time_up() -> void:
	if not timed_out:
		return
	timed_out = false
	time_up_left = 0.0
	process_mode = Node.PROCESS_MODE_INHERIT
	_set_paused(false)
	run_ended.emit(result, coins)


## True while the time's up screen plays (T-317): the clock ran out and
## run_ended has not been sent yet.
func is_timed_out() -> bool:
	return timed_out


## True during the wreck (T-360): the last heart is gone and run_ended has not
## been sent yet.
func is_wrecked() -> bool:
	return wrecked


## A kill by the car's weapons (the minion spawner and the kaiju boss call it
## when an enemy dies): `enemy_type` is "minion" or "kaiju" (the enemy's
## ENEMY_TYPE), `weapon_id` the weapon that struck the last blow ("" if
## unknown). Ignored when the run is not going.
func enemy_slain(enemy_type: String, weapon_id := "") -> void:
	if not _counts_pickups() or enemy_type == "":
		return
	_slain[enemy_type] = int(_slain.get(enemy_type, 0)) + 1
	if weapon_id != "":
		_weapon_kills[weapon_id] = int(_weapon_kills.get(weapon_id, 0)) + 1


## The car's tier of driving power-up `id` (T-457; PowerUpData.IDS): 0 when not owned.
func power_up_tier(id: String) -> int:
	return int(_power_ups.get(id, 0))


## Owned driving power-ups, a copy: {id: tier}.
func owned_power_ups() -> Dictionary:
	return _power_ups.duplicate()


## Gives the car driving power-up `id` (the mission gift calls it, T-457): tier 1 when new,
## otherwise the next tier, held at the power-up's last tier (power_ups.json). Sends
## power_ups_changed when the tier went up. Returns the tier now; 0 for an unknown id.
func grant_power_up(id: String) -> int:
	if _power_up_data == null:
		_power_up_data = PowerUpData.new()
	if not _power_up_data.is_ok() or not _power_up_data.ids().has(id):
		return 0
	var before := power_up_tier(id)
	var tier := mini(before + 1, _power_up_data.max_tier(id))
	if tier != before:
		_power_ups[id] = tier
		power_ups_changed.emit()
	return tier


## God mode (T-504): sets power-up `id` straight to `tier` (0 = not owned, up to its last
## tier), as if the gifts had given it. Sends power_ups_changed when it changed. Returns the
## tier now; -1, changing nothing, for an unknown id.
func set_power_up_tier(id: String, tier: int) -> int:
	if _power_up_data == null:
		_power_up_data = PowerUpData.new()
	if not _power_up_data.is_ok() or not _power_up_data.ids().has(id):
		return -1
	var t := clampi(tier, 0, _power_up_data.max_tier(id))
	if t != power_up_tier(id):
		if t == 0:
			_power_ups.erase(id)
		else:
			_power_ups[id] = t
		power_ups_changed.emit()
	return t


func _record_trick(trick_id: String) -> void:
	_tricks_done[trick_id] = int(_tricks_done.get(trick_id, 0)) + 1
	_highest_combo = maxf(_highest_combo, combo)


## The run's stats for the recap screen and the runs history (T-319): a plain
## Dictionary (numbers, strings, nested Dictionaries, so it serialises to
## JSON), a copy the caller may keep. While the run is going it is live; once
## it has ended it is the final summary, still readable after run_ended until
## the next start_run() clears it. Fields:
##   result: "win" | "loss" | "" (still going)
##   loss_reason: "time" | "health" | ""
##   time_survived: seconds into the run at its end (or so far)
##   coins: coins collected; likes: likes (XP) gained in total; level: level reached
##   enemies_slain: {enemy type: kills}, e.g. {"minion": 40, "kaiju": 1}
##   tricks: {trick id: times completed} (every id the combo counts)
##   highest_combo: the highest multiplier reached
##   peak_viewers: the live viewers counter's highest number (T-320 quick tuning,
##     board 2026-10-29): the viewers for highest_combo on T-332's curve
##     (ViewersData.viewers_for), the number the counter counts up to, without its wobble
##   weapons: {weapon id: {"tier": tier it ended on, "kills": kills it made}}
func recap() -> Dictionary:
	if not _final_recap.is_empty():
		return _final_recap.duplicate(true)
	return _build_recap()


## The live viewers for a combo multiplier (T-332's curve, the counter's target), for
## the recap's peak viewers (T-320). Whole viewers.
static func peak_viewers_for(multiplier: float) -> float:
	if _viewers_curve == null:
		_viewers_curve = ViewersData.new()
	return _viewers_curve.viewers_for(maxf(multiplier, 1.0))


static var _viewers_curve: ViewersData = null


func _build_recap() -> Dictionary:
	var weapons_out := {}
	if weapons_source.is_valid():
		var tiers: Dictionary = weapons_source.call()
		for id in tiers:
			weapons_out[id] = {"tier": int(tiers[id]), "kills": int(_weapon_kills.get(id, 0))}
	return {
		"result": result,
		"loss_reason": loss_reason,
		"time_survived": time_elapsed(),
		"coins": coins,
		"likes": _likes_total,
		"level": level,
		"enemies_slain": _slain.duplicate(),
		"tricks": _tricks_done.duplicate(),
		"highest_combo": _highest_combo,
		"peak_viewers": peak_viewers_for(_highest_combo),
		"weapons": weapons_out,
	}
