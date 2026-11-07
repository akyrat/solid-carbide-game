class_name PracticeOffers
extends PowerUpOffers
## The power-up gift of a tutorial practice window (task T-561; HUD and menus, Decisions,
## "Interactive tutorial slides": the grind slide's practice starts by offering one power-up
## gift, Jump). The real gift (PowerUpOffers, shown by the real overlay, PowerUpScreen), with two
## differences, so it fits in a window on a slide:
## - it opens only when the practice asks (offer_only), never from a completed mission;
## - it pauses only its practice session (`pause_with`), never the whole tree, so the slide around
##   the window keeps working.

## Called with true when the gift opens and false when it closes (the session's pause).
var pause_with := Callable()


## Like PowerUpOffers.bind, without the missions: a practice's gift opens only through offer_only.
func bind(the_state: RunState, the_data: PowerUpData = null) -> void:
	state = the_state
	data = the_data if the_data != null else PowerUpData.new()
	state.run_started.connect(_on_run_started)


## Opens a gift that offers only power-up `id` (one card). False, changing nothing, when a gift
## is already on show or `id` is not a power-up.
func offer_only(id: String) -> bool:
	if is_showing() or data == null or not data.is_ok() or not data.ids().has(id):
		return false
	gifts_opened += 1
	current_offers = [id]
	current_mission = -1
	_set_paused(true)
	offers_ready.emit(-1, [id])
	return true


func _set_paused(paused: bool) -> void:
	if pause_with.is_valid():
		pause_with.call(paused)
