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
## Targeting rule (report, "How it chooses and aims at a target"): the enemies
## in range sorted closest first; bullet 1 goes to the closest, bullet 2 to the
## second closest and so on, going round them again, closest first, when there
## are more bullets than enemies. Bullets in a volley leave delay_between_bullets
## apart. Each is aimed from the car's centre at that moment at its target's
## centre at that moment (no leading); a target that died before its bullet
## left is aimed at where it was last seen.
##
## Numbers: WeaponData.gun_at(tier), from res://data/weapons.json. Nothing here
## changes them.

const BulletScript := preload("res://scripts/weapons/bullet.gd")

## Small tolerance so a sum of physics steps that lands on the interval counts.
const EPSILON := 0.000001

## Emitted for every bullet fired, with its target.
signal fired(bullet: Node, target: Node)

## The current tier's values (WeaponData.gun_at): damage, range, fire_interval,
## bullets, bullet_speed, bullet_hit_radius, delay_between_bullets,
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
	var targets: Array = rack.enemies_within(rack.car_units(), float(stats["range"]))
	if targets.is_empty():
		return
	volleys += 1
	_queue.clear()
	for i in int(stats["bullets"]):
		var t = targets[i % targets.size()]
		_queue.append([t, t.position_units()])
	_fire_next()


func _step_volley(dt: float) -> void:
	if _queue.is_empty():
		return
	_queue_wait -= dt
	if _queue_wait <= EPSILON:
		_fire_next()


func _fire_next() -> void:
	var entry: Array = _queue.pop_front()
	var target = entry[0]
	var aim: Vector2 = entry[1]
	if rack.is_target(target):
		aim = target.position_units()
	else:
		target = null
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
	b.setup(rack, from, dir.normalized(), stats)
	rack.add_projectile(b)
	fired.emit(b, target)
	return b
