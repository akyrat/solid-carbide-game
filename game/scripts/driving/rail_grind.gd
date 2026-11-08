extends RefCounted
## Rail grinding (task T-541, a prototype; Drifting, Decisions, "Rail grinding, a prototype";
## how it behaves and every proposed number: Drifting, Content, "Rail grinding (task T-541)").
## Built from the trick prototype's wall grind (hold/trick-prototype, trick_grind.gd), on the
## car's real height (car_height.gd) and the map's rails (scripts/level/rails.gd). Its numbers
## are in data/rail_grind.json (proposals; the defaults below are used when a key is missing).
##
## T-551 (the grind overhaul; Drifting, Decisions, "The grind overhaul"): the car decides WHEN
## (car.gd): find() is asked only while Space is held in the air, the grind lasts only while Space
## stays held, and letting go ends it with stop("jump"), the launch where the car faces
## (leave_velocity("jump"), at the grind's speed flat, T-578, and launch_takeoff_speed up, any car,
## no power-up).
##
## The car (car.gd) owns one, `car.grind`, and the run gives it the map's rails (`rails`).
##  - find(pos, vel, height, vz, heading, tilt_step): after each step in the air, the rail the car
##    catches. T-566 (Drifting, Decisions, "A grind starts when the car's drawing crosses the
##    rail's"): the car's drawing on screen (car_outline.gd: its own pixels for its heading and tilt
##    frame, lifted by its height) crosses the rail's drawn bar (its 3 pixel rows), whatever the
##    car's height above or below the bar, rising or falling; this replaced the catch reach, the end
##    margin and the height window. Any crossing angle catches (the board, 2026-11-07, Drifting,
##    Decisions: "A crossing square-on to the rail catches too"): a car moving along the rail at
##    `min_start_speed` or more grinds on its way along it at its speed along it, as before; one
##    slower along it (square-on, or standing) grinds the way its nose points along the rail at
##    `square_start_speed` (its velocity's way along it when the nose is exactly square). Two rails crossed:
##    the one whose bar is nearest the car's drawn centre on screen wins. The car lands on the
##    point of the bar nearest its drawn centre on screen, so its drawing barely moves at the snap.
##  - start(info, heading): locks on. The car sits on the bar facing the way it landed. Only the
##    speed along the rail is kept, and the landing boost (T-548; the board, 2026-11-06: every
##    landing on a rail boosts) adds `land_boost` units/s to it. A joint is not a landing.
##  - turn(steer, rate, dt): A or D spin the car's body (`body_heading`) as in the air (the
##    board's tweak, 2026-11-06); the car keeps sliding along the rail whatever way it faces.
##  - step(dt): slides on along the rail, losing `decel` units/s every second, and the landing
##    boost's part of the speed (`boost_left`) another `boost_decline` units/s every second until
##    it is used up; returns "end"
##    past the rail's end or "slow" below `end_speed` ("" while it goes on).
##  - Joints (T-542 round 2; the board: a joint between rail pieces at an angle must cost no speed):
##    past a rail's end, a CONNECTED rail takes the car on: another rail with an end within
##    `join_distance` of this end (flat) and `join_height` of its height, whose way on turns the
##    travel by no more than `join_max_angle_deg`. The car carries its whole speed onto that rail's
##    direction (nothing lost to the angle, no fall, no new catch), and the extra distance of the
##    step goes on along it. The grind goes on as one: its seconds and length go on adding up.
##  - stop(reason): ends it ("end", "slow", "jump": the launch when Space is let go), sending grind_ended with its seconds and
##    length, which the run pays as the GRIND! trick. leave_velocity(reason) is the car's flat
##    velocity as it leaves: along the rail; for a jump (T-548; the board, 2026-11-06) where the
##    car faces, whatever its travel along the rail (backwards too), at the speed it was grinding at
##    (T-578; the board, 2026-11-08: the momentum along the rail turns into where the car faces),
##    never under `launch_min_speed`; for a slow drop with a sideways push (`drop_side_speed`) toward the
##    side of the rail line the nose points to (nose_side()).
## The rail it left can't be caught again until the car touches the ground or another rail
## (`exclude`, cleared by touched_ground()), so a jump off a rail never lands back on it.
## Node-free: tests drive it directly.

const Rails := preload("res://scripts/level/rails.gd")
const CarOutline := preload("res://scripts/driving/car_outline.gd")

## T-566: half the thickness of the rail's drawn bar, screen px (rail_drawing.gd draws 3 rows).
const BAR_HALF_PX := 1.5

## The data file and the defaults (data/rail_grind.json explains each).
const DATA_FILE := "rail_grind"
const DEFAULTS := {
	"min_start_speed": 2.0,
	"square_start_speed": 6.0,
	"decel": 1.0,
	"end_speed": 2.0,
	"drop_side_speed": 2.0,
	"land_boost": 4.0,
	"boost_decline": 2.0,
	"launch_min_speed": 6.0,
	"launch_takeoff_speed": 5.0,
	"join_distance": 1.0,
	"join_height": 0.6,
	"join_max_angle_deg": 100.0,
}

## Sent when a grind starts, with the rail's index in `rails`.
signal grind_started(rail_index: int)
## Sent when a grind ends: why ("end", "slow" or "jump"), its seconds and its length (units).
signal grind_ended(reason: String, seconds: float, length: float)

## The numbers (data/rail_grind.json).
var min_start_speed: float = DEFAULTS.min_start_speed
## T-566: the speed along the rail a square-on catch starts at, before the landing boost (units/s).
var square_start_speed: float = DEFAULTS.square_start_speed
var decel: float = DEFAULTS.decel
var end_speed: float = DEFAULTS.end_speed
var drop_side_speed: float = DEFAULTS.drop_side_speed
var land_boost: float = DEFAULTS.land_boost
var boost_decline: float = DEFAULTS.boost_decline
## T-578: the slowest launch off a rail (units/s, flat): a launch is at the grind's speed, but never
## slower than this (T-548's old set speed, so a slow grind launches as it used to).
var launch_min_speed: float = DEFAULTS.launch_min_speed
## T-551: the launch's vertical speed off the bar (units/s, up), for any car (car.gd _leave_grind).
var launch_takeoff_speed: float = DEFAULTS.launch_takeoff_speed
var join_distance: float = DEFAULTS.join_distance
var join_height: float = DEFAULTS.join_height
var join_max_angle_deg: float = DEFAULTS.join_max_angle_deg

## The map's rails (Rails.from_layout).
var rails: Array = []
## True while grinding.
var active := false
## The rail of the current (or last) grind, and its index in `rails`.
var rail := {}
var rail_index := -1
## The car's distance along the rail from its end a (units), its speed (>= 0, units/s) and its
## direction along the rail (+1 toward end b, -1 toward end a).
var s := 0.0
var speed := 0.0
var direction := 1.0
## T-548: the part of `speed` that is still the landing boost (units/s); it fades at boost_decline.
var boost_left := 0.0
## The car's heading while grinding (radians): where it landed facing, turned by A and D.
var body_heading := 0.0
## The current grind's seconds and length so far.
var seconds := 0.0
var length := 0.0
## The rail that can't be caught (the one just left), -1 for none.
var exclude := -1
## Grinds started so far (tests, readouts).
var grinds := 0
## Joints crossed so far (tests, readouts).
var joints := 0
## T-586: the Grinding Wheels power-up (grinding_wheels.gd), or null. The car sets it; when owned,
## launch_speed() is multiplied by its launch_multiplier(seconds). Not owned or null: no change.
var wheels = null


func _init() -> void:
	load_numbers()


## Reads the numbers from data/rail_grind.json (a missing file or key keeps the default).
func load_numbers(file: String = DATA_FILE) -> void:
	var r := GameData.load_file(file)
	var d: Dictionary = r.data if r.ok and r.data is Dictionary else {}
	for k in DEFAULTS.keys():
		set(k, float(d.get(k, DEFAULTS[k])))


## The rail the car catches at `pos` (units) with flat velocity `vel` (units/s), at `height`
## (units; `vz`, its vertical speed, no longer matters since T-566; any flat velocity catches), heading `heading` (radians;
## NAN: the velocity's direction) drawn at tilt step `tilt_step` (0 to 3), or {}:
## {"index", "s", "speed_along", "screen_gap"}.
func find(pos: Vector2, vel: Vector2, height: float, _vz: float = 0.0, heading: float = NAN,
		tilt_step: int = 3) -> Dictionary:
	if is_nan(heading):
		heading = atan2(vel.y, vel.x)
	var at := CarOutline.screen_of(pos, height)
	var best := {}
	var best_gap := INF
	for i in rails.size():
		if i == exclude:
			continue
		var r: Dictionary = rails[i]
		var a := CarOutline.screen_of(r.a, float(r.za))
		var b := CarOutline.screen_of(r.b, float(r.zb))
		if not CarOutline.touches_segment(at, heading, tilt_step, a, b, BAR_HALF_PX):
			continue
		var t := snap_t(at, a, b)
		var gap := at.distance_to(a.lerp(b, t))
		if gap >= best_gap:
			continue
		best = {"index": i, "s": t * float(r.length), "speed_along": start_speed_along(vel, heading, r.dir),
			"screen_gap": gap}
		best_gap = gap
	return best


## T-566: the signed speed along a rail of direction `dir` a catch starts with (before the landing
## boost): the car's own speed along it when that is min_start_speed or more; otherwise (a square-on
## crossing) square_start_speed the way the nose (`heading`) points along it, or the velocity's way
## along it when the nose is exactly square, or toward end b when both are.
func start_speed_along(vel: Vector2, heading: float, dir: Vector2) -> float:
	var v := vel.dot(dir)
	if absf(v) >= min_start_speed:
		return v
	var nose := Vector2(cos(heading), sin(heading)).dot(dir)
	var way := signf(nose) if absf(nose) > 1e-6 else (signf(v) if absf(v) > 1e-6 else 1.0)
	return way * square_start_speed


## T-566: where along the screen segment a-b (0 to 1) the point nearest `p` is.
static func snap_t(p: Vector2, a: Vector2, b: Vector2) -> float:
	var d := b - a
	var len2 := d.length_squared()
	if len2 < 1e-9:
		return 0.0
	return clampf((p - a).dot(d) / len2, 0.0, 1.0)


## Locks onto info's rail (from find()); heading is the car's heading (radians) as it lands.
func start(info: Dictionary, heading: float) -> void:
	rail_index = int(info.index)
	rail = rails[rail_index]
	s = float(info.s)
	direction = signf(float(info.speed_along))
	boost_left = land_boost  # T-548: every landing on a rail boosts (joints never call start)
	speed = absf(float(info.speed_along)) + boost_left
	body_heading = heading
	seconds = 0.0
	length = 0.0
	exclude = -1
	active = true
	grinds += 1
	grind_started.emit(rail_index)


## A or D while grinding (steer > 0: A): the body spins at `rate_deg` degrees a second (the air
## turn rate), with the driving model's sign (A turns the heading down). The car stays on the rail.
func turn(steer: float, rate_deg: float, dt: float) -> void:
	if active:
		body_heading -= deg_to_rad(steer * rate_deg * dt)


## Slides on by dt: "" while it goes on, "end" once past the rail's end, "slow" below end_speed.
func step(dt: float) -> String:
	if not active:
		return ""
	var fade := minf(boost_left, boost_decline * dt)  # T-548: the landing boost declines
	boost_left -= fade
	speed = maxf(0.0, speed - decel * dt - fade)
	var moved := speed * dt
	s += direction * moved
	seconds += dt
	length += moved
	if (direction > 0.0 and s > float(rail.length)) or (direction < 0.0 and s < 0.0):
		var over := s - float(rail.length) if direction > 0.0 else -s
		if _cross_joint(over):
			return ""
		return "end"
	if speed < end_speed:
		return "slow"
	return ""


## T-542 round 2: the connected rail past this rail's end (see the top), as {"index", "s", "direction"} with
## s the joint's distance along it from its end a, or {}. The smallest turn wins, then the nearest end.
func joint_at_end() -> Dictionary:
	var end_s := float(rail.length) if direction > 0.0 else 0.0
	var exit_point := Rails.point_at(rail, end_s)
	var exit_h := Rails.height_at(rail, end_s)
	var best := {}
	var best_key := Vector2(INF, INF)
	var cos_max := cos(deg_to_rad(join_max_angle_deg))
	for i in rails.size():
		if i == rail_index:
			continue
		var r: Dictionary = rails[i]
		for at_b in [false, true]:
			var p: Vector2 = r.b if at_b else r.a
			var h: float = float(r.zb) if at_b else float(r.za)
			var gap := p.distance_to(exit_point)
			if gap > join_distance or absf(h - exit_h) > join_height:
				continue
			var way: Vector2 = -r.dir if at_b else r.dir  # the way on from this end
			var c := travel().dot(way)
			if c < cos_max - 1e-9:
				continue
			var key := Vector2(-c, gap)
			if key.x < best_key.x - 1e-9 or (absf(key.x - best_key.x) <= 1e-9 and key.y < best_key.y):
				best_key = key
				best = {"index": i, "s": float(r.length) if at_b else 0.0, "direction": -1.0 if at_b else 1.0}
	return best


## Crosses to the connected rail with `over` units of the step left, true when there is one.
func _cross_joint(over: float) -> bool:
	var j := joint_at_end()
	if j.is_empty():
		return false
	rail_index = int(j.index)
	rail = rails[rail_index]
	direction = float(j.direction)
	s = float(j.s) + direction * over
	# Short rails: the extra distance may pass this one's far end too (the next step crosses on).
	joints += 1
	return true


## Ends the grind: the rail can't be caught again until the ground (or another rail).
func stop(reason: String) -> void:
	if not active:
		return
	active = false
	exclude = rail_index
	grind_ended.emit(reason, seconds, length)


## The car touched the ground: every rail can be caught again.
func touched_ground() -> void:
	if not active:
		exclude = -1


## The way the car travels along the rail (unit vector, flat).
func travel() -> Vector2:
	if rail.is_empty():
		return Vector2.RIGHT
	return rail.dir * direction


## The left of the travel (unit vector, flat; y points south, so this is travel turned -90 deg).
func travel_left() -> Vector2:
	return travel().rotated(-PI / 2.0)


## Which side of the rail line the nose points to (the board's threshold, 2026-11-06): +1 left
## of the travel, -1 right, 0 exactly along the line (either way along it).
func nose_side() -> float:
	var d := Vector2(cos(body_heading), sin(body_heading)).dot(travel_left())
	if absf(d) < 1e-6:
		return 0.0
	return signf(d)


## The car's centre now: on the bar (units, flat; held at the rail's ends).
func position_units() -> Vector2:
	return Rails.point_at(rail, clampf(s, 0.0, float(rail.length)))


## The bar's height under the car (units).
func height() -> float:
	return Rails.height_at(rail, s)


## The car's flat velocity while grinding (units/s).
func velocity() -> Vector2:
	return travel() * speed


## The car's heading while grinding (radians).
func heading() -> float:
	return body_heading


## T-578: the flat speed a launch (Space let go) leaves the rail at: the grind's speed now, or
## launch_min_speed when that is higher (units/s). T-586: with Grinding Wheels owned, that floored
## speed times the wheels' launch multiplier for this grind's seconds (the floor first, then the
## boost: max(speed, launch_min_speed) x (1 + stacks / 3)).
func launch_speed() -> float:
	var base := maxf(speed, launch_min_speed)
	if wheels != null and wheels.is_owned():
		return base * float(wheels.launch_multiplier(seconds))
	return base


## The car's flat velocity as it leaves for `reason` (units/s): along the rail at its speed; a
## jump where the car faces (T-548: a car facing backwards jumps backwards) at the speed it was
## grinding at (T-578: the speed along the rail turns into the nose's direction), never under
## launch_min_speed; a slow drop with drop_side_speed toward nose_side().
func leave_velocity(reason: String) -> Vector2:
	match reason:
		"jump":
			return Vector2(cos(body_heading), sin(body_heading)) * launch_speed()
		"slow":
			return velocity() + travel_left() * nose_side() * drop_side_speed
	return velocity()
