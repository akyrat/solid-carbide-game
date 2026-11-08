extends GutTest
## Task T-583: the car points where it goes. Fix A (the frame remap, car_facing.gd) and fix C (the
## grip outside a drift, car_model.gd sideways_grip), each switchable in data/car_facing.json.
## Checks each fix on its own, then measures T-580's cases (tests/helpers/facing_travel_probe.gd)
## for every combination, none, A, C and A+C, and prints the table for the ticket's result notes
## (search the output for "T583").

const Probe := preload("res://tests/helpers/facing_travel_probe.gd")
const CarFacing := preload("res://scripts/driving/car_facing.gd")
const CarModel := preload("res://scripts/driving/car_model.gd")
const CarTuning := preload("res://scripts/driving/car_tuning.gd")
const CarSpriteScript := preload("res://scripts/driving/car_sprite.gd")
const CarOutline := preload("res://scripts/driving/car_outline.gd")

const COMBOS := ["none", "A", "C", "AC"]


func after_each() -> void:
	CarFacing.remap_override = null


# --- The data -------------------------------------------------------------------------------

func test_data_file_has_both_switches() -> void:
	var d = JSON.parse_string(FileAccess.get_file_as_string(CarFacing.DATA_PATH))
	assert_typeof(d, TYPE_DICTIONARY)
	assert_typeof(d.frame_remap, TYPE_BOOL, "frame_remap is an on/off switch")
	assert_typeof(d.straight_grip_on, TYPE_BOOL, "straight_grip_on is an on/off switch")
	assert_between(float(d.straight_grip), 0.5, 0.98, "straight_grip is a grip per step")
	var t = CarTuning.new()
	assert_eq(t.straight_grip_on, bool(d.straight_grip_on), "the tuning reads the switch")
	assert_almost_eq(t.straight_grip, float(d.straight_grip), 1e-9, "and the value")
	t.reset_to_unity()
	assert_false(t.straight_grip_on, "the Unity values turn fix C off")
	t.reset_to_defaults()
	assert_eq(t.straight_grip_on, bool(d.straight_grip_on), "the defaults turn it back to the data")


# --- Fix A ----------------------------------------------------------------------------------

## With the remap on, every heading gets the frame whose drawn angle is closest on screen.
func test_remap_picks_the_closest_drawn_frame() -> void:
	var layout = JSON.parse_string(FileAccess.get_file_as_string("res://art/car/car_iso.json"))
	var angles := CarFacing.drawn_angles(layout)
	assert_eq(angles.size(), 32, "every frame of the car sheet has its drawn angle")
	CarFacing.remap_override = true
	var h := 0.0
	while h < 360.0:
		var rot := deg_to_rad(h)
		var target := CarFacing.screen_angle(rot)
		var f := CarFacing.frame_for(rot, layout)
		var best := INF
		for a in angles:
			best = minf(best, absf(CarFacing.wrap180(float(a) - target)))
		assert_almost_eq(absf(CarFacing.wrap180(float(angles[f]) - target)), best, 1e-3,
			"heading %.2f: frame %d is the closest drawing" % [h, f])
		h += 0.5
	CarFacing.remap_override = false
	assert_eq(CarFacing.frame_for(deg_to_rad(247.5), layout), 22, "off: frame = heading / 11.25")
	CarFacing.remap_override = true
	assert_ne(CarFacing.frame_for(deg_to_rad(247.5), layout), 22,
		"on: the screen up-right diagonal no longer uses frame 22, drawn straight up")


## A sheet with no drawn angles (the flat placeholder) keeps the index rule.
func test_remap_without_angles_keeps_the_index() -> void:
	CarFacing.remap_override = true
	var layout := {"frame_count": 16, "step_deg": 22.5, "frame0_heading_deg": 0.0}
	for i in 16:
		assert_eq(CarFacing.frame_for(deg_to_rad(i * 22.5), layout), i)


## The sprite, its shadowless and tilt sheets, and the rail snap's outline all follow the remap.
func test_sprite_tilt_and_outline_follow_the_remap() -> void:
	CarFacing.remap_override = true
	var sp = CarSpriteScript.new()
	sp.use_sheet("iso")
	add_child_autofree(sp)
	var rot := deg_to_rad(251.6)  # the screen's up-right diagonal
	var want := CarFacing.frame_for(rot, sp.layout)
	sp.set_heading(rot)
	assert_eq(sp.frame, want, "normal sheet")
	assert_eq(CarOutline.frame_for(rot), want, "the rail snap uses the drawing the player sees")
	sp.set_in_air(true)
	assert_eq(sp.frame, want, "shadowless sheet")
	if sp.has_tilt_art:
		sp.set_tilt_step(3)
		assert_eq(sp.frame, CarSpriteScript.tilt_frame_index(want, 3, 32), "tilt sheet, same column")
	CarFacing.remap_override = false
	sp.set_tilt_step(0)
	sp.set_heading(rot)
	assert_eq(sp.frame, sp.index_frame_for_rotation(rot), "off: the index frame")


# --- Fix C ----------------------------------------------------------------------------------

func _pair():
	var a = CarModel.new()
	a.tuning.straight_grip_on = false
	var b = CarModel.new()
	b.tuning.straight_grip_on = true
	return [a, b]


## A held drift (its start included) drives exactly as before: the grip only changes off a drift.
func test_held_drift_is_unchanged() -> void:
	var p = _pair()
	for m in p:
		for i in 60:
			m.step(true, false, 0.0)
		for i in 100:
			m.step(true, false, 1.0)
	assert_eq(p[0].vx, p[1].vx, "same velocity after 2 s of drift")
	assert_eq(p[0].vy, p[1].vy)
	assert_eq(p[0].rotation, p[1].rotation)
	# The same for a reverse drift (S + D).
	p = _pair()
	for m in p:
		for i in 60:
			m.step(false, true, 0.0)
		for i in 80:
			m.step(false, true, -1.0)
	assert_eq(p[0].get_velocity(), p[1].get_velocity(), "reverse drift unchanged")


## A coast (no W), steering or not, keeps the Unity grip: the Polarized Steering Wheel's lift and
## steer still swings the nose 60 degrees and more off the travel.
func test_coast_is_unchanged() -> void:
	var p = _pair()
	for m in p:
		for i in 75:
			m.step(true, false, 0.0)
		for i in 25:
			m.step(false, false, 1.0)
		for i in 10:
			m.step(false, false, 0.0)
	assert_eq(p[0].get_velocity(), p[1].get_velocity(), "same velocity after a coast and a turn")
	assert_eq(p[0].rotation, p[1].rotation)
	assert_gt(absf(p[1].drift_angle_deg()), 60.0, "the coast turn still leaves the nose far off the travel")


## After a turn without W (not a drift), the slide fades much faster with C once W is held.
func test_slide_after_a_turn_fades_fast() -> void:
	var p = _pair()
	var gaps := []
	for m in p:
		for i in 75:
			m.step(true, false, 0.0)
		for i in 12:
			m.step(false, false, 1.0)
		var n := 0
		while absf(m.drift_angle_deg()) > 5.0 and n < 200:
			m.step(true, false, 0.0)
			n += 1
		gaps.append(n * m.dt)
	print("T583 coast turn, then W: under 5 degrees after %.2f s (off) and %.2f s (on)" % gaps)
	assert_gt(gaps[0], 1.5, "off: the Unity grip leaves the slide for well over a second")
	assert_lt(gaps[1], 0.5, "on: the car moves where it points within half a second")


## After a drift ends, the slide fades as the drift amount falls (0.33 s), then fast.
func test_slide_out_of_a_drift_fades_after_the_drift() -> void:
	var p = _pair()
	var gaps := []
	for m in p:
		for i in 75:
			m.step(true, false, 0.0)
		for i in 12:
			m.step(true, false, 1.0)
		var n := 0
		while absf(m.drift_angle_deg()) > 5.0 and n < 200:
			m.step(true, false, 0.0)
			n += 1
		gaps.append(n * m.dt)
	print("T583 short drift, then W: under 5 degrees after %.2f s (off) and %.2f s (on)" % gaps)
	assert_gt(gaps[0], 1.5)
	assert_lt(gaps[1], 0.8, "on: straightened within a short time")
	assert_gt(gaps[1], 0.1, "but the drift still slides out a little")


# --- The table ------------------------------------------------------------------------------

## Straight lines: the drawn nose against the travel over every heading, and along the 4 screen
## diagonals and the screen up direction.
func _straight(probe) -> Dictionary:
	var worst := 0.0
	var worst_at := 0.0
	var sum := 0.0
	var n := 0
	var h := 0.0
	while h < 360.0:
		var m = probe.car(h)
		m.vx = cos(deg_to_rad(h))
		m.vy = sin(deg_to_rad(h))
		var r: Dictionary = probe.sample(m, 0.0)
		var g := absf(float(r.drawn_gap))
		sum += g
		n += 1
		if g > worst:
			worst = g
			worst_at = h
		h += 0.25
	var diag := {}
	for sdeg in [315, 45, 135, 225, 270]:
		var m = probe.car(Probe.world_heading_for_screen(float(sdeg)))
		var rows: Array = probe.drive(m, [[100, true, false, 0.0]])
		diag[sdeg] = float(rows[-1].drawn_gap)
	return {"worst": worst, "worst_at": worst_at, "mean": sum / n, "diag": diag}


func _case(probe, c: Dictionary) -> Dictionary:
	var rows: Array = probe.drive(probe.car(float(c.start)), c.phases)
	var last: int = c.phases.size() - 1
	var w := -1
	for i in rows.size():
		if rows[i].phase == last:
			w = i
			break
	var first: Dictionary = rows[w]
	var half := -1.0
	var under5 := -1.0
	for i in range(w, rows.size()):
		var g := absf(float(rows[i].world_gap))
		if half < 0.0 and g <= absf(float(first.world_gap)) / 2.0:
			half = float(rows[i].t) - float(first.t)
		if under5 < 0.0 and g <= 5.0:
			under5 = float(rows[i].t) - float(first.t)
	var at05: Dictionary = rows[mini(w + 25, rows.size() - 1)]
	var at1: Dictionary = rows[mini(w + 50, rows.size() - 1)]
	return {"world": float(first.world_gap), "drawn": float(first.drawn_gap), "half": half,
		"under5": under5, "drawn05": float(at05.drawn_gap), "drawn1": float(at1.drawn_gap),
		"end": float(rows[-1].drawn_gap)}


func test_compare_every_combination() -> void:
	var results := {}
	for combo in COMBOS:
		var probe = Probe.new()
		probe.set_combo(combo)
		var cases := {}
		for c in Probe.cases():
			cases[c.name] = _case(probe, c)
		results[combo] = {"straight": _straight(probe), "cases": cases}
	print("T583 straight lines, drawn nose minus travel on screen (degrees):")
	print("T583   combo | worst (at world heading) | mean | screen up-right 315 | down-right 45 | down-left 135 | up-left 225 | up 270")
	for combo in COMBOS:
		var s: Dictionary = results[combo].straight
		print("T583   %-4s | %5.1f (%6.2f) | %4.1f | %+5.1f | %+5.1f | %+5.1f | %+5.1f | %+5.1f" % [
			combo, s.worst, s.worst_at, s.mean, s.diag[315], s.diag[45], s.diag[135], s.diag[225], s.diag[270]])
	print("T583 cases: world gap at W | drawn gap at W, +0.5 s, +1 s, end (+2 s) | halves in s | under 5 deg after s (-1 = not within 2 s):")
	for c in Probe.cases():
		for combo in COMBOS:
			var r: Dictionary = results[combo].cases[c.name]
			print("T583   %-32s %-4s | %5.1f | %+6.1f %+6.1f %+6.1f %+6.1f | %5.2f | %5.2f" % [
				c.name, combo, r.world, r.drawn, r.drawn05, r.drawn1, r.end, r.half, r.under5])
	# A alone: the straight-line art gap falls (T-580 estimated 55 to 23 degrees worst).
	assert_lt(results.A.straight.worst, results.none.straight.worst - 20.0, "A cuts the worst straight-line gap")
	assert_lt(results.A.straight.mean, results.none.straight.mean, "and the mean")
	assert_lt(absf(results.A.straight.diag[315]), 15.0, "the screen up-right diagonal is drawn within 15 degrees")
	# C alone: the physics is unchanged in a straight line, so its straight gaps equal none's.
	assert_almost_eq(results.C.straight.worst, results.none.straight.worst, 1e-6)
	# C: every after-turn case is under 5 degrees in the world well within 2 s.
	for c in Probe.cases():
		var rc: Dictionary = results.C.cases[c.name]
		assert_between(rc.under5, 0.0, 1.0, "%s: C straightens within a second" % c.name)
		assert_lt(rc.half, results.none.cases[c.name].half, "%s: C halves the slide sooner" % c.name)
	# A+C: one second after W, the drawn car is never further from its travel than A's worst
	# straight-line art gap (what is left is the art itself: frames 20 to 24, T-584), and closer than
	# with no fix in every case.
	for c in Probe.cases():
		var d1: float = absf(results.AC.cases[c.name].drawn1)
		assert_lt(d1, results.A.straight.worst + 0.5, "%s: A+C after 1 s is down to the art" % c.name)
		assert_lt(d1, absf(results.none.cases[c.name].drawn1) + 0.01, "%s: A+C no worse than none" % c.name)


## The grip's value (the proposal's reason): for a few candidates, how long each case takes to be
## under 5 degrees in the world after W, and the slide out of a drift.
func test_grip_candidates() -> void:
	print("T583 grip candidates: per step kept | half-life s | under 5 deg after W, per case (s)")
	for g in [0.98, 0.95, 0.93, 0.9, 0.85, 0.8]:
		var probe = Probe.new()
		probe.set_combo("C")
		var parts := []
		for c in Probe.cases():
			var m = probe.car(float(c.start))
			m.tuning.straight_grip = g
			var rows: Array = probe.drive(m, c.phases)
			var last: int = c.phases.size() - 1
			var u := -1.0
			var t0 := -1.0
			for r in rows:
				if r.phase == last:
					if t0 < 0.0:
						t0 = float(r.t)
					if absf(float(r.world_gap)) <= 5.0:
						u = float(r.t) - t0
						break
			parts.append("%s %.2f" % [c.name, u])
		print("T583   %.2f | %.2f | %s" % [g, log(0.5) / log(g) * 0.02, ", ".join(parts)])
	pass_test("printed")
