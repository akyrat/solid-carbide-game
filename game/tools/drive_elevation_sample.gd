extends SceneTree
## The scripted reachability drive on the elevation sample map (task T-195):
## the real car (car.gd, car_height.gd) in the sample map scene (T-196), driven
## by scripted inputs from the street up a 0-to-3 ramp, up a 3-to-6 ramp, then
## off a height-6 edge. Prints a log: each layer reached, the jumps, the maximum
## height and the airtime of the jump off the edge.
##
## Usage (normally through tools/drive_elevation_sample.sh or .ps1, from the repo root):
##   godot --headless --path game -s res://tools/drive_elevation_sample.gd -- \
##       [--csv=<file.csv>] [--plot=<file.png>]
## --csv writes one line per physics step (time, position, height, the ground's
## height under the car, airborne). --plot draws the height over time as a PNG
## (and <name>_light.png on a light background).
## Exit codes: 0 = all three layers reached and the car landed off the edge;
## 1 = not; 2 = bad arguments or no route in the file.
##
## The route comes from the file by heights, not coordinates (plan()): the first
## 0-to-3 ramp with a 3-to-6 ramp on the rooftop it climbs to. The inputs steer
## toward waypoints along it (W held; A/D proportional to the heading error), the
## way a player would. tests/unit/test_drive_elevation_sample.gd runs the same drive.

const SCENE_PATH := "res://scenes/elevation_sample/elevation_sample_map.tscn"
## Physics steps before the drive gives up (50 per second).
const MAX_STEPS := 1500
## A waypoint counts as reached this close (units), or once the car is past it.
const WAYPOINT_RADIUS := 1.5
## Steering per radian of heading error (clamped to -1..1, A/D).
const STEER_GAIN := 2.5
## Steps the drive goes on, W released, after landing off the edge.
const STEPS_AFTER_LANDING := 25
## Units in front of the 0-to-3 ramp's foot where the drive starts (the scene's start).
const START_BEFORE_FOOT := 4.0

var _frames := 0
var _scene: Node
var _csv := ""
var _plot := ""


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--csv="):
			_csv = arg.substr(6)
		elif arg.begins_with("--plot="):
			_plot = arg.substr(7)
		else:
			printerr("drive_elevation_sample.gd: unknown argument '%s'" % arg)
			quit(2)
			return
	_scene = load(SCENE_PATH).instantiate()
	root.add_child(_scene)
	prepare(_scene)


## The drive waits two physics frames: new static bodies (the map's buildings
## and boulders) join the physics space on the next physics frame.
func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _frames != 3:
		return false
	var route := plan(_scene.ground_height)
	if route.is_empty():
		printerr("drive_elevation_sample.gd: no 0-to-3 ramp with a 3-to-6 ramp on its rooftop in the file")
		quit(2)
		return false
	var result := drive(_scene, route)
	for line in log_lines(result):
		print(line)
	if _csv != "":
		_write(_csv, csv_text(result))
		print("Saved %s" % _csv)
	if _plot != "":
		plot_image(result, false).save_png(_plot)
		var light := _plot.get_basename() + "_light.png"
		plot_image(result, true).save_png(light)
		print("Saved %s and %s" % [_plot, light])
	quit(0 if result.passed else 1)
	return false


static func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


## Puts the scene's car on scripted inputs (no keyboard, no tricks, not stepped by itself).
static func prepare(scene: Node) -> void:
	scene.car.set_physics_process(false)
	scene.car.use_keyboard = false
	scene.car.detect_tricks = false


# ---- The route ---------------------------------------------------------------------

## The direction a ramp climbs, from its foot to its top.
static func climb_dir(r: Dictionary) -> Vector2:
	match str(r.side):
		"east":
			return Vector2.LEFT
		"west":
			return Vector2.RIGHT
		"south":
			return Vector2.UP
		_:
			return Vector2.DOWN


static func _ramp_ends(r: Dictionary) -> Array:
	var d := climb_dir(r)
	var length: float = r.rect.size.x if d.x != 0.0 else r.rect.size.y
	var c: Vector2 = r.rect.get_center()
	return [c - d * length / 2.0, c + d * length / 2.0]


static func _platform(ground, id: String) -> Dictionary:
	for p in ground.platforms:
		if p.id == id:
			return p
	return {}


## The route from the file: {"start", "rotation", "ramp_0_3", "ramp_3_6",
## "rooftop_3", "rooftop_6", "waypoints": [{"name", "point"}]}, or {} when the
## file has no 0-to-3 ramp with a 3-to-6 ramp on the rooftop it climbs to.
static func plan(ground) -> Dictionary:
	for r1 in ground.ramps:
		if not (is_equal_approx(float(r1.bottom_height), 0.0) and is_equal_approx(float(r1.top_height), 3.0)):
			continue
		for r2 in ground.ramps:
			if not (is_equal_approx(float(r2.bottom_height), 3.0) and is_equal_approx(float(r2.top_height), 6.0)):
				continue
			var top6 := _platform(ground, r2.platform)
			if top6.is_empty() or str(top6.get("on", "")) != r1.platform:
				continue
			var d1 := climb_dir(r1)
			var d2 := climb_dir(r2)
			var e1 := _ramp_ends(r1)
			var e2 := _ramp_ends(r2)
			# Across the height-6 rooftop along the second ramp's direction, to its far edge.
			var edge: Vector2 = e2[1] + d2 * 0.5
			for i in 400:
				var next: Vector2 = edge + d2 * 0.5
				if not ground.ramp_at(next).is_empty() or not is_equal_approx(ground.height_at(next), 6.0):
					break
				edge = next
			return {
				"start": e1[0] - d1 * START_BEFORE_FOOT,
				"rotation": d1.angle(),
				"ramp_0_3": r1.id,
				"ramp_3_6": r2.id,
				"rooftop_3": r1.platform,
				"rooftop_6": r2.platform,
				"waypoints": [
					{"name": "the 0-to-3 ramp's foot", "point": e1[0]},
					{"name": "on the height-3 rooftop", "point": e1[1] + d1 * 3.0},
					{"name": "the run-up to the 3-to-6 ramp", "point": e2[0] - d2 * 5.0},
					{"name": "the 3-to-6 ramp's foot", "point": e2[0]},
					{"name": "the 3-to-6 ramp's top", "point": e2[1]},
					{"name": "the height-6 edge", "point": edge},
					{"name": "past the edge", "point": edge + d2 * 12.0},
				],
			}
	return {}


# ---- The drive ---------------------------------------------------------------------

## A ground layer when the car is on flat ground at 0, 3 or 6 (not on a ramp), else -1.
static func layer_at(ground, pos: Vector2, height: float, airborne: bool) -> int:
	if airborne or not ground.ramp_at(pos).is_empty():
		return -1
	for h in [0, 3, 6]:
		if absf(height - float(h)) < 0.001:
			return h
	return -1


## Drives the scene's car along the route (stopping after max_steps physics
## steps at most, for the screenshot fixtures) and returns what happened:
## {"route", "passed", "problems", "layers" ([layer, time] in order),
## "waypoints" ([name, time]), "jumps" ([{from_ramp, t0, t1, h0, vz, max_h,
## land_h, airtime, impact, landed}]), "edge_jump" (index or -1), "max_height",
## "max_height_t", "hits", "hit_list" ([{t, at, speed, what}]), "samples"
## ([t, x, y, height, ground, airborne, w, steer])}.
static func drive(scene: Node, route: Dictionary, max_steps: int = MAX_STEPS) -> Dictionary:
	var car = scene.car
	var ground = scene.ground_height
	scene.place_car(route.start, route.rotation)
	var dt: float = car.model.dt
	var out := {"route": route, "passed": false, "problems": [], "layers": [], "waypoints": [],
		"jumps": [], "edge_jump": -1, "max_height": car.height, "max_height_t": 0.0, "hits": 0,
		"hit_list": [], "samples": []}
	var clock := [0.0]
	var jumps: Array = out.jumps
	var on_takeoff := func(from_ramp: bool, vz: float) -> void:
		jumps.append({"from_ramp": from_ramp, "t0": clock[0], "h0": car.height, "vz": vz,
			"max_h": car.height, "landed": false, "t1": 0.0, "airtime": 0.0, "land_h": 0.0,
			"impact": 0.0, "at": car.model.get_position()})
	var on_landed := func(impact: float) -> void:
		if jumps.is_empty():
			return
		var j: Dictionary = jumps[-1]
		j.landed = true
		j.t1 = clock[0]
		j.airtime = j.t1 - j.t0
		j.land_h = car.height
		j.impact = impact
		j.land_at = car.model.get_position()
	var on_hit := func(c, _i, _n, s: float) -> void:
		out.hits += 1
		out.hit_list.append({"t": clock[0], "at": car.model.get_position(), "speed": s,
			"what": "a side of the ground" if c == ground else "a building, boulder or wall"})
	car.height_model.took_off.connect(on_takeoff)
	car.height_model.landed.connect(on_landed)
	car.hit_obstacle.connect(on_hit)

	var wps: Array = route.waypoints
	var wp := 0
	var prev_point: Vector2 = route.start
	var last_layer := -1
	var after_landing := -1
	var pos: Vector2 = car.model.get_position()
	_note_layer(out, layer_at(ground, pos, car.height, car.airborne), 0.0)
	if not out.layers.is_empty():
		last_layer = out.layers[-1][0]
	out.samples.append([0.0, pos.x, pos.y, car.height, ground.height_at(pos), false, false, 0.0])
	for step in max_steps:
		pos = car.model.get_position()
		# Next waypoint: reached, or passed along the leg to it.
		while wp < wps.size():
			var target: Vector2 = wps[wp].point
			var leg: Vector2 = (target - prev_point).normalized()
			if pos.distance_to(target) < WAYPOINT_RADIUS or (pos - target).dot(leg) >= 0.0:
				out.waypoints.append([wps[wp].name, clock[0]])
				prev_point = target
				wp += 1
			else:
				break
		var steer := 0.0
		# W held until the car leaves the height-6 edge, then released (it coasts).
		var w: bool = out.edge_jump < 0
		if wp < wps.size():
			var desired: float = (wps[wp].point - pos).angle()
			var err := wrapf(desired - car.model.rotation, -PI, PI)
			steer = clampf(-err * STEER_GAIN, -1.0, 1.0)
			if absf(steer) < 0.02:
				steer = 0.0
		car.scripted_input = [w, false, steer]
		car.physics_step()
		clock[0] += dt
		pos = car.model.get_position()
		if car.airborne and not jumps.is_empty():
			jumps[-1].max_h = maxf(jumps[-1].max_h, car.height)
		if car.height > out.max_height:
			out.max_height = car.height
			out.max_height_t = clock[0]
		var layer := layer_at(ground, pos, car.height, car.airborne)
		if layer >= 0 and layer != last_layer:
			_note_layer(out, layer, clock[0])
			last_layer = layer
		out.samples.append([clock[0], pos.x, pos.y, car.height, ground.height_at(pos), car.airborne, w, steer])
		# The jump off the edge: the first fall (not a ramp takeoff) from height 6.
		if out.edge_jump < 0:
			for k in jumps.size():
				if not jumps[k].from_ramp and absf(jumps[k].h0 - 6.0) < 0.001:
					out.edge_jump = k
					break
		if after_landing < 0 and out.edge_jump >= 0 and jumps[out.edge_jump].landed:
			after_landing = 0
		elif after_landing >= 0:
			after_landing += 1
			if after_landing >= STEPS_AFTER_LANDING:
				break
	car.height_model.took_off.disconnect(on_takeoff)
	car.height_model.landed.disconnect(on_landed)
	car.hit_obstacle.disconnect(on_hit)

	var seen := []
	for l in out.layers:
		seen.append(l[0])
	for need in [0, 3, 6]:
		if not seen.has(need):
			out.problems.append("never on height %d" % need)
	var i3 := seen.find(3)
	var i6 := seen.find(6)
	if i3 >= 0 and i6 >= 0 and i6 < i3:
		out.problems.append("height 6 before height 3")
	if out.edge_jump < 0:
		out.problems.append("never went off a height-6 edge")
	elif not jumps[out.edge_jump].landed:
		out.problems.append("never landed after the height-6 edge")
	out.passed = out.problems.is_empty()
	return out


static func _note_layer(out: Dictionary, layer: int, t: float) -> void:
	if layer >= 0:
		out.layers.append([layer, t])


# ---- The log -----------------------------------------------------------------------

static func _layer_name(h: float) -> String:
	if absf(h) < 0.001:
		return "the street (0)"
	return "height %s" % str(snappedf(h, 0.01))


static func log_lines(r: Dictionary) -> PackedStringArray:
	var route: Dictionary = r.route
	var lines := PackedStringArray()
	lines.append("Elevation sample drive (T-195): from the street (%.1f, %.1f) up %s onto %s, up %s onto %s, then off its edge"
		% [route.start.x, route.start.y, route.ramp_0_3, route.rooftop_3, route.ramp_3_6, route.rooftop_6])
	var parts := PackedStringArray()
	for l in r.layers:
		parts.append("%d at %.2f s" % [l[0], l[1]])
	lines.append("Layers reached, in order: %s" % ", ".join(parts))
	parts = PackedStringArray()
	for wpt in r.waypoints:
		parts.append("%s %.2f s" % [wpt[0], wpt[1]])
	lines.append("Waypoints: %s" % "; ".join(parts))
	for k in r.jumps.size():
		var j: Dictionary = r.jumps[k]
		var kind := "off a ramp's top" if j.from_ramp else "off an edge"
		if k == r.edge_jump:
			kind = "off the height-6 edge"
		var landed := "landed on %s at %.2f s (impact %.2f units/s)" % [_layer_name(j.land_h), j.t1, j.impact] \
			if j.landed else "never landed"
		lines.append("Jump %d, %s at %.2f s: from height %.2f, takeoff vertical speed %.2f units/s, max height %.2f, airtime %.2f s, %s"
			% [k + 1, kind, j.t0, j.h0, j.vz, j.max_h, j.airtime, landed])
	lines.append("Maximum height: %.2f units, at %.2f s" % [r.max_height, r.max_height_t])
	if r.edge_jump >= 0:
		var e: Dictionary = r.jumps[r.edge_jump]
		lines.append("Airtime of the jump off the height-6 edge: %.2f s" % e.airtime)
	lines.append("Wall and obstacle hits: %d" % r.hits)
	for h in r.hit_list:
		lines.append("  hit %s at %.2f s at (%.1f, %.1f), %.2f units/s" % [h.what, h.t, h.at.x, h.at.y, h.speed])
	var last: Array = r.samples[-1]
	lines.append("Ended at (%.1f, %.1f), height %.2f, after %.2f s" % [last[1], last[2], last[3], last[0]])
	if r.passed:
		lines.append("PASS: the street, height 3 and height 6 reached, and the car landed off the height-6 edge")
	else:
		lines.append("FAIL: %s" % "; ".join(PackedStringArray(r.problems)))
	return lines


static func csv_text(r: Dictionary) -> String:
	var lines := PackedStringArray(["t_s,x,y,height,ground,airborne,w,steer"])
	for s in r.samples:
		lines.append("%.2f,%.3f,%.3f,%.4f,%.4f,%d,%d,%.3f" % [s[0], s[1], s[2], s[3], s[4], 1 if s[5] else 0, 1 if s[6] else 0, s[7]])
	return "\n".join(lines) + "\n"


# ---- The plot ----------------------------------------------------------------------

const PLOT_W := 960
const PLOT_H := 360
const PLOT_LEFT := 40
const PLOT_RIGHT := 16
const PLOT_TOP := 16
const PLOT_BOTTOM := 30
const PLOT_MAX_H := 7.0
## A 3 x 5 pixel font for the axis numbers (each row 3 bits, left bit first).
const DIGITS := {
	"0": [7, 5, 5, 5, 7], "1": [2, 6, 2, 2, 7], "2": [7, 1, 7, 4, 7], "3": [7, 1, 7, 1, 7],
	"4": [5, 5, 7, 1, 1], "5": [7, 4, 7, 1, 7], "6": [7, 4, 7, 5, 7], "7": [7, 1, 1, 1, 1],
	"8": [7, 5, 7, 5, 7], "9": [7, 5, 7, 1, 7], "s": [0, 7, 4, 1, 7], ".": [0, 0, 0, 0, 2],
}


## The height over time: the car's height (bright line), the ground's height
## under the car (thinner, darker line), the air time shaded, lines at 0, 3 and 6
## with their numbers on the left, and a tick and number every second.
static func plot_image(r: Dictionary, light: bool) -> Image:
	var bg := Color8(240, 240, 236) if light else Color8(24, 26, 32)
	var grid := Color8(200, 200, 196) if light else Color8(60, 64, 76)
	var axis := Color8(90, 90, 90) if light else Color8(170, 170, 180)
	var air := Color8(214, 228, 244) if light else Color8(34, 46, 66)
	var ground_c := Color8(150, 110, 60) if light else Color8(170, 130, 80)
	var car_c := Color8(20, 90, 200) if light else Color8(90, 200, 255)
	var img := Image.create(PLOT_W, PLOT_H, false, Image.FORMAT_RGBA8)
	img.fill(bg)
	var samples: Array = r.samples
	var t_max: float = maxf(1.0, ceilf(samples[-1][0]))
	var x_of := func(t: float) -> int:
		return PLOT_LEFT + roundi(t / t_max * float(PLOT_W - PLOT_LEFT - PLOT_RIGHT))
	var y_of := func(h: float) -> int:
		return PLOT_H - PLOT_BOTTOM - roundi(h / PLOT_MAX_H * float(PLOT_H - PLOT_TOP - PLOT_BOTTOM))
	for i in range(1, samples.size()):
		if samples[i][5]:
			for x in range(x_of.call(samples[i - 1][0]), x_of.call(samples[i][0]) + 1):
				for y in range(PLOT_TOP, PLOT_H - PLOT_BOTTOM):
					img.set_pixel(x, y, air)
	for h in [3.0, 6.0]:
		_hline(img, PLOT_LEFT, PLOT_W - PLOT_RIGHT, y_of.call(h), grid)
	for sec in range(0, int(t_max) + 1):
		var x: int = x_of.call(float(sec))
		for y in range(PLOT_H - PLOT_BOTTOM, PLOT_H - PLOT_BOTTOM + 4):
			img.set_pixel(x, y, axis)
		_text(img, str(sec), x - 2, PLOT_H - PLOT_BOTTOM + 8, axis, 2)
	_text(img, "s", x_of.call(t_max) - 2 + 4 * 2 * str(int(t_max)).length() + 2, PLOT_H - PLOT_BOTTOM + 8, axis, 2)
	for h in [0, 3, 6]:
		_text(img, str(h), PLOT_LEFT - 14, y_of.call(float(h)) - 5, axis, 2)
	_hline(img, PLOT_LEFT, PLOT_W - PLOT_RIGHT, y_of.call(0.0), axis)
	for k in range(PLOT_TOP, PLOT_H - PLOT_BOTTOM + 1):
		img.set_pixel(PLOT_LEFT, k, axis)
	for i in range(1, samples.size()):
		var a: Array = samples[i - 1]
		var b: Array = samples[i]
		_line(img, x_of.call(a[0]), y_of.call(a[4]), x_of.call(b[0]), y_of.call(b[4]), ground_c, 1)
	for i in range(1, samples.size()):
		var a: Array = samples[i - 1]
		var b: Array = samples[i]
		_line(img, x_of.call(a[0]), y_of.call(a[3]), x_of.call(b[0]), y_of.call(b[3]), car_c, 2)
	return img


static func _hline(img: Image, x0: int, x1: int, y: int, c: Color) -> void:
	for x in range(x0, x1 + 1):
		img.set_pixel(x, y, c)


static func _line(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color, width: int) -> void:
	var n := maxi(absi(x1 - x0), absi(y1 - y0))
	for i in n + 1:
		var t := 0.0 if n == 0 else float(i) / float(n)
		var x := roundi(lerpf(x0, x1, t))
		var y := roundi(lerpf(y0, y1, t))
		for dx in width:
			for dy in width:
				var px := x + dx
				var py := y + dy - width / 2
				if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
					img.set_pixel(px, py, c)


static func _text(img: Image, s: String, x: int, y: int, c: Color, scale: int) -> void:
	for ch in s:
		var rows: Array = DIGITS.get(ch, [0, 0, 0, 0, 0])
		for ry in 5:
			for rx in 3:
				if (int(rows[ry]) >> (2 - rx)) & 1:
					for sx in scale:
						for sy in scale:
							var px := x + rx * scale + sx
							var py := y + ry * scale + sy
							if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
								img.set_pixel(px, py, c)
		x += 4 * scale
