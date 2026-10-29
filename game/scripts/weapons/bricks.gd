extends "res://scripts/weapons/weapon.gd"
## Bricks (task T-324; Weapons, Decisions, "Bricks", 2026-10-28; how it works:
## Weapons, Content, "Bricks"). The car carries a load of bricks. Each time it
## lands on the ground after being in the air for at least `min_air_seconds`
## (off a ramp, a rooftop's edge or any drop), one impact wave goes out around
## the landing spot: every enemy whose body is within `radius` units takes
## `damage` once (the kaiju too), and a minion that survives is pushed
## `knockback_distance` units straight away from the car (never the kaiju, the
## wiper's rule). The same wave whatever the height of the fall. A shorter hop
## sends none; a landing less than `cooldown` seconds after the last wave sends
## none either. Every number comes from res://data/weapons.json ("bricks")
## through WeaponData.bricks_at(); the garage damage bonus multiplies the damage
## (weapon.gd, boosted_damage()). The car's handling is not changed.
##
## The landing: each step the weapon reads the car's `airborne` (car.gd, from
## its height model, car_height.gd) and adds up the seconds it has been in the
## air; the step it reads the car back on the ground is the landing, with those
## seconds (the same count the airtime trick makes). So it stops with the rack:
## nothing is counted while the run is paused or over.
##
## One of the run's weapons (listed in weapons.gd's WEAPON_SCRIPTS, id
## "bricks"): a run starts without it (tier 0); `run.weapons.upgrade("bricks")`
## gives it (0 to 1) and applies tiers 2 to 8.
##
## Look: the wave (BricksWave, below), a projectile of the rack: an expanding
## ring on the ground at the landing spot (at the ground's height there, so on a
## rooftop it is on the roof) that grows out to exactly the damage radius, with a
## burst of dust puffs and brick chips. T-325's art: one script-drawn sheet per
## damage radius the tiers reach (res://art/weapons/bricks_wave_r<radius>.png,
## game/tools/build_bricks_wave.py), 12 stepped frames at 32 art px per unit,
## drawn at 0.5. A radius with no sheet falls back to T-324's code-drawn
## placeholder. City colours, opaque hard-edged pixels, none of Greenbull's.

## Flat world pixels per unit (Car.PX_PER_UNIT).
const PX_PER_UNIT := 16.0
## The run's isometric projection (run.gd ISO_TRANSFORM).
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
## Float tolerance.
const EPS := 1e-6
## The playtest switch file (res://data/playtest.json), one key of several.
const PLAYTEST_FILE := "playtest"
const PLAYTEST_KEY := "bricks_at_start"
## The group the kaiju is in (kaiju.gd): never pushed unless the data says so.
const KAIJU_GROUP := "kaiju"

## Tests set this to 0 (off) or 1 (on) to override data/playtest.json; -1 reads the file.
static var playtest_override := -1

## A wave went out at `centre` (flat world, units) and hit `hit_count` enemies.
signal wave_sent(centre: Vector2, hit_count: int)
## Every hit, with the damage dealt and whether the enemy was pushed.
signal enemy_hit(enemy: Node, amount: float, pushed: bool)

## WeaponData.bricks_at(tier) (tier 1's values while not owned), damage boosted.
var stats: Dictionary = {}
## Seconds the car has been in the air since it last left the ground (0 on the ground).
var air_seconds := 0.0
## Whether the car was in the air on the last step.
var was_airborne := false
## Seconds since the last wave (INF before the first of the run).
var since_wave := INF
## Waves sent and hits dealt (all enemies) this run.
var waves := 0
var hits := 0
## The last wave drawn (a BricksWave), for tests and screenshots.
var last_wave: Node2D = null


func _init() -> void:
	weapon_id = "bricks"
	starts_owned = false
	stats = data.bricks_at(1)


## The playtest switch: data/playtest.json "bricks_at_start" (or playtest_override).
static func playtest_switch_on() -> bool:
	if playtest_override >= 0:
		return playtest_override == 1
	var r := GameData.load_file(PLAYTEST_FILE)
	if not r.ok:
		return false
	var v := GameData.get_value(r.data, PLAYTEST_KEY)
	return v.ok and bool(v.data)


func _car() -> Node2D:
	if rack == null or rack.car == null or not is_instance_valid(rack.car):
		return null
	return rack.car


# --- Tiers and runs --------------------------------------------------------

func apply_tier() -> void:
	stats = data.bricks_at(maxi(tier, 1))
	stats["damage"] = boosted_damage(float(stats["damage"]))
	if not is_owned():
		_reset_air()


func reset_for_run() -> void:
	waves = 0
	hits = 0
	last_wave = null
	_reset_air()
	super.reset_for_run()


func _reset_air() -> void:
	air_seconds = 0.0
	was_airborne = false
	since_wave = INF


# --- Each step -------------------------------------------------------------

## One physics step of `dt` seconds (the rack calls it while owned and the run
## is going): counts the car's time in the air and sends a wave on a landing.
func step(dt: float) -> void:
	since_wave += dt
	var car := _car()
	if car == null:
		return
	var air := car_airborne()
	if air:
		air_seconds += dt
	elif was_airborne:
		var seconds := air_seconds
		air_seconds = 0.0
		on_landing(seconds)
	was_airborne = air


## True while the car is in the air (car.gd `airborne`; false for a car without one).
func car_airborne() -> bool:
	var car := _car()
	if car == null:
		return false
	var a = car.get("airborne")
	return a != null and bool(a)


## The car landed after `seconds` in the air: sends the wave when that was long
## enough and the last wave is at least `cooldown` seconds old. True when it did.
func on_landing(seconds: float) -> bool:
	if seconds < float(stats["min_air_seconds"]) - EPS:
		return false
	if since_wave < float(stats["cooldown"]) - EPS:
		return false
	send_wave(car_units())
	return true


## One impact wave at `centre` (flat world, units): every living enemy whose body
## is within the radius takes the damage once; minions that survive are pushed
## away from the centre. Returns the enemies hit.
func send_wave(centre: Vector2) -> Array:
	since_wave = 0.0
	waves += 1
	var hit := []
	for e in targets():
		if reaches(centre, e):
			hit.append(e)
	for e in hit:
		_hit(e, centre)
	_draw_wave(centre)
	wave_sent.emit(centre, hit.size())
	return hit


## True when an enemy's body (the rack's radius_of()) is within the wave's radius of `centre`.
func reaches(centre: Vector2, e: Node) -> bool:
	var r: float = maxf(rack.radius_of(e), 0.0) if rack != null else 0.0
	return centre.distance_to(enemy_units(e)) - r <= radius() + EPS


## The wave's radius now, in units.
func radius() -> float:
	return float(stats["radius"])


## Every living, damageable enemy in the run (the rack's rule).
func targets() -> Array:
	return rack.living_enemies() if rack != null else []


## The car's centre in units (flat world), from its driving model.
func car_units() -> Vector2:
	var car := _car()
	return Vector2(car.model.x, car.model.y) if car != null else Vector2.ZERO


## The ground's height under the car in units (car.gd `height`; 0 on the street).
func car_height() -> float:
	var car := _car()
	if car == null:
		return 0.0
	var h = car.get("height")
	return float(h) if h != null else 0.0


static func enemy_units(e: Node) -> Vector2:
	if e.has_method("position_units"):
		return e.position_units()
	return (e as Node2D).position / PX_PER_UNIT


## True when the wave pushes this enemy: it has the knockback call (only
## minions have it, T-167) and is not the kaiju (unless the data allows it).
func pushes(e: Node) -> bool:
	if not e.has_method("apply_knockback"):
		return false
	return bool(stats["knockback_kaiju"]) or not e.is_in_group(KAIJU_GROUP)


func _hit(e: Node, centre: Vector2) -> void:
	if not rack.is_target(e):
		return  # killed by an earlier hit's side effect this wave
	var amount: float = stats["damage"]
	var push := pushes(e)
	hits += 1
	var away := enemy_units(e) - centre
	if away.length() < 0.001:
		var car := _car()
		var rot := float(car.model.rotation) if car != null else 0.0
		away = Vector2(cos(rot), sin(rot))
	e.take_damage(amount, weapon_id)
	if push and is_instance_valid(e) and not (e.has_method("is_dead") and e.is_dead()):
		e.apply_knockback(away, float(stats["knockback_distance"]))
	enemy_hit.emit(e, amount, push)


# --- Drawing ----------------------------------------------------------------

## Adds the wave's drawing to the rack's draw root (a projectile: it stops while
## paused and is removed when done or at a new run).
func _draw_wave(centre: Vector2) -> void:
	if rack == null or rack.draw_root == null or not is_instance_valid(rack.draw_root):
		return
	var w := BricksWave.new()
	w.name = "BricksWave"
	w.setup(centre, radius(), car_height(), waves)
	if rack.depth != null:
		w.z_index = rack.depth.z_index_for(centre, 0.5, 0.0, car_height())
	rack.add_projectile(w)
	last_wave = w


## The impact wave: T-325's sheet for its radius (see ART), or, for a radius
## with no sheet, T-324's placeholder: an expanding ring on the ground, drawn as the
## isometric ellipse of a circle, growing in stepped frames from the car's size
## to the damage radius in WAVE_SECONDS, plus dust puffs and brick chips thrown
## out from the landing spot that grow and then shrink away (no fading: every
## pixel is opaque). Drawn in the run's screen pixels, at the ground's height.
class BricksWave:
	extends Node2D

	## T-325's sheets: one per radius, named by the radius to one decimal
	## (bricks_wave_r4_0.png), FRAMES frames in one row, ART_TOP art px above the
	## ring's ellipse, drawn at ART_SCALE (32 art px per unit on 16 screen px).
	const ART := "res://art/weapons/bricks_wave_r%s.png"
	const FRAMES := 12
	const ART_TOP := 44
	const ART_SCALE := 0.5

	## How long the wave shows, in seconds; the ring reaches the radius at RING_SECONDS.
	const WAVE_SECONDS := 0.6
	const RING_SECONDS := 0.35
	## The stepped animation's frame length (pixel-art steps, not smooth).
	const FRAME_SECONDS := 0.05
	## The ring's first radius, units (about the car's size).
	const START_RADIUS := 0.6
	const PUFFS := 12
	const CHIPS := 8
	## City colours (Visual style, "City colours"): a dark navy outline, cool
	## blue-grey concrete, pale blue and white light; brick brown chips. None of
	## Greenbull's colours.
	const OUTLINE := Color8(20, 24, 40)
	const RING_OUTER := Color8(96, 112, 140)
	const RING_INNER := Color8(176, 200, 224)
	const RING_CORE := Color8(240, 246, 255)
	const DUST_DARK := Color8(110, 118, 132)
	const DUST_LIGHT := Color8(170, 176, 186)
	const CHIP := Color8(160, 124, 104)
	const CHIP_DARK := Color8(100, 80, 70)

	## Flat world, units.
	var centre := Vector2.ZERO
	var radius := 4.0
	var ground_h := 0.0
	var age := 0.0
	## Puffs and chips: {dir: Vector2 (flat), dist: float (units), size: float (px)}.
	var puffs: Array = []
	var chips: Array = []
	var _frame := -1
	## The sheet for this radius (null: the placeholder drawing), one frame's size
	## and the landing spot's place in a frame, in art pixels.
	var sheet: Texture2D = null
	var frame_size := Vector2.ZERO
	var art_centre := Vector2.ZERO

	## The sheet's path for a damage radius of `r` units.
	static func art_path(r: float) -> String:
		return ART % ("%.1f" % r).replace(".", "_")

	## The sheet for a radius of `r` units, or null when there is none.
	static func sheet_for(r: float) -> Texture2D:
		var path := art_path(r)
		return load(path) if ResourceLoader.exists(path) else null

	## The frame of the sheet shown now (0 to FRAMES - 1).
	func frame_index() -> int:
		return clampi(int(floor(age / FRAME_SECONDS + EPS)), 0, FRAMES - 1)

	func setup(at: Vector2, r: float, height: float, seed_value: int) -> void:
		centre = at
		radius = r
		ground_h = height
		position = ISO_TRANSFORM * (centre * PX_PER_UNIT) + Vector2(0.0, -ground_h * PX_PER_UNIT)
		sheet = sheet_for(r)
		if sheet != null:
			frame_size = Vector2(float(sheet.get_width()) / FRAMES, float(sheet.get_height()))
			art_centre = Vector2(frame_size.x / 2.0, (frame_size.y + ART_TOP) / 2.0)
		var rng := RandomNumberGenerator.new()
		rng.seed = 7919 * seed_value + 13
		for i in PUFFS:
			var a := TAU * (float(i) + rng.randf_range(-0.3, 0.3)) / float(PUFFS)
			puffs.append({"dir": Vector2(cos(a), sin(a)), "dist": rng.randf_range(0.8, 1.6),
				"size": rng.randf_range(7.0, 11.0)})
		for i in CHIPS:
			var a := rng.randf_range(0.0, TAU)
			chips.append({"dir": Vector2(cos(a), sin(a)), "dist": rng.randf_range(1.0, 2.2),
				"size": rng.randf_range(2.0, 3.0)})

	func _ready() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		reset_physics_interpolation()

	func step(dt: float) -> void:
		age += dt
		var f := int(floor(age / FRAME_SECONDS + EPS))
		if f != _frame:
			_frame = f
			queue_redraw()

	func is_done() -> bool:
		return age >= WAVE_SECONDS - EPS

	## Seconds of the stepped animation now (age rounded down to a frame).
	func stepped_age() -> float:
		return floor(age / FRAME_SECONDS + EPS) * FRAME_SECONDS

	## The ring's radius now, units: eases out from START_RADIUS to `radius`.
	func ring_radius() -> float:
		var t := clampf(stepped_age() / RING_SECONDS, 0.0, 1.0)
		var e := 1.0 - (1.0 - t) * (1.0 - t)
		return lerpf(START_RADIUS, radius, e)

	## Every colour the wave draws with (tests check none is Greenbull's).
	func colours() -> Array:
		return [OUTLINE, RING_OUTER, RING_INNER, RING_CORE, DUST_DARK, DUST_LIGHT, CHIP, CHIP_DARK]

	## The ellipse on screen (pixels, relative to the centre) of a ground circle of `r` units.
	static func ellipse(r: float, points: int = 48) -> PackedVector2Array:
		var out := PackedVector2Array()
		for i in points + 1:
			var a := TAU * float(i) / float(points)
			out.append(ISO_TRANSFORM.basis_xform(Vector2(cos(a), sin(a)) * r * PX_PER_UNIT))
		return out

	func _draw() -> void:
		if sheet != null:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(ART_SCALE, ART_SCALE))
			draw_texture_rect_region(sheet, Rect2(-art_centre, frame_size),
				Rect2(Vector2(frame_index() * frame_size.x, 0.0), frame_size))
			return
		_draw_placeholder()

	## T-324's placeholder drawing, for a radius with no sheet.
	func _draw_placeholder() -> void:
		var t := stepped_age()
		# The ring: thick while it travels, thinner once it reaches the radius.
		var r := ring_radius()
		var ring_t := clampf((t - RING_SECONDS) / maxf(WAVE_SECONDS - RING_SECONDS, EPS), 0.0, 1.0)
		var w := 4.0 if ring_t <= 0.0 else (3.0 if ring_t < 0.5 else 2.0)
		var pts := ellipse(r)
		draw_polyline(pts, OUTLINE, w + 4.0, false)
		draw_polyline(pts, RING_OUTER, w + 2.0, false)
		draw_polyline(pts, RING_INNER, w, false)
		if w > 2.0:
			draw_polyline(pts, RING_CORE, 1.0, false)
		# A second, inner ring right behind the first while it travels.
		if ring_t <= 0.0 and r > START_RADIUS + 0.5:
			var inner := ellipse(r * 0.7)
			draw_polyline(inner, OUTLINE, 3.0, false)
			draw_polyline(inner, RING_OUTER, 1.0, false)
		# Dust puffs: thrown out and up, growing for the first third, then shrinking away.
		var life := clampf(t / WAVE_SECONDS, 0.0, 1.0)
		var grow := clampf(life / 0.33, 0.0, 1.0) if life < 0.33 else clampf(1.0 - (life - 0.33) / 0.67, 0.0, 1.0)
		for p in puffs:
			var flat: Vector2 = p.dir * (0.4 + float(p.dist) * minf(life * 2.0, 1.0)) * PX_PER_UNIT
			var at := ISO_TRANSFORM.basis_xform(flat) + Vector2(0.0, -life * 10.0)
			var s := roundf(float(p.size) * grow)
			if s < 1.0:
				continue
			var half := Vector2(s, s) / 2.0
			draw_rect(Rect2((at - half - Vector2.ONE).round(), (half * 2.0 + Vector2(2, 2)).round()), OUTLINE)
			draw_rect(Rect2((at - half).round(), (half * 2.0).round()), DUST_DARK)
			draw_rect(Rect2((at - half).round(), (half * 1.2).round()), DUST_LIGHT)
		# Brick chips: fly out in a short hop and drop, gone at the end.
		for c in chips:
			if life >= 0.9:
				break
			var flat: Vector2 = c.dir * float(c.dist) * life * PX_PER_UNIT
			var hop := 4.0 * 14.0 * life * (1.0 - life)
			var at := ISO_TRANSFORM.basis_xform(flat) + Vector2(0.0, -hop)
			var s := float(c.size)
			draw_rect(Rect2((at - Vector2(s, s) / 2.0 - Vector2.ONE).round(), Vector2(s + 2.0, s + 2.0).round()), OUTLINE)
			draw_rect(Rect2((at - Vector2(s, s) / 2.0).round(), Vector2(s, s).round()), CHIP)
			draw_rect(Rect2((at - Vector2(s, s) / 2.0 + Vector2(0, s / 2.0)).round(), Vector2(s, s / 2.0).round()), CHIP_DARK)
