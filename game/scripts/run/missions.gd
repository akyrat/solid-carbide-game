class_name RunMissions
extends RefCounted
## The run's missions (task T-457; Game loop architecture, Decisions, "Mission packs"): the
## tracker behind the notebook page, invisible by itself. A run has MissionData.total() (12, T-521)
## missions: the 5 fixed ones from res://data/missions.json, then the rest generated from the
## file's rules with an RNG seeded per run (start(seed); a negative seed picks a new one).
## One mission is current at a time; every goal of it counts in parallel, and when all of
## them are done the mission is completed and the next one becomes current. After the last
## one nothing more is offered (is_all_done(), a proposal for the playtest).
##
## RunState owns one (RunState.missions) and feeds it while the run is going: the car's
## tricks (on_trick), its landings (on_airtime), thread the needle (on_trick with
## "thread_the_needle"), its drift state each step (on_drift_step) and crashes (on_crash).
## How tricks pay is not touched. Indices are 0-based: mission_index 0 is mission 1.
##
## Goal kinds: "count" adds 1 per trick (any trick id the data allows); "seconds" adds the
## seconds, except for "extended_drift", which counts only one unbroken drift: its progress is
## the length of the drift in progress (or the one that just ended), and a drift that ends,
## by release or a crash, starts over from 0.
##
## Proposals for the playtest: a trick that completes a mission does not also count for the
## next one, and the next mission's drift goal counts only drifting done after it started.

## A goal's progress changed: `done` out of `total` (a count, or seconds).
signal goal_progress(mission_index: int, goal_index: int, done: float, total: float)
## A goal of the current mission is done (sent after its last goal_progress).
signal goal_completed(mission_index: int, goal_index: int)
## Every goal of mission `mission_index` is done (sent after its last goal_completed).
signal mission_completed(mission_index: int)
## Mission `mission_index` is the current one now (a new run, or the one before it completed).
## Not sent after the last mission.
signal mission_started(mission_index: int)

const KIND_COUNT := "count"
const KIND_SECONDS := "seconds"
const TRICK_DRIFT := "extended_drift"
const EPSILON := 0.000001

const TrickDetector := preload("res://scripts/driving/trick_detector.gd")

## Every mission of this run, in order: each an Array of goals {"trick", "kind", "amount"}.
var missions: Array = []
## The current mission's index (0-based); missions.size() once all are done.
var current := 0
## The seed this run's missions were generated with (not `seed`: that is a global function).
var mission_seed := 0
## Progress of each goal of the current mission (same order as its goals).
var progress: Array = []
## Whether each goal of the current mission is done.
var completed: Array = []

## Seconds of the unbroken drift in progress, since the current mission started.
var _live_drift := 0.0
var _data: MissionData


func _init(data: MissionData = null) -> void:
	_data = data if data != null else MissionData.new()


## A fresh set for a new run: back to mission 1, missions 6 on generated from `run_seed`
## (negative: a new random seed). Sends mission_started(0).
func start(run_seed: int = -1) -> void:
	if run_seed < 0:
		var r := RandomNumberGenerator.new()
		r.randomize()
		run_seed = r.randi() & 0x7fffffff
	mission_seed = run_seed
	var rng := RandomNumberGenerator.new()
	rng.seed = mission_seed
	missions = []
	for n in range(1, _data.total() + 1):
		missions.append(_data.mission(n, rng).duplicate(true))
	current = 0
	_live_drift = 0.0
	_load_current()


## How many missions the run has (12).
func count() -> int:
	return missions.size()


## The current mission's index (0-based), or -1 once all are done.
func current_index() -> int:
	return -1 if is_all_done() else current


## The current mission's number (1 to 12), or 0 once all are done.
func current_number() -> int:
	return current_index() + 1


## True after the last mission was completed: nothing more is offered.
func is_all_done() -> bool:
	return current >= missions.size()


## Mission `index`'s goals (a copy): [{"trick", "kind", "amount"}].
func mission(index: int) -> Array:
	return missions[index].duplicate(true)


## The current mission's goals with their state (a copy): [{"trick", "kind", "amount",
## "done" (progress), "completed"}]. Empty once all are done.
func current_goals() -> Array:
	if is_all_done():
		return []
	var out: Array = []
	for i in missions[current].size():
		var g: Dictionary = missions[current][i].duplicate()
		g["done"] = progress[i]
		g["completed"] = completed[i]
		out.append(g)
	return out


## A trick happened: `trick_id` as the combo uses it (TrickDetector.TRICK_IDS, or
## "thread_the_needle"); `seconds` is a whole drift's length for "extended_drift".
func on_trick(trick_id: String, seconds := 0.0) -> void:
	if is_all_done():
		return
	var index := current
	for i in _goal_count():
		if completed[i] or String(missions[index][i]["trick"]) != trick_id:
			continue
		var g: Dictionary = missions[index][i]
		if String(g["kind"]) == KIND_SECONDS:
			if trick_id == TRICK_DRIFT:
				_set_progress(i, seconds)  # one unbroken drift: its whole length
			else:
				_set_progress(i, progress[i] + seconds)
		else:
			_set_progress(i, progress[i] + 1.0)
		if index != current:
			return  # this trick completed the mission: it does not count for the next one


## The car landed after `seconds` in the air ("airtime"): seconds goals add them up,
## count goals add 1. Every landing counts, also one too short to pay in the combo.
func on_airtime(seconds: float) -> void:
	if seconds > 0.0:
		on_trick(TrickDetector.TRICK_AIRTIME, seconds)


## The car's drift state after one physics step: the drift goal follows the unbroken drift
## in progress; a step without drifting ends it, and the drift goal starts over.
func on_drift_step(drifting: bool, delta: float) -> void:
	if not drifting:
		_end_drift()
		return
	_live_drift += delta
	if is_all_done():
		return
	var index := current
	for i in _goal_count():
		if not completed[i] and _is_drift_seconds(i):
			_set_progress(i, _live_drift)
			if index != current:
				return


## The car crashed (a wall, a building, a boulder or damage): the drift in progress ends,
## so the drift goal starts over (the crash pays the drift to on_trick first).
func on_crash() -> void:
	_end_drift()


func _end_drift() -> void:
	_live_drift = 0.0
	if is_all_done():
		return
	for i in _goal_count():
		if not completed[i] and _is_drift_seconds(i) and progress[i] != 0.0:
			_set_progress(i, 0.0)


func _is_drift_seconds(i: int) -> bool:
	var g: Dictionary = missions[current][i]
	return String(g["trick"]) == TRICK_DRIFT and String(g["kind"]) == KIND_SECONDS


func _goal_count() -> int:
	return missions[current].size()


func _set_progress(i: int, value: float) -> void:
	var total := float(missions[current][i]["amount"])
	var done := value >= total - EPSILON
	value = total if done else value
	if value == progress[i] and not done:
		return
	progress[i] = value
	goal_progress.emit(current, i, value, total)
	if done:
		completed[i] = true
		goal_completed.emit(current, i)
		if not completed.has(false):
			_complete_mission()


func _complete_mission() -> void:
	var index := current
	current += 1
	_live_drift = 0.0  # proposal: a new mission counts only what happens from now on
	mission_completed.emit(index)
	_load_current()


func _load_current() -> void:
	progress = []
	completed = []
	if is_all_done():
		return
	for g in missions[current]:
		progress.append(0.0)
		completed.append(false)
	mission_started.emit(current)
