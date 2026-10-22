extends GutTest
## Task T-242: the airtime trick (Drifting, Decisions, "Airtime trick"): on
## landing, every airtime pays a combo amount that scales with its seconds
## (combo.json, "airtime"), with T-241's text "HANG TIME!".

const TrickDetector := preload("res://scripts/driving/trick_detector.gd")
const ComboDataScript := preload("res://scripts/data/combo_data.gd")
const RUN := preload("res://scenes/run/run.tscn")

const DT := 0.02

var _det
var _airtimes: Array = []
var _tricks: Array = []


func before_each() -> void:
	_det = TrickDetector.new()
	_airtimes = []
	_tricks = []
	_det.airtime_trick.connect(func(s: float) -> void: _airtimes.append(s))
	_det.trick.connect(func(id: String) -> void: _tricks.append(id))


## `steps` air steps of DT each, then the landing step.
func _jump(steps: int, turn_per_step := 0.0) -> void:
	for i in steps:
		_det.observe_air(true, turn_per_step, DT)
	_det.observe_air(false, 0.0, DT)


func test_landing_emits_the_airtime_in_seconds() -> void:
	_jump(50)
	assert_eq(_airtimes.size(), 1)
	assert_almost_eq(_airtimes[0], 1.0, 0.0001)
	assert_eq(_det.counts["airtime"], 1)
	assert_eq(_det.last_trick, "airtime")


func test_nothing_mid_air_and_nothing_without_a_jump() -> void:
	for i in 30:
		_det.observe_air(true, 0.0, DT)
	assert_eq(_airtimes, [])
	for i in 30:
		_det.observe_air(false, 0.0, DT)
	assert_eq(_airtimes.size(), 1, "pays once, on landing")


func test_two_jumps_pay_separately() -> void:
	_jump(20)
	_jump(40)
	assert_eq(_airtimes.size(), 2)
	assert_almost_eq(_airtimes[0], 0.4, 0.0001)
	assert_almost_eq(_airtimes[1], 0.8, 0.0001)


func test_the_amount_scales_with_the_airtime() -> void:
	var c = ComboDataScript.new()
	var short: float = c.airtime_add(0.5)
	var long: float = c.airtime_add(1.0)
	assert_almost_eq(short, 0.1, 0.000001, "0.5 s at 0.2 a second")
	assert_almost_eq(long, 0.2, 0.000001, "1.0 s at 0.2 a second")
	assert_gt(long, short)
	assert_almost_eq(c.airtime_add(1.23), 0.25, 0.000001, "hundredths of a second count")


func test_below_the_minimum_pays_nothing() -> void:
	var c = ComboDataScript.new()
	assert_eq(c.airtime_add(0.0), 0.0)
	assert_eq(c.airtime_add(0.28), 0.0)
	assert_gt(c.airtime_add(0.30), 0.0, "the minimum itself pays")


func test_the_cap() -> void:
	var c = ComboDataScript.new()
	assert_almost_eq(c.airtime_add(3.0), 0.6, 0.000001)
	assert_almost_eq(c.airtime_add(30.0), 0.6, 0.000001, "held at max_add")


func test_the_numbers_come_from_combo_json() -> void:
	var c = ComboDataScript.new()
	assert_true(c.is_ok())
	var d: Dictionary = GameData.load_file("combo").data["airtime"]
	assert_eq(float(d["min_seconds"]), 0.3)
	assert_eq(float(d["per_second"]), 0.2)
	assert_eq(float(d["max_add"]), 0.6)


func test_a_hop_pays_less_than_an_air_180() -> void:
	var c = ComboDataScript.new()
	assert_lt(c.airtime_add(1.0), c.trick_add("air_one_eighty"), "the rooftop drop alone is worth less than a 180")


func test_it_counts_alongside_the_air_tricks() -> void:
	# 19 steps of 9.6 degrees = a 180, in a 0.4 s airtime.
	_jump(20, deg_to_rad(9.6))
	assert_eq(_tricks, ["air_one_eighty"])
	assert_eq(_airtimes.size(), 1)


func test_reset_forgets_the_airtime() -> void:
	for i in 30:
		_det.observe_air(true, 0.0, DT)
	_det.reset()
	_det.observe_air(false, 0.0, DT)
	assert_eq(_airtimes, [])
	assert_eq(_det.counts["airtime"], 0)


func test_callers_without_dt_get_no_airtime() -> void:
	for i in 40:
		_det.observe_air(true, 0.0)
	_det.observe_air(false, 0.0)
	assert_eq(_airtimes, [])


func test_popup_text_word_for_word() -> void:
	assert_eq(TrickPopups.TEXTS["airtime"], "HANG TIME!")
	assert_eq(TrickPopups.trick_text("airtime", 0.2), "HANG TIME! +0.2")
	assert_eq(TrickPopups.trick_text("airtime", 0.25), "HANG TIME! +0.25")
	assert_eq(TrickPopups.TEXTS["air_one_eighty"], "AIR 180!")
	assert_eq(TrickPopups.TEXTS["air_three_sixty"], "AIR 360!")


func test_run_pays_the_combo_and_shows_the_popup() -> void:
	var c = ComboDataScript.new()
	for seconds in [0.5, 1.0]:
		var r: Node2D = RUN.instantiate()
		add_child_autofree(r)
		var before: float = r.state.combo
		r.car.airtime_trick.emit(seconds)
		assert_almost_eq(r.state.combo, before + c.airtime_add(seconds), 0.000001, str(seconds))
		var pop = r.trick_popups.popups().back()
		assert_eq(pop.text, "HANG TIME! +%s" % String.num(c.airtime_add(seconds), 2))


func test_run_short_hop_pays_nothing() -> void:
	var r: Node2D = RUN.instantiate()
	add_child_autofree(r)
	var before: float = r.state.combo
	r.car.airtime_trick.emit(0.2)
	assert_eq(r.state.combo, before)
	assert_eq(r.trick_popups.popups().size(), 0)
