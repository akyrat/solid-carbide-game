extends RefCounted
## Keeps the dead minions' bodies (task T-531; Enemies, Decisions, "Minion deaths"): the
## minion spawner hands each body here when it dies. The keeper
## - turns the body into a corpse (minion.gd keep_as_corpse): the drawing plays its death
##   animation and lies, and one green spill (minion_spill.gd) bursts from it;
## - steps every corpse (it slides after a knock, its 2 s timer runs, it fades and is freed)
##   and every spill, once per physics step from the spawner's step();
## - knocks a corpse the car drives into (the weapons knock theirs through
##   minion.gd knock_corpse, found by the group "minion_corpses");
## - keeps the crowd cheap: at most `max_corpses` whole corpses (the oldest fades at once
##   when a new one makes more), at most twice that counting the fading ones (the oldest is
##   freed at once), at most `max_droplets` droplets and `max_pools` pools alive (a burst
##   gets fewer droplets, or none, and a droplet makes no new pool, when the room is gone).
##
## Corpses are in no enemy group, on no collision layer, and never in the spawner's
## `minions` list: they are never targets, deal no damage, count no second kill and block
## nobody. Numbers: enemies.json, minion.death (EnemyData.minion_death()).

const PX_PER_UNIT := 16.0
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
const SpillScript := preload("res://scripts/enemies/minion_spill.gd")
const EnemyHeightScript := preload("res://scripts/enemies/enemy_height.gd")

var settings: Dictionary = {}
var rng := RandomNumberGenerator.new()
## False: bodies are freed at death, as before T-531 (tests, and the perf comparison).
var enabled := true
var draw_root: Node2D = null
var depth = null
var ground = null

## Corpses, oldest first.
var corpses: Array = []
## Microseconds the last step() took, and the sum of the adopt() calls since the last step (the bench).
var last_step_usec := 0
var adopt_usec := 0
## The spills, oldest first, each {"node": MinionSpill, "corpse": Minion}.
var spills: Array = []


func _init(the_settings: Dictionary = {}) -> void:
	settings = the_settings
	rng.randomize()


func max_corpses() -> int:
	return int(settings.get("max_corpses", 24.0))


func max_droplets() -> int:
	return int(settings.get("max_droplets", 120.0))


func max_pools() -> int:
	return int(settings.get("max_pools", 160.0))


func corpse_count() -> int:
	return corpses.size()


## Corpses not yet fading.
func whole_corpse_count() -> int:
	var n := 0
	for c in corpses:
		if c.corpse_fade_left < 0.0:
			n += 1
	return n


func droplet_count() -> int:
	var n := 0
	for s in spills:
		n += s["node"].droplet_count()
	return n


func pool_count() -> int:
	var n := 0
	for s in spills:
		n += s["node"].pool_count()
	return n


## Takes the body `m` that has just died at `at_units` over. Returns true when it is kept
## (the spawner's `died` listener runs this; minion.gd then does not free it).
func adopt(m: Node, at_units: Vector2) -> bool:
	var t0 := Time.get_ticks_usec()
	var kept := _adopt(m, at_units)
	adopt_usec += Time.get_ticks_usec() - t0
	return kept


func _adopt(m: Node, at_units: Vector2) -> bool:
	if not enabled or draw_root == null or m.sprite == null or not is_instance_valid(m.sprite):
		return false
	# The hard cap first: the oldest bodies go at once to make room.
	while corpses.size() >= 2 * max_corpses() and not corpses.is_empty():
		_free_corpse(corpses[0])
	m.keep_as_corpse(settings)
	corpses.append(m)
	m.sprite.start_death(float(settings.get("animation_seconds", 0.5)))
	_spill(m, at_units)
	var whole := whole_corpse_count()
	var i := 0
	while whole > max_corpses() and i < corpses.size():
		if corpses[i].corpse_fade_left < 0.0:
			corpses[i].start_fade_now()
			whole -= 1
		i += 1
	return true


func _spill(m: Node, at_units: Vector2) -> void:
	var n := mini(int(settings.get("droplets_per_death", 9.0)), maxi(max_droplets() - droplet_count(), 0))
	if n <= 0:
		return
	var node := SpillScript.new()
	node.name = "MinionSpill"
	node.ground = ground
	node.z_index = (m.sprite as Node2D).z_index - 1
	draw_root.add_child(node)
	var g: float = m.ground_height()
	node.burst(at_units, g + m.height_units() * 0.5, n, settings, rng)
	spills.append({"node": node, "corpse": m})


## One physics step of `dt` seconds. `car` knocks corpses it drives into; a corpse whose
## position is outside `keep_rect` (the view's pixels; an empty rect keeps all) is freed.
func step(dt: float, car: Node2D, keep_rect: Rect2) -> void:
	if corpses.is_empty() and spills.is_empty():
		return
	var t0 := Time.get_ticks_usec()
	Perf.begin(&"minions.corpses")
	var car_units := Vector2.ZERO
	var car_speed := 0.0
	var car_h := 0.0
	var car_ok: bool = car != null and is_instance_valid(car)
	if car_ok:
		car_units = car.position / PX_PER_UNIT
		var model = car.get("model")
		car_speed = model.get_velocity().length() if model != null else 0.0
		car_h = EnemyHeightScript.car_height(car)
	var i := corpses.size() - 1
	while i >= 0:
		var c: Node = corpses[i]
		if not is_instance_valid(c):
			corpses.remove_at(i)
			i -= 1
			continue
		var gone: bool = c.corpse_step(dt)
		if not gone and keep_rect.size.x > 0.0 and not keep_rect.has_point(ISO_TRANSFORM * c.position):
			gone = true
		if gone:
			_free_corpse(c)
			i -= 1
			continue
		if car_ok and c.touches_car(car_units, car.rotation) \
				and (ground == null or EnemyHeightScript.minion_can_hit(c.body_height(), car_h)):
			if c.car_knock(car_units, car_speed):
				c.corpse_moved = true
		if c.corpse_moved:
			place(c)
		var s = c.sprite
		if s != null and is_instance_valid(s):
			if c.corpse_fade_left >= 0.0:
				(s as CanvasItem).modulate.a = c.corpse_alpha()
			elif (s as CanvasItem).modulate.a < 1.0:
				(s as CanvasItem).modulate.a = 1.0
		i -= 1
	Perf.end(&"minions.corpses")
	Perf.begin(&"minions.spill")
	var pools := pool_count()
	var k := spills.size() - 1
	while k >= 0:
		var sp: Dictionary = spills[k]
		var node: Node2D = sp["node"]
		var corpse = sp["corpse"]
		if is_instance_valid(corpse) and corpse.is_corpse():
			if corpse.corpse_fade_left >= 0.0:
				node.begin_fade(corpse.corpse_fade_left)
		else:
			node.begin_fade(float(settings.get("fade_seconds", 0.4)))
		var before: int = node.pool_count()
		var alive: bool = node.step(dt, max_pools() - pools)
		pools += node.pool_count() - before
		if not alive:
			node.queue_free()
			spills.remove_at(k)
		k -= 1
	Perf.end(&"minions.spill")
	last_step_usec = Time.get_ticks_usec() - t0


## Puts a corpse's drawing at its body, in the buildings' depth order.
func place(c: Node) -> void:
	c.corpse_moved = false
	var s = c.sprite
	if s == null or not is_instance_valid(s):
		return
	var h: float = c.body_height()
	(s as Node2D).position = ISO_TRANSFORM * c.position + Vector2(0.0, -h * PX_PER_UNIT)
	if depth != null:
		(s as Node2D).z_index = depth.z_index_for(c.position_units(), c.radius_units(), c.height_units(), h)


func _free_corpse(c: Node) -> void:
	corpses.erase(c)
	if is_instance_valid(c):
		c.queue_free()


## Frees every corpse and spill (a new run).
func clear() -> void:
	for c in corpses:
		if is_instance_valid(c):
			c.queue_free()
	corpses.clear()
	for sp in spills:
		if is_instance_valid(sp["node"]):
			sp["node"].queue_free()
	spills.clear()
