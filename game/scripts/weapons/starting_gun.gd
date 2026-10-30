extends "res://scripts/weapons/weapon.gd"
## The starting gun (task T-041; Weapons, Decisions; the Unity prototype's
## "Simple Gun", Unity weapons report, section 2). Every run starts with it.
## There is nothing to see on the car, only the bullets.
##
## Firing: a timer counts physics time. Each time it reaches the fire interval
## it goes back to 0 and the gun looks for living enemies whose centre is
## within range of the car's centre. None: nothing happens until the next
## check, one interval later (the gun looks only once per interval, as in the
## prototype). Some: it fires a volley.
##
## Targeting rule (T-408; Weapons, Content, "The starting gun"): the enemies in
## range sorted closest first, and the tier's `targets` (1, 3 from tier 6, 5 at
## tier 11) says how many of them a volley aims at.
## - One target (below tier 6): the whole volley goes at the closest enemy, its
##   bullets leaving delay_between_bullets apart. A bullet whose target has died
##   by the time it leaves aims at the closest living enemy in range instead
##   (none: where the target was last seen).
## - Several (tier 6 on): the closest `targets` enemies; bullet 1 goes to the
##   closest, bullet 2 to the second closest and so on, round them again when
##   there are more bullets than targets. The whole volley leaves at once.
## Each bullet is aimed from the car's centre at its target's centre at that
## moment (no leading).
##
## Numbers: WeaponData.gun_at(tier), from res://data/weapons.json. Nothing here
## changes them.

const BulletScript := preload("res://scripts/weapons/bullet.gd")

## Small tolerance so a sum of physics steps that lands on the interval counts.
const EPSILON := 0.000001

## Emitted for every bullet fired, with its target.
signal fired(bullet: Node, target: Node)

## The current tier's values (WeaponData.gun_at): damage, range, fire_interval,
## bullets, targets, bullet_speed, bullet_hit_radius, delay_between_bullets,
## pierce_hits, missed_bullet_max_travel.
var stats: Dictionary = {}
## Seconds since the last target check.
var fire_clock := 0.0
## How many target checks found nothing / fired a volley (for tests and notes).
var checks := 0
var volleys := 0

## The rest of the current volley: [target, last seen position (units)] pairs.
var _queue: Array = []
var _queue_wait := 0.0
var _drawn_size := -1.0


func _init() -> void:
	weapon_id = "gun"
	starts_owned = true


func apply_tier() -> void:
	stats = data.gun_at(maxi(tier, 1))
	stats["damage"] = boosted_damage(float(stats["damage"]))
	# The placeholder's drawn size; WeaponData.gun_at() leaves it out.
	if _drawn_size < 0.0:
		var raw = GameData.unwrap(GameData.load_file("weapons"))
		_drawn_size = float(GameData.unwrap(GameData.get_value(raw, "gun.bullet_drawn_size")))
	stats["bullet_drawn_size"] = _drawn_size


func reset_for_run() -> void:
	fire_clock = 0.0
	checks = 0
	volleys = 0
	_queue.clear()
	_queue_wait = 0.0
	super.reset_for_run()


## Seconds between target checks at the current tier.
func fire_interval() -> float:
	return float(stats["fire_interval"])


func step(dt: float) -> void:
	_step_volley(dt)
	fire_clock += dt
	if fire_clock < fire_interval() - EPSILON:
		return
	fire_clock = 0.0
	checks += 1
	# T-326: only enemies on the car's level are aimed at, so no volley is wasted
	# on one on another level.
	var targets: Array = rack.enemies_within(rack.car_units(), float(stats["range"]), rack.car_level())
	var bullets := int(stats["bullets"])
	if targets.is_empty() or bullets <= 0:
		return
	volleys += 1
	_queue.clear()
	var aimed := targets.slice(0, maxi(1, targets_per_volley()))
	if aimed.size() == 1 and targets_per_volley() <= 1:
		# One target: a stream at the closest, delay_between_bullets apart.
		for i in bullets:
			_queue.append([aimed[0], aimed[0].position_units()])
		_fire_next()
		return
	# Several targets: the whole volley at once, round the closest ones.
	for i in bullets:
		var t = aimed[i % aimed.size()]
		fire_at(t.position_units(), t)


## How many enemies a volley aims at, at the current tier (1, 3 or 5).
func targets_per_volley() -> int:
	return int(stats.get("targets", 1))


func _step_volley(dt: float) -> void:
	if _queue.is_empty():
		return
	_queue_wait -= dt
	if _queue_wait <= EPSILON:
		_fire_next()


func _fire_next() -> void:
	if _queue.is_empty():
		return
	var entry: Array = _queue.pop_front()
	var target = entry[0]
	var aim: Vector2 = entry[1]
	if not rack.is_target(target):
		# The target died mid-volley: the closest living enemy in range instead.
		var others: Array = rack.enemies_within(rack.car_units(), float(stats["range"]), rack.car_level())
		target = null
		if not others.is_empty():
			target = others[0]
			for e in _queue:
				if not rack.is_target(e[0]):
					e[0] = target
	if target != null:
		aim = target.position_units()
	fire_at(aim, target)
	_queue_wait = float(stats["delay_between_bullets"])


## Fires one bullet from the car's centre at `aim` (flat world, units).
func fire_at(aim: Vector2, target: Node = null) -> Node:
	var from: Vector2 = rack.car_units()
	var dir := aim - from
	if dir.length() < 0.0001:
		dir = Vector2.RIGHT.rotated(rack.car.rotation)
	var b: Node2D = BulletScript.new()
	b.name = "Bullet"
	b.setup(rack, from, dir.normalized(), stats, rack.car_level())
	b.weapon_id = weapon_id
	rack.add_projectile(b)
	fired.emit(b, target)
	return b
