extends GutTest
## Task T-459: the driving power-up gift's offer rules (PowerUpOffers): only power-ups the
## car doesn't own and the next tiers of those it owns, never one at its last tier; 2
## choices, 1 when only one is left, the gift skipped when none is (power_ups.json's
## offer_when_exhausted, "skip_gift").

var state: RunState
var offers: PowerUpOffers
var data: PowerUpData
var ready_calls: Array = []
var skipped: Array = []


func before_each() -> void:
	state = RunState.new()
	state.mission_seed = 1
	state.start_run()
	data = PowerUpData.new()
	offers = PowerUpOffers.new()
	offers.bind(state, data)
	offers.rng.seed = 7
	ready_calls = []
	skipped = []
	offers.offers_ready.connect(func(i: int, ids: Array) -> void: ready_calls.append([i, ids]))
	offers.gift_skipped.connect(func(i: int) -> void: skipped.append(i))


func after_each() -> void:
	offers.free()
	state.free()


func _max_out(id: String) -> void:
	while state.power_up_tier(id) < data.max_tier(id):
		state.grant_power_up(id)


func test_a_fresh_car_can_be_offered_every_power_up() -> void:
	assert_eq(offers.available_offers(), ["rev_charge", "jump", "bouncy_bumpers", "rusty_overcoat"])
	for id in offers.available_offers():
		assert_eq(offers.offered_tier(id), 1, "a power-up not owned is offered at tier 1")


func test_an_owned_power_up_is_offered_at_its_next_tier() -> void:
	state.grant_power_up("jump")
	state.grant_power_up("jump")
	assert_true(offers.available_offers().has("jump"))
	assert_eq(offers.offered_tier("jump"), 3)


func test_a_power_up_at_its_last_tier_is_never_offered() -> void:
	_max_out("jump")
	_max_out("rev_charge")
	assert_eq(offers.available_offers(), ["bouncy_bumpers", "rusty_overcoat"])
	for s in 40:
		offers.rng.seed = s
		var ids := offers.compute_offers()
		assert_false(ids.has("jump") or ids.has("rev_charge"), "seed %d" % s)


func test_a_gift_offers_two_different_available_power_ups_in_data_order() -> void:
	var seen := {}
	for s in 40:
		offers.rng.seed = s
		var ids := offers.compute_offers()
		assert_eq(ids.size(), 2)
		assert_ne(ids[0], ids[1])
		var order: Array = data.ids()
		assert_true(order.find(ids[0]) < order.find(ids[1]), "shown in the data's order")
		seen[str(ids)] = true
	assert_gt(seen.size(), 1, "the pair is drawn at random")


func test_a_completed_mission_opens_a_gift_of_two() -> void:
	state.missions.mission_completed.emit(0)
	assert_eq(ready_calls.size(), 1)
	assert_eq(ready_calls[0][0], 0)
	assert_eq((ready_calls[0][1] as Array).size(), 2)
	assert_true(offers.is_showing())


func test_with_one_power_up_left_the_gift_offers_it_alone() -> void:
	for id in ["rev_charge", "jump", "bouncy_bumpers"]:
		_max_out(id)
	state.grant_power_up("rusty_overcoat")
	state.missions.mission_completed.emit(3)
	assert_eq(ready_calls.size(), 1)
	assert_eq(ready_calls[0][1], ["rusty_overcoat"])
	assert_eq(offers.offered_tier("rusty_overcoat"), 2)


func test_with_nothing_left_the_gift_is_skipped() -> void:
	assert_eq(data.offer_when_exhausted(), PowerUpOffers.SKIP_GIFT)
	for id in data.ids():
		_max_out(id)
	state.missions.mission_completed.emit(9)
	assert_eq(ready_calls.size(), 0, "no overlay")
	assert_eq(skipped, [9])
	assert_false(offers.is_showing())


func test_choosing_grants_the_power_up_and_closes_the_gift() -> void:
	state.missions.mission_completed.emit(0)
	var taken: Array = []
	offers.offer_taken.connect(func(id: String) -> void: taken.append(id))
	var id: String = offers.current_offers[0]
	assert_true(offers.choose(id))
	assert_eq(state.power_up_tier(id), 1)
	assert_eq(taken, [id])
	assert_false(offers.is_showing())


func test_a_choice_not_on_offer_changes_nothing() -> void:
	state.missions.mission_completed.emit(0)
	var other: String = offers.available_offers().filter(func(i) -> bool: return not offers.current_offers.has(i))[0]
	assert_false(offers.choose(other))
	assert_eq(state.power_up_tier(other), 0)
	assert_true(offers.is_showing())


func test_two_gifts_in_a_row_open_one_after_the_other() -> void:
	state.missions.mission_completed.emit(0)
	state.missions.mission_completed.emit(1)
	assert_eq(ready_calls.size(), 1, "the second waits")
	offers.choose(offers.current_offers[0])
	assert_eq(ready_calls.size(), 2)
	assert_eq(ready_calls[1][0], 1)


func test_a_new_run_drops_the_gift() -> void:
	state.missions.mission_completed.emit(0)
	state.start_run()
	assert_false(offers.is_showing())
	assert_eq(offers.pending.size(), 0)
