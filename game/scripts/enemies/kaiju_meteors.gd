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
##
## Paired meteors (T-539; Enemies, Decisions, "Paired meteors hurt the kaiju"):
## the meteors of an attack land in pairs, pair_distance_units apart with a
## drivable gap between the two (pick_pair). Once both of a pair have landed, a
## drifting car whose step crosses the line between their centres hurts the
## kaiju by pair_damage_to_kaiju, and both boulders break at once (strike_pair).
## Each pair pays once; a pair whose boulder is gone (faded, or never placed)
## pays nothing. Placeholders drawn in code: a faint cyan dashed line between
## the two of a pair (on the ground), and on a strike the boulders' break-up,
## a cyan and pink energy beam from the pair to the kaiju, and a burst on the
## kaiju with its red hit flash (meteor_pair_fx.gd).

const KaijuScript := preload("res://scripts/enemies/kaiju.gd")
const PairFx := preload("res://scripts/enemies/meteor_pair_fx.gd")

const EnemyHeightScript := preload("res://scripts/enemies/enemy_height.gd")

const PX_PER_UNIT := 16.0
## The shortest gap between attacks the clock accepts (T-418): a gap of 0 or less in the data
## would start an attack every step.
const MIN_ATTACK_GAP := 0.1
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
## Tries per meteor to find a landing spot; a meteor with no spot found is
## left out of that attack.
const SPOT_TRIES := 40

## The placeholder warning colour: a hazard amber, clearly not the heart's red
## (Visual style, Decisions, "Red after the rebrand": red is no longer reserved).
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
## Pairing rules of the code (T-539), not balancing numbers: tries for a pair's
## partner around each first spot, and the half width of the free path checked
## between the two boulders (the car's 1-unit body), sampled every
## GAP_SAMPLE_UNITS.
const PARTNER_TRIES := 16
const GAP_CLEAR_RADIUS := 0.5
const GAP_SAMPLE_UNITS := 0.5

## An attack's windup began (the kaiju's short animation).
signal attack_started()
## The warning circles appeared; `spots` are the landing points (units).
signal warnings_shown(spots: Array)
## A meteor landed at `units`; `hit_car` is true when it hit the car.
signal meteor_landed(units: Vector2, hit_car: bool)
## A landed meteor's boulder was placed at `units` (map.add_meteor_boulder).
signal boulder_placed(units: Vector2, body: Node)
## A drifting car crossed between the landed pair `a`-`b` (units): the kaiju
## took `damage` and both boulders broke (T-539).
signal pair_struck(a: Vector2, b: Vector2, damage: float)

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
## Meteor pairs (T-539): {a: Vector2, b: Vector2, landed: int, bodies: Array,
## paid: bool, dead: bool}. Kept from the warning until the pair pays or a
## boulder of it is gone.
var pairs: Array = []
## Strike effects being drawn (T-539): the beams {from: Vector2 units,
## to: Vector2 units, kaiju: Node, age}, and the boulders breaking {units, age}.
var links: Array = []
var breakups: Array = []

## The ground drawing (warning circles), in the map's View; and the sky drawing.
var ground_draw: Node2D = null
var sky_draw: Node2D = null

var _stats: Dictionary
var _run: Node = null
var _was_live := false
## The car's position (units) at the end of the last step, for the pair crossing.
var _last_car_units := Vector2.ZERO
var _have_last_car := false


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
	sky_draw.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
	pairs.clear()
	links.clear()
	breakups.clear()
	_have_last_car = false
	_was_live = false
	_redraw()


func _physics_process(delta: float) -> void:
	Perf.begin(&"meteors.step")
	step(delta)
	Perf.end(&"meteors.step")


## The run's minion spawner, or null (T-418).
func _spawner():
	if _run == null or not is_instance_valid(_run):
		return null
	return _run.get("minions")


## The map's ground heights (GroundHeight), or null on a flat map (T-418).
func _ground():
	var sp = _spawner()
	return sp.ground if sp != null else null


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
			next_attack_at += maxf(stat("seconds_between_attacks"), MIN_ATTACK_GAP)
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
		land(w.units, w.get("pair", {}))
	_place_waiting_boulders()
	_age_boulders(dt)
	_check_pair_crossings()
	for d in dust:
		d.age += dt
	dust = dust.filter(func(d) -> bool: return d.age < MeteorFx.impact_seconds())
	for l in links:
		l.age += dt
	links = links.filter(func(l) -> bool: return l.age < PairFx.LINK_SECONDS)
	for b in breakups:
		b.age += dt
	breakups = breakups.filter(func(b) -> bool: return b.age < PairFx.BREAKUP_SECONDS)
	_redraw()


## The warnings whose meteor is in the air right now (the comet tail shows only
## for these, T-070): the meteor is seen for the last FALL_SECONDS before landing.
func falling() -> Array:
	return warnings.filter(func(w) -> bool: return w.time_left > 0.0 and w.time_left <= FALL_SECONDS)


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
## T-539: they come in pairs (pick_pair), meteors_per_attack / 2 of them; an
## odd one left over lands alone. A pair with no spot found is left out.
func drop_meteors() -> Array:
	var spots: Array = []
	var n := int(stat("meteors_per_attack"))
	for i in n / 2:
		var pr = pick_pair()
		if pr == null:
			continue
		add_pair_warnings(pr[0], pr[1])
		spots.append(pr[0])
		spots.append(pr[1])
	if n % 2 == 1:
		var p = pick_spot()
		if p != null:
			add_warning(p)
			spots.append(p)
	warnings_shown.emit(spots)
	return spots


## Adds one warning circle at `units`; its meteor lands warning_seconds later.
## `pair` is the meteor's pair (T-539), empty for a meteor on its own.
func add_warning(units: Vector2, pair: Dictionary = {}) -> Dictionary:
	var w := {"units": units, "time_left": stat("warning_seconds"), "pair": pair}
	warnings.append(w)
	_redraw()
	return w


## Adds the two warnings of a pair at `a` and `b` (T-539) and returns the pair.
func add_pair_warnings(a: Vector2, b: Vector2) -> Dictionary:
	var pair := {"a": a, "b": b, "landed": 0, "bodies": [], "paid": false, "dead": false}
	pairs.append(pair)
	add_warning(a, pair)
	add_warning(b, pair)
	return pair


## Two landing spots pair_distance_units apart (T-539), [first, partner], or
## null: the first is picked as pick_spot() picks, the partner at that distance
## in a random direction, also within land_within_units_of_car of the car;
## both pass is_good_spot() and the ground between the
## two boulders is free for the car (gap_is_clear).
func pick_pair():
	var c: Vector2 = car.position / PX_PER_UNIT
	var reach := stat("land_within_units_of_car")
	var dist := stat("pair_distance_units")
	var apart: float = map.boulder_diameter() + stat("boulder_clearance_units")
	for _t in SPOT_TRIES:
		var p := c + Vector2.RIGHT.rotated(rng.randf() * TAU) * reach * sqrt(rng.randf())
		if not is_good_spot(p):
			continue
		for _j in PARTNER_TRIES:
			var q := p + Vector2.RIGHT.rotated(rng.randf() * TAU) * dist
			if q.distance_to(p) < apart - 0.0001 or q.distance_to(c) > reach or not is_good_spot(q):
				continue
			if gap_is_clear(p, q):
				return [p, q]
	return null


## True when the ground between the edges of two boulders at `a` and `b` is
## open for the car's body (the map's is_open_spot, GAP_CLEAR_RADIUS wide).
func gap_is_clear(a: Vector2, b: Vector2) -> bool:
	var r: float = map.boulder_diameter() / 2.0
	var length := a.distance_to(b) - 2.0 * r
	if length <= 0.0:
		return false
	var dir := (b - a).normalized()
	var n := maxi(1, int(ceil(length / GAP_SAMPLE_UNITS)))
	for i in n + 1:
		var s := a + dir * (r + length * i / float(n))
		if not map.is_open_spot(s, GAP_CLEAR_RADIUS):
			return false
	return true


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
## Returns true when it hit the car. `pair` is the meteor's pair (T-539): it
## counts the landing.
func land(units: Vector2, pair: Dictionary = {}) -> bool:
	if not pair.is_empty():
		pair.landed += 1
	var hit := false
	var car_units: Vector2 = car.position / PX_PER_UNIT
	# T-418: a car more than the contact rule's tolerance above the landing (jumping over it) is missed.
	var ground_here: float = EnemyHeightScript.height_at(_ground(), units)
	var at_level: bool = EnemyHeightScript.at_car_level(ground_here, EnemyHeightScript.car_height(car))
	# The car's invulnerability after a hit (T-334): a meteor landing on it then does nothing.
	var invulnerable: bool = state != null and state.has_method("is_invulnerable") and state.is_invulnerable()
	if at_level and not invulnerable and car_units.distance_to(units) <= stat("impact_radius_units"):
		hit = true
		if state != null:
			state.damage_car(stat("impact_damage"))
		var away := car_units - units
		if away.length() < 0.001:
			away = Vector2.RIGHT.rotated(car.rotation + PI)  # straight on: backwards
		car.apply_knockback(away, stat("knockback"))
	# T-418: minions under the meteor are hurt (Enemies, Decisions, "Meteors hit minions...").
	var spawner = _spawner()
	if spawner != null:
		spawner.damage_minions_at(units, stat("impact_radius_units"), stat("minion_damage"))
	dust.append({"units": units, "age": 0.0})  # the impact animation (T-070): plays once, then goes
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
		var pair := _pair_at(p)
		if map.can_place_meteor_boulder(p):
			var body: Node = map.add_meteor_boulder(p)
			var spawner = _spawner()
			if spawner != null:  # T-418: coins and health pickups on the spot are pushed out
				spawner.push_pickups_out(p, map.boulder_diameter() / 2.0)
			standing_boulders.append({"body": body, "age": 0.0, "pair": pair})
			if not pair.is_empty():
				pair.bodies.append(body)
			boulder_placed.emit(p, body)
		elif not pair.is_empty():
			pair.dead = true  # T-539: a pair missing a boulder pays nothing
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
			if not b.get("pair", {}).is_empty():
				b.pair.dead = true  # T-539: gone, so its pair no longer pays
		elif b.age > life:
			map.set_meteor_boulder_alpha(body, 1.0 - (b.age - life) / fade)


## The pair a meteor at `units` belongs to (T-539), or an empty dictionary.
func _pair_at(units: Vector2) -> Dictionary:
	for pr in pairs:
		if pr.a.is_equal_approx(units) or pr.b.is_equal_approx(units):
			return pr
	return {}


## True when `pair` pays on a crossing (T-539): both meteors landed, every
## boulder of it still there (standing, fading or waiting), not paid yet.
func is_pair_armed(pair: Dictionary) -> bool:
	return pair.landed >= 2 and not pair.paid and not pair.dead


## The car's own drift state, as the drift marks read it: drifting, on the ground.
func car_is_drifting() -> bool:
	var m = car.get("model")
	return m != null and m.is_drifting and car.get("airborne") != true


## T-539: a drifting car whose last step crossed the line between an armed
## pair's centres strikes it. Forgets pairs that paid or lost a boulder.
func _check_pair_crossings() -> void:
	var cu: Vector2 = car.position / PX_PER_UNIT
	if _have_last_car and car_is_drifting() and cu != _last_car_units:
		for pr in pairs.duplicate():
			if is_pair_armed(pr) and Geometry2D.segment_intersects_segment(_last_car_units, cu, pr.a, pr.b) != null:
				strike_pair(pr)
	_last_car_units = cu
	_have_last_car = true
	pairs = pairs.filter(func(pr) -> bool: return not pr.paid and not pr.dead)


## The car drifted through `pair` (T-539): the kaiju takes pair_damage_to_kaiju
## (its red hit flash comes with take_damage), both boulders break at once
## (removed from the map, or no longer waiting), and the strike effects start:
## the break-up at each boulder and the beam from the pair to the kaiju.
## Returns false, doing nothing, when no live kaiju is on the map.
func strike_pair(pair: Dictionary) -> bool:
	var k := _kaiju()
	if k == null or pair.paid:
		return false
	pair.paid = true
	var dmg := stat("pair_damage_to_kaiju")
	var k_at: Vector2 = k.position_units()
	links.append({"from": (pair.a + pair.b) / 2.0, "to": k_at, "kaiju": k, "age": 0.0})
	for body in pair.bodies:
		for b in standing_boulders.duplicate():
			if b.body == body:
				standing_boulders.erase(b)
		map.remove_meteor_boulder(body)
	pair.bodies.clear()
	for u in [pair.a, pair.b]:
		for p in pending_boulders.duplicate():
			if p.is_equal_approx(u):
				pending_boulders.erase(p)
		breakups.append({"units": u, "age": 0.0})
	k.take_damage(dmg)
	pair_struck.emit(pair.a, pair.b, dmg)
	_redraw()
	return true


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
		if Perf.on: Perf.each_begin(&"meteors.fx_process")
		_pulse = fmod(_pulse + delta * 3.0, 1.0)
		if not owner_attack.warnings.is_empty() or not owner_attack.pairs.is_empty():
			queue_redraw()
		if Perf.on: Perf.each_end(&"meteors.fx_process")

	func _draw() -> void:
		if Perf.on: Perf.each_begin(&"draw.meteors")
		var a = owner_attack
		if a.map == null:
			if Perf.on: Perf.each_end(&"draw.meteors")
			return
		var r: float = a.map.boulder_diameter() / 2.0
		var total: float = maxf(a.stat("warning_seconds"), 0.001)
		# T-539: the faint line between the two of each pair, under the circles.
		for pr in a.pairs:
			if pr.paid or pr.dead:
				continue
			var dir: Vector2 = (pr.b - pr.a).normalized()
			if pr.a.distance_to(pr.b) <= 2.0 * r:
				continue
			var from: Vector2 = ISO_TRANSFORM * ((pr.a + dir * r) * PX_PER_UNIT)
			var to: Vector2 = ISO_TRANSFORM * ((pr.b - dir * r) * PX_PER_UNIT)
			PairFx.draw_pair_line(self, from, to, a.is_pair_armed(pr), _pulse)
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
		if Perf.on: Perf.each_end(&"draw.meteors")


## Over everything: the windup flash above the kaiju, the falling meteors and
## the dust bursts.
class _SkyDraw extends Node2D:
	var owner_attack: Node
	var _t := 0.0

	func _process(delta: float) -> void:
		if Perf.on: Perf.each_begin(&"meteors.fx_process")
		_t += delta
		var a = owner_attack
		if a.is_winding_up() or not a.warnings.is_empty() or not a.dust.is_empty() or not a.links.is_empty() or not a.breakups.is_empty():
			queue_redraw()
		if Perf.on: Perf.each_end(&"meteors.fx_process")

	func _draw() -> void:
		if Perf.on: Perf.each_begin(&"draw.meteors")
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
			if MeteorFx.tail_active(w.time_left, FALL_SECONDS):
				MeteorFx.draw_tail(self, at, FALL_SECONDS - w.time_left, p, int(w.units.x * 31.0 + w.units.y * 17.0))
			draw_line(at, at - back * 30.0, METEOR_GLOW, 6.0)
			draw_circle(at, 13.0, METEOR_OUTLINE)
			draw_circle(at, 11.0, METEOR_COLOR)
			draw_circle(at + Vector2(3, -3), 4.0, METEOR_GLOW)
		for d in a.dust:
			var c: Vector2 = ISO_TRANSFORM * (d.units * PX_PER_UNIT)
			if MeteorFx.version() != "off":
				MeteorFx.draw_impact(self, c, d.age, int(d.units.x * 31.0 + d.units.y * 17.0))
				continue
			var f: float = d.age / DUST_SECONDS
			for i in 8:
				var dir := Vector2.RIGHT.rotated(TAU * i / 8.0)
				var off := Vector2(dir.x, dir.y * 0.5) * (10.0 + f * 34.0)
				draw_circle(c + off, 9.0 * (1.0 - f) + 2.0, DUST_COLOR)
		# T-539: the struck pairs' boulders breaking, and the beams to the kaiju.
		for b in a.breakups:
			PairFx.draw_breakup(self, ISO_TRANSFORM * (b.units * PX_PER_UNIT), b.age, int(b.units.x * 31.0 + b.units.y * 17.0))
		for l in a.links:
			var to_units: Vector2 = l.to
			if is_instance_valid(l.kaiju):
				to_units = l.kaiju.position_units()
			var chest: Vector2 = ISO_TRANSFORM * (to_units * PX_PER_UNIT) - Vector2(0, KaijuScript.HEIGHT_UNITS * PX_PER_UNIT * 0.45)
			PairFx.draw_link(self, ISO_TRANSFORM * (l.from * PX_PER_UNIT), chest, l.age, int(l.from.x * 31.0 + l.from.y * 17.0))
		if Perf.on: Perf.each_end(&"draw.meteors")
