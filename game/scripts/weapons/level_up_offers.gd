extends Node
## The level-up's weapon choices (tasks T-043 and T-172; Weapons, Decisions,
## "Level-up flow in the MVP" and "Level-up offers with five weapons"). When
## the run starts a level-up's weapon choice (RunState.level_up_choice_started)
## this works out the choices for the car's weapons as they are now and emits
## `offers_ready`; the level-up screen shows them by id and calls choose(id)
## with the one taken, which applies it and calls RunState.choice_made() so the
## run resumes.
##
## Choice ids (the screen maps each to its text), one pair per weapon:
##   "get_<weapon>"      gives the weapon (tier 1) while the car does not have it
##   "upgrade_<weapon>"  the owned weapon's next tier, until its last tier (8)
## The weapons are gun, flamethrower, underglow, molotov, wiper. The gun is
## always owned, so it has only "upgrade_gun".
##
## Each level-up offers 2 different choices drawn at random (`rng`, which tests
## can seed) from every available one, shown in the order of ALL_IDS. The first
## choice of a run whose car has only the gun is always "upgrade_gun" and
## "get_flamethrower". With only one choice available it is offered alone;
## with none the choice is skipped (choice_made() is called at once,
## offers_ready is not emitted).

const UPGRADE_GUN := "upgrade_gun"
const GET_FLAMETHROWER := "get_flamethrower"
const UPGRADE_FLAMETHROWER := "upgrade_flamethrower"
const GET_UNDERGLOW := "get_underglow"
const UPGRADE_UNDERGLOW := "upgrade_underglow"
const GET_MOLOTOV := "get_molotov"
const UPGRADE_MOLOTOV := "upgrade_molotov"
const GET_WIPER := "get_wiper"
const UPGRADE_WIPER := "upgrade_wiper"

## The weapons that can be offered, in the order the choices are shown.
const WEAPON_ORDER := ["gun", "flamethrower", "underglow", "molotov", "wiper"]
## Every choice id, in the order they are shown.
const ALL_IDS := [UPGRADE_GUN, GET_FLAMETHROWER, UPGRADE_FLAMETHROWER, GET_UNDERGLOW, UPGRADE_UNDERGLOW,
		GET_MOLOTOV, UPGRADE_MOLOTOV, GET_WIPER, UPGRADE_WIPER]
## The fixed first choice of a normal run (Weapons, Decisions).
const FIRST_OFFERS := [UPGRADE_GUN, GET_FLAMETHROWER]
## How many choices a level-up offers (Weapons, Decisions: 2 in the MVP).
const OFFER_COUNT := 2

## The choices are ready: `level` is the level that was reached, `offers` the
## ids to show (1 or 2 of them), in the order to show them.
signal offers_ready(level: int, offers: Array)
## A choice was taken and applied (before the run resumes).
signal offer_taken(id: String)

var rack: Node = null
var state: Node = null
## The ids on offer now; empty when no choice is waiting.
var current_offers: Array = []
## Choices taken this run (the first one is the fixed first offer).
var choices_taken := 0
## The random draw's generator. Randomized once; tests set rng.seed.
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.randomize()


func bind(the_rack: Node) -> void:
	rack = the_rack
	state = rack.state
	state.level_up_choice_started.connect(_on_choice_started)
	state.run_started.connect(_on_run_started)


## The weapon id a choice id is about ("upgrade_wiper" -> "wiper"), or "".
static func weapon_of(id: String) -> String:
	for prefix in ["get_", "upgrade_"]:
		if id.begins_with(prefix):
			var w := id.substr(prefix.length())
			if WEAPON_ORDER.has(w):
				return w
	return ""


## Every choice available now, in ALL_IDS order (does not change anything):
## "get_<weapon>" for a weapon the car does not have, "upgrade_<weapon>" for
## one it has below its last tier.
func available_offers() -> Array:
	var out := []
	for weapon_id in WEAPON_ORDER:
		var w: Node = rack.get_weapon(weapon_id)
		if w == null or w.is_max_tier():
			continue
		out.append(("upgrade_" if w.is_owned() else "get_") + weapon_id)
	return out


## The ids the next choice will offer for the car's weapons as they are now.
## Changes nothing: the generator is put back as it was.
func compute_offers() -> Array:
	var saved := rng.state
	var out := _draw()
	rng.state = saved
	return out


## True when the next choice is the fixed first one: no choice taken yet this
## run, the car has only the gun, and both first choices are available.
func is_first_offer() -> bool:
	if choices_taken > 0 or rack.owned_ids() != ["gun"]:
		return false
	var available := available_offers()
	return available.has(UPGRADE_GUN) and available.has(GET_FLAMETHROWER)


## Draws the choices (advances `rng`).
func _draw() -> Array:
	if is_first_offer():
		return FIRST_OFFERS.duplicate()
	var pool := available_offers()
	if pool.size() <= OFFER_COUNT:
		return pool
	var picked := []
	while picked.size() < OFFER_COUNT:
		var i := rng.randi_range(0, pool.size() - 1)
		picked.append(pool[i])
		pool.remove_at(i)
	# Shown in ALL_IDS order.
	return ALL_IDS.filter(func(id) -> bool: return picked.has(id))


## True while a choice is waiting for choose().
func has_offers() -> bool:
	return not current_offers.is_empty()


## The player took choice `id`: applies it, then RunState.choice_made() so the
## run resumes (or the next waiting level-up's choice starts). False, changing
## nothing, when `id` is not on offer.
func choose(id: String) -> bool:
	if not current_offers.has(id):
		return false
	var weapon_id := weapon_of(id)
	if weapon_id == "" or not rack.upgrade(weapon_id):
		return false
	current_offers = []
	choices_taken += 1
	offer_taken.emit(id)
	state.choice_made()
	return true


func _on_choice_started(level: int) -> void:
	current_offers = _draw()
	if current_offers.is_empty():
		# Nothing left to offer: skip the choice, the run goes on.
		state.choice_made()
		return
	offers_ready.emit(level, current_offers.duplicate())


func _on_run_started() -> void:
	current_offers = []
	choices_taken = 0
