extends RefCounted
## Which jump effect plays around the car when it jumps (task T-551; Drifting, Decisions, "A jump
## effect around the car"; Garage design, Decisions, "Cosmetics"). The seam between the car's
## effect (jump_effect.gd) and the saved cosmetic choice.
##
## T-552 (the cosmetics save) plugs in here: set `provider` once to a Callable that returns the
## saved, equipped jump effect id (its API's equipped_jump_effect()), for example from the
## cosmetics script's _static_init or an autoload's _ready:
##     JumpEffectChoice.provider = func() -> String: return Cosmetics.equipped_jump_effect()
## Until then (no provider), and for any id this list doesn't know, it is DEFAULT_ID, the dash
## cloud. Tests set `override_id`.

const DEFAULT_ID := "dash_cloud"
## The five jump effects (ids shared with T-552's data, T-553's menu and T-556's art).
const IDS := ["dash_cloud", "spring", "jet_thrust", "stunt_sparks", "shockwave_ring"]

## Callable() -> String: the saved choice (T-552). Unset: the default.
static var provider := Callable()
## Tests: when not empty, this id is used instead of the saved one.
static var override_id := ""


## The id of the effect to play now: the override, else the saved choice, else the dash cloud.
static func equipped_id() -> String:
	var id := override_id
	if id == "" and provider.is_valid():
		id = str(provider.call())
	return id if id in IDS else DEFAULT_ID
