class_name PowerUpOffers
extends Node
## The driving power-up gift's choices (task T-459; Game loop architecture, Decisions,
## "Mission packs"; Drifting, Decisions, "Driving power-ups"). When the run's tracker
## completes a mission (RunMissions.mission_completed) this pauses the run, works out the
## choices for the power-ups the car has now and emits `offers_ready`; the power-up screen
## shows them by id (the power-up ids of res://data/power_ups.json) and calls choose(id),
## which gives that power-up (RunState.grant_power_up: tier 1 when new, else the next tier)
## and resumes the run.
##
## The rules (HUD and menus, Content, "Power-up overlay"):
## - A choice is a power-up the car doesn't own or one it owns below its last tier; a
##   power-up at its last tier is never offered.
## - Each gift offers 2 different choices drawn at random (`rng`, which tests can seed),
##   shown in the data's order. With only one choice left it is offered alone (proposal).
##   With none, power_ups.json's offer_when_exhausted says what happens: "skip_gift" (its
##   proposal) skips the gift, with no overlay and no pause (`gift_skipped`).
## - Never at once with the level-up (weapons gift) screen (proposal): a gift for a
##   mission completed while a weapon choice is waiting opens once that choice is made;
##   a weapon choice that starts while the overlay is open is held by the level-up screen
##   (LevelUpScreen.hold) and shown when the overlay closes (`closed`). Several gifts in
##   a row open one after another.

## The choices for the gift of mission `mission_index` (0-based) are on show: `offers`
## are 1 or 2 power-up ids, in the order to show them. The run is paused.
signal offers_ready(mission_index: int, offers: Array)
## Power-up `id` was taken and granted (before the run resumes or the next screen shows).
signal offer_taken(id: String)
## The overlay closed after a choice; a held weapon choice can show now.
signal closed
## The gift of mission `mission_index` was skipped: nothing was left to offer.
signal gift_skipped(mission_index: int)

## How many choices a gift offers (Game loop architecture, Decisions, "Mission packs": 2).
const OFFER_COUNT := 2
const SKIP_GIFT := "skip_gift"

var state: RunState = null
var data: PowerUpData = null
## The ids on offer now; empty when no gift is on show.
var current_offers: Array = []
## The mission whose gift is on show (-1 when none).
var current_mission := -1
## Completed missions whose gift waits its turn, oldest first.
var pending: Array[int] = []
## The random draw's generator. Randomized once; tests set rng.seed.
var rng := RandomNumberGenerator.new()
## Set when the tree must be checked at the start of the next frame (see _sync).
var _sync_armed := false


func _init() -> void:
	rng.randomize()
	# Runs while the tree is paused, so it can re-pause or open a waiting gift.
	process_mode = Node.PROCESS_MODE_ALWAYS


func bind(the_state: RunState, the_data: PowerUpData = null) -> void:
	state = the_state
	data = the_data if the_data != null else PowerUpData.new()
	state.missions.mission_completed.connect(_on_mission_completed)
	state.run_started.connect(_on_run_started)
	state.level_up_choice_made.connect(_on_level_up_choice_made)


func _enter_tree() -> void:
	get_tree().process_frame.connect(_sync)
	get_tree().physics_frame.connect(_sync)


func _exit_tree() -> void:
	get_tree().process_frame.disconnect(_sync)
	get_tree().physics_frame.disconnect(_sync)


## True while the overlay's choice is on show (the run is paused for it).
func is_showing() -> bool:
	return not current_offers.is_empty()


## Every choice available now, in the data's order (changes nothing): the power-ups the
## car doesn't own and those it owns below their last tier.
func available_offers() -> Array:
	var out := []
	if data == null or not data.is_ok() or state == null:
		return out
	# T-521: with the slots full (slots.json max_power_ups), only the owned ones' next tiers.
	var full := state.owned_power_ups().size() >= state.slot_rules.max_power_ups()
	for id in data.ids():
		if full and state.power_up_tier(id) == 0:
			continue
		if state.power_up_tier(id) < data.max_tier(id):
			out.append(String(id))
	return out


## The tier a choice would give: the car's tier now + 1.
func offered_tier(id: String) -> int:
	return state.power_up_tier(id) + 1


## The ids the next gift would offer as things are now. Changes nothing.
func compute_offers() -> Array:
	var saved := rng.state
	var out := _draw()
	rng.state = saved
	return out


## Draws the choices (advances `rng`).
func _draw() -> Array:
	var pool := available_offers()
	if pool.size() <= OFFER_COUNT:
		return pool
	var all := pool.duplicate()
	var picked := []
	while picked.size() < OFFER_COUNT:
		var i := rng.randi_range(0, pool.size() - 1)
		picked.append(pool[i])
		pool.remove_at(i)
	return all.filter(func(id) -> bool: return picked.has(id))


## The player took power-up `id`: grants it, closes the gift, then the next waiting gift
## opens, or a held weapon choice shows, or the run resumes. False, changing nothing,
## when `id` is not on offer.
func choose(id: String) -> bool:
	if not current_offers.has(id):
		return false
	state.grant_power_up(id)
	current_offers = []
	current_mission = -1
	offer_taken.emit(id)
	if _can_open():
		_open_next()  # the tree stays paused
		return true
	closed.emit()
	if not state.is_waiting_for_choice():
		_set_paused(false)
	return true


func _on_mission_completed(mission_index: int) -> void:
	pending.append(mission_index)
	if _can_open():
		_open_next()


func _can_open() -> bool:
	return not pending.is_empty() and not is_showing() and state.running \
			and not state.is_waiting_for_choice()


## Opens the oldest waiting gift; one with nothing to offer is skipped (offer_when_exhausted).
func _open_next() -> void:
	while _can_open():
		var mission_index: int = pending.pop_front()
		var ids := _draw()
		if ids.is_empty():
			# "skip_gift" (the data's proposal; the only action there is): no overlay, no pause.
			gift_skipped.emit(mission_index)
			continue
		current_offers = ids
		current_mission = mission_index
		_set_paused(true)
		offers_ready.emit(mission_index, ids.duplicate())
		return


## A weapon choice was made. RunState resumes the tree right after this, so the check
## waits for the start of the next frame (before anything else moves): a waiting gift
## opens then, or the overlay still on show pauses the run again (a weapon choice with
## nothing to offer is made at once, even while the overlay is open).
func _on_level_up_choice_made(_level: int) -> void:
	if is_showing() or not pending.is_empty():
		_sync_armed = true


## At the start of a frame (process or physics, before the nodes run), once armed.
func _sync() -> void:
	if not _sync_armed:
		return
	_sync_armed = false
	if is_showing():
		_set_paused(true)
	elif _can_open():
		_open_next()


func _on_run_started() -> void:
	if is_showing():
		_set_paused(false)  # a new run never starts behind a paused gift
	current_offers = []
	current_mission = -1
	pending.clear()
	_sync_armed = false


func _set_paused(paused: bool) -> void:
	if is_inside_tree():
		get_tree().paused = paused
