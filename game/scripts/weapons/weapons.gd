extends Node
## The car's weapons in a run (task T-041; Weapons, Decisions): the weapon
## rack. The run scene adds it as `run.weapons` (child "Weapons") and calls
## bind(run). It holds one node of each weapon (WEAPON_SCRIPTS), steps the
## owned ones and every projectile once per physics step (_physics_process,
## pausable, so the pause screen and the level-up pause stop them), and does
## nothing once the run is over. On run.world_rebuilt (a new run) it removes
## every projectile and resets every weapon: the run starts with the starting
## gun at tier 1 and nothing else.
##
## Targets: every node in the group "enemies" inside this run that has
## take_damage(amount) and is not dead (is_dead()). That finds the minions
## now and the kaiju once it joins the group. A target gives its centre with
## position_units() (flat world, units) and its size with
## hit_radius_units() when it has one, else from its first CollisionShape2D.
##
## Drawing: projectiles live in `draw_root` (node "WeaponShots", just before
## the car's View, in the isometric view), each placed in the buildings'
## depth order with the minions' rule (enemy_depth.gd).

const StartingGunScript := preload("res://scripts/weapons/starting_gun.gd")
const ExhaustFlamethrowerScript := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const NeonUnderglowScript := preload("res://scripts/weapons/neon_underglow.gd")
const MolotovsScript := preload("res://scripts/weapons/molotovs.gd")
const LevelUpOffersScript := preload("res://scripts/weapons/level_up_offers.gd")
const EnemyDepthScript := preload("res://scripts/enemies/enemy_depth.gd")

## Every weapon the car can have, one node each. A new weapon adds its script here.
const WEAPON_SCRIPTS := [StartingGunScript, ExhaustFlamethrowerScript, NeonUnderglowScript, MolotovsScript]

const PX_PER_UNIT := 16.0
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
## Group every damageable enemy is in (minions now, the kaiju later).
const ENEMY_GROUP := "enemies"
## Used when a target has neither hit_radius_units() nor a collision shape.
const DEFAULT_TARGET_RADIUS_UNITS := 0.5

## False stops the weapons and projectiles (tests).
var enabled := true
## Bound by bind(): the run scene, its state and car.
var run: Node = null
var state: Node = null
var car: Node2D = null
## The drawing's node for projectiles (isometric screen pixels).
var draw_root: Node2D = null
## The weapons by id ("gun", ...).
var weapons: Dictionary = {}
## Projectiles in flight: nodes with step(dt) and is_done(); removed when done.
var projectiles: Array = []
var depth = EnemyDepthScript.new()
## The level-up's weapon choices (level_up_offers.gd), made in bind().
var offers: Node = null
## The garage's damage bonus in percent (T-062), set at the start of a run with
## set_damage_bonus(); it stays across weapon resets. 0 = no bonus.
var damage_bonus_percent := 0.0


func _init() -> void:
	for script in WEAPON_SCRIPTS:
		var w: Node = script.new()
		w.rack = self
		w.name = w.weapon_id.capitalize().replace(" ", "")
		weapons[w.weapon_id] = w
		add_child(w)


## The starting gun (starting_gun.gd).
var gun: Node:
	get:
		return weapons.get("gun")
## The exhaust flamethrower (flamethrower/exhaust_flamethrower.gd).
var flamethrower: Node:
	get:
		return weapons.get("flamethrower")
## The neon underglow (neon_underglow.gd).
var underglow: Node:
	get:
		return weapons.get("underglow")
## The molotovs (molotovs.gd).
var molotov: Node:
	get:
		return weapons.get("molotov")


## Binds the rack to a run scene (run.gd): its state and car, and a draw root
## just before its View node. Follows world_rebuilt (a new run).
func bind(the_run: Node) -> void:
	run = the_run
	state = run.state
	draw_root = Node2D.new()
	draw_root.name = "WeaponShots"
	run.add_child(draw_root)
	run.move_child(draw_root, run.view_root.get_index())
	run.world_rebuilt.connect(_on_world_rebuilt)
	offers = LevelUpOffersScript.new()
	offers.name = "LevelUpOffers"
	add_child(offers)
	offers.bind(self)
	if run.car != null:
		_on_world_rebuilt()


func _on_world_rebuilt() -> void:
	car = run.car
	depth.set_map(run.map)
	reset_for_run()


## A new run: no projectiles, the starting gun at tier 1, every other weapon not owned.
func reset_for_run() -> void:
	clear_projectiles()
	for w in weapons.values():
		w.reset_for_run()
	# Playtest switch (T-042, data/playtest.json "flamethrower_at_start"): gives
	# the flamethrower with the level-up's own call (the level-up then offers the flamethrower's upgrades).
	if ExhaustFlamethrowerScript.playtest_switch_on():
		upgrade("flamethrower")
	# Playtest switch (T-168, data/playtest.json "underglow_at_start"): the same for the underglow.
	if NeonUnderglowScript.playtest_switch_on():
		upgrade("underglow")
	# Playtest switch (T-169, data/playtest.json "molotov_at_start"): the same for the molotovs.
	if MolotovsScript.playtest_switch_on():
		upgrade("molotov")


## The factor every weapon's damage is multiplied by: 1 + bonus / 100.
func damage_multiplier() -> float:
	return 1.0 + damage_bonus_percent / 100.0


## Sets the garage's damage bonus (percent) and re-applies the tiers of the
## owned weapons, so both weapons get it at once.
func set_damage_bonus(percent: float) -> void:
	damage_bonus_percent = percent
	for w in weapons.values():
		if w.is_owned():
			w.apply_tier()


func clear_projectiles() -> void:
	for p in projectiles:
		if is_instance_valid(p):
			p.queue_free()
	projectiles.clear()


## The weapon with that id, or null.
func get_weapon(weapon_id: String) -> Node:
	return weapons.get(weapon_id)


## The owned weapons' ids.
func owned_ids() -> Array:
	var out := []
	for id in weapons:
		if weapons[id].is_owned():
			out.append(id)
	return out


## Gets the weapon or applies its next tier (for the level-up, T-043).
## False when it is already at its last tier or there is no such weapon.
func upgrade(weapon_id: String) -> bool:
	var w := get_weapon(weapon_id)
	return w != null and w.upgrade()


func _physics_process(delta: float) -> void:
	step(delta)


## One physics step: each projectile in flight, then each owned weapon. Nothing happens
## once the run is over.
func step(dt: float) -> void:
	if not enabled or car == null or not is_instance_valid(car):
		return
	if state != null and not state.is_running():
		return
	# Projectiles first, so one fired this step starts moving on the next
	# (as the prototype's bullets do).
	for p in projectiles.duplicate():
		if not is_instance_valid(p):
			projectiles.erase(p)
			continue
		p.step(dt)
		if p.is_done():
			projectiles.erase(p)
			p.queue_free()
	for w in weapons.values():
		if w.is_owned():
			w.step(dt)


## Adds a projectile (a Node2D with step(dt) and is_done()) to the drawing and the step.
## `parent` draws it elsewhere than draw_root (the molotovs' fire areas, on the
## ground); it is still stepped, freed once done and removed at a new run.
func add_projectile(p: Node2D, parent: Node = null) -> void:
	(parent if parent != null else draw_root).add_child(p, true)
	projectiles.append(p)


## The car's centre in units (flat world).
func car_units() -> Vector2:
	return car.position / PX_PER_UNIT


## Every living, damageable enemy in this run.
func living_enemies() -> Array:
	var out := []
	if run == null or not run.is_inside_tree():
		return out
	for e in run.get_tree().get_nodes_in_group(ENEMY_GROUP):
		if is_target(e) and run.is_ancestor_of(e):
			out.append(e)
	return out


## True for a living enemy a weapon can damage.
static func is_target(e: Object) -> bool:
	if e == null or not is_instance_valid(e) or not e.has_method("take_damage"):
		return false
	if e is Node and (e as Node).is_queued_for_deletion():
		return false
	return not (e.has_method("is_dead") and e.is_dead())


## Living enemies whose centre is within `radius` units of `centre`, closest first.
func enemies_within(centre: Vector2, radius: float) -> Array:
	var found := []
	for e in living_enemies():
		var d: float = centre.distance_to(e.position_units())
		if d <= radius:
			found.append([d, e])
	found.sort_custom(func(a, b) -> bool: return a[0] < b[0])
	return found.map(func(pair): return pair[1])


## How far from its centre an enemy's body reaches, in units.
static func radius_of(e: Node) -> float:
	if e.has_method("hit_radius_units"):
		return float(e.hit_radius_units())
	for c in e.get_children():
		if c is CollisionShape2D and c.shape != null:
			var s: Shape2D = c.shape
			if s is CircleShape2D:
				return (s as CircleShape2D).radius / PX_PER_UNIT
			if s is RectangleShape2D:
				return (s as RectangleShape2D).size.length() / 2.0 / PX_PER_UNIT
			if s is CapsuleShape2D:
				return maxf((s as CapsuleShape2D).radius, (s as CapsuleShape2D).height / 2.0) / PX_PER_UNIT
			return s.get_rect().size.length() / 2.0 / PX_PER_UNIT
	return DEFAULT_TARGET_RADIUS_UNITS
