class_name RunState
extends Node
## The run's state (task T-036): the 8-minute clock, the car's health, the
## coins collected this run, and win and loss (Game loop architecture,
## Decisions). Other agents' work plugs in through the signals and public
## functions below; game/README.md, "The run", lists them.
##
## The clock counts down in _process, so it stops whenever the scene tree is
## paused (this node uses the default, pausable process mode). advance() moves
## it by hand, for tests.
##
## The run's length and the boss's arrival are Game loop architecture,
## Decisions ("A run lasts 8 minutes", "At the 7-minute mark the kaiju
## spawns"), not balancing numbers, so they are constants here. The car's
## starting health comes from res://data/run.json (RunData).

## The run lasts 8 minutes.
const RUN_SECONDS := 480.0
## The kaiju arrives when 7 minutes have passed (1:00 left).
const BOSS_TIME_LEFT := 60.0

## Clock comparisons allow this much rounding error from summing frame times.
const EPSILON := 0.000001

const RESULT_WIN := "win"
const RESULT_LOSS := "loss"

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
## The car's health changed (damage, or a new run).
signal health_changed(health: float, max_health: float)
## The coins collected this run changed.
signal coins_changed(coins: int)

## Seconds left on the clock (RUN_SECONDS at the start, 0 at the end).
var time_left := RUN_SECONDS
var health := 0.0
var max_health := 0.0
## Coins collected this run.
var coins := 0
## True from start_run() until the run ends.
var running := false
## "" while the run is going (or before the first one), then "win" or "loss".
var result := ""
var boss_time_sent := false

var _run_data: RunData


func _init(run_data: RunData = null) -> void:
	_run_data = run_data


## Starts a fresh run from the start: full health, 8:00, 0 coins.
func start_run() -> void:
	if _run_data == null:
		_run_data = RunData.new()
	max_health = _run_data.starting_health()
	health = max_health
	time_left = RUN_SECONDS
	coins = 0
	result = ""
	boss_time_sent = false
	running = true
	run_started.emit()
	time_left_changed.emit(time_left)
	health_changed.emit(health, max_health)
	coins_changed.emit(coins)


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
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
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


func _end(r: String) -> void:
	running = false
	result = r
	run_ended.emit(r, coins)
