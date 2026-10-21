extends Node
## The kaiju's meteor attack (task T-046; Enemies, Decisions): while the kaiju
## is on the map it attacks first_attack_after_seconds after it appeared, then
## every seconds_between_attacks. Each attack: a short windup (a placeholder
## flash above the kaiju) for windup_seconds, then meteors_per_attack warning
## circles appear at once on the ground near the car, and warning_seconds later
## a meteor lands on each. A meteor landing with the car's centre within
## impact_radius_units damages the car (RunState.damage_car(impact_damage)) and
## knocks it back away from the landing point (car.apply_knockback(knockback)).
## A boulder stays boulder_lifetime_seconds after it lands, then fades over
## boulder_fade_seconds and is removed (T-142).
## Each landed meteor leaves a plain boulder there through the map's
## add_meteor_boulder() (T-097), only at spots its can_place_meteor_boulder()
## accepts. Numbers: res://data/enemies.json's "meteor_attack"
## (EnemyData.meteor_attack()); nothing here changes them.
##
## The boss (kaiju_boss.gd) adds it as its child "Meteors"
## (`run.kaiju_boss.meteors`) and calls bind(run, boss). Everything moves in
## step(), once per physics step from _physics_process, and the drawings
## animate in _process, so pausing the tree stops the attack, the warnings and
## the falling meteors. Nothing happens once the run is over. A new run
## (run.world_rebuilt) clears it all.
##
## Placement rules of this code (not balancing numbers): a landing spot is
## picked uniformly within land_within_units_of_car of the car, must pass the
## map's placement check, keep boulder_clearance_units clear of every meteor
## boulder still on the map (fading and waiting ones too) and of another meteor
## still to land (T-147), and must not overlap the kaiju's body. A boulder never appears on top of the car or the kaiju:
## when one of them is over the spot as the meteor lands, the boulder waits
## until it has moved off (the car is knocked away at once on a hit).
##
## Drawings are placeholders (Visual style, Decisions: a warning circle, a
## falling meteor, a burst of dust): the warning circles lie on the ground in
## the map's drawing, just over the ground tiles (under buildings, boulders and
## the car); the falling meteors, the dust and the windup flash are drawn over
## everything.

const KaijuScript := preload("res://scripts/enemies/kaiju.gd")

const PX_PER_UNIT := 16.0
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
## Tries per meteor to find a landing spot; a meteor with no spot found is
## left out of that attack.
const SPOT_TRIES := 40

## The placeholder warning colour: a hazard amber, clearly not Redgull red
## (Visual style allows red outside Redgull only on the kaiju alert signs).
const WARNING_COLOR := Color(1.0, 0.62, 0.12)
const WARNING_FILL := Color(1.0, 0.62, 0.12, 0.28)
## The placeholder meteor: the boulders' alien navy and purple, with a magenta glow.
const METEOR_COLOR := Color(0.20, 0.14, 0.32)
const METEOR_GLOW := Color(0.85, 0.30, 0.90)
const METEOR_OUTLINE := Color(0.05, 0.04, 0.10)
## The placeholder dust: warm grey.
const DUST_COLOR := Color(0.62, 0.58, 0.52)
## The windup flash above the kaiju: pale yellow.
const WINDUP_COLOR := Color(1.0, 0.92, 0.55)
## How long the meteor is seen falling (the last part of the warning), the
## height it falls from (screen pixels) and how long the dust lasts. Rules of
## the placeholder drawing.
const FALL_SECONDS := 0.5
const FALL_HEIGHT_PX := 220.0
const DUST_SECONDS := 0.5

## An attack's windup began (the kaiju's short animation).
signal attack_started()
## The warning circles appeared; `spots` are the landing points (units).
signal warnings_shown(spots: Array)
## A meteor landed at `units`; `hit_car` is true when it hit the car.
signal meteor_landed(units: Vector2, hit_car: bool)
## A landed meteor's boulder was placed at `units` (map.add_meteor_boulder).
signal boulder_placed(units: Vector2, body: Node)

## False stops attacks (tests and fixtures); meteors already warned still land.
var enabled := true
## Random numbers for the landing spots. Seed it for tests.
var rng := RandomNumberGenerator.new()
var data: EnemyData

var state: Node = null
var car: Node2D = null
var map: Node2D = null
var boss: Node = null

## Seconds the kaiju has been on the map (counted in steps while the run runs).
var fight_time := 0.0
## When the next attack's windup starts, in fight_time.
var next_attack_at := 0.0
## Seconds of windup left; < 0 when no windup is running.
var windup_left := -1.0
## The meteors warned and not landed yet: {units: Vector2, time_left: float}.
var warnings: Array = []
## Landed meteors whose boulder waits for the car or the kaiju to move off: Vector2 (units).
var pending_boulders: Array = []
## Boulders on the map that will fade (T-142): {"body": Node, "age": seconds since it was placed}.
var standing_boulders: Array = []
## Dust bursts being drawn: {units: Vector2, age: float}.
var dust: Array = []

## The ground drawing (warning circles), in the map's View; and the sky drawing.
var ground_draw: Node2D = null
var sky_draw: Node2D = null

var _stats: Dictionary
var _run: Node = null
var _was_live := false


func _init() -> void:
	data = EnemyData.new()
	_stats = data.meteor_attack()
	rng.randomize()
	next_attack_at = _stats.get("first_attack_after_seconds", 0.0)


func stat(key: String) -> float:
	return float(_stats.get(key, 0.0))


## Binds the attack to a run scene (run.gd) and its kaiju boss (kaiju_boss.gd).
func bind(run: Node, kaiju_boss: Node) -> void:
	_run = run
	boss = kaiju_boss
	state = run.state
	sky_draw = _SkyDraw.new()
	sky_draw.name = "MeteorSky"
	sky_draw.owner_attack = self
	sky_draw.z_index = RenderingServer.CANVAS_ITEM_Z_MAX - 16
	run.add_child(sky_draw)
	run.world_rebuilt.connect(_on_world_rebuilt)
	if run.car != null:
		_on_world_rebuilt()


func _on_world_rebuilt() -> void:
	car = _run.car
	map = _run.map
	clear()
	ground_draw = _GroundDraw.new()
	ground_draw.name = "MeteorWarnings"
	ground_draw.owner_attack = self
	map.view_root.add_child(ground_draw)
	# The map's View applies the isometric transform; the circles are drawn in
	# the view's screen pixels, as the map's ground tiles and boulder sprites are.
	ground_draw.transform = map.view_root.transform.affine_inverse()
	var after: Node = map.view_root.get_node_or_null("DriftMarks")
	if after == null:
		after = map.ground_tiles
	map.view_root.move_child(ground_draw, after.get_index() + 1)


## Forgets every attack, warning, meteor and dust (a new run).
func clear() -> void:
	fight_time = 0.0
	next_attack_at = stat("first_attack_after_seconds")
	windup_left = -1.0
	warnings.clear()
	pending_boulders.clear()
	standing_boulders.clear()
	dust.clear()
	_was_live = false
	_redraw()


func _physics_process(delta: float) -> void:
	step(delta)


func _kaiju() -> Node:
	if boss == null:
		return null
	var k = boss.get("kaiju")
	if k == null or not is_instance_valid(k) or k.is_dead():
		return null
	return k


## One physics step of `dt` seconds: the attack clock, the windup, the warnings
## counting down and meteors landing, boulders waiting for the spot to clear.
func step(dt: float) -> void:
	if car == null or not is_instance_valid(car) or map == null:
		return
	if state != null and not state.is_running():
		return
	var k := _kaiju()
	if k != null:
		if not _was_live:
			_was_live = true
			fight_time = 0.0
			next_attack_at = stat("first_attack_after_seconds")
		fight_time += dt
		if enabled and windup_left < 0.0 and fight_time >= next_attack_at:
			start_attack()
			next_attack_at += stat("seconds_between_attacks")
	if windup_left >= 0.0:
		windup_left -= dt
		if windup_left <= 0.0:
			windup_left = -1.0
			drop_meteors()
	var landed: Array = []
	for w in warnings:
		w.time_left -= dt
		if w.time_left <= 0.0:
			landed.append(w)
	for w in landed:
		warnings.erase(w)
		land(w.units)
	_place_waiting_boulders()
	_age_boulders(dt)
	for d in dust:
		d.age += dt
	dust = dust.filter(func(d) -> bool: return d.age < DUST_SECONDS)
	_redraw()


## Starts an attack: the windup (windup_seconds), after which the meteors drop.
func start_attack() -> void:
	windup_left = stat("windup_seconds")
	attack_started.emit()
	if windup_left <= 0.0:
		windup_left = -1.0
		drop_meteors()


func is_winding_up() -> bool:
	return windup_left >= 0.0


## Shows meteors_per_attack warning circles at once near the car (fewer if not
## enough spots are found). Returns the landing spots (units).
func drop_meteors() -> Array:
	var spots: Array = []
	for i in int(stat("meteors_per_attack")):
		var p = pick_spot()
		if p == null:
			continue
		add_warning(p)
		spots.append(p)
	warnings_shown.emit(spots)
	return spots


## Adds one warning circle at `units`; its meteor lands warning_seconds later.
func add_warning(units: Vector2) -> Dictionary:
	var w := {"units": units, "time_left": stat("warning_seconds")}
	warnings.append(w)
	_redraw()
	return w


## A landing spot within land_within_units_of_car of the car that the map's
## placement check accepts, clear of meteors still to land and of the kaiju's
## body; null when none of SPOT_TRIES tries is.
func pick_spot():
	var c: Vector2 = car.position / PX_PER_UNIT
	var reach := stat("land_within_units_of_car")
	for _t in SPOT_TRIES:
		var p := c + Vector2.RIGHT.rotated(rng.randf() * TAU) * reach * sqrt(rng.randf())
		if is_good_spot(p):
			return p
	return null


func is_good_spot(units: Vector2) -> bool:
	if not map.can_place_meteor_boulder(units):
		return false
	var d: float = map.boulder_diameter()
	# T-147: clear of every boulder a meteor left that is still on the map (standing
	# or fading), by boulder_clearance_units of free ground between the circles.
	var apart := d + stat("boulder_clearance_units")
	for b in map.meteor_boulders:
		if Vector2(float(b.x), float(b.y)).distance_to(units) < apart:
			return false
	for w in warnings:
		if w.units.distance_to(units) < apart:
			return false
	for p in pending_boulders:
		if p.distance_to(units) < apart:
			return false
	var k := _kaiju()
	if k != null and k.position_units().distance_to(units) < d / 2.0 + KaijuScript.RADIUS_UNITS:
		return false
	return true


## A meteor lands at `units`: the dust, the hit on the car if its centre is
## within impact_radius_units, and the boulder (now, or once the spot is clear).
## Returns true when it hit the car.
func land(units: Vector2) -> bool:
	var hit := false
	var car_units: Vector2 = car.position / PX_PER_UNIT
	if car_units.distance_to(units) <= stat("impact_radius_units"):
		hit = true
		if state != null:
			state.damage_car(stat("impact_damage"))
		var away := car_units - units
		if away.length() < 0.001:
			away = Vector2.RIGHT.rotated(car.rotation + PI)  # straight on: backwards
		car.apply_knockback(away, stat("knockback"))
	dust.append({"units": units, "age": 0.0})
	meteor_landed.emit(units, hit)
	pending_boulders.append(units)
	_place_waiting_boulders()
	return hit


## Places each waiting boulder whose spot the car and the kaiju have left.
## A spot the placement check no longer accepts gets no boulder.
func _place_waiting_boulders() -> void:
	var placed: Array = []
	for p in pending_boulders:
		if _blocked_by_body(p):
			continue
		placed.append(p)
		if map.can_place_meteor_boulder(p):
			var body: Node = map.add_meteor_boulder(p)
			standing_boulders.append({"body": body, "age": 0.0})
			boulder_placed.emit(p, body)
	for p in placed:
		pending_boulders.erase(p)


## Ages every boulder a meteor left (T-142): it stays boulder_lifetime_seconds,
## then fades out over boulder_fade_seconds (still drawn and still blocking) and
## is removed from the map, so it no longer blocks anything.
func _age_boulders(dt: float) -> void:
	var life := stat("boulder_lifetime_seconds")
	var fade := maxf(stat("boulder_fade_seconds"), 0.0001)
	for b in standing_boulders.duplicate():
		b.age += dt
		var body: Node = b.body
		if not is_instance_valid(body):
			standing_boulders.erase(b)
		elif b.age >= life + fade:
			map.remove_meteor_boulder(body)
			standing_boulders.erase(b)
		elif b.age > life:
			map.set_meteor_boulder_alpha(body, 1.0 - (b.age - life) / fade)


## True when a boulder at `units` would be on the car's 1 x 1 body or the kaiju's.
func _blocked_by_body(units: Vector2) -> bool:
	var r: float = map.boulder_diameter() / 2.0
	var local := (units - car.position / PX_PER_UNIT).rotated(-car.rotation)
	var nearest := Vector2(clampf(local.x, -0.5, 0.5), clampf(local.y, -0.5, 0.5))
	if local.distance_to(nearest) < r:
		return true
	var k := _kaiju()
	if k != null and k.position_units().distance_to(units) < r + KaijuScript.RADIUS_UNITS:
		return true
	return false


## The flat-world circle of `radius_units` at `units`, in the view's pixels.
static func ground_ellipse(units: Vector2, radius_units: float, n: int = 32) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / float(n)
		pts.append(ISO_TRANSFORM * ((units + Vector2(cos(a), sin(a)) * radius_units) * PX_PER_UNIT))
	return pts


func _redraw() -> void:
	if ground_draw != null and is_instance_valid(ground_draw):
		ground_draw.queue_redraw()
	if sky_draw != null and is_instance_valid(sky_draw):
		sky_draw.queue_redraw()


## The warning circles on the ground: a translucent amber disc the size of the
## boulder to come, a thick amber edge, and an inner ring closing in as the
## meteor gets near (the time left).
class _GroundDraw extends Node2D:
	var owner_attack: Node
	var _pulse := 0.0

	func _process(delta: float) -> void:
		_pulse = fmod(_pulse + delta * 3.0, 1.0)
		if not owner_attack.warnings.is_empty():
			queue_redraw()

	func _draw() -> void:
		var a = owner_attack
		if a.map == null:
			return
		var r: float = a.map.boulder_diameter() / 2.0
		var total: float = maxf(a.stat("warning_seconds"), 0.001)
		for w in a.warnings:
			var disc: PackedVector2Array = a.ground_ellipse(w.units, r)
			draw_colored_polygon(disc, WARNING_FILL)
			var edge := disc.duplicate()
			edge.append(disc[0])
			var width := 2.0 + 1.0 * sin(_pulse * TAU)
			draw_polyline(edge, WARNING_COLOR, 2.0 + width)
			var t: float = clampf(w.time_left / total, 0.0, 1.0)
			if t > 0.02:
				var inner: PackedVector2Array = a.ground_ellipse(w.units, r * t)
				inner.append(inner[0])
				draw_polyline(inner, WARNING_COLOR, 2.0)


## Over everything: the windup flash above the kaiju, the falling meteors and
## the dust bursts.
class _SkyDraw extends Node2D:
	var owner_attack: Node
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		var a = owner_attack
		if a.is_winding_up() or not a.warnings.is_empty() or not a.dust.is_empty():
			queue_redraw()

	func _draw() -> void:
		var a = owner_attack
		var k = a._kaiju()
		if a.is_winding_up() and k != null:
			var head: Vector2 = ISO_TRANSFORM * k.position - Vector2(0, KaijuScript.HEIGHT_UNITS * PX_PER_UNIT * 0.85)
			for i in 3:
				var f := fmod(_t * 2.5 + i / 3.0, 1.0)
				draw_arc(head, 8.0 + f * 30.0, 0.0, TAU, 24, WINDUP_COLOR, 3.0 * (1.0 - f) + 1.0)
		for w in a.warnings:
			if w.time_left > FALL_SECONDS:
				continue
			var p: float = 1.0 - w.time_left / FALL_SECONDS  # 0 at the top, 1 landed
			var ground: Vector2 = ISO_TRANSFORM * (w.units * PX_PER_UNIT)
			var at := ground - Vector2(-20.0, FALL_HEIGHT_PX) * (1.0 - p)
			var back := Vector2(-20.0, FALL_HEIGHT_PX).normalized()
			draw_line(at, at - back * 30.0, METEOR_GLOW, 6.0)
			draw_circle(at, 13.0, METEOR_OUTLINE)
			draw_circle(at, 11.0, METEOR_COLOR)
			draw_circle(at + Vector2(3, -3), 4.0, METEOR_GLOW)
		for d in a.dust:
			var f: float = d.age / DUST_SECONDS
			var c: Vector2 = ISO_TRANSFORM * (d.units * PX_PER_UNIT)
			for i in 8:
				var dir := Vector2.RIGHT.rotated(TAU * i / 8.0)
				var off := Vector2(dir.x, dir.y * 0.5) * (10.0 + f * 34.0)
				draw_circle(c + off, 9.0 * (1.0 - f) + 2.0, DUST_COLOR)
