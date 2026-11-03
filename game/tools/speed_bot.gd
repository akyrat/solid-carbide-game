extends SceneTree
## The speed-stacking bot (task T-527). Drives the real car (car.gd) on open ground
## for SECONDS simulated seconds, with the Polarized Steering Wheel at tier 1 and at
## tier 2, and tries to reach the highest speeds it can: it chains the wheel's trigger
## as fast as the rules allow (W, lift, steer until the nose is 60+ degrees off, W
## again), drifts while W is held, and (optionally) charges Rev Charge tier 2 in
## between. A small grid of policies is tried; the best by peak speed is reported.
## Not used: ramps and jumps (the jump adds no forward speed; it only keeps it).
##
## Usage (from the repo root): bash game/tools/speed_bot.sh [--csv=<file.csv>] [--seconds=60]
## Prints per tier: the car's normal top speed, then the best policy's peak and average
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
	for tier in [1, 2]:
		var best := {}
		for rev in [false, true]:
			for hold in [0, 10, 30]:
				for dir in [-1.0, 1.0]:
					for drift in [0.0, 1.0]:
						var r := _run(tier, {"rev": rev, "hold": hold, "dir": dir, "drift": drift})
						print("run tier %d %s -> peak %.1f" % [tier, str(r.policy), r.peak])
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
	_car.detect_tricks = false
	_car.polarized.set_tier(tier)
	_car.rev_charge.set_tier(2)
	return _car


## One policy for `seconds`. Phases: REV (W+S until charged, S released = boost), HOLD
## (W, drifting), COAST (W up, steering until the nose is 62+ degrees off), PRESS.
func _run(tier: int, p: Dictionary) -> Dictionary:
	var car := _new_car(tier)
	var wheel = car.polarized
	var steps := int(seconds / car.model.dt)
	var phase := "HOLD"
	var n := 0
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
				steer = p.drift
				n += 1
				var ready: bool = not wheel.has_method("is_ready") or wheel.is_ready()
				if n >= p.hold and ready and not car.rev_charge.is_boosting():
					phase = "COAST"
					n = 0
			"COAST":
				w = false
				steer = p.dir
				n += 1
				var ang: float = car.polarized.angle_between(car.model.rotation, car.model.get_velocity())
				if ang >= 62.0 or n > 58:
					phase = "PRESS"
			"PRESS":
				phase = "AFTER"
				n = 0
			"AFTER":
				# a few steps of W after the press, then maybe a Rev Charge, else hold
				n += 1
				if n >= 2:
					phase = "REV" if p.rev and not car.rev_charge.is_boosting() else "HOLD"
					n = 0
		car.scripted_input = [w, s, steer]
		car.physics_step()
		var v: float = car.model.get_velocity().length()
		if not is_finite(v):
			overflow_t = i * car.model.dt
			v = INF
			series.append(v)
			break
		series.append(v)
		if trace and tier == 1 and p.rev and p.hold == 0 and p.dir == 1.0 and p.drift == 1.0 and i < 220 and i % 4 == 0:
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
