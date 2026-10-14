extends Node
## The level-up's weapon choices (task T-043; Weapons, Decisions, "Level-up
## flow in the MVP"). When the run starts a level-up's weapon choice
## (RunState.level_up_choice_started) this works out the choices for the car's
## weapons as they are now and emits `offers_ready`; the level-up screen (a
## later UI task) shows them by id and calls choose(id) with the one taken,
## which applies it and calls RunState.choice_made() so the run resumes.
##
## Choice ids (the screen maps each to its text):
##   "upgrade_gun"          the starting gun's next tier
##   "get_flamethrower"     gives the exhaust flamethrower (tier 1)
##   "upgrade_flamethrower" the flamethrower's next tier
## A weapon at its last tier is not offered. With nothing to offer the choice
## is skipped (choice_made() is called at once, offers_ready is not emitted).

const GET_FLAMETHROWER := "get_flamethrower"
const UPGRADE_GUN := "upgrade_gun"
const UPGRADE_FLAMETHROWER := "upgrade_flamethrower"

## The choices are ready: `level` is the level that was reached, `offers` the
## ids to show (1 or 2 of them), in the order to show them.
signal offers_ready(level: int, offers: Array)
## A choice was taken and applied (before the run resumes).
signal offer_taken(id: String)

var rack: Node = null
var state: Node = null
## The ids on offer now; empty when no choice is waiting.
var current_offers: Array = []


func bind(the_rack: Node) -> void:
	rack = the_rack
	state = rack.state
	state.level_up_choice_started.connect(_on_choice_started)
	state.run_started.connect(_on_run_started)


## The choice ids for the car's weapons as they are now (does not change anything).
func compute_offers() -> Array:
	var out := []
	var gun: Node = rack.gun
	var flame: Node = rack.flamethrower
	if gun != null and not gun.is_max_tier():
		out.append(UPGRADE_GUN)
	if flame != null and not flame.is_max_tier():
		out.append(UPGRADE_FLAMETHROWER if flame.is_owned() else GET_FLAMETHROWER)
	return out


## True while a choice is waiting for choose().
func has_offers() -> bool:
	return not current_offers.is_empty()


## The player took choice `id`: applies it, then RunState.choice_made() so the
## run resumes (or the next waiting level-up's choice starts). False, changing
## nothing, when `id` is not on offer.
func choose(id: String) -> bool:
	if not current_offers.has(id):
		return false
	var applied := false
	match id:
		UPGRADE_GUN:
			applied = rack.upgrade("gun")
		GET_FLAMETHROWER, UPGRADE_FLAMETHROWER:
			applied = rack.upgrade("flamethrower")
	if not applied:
		return false
	current_offers = []
	offer_taken.emit(id)
	state.choice_made()
	return true


func _on_choice_started(level: int) -> void:
	current_offers = compute_offers()
	if current_offers.is_empty():
		# Nothing left to offer: skip the choice, the run goes on.
		state.choice_made()
		return
	offers_ready.emit(level, current_offers.duplicate())


func _on_run_started() -> void:
	current_offers = []
