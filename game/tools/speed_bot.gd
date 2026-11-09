extends SceneTree
## The speed-stacking bot (task T-527; T-603: the wheel's new trigger). Drives the real
## car (car.gd, trick detection on) on open ground for SECONDS simulated seconds, with the
## Polarized Steering Wheel at tier 1 and at tier 2, and tries to reach the highest speeds
## it can: it chains alternate drifts (a forward drift W + steer, then a backward drift
## S + the same steer, which the trick detector pays as ALT DRIFT!, and back again) as fast
## as the rules allow, drives straight with W in between, and (optionally) charges Rev
## Charge tier 2 in between. A small grid of policies is tried; the best by peak speed is
## reported.
## Not used: ramps and jumps (the jump adds no forward speed; it only keeps it).
##
## Usage (from the repo root): bash game/tools/speed_bot.sh [--csv=<file.csv>] [--seconds=60]
## Prints per tier (0 = no wheel, the baseline; T-603): the car's normal top speed, then the best policy's peak and average
## forward speed, the peak of each 10 s window (does it keep climbing?), bursts fired.
## --csv writes time and speed for the best policy of each tier (tier 1, tier 2 columns).
## Exit code 0 always (it measures; it does not judge).

const CarScript := preload("res://scripts/driving/car.gd")

var seconds := 60.0
var trace := false
var csv := ""
var _car: CharacterBody2D


var _frames := 0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--csv="):
			csv = arg.substr(6)
		elif arg == "--trace":
			trace = true
		elif arg.begins_with("--seconds="):
			seconds = float(arg.substr(10))


## The run waits for the third physics frame: the root has no physics space before it
## (as in drive_elevation_sample.gd), and the car needs one to move.
func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _frames != 3:
		return false
	var series := {}
	for tier in [0, 1, 2]:  # T-603: tier 0 (no wheel) as the baseline
		var best := {}
		for rev in [false, true]:
			for hold in [0, 30]:
				for fwd in [16, 25, 40]:
					for back in [16, 25]:
						for chain in [1, 3]:
							var r := _run(tier, {"rev": rev, "hold": hold, "fwd": fwd, "back": back, "chain": chain})
							print("run tier %d %s -> peak %.1f avg %.1f bursts %d" % [tier, str(r.policy), r.peak, r.avg, r.bursts])
							if best.is_empty() or (r.overflow_t >= 0.0 and (best.overflow_t < 0.0 or r.overflow_t < best.overflow_t)) or (best.overflow_t < 0.0 and r.peak > best.peak):
								best = r
		_report(tier, best)
		series[tier] = best.series
	if csv != "":
		var f := FileAccess.open(csv, FileAccess.WRITE)
		f.store_line("time,tier1,tier2")
		var n: int = maxi(series[1].size(), series[2].size())
		for i in n:
			# a run that overflowed stops there; its column shows inf from then on
			var a: float = series[1][i] if i < series[1].size() else INF
			var b: float = series[2][i] if i < series[2].size() else INF
			f.store_line("%.2f,%s,%s" % [i * 0.02, str(a) if is_finite(a) else "inf", str(b) if is_finite(b) else "inf"])
	quit(0)
	return true


func _new_car(tier: int) -> CharacterBody2D:
	if _car != null:
		_car.free()
	_car = CarScript.new()
	root.add_child(_car)
	_car.set_physics_process(false)
	_car.use_keyboard = false
	_car.detect_tricks = true  # T-603: the wheel bursts on the trick detector's ALT DRIFT!
	_car.polarized.set_tier(tier)
	_car.rev_charge.set_tier(2)
	return _car


## One policy for `seconds`. Phases: REV (W+S until charged, S released = boost), HOLD
## (W straight for `hold` steps, waiting for the wheel's cooldown), then `chain` pairs of
## FWD (W + A for `fwd` steps) and BACK (S + A for `back` steps): each switch held 0.3 s
## or more is an ALT DRIFT! (the first FWD of a chain is not, it has no drift before it).
func _run(tier: int, p: Dictionary) -> Dictionary:
	var car := _new_car(tier)
	var wheel = car.polarized
	var steps := int(seconds / car.model.dt)
	var phase := "HOLD"
	var n := 0
	var pairs := 0
	var series := []
	var peak := 0.0
	var sum := 0.0
	var windows := []
	var win_peak := 0.0
	var overflow_t := -1.0
	var rev_steps := int(car.rev_charge.charge_seconds / car.model.dt) + 2
	for i in steps:
		var w := true
		var s := false
		var steer := 0.0
		match phase:
			"REV":
				s = n < rev_steps
				n += 1
				if n > rev_steps:
					phase = "HOLD"
					n = 0
			"HOLD":
				n += 1
				if n >= p.hold and wheel.is_ready() and not car.rev_charge.is_boosting():
					phase = "FWD"
					n = 0
					pairs = 0
			"FWD":
				steer = 1.0
				n += 1
				if n >= p.fwd:
					phase = "BACK"
					n = 0
			"BACK":
				w = false
				s = true
				steer = 1.0
				n += 1
				if n >= p.back:
					n = 0
					pairs += 1
					if pairs < p.chain:
						phase = "FWD"
					else:
						phase = "REV" if p.rev and not car.rev_charge.is_boosting() else "HOLD"
		car.scripted_input = [w, s, steer]
		car.physics_step()
		var v: float = car.model.get_velocity().length()
		if not is_finite(v):
			overflow_t = i * car.model.dt
			v = INF
			series.append(v)
			break
		series.append(v)
		if trace and tier == 1 and p.rev and p.hold == 0 and p.fwd == 25 and p.back == 16 and p.chain == 3 and i < 220 and i % 4 == 0:
			var hd: float = car.model.rotation
			var fw: float = car.model.vx * cos(hd) + car.model.vy * sin(hd)
			print("t %.2f %s v %.1f fwd %.1f side %.1f burst %s rev %s" % [i * 0.02, phase, v, fw, sqrt(maxf(v * v - fw * fw, 0.0)), wheel.is_bursting(), car.rev_charge.is_boosting()])
		peak = maxf(peak, v)
		sum += v
		win_peak = maxf(win_peak, v)
		if (i + 1) % 500 == 0:
			windows.append(win_peak)
			win_peak = 0.0
	var avg := sum / maxi(series.size(), 1)
	if overflow_t >= 0.0:
		peak = INF
		avg = INF
	return {"overflow_t": overflow_t, "peak": peak, "avg": avg, "windows": windows, "series": series, "policy": p,
		"bursts": wheel.bursts_fired, "top": car.model.tuning.top_speed(), "cruise": car.model.tuning.forward_speed}


func _report(tier: int, r: Dictionary) -> void:
	var win := []
	for x in r.windows:
		win.append("%.1f" % x if is_finite(x) else "inf")
	print("TIER %d  top %.1f  cruise %.1f  |  peak %.1f  avg %.1f  bursts %d  policy %s" % [
		tier, r.top, r.cruise, r.peak, r.avg, r.bursts, str(r.policy)])
	print("  peak per 10 s window: " + ", ".join(win))
	if r.overflow_t >= 0.0:
		print("  the speed overflowed to infinity/NaN at t = %.1f s" % r.overflow_t)
	var t10 := -1.0
	var t100 := -1.0
	for i in r.series.size():
		if t10 < 0.0 and r.series[i] > r.top * 10.0:
			t10 = i * 0.02
		if t100 < 0.0 and r.series[i] > r.top * 100.0:
			t100 = i * 0.02
	print("  first above 10x top speed at t = %.2f s, above 100x at t = %.2f s (-1 = never)" % [t10, t100])
