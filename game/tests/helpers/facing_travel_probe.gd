extends RefCounted
## Task T-580 (investigation; no gameplay code changed): measures where the car points against
## where it goes, step by step, with the game's own driving model (car_model.gd at the default
## tuning) and the isometric car sheet's layout (art/car/car_iso.json). Used by
## tests/unit/test_t580_facing_vs_travel.gd (the numbers) and tests/fixtures/t580_facing_demo.gd
## (the pictures). Read only: it never changes the model's code or tuning.
##
## Angles, all in degrees:
## - heading: the body's world angle (model.rotation; 0 = world +x, clockwise on screen).
## - travel: the world angle of the velocity.
## - world_gap: travel - heading, wrapped to -180..180 (the drift angle; + = sliding right).
## - screen_heading / screen_travel: the same two directions after the run's 2:1 isometric
##   projection (screen = (x - y, (x + y) / 2), run.gd ISO_TRANSFORM), 0 = screen right,
##   clockwise (y down).
## - frame: the sheet frame car_sprite.gd draws for the heading (32 frames, 11.25 apart).
## - frame_screen: the screen angle that frame should show (the projected frame heading,
##   car_iso.json nose_screen_angle_deg): the snap alone.
## - art_screen: the screen angle the frame's drawing actually shows (car_iso.json
##   seen_nose_screen_angle_deg_approx, measured on the art in T-102).
## - snap_gap: frame_screen - screen_travel (what the player would see with ideal art).
## - drawn_gap: art_screen - screen_travel (what the player sees: drawn nose versus travel).

const CarModel := preload("res://scripts/driving/car_model.gd")
const SHEET_JSON := "res://art/car/car_iso.json"
const ISO := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)

var frames: Array = []
var step_deg := 11.25


func _init() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SHEET_JSON))
	frames = parsed.frames
	step_deg = float(parsed.step_deg)


static func wrap180(a: float) -> float:
	return fposmod(a + 180.0, 360.0) - 180.0


static func screen_angle_of(world_dir: Vector2) -> float:
	var s := ISO.basis_xform(world_dir)
	return fposmod(rad_to_deg(atan2(s.y, s.x)), 360.0)


## The world heading (degrees) whose isometric drawing points along screen angle `screen_deg`.
static func world_heading_for_screen(screen_deg: float) -> float:
	var s := Vector2(cos(deg_to_rad(screen_deg)), sin(deg_to_rad(screen_deg)))
	var w := ISO.affine_inverse().basis_xform(s)
	return fposmod(rad_to_deg(atan2(w.y, w.x)), 360.0)


func frame_for_heading(heading_deg: float) -> int:
	return posmod(roundi(heading_deg / step_deg), frames.size())


## One record for the model's state now.
func sample(m, t: float) -> Dictionary:
	var heading := fposmod(rad_to_deg(m.rotation), 360.0)
	var v := Vector2(m.vx, m.vy)
	var speed := v.length()
	var moving := speed > 0.05
	var travel := fposmod(rad_to_deg(atan2(v.y, v.x)), 360.0) if moving else heading
	var f := frame_for_heading(heading)
	var fs := float(frames[f].nose_screen_angle_deg)
	var art := float(frames[f].seen_nose_screen_angle_deg_approx)
	var sh := screen_angle_of(Vector2(cos(deg_to_rad(heading)), sin(deg_to_rad(heading))))
	var st := screen_angle_of(v) if moving else sh
	return {
		"t": t, "speed": speed, "fwd": m.forward_speed(), "side": m.sideways_speed(),
		"heading": heading, "travel": travel, "world_gap": wrap180(travel - heading),
		"screen_heading": sh, "screen_travel": st, "screen_gap": wrap180(st - sh),
		"frame": f, "frame_screen": fs, "art_screen": art,
		"snap_gap": wrap180(fs - st), "drawn_gap": wrap180(art - st),
	}


## A fresh car at the default tuning, standing, nose at world heading `heading_deg`.
static func new_car(heading_deg: float):
	var m = CarModel.new()
	m.dt = 0.02
	m.rotation = deg_to_rad(heading_deg)
	return m


## Runs a list of input phases on `m`: each phase is [steps, w, s, steer] (steer +1 = A,
## -1 = D). Returns one record per step (after the step), with the phase index.
func drive(m, phases: Array, t0 := 0.0) -> Array:
	var out := []
	var t := t0
	for p in phases.size():
		var ph: Array = phases[p]
		for i in int(ph[0]):
			m.step(bool(ph[1]), bool(ph[2]), float(ph[3]))
			t += m.dt
			var r := sample(m, t)
			r["phase"] = p
			out.append(r)
	return out


## The named cases of the investigation. Each returns {"name", "about", "car", "phases"}; the
## car is fresh, so the fixture and the test drive exactly the same thing.
## Headings picked so the end of each turn lands on a screen diagonal or a world diagonal.
static func cases() -> Array:
	# The A key turns the body counter-clockwise (rotation decreases), 191.9 deg/s,
	# 3.84 degrees a step; 12 steps = 46.1 degrees.
	return [
		{"name": "coast_then_throttle",
			"about": "W 1.5 s along world 0 (screen down-right), let go, A alone 12 steps (46 degrees, no W: not a drift), then W straight 2 s",
			"start": 0.0,
			"phases": [[75, true, false, 0.0], [12, false, false, 1.0], [100, true, false, 0.0]]},
		{"name": "coast_long_then_throttle",
			"about": "W 1.5 s along world 0, coast 1 s, A alone 12 steps, coast 0.3 s, then W straight 2 s",
			"start": 0.0,
			"phases": [[75, true, false, 0.0], [50, false, false, 0.0], [12, false, false, 1.0],
				[15, false, false, 0.0], [100, true, false, 0.0]]},
		{"name": "drift_turn_onto_diagonal",
			"about": "W 1.5 s along world 0, W + A 12 steps (a short drift turn of 46 degrees), then W straight 2 s",
			"start": 0.0,
			"phases": [[75, true, false, 0.0], [12, true, false, 1.0], [100, true, false, 0.0]]},
		{"name": "turn_onto_screen_up_right",
			"about": "W 1.5 s along screen right (world 315), W + A 17 steps (65 degrees) onto about world 250 (screen up-right diagonal), then W straight 2 s",
			"start": 315.0,
			"phases": [[75, true, false, 0.0], [17, true, false, 1.0], [100, true, false, 0.0]]},
		{"name": "coast_turn_onto_screen_up_right",
			"about": "W 1.5 s along screen right (world 315), let go, A alone 17 steps onto about world 250, then W straight 2 s",
			"start": 315.0,
			"phases": [[75, true, false, 0.0], [17, false, false, 1.0], [100, true, false, 0.0]]},
	]
