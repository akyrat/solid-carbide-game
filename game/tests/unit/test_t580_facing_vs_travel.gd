extends GutTest
## Task T-580 (investigation; no gameplay code changed): where the car points against where it
## goes. Drives the game's own driving model at the default tuning (tests/helpers/
## facing_travel_probe.gd) and prints, per case, the angle between the nose and the travel, in
## the world and on screen, with the sprite frame drawn. The asserts pin the findings so a later
## fix shows up here as a changed number:
## - straight driving: the world gap is 0, so any gap on screen is the sprite (snap and art);
## - a turn leaves sideways speed that the grip (0.98 kept per step) takes about 0.7 s to halve,
##   and W only sets the speed along the nose, so after a turn the car points one way and moves
##   another for well over a second.
## The tables are printed for the ticket's result notes (search the output for "T580").

const Probe := preload("res://tests/helpers/facing_travel_probe.gd")

var probe


func before_all() -> void:
	probe = Probe.new()


func _row(r: Dictionary) -> String:
	return "t=%.2f speed=%5.2f fwd=%6.2f side=%6.2f heading=%6.1f travel=%6.1f world_gap=%6.1f | screen nose=%6.1f travel=%6.1f gap=%6.1f | frame %2d ideal %6.1f art %6.1f snap_gap=%6.1f drawn_gap=%6.1f" % [
		r.t, r.speed, r.fwd, r.side, r.heading, r.travel, r.world_gap, r.screen_heading,
		r.screen_travel, r.screen_gap, r.frame, r.frame_screen, r.art_screen, r.snap_gap, r.drawn_gap]


func _drive_case(c: Dictionary) -> Array:
	return probe.drive(Probe.new_car(float(c.start)), c.phases)


## Straight along the 8 world directions and the 8 screen directions, W held 2 s.
func test_straight_lines_have_no_world_gap() -> void:
	print("T580 straight lines (W held 2 s, last step):")
	var dirs := []
	for i in 8:
		dirs.append(["world %d" % (i * 45), float(i * 45)])
	for i in 8:
		dirs.append(["screen %d" % (i * 45), Probe.world_heading_for_screen(float(i * 45))])
	for d in dirs:
		var m = Probe.new_car(float(d[1]))
		var rows: Array = probe.drive(m, [[100, true, false, 0.0]])
		var r: Dictionary = rows[-1]
		print("T580   %-10s %s" % [d[0], _row(r)])
		assert_almost_eq(float(r.world_gap), 0.0, 0.01, "%s: straight driving moves where it points" % d[0])
		assert_almost_eq(float(r.screen_gap), 0.0, 0.01, "%s: and on screen" % d[0])
		# The snap to 32 frames: at most half a frame (5.6 degrees) in the world; on screen it
		# grows where the projection stretches angles (up to about 11 degrees).
		assert_lt(absf(float(r.snap_gap)), 11.5, "%s: snap gap on screen" % d[0])


## The worst snap gap on screen over every heading (ideal art), and the drawn (art) gap.
func test_snap_and_art_gap_over_all_headings() -> void:
	var worst_snap := 0.0
	var worst_snap_at := 0.0
	print("T580 per frame: heading, should-be screen angle, drawn (art) screen angle, art gap:")
	for f in probe.frames:
		print("T580   frame %2d heading %6.2f ideal %6.1f art %6.1f art_gap %6.1f" % [
			int(f.index), float(f.heading_deg), float(f.nose_screen_angle_deg),
			float(f.seen_nose_screen_angle_deg_approx),
			Probe.wrap180(float(f.seen_nose_screen_angle_deg_approx) - float(f.nose_screen_angle_deg))])
	var h := 0.0
	while h < 360.0:
		var m = Probe.new_car(h)
		m.vx = cos(deg_to_rad(h))
		m.vy = sin(deg_to_rad(h))
		var r: Dictionary = probe.sample(m, 0.0)
		if absf(float(r.snap_gap)) > absf(worst_snap):
			worst_snap = float(r.snap_gap)
			worst_snap_at = h
		h += 0.25
	print("T580 worst snap gap on screen (ideal art): %.1f at world heading %.2f" % [worst_snap, worst_snap_at])
	assert_lt(absf(worst_snap), 11.5, "the 32-frame snap alone stays under about 11 degrees on screen")


## Each named case: prints a row every 0.1 s and the turn's end, and checks the slide's size.
func test_cases_print_and_measure() -> void:
	for c in Probe.cases():
		var rows := _drive_case(c)
		print("T580 case %s: %s" % [c.name, c.about])
		var last_phase: int = c.phases.size() - 1
		var throttle_start := -1
		for i in rows.size():
			var r: Dictionary = rows[i]
			if r.phase == last_phase and throttle_start < 0:
				throttle_start = i
			if i % 5 == 4 or (throttle_start == i):
				print("T580   p%d %s" % [r.phase, _row(r)])
		# The gap the moment the turn ends and W takes over.
		var first: Dictionary = rows[throttle_start]
		var half := -1.0
		for i in range(throttle_start, rows.size()):
			if absf(float(rows[i].world_gap)) <= absf(float(first.world_gap)) / 2.0:
				half = float(rows[i].t) - float(first.t)
				break
		var under5 := -1.0
		for i in range(throttle_start, rows.size()):
			if absf(float(rows[i].world_gap)) <= 5.0:
				under5 = float(rows[i].t) - float(first.t)
				break
		print("T580   summary %s: gap at W %.1f world, %.1f screen, drawn %.1f; halves in %.2f s; under 5 degrees after %.2f s" % [
			c.name, first.world_gap, first.screen_gap, first.drawn_gap, half, under5])
		# Every turn case leaves a slide of well over a sprite frame when W takes over.
		assert_gt(absf(float(first.world_gap)), 11.25, "%s: the turn leaves a slide bigger than one frame" % c.name)
		# And it takes more than half a second to halve under W.
		assert_gt(half, 0.4, "%s: the slide fades slowly" % c.name)


## The grip itself: with no steering, the sideways speed keeps 0.98 per step at every drift amount
## (the three grip values are all 0.98 at the default tuning), so it halves in 34 steps (0.69 s).
func test_grip_half_life() -> void:
	var m = Probe.new_car(0.0)
	assert_almost_eq(m.sideways_grip(11.0), 0.98, 1e-9)
	m.drift_amount = 1.0
	assert_almost_eq(m.sideways_grip(11.0), 0.98, 1e-9)
	var steps := ceili(log(0.5) / log(0.98))
	print("T580 grip 0.98 per step: half-life %d steps (%.2f s); 1/10 left after %.2f s" % [
		steps, steps * 0.02, log(0.1) / log(0.98) * 0.02])
	assert_eq(steps, 35)
